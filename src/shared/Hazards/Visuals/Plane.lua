--!strict
-- Plane (Meadow Sky) - signature attack: CREASE CUTTER
-- Glide -> unfold into a spinning sheet while a lime crease grid draws itself ->
-- refold into a razor dart -> square sonic rings + speed lines -> the cut splits in two.

local Hazards = script.Parent.Parent
local StudKit = require(Hazards.StudKit)
local VFX = require(Hazards.VFX)
local Ease = VFX.Ease

local Plane = {}

local WHITE = Color3.fromHex("FFFFFF")
local PAPER = Color3.fromHex("F4F7FF")
local FOLD = Color3.fromHex("B8C2D4")
local SMOOTH = Enum.Material.SmoothPlastic

-- sheet-space crease lines (unit square -1..1), like the origami grid on the concept board
local CREASES = {
	{ -1, -1, 1, 1 },
	{ 1, -1, -1, 1 },
	{ 0, -1, 0, 1 },
	{ -1, 0, 1, 0 },
	{ -1, -0.5, 0.5, 1 },
	{ 0.5, -1, -1, 0.5 },
}

function Plane.Build(cfg: any): StudKit.Rig
	local rig = StudKit.Rig("Plane", cfg)
	local P = StudKit.Part
	local wedge = { Shape = "Wedge", Material = SMOOTH, Studs = false }
	rig:Add("WingL", P(Vector3.new(0.08, 2.4, 6.4), WHITE, wedge), CFrame.new(-1.2, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), "paper")
	rig:Add("WingR", P(Vector3.new(0.08, 2.4, 6.4), WHITE, wedge), CFrame.new(1.2, 0, 0) * CFrame.Angles(0, 0, math.rad(-90)), "paper")
	rig:Add("KeelL", P(Vector3.new(0.08, 1.0, 6.4), FOLD, wedge), CFrame.new(-0.06, -0.5, 0) * CFrame.Angles(0, 0, math.pi), "paper")
	rig:Add("KeelR", P(Vector3.new(0.08, 1.0, 6.4), FOLD, wedge), CFrame.new(0.06, -0.5, 0) * CFrame.Angles(0, 0, math.pi), "paper")
	rig:Add("Crease", StudKit.Neon(Vector3.new(0.14, 0.14, 6.4), cfg.Color), CFrame.new(0, 0.05, 0), "paper")
	-- leading edges glow only while attacking
	local edgeLen = math.sqrt(2.4 ^ 2 + 6.4 ^ 2)
	rig:Add("EdgeL", StudKit.Neon(Vector3.new(0.1, 0.1, edgeLen), cfg.Color), CFrame.lookAt(Vector3.new(-1.2, 0.03, 0), Vector3.new(0, 0.03, -3.2)), "edge")
	rig:Add("EdgeR", StudKit.Neon(Vector3.new(0.1, 0.1, edgeLen), cfg.Color), CFrame.lookAt(Vector3.new(1.2, 0.03, 0), Vector3.new(0, 0.03, -3.2)), "edge")
	rig:Fade(1, "edge")

	local light = Instance.new("PointLight")
	light.Color = cfg.Color
	light.Brightness = 0.5
	light.Range = 9
	light.Parent = rig.parts.Crease.part
	rig.data.light = light

	Plane.Reset(rig)
	return rig
end

function Plane.Reset(rig: StudKit.Rig)
	rig.pose.sway = 1
	rig:Fade(0, "paper")
	rig:Fade(1, "edge")
	rig.data.light.Brightness = 0.5
end

function Plane.Animate(rig: StudKit.Rig, _dt: number)
	local t = rig.t
	local s = rig.pose.sway
	local base = rig.cf
		* CFrame.new(0, math.sin(t * 1.8) * 0.4 * s, 0)
		* CFrame.Angles(math.sin(t * 1.3) * 0.06 * s, 0, math.sin(t * 1.1) * 0.2 * s)
	for key in rig.parts do
		rig:Rest(key, base)
	end
	rig:Flush()
end

-- The cut: a hot slab along the flight line that splits into two drifting halves.
function Plane.Cut(pos: Vector3, dir: Vector3, up: Vector3, C: Color3, HOT: Color3)
	local cf = CFrame.lookAt(pos, pos + dir, up)
	local slab = VFX.Get(HOT)
	VFX.Run(0.22, function(a)
		local len = 26 * Ease.outExpo(math.min(a / 0.4, 1))
		slab.Size = Vector3.new(0.25, 1.4 * (1 - a * 0.5), math.max(len, 0.1))
		slab.CFrame = cf
		slab.Transparency = math.max(0, (a - 0.5) / 0.5)
		if a >= 1 then
			VFX.Release(slab)
		end
	end)
	task.delay(0.08, function()
		for _, sgn in { 1, -1 } do
			local half = VFX.Get(C)
			VFX.Run(0.6, function(a)
				local e = Ease.outCubic(a)
				half.Size = Vector3.new(0.18, 0.55, 26 * (1 - a * 0.2))
				half.CFrame = cf * CFrame.new(0, sgn * (0.35 + 3 * e), sgn * e * 1.5) * CFrame.Angles(sgn * e * 0.08, 0, sgn * e * 0.12)
				half.Transparency = a ^ 1.4
				if a >= 1 then
					VFX.Release(half)
				end
			end)
		end
	end)
end

function Plane.Attack(rig: StudKit.Rig, ctx: any)
	local cfg = ctx.cfg
	local C: Color3, HOT: Color3 = cfg.Color, cfg.Hot
	rig.follow = false
	local cf0 = rig.cf

	-- 1. GLIDE: straight line, like the spec's paper planes
	ctx:Add(VFX.Run(cfg.UnfoldAt, function(_, _, t)
		rig.cf = cf0 * CFrame.new(0, 0, -cfg.MoveSpeed * t)
	end))
	if not ctx:WaitUntil(cfg.UnfoldAt) then
		return
	end

	-- 2. UNFOLD: a spinning sheet with a lime crease grid drawing itself on
	local center = rig.cf.Position
	local sheet = ctx:Add(StudKit.Part(Vector3.new(6, 6, 0.1), PAPER, { Material = SMOOTH, Studs = false }))
	sheet.Parent = VFX.Folder
	local creases = {}
	for i = 1, #CREASES do
		local bar = ctx:Add(StudKit.Neon(Vector3.one * 0.1, C))
		bar.Parent = VFX.Folder
		creases[i] = bar
	end
	local state = { scale = 0.2, squash = 1, grow = 0, thick = 0.16, spin = 0, cf = CFrame.new(center) }
	local function drawSheet()
		local h = 3 * state.scale
		sheet.Size = Vector3.new(math.max(6 * state.scale * state.squash, 0.05), 6 * state.scale, 0.1)
		sheet.CFrame = state.cf
		for i, d in CREASES do
			local q0 = state.cf * Vector3.new(d[1] * h * state.squash, d[2] * h, -0.08)
			local q1 = state.cf * Vector3.new(d[3] * h * state.squash, d[4] * h, -0.08)
			VFX.SetBar(creases[i], q0, q0:Lerp(q1, state.grow), state.thick)
		end
	end
	VFX.Light(center, C, 3, 16, cfg.LockTime - cfg.UnfoldAt + 0.2)
	ctx:Add(VFX.Run(cfg.LockTime - cfg.UnfoldAt, function(a)
		local tpos = ctx:Target()
		state.scale = 0.2 + 0.8 * Ease.outBack(math.min(a / 0.6, 1))
		state.spin = a * math.pi * 2
		state.cf = CFrame.lookAt(center, tpos) * CFrame.Angles(math.sin(a * math.pi) * 0.6, 0, state.spin)
		state.grow = math.clamp((a - 0.15) / 0.6, 0, 1)
		rig:Fade(math.min(a / 0.15, 1), "paper")
		drawSheet()
	end))

	-- 3. REFOLD: the aim locks, the sheet collapses into a razor dart
	local lockPos: Vector3? = ctx:WaitLock()
	if not lockPos then
		return
	end
	local target: Vector3 = lockPos
	local p0: Vector3 = ctx.launchPos or center -- the server's launch point, so the cut matches its hit line
	local dir = target - p0
	dir = if dir.Magnitude > 0.1 then dir.Unit else rig.cf.LookVector
	local exit = target + dir * cfg.ExitDistance
	local aim = CFrame.lookAt(p0, p0 + dir)
	rig.cf = aim
	rig.pose.sway = 0
	state.thick = 0.32
	VFX.Star(p0, HOT, 8, 0.32)
	VFX.Light(p0, C, 6, 18, 0.3)
	ctx:Add(VFX.Run(cfg.LaunchAt - cfg.LockTime, function(a)
		state.squash = 1 - 0.92 * Ease.inQuad(math.min(a / 0.6, 1))
		state.cf = CFrame.lookAt(p0, target) * CFrame.Angles(0, 0, state.spin)
		drawSheet()
		local fadeSheet = math.max(0, (a - 0.5) / 0.5)
		sheet.Transparency = fadeSheet
		for _, c in creases do
			c.Transparency = fadeSheet
		end
		local show = 1 - math.clamp((a - 0.3) / 0.4, 0, 1)
		rig:Fade(show, "paper")
		rig:Fade(show, "edge")
	end))

	-- 4. LAUNCH: square sonic rings + stretched speed lines
	if not ctx:WaitUntil(cfg.LaunchAt) then
		return
	end
	sheet.Transparency = 1
	for _, c in creases do
		c.Transparency = 1
	end
	rig:Fade(0, "paper")
	rig:Fade(0, "edge")
	rig.data.light.Brightness = 3
	VFX.SquareRing(aim, C, 2.5, 9, 0.4, 0.3)
	task.delay(0.07, function()
		VFX.SquareRing(aim * CFrame.Angles(0, 0, math.rad(45)), HOT, 2, 7, 0.25, 0.3)
	end)
	local right = dir:Cross(Vector3.yAxis)
	right = if right.Magnitude > 0.01 then right.Unit else Vector3.xAxis
	local up = right:Cross(dir).Unit
	for k, off in { -1.4, -0.6, 0.6, 1.4 } do
		local bar = VFX.Get(if k % 2 == 0 then C else HOT)
		local o = right * off + up * (if k % 2 == 0 then 0.5 else -0.5)
		VFX.Run(0.38, function(a)
			local head = math.min(a / 0.45, 1)
			local tail = math.clamp((a - 0.3) / 0.7, 0, 1)
			VFX.SetBar(bar, (p0 + o):Lerp(exit + o, tail), (p0 + o):Lerp(exit + o, head), 0.12)
			bar.Transparency = a * a
			if a >= 1 then
				VFX.Release(bar)
			end
		end)
	end
	ctx:Add(VFX.Trail(rig.parts.Crease.part, C, 0.2, 2.4))
	ctx:Add(VFX.Run(cfg.HitTime - cfg.LaunchAt, function(a)
		local pos = p0:Lerp(target, Ease.inQuad(a))
		rig.cf = CFrame.lookAt(pos, pos + dir)
	end))

	-- 5. CUT
	if not ctx:WaitUntil(cfg.HitTime) then
		return
	end
	Plane.Cut(target, dir, up, C, HOT)
	VFX.Impact(target, C, HOT, { Scale = 0.8, Cubes = 20 })
	VFX.Cubes({ -- paper shreds
		Pos = target,
		Count = 26,
		Colors = { WHITE, PAPER, C },
		Speed = { 10, 26 },
		Size = { 0.6, 1.1 },
		Life = { 0.8, 1.4 },
		Gravity = -14,
		Drag = 2.5,
		Plate = true,
		Neon = false,
		Spin = 12,
	})
	ctx:Add(VFX.Run(cfg.Recover, function(a)
		local pos = target:Lerp(exit, Ease.outQuad(a))
		rig.cf = CFrame.lookAt(pos, pos + dir)
		rig:Fade(a, "edge")
	end))
	ctx:WaitUntil(cfg.HitTime + cfg.Recover)
end

return Plane
