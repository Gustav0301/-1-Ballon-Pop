--!strict
-- VFX: client-side effect toolkit for hazards, in the game's stud style.
-- Everything is built from Neon/Plastic Parts, Trails and PointLights, so it needs
-- no uploaded textures and imports into any place 1:1. Particles are real little
-- cubes and plates (section 14 of the game prompt: "square confetti, cube sparkles").
--
-- The controller calls VFX.Step(dt) once per RenderStepped. Only require this on clients.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local StudKit = require(script.Parent.StudKit)

local VFX = {}

VFX.Folder = nil :: Instance?
VFX.ShakeDistance = 70
VFX.MaxParticles = 450

local rng = Random.new()
VFX.Random = rng

--------------------------------------------------------------------------------
-- Easing

local Ease = {}
function Ease.linear(a: number): number
	return a
end
function Ease.inQuad(a: number): number
	return a * a
end
function Ease.outQuad(a: number): number
	return 1 - (1 - a) * (1 - a)
end
function Ease.inCubic(a: number): number
	return a * a * a
end
function Ease.outCubic(a: number): number
	return 1 - (1 - a) ^ 3
end
function Ease.inOutSine(a: number): number
	return -(math.cos(math.pi * a) - 1) / 2
end
function Ease.outBack(a: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (a - 1) ^ 3 + c1 * (a - 1) ^ 2
end
function Ease.outExpo(a: number): number
	return if a >= 1 then 1 else 1 - 2 ^ (-10 * a)
end
function Ease.outElastic(a: number): number
	if a <= 0 or a >= 1 then
		return a
	end
	local c4 = (2 * math.pi) / 3
	return 2 ^ (-10 * a) * math.sin((a * 10 - 0.75) * c4) + 1
end
VFX.Ease = Ease

--------------------------------------------------------------------------------
-- Runners: per-frame callbacks with a duration. fn(alpha, dt, elapsed).

export type Runner = {
	t: number,
	d: number,
	fn: (number, number, number) -> (),
	alive: boolean,
	Stop: (Runner) -> (),
}

local runners: { Runner } = {}

local function stopRunner(self: Runner)
	self.alive = false
end

function VFX.Run(duration: number, fn: (number, number, number) -> ()): Runner
	local r: Runner = { t = 0, d = duration, fn = fn, alive = true, Stop = stopRunner }
	table.insert(runners, r)
	return r
end

--------------------------------------------------------------------------------
-- Part pool

local pool: { BasePart } = {}

local function parent(): Instance
	return VFX.Folder or workspace
end

function VFX.Get(color: Color3, neon: boolean?): BasePart
	local p: BasePart = table.remove(pool) or StudKit.Neon(Vector3.one, color, "FX")
	p.Color = color
	p.Material = if neon == false then Enum.Material.SmoothPlastic else Enum.Material.Neon
	p.Transparency = 1 -- hidden until its first update places it
	p.Parent = parent()
	return p
end

function VFX.Release(p: BasePart)
	p.Parent = nil
	if #pool < 400 then
		table.insert(pool, p)
	else
		p:Destroy()
	end
end

function VFX.SetBar(part: BasePart, p0: Vector3, p1: Vector3, thick: number, tall: number?)
	local d = p1 - p0
	local len = d.Magnitude
	part.Size = Vector3.new(thick, tall or thick, math.max(len, 0.05))
	if len < 1e-3 then
		part.CFrame = CFrame.new(p0)
	else
		part.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
	end
end

--------------------------------------------------------------------------------
-- Cube particles

type Particle = {
	part: BasePart,
	pos: Vector3,
	vel: Vector3,
	rot: CFrame,
	spin: Vector3,
	age: number,
	life: number,
	size: Vector3,
	gravity: number,
	drag: number,
	shrink: boolean,
	pop: boolean,
	pull: Vector3?, -- homing point (for inward effects)
}

local particles: { Particle } = {}

export type ParticleOpts = {
	Color: Color3,
	Size: number,
	Life: number,
	Velocity: Vector3?,
	Gravity: number?,
	Drag: number?,
	Neon: boolean?,
	Plate: boolean?,
	Shrink: boolean?,
	Pop: boolean?,
	Spin: number?,
	Pull: Vector3?,
}

function VFX.Particle(pos: Vector3, o: ParticleOpts)
	if #particles >= VFX.MaxParticles then
		return
	end
	local part = VFX.Get(o.Color, o.Neon)
	local s = o.Size
	local size = if o.Plate then Vector3.new(s, s * 0.14, s * 0.7) else Vector3.new(s, s, s)
	part.Size = size
	part.CFrame = CFrame.new(pos)
	local spinMax = o.Spin or 10
	table.insert(particles, {
		part = part,
		pos = pos,
		vel = o.Velocity or Vector3.zero,
		rot = CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
		spin = Vector3.new(
			rng:NextNumber(-spinMax, spinMax),
			rng:NextNumber(-spinMax, spinMax),
			rng:NextNumber(-spinMax, spinMax)
		),
		age = 0,
		life = o.Life,
		size = size,
		gravity = o.Gravity or 0,
		drag = o.Drag or 0,
		shrink = o.Shrink ~= false,
		pop = o.Pop == true,
		pull = o.Pull,
	})
end

local function randUnit(): Vector3
	local z = rng:NextNumber(-1, 1)
	local a = rng:NextNumber(0, 2 * math.pi)
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end
VFX.RandUnit = randUnit

export type CubesOpts = {
	Pos: Vector3,
	Count: number,
	Colors: { Color3 },
	Speed: { number },
	Size: { number },
	Life: { number },
	Gravity: number?,
	Drag: number?,
	Dir: Vector3?,
	Spread: number?, -- 0 = straight along Dir, 1 = any direction
	Flatten: number?, -- squash vertical velocity (0..1)
	Neon: boolean?,
	Plate: boolean?,
	Shrink: boolean?,
	Spin: number?,
	Offset: number?, -- random start offset radius
}

function VFX.Cubes(o: CubesOpts)
	for i = 1, o.Count do
		local dir: Vector3
		if o.Dir then
			dir = (o.Dir.Unit + randUnit() * (o.Spread or 0.35)).Unit
		else
			dir = randUnit()
		end
		if o.Flatten then
			dir = Vector3.new(dir.X, dir.Y * (1 - o.Flatten), dir.Z)
		end
		local start = o.Pos
		if o.Offset then
			start += randUnit() * rng:NextNumber(0, o.Offset)
		end
		VFX.Particle(start, {
			Color = o.Colors[(i - 1) % #o.Colors + 1],
			Size = rng:NextNumber(o.Size[1], o.Size[2]),
			Life = rng:NextNumber(o.Life[1], o.Life[2]),
			Velocity = dir * rng:NextNumber(o.Speed[1], o.Speed[2]),
			Gravity = o.Gravity,
			Drag = o.Drag,
			Neon = o.Neon,
			Plate = o.Plate,
			Shrink = o.Shrink,
			Spin = o.Spin,
		})
	end
end

-- Cubes that start on a ring/sphere and get sucked into `center`.
function VFX.Suck(center: Vector3, radius: number, count: number, colors: { Color3 }, life: number, size: number)
	for i = 1, count do
		local d = randUnit()
		d = Vector3.new(d.X, d.Y * 0.45, d.Z).Unit
		local start = center + d * radius * rng:NextNumber(0.8, 1.2)
		local lifeI = life * rng:NextNumber(0.75, 1.1)
		VFX.Particle(start, {
			Color = colors[(i - 1) % #colors + 1],
			Size = size * rng:NextNumber(0.7, 1.2),
			Life = lifeI,
			Velocity = (center - start) / lifeI,
			Shrink = true,
			Pull = center,
		})
	end
end

--------------------------------------------------------------------------------
-- Shapes

-- A square frame of 4 Neon bars in the XY plane of `cf`, growing from size0 to size1.
function VFX.SquareRing(cf: CFrame, color: Color3, size0: number, size1: number, thick: number, duration: number, ease: ((number) -> number)?)
	local bars = { VFX.Get(color), VFX.Get(color), VFX.Get(color), VFX.Get(color) }
	local easing = ease or Ease.outQuad
	VFX.Run(duration, function(a)
		local e = easing(a)
		local s = size0 + (size1 - size0) * e
		local h = s / 2
		local th = math.max(thick * (1 - a * 0.7), 0.05)
		local tr = a ^ 1.6
		bars[1].Size = Vector3.new(s + th, th, th)
		bars[1].CFrame = cf * CFrame.new(0, h, 0)
		bars[2].Size = Vector3.new(s + th, th, th)
		bars[2].CFrame = cf * CFrame.new(0, -h, 0)
		bars[3].Size = Vector3.new(th, s + th, th)
		bars[3].CFrame = cf * CFrame.new(-h, 0, 0)
		bars[4].Size = Vector3.new(th, s + th, th)
		bars[4].CFrame = cf * CFrame.new(h, 0, 0)
		for _, b in bars do
			b.Transparency = tr
		end
		if a >= 1 then
			for _, b in bars do
				VFX.Release(b)
			end
		end
	end)
end

-- A persistent square frame you drive yourself (reticles, warning frames).
export type Frame = {
	bars: { BasePart },
	Update: (Frame, CFrame, number, number, number) -> (),
	Destroy: (Frame) -> (),
}

function VFX.Frame(color: Color3, corners: boolean?): Frame
	local n = if corners then 8 else 4
	local bars = {}
	for i = 1, n do
		bars[i] = VFX.Get(color)
	end
	local frame = {} :: Frame
	frame.bars = bars
	function frame.Update(self: Frame, cf: CFrame, size: number, thick: number, transparency: number)
		local h = size / 2
		if n == 4 then
			local b = self.bars
			b[1].Size = Vector3.new(size + thick, thick, thick)
			b[1].CFrame = cf * CFrame.new(0, h, 0)
			b[2].Size = Vector3.new(size + thick, thick, thick)
			b[2].CFrame = cf * CFrame.new(0, -h, 0)
			b[3].Size = Vector3.new(thick, size + thick, thick)
			b[3].CFrame = cf * CFrame.new(-h, 0, 0)
			b[4].Size = Vector3.new(thick, size + thick, thick)
			b[4].CFrame = cf * CFrame.new(h, 0, 0)
		else
			-- corner brackets: each corner gets one horizontal and one vertical arm
			local arm = size * 0.3
			local k = 0
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					k += 1
					local hb = self.bars[k]
					hb.Size = Vector3.new(arm, thick, thick)
					hb.CFrame = cf * CFrame.new(sx * (h - arm / 2), sy * h, 0)
					k += 1
					local vb = self.bars[k]
					vb.Size = Vector3.new(thick, arm, thick)
					vb.CFrame = cf * CFrame.new(sx * h, sy * (h - arm / 2), 0)
				end
			end
		end
		for _, b in self.bars do
			b.Transparency = transparency
		end
	end
	function frame.Destroy(self: Frame)
		for _, b in self.bars do
			VFX.Release(b)
		end
		table.clear(self.bars)
	end
	return frame
end

-- A cube (rotated 45 degrees) that blasts out and fades. The core of every impact.
function VFX.Flash(pos: Vector3, color: Color3, size: number, duration: number)
	local outer = VFX.Get(color)
	local inner = VFX.Get(Color3.new(1, 1, 1))
	local tilt = CFrame.new(pos) * CFrame.Angles(math.rad(45), math.rad(45), 0)
	VFX.Run(duration, function(a)
		local e = Ease.outExpo(a)
		local s = size * (0.25 + 0.95 * e)
		outer.Size = Vector3.new(s, s, s)
		outer.CFrame = tilt * CFrame.Angles(0, a * 1.2, 0)
		outer.Transparency = 0.1 + 0.9 * a
		local si = s * 0.55 * (1 - a)
		inner.Size = Vector3.new(si, si, si)
		inner.CFrame = tilt * CFrame.Angles(a * 2, 0, 0)
		inner.Transparency = a
		if a >= 1 then
			VFX.Release(outer)
			VFX.Release(inner)
		end
	end)
end

-- A four-point glint made of two crossing bars, always facing the camera.
function VFX.Star(pos: Vector3, color: Color3, size: number, duration: number)
	local a1 = VFX.Get(color)
	local a2 = VFX.Get(color)
	VFX.Run(duration, function(a)
		local cam = workspace.CurrentCamera
		local face = if cam then CFrame.lookAt(pos, cam.CFrame.Position) else CFrame.new(pos)
		local k = if a < 0.35 then Ease.outBack(a / 0.35) else 1 - (a - 0.35) / 0.65
		local s = size * k
		local rot = face * CFrame.Angles(0, 0, a * 1.4)
		a1.Size = Vector3.new(s, s * 0.12, 0.05)
		a1.CFrame = rot
		a2.Size = Vector3.new(s * 0.12, s, 0.05)
		a2.CFrame = rot
		a1.Transparency = a * 0.6
		a2.Transparency = a * 0.6
		if a >= 1 then
			VFX.Release(a1)
			VFX.Release(a2)
		end
	end)
end

function VFX.Light(pos: Vector3, color: Color3, brightness: number, range: number, duration: number)
	local holder = StudKit.Part(Vector3.one * 0.2, color, { Transparency = 1, Studs = false })
	holder.CFrame = CFrame.new(pos)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = holder
	holder.Parent = parent()
	VFX.Run(duration, function(a)
		light.Brightness = brightness * (1 - Ease.outQuad(a))
		if a >= 1 then
			holder:Destroy()
		end
	end)
end

-- Glow sparkles: one ParticleEmitter burst on the engine's built-in sparkle texture.
function VFX.Sparkles(pos: Vector3, color: Color3, count: number, speed: number?)
	local holder = StudKit.Part(Vector3.one * 0.2, color, { Transparency = 1, Studs = false })
	holder.CFrame = CFrame.new(pos)
	local att = Instance.new("Attachment")
	att.Parent = holder
	local pe = Instance.new("ParticleEmitter")
	pe.Enabled = false
	pe.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	pe.LightEmission = 1
	pe.LightInfluence = 0
	pe.Brightness = 3
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Speed = NumberRange.new((speed or 22) * 0.5, speed or 22)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 5
	pe.RotSpeed = NumberRange.new(-360, 360)
	pe.Rotation = NumberRange.new(0, 360)
	pe.Parent = att
	holder.Parent = parent()
	pe:Emit(count)
	task.delay(0.8, function()
		holder:Destroy()
	end)
end

export type Destroyable = { Destroy: (any) -> () }

function VFX.Trail(part: BasePart, color: Color3, lifetime: number, width: number): Destroyable
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	trail.Lifetime = lifetime
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Parent = part
	return {
		Destroy = function()
			trail:Destroy()
			a0:Destroy()
			a1:Destroy()
		end,
	}
end

-- A fading Neon afterimage of every part in a model.
function VFX.Ghost(model: Model, color: Color3, duration: number)
	local copies = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local g = VFX.Get(color)
			g.Size = d.Size
			g.CFrame = d.CFrame
			g.Transparency = 0.35
			table.insert(copies, g)
		end
	end
	VFX.Run(duration, function(a)
		for _, g in copies do
			g.Transparency = 0.35 + 0.65 * a
		end
		if a >= 1 then
			for _, g in copies do
				VFX.Release(g)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Screen feel

local trauma = 0

function VFX.Shake(pos: Vector3?, magnitude: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local f = 1
	if pos then
		f = math.clamp(1 - (cam.CFrame.Position - pos).Magnitude / VFX.ShakeDistance, 0, 1)
	end
	trauma = math.min(1.4, trauma + magnitude * f)
end

local tint: ColorCorrectionEffect? = nil

function VFX.Tint(color: Color3, strength: number, duration: number)
	if not tint then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "HazardTint"
		cc.Parent = Lighting
		tint = cc
	end
	local cc = tint :: ColorCorrectionEffect
	VFX.Run(duration, function(a)
		local k = strength * (1 - Ease.outQuad(a))
		cc.TintColor = Color3.new(1, 1, 1):Lerp(color, k)
		cc.Brightness = 0.12 * k
		if a >= 1 then
			cc.TintColor = Color3.new(1, 1, 1)
			cc.Brightness = 0
		end
	end)
end

function VFX.NearCamera(pos: Vector3, distance: number): boolean
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - pos).Magnitude <= distance
end

-- Floating "-1" damage number.
function VFX.Popup(pos: Vector3, text: string, color: Color3)
	local holder = StudKit.Part(Vector3.one * 0.2, color, { Transparency = 1, Studs = false })
	holder.CFrame = CFrame.new(pos)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 90)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(26, 16, 48)
	stroke.Parent = label
	holder.Parent = parent()
	VFX.Run(0.9, function(a)
		local pop = if a < 0.15 then Ease.outBack(a / 0.15) * 1.25 else 1.25 - 0.25 * math.min((a - 0.15) / 0.2, 1)
		label.Size = UDim2.fromScale(pop, pop)
		holder.CFrame = CFrame.new(pos + Vector3.new(0, 4.5 * Ease.outQuad(a), 0))
		local fade = math.clamp((a - 0.55) / 0.45, 0, 1)
		label.TextTransparency = fade
		stroke.Transparency = fade
		if a >= 1 then
			holder:Destroy()
		end
	end)
end

--------------------------------------------------------------------------------
-- The shared hit burst: flash cube, two square shock rings, cube burst, sparkles,
-- light, shake and a tint when it's close to you.

export type ImpactOpts = {
	Scale: number?,
	Cubes: number?,
	Colors: { Color3 }?,
	Shake: number?,
}

function VFX.Impact(pos: Vector3, color: Color3, hot: Color3, o: ImpactOpts?)
	local opts: ImpactOpts = o or {}
	local s = opts.Scale or 1
	local cam = workspace.CurrentCamera
	local face = if cam then CFrame.lookAt(pos, cam.CFrame.Position) else CFrame.new(pos)
	VFX.Flash(pos, hot, 6 * s, 0.4)
	VFX.SquareRing(face * CFrame.Angles(0, 0, math.rad(45)), color, 2 * s, 16 * s, 0.55 * s, 0.5)
	task.delay(0.07, function()
		VFX.SquareRing(face, hot, 1.5 * s, 11 * s, 0.35 * s, 0.42)
	end)
	VFX.Cubes({
		Pos = pos,
		Count = opts.Cubes or 36,
		Colors = opts.Colors or { color, hot },
		Speed = { 16 * s, 40 * s },
		Size = { 0.35 * s, 0.85 * s },
		Life = { 0.45, 0.95 },
		Drag = 3.5,
		Gravity = -22,
		Neon = true,
	})
	VFX.Sparkles(pos, color, 28, 26 * s)
	VFX.Light(pos, color, 10, 28 * s, 0.5)
	VFX.Shake(pos, opts.Shake or 0.45)
	if VFX.NearCamera(pos, VFX.ShakeDistance * 0.6) then
		VFX.Tint(color, 0.35, 0.35)
	end
end

--------------------------------------------------------------------------------
-- Frame step

local bulkParts: { BasePart } = {}
local bulkCFs: { CFrame } = {}

function VFX.Step(dt: number)
	-- runners
	local i = 1
	while i <= #runners do
		local r = runners[i]
		if r.alive then
			r.t += dt
			local a = if r.d > 0 and r.d < math.huge then math.min(r.t / r.d, 1) else 0
			local ok = xpcall(r.fn, function(err)
				warn("[HazardVFX] runner error:", err)
			end, a, dt, r.t)
			if not ok then
				r.alive = false
			elseif r.d < math.huge and r.t >= r.d then
				r.alive = false
			end
		end
		if r.alive then
			i += 1
		else
			runners[i] = runners[#runners]
			runners[#runners] = nil
		end
	end

	-- particles
	local n = 0
	local j = 1
	while j <= #particles do
		local p = particles[j]
		p.age += dt
		if p.age >= p.life then
			VFX.Release(p.part)
			particles[j] = particles[#particles]
			particles[#particles] = nil
		else
			local a = p.age / p.life
			if p.pull then
				-- homing: arrive at the pull point exactly at end of life
				local remaining = p.life - p.age
				p.vel = (p.pull - p.pos) / math.max(remaining, dt)
			else
				p.vel = p.vel * math.max(0, 1 - p.drag * dt) + Vector3.new(0, p.gravity * dt, 0)
			end
			p.pos += p.vel * dt
			p.rot = p.rot * CFrame.Angles(p.spin.X * dt, p.spin.Y * dt, p.spin.Z * dt)
			local k = 1
			if p.pop then
				k = if a < 0.12 then (a / 0.12) * 1.5 else 1.5 - (a - 0.12) / 0.88 * 1.3
			elseif p.shrink then
				k = 1 - a * 0.8
			end
			if k ~= 1 or p.pop or p.shrink then
				p.part.Size = p.size * math.max(k, 0.02)
			end
			p.part.Transparency = if a > 0.6 then (a - 0.6) / 0.4 else 0
			n += 1
			bulkParts[n] = p.part
			bulkCFs[n] = CFrame.new(p.pos) * p.rot
			j += 1
		end
	end
	if n > 0 then
		for k = #bulkParts, n + 1, -1 do
			bulkParts[k] = nil
			bulkCFs[k] = nil
		end
		workspace:BulkMoveTo(bulkParts, bulkCFs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Camera shake runs after the camera script so it layers on top of it.
function VFX.BindCamera()
	RunService:BindToRenderStep("HazardShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		if trauma <= 0.001 then
			return
		end
		local cam = workspace.CurrentCamera
		if cam then
			local s = trauma * trauma
			local t = os.clock() * 38
			cam.CFrame = cam.CFrame
				* CFrame.new(math.noise(t, 7) * 0.5 * s, math.noise(t, 8) * 0.5 * s, 0)
				* CFrame.Angles(math.noise(t, 1) * 0.045 * s, math.noise(t, 2) * 0.045 * s, math.noise(t, 3) * 0.03 * s)
		end
		trauma = math.max(0, trauma - dt * 2.4)
	end)
end

return VFX
