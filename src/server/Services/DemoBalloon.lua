--!strict
-- DemoBalloon: only used when HazardConfig.Demo.Enabled is true.
-- Gives every character a stud Gumball over their head with 3 HP, applies hazard hits,
-- pops it into brick confetti at 0 HP and reinflates it after a few seconds.
-- The real game replaces all of this with FlightService (section 2 of the prompt).

local Players = game:GetService("Players")

local DemoBalloon = {}

local RED = Color3.fromHex("FF3B3B")
local RED_DARK = Color3.fromHex("D9232F")
local RED_LIGHT = Color3.fromHex("FF9A9A")

local LAYERS = { 2, 4, 5, 5, 5, 4, 2 } -- stepped "voxel sphere" widths, bottom to top

local function newPart(size: Vector3, color: Color3, name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function buildHP(body: BasePart, maxHP: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "HP"
	gui.Size = UDim2.fromOffset(34 * maxHP, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = gui
	for i = 1, maxHP do
		local pip = Instance.new("Frame")
		pip.Name = "Pip" .. i
		pip.Size = UDim2.fromOffset(24, 24)
		pip.BackgroundColor3 = RED
		pip.LayoutOrder = i
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = pip
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(26, 16, 48)
		stroke.Parent = pip
		pip.Parent = gui
	end
	gui.Parent = body
	return gui
end

local function refreshHP(player: Player)
	local character = player.Character
	local balloon = character and character:FindFirstChild("Balloon")
	local body = balloon and balloon:FindFirstChild("Body")
	local gui = body and body:FindFirstChild("HP")
	if not gui then
		return
	end
	local hp = (player:GetAttribute("BalloonHP") :: number?) or 0
	for _, child in gui:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundColor3 = if child.LayoutOrder <= hp then RED else Color3.fromRGB(42, 36, 64)
		end
	end
end

local function build(character: Model, cfg: any)
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp then
		return
	end
	local old = character:FindFirstChild("Balloon")
	if old then
		old:Destroy()
	end
	local oldString = character:FindFirstChild("BalloonString")
	if oldString then
		oldString:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "Balloon"
	local center = hrp.CFrame * CFrame.new(0, cfg.Demo.BalloonHeight, 0)
	local mid = (#LAYERS + 1) / 2
	local body: Part? = nil
	for i, w in LAYERS do
		local color = if i == 1 or i == #LAYERS then RED_DARK else RED
		local layer = newPart(Vector3.new(w, 1, w), color, if i == mid then "Body" else "Layer" .. i)
		layer.CFrame = center * CFrame.new(0, i - mid, 0)
		layer.Parent = model
		weld(hrp, layer)
		if layer.Name == "Body" then
			body = layer
		end
	end
	local shine = newPart(Vector3.new(1, 2, 1), RED_LIGHT, "Shine")
	shine.CFrame = center * CFrame.new(-1.6, 1, -1.6)
	shine.Parent = model
	weld(hrp, shine)
	local knot = Instance.new("WedgePart")
	knot.Name = "Knot"
	knot.Size = Vector3.new(0.8, 0.8, 0.8)
	knot.Color = RED_DARK
	knot.CanCollide = false
	knot.CanTouch = false
	knot.CanQuery = false
	knot.Massless = true
	knot.CFrame = center * CFrame.new(0, -mid - 0.1, 0) * CFrame.Angles(math.pi, 0, 0)
	knot.Parent = model
	weld(hrp, knot)
	model.PrimaryPart = body
	model.Parent = character

	local stringLen = cfg.Demo.BalloonHeight - mid - 1
	local str = newPart(Vector3.new(0.1, stringLen, 0.1), Color3.fromHex("F4F6FF"), "BalloonString")
	str.TopSurface = Enum.SurfaceType.Smooth
	str.BottomSurface = Enum.SurfaceType.Smooth
	str.CFrame = hrp.CFrame * CFrame.new(0, 1 + stringLen / 2, 0)
	str.Parent = character
	weld(hrp, str)

	if body then
		buildHP(body, cfg.Demo.BalloonHP)
	end
end

function DemoBalloon.Start(cfg: any, _target: any, service: any, remote: RemoteEvent)
	local popping: { [Player]: boolean } = {}

	local function setup(player: Player)
		player:SetAttribute("BalloonHP", cfg.Demo.BalloonHP)
		player.CharacterAdded:Connect(function(character)
			popping[player] = nil
			player:SetAttribute("BalloonHP", cfg.Demo.BalloonHP)
			build(character, cfg)
			refreshHP(player)
		end)
		if player.Character then
			build(player.Character, cfg)
		end
	end
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(player)
		popping[player] = nil
	end)

	service.Hit.Event:Connect(function(player: Player, damage: number)
		if popping[player] then
			return
		end
		local hp = math.max(0, ((player:GetAttribute("BalloonHP") :: number?) or 0) - damage)
		player:SetAttribute("BalloonHP", hp)
		refreshHP(player)
		if hp > 0 then
			return
		end
		-- POP: brick confetti on every client, then reinflate
		popping[player] = true
		local character = player.Character
		local balloon = character and character:FindFirstChild("Balloon") :: Model?
		if balloon and balloon.PrimaryPart then
			remote:FireAllClients("Pop", player.UserId, balloon.PrimaryPart.Position, RED)
			balloon:Destroy()
			local str = character and character:FindFirstChild("BalloonString")
			if str then
				str:Destroy()
			end
		end
		task.delay(cfg.Demo.RespawnDelay, function()
			if player.Parent ~= Players then
				return
			end
			popping[player] = nil
			player:SetAttribute("BalloonHP", cfg.Demo.BalloonHP)
			if player.Character then
				build(player.Character, cfg)
				refreshHP(player)
			end
		end)
	end)
end

return DemoBalloon
