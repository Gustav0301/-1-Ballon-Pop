--!strict
-- ZoneLayerController: the sky changes with your height (client only, every player sees their own).
--  * Look: Lighting, Atmosphere, ColorCorrection and Terrain clouds blend from zone to zone.
--  * Clouds: puffy stud clouds in Meadow Sky, small golden cloudlets in Cloud Shelf, drifting with the wind.
--  * Deck: a stud cloud deck at 480-520. A ceiling from below, a floor from above, no collision.
--    Tiles follow you. Further out the floor goes on as flat slabs that break up and fade into the sky.
--    Cloud towers grow out of the deck far away.
--  * Near bits: petals and pollen down low, golden dust up high.
--  * Clouds never turn see-through: they grow in from small and shrink away.
--  * Punch-through: crossing the deck gives a cloud puff ring, a flash and a whoosh.
-- Everything is in ZoneLayerConfig. Weather goes on top with SetOverlay (see below).
-- The cloud shapes use the same math as the preview (docs/mockups/zone-layers) and tools/zones/clouds.py.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local ZoneLayerController = {}
ZoneLayerController.ZoneChanged = Instance.new("BindableEvent") -- (zone, oldZone) when you cross into a new zone
ZoneLayerController.PunchThrough = Instance.new("BindableEvent") -- (up: boolean) when you cross the cloud deck
ZoneLayerController.Zone = nil :: any -- the zone you are in now (a ZoneLayerConfig.Zones entry)
ZoneLayerController.Look = nil :: any -- the blended Sky values right now (after weather)

type Box = { x: number, y: number, z: number, sx: number, sy: number, sz: number, c: Color3, top: boolean }
type Rng = () -> number
type Island = { x: number, y: number, z: number, r: number, lo: Vector3, hi: Vector3 }
type Cloud = { parts: { BasePart }, offs: { Vector3 }, sizes: { Vector3 }, pos: Vector3, half: Vector3, alpha: number, shown: number, scale: number, fade: number, alive: boolean }
type Tile = { inst: Instance?, far: boolean, ix: number, iz: number }
type Tower = { ix0: number, iz0: number, n: number, x: number, z: number }
type CloudLayer = { zone: any, clouds: { Cloud }, active: boolean, filled: boolean, folder: Folder, sizeMin: number, sizeMax: number }
type Bit = { part: BasePart, kind: string, age: number, life: number, vel: Vector3, spin: Vector3 }
type Overlay = { values: { [string]: any }, weight: number, target: number, speed: number }

local Cfg: any
local Sound: any
local Zones: { any }
local Deck: any
local root: Folder
local overlays: { [string]: Overlay } = {}
local overlayOrder: { string } = {}
local islands: { Island } = {}
local skyKeys: { string } = {}

local atmosphere: Atmosphere
local cc: ColorCorrectionEffect
local flashCC: ColorCorrectionEffect
local skyObj: Sky?
local terrainClouds: Clouds?

-- ---------------------------------------------------------------- helpers

-- Park-Miller random numbers: the same sequence as the preview and the Python tools
local function rng(seed: number): Rng
	local s = math.floor(seed) % 2147483646 + 1
	return function(): number
		s = (s * 16807) % 2147483647
		return (s - 1) / 2147483646
	end
end

local function smooth(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function lerpAny(a: any, b: any, k: number): any
	if typeof(a) == "number" and typeof(b) == "number" then
		return a + (b - a) * k
	elseif typeof(a) == "Color3" and typeof(b) == "Color3" then
		return (a :: Color3):Lerp(b :: Color3, k)
	end
	return if k >= 0.5 then b else a
end

local function myHeightAndPos(): (number, Vector3)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		return hrp.Position.Y, hrp.Position
	end
	local cam = Workspace.CurrentCamera
	local p = if cam then cam.Focus.Position else Vector3.zero
	return p.Y, p
end

local function newPart(b: Box, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false -- the camera and raycasts ignore clouds
	p.CanTouch = false
	p.CastShadow = false -- a deck at 500 would shadow the whole map
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Locked = true
	p.Size = Vector3.new(math.max(b.sx, 0.2), math.max(b.sy, 0.2), math.max(b.sz, 0.2))
	p.CFrame = CFrame.new(b.x, b.y, b.z)
	p.Color = b.c
	if b.top and Cfg.Studs.On then
		local t = Instance.new("Texture")
		t.Texture = Cfg.Studs.Texture
		t.Face = Enum.NormalId.Top
		t.StudsPerTileU = Cfg.Studs.Tile
		t.StudsPerTileV = Cfg.Studs.Tile
		t.Transparency = Cfg.Studs.Transparency
		t.Parent = p
	end
	p.Parent = parent
	return p
end

-- ---------------------------------------------------------------- cloud shapes (same as the preview)

-- a stepped dome: layers stacked up (dir 1) or down (dir -1) from baseY, each one smaller
local function dome(out: { Box }, cx: number, baseY: number, cz: number, w: number, d: number, h: number, layers: number, dir: number, colOf: (number, number) -> Color3)
	local lh = h / layers
	local y = baseY
	for i = 0, layers - 1 do
		local k = 1 - i * 0.26
		table.insert(out, { x = cx, y = y + dir * lh / 2, z = cz, sx = w * k, sy = lh, sz = d * k, c = colOf(i, layers), top = dir > 0 and i == layers - 1 })
		y += dir * lh
	end
end

-- a puffy cloud: a flat slab, a grid of stepped puffs on top, a darker belly under it (all parts touch, none overlap)
local function cloudBoxes(r: Rng, cx: number, cy: number, cz: number, size: number, c: any): { Box }
	local out: { Box } = {}
	local w = size * (1.2 + r() * 0.6)
	local d = size * (0.7 + r() * 0.3)
	local hb = size * 0.2
	table.insert(out, { x = cx, y = cy, z = cz, sx = w, sy = hb, sz = d, c = c.Side, top = true })
	local nx = 2 + (if r() < 0.5 then 1 else 0)
	local nz = if d > size * 0.85 then 2 else 1
	local cw, cd = w / nx, d / nz
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			if r() > 0.85 then
				continue
			end
			local pw = cw * (0.7 + r() * 0.3)
			local pd = cd * (0.7 + r() * 0.3)
			local ph = size * (0.25 + r() * 0.35)
			local layers = 2 + math.floor(r() * 2)
			local px = cx - w / 2 + cw * (i + 0.5) + (cw - pw) / 2 * (r() * 2 - 1)
			local pz = cz - d / 2 + cd * (j + 0.5) + (cd - pd) / 2 * (r() * 2 - 1)
			dome(out, px, cy + hb / 2, pz, pw, pd, ph, layers, 1, function()
				return c.Top
			end)
		end
	end
	table.insert(out, { x = cx, y = cy - hb / 2 - size * 0.05, z = cz, sx = w * 0.82, sy = size * 0.1, sz = d * 0.8, c = c.Bottom, top = false })
	return out
end

local function tileSeed(ix: number, iz: number): number
	return ix * 7349 + iz * 9157 + Deck.Seed * 101
end

local towerTiles: { [string]: boolean } = {} -- deck tiles that a cloud tower stands in

-- one deck tile: a slab that meets its neighbours edge to edge, stepped puffs on a 2x2 grid on top, bellies under.
-- far = true: only the flat slab (the far floor)
local function deckTile(ix: number, iz: number, far: boolean): { Box }
	local r = rng(tileSeed(ix, iz))
	local t = Deck.Tile
	local out: { Box } = {}
	local cx, cz = (ix + 0.5) * t, (iz + 0.5) * t
	if r() > Deck.Coverage or towerTiles[ix .. "," .. iz] then
		return out
	end
	for _, I in islands do
		if math.abs(I.y - Deck.Y) < Deck.Thickness / 2 + Deck.IslandBand and math.sqrt((cx - I.x) ^ 2 + (cz - I.z) ^ 2) < I.r + Deck.IslandHole then
			return out
		end
	end
	local thick = Deck.Thickness * (0.6 + r() * 0.2)
	local sy = Deck.Y + (r() - 0.5) * 6
	local c = t / 2
	table.insert(out, { x = cx, y = sy, z = cz, sx = t, sy = thick, sz = t, c = Deck.Side, top = not far })
	if far then
		return out
	end
	for i = 0, 1 do
		for j = 0, 1 do
			if r() > 0.75 then
				continue
			end
			local pw = 14 + r() * 16
			local pd = 14 + r() * 16
			local h = 6 + r() * 10
			local layers = 2 + math.floor(r() * 2)
			local gold = r() < 0.3
			local px = cx - c / 2 + c * i + (c - pw) / 2 * (r() * 2 - 1)
			local pz = cz - c / 2 + c * j + (c - pd) / 2 * (r() * 2 - 1)
			dome(out, px, sy + thick / 2, pz, pw, pd, h, layers, 1, function(k, n)
				return if gold and k == n - 1 then Deck.TopGold else Deck.Top
			end)
		end
	end
	for i = 0, 1 do
		for j = 0, 1 do
			if r() > 0.55 then
				continue
			end
			local pw = 12 + r() * 18
			local pd = 12 + r() * 18
			local h = 4 + r() * 6
			local px = cx - c / 2 + c * i + (c - pw) / 2 * (r() * 2 - 1)
			local pz = cz - c / 2 + c * j + (c - pd) / 2 * (r() * 2 - 1)
			dome(out, px, sy - thick / 2, pz, pw, pd, h, 2, -1, function()
				return Deck.Bottom
			end)
		end
	end
	return out
end

-- a tall stepped cloud tower with little bumps on each step
local function towerBoxes(r: Rng, x: number, z: number, baseY: number, W: number): { Box }
	local T = Cfg.Towers
	local out: { Box } = {}
	local H = T.Height[1] + r() * (T.Height[2] - T.Height[1])
	local y, w = baseY, W
	local steps = 5 + math.floor(r() * 3)
	for k = 0, steps - 1 do
		local h = H / steps * (1.1 - k * 0.05)
		local col = if k == steps - 1 then Deck.TopGold elseif k % 2 == 1 then Deck.Top else Deck.Side
		table.insert(out, { x = x, y = y + h / 2, z = z, sx = w, sy = h, sz = w, c = col, top = true })
		if k < steps - 1 then
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					if r() < 0.4 then
						continue
					end
					local bw = w * 0.08
					local bh = h * (0.15 + r() * 0.2)
					table.insert(out, { x = x + sx * (w / 2 - bw / 2), y = y + h + bh / 2, z = z + sz * (w / 2 - bw / 2), sx = bw, sy = bh, sz = bw, c = Deck.Top, top = true })
				end
			end
		end
		y += h
		w *= 0.8
	end
	return out
end

-- where the towers stand: on the deck grid, each one in place of n x n tiles (so nothing overlaps)
local function towerLayout(): { Tower }
	local T = Cfg.Towers
	local t = Deck.Tile
	local r = rng(31)
	local out: { Tower } = {}
	for i = 0, T.Count - 1 do
		local a = (i / T.Count) * math.pi * 2 + r() * 0.5
		local dist = T.Distance[1] + r() * (T.Distance[2] - T.Distance[1])
		local n = T.Tiles[1] + math.floor(r() * (T.Tiles[2] - T.Tiles[1] + 1))
		local ix0 = math.floor(math.cos(a) * dist / t - n / 2 + 0.5)
		local iz0 = math.floor(math.sin(a) * dist / t - n / 2 + 0.5)
		table.insert(out, { ix0 = ix0, iz0 = iz0, n = n, x = (ix0 + n / 2) * t, z = (iz0 + n / 2) * t })
	end
	return out
end

-- ---------------------------------------------------------------- islands (holes in the deck, clouds keep away)

local function readIslands(shared: Instance?)
	islands = {}
	for _, name in Cfg.Islands.Folders do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			for _, m in folder:GetChildren() do
				if m:IsA("Model") then
					local cf, size = m:GetBoundingBox()
					local hi = cf.Position + size / 2
					table.insert(islands, {
						x = cf.Position.X,
						y = hi.Y,
						z = cf.Position.Z,
						r = math.max(size.X, size.Z) / 2,
						lo = cf.Position - size / 2,
						hi = hi,
					})
				end
			end
		end
	end
	if #islands == 0 and shared then
		local ok, IslandConfig = pcall(function()
			return require((shared :: any).Config.IslandConfig) :: any
		end)
		if ok and IslandConfig then
			for _, I in IslandConfig.Islands do
				local top: Vector3 = I.Top
				table.insert(islands, {
					x = top.X,
					y = top.Y,
					z = top.Z,
					r = I.Radius,
					lo = top - Vector3.new(I.Radius, 30, I.Radius),
					hi = top + Vector3.new(I.Radius, 24, I.Radius),
				})
			end
		end
	end
end

local function hitsIsland(center: Vector3, half: Vector3): boolean
	local m = Cfg.Islands.Margin
	for _, I in islands do
		if center.X + half.X + m > I.lo.X and center.X - half.X - m < I.hi.X
			and center.Y + half.Y + m > I.lo.Y and center.Y - half.Y - m < I.hi.Y
			and center.Z + half.Z + m > I.lo.Z and center.Z - half.Z - m < I.hi.Z then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------- the look

local function zoneAt(h: number): number
	for i, z in Zones do
		if h < z.To then
			return i
		end
	end
	return #Zones
end

-- blend every Sky value by height: zone i fades into zone i+1 from (To - Below) to (To + Above)
local function blendedSky(h: number): { [string]: any }
	local look: { [string]: any } = table.clone(Zones[1].Sky)
	for i = 1, #Zones - 1 do
		local k = smooth((h - (Zones[i].To - Cfg.Blend.Below)) / (Cfg.Blend.Below + Cfg.Blend.Above))
		if k <= 0 then
			break
		end
		local nextSky = Zones[i + 1].Sky
		for _, key in skyKeys do
			if nextSky[key] ~= nil then
				look[key] = lerpAny(look[key], nextSky[key], k)
			end
		end
	end
	return look
end

-- 0 outside the deck, 1 in its middle: the fog closes in
local function mistK(h: number): number
	local half = Deck.Thickness / 2
	local d = math.abs(h - Deck.Y)
	return 1 - math.clamp((d - half * 0.4) / (half * 1.6), 0, 1)
end

-- blend weight between the first two zones (petals fade out, golden dust fades in)
local function upperK(h: number): number
	return smooth((h - (Zones[1].To - Cfg.Blend.Below)) / (Cfg.Blend.Below + Cfg.Blend.Above))
end

local function applyLook(h: number)
	local look = blendedSky(h)
	for _, id in overlayOrder do
		local ov = overlays[id]
		if ov and ov.weight > 0 then
			for key, v in ov.values do
				if look[key] ~= nil then
					look[key] = lerpAny(look[key], v, ov.weight)
				end
			end
		end
	end
	local m = mistK(h)
	ZoneLayerController.Look = look

	Lighting.Brightness = look.Brightness
	Lighting.ClockTime = look.ClockTime
	Lighting.ExposureCompensation = look.Exposure
	Lighting.Ambient = look.Ambient
	Lighting.OutdoorAmbient = look.OutdoorAmbient
	atmosphere.Color = (look.AtmosColor :: Color3):Lerp(Color3.new(1, 1, 1), m)
	atmosphere.Decay = (look.AtmosDecay :: Color3):Lerp(Color3.new(1, 1, 1), m * 0.6)
	atmosphere.Density = look.AtmosDensity + (Cfg.Punch.MistDensity - look.AtmosDensity) * m
	atmosphere.Haze = look.AtmosHaze * (1 - m)
	atmosphere.Glare = look.AtmosGlare * (1 - m)
	atmosphere.Offset = look.AtmosOffset
	cc.TintColor = look.Tint
	cc.Saturation = look.Saturation
	cc.Contrast = look.Contrast
	cc.Brightness = look.CCBrightness
	if skyObj then
		skyObj.SunAngularSize = look.SunSize
	end
	if terrainClouds then
		terrainClouds.Cover = look.CloudCover
		terrainClouds.Density = look.CloudDensity
		terrainClouds.Color = look.CloudColor
	end
end

-- ---------------------------------------------------------------- drifting clouds

local cloudRandom = Random.new()
local layers: { CloudLayer } = {}

-- clouds grow in from small and shrink away (never see-through)
local function cloudVisible(cl: Cloud, alpha: number)
	if cl.shown == alpha then
		return
	end
	local wasHidden = cl.shown <= 0
	cl.shown = alpha
	cl.scale = if alpha >= 1 then 1 else 0.08 + 0.92 * (1 - (1 - alpha) ^ 3)
	for j, p in cl.parts do
		if alpha <= 0 then
			p.Transparency = 1
		else
			if wasHidden then
				p.Transparency = 0
			end
			p.Size = cl.sizes[j] * cl.scale
		end
	end
end

local function freeSpot(layer: CloudLayer, center: Vector3, half: Vector3, skip: Cloud?): boolean
	if hitsIsland(center, half) then
		return false
	end
	for _, other in layer.clouds do
		if other ~= skip and other.alive then
			local d = other.pos - center
			if math.abs(d.X) < other.half.X + half.X + 4 and math.abs(d.Y) < other.half.Y + half.Y + 4 and math.abs(d.Z) < other.half.Z + half.Z + 4 then
				return false
			end
		end
	end
	return true
end

-- clouds live between MinY and MaxY, but only near your height (so there are always some around you)
local function heightBand(zc: any, h: number): (number, number)
	local lo, hi = math.max(zc.MinY, h - 250), math.min(zc.MaxY, h + 250)
	if lo > hi then
		return zc.MinY, zc.MaxY
	end
	return lo, hi
end

-- (re)build one cloud at a free spot in the ring around you; edge = true puts it far out (upwind)
local function placeCloud(layer: CloudLayer, cl: Cloud?, me: Vector3, edge: boolean): Cloud?
	local zc = layer.zone.Clouds
	local seed = cloudRandom:NextInteger(1, 2147483000)
	local r = rng(seed)
	local size = layer.sizeMin + r() * (layer.sizeMax - layer.sizeMin)
	local boxes = cloudBoxes(r, 0, 0, 0, size, zc)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, b in boxes do
		local e = Vector3.new(b.sx, b.sy, b.sz) / 2
		lo = lo:Min(Vector3.new(b.x, b.y, b.z) - e)
		hi = hi:Max(Vector3.new(b.x, b.y, b.z) + e)
	end
	local half = (hi - lo) / 2
	local mid = (hi + lo) / 2
	for _ = 1, 8 do
		local a: number
		if edge then
			-- come in from upwind so clouds drift towards you
			local drift: Vector3 = zc.Drift
			a = math.atan2(-drift.Z, -drift.X) + cloudRandom:NextNumber(-1.1, 1.1)
		else
			a = cloudRandom:NextNumber(0, math.pi * 2)
		end
		local ring = zc.Ring
		local dist = if edge then cloudRandom:NextNumber(ring[2] * 0.85, ring[2]) else cloudRandom:NextNumber(ring[1], ring[2])
		local yLo, yHi = heightBand(zc, me.Y)
		local pos = Vector3.new(me.X + math.cos(a) * dist, cloudRandom:NextNumber(yLo, yHi), me.Z + math.sin(a) * dist)
		if freeSpot(layer, pos, half, cl) then
			if cl then
				for _, p in cl.parts do
					p:Destroy()
				end
			end
			local new: Cloud = cl or ({} :: any)
			new.parts, new.offs, new.sizes = {}, {}, {}
			for _, b in boxes do
				local p = newPart(b, layer.folder)
				p.Transparency = 1
				table.insert(new.parts, p)
				table.insert(new.offs, Vector3.new(b.x, b.y, b.z) - mid)
				table.insert(new.sizes, p.Size)
			end
			new.pos, new.half, new.alpha, new.shown, new.scale, new.fade, new.alive = pos, half, 0, 1, 1, 1, true
			return new
		end
	end
	return nil
end

local function stepClouds(dt: number, h: number, me: Vector3)
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for _, layer in layers do
		local zc = layer.zone.Clouds
		local want = h > zc.MinY - 250 and h < zc.MaxY + 250
		if want ~= layer.active then
			layer.active = want
			layer.folder.Parent = if want then root else nil
			if not want then
				-- left this layer: clear it, it fills up around you again when you come back
				for _, cl in layer.clouds do
					for _, p in cl.parts do
						p:Destroy()
					end
				end
				layer.clouds, layer.filled = {}, false
			end
		end
		if not want then
			continue
		end
		-- fill up to Count (a few per frame)
		local alive = 0
		for _, cl in layer.clouds do
			if cl.alive then
				alive += 1
			end
		end
		for _ = 1, 2 do
			if alive >= zc.Count then
				break
			end
			local cl = placeCloud(layer, nil, me, layer.filled)
			if cl then
				table.insert(layer.clouds, cl)
				alive += 1
			end
		end
		if alive >= zc.Count then
			layer.filled = true
		end
		local yLo, yHi = heightBand(zc, h)
		local drift: Vector3 = zc.Drift
		for i = #layer.clouds, 1, -1 do
			local cl = layer.clouds[i]
			cl.pos += drift * dt
			local flat = Vector3.new(cl.pos.X - me.X, 0, cl.pos.Z - me.Z).Magnitude
			local offBand = cl.pos.Y < yLo - 60 or cl.pos.Y > yHi + 60
			if cl.fade > 0 and (flat > zc.Ring[2] + 80 or offBand or hitsIsland(cl.pos + drift * 2, cl.half)) then
				cl.fade = -1 -- fade out, then move it
			end
			cl.alpha = math.clamp(cl.alpha + cl.fade * dt / 1.5, 0, 1)
			if cl.fade < 0 and cl.alpha <= 0 then
				local moved = placeCloud(layer, cl, me, true)
				if not moved then
					for _, p in cl.parts do
						p:Destroy()
					end
					table.remove(layer.clouds, i)
					continue
				end
			end
			cloudVisible(cl, cl.alpha)
			for j, p in cl.parts do
				table.insert(parts, p)
				table.insert(cframes, CFrame.new(cl.pos + cl.offs[j] * cl.scale))
			end
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- ---------------------------------------------------------------- the deck, the far floor and the towers

local deckFolder: Folder
local tiles: { [string]: Tile } = {}
local buildQueue: { { number } } = {}
local deckCenter: { number }? = nil
local towers: { Tower } = {}
local towersBuilt = false

local function setDeckActive(on: boolean)
	local want = if on then root else nil
	if deckFolder.Parent ~= want then
		deckFolder.Parent = want
	end
end

-- a far floor slab: the further out, the more it takes the haze colour; near the end more and more slabs drop out
-- (dist = from you in studs). Never see-through: a slab is shown or not.
local function farLook(tile: Tile, dist: number)
	local p = tile.inst
	if not p or not p:IsA("BasePart") then
		return
	end
	local k = math.clamp((dist - Deck.Radius) / (Deck.FarRadius - Deck.Radius), 0, 1)
	local brk = math.clamp((k - Deck.FarBreakUp) / (1 - Deck.FarBreakUp), 0, 1)
	local hv = rng(tileSeed(tile.ix, tile.iz) + 13)()
	p.Transparency = if hv > 1 - brk * (1 - Deck.FarCoverage) then 1 else 0
	p.Color = (Deck.Side :: Color3):Lerp(Deck.FarColor, smooth(k))
end

local function buildTowers()
	towersBuilt = true
	local folder = Instance.new("Folder")
	folder.Name = "CloudTowers"
	folder.Parent = deckFolder
	local t = Deck.Tile
	for i, tw in towers do
		local w = tw.n * t
		local model = Instance.new("Model")
		model.Name = "CloudTower"
		-- the bottom step starts inside the deck, so the tower grows out of the floor
		for _, b in towerBoxes(rng(31 + i * 977), tw.x, tw.z, Deck.Y - Deck.Thickness * 0.4, w) do
			newPart(b, model)
		end
		model.Parent = folder
	end
end

local function stepDeck(h: number, me: Vector3)
	local on = math.abs(h - Deck.Y) < Deck.ActiveRange
	setDeckActive(on)
	if not on then
		return
	end
	if not towersBuilt then
		buildTowers()
	end
	local t = Deck.Tile
	local cix, ciz = math.floor(me.X / t), math.floor(me.Z / t)
	if not deckCenter or deckCenter[1] ~= cix or deckCenter[2] ~= ciz then
		deckCenter = { cix, ciz }
		-- near tiles (with puffs) inside Radius, flat far slabs out to FarRadius.
		-- Drop what is too far or changed kind, update the far look, queue the new ones (nearest first).
		for key, tile in tiles do
			local dist = math.sqrt((tile.ix - cix) ^ 2 + (tile.iz - ciz) ^ 2) * t
			if dist > Deck.FarRadius or (dist > Deck.Radius) ~= tile.far then
				if tile.inst then
					tile.inst:Destroy()
				end
				tiles[key] = nil
			elseif tile.far then
				farLook(tile, dist)
			end
		end
		buildQueue = {}
		local nf = math.ceil(Deck.FarRadius / t)
		for ix = cix - nf, cix + nf do
			for iz = ciz - nf, ciz + nf do
				local dist = math.sqrt((ix - cix) ^ 2 + (iz - ciz) ^ 2) * t
				if dist <= Deck.FarRadius and tiles[ix .. "," .. iz] == nil then
					table.insert(buildQueue, { ix, iz, dist })
				end
			end
		end
		table.sort(buildQueue, function(a, b)
			return a[3] > b[3] -- pop from the end = nearest first
		end)
	end
	-- a near tile costs as much as FarBuildPerFrame / BuildPerFrame far slabs
	local budget = Deck.FarBuildPerFrame
	while budget > 0 do
		local q = table.remove(buildQueue)
		if not q then
			break
		end
		local far = q[3] > Deck.Radius
		budget -= if far then 1 else Deck.FarBuildPerFrame / Deck.BuildPerFrame
		local tile: Tile = { inst = nil, far = far, ix = q[1], iz = q[2] }
		local boxes = deckTile(q[1], q[2], far)
		if far and #boxes > 0 then
			local p = newPart(boxes[1], deckFolder)
			p.Name = "DeckFar"
			tile.inst = p
			farLook(tile, q[3])
		elseif #boxes > 0 then
			local model = Instance.new("Model")
			model.Name = "DeckTile"
			for _, b in boxes do
				newPart(b, model)
			end
			model.Parent = deckFolder
			tile.inst = model
		end
		tiles[q[1] .. "," .. q[2]] = tile
	end
end

-- ---------------------------------------------------------------- near bits

local bits: { Bit } = {}
local nearFolder: Folder
local spawnDebt: { [string]: number } = { petal = 0, pollen = 0, dust = 0 }

local function spawnBit(kind: string, me: Vector3)
	if #bits >= Cfg.Near.Max then
		return
	end
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	local a = math.random() * math.pi * 2
	local d = 6 + math.random() * 34
	local life = 7
	if kind == "petal" then
		local pc = Zones[1].Near.PetalColors
		p.Size = Vector3.new(0.7, 0.12, 0.5)
		p.Color = pc[math.random(1, #pc)]
	elseif kind == "pollen" then
		p.Size = Vector3.one * 0.22
		p.Color = Color3.fromHex("FFF07A")
		p.Material = Enum.Material.Neon
	else -- golden dust
		p.Size = Vector3.one * 0.3
		p.Color = Color3.fromHex("FFD66B")
		p.Material = Enum.Material.Neon
	end
	p.Transparency = 1
	p.CFrame = CFrame.new(me.X + math.cos(a) * d, me.Y - 20 + math.random() * 30, me.Z + math.sin(a) * d)
		* CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
	p.Parent = nearFolder
	table.insert(bits, {
		part = p,
		kind = kind,
		age = 0,
		life = life,
		vel = Vector3.new((math.random() - 0.3) * 2, 1.5 + math.random() * 2.5, (math.random() - 0.5) * 2),
		spin = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 4,
	})
end

local function stepNear(dt: number, h: number, me: Vector3)
	local k = upperK(h)
	local lo, hi = Zones[1].Near, Zones[2] and Zones[2].Near or Zones[1].Near
	local rates = {
		petal = (1 - k) * lo.Petals * 4,
		pollen = (1 - k) * lo.Pollen * 5,
		dust = k * hi.Dust * 6,
	}
	local onGround = h < 25
	for kind, rate in rates do
		spawnDebt[kind] += if onGround then 0 else rate * dt
		while spawnDebt[kind] >= 1 do
			spawnDebt[kind] -= 1
			spawnBit(kind, me)
		end
	end
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for i = #bits, 1, -1 do
		local b = bits[i]
		b.age += dt
		local f = b.age / b.life
		if f >= 1 then
			b.part:Destroy()
			table.remove(bits, i)
			continue
		end
		local cf = b.part.CFrame + b.vel * dt
		if b.kind == "petal" then
			cf *= CFrame.Angles(b.spin.X * dt, 0, b.spin.Z * dt)
			b.part.Transparency = math.max(0, 1 - math.sin(f * math.pi) * 1.2)
		elseif b.kind == "dust" then
			b.part.Transparency = 1 - math.sin(f * math.pi) * (0.6 + 0.4 * math.sin(b.age * 9))
		else
			b.part.Transparency = 1 - math.sin(f * math.pi)
		end
		table.insert(parts, b.part)
		table.insert(cframes, cf)
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- ---------------------------------------------------------------- punch-through

local lastPunch = 0

local function punch(up: boolean, me: Vector3)
	if os.clock() - lastPunch < 1.5 then
		return
	end
	lastPunch = os.clock()
	local dir = if up then 1 else -1
	local n = if up then 26 else 16
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local s = 3 + math.random() * 4
		local p = newPart({
			x = me.X + math.cos(a) * 4,
			y = Deck.Y + Deck.Thickness / 2 * dir,
			z = me.Z + math.sin(a) * 4,
			sx = s,
			sy = s,
			sz = s,
			c = if i % 3 == 0 then Color3.fromHex("FFF2D6") else Color3.new(1, 1, 1),
			top = false,
		}, root)
		local goal = p.Position + Vector3.new(math.cos(a) * 30, dir * (6 + math.random() * 10), math.sin(a) * 30)
		local tw = TweenService:Create(p, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = goal,
			Size = p.Size * 2.5,
			Transparency = 1,
		})
		tw.Completed:Connect(function()
			p:Destroy()
		end)
		tw:Play()
	end
	if up then
		flashCC.Brightness = Cfg.Punch.FlashBrightness
		TweenService:Create(flashCC, TweenInfo.new(Cfg.Punch.FlashTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	end
	if Sound and Sound.Play then
		Sound.Play(Cfg.Punch.Whoosh, { Pitch = Cfg.Punch.WhooshPitch * (if up then 1 else 0.85) })
	end
	ZoneLayerController.PunchThrough:Fire(up)
end

-- ---------------------------------------------------------------- public API

-- Weather (or anything else) on top of the zone look. values = Sky keys to move towards
-- (e.g. { AtmosDensity = 0.45, AtmosColor = Color3.fromHex("C8D2DC") }), weight 0..1, fades over fadeTime.
-- SetOverlay(id, nil) fades it out and removes it.
function ZoneLayerController.SetOverlay(id: string, values: { [string]: any }?, weight: number?, fadeTime: number?)
	local ov = overlays[id]
	local speed = 1 / math.max(fadeTime or 2, 0.01)
	if values then
		if not ov then
			ov = { values = values, weight = 0, target = weight or 1, speed = speed }
			overlays[id] = ov
			table.insert(overlayOrder, id)
		else
			ov.values, ov.target, ov.speed = values, weight or 1, speed
		end
	elseif ov then
		ov.target, ov.speed = 0, speed
	end
end

function ZoneLayerController.GetZoneAt(h: number): any
	return Zones[zoneAt(h)]
end

local function stepOverlays(dt: number)
	for i = #overlayOrder, 1, -1 do
		local id = overlayOrder[i]
		local ov = overlays[id]
		local d = ov.target - ov.weight
		ov.weight += math.clamp(d, -ov.speed * dt, ov.speed * dt)
		if ov.target == 0 and ov.weight <= 0 then
			overlays[id] = nil
			table.remove(overlayOrder, i)
		end
	end
end

export type StartOptions = { Shared: Instance, Sound: any? }

function ZoneLayerController.Start(opts: StartOptions)
	Cfg = require((opts.Shared :: any).Config.ZoneLayerConfig) :: any
	Sound = opts.Sound
	Zones = Cfg.Zones
	Deck = Cfg.Deck
	for key in Zones[1].Sky do
		table.insert(skyKeys, key)
	end

	root = Instance.new("Folder")
	root.Name = "ZoneLayers"
	root.Parent = Workspace
	deckFolder = Instance.new("Folder")
	deckFolder.Name = "CloudDeck"
	nearFolder = Instance.new("Folder")
	nearFolder.Name = "NearBits"
	nearFolder.Parent = root

	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	atmosphere = a :: Atmosphere
	local c = Lighting:FindFirstChild("ZoneLayerCC")
	if not c then
		c = Instance.new("ColorCorrectionEffect")
		c.Name = "ZoneLayerCC"
		c.Parent = Lighting
	end
	cc = c :: ColorCorrectionEffect
	flashCC = Instance.new("ColorCorrectionEffect")
	flashCC.Name = "ZoneLayerFlash"
	flashCC.Parent = Lighting
	skyObj = Lighting:FindFirstChildOfClass("Sky")
	local tc = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if not tc then
		tc = Instance.new("Clouds")
		tc.Parent = Workspace.Terrain
	end
	terrainClouds = tc

	readIslands(opts.Shared)
	-- the towers' tiles stay empty (the tower fills them); towers keep away from islands
	for _, tw in towerLayout() do
		local w = tw.n * Deck.Tile
		if not hitsIsland(Vector3.new(tw.x, Deck.Y + 200, tw.z), Vector3.new(w / 2, 220, w / 2)) then
			table.insert(towers, tw)
			for ix = tw.ix0, tw.ix0 + tw.n - 1 do
				for iz = tw.iz0, tw.iz0 + tw.n - 1 do
					towerTiles[ix .. "," .. iz] = true
				end
			end
		end
	end
	for _, z in Zones do
		if z.Clouds then
			local f = Instance.new("Folder")
			f.Name = z.Id .. "Clouds"
			local small = z.Clouds.Kind == "Cloudlets"
			table.insert(layers, {
				zone = z,
				clouds = {},
				active = false,
				filled = false,
				folder = f,
				sizeMin = if small then 14 else 26,
				sizeMax = if small then 28 else 52,
			})
		end
	end

	local h0 = myHeightAndPos()
	local zi = zoneAt(h0)
	ZoneLayerController.Zone = Zones[zi]
	local lastH = h0
	local islandTimer = 0

	RunService.RenderStepped:Connect(function(dt: number)
		local h, me = myHeightAndPos()
		stepOverlays(dt)
		applyLook(h)

		-- zone change (3 studs of slack so it doesn't flicker on the line)
		local cur = Zones[zi]
		if h >= cur.To + 3 or h < cur.From - 3 then
			local nz = zoneAt(h)
			if nz ~= zi then
				local old = Zones[zi]
				zi = nz
				ZoneLayerController.Zone = Zones[zi]
				ZoneLayerController.ZoneChanged:Fire(Zones[zi], old)
			end
		end

		if lastH < Deck.Y and h >= Deck.Y then
			punch(true, me)
		elseif lastH >= Deck.Y and h < Deck.Y and h > Deck.Y - 200 then
			punch(false, me)
		end
		lastH = h

		-- islands can be moved or added in Studio: read them again now and then
		islandTimer += dt
		if islandTimer > 10 then
			islandTimer = 0
			readIslands(opts.Shared)
		end

		stepDeck(h, me)
		stepClouds(dt, h, me)
		stepNear(dt, h, me)
	end)
end

return ZoneLayerController
