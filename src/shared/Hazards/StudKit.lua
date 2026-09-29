--!strict
-- StudKit: builds classic stud-style Parts and a light "rig" for procedurally
-- animated hazards. Rigs are anchored Parts moved together with BulkMoveTo, so
-- animation is smooth and never touches physics.

local StudKit = {}

export type PartOpts = {
	Shape: string?, -- "Block" | "Wedge" | "Ball" | "Cylinder"
	Material: Enum.Material?,
	Transparency: number?,
	Studs: boolean?, -- Studs on top, Inlet underneath (default true for Plastic)
	Name: string?,
}

function StudKit.Part(size: Vector3, color: Color3, opts: PartOpts?): BasePart
	local o: PartOpts = opts or {}
	local part: BasePart
	if o.Shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if o.Shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif o.Shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		end
		part = p
	end
	part.Name = o.Name or "Stud"
	part.Size = size
	part.Color = color
	part.Material = o.Material or Enum.Material.Plastic
	part.Transparency = o.Transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	local studs = o.Studs
	if studs == nil then
		studs = part.Material == Enum.Material.Plastic
	end
	if studs then
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Inlet
	else
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	return part
end

function StudKit.Neon(size: Vector3, color: Color3, name: string?): BasePart
	return StudKit.Part(size, color, { Material = Enum.Material.Neon, Studs = false, Name = name })
end

--------------------------------------------------------------------------------
-- Rig

export type RigPart = {
	part: BasePart,
	offset: CFrame,
	size: Vector3,
	transparency: number,
	color: Color3,
}

local Rig = {}
Rig.__index = Rig

export type Rig = typeof(setmetatable(
	{} :: {
		model: Model,
		parts: { [string]: RigPart },
		groups: { [string]: { string } },
		pose: { [string]: number },
		cf: CFrame,
		t: number,
		scale: number,
		follow: boolean,
		visible: boolean,
		root: BasePart?,
		ctx: any,
		kind: string,
		cfg: any,
		data: { [string]: any },
		_p: { BasePart },
		_c: { CFrame },
		_scaleApplied: number,
	},
	Rig
))

function StudKit.Rig(kind: string, cfg: any): Rig
	local model = Instance.new("Model")
	model.Name = kind
	local self = setmetatable({
		model = model,
		parts = {},
		groups = {},
		pose = {},
		cf = CFrame.identity,
		t = 0,
		scale = 1,
		follow = true,
		visible = true,
		root = nil,
		ctx = nil,
		kind = kind,
		cfg = cfg,
		data = {},
		_p = {},
		_c = {},
		_scaleApplied = 1,
	}, Rig)
	return self
end

-- Adds a part at a rest offset (relative to the rig's pivot, facing -Z).
function Rig.Add(self: Rig, key: string, part: BasePart, offset: CFrame?, group: string?): BasePart
	part.Name = key
	part.Parent = self.model
	self.parts[key] = {
		part = part,
		offset = offset or CFrame.identity,
		size = part.Size,
		transparency = part.Transparency,
		color = part.Color,
	}
	if group then
		local g = self.groups[group]
		if not g then
			g = {}
			self.groups[group] = g
		end
		table.insert(g, key)
	end
	return part
end

function Rig.Set(self: Rig, key: string, cf: CFrame)
	local rp = self.parts[key]
	if rp then
		local n = #self._p + 1
		self._p[n] = rp.part
		self._c[n] = cf
	end
end

-- Places a part at base * (its rest offset scaled by the rig scale).
function Rig.Rest(self: Rig, key: string, base: CFrame)
	local rp = self.parts[key]
	if rp then
		local o = rp.offset
		local s = self.scale
		self:Set(key, base * (if s == 1 then o else (o - o.Position + o.Position * s)))
	end
end

function Rig.Flush(self: Rig)
	if #self._p > 0 then
		workspace:BulkMoveTo(self._p, self._c, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(self._p)
		table.clear(self._c)
	end
end

function Rig.ApplyScale(self: Rig)
	if math.abs(self.scale - self._scaleApplied) < 0.004 then
		return
	end
	self._scaleApplied = self.scale
	for _, rp in self.parts do
		rp.part.Size = rp.size * self.scale
	end
end

function Rig.Keys(self: Rig, group: string?): { string }
	if group then
		return self.groups[group] or {}
	end
	local all = {}
	for key in self.parts do
		table.insert(all, key)
	end
	return all
end

-- alpha 0 = rest transparency, alpha 1 = invisible
function Rig.Fade(self: Rig, alpha: number, group: string?)
	for _, key in self:Keys(group) do
		local rp = self.parts[key]
		rp.part.Transparency = rp.transparency + (1 - rp.transparency) * alpha
	end
end

function Rig.Tint(self: Rig, color: Color3, alpha: number, group: string?)
	for _, key in self:Keys(group) do
		local rp = self.parts[key]
		rp.part.Color = rp.color:Lerp(color, alpha)
	end
end

function Rig.Show(self: Rig, visible: boolean)
	if self.visible == visible then
		return
	end
	self.visible = visible
	self.model.Parent = if visible then (self.data.parent :: Instance?) else nil
end

function Rig.Destroy(self: Rig)
	self.model:Destroy()
end

StudKit.RigClass = Rig

return StudKit
