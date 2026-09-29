--!strict
-- BalloonBuilder: turns the generated voxel data in BalloonModels into a real stud Model.
--
--   local model = BalloonBuilder.Build("Gumball", { Anchored = false, CFrame = cf, Scale = 1.5 })
--
-- The model's PrimaryPart is an invisible "Root" at the balloon's centre; every part is
-- welded to it (or anchored), so Model:PivotTo and Model:ScaleTo work as the prompt asks.
-- Root holds a "StringAttachment" at the knot for the string / RopeConstraint.

local BalloonModels = require(script.Parent.BalloonModels)

local BalloonBuilder = {}

local MATERIALS = {
	P = Enum.Material.Plastic,
	S = Enum.Material.SmoothPlastic,
	N = Enum.Material.Neon,
	G = Enum.Material.Glass,
}

export type BuildOptions = {
	Anchored: boolean?, -- default true
	CFrame: CFrame?,
	Scale: number?,
	Name: string?,
}

type Style = { color: Color3, material: Enum.Material, transparency: number, studs: boolean }

local styleCache: { [string]: { [string]: Style } } = {}

local function styles(kind: string, def: any): { [string]: Style }
	local cached = styleCache[kind]
	if cached then
		return cached
	end
	local out = {}
	for key, entry in def.Palette do
		local mat = MATERIALS[entry[2]] or Enum.Material.Plastic
		out[key] = {
			color = Color3.fromHex(entry[1]),
			material = mat,
			transparency = entry[3] or 0,
			studs = mat == Enum.Material.Plastic,
		}
	end
	styleCache[kind] = out
	return out
end

function BalloonBuilder.Has(kind: string): boolean
	return BalloonModels[kind] ~= nil
end

function BalloonBuilder.Build(kind: string, opts: BuildOptions?): Model
	local def = BalloonModels[kind]
	assert(def, "Unknown balloon: " .. tostring(kind))
	local o: BuildOptions = opts or {}
	local anchored = o.Anchored ~= false
	local palette = styles(kind, def)

	local model = Instance.new("Model")
	model.Name = o.Name or kind
	model:SetAttribute("Balloon", kind)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.one
	root.Transparency = 1
	root.Anchored = anchored
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = true
	root.CFrame = CFrame.identity
	root.Parent = model

	for i, rec in def.Parts do
		local part: BasePart = if rec[1] == "W" then Instance.new("WedgePart") else Instance.new("Part")
		local style = palette[rec[2]]
		part.Name = rec[2] .. i
		part.Size = Vector3.new(rec[3], rec[4], rec[5])
		part.CFrame = if #rec >= 17
			then CFrame.new(rec[6], rec[7], rec[8], rec[9], rec[10], rec[11], rec[12], rec[13], rec[14], rec[15], rec[16], rec[17])
			else CFrame.new(rec[6], rec[7], rec[8])
		part.Color = style.color
		part.Material = style.material
		part.Transparency = style.transparency
		if style.studs then
			part.TopSurface = Enum.SurfaceType.Studs
			part.BottomSurface = Enum.SurfaceType.Inlet
		else
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
		end
		part.Anchored = anchored
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Massless = true
		part.Parent = model
		if not anchored then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end

	local knot = Instance.new("Attachment")
	knot.Name = "StringAttachment"
	knot.Position = Vector3.new(def.Knot[1], def.Knot[2], def.Knot[3])
	knot.Parent = root

	if def.Light then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromHex(def.Light[1])
		light.Brightness = def.Light[2]
		light.Range = def.Light[3]
		light.Shadows = false
		light.Parent = root
	end

	model.PrimaryPart = root
	if o.Scale and o.Scale ~= 1 then
		model:ScaleTo(o.Scale)
	end
	if o.CFrame then
		model:PivotTo(o.CFrame)
	end
	return model
end

-- Knot offset from the balloon centre (in model space, before scaling).
function BalloonBuilder.KnotOffset(kind: string): Vector3
	local def = BalloonModels[kind]
	return if def then Vector3.new(def.Knot[1], def.Knot[2], def.Knot[3]) else Vector3.new(0, -5, 0)
end

return BalloonBuilder
