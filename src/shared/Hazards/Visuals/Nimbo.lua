--!strict
-- Nimbo (Cloud Shelf) - signature attack: PIN DRIZZLE
-- Drift over -> soak (swell up, darken, suck in water cubes) -> mark a danger column
-- and three shrinking target squares -> rain Neon pins through the column -> wring out.

local Hazards = script.Parent.Parent
local StudKit = require(Hazards.StudKit)
local VFX = require(Hazards.VFX)
local Ease = VFX.Ease

local Nimbo = {}

local WHITE = Color3.fromHex("F7FAFF")
local SIDE = Color3.fromHex("EEF3FF")
local SHADE = Color3.fromHex("C3CFE8")
local INK = Color3.fromHex("1A2440")
local STORM = Color3.fromHex("7F8BA8")

function Nimbo.Build(cfg: any): StudKit.Rig
	local rig = StudKit.Rig("Nimbo", cfg)
	local P = StudKit.Part
	rig:Add("Core", P(Vector3.new(8, 3.2, 5), WHITE), CFrame.new(0, 0, 0), "cloud")
	rig:Add("PuffL", P(Vector3.new(3.6, 2.6, 4), WHITE), CFrame.new(-1.7, 2.3, 0.2), "cloud")
	rig:Add("PuffR", P(Vector3.new(4.2, 3, 4.2), WHITE), CFrame.new(1.6, 2.6, 0), "cloud")
	rig:Add("SideL", P(Vector3.new(2.4, 2.6, 3.6), SIDE), CFrame.new(-4.9, -0.2, 0.1), "cloud")
	rig:Add("SideR", P(Vector3.new(2.6, 2.8, 3.8), SIDE), CFrame.new(5, -0.1, 0), "cloud")
	rig:Add("Base", P(Vector3.new(8, 0.6, 5), SHADE, { Studs = false }), CFrame.new(0, -1.9, 0), "cloud")
	rig:Add("EyeL", StudKit.Neon(Vector3.new(0.9, 0.65, 0.12), cfg.Color), CFrame.new(-1.2, -0.2, -2.56))
	rig:Add("EyeR", StudKit.Neon(Vector3.new(0.9, 0.65, 0.12), cfg.Color), CFrame.new(1.2, -0.2, -2.56))
	rig:Add("BrowL", P(Vector3.new(1.3, 0.3, 0.12), INK, { Studs = false }), CFrame.new(-1.2, 0.5, -2.56) * CFrame.Angles(0, 0, math.rad(-18)))
	rig:Add("BrowR", P(Vector3.new(1.3, 0.3, 0.12), INK, { Studs = false }), CFrame.new(1.2, 0.5, -2.56) * CFrame.Angles(0, 0, math.rad(18)))
	rig:Add("Mouth", P(Vector3.new(1.3, 0.35, 0.12), INK, { Studs = false }), CFrame.new(0, -1.05, -2.56))
	-- pins stuck in its head (its ammo)
	local pins = {
		CFrame.new(-2, 3.4, 0) * CFrame.Angles(0, 0, math.rad(20)),
		CFrame.new(0.8, 4.2, 0) * CFrame.Angles(0, 0, math.rad(-8)),
		CFrame.new(3.2, 3.6, 0) * CFrame.Angles(0, 0, math.rad(-25)),
	}
	for i, pin in pins do
		rig:Add("Pin" .. i, P(Vector3.new(0.16, 2, 0.16), cfg.Hot, { Material = Enum.Material.SmoothPlastic, Studs = false }), pin * CFrame.new(0, 0.5, 0))
		rig:Add("PinHead" .. i, StudKit.Neon(Vector3.new(0.5, 0.5, 0.5), cfg.Color), pin * CFrame.new(0, 1.6, 0))
	end

	local light = Instance.new("PointLight")
	light.Color = cfg.Color
	light.Brightness = 0.8
	light.Range = 12
	light.Parent = rig.parts.Core.part
	rig.data.light = light

	Nimbo.Reset(rig)
	return rig
end

function Nimbo.Reset(rig: StudKit.Rig)
	rig.pose.bob = 1
	rig.pose.swell = 1
	rig.pose.gloom = 0
	rig.data.light.Brightness = 0.8
	rig:Tint(STORM, 0, "cloud")
end

function Nimbo.Animate(rig: StudKit.Rig, _dt: number)
	local p = rig.pose
	local t = rig.t
	rig.scale = p.swell * (1 + math.sin(t * 2.1) * 0.025)
	rig:ApplyScale()
	local base = rig.cf * CFrame.new(0, math.sin(t * 1.6) * 0.5 * p.bob, 0) * CFrame.Angles(0, 0, math.sin(t * 1.2) * 0.04)
	for key in rig.parts do
		rig:Rest(key, base)
	end
	rig:Flush()
end

function Nimbo.Attack(rig: StudKit.Rig, ctx: any)
	local cfg = ctx.cfg
	local C: Color3, HOT: Color3 = cfg.Color, cfg.Hot
	local p = rig.pose

	-- 1. DRIFT: keep following the server root until it's parked over the balloon
	if not ctx:WaitUntil(cfg.SoakAt) then
		return
	end
	rig.follow = false
	local center = rig.cf.Position

	-- 2. SOAK: swell to 1.25x, darken, suck in water cubes, eyes blaze
	local suckClock = 0
	ctx:Add(VFX.Run(cfg.LockTime - cfg.SoakAt, function(a, dt)
		p.swell = 1 + 0.25 * Ease.outBack(a)
		p.gloom = a
		rig:Tint(STORM, 0.55 * a, "cloud")
		rig.data.light.Brightness = 0.8 + 3.5 * a
		suckClock += dt
		while suckClock > 0.05 do
			suckClock -= 0.05
			VFX.Suck(center, 13, 3, { C, HOT }, 0.4, 0.5)
		end
	end))

	-- 3. MARK: danger column + three shrinking target squares locked on the drop zone
	local lockPos: Vector3? = ctx:WaitLock()
	if not lockPos then
		return
	end
	local target: Vector3 = lockPos
	local radius: number = cfg.HitRadius
	local bottom = center.Y - 2.2 * p.swell
	local depth: number = cfg.ColumnDepth
	local column = ctx:Add(StudKit.Neon(Vector3.new(radius * 2, depth, radius * 2), C))
	column.CFrame = CFrame.new(target.X, bottom - depth / 2, target.Z)
	column.Transparency = 1
	column.Parent = VFX.Folder
	local flat = CFrame.new(target) * CFrame.Angles(math.pi / 2, 0, 0)
	local squares = { ctx:Add(VFX.Frame(C)), ctx:Add(VFX.Frame(C)), ctx:Add(VFX.Frame(HOT)) }
	local cross = { ctx:Add(StudKit.Neon(Vector3.one, C)), ctx:Add(StudKit.Neon(Vector3.one, C)) }
	for _, b in cross do
		b.Parent = VFX.Folder
	end
	local markRun = ctx:Add(VFX.Run(math.huge, function()
		local t = ctx:Time()
		local since = t - cfg.LockTime
		local urgency = math.clamp(since / (cfg.HitTime - cfg.LockTime), 0, 1)
		local blinkRate = 8 + 22 * urgency
		local blink = if math.floor(t * blinkRate) % 2 == 0 then 0 else 0.55
		column.Transparency = 0.9 - 0.12 * urgency - (if blink == 0 then 0.04 else 0)
		for i, sq in squares do
			local delay = (i - 1) * 0.2
			local k = math.clamp((since - delay) / 0.25, 0, 1)
			local size = radius * 2 * (1 - (i - 1) * 0.25) * (1.7 - 0.7 * Ease.outBack(k))
			sq:Update(flat * CFrame.Angles(0, 0, (1 - k) * 0.8), size, 0.3, if k <= 0 then 1 else blink)
		end
		VFX.SetBar(cross[1], target - Vector3.xAxis * radius, target + Vector3.xAxis * radius, 0.15)
		VFX.SetBar(cross[2], target - Vector3.zAxis * radius, target + Vector3.zAxis * radius, 0.15)
		cross[1].Transparency = 0.3 + blink
		cross[2].Transparency = 0.3 + blink
	end))

	-- 4. DRIZZLE: Neon pins rain through the column
	if not ctx:WaitUntil(cfg.DrizzleAt) then
		return
	end
	local rng = VFX.Random
	local pinCount: number = cfg.PinCount
	local speed = 115
	for _ = 1, pinCount do
		task.delay(rng:NextNumber(0, 0.28), function()
			if ctx.cancelled then
				return
			end
			local x = target.X + rng:NextNumber(-radius, radius) * 0.9
			local z = target.Z + rng:NextNumber(-radius, radius) * 0.9
			local start = Vector3.new(x, bottom, z)
			local shaft = VFX.Get(HOT)
			local head = VFX.Get(C)
			shaft.Size = Vector3.new(0.14, 3.2, 0.14)
			head.Size = Vector3.new(0.42, 0.42, 0.42)
			local splashed = false
			local life = (depth + 6) / speed
			VFX.Run(life, function(_, _, t)
				local y = start.Y - speed * t
				local pos = Vector3.new(x, y, z)
				shaft.CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0))
				head.CFrame = CFrame.new(pos + Vector3.new(0, 3.3, 0))
				shaft.Transparency = 0.15
				head.Transparency = 0
				if not splashed and y <= target.Y then
					splashed = true
					for _ = 1, 3 do
						local d = VFX.RandUnit()
						VFX.Particle(Vector3.new(x, target.Y, z), { Color = C, Size = 0.3, Life = 0.3, Velocity = Vector3.new(d.X, math.abs(d.Y) * 0.6, d.Z) * 14, Gravity = -40 })
					end
				end
				if t >= life then
					VFX.Release(shaft)
					VFX.Release(head)
				end
			end)
		end)
	end
	ctx:Add(VFX.Run(cfg.HitTime - cfg.DrizzleAt, function(a)
		p.swell = 1.25 - 0.3 * Ease.inQuad(a)
	end))

	-- 5. HIT
	if not ctx:WaitUntil(cfg.HitTime) then
		return
	end
	markRun:Stop()
	column.Transparency = 1
	for _, sq in squares do
		sq:Destroy()
	end
	for _, b in cross do
		b.Transparency = 1
	end
	VFX.Impact(target, C, HOT, { Cubes = 40, Colors = { C, HOT, Color3.fromHex("8ADCFF") } })
	VFX.SquareRing(flat, C, 4, radius * 3.2, 0.5, 0.5)

	-- 6. WRING: bounce back to size, colour returns, a few wisps float off
	if not ctx:WaitUntil(cfg.WringAt) then
		return
	end
	VFX.Cubes({
		Pos = center,
		Count = 10,
		Colors = { WHITE, SIDE },
		Speed = { 2, 5 },
		Size = { 0.6, 1.1 },
		Life = { 0.8, 1.3 },
		Gravity = 4,
		Dir = Vector3.yAxis,
		Spread = 0.9,
		Neon = false,
		Offset = 3,
	})
	ctx:Add(VFX.Run(cfg.HitTime + cfg.Recover - cfg.WringAt, function(a)
		local e = Ease.outElastic(a)
		p.swell = 0.95 + 0.05 * e
		rig:Tint(STORM, 0.55 * (1 - a), "cloud")
		rig.data.light.Brightness = 4.3 - 3.5 * a
	end))
	ctx:WaitUntil(cfg.HitTime + cfg.Recover)
end

return Nimbo
