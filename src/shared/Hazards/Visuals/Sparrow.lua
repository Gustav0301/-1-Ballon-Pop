--!strict
-- Sparrow (Meadow Sky) - signature attack: CORKSCREW DIVE
-- Lock-on reticle -> beak glint -> wings tuck -> barrel-roll dive through the balloon,
-- drilling a helix of yellow Neon cubes and three square drill rings -> hit burst -> pull-through.

local Hazards = script.Parent.Parent
local StudKit = require(Hazards.StudKit)
local VFX = require(Hazards.VFX)
local Ease = VFX.Ease

local Sparrow = {}

local BROWN = Color3.fromHex("C8742A")
local DARK = Color3.fromHex("8A4A18")
local CREAM = Color3.fromHex("F2D7A6")
local INK = Color3.fromHex("141414")

local STATIC = { "Body", "Belly", "Head", "Cap", "Beak", "EyeL", "EyeR", "Tail", "FootL", "FootR" }

function Sparrow.Build(cfg: any): StudKit.Rig
	local rig = StudKit.Rig("Sparrow", cfg)
	local P = StudKit.Part
	rig:Add("Body", P(Vector3.new(2.6, 2.4, 3.4), BROWN), CFrame.new(0, 0, 0))
	rig:Add("Belly", P(Vector3.new(2.2, 1, 2.6), CREAM), CFrame.new(0, -0.8, -0.2))
	rig:Add("Head", P(Vector3.new(2.2, 2.2, 2.2), BROWN), CFrame.new(0, 0.9, -2.3))
	rig:Add("Cap", P(Vector3.new(2.3, 0.5, 2.3), DARK), CFrame.new(0, 2.05, -2.3))
	rig:Add("Beak", P(Vector3.new(0.9, 0.8, 1.3), cfg.Color, { Shape = "Wedge", Studs = false }), CFrame.new(0, 0.75, -4.05))
	rig:Add("EyeL", P(Vector3.new(0.12, 0.45, 0.45), INK, { Studs = false }), CFrame.new(-1.12, 1.15, -2.9))
	rig:Add("EyeR", P(Vector3.new(0.12, 0.45, 0.45), INK, { Studs = false }), CFrame.new(1.12, 1.15, -2.9))
	rig:Add("Tail", P(Vector3.new(1.8, 0.3, 1.8), DARK), CFrame.new(0, 0.5, 2.4) * CFrame.Angles(math.rad(20), 0, 0))
	rig:Add("FootL", P(Vector3.new(0.3, 0.7, 0.3), cfg.Deep, { Studs = false }), CFrame.new(-0.6, -1.5, 0.2))
	rig:Add("FootR", P(Vector3.new(0.3, 0.7, 0.3), cfg.Deep, { Studs = false }), CFrame.new(0.6, -1.5, 0.2))
	rig:Add("WingL", P(Vector3.new(2.6, 0.3, 1.9), DARK), nil, "wings")
	rig:Add("WingR", P(Vector3.new(2.6, 0.3, 1.9), DARK), nil, "wings")

	local light = Instance.new("PointLight")
	light.Color = cfg.Color
	light.Brightness = 0.6
	light.Range = 10
	light.Parent = rig.parts.Body.part
	rig.data.light = light

	Sparrow.Reset(rig)
	return rig
end

function Sparrow.Reset(rig: StudKit.Rig)
	rig.pose.bob = 1
	rig.pose.pitch = 0
	rig.pose.roll = 0
	rig.pose.tuck = 0
	rig.data.light.Brightness = 0.6
end

function Sparrow.Animate(rig: StudKit.Rig, _dt: number)
	local p = rig.pose
	local t = rig.t
	local bob = math.sin(t * 4.2) * p.bob
	local base = rig.cf * CFrame.new(0, bob * 0.35, 0) * CFrame.Angles(p.pitch + bob * 0.05, 0, p.roll)
	for _, key in STATIC do
		rig:Rest(key, base)
	end
	local flap = math.sin(t * 20) * 0.75 * (1 - p.tuck)
	local fold = p.tuck
	rig:Set("WingL", base * CFrame.new(-1.2, 0.6, -0.3) * CFrame.Angles(0, fold * 0.9, -flap + fold * 0.25) * CFrame.new(-1.3, 0, 0))
	rig:Set("WingR", base * CFrame.new(1.2, 0.6, -0.3) * CFrame.Angles(0, -fold * 0.9, flap - fold * 0.25) * CFrame.new(1.3, 0, 0))
	rig:Flush()
end

function Sparrow.Attack(rig: StudKit.Rig, ctx: any)
	local cfg = ctx.cfg
	local C: Color3, HOT: Color3 = cfg.Color, cfg.Hot
	rig.follow = false
	local start = rig.cf

	-- 1. LOCK-ON: corner-bracket reticle snaps onto the balloon, a stream of cubes marks the line
	local reticle = ctx:Add(VFX.Frame(C, true))
	local dots = {}
	for i = 1, 10 do
		dots[i] = ctx:Add(StudKit.Neon(Vector3.one * 0.4, C))
		dots[i].Parent = VFX.Folder
	end
	ctx:Add(VFX.Run(math.huge, function()
		local t = ctx:Time()
		local tpos: Vector3, r: number = ctx:Target()
		local a = math.clamp(t / cfg.LockTime, 0, 1)
		local e = Ease.outBack(a)
		local cam = workspace.CurrentCamera
		local face = if cam then CFrame.lookAt(tpos, cam.CFrame.Position) else CFrame.new(tpos)
		local size = (r * 2 + 3) * (2.2 - 1.2 * e)
		local tr = 0
		if t >= cfg.HitTime then
			tr = 1
		elseif ctx.lockPos then
			tr = if math.floor(t * 16) % 2 == 0 then 0 else 0.65
		end
		reticle:Update(face * CFrame.Angles(0, 0, (1 - e) * math.pi / 4), size, 0.35, tr)
		local from = rig.cf.Position
		for i, d in dots do
			local f = ((i - 1) / #dots + t * 1.2) % 1
			d.CFrame = CFrame.new(from:Lerp(tpos, f)) * CFrame.Angles(t * 3, t * 2, 0)
			d.Transparency = if t < cfg.DiveStart then 0.25 + 0.6 * f else 1
		end
	end))
	-- rear back while aiming
	ctx:Add(VFX.Run(cfg.LockTime, function(a)
		local e = Ease.outQuad(a)
		rig.cf = start * CFrame.new(0, 1.2 * e, 1.8 * e)
		rig.data.light.Brightness = 0.6 + 2.5 * a
	end))

	-- 2. TUCK: beak glint, wings fold, swing onto the locked dive line
	if not ctx:WaitUntil(cfg.LockTime - 0.08) then
		return
	end
	local beak = rig.parts.Beak.part
	VFX.Star(beak.Position + rig.cf.LookVector * 0.8, HOT, 4, 0.3)
	VFX.Light(beak.Position, C, 6, 14, 0.3)

	local lockPos: Vector3? = ctx:WaitLock()
	if not lockPos then
		return
	end
	local target: Vector3 = lockPos
	local p0 = rig.cf.Position
	local dir = target - p0
	dir = if dir.Magnitude > 0.1 then dir.Unit else rig.cf.LookVector
	local exit = target + dir * cfg.ExitDistance
	local tuckFrom = rig.cf
	local aim = CFrame.lookAt(p0 - dir * 1.5, target)
	ctx:Add(VFX.Run(cfg.DiveStart - cfg.LockTime, function(a)
		local e = Ease.inOutSine(a)
		rig.pose.tuck = e
		rig.pose.bob = 1 - e
		rig.cf = tuckFrom:Lerp(aim, e)
	end))

	-- 3. CORKSCREW: barrel-roll down the line, drilling a helix of cubes + square rings
	if not ctx:WaitUntil(cfg.DiveStart) then
		return
	end
	local diveFrom = rig.cf.Position
	ctx:Add(VFX.Trail(rig.parts.WingL.part, C, 0.22, 1.2))
	ctx:Add(VFX.Trail(rig.parts.WingR.part, HOT, 0.22, 1.2))
	local right = dir:Cross(Vector3.yAxis)
	right = if right.Magnitude > 0.01 then right.Unit else Vector3.xAxis
	local up = right:Cross(dir).Unit
	local ringsAt = { 0.28, 0.55, 0.8 }
	local ringI = 1
	local laid = 0
	local step = 0.85
	ctx:Add(VFX.Run(cfg.HitTime - cfg.DiveStart, function(a)
		local e = a * a
		local pos = diveFrom:Lerp(target, e)
		rig.pose.roll = e * math.pi * 6
		rig.cf = CFrame.lookAt(pos, pos + dir)
		local dist = (pos - diveFrom).Magnitude
		while laid < dist do
			laid += step
			local ph = laid * 0.95
			local hp = diveFrom + dir * laid + (right * math.cos(ph) + up * math.sin(ph)) * 1.7
			local even = math.floor(laid / step) % 2 == 0
			VFX.Particle(hp, { Color = if even then C else HOT, Size = if even then 0.55 else 0.75, Life = 0.55, Pop = true, Spin = 8 })
		end
		while ringsAt[ringI] and e >= ringsAt[ringI] do
			local rp = diveFrom:Lerp(target, ringsAt[ringI])
			VFX.SquareRing(CFrame.lookAt(rp, rp + dir) * CFrame.Angles(0, 0, ringI * 0.4), C, 2.5, 8, 0.3, 0.4)
			ringI += 1
		end
	end))

	-- 4. HIT
	if not ctx:WaitUntil(cfg.HitTime) then
		return
	end
	VFX.Impact(target, C, HOT, { Colors = { C, HOT, Color3.fromHex("FFB000") }, Cubes = 40 })
	VFX.Cubes({ -- feather studs
		Pos = target,
		Count = 10,
		Colors = { BROWN, DARK, CREAM },
		Speed = { 6, 14 },
		Size = { 0.4, 0.7 },
		Life = { 0.9, 1.4 },
		Gravity = -26,
		Drag = 2,
		Neon = false,
		Plate = true,
	})

	-- 5. PULL-THROUGH: carry on past the balloon, roll out and level off
	ctx:Add(VFX.Run(cfg.Recover, function(a)
		local e = Ease.outQuad(a)
		local pos = target:Lerp(exit, e)
		rig.pose.roll = math.pi * 6 + e * math.pi * 2
		rig.pose.tuck = 1 - e
		rig.cf = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(e * 0.5, 0, 0)
	end))
	ctx:WaitUntil(cfg.HitTime + cfg.Recover)
end

return Sparrow
