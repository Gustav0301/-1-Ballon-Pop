--!strict
-- Pinwheel (Cloud Shelf) - signature attack: SAW BLOOM
-- Spin-up with flung cube sparks -> 4 vanes detach and bloom out in a spiral around the
-- balloon -> clamp at 4 points with a flashing square frame -> snap shut through the
-- middle in a + cross -> vanes boomerang home.

local Hazards = script.Parent.Parent
local StudKit = require(Hazards.StudKit)
local VFX = require(Hazards.VFX)
local Ease = VFX.Ease

local Pinwheel = {}

local R = 3.2 -- vane length
local H = 2.6 -- vane height
local VANE_COLORS = {
	Color3.fromHex("FF3FD0"),
	Color3.fromHex("FFD0F5"),
	Color3.fromHex("C21E9E"),
	Color3.fromHex("FF8AE6"),
}
local ROT_Y = CFrame.Angles(0, math.pi / 2, 0)
local EDGE_ROT = CFrame.Angles(0, 0, math.atan2(H, R))
local EDGE_LEN = math.sqrt(R * R + H * H)
-- vane placed on the hub (triangle corners at (0,0), (R,0), (R,H) in the hub plane)
local VANE_OFF = CFrame.new(R / 2, H / 2, -0.55) * ROT_Y
local EDGE_OFF = CFrame.new(R / 2, H / 2, -0.66) * EDGE_ROT
-- the same, but pivoting on the triangle's centroid (for free flight)
local CENT = Vector3.new(2 * R / 3, H / 3, 0)
local FLY_VANE = CFrame.new(R / 2 - CENT.X, H / 2 - CENT.Y, 0) * ROT_Y
local FLY_EDGE = CFrame.new(R / 2 - CENT.X, H / 2 - CENT.Y, -0.11) * EDGE_ROT
-- angle from the centroid to the sharp tip at (0,0): the vane leads with it
local TIP_ANGLE = math.atan2(-CENT.Y, -CENT.X)

local STATIC = { "Stick", "Hub", "HubTop", "EyeL", "EyeR", "Mouth" }

function Pinwheel.Build(cfg: any): StudKit.Rig
	local rig = StudKit.Rig("Pinwheel", cfg)
	local P = StudKit.Part
	rig:Add("Stick", P(Vector3.new(0.5, 6, 0.5), Color3.fromHex("8A5A2E")), CFrame.new(0, -3.7, 0.3))
	rig:Add("Hub", P(Vector3.new(1.8, 1.8, 0.9), Color3.fromHex("FFFFFF")), CFrame.new(0, 0, -0.2))
	rig:Add("HubTop", P(Vector3.new(1.1, 0.35, 0.6), Color3.fromHex("F1E6F0")), CFrame.new(0, 1.07, -0.2))
	rig:Add("EyeL", P(Vector3.new(0.45, 0.28, 0.1), Color3.fromHex("2A0A24"), { Studs = false }), CFrame.new(-0.4, 0.22, -0.7) * CFrame.Angles(0, 0, math.rad(-15)))
	rig:Add("EyeR", P(Vector3.new(0.45, 0.28, 0.1), Color3.fromHex("2A0A24"), { Studs = false }), CFrame.new(0.4, 0.22, -0.7) * CFrame.Angles(0, 0, math.rad(15)))
	rig:Add("Mouth", StudKit.Neon(Vector3.new(0.9, 0.2, 0.1), cfg.Color), CFrame.new(0, -0.35, -0.7))
	for i = 0, 3 do
		rig:Add("Vane" .. i, P(Vector3.new(0.18, H, R), VANE_COLORS[i + 1], { Shape = "Wedge", Material = Enum.Material.SmoothPlastic, Studs = false }), nil, "vanes")
		rig:Add("Edge" .. i, StudKit.Neon(Vector3.new(EDGE_LEN, 0.12, 0.12), cfg.Color), nil, "vanes")
	end

	local light = Instance.new("PointLight")
	light.Color = cfg.Color
	light.Brightness = 0.7
	light.Range = 11
	light.Parent = rig.parts.Hub.part
	rig.data.light = light

	Pinwheel.Reset(rig)
	return rig
end

function Pinwheel.Reset(rig: StudKit.Rig)
	rig.pose.spin = rig.pose.spin or 0
	rig.pose.spinSpeed = 4
	rig.pose.shake = 0
	rig:Fade(0, "vanes")
	rig.data.light.Brightness = 0.7
end

-- world CFrame of the hub (after sway and shake)
local function hubCF(rig: StudKit.Rig): CFrame
	local t = rig.t
	local sh = rig.pose.shake
	local jitter = if sh > 0
		then Vector3.new(VFX.Random:NextNumber(-sh, sh), VFX.Random:NextNumber(-sh, sh), 0)
		else Vector3.zero
	return rig.cf * CFrame.new(Vector3.new(0, math.sin(t * 2) * 0.35, 0) + jitter) * CFrame.Angles(0, 0, math.sin(t * 1.7) * 0.08)
end

function Pinwheel.Animate(rig: StudKit.Rig, dt: number)
	local p = rig.pose
	p.spin += p.spinSpeed * dt
	local base = hubCF(rig)
	rig.data.hub = base
	for _, key in STATIC do
		rig:Rest(key, base)
	end
	for i = 0, 3 do
		local spoke = base * CFrame.Angles(0, 0, p.spin + i * math.pi / 2)
		rig:Set("Vane" .. i, spoke * VANE_OFF)
		rig:Set("Edge" .. i, spoke * EDGE_OFF)
	end
	rig:Flush()
end

type Flyer = { vane: BasePart, edge: BasePart, pos: Vector3, spin: number }

function Pinwheel.Attack(rig: StudKit.Rig, ctx: any)
	local cfg = ctx.cfg
	local C: Color3, HOT: Color3 = cfg.Color, cfg.Hot
	rig.follow = false
	local p = rig.pose

	-- 1. SPIN-UP: faster and faster, shaking, flinging cube sparks off the tips; a whirl frame forms
	local whirl = ctx:Add(VFX.Frame(C))
	local sparkClock = 0
	ctx:Add(VFX.Run(cfg.BloomAt, function(a, dt)
		local e = Ease.inQuad(a)
		p.spinSpeed = 4 + 40 * e
		p.shake = 0.18 * e
		rig.data.light.Brightness = 0.7 + 4 * e
		local hub: CFrame = rig.data.hub or rig.cf
		whirl:Update(hub * CFrame.Angles(0, 0, p.spin * 0.25), 7 + 2 * e, 0.22, 1 - 0.8 * e)
		sparkClock += dt
		while sparkClock > 0.035 do
			sparkClock -= 0.035
			local i = VFX.Random:NextInteger(0, 3)
			local ang = p.spin + i * math.pi / 2
			local tipLocal = Vector3.new(math.cos(ang) * R - math.sin(ang) * H, math.sin(ang) * R + math.cos(ang) * H, -0.6)
			local tip = hub * tipLocal
			local tangent = hub:VectorToWorldSpace(Vector3.new(-math.sin(ang), math.cos(ang), 0))
			VFX.Particle(tip, { Color = if i % 2 == 0 then C else HOT, Size = 0.35, Life = 0.35, Velocity = tangent * (10 + 20 * e), Drag = 3 })
		end
	end))
	if not ctx:WaitUntil(cfg.BloomAt) then
		return
	end
	whirl:Destroy()

	-- 2. BLOOM: vanes detach and spiral out to 4 points around the balloon
	local hub: CFrame = rig.data.hub or rig.cf
	local hubPos = hub.Position
	rig:Fade(1, "vanes")
	p.shake = 0
	p.spinSpeed = 2
	VFX.Cubes({ Pos = hubPos, Count = 16, Colors = { C, HOT }, Speed = { 12, 24 }, Size = { 0.3, 0.6 }, Life = { 0.3, 0.5 }, Drag = 4, Neon = true })

	local function frameAt(from: Vector3, to: Vector3): CFrame
		local fwd = to - from
		fwd = if fwd.Magnitude > 0.1 then fwd.Unit else hub.LookVector
		local right = fwd:Cross(Vector3.yAxis)
		right = if right.Magnitude > 0.01 then right.Unit else Vector3.xAxis
		local upP = right:Cross(fwd).Unit
		return CFrame.fromMatrix(Vector3.zero, right, upP)
	end

	local flyers: { Flyer } = {}
	for i = 0, 3 do
		local vane = ctx:Add(rig.parts["Vane" .. i].part:Clone())
		local edge = ctx:Add(rig.parts["Edge" .. i].part:Clone())
		vane.Transparency = 0
		edge.Transparency = 0
		vane.Parent = VFX.Folder
		edge.Parent = VFX.Folder
		ctx:Add(VFX.Trail(edge, C, 0.35, 1.4))
		local ang = p.spin + i * math.pi / 2
		local startPos = hub * Vector3.new(math.cos(ang) * CENT.X - math.sin(ang) * CENT.Y, math.sin(ang) * CENT.X + math.cos(ang) * CENT.Y, -0.55)
		flyers[i + 1] = { vane = vane, edge = edge, pos = startPos, spin = ang }
	end

	local function place(f: Flyer, rot: CFrame)
		local cf = CFrame.new(f.pos) * rot * CFrame.Angles(0, 0, f.spin)
		f.vane.CFrame = cf * FLY_VANE
		f.edge.CFrame = cf * FLY_EDGE
	end

	local starts = {}
	for i, f in flyers do
		starts[i] = { pos = f.pos, spin = f.spin }
	end
	local clampR: number = cfg.ClampRadius
	local function clampSpot(i: number, center: Vector3, rot: CFrame): (Vector3, number)
		local th = (i - 1) * math.pi / 2
		local dirW = rot:VectorToWorldSpace(Vector3.new(math.cos(th), math.sin(th), 0))
		local spin = (th + math.pi) - TIP_ANGLE
		return center + dirW * clampR, spin
	end

	ctx:Add(VFX.Run(cfg.LockTime - cfg.BloomAt, function(a)
		local e = Ease.outCubic(a)
		local center: Vector3 = ctx:Target()
		local rot = frameAt(hubPos, center)
		for i, f in flyers do
			local goal, goalSpin = clampSpot(i, center, rot)
			local th = (i - 1) * math.pi / 2
			local swirl = rot:VectorToWorldSpace(Vector3.new(math.cos(th + 1.2), math.sin(th + 1.2), 0))
			local ctrl = starts[i].pos:Lerp(goal, 0.5) + swirl * 10
			local q0 = starts[i].pos:Lerp(ctrl, e)
			local q1 = ctrl:Lerp(goal, e)
			f.pos = q0:Lerp(q1, e)
			f.spin = starts[i].spin + (goalSpin + math.pi * 4 - starts[i].spin) * e
			place(f, rot)
		end
	end))

	-- 3. CLAMP: lock at 4 points, aim inward, flashing square frame + aim dots
	local lockPos: Vector3? = ctx:WaitLock()
	if not lockPos then
		return
	end
	local target: Vector3 = lockPos
	local rot = frameAt(hubPos, target)
	local clampPos = {}
	local clampSpin = {}
	for i = 1, 4 do
		clampPos[i], clampSpin[i] = clampSpot(i, target, rot)
	end
	local frame = ctx:Add(VFX.Frame(C))
	local aimDots = {}
	for i = 1, 12 do
		local d = ctx:Add(StudKit.Neon(Vector3.one * 0.35, HOT))
		d.Parent = VFX.Folder
		aimDots[i] = d
	end
	local clampRun = ctx:Add(VFX.Run(math.huge, function(_, _, t)
		local blink = if math.floor(t * 18) % 2 == 0 then 0 else 0.7
		frame:Update(CFrame.new(target) * rot, clampR * 2, 0.3, blink)
		for i, f in flyers do
			local pulse = math.sin(t * 40) * 0.12
			f.pos = clampPos[i] + (clampPos[i] - target).Unit * pulse
			f.spin = clampSpin[i]
			place(f, rot)
		end
		for k, d in aimDots do
			local lane = (k - 1) % 4 + 1
			local step = math.floor((k - 1) / 4)
			local fr = ((step / 3) + t * 2.5) % 1
			d.CFrame = CFrame.new(clampPos[lane]:Lerp(target, fr))
			d.Transparency = blink * 0.5 + fr * 0.4
		end
	end))
	VFX.Light(target, C, 3, 18, cfg.SnapAt - cfg.LockTime)

	-- 4. SNAP: the vanes slam through the middle
	if not ctx:WaitUntil(cfg.SnapAt) then
		return
	end
	clampRun:Stop()
	frame:Destroy()
	for _, d in aimDots do
		d.Transparency = 1
	end
	ctx:Add(VFX.Run(cfg.HitTime - cfg.SnapAt, function(a)
		local e = Ease.inQuad(a)
		for i, f in flyers do
			local through = target + (target - clampPos[i]).Unit * 2.5
			f.pos = clampPos[i]:Lerp(through, e)
			place(f, rot)
		end
	end))
	if not ctx:WaitUntil(cfg.HitTime) then
		return
	end
	-- + cross flash
	for _, axis in { Vector3.xAxis, Vector3.yAxis } do
		local bar = VFX.Get(HOT)
		local along = rot:VectorToWorldSpace(axis)
		VFX.Run(0.4, function(a)
			local grow = Ease.outExpo(math.min(a / 0.25, 1))
			local half = (clampR + 4) * grow
			VFX.SetBar(bar, target - along * half, target + along * half, 0.9 * (1 - a) + 0.05)
			bar.Transparency = a ^ 1.5
			if a >= 1 then
				VFX.Release(bar)
			end
		end)
	end
	VFX.Impact(target, C, HOT, { Cubes = 46, Colors = { C, HOT, VANE_COLORS[4] } })

	-- 5. RETURN: vanes boomerang home and snap back onto the hub
	if not ctx:WaitUntil(cfg.ReturnAt) then
		return
	end
	local from = {}
	for i, f in flyers do
		from[i] = { pos = f.pos, spin = f.spin }
	end
	local backT = cfg.HitTime + cfg.Recover - cfg.ReturnAt
	ctx:Add(VFX.Run(backT, function(a)
		local e = Ease.inOutSine(a)
		local home: CFrame = rig.data.hub or rig.cf
		for i, f in flyers do
			local ang = p.spin + (i - 1) * math.pi / 2
			local goal = home * Vector3.new(math.cos(ang) * CENT.X - math.sin(ang) * CENT.Y, math.sin(ang) * CENT.X + math.cos(ang) * CENT.Y, -0.55)
			local th = (i - 1) * math.pi / 2
			local ctrl = from[i].pos:Lerp(goal, 0.5) + rot:VectorToWorldSpace(Vector3.new(math.cos(th - 1.2), math.sin(th - 1.2), 0)) * 8
			f.pos = from[i].pos:Lerp(ctrl, e):Lerp(ctrl:Lerp(goal, e), e)
			f.spin = from[i].spin + math.pi * 6 * e
			place(f, rot)
		end
	end))
	ctx:WaitUntil(cfg.HitTime + cfg.Recover)
	VFX.Sparkles((rig.data.hub or rig.cf).Position, C, 16, 12)
end

return Pinwheel
