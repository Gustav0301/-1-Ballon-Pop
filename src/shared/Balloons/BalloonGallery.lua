--!strict
-- BalloonGallery (client, demo mode only): an arc of stud pedestals near the spawn with
-- every balloon floating, spinning and bobbing above its nameplate. Each pedestal has a
-- "Try it" prompt that swaps the demo balloon over your head to that type.
-- Built locally, so it never replicates and costs the server nothing.

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local BalloonBuilder = require(script.Parent.BalloonBuilder)
local BalloonConfig = require(Shared.Config.BalloonConfig)

local BalloonGallery = {}

local STONE = Color3.fromHex("A3A2A5")
local STONE_DARK = Color3.fromHex("7B7A80")
local GOLD = Color3.fromHex("FFC21A")

local function block(size: Vector3, color: Color3, cf: CFrame, parent: Instance, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.Anchored = true
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function findSpawn(): CFrame
	for _, d in workspace:GetDescendants() do
		if d:IsA("SpawnLocation") then
			return CFrame.new(d.Position - Vector3.new(0, d.Size.Y / 2, 0))
		end
	end
	return CFrame.new(0, 0, 0)
end

type Exhibit = { model: Model, base: CFrame, phase: number }

function BalloonGallery.Start(equipRemote: RemoteEvent?): Folder
	local folder = Instance.new("Folder")
	folder.Name = "BalloonGallery"
	folder.Parent = workspace

	local origin = findSpawn()
	local names = BalloonConfig.Ordered()
	local radius = 62
	local span = math.rad(150)
	local exhibits: { Exhibit } = {}

	for i, name in names do
		local t = (i - 1) / (#names - 1)
		local a = -span / 2 + span * t
		local floor = origin * CFrame.new(math.sin(a) * radius, 0, -math.cos(a) * radius)
		local face = CFrame.lookAt(floor.Position, Vector3.new(origin.X, floor.Y, origin.Z))
		local cfg = BalloonConfig.Types[name]
		local tierColor = BalloonConfig.TierColors[cfg.Tier]

		local stand = Instance.new("Model")
		stand.Name = name
		stand.Parent = folder
		block(Vector3.new(6, 1, 6), STONE_DARK, face * CFrame.new(0, 0.5, 0), stand)
		block(Vector3.new(4, 3, 4), STONE, face * CFrame.new(0, 2.5, 0), stand)
		local top = block(Vector3.new(5, 0.6, 5), GOLD, face * CFrame.new(0, 4.3, 0), stand)
		local trim = block(Vector3.new(4.2, 0.4, 0.2), tierColor, face * CFrame.new(0, 1.3, -2.05), stand, Enum.Material.Neon)
		trim.TopSurface = Enum.SurfaceType.Smooth

		-- nameplate
		local plate = block(Vector3.new(3.6, 1.6, 0.3), Color3.fromHex("2A2440"), face * CFrame.new(0, 2.6, -2.1), stand, Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(360, 160)
		gui.LightInfluence = 0
		gui.Parent = plate
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.62)
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.Text = name
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Parent = gui
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.fromScale(0, 0.6)
		sub.Size = UDim2.fromScale(1, 0.36)
		sub.Font = Enum.Font.FredokaOne
		sub.TextScaled = true
		sub.Text = string.upper(cfg.Tier) .. "  ·  LIFT x" .. cfg.Lift
		sub.TextColor3 = tierColor
		sub.Parent = gui
		for _, label in { title, sub } do
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(26, 16, 48)
			stroke.Parent = label
		end

		-- balloon on a string
		local base = face * CFrame.new(0, 12.5, 0)
		local balloon = BalloonBuilder.Build(name, { Anchored = true, CFrame = base, Scale = 0.72 })
		balloon.Parent = stand
		local knot = balloon.PrimaryPart and (balloon.PrimaryPart :: BasePart):FindFirstChild("StringAttachment") :: Attachment?
		if knot then
			local knotPos = knot.WorldPosition
			local fromPos = top.Position + Vector3.new(0, 0.3, 0)
			local len = (knotPos - fromPos).Magnitude
			local str = Instance.new("Part")
			str.Size = Vector3.new(0.12, 0.12, len)
			str.CFrame = CFrame.lookAt((knotPos + fromPos) / 2, knotPos)
			str.Color = Color3.fromHex("F4F6FF")
			str.Material = Enum.Material.SmoothPlastic
			str.Anchored = true
			str.CanCollide = false
			str.Parent = stand
		end

		if equipRemote then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Try it"
			prompt.ObjectText = name
			prompt.HoldDuration = 0.2
			prompt.MaxActivationDistance = 12
			prompt.Parent = top
			prompt.Triggered:Connect(function()
				equipRemote:FireServer(name)
			end)
		end

		table.insert(exhibits, { model = balloon, base = base, phase = i * 0.7 })
	end

	local camera = workspace.CurrentCamera
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local camPos = if camera then camera.CFrame.Position else Vector3.zero
		for _, e in exhibits do
			if (e.base.Position - camPos).Magnitude < 180 then
				e.model:PivotTo(e.base * CFrame.new(0, math.sin(t * 1.6 + e.phase) * 0.5, 0) * CFrame.Angles(0, t * 0.6 + e.phase, 0))
			end
		end
	end)

	return folder
end

return BalloonGallery
