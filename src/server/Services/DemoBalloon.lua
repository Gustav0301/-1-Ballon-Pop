--!strict
-- DemoBalloon: only used when HazardConfig.Demo.Enabled is true.
-- Gives every character a stud balloon over their head (Gumball to start; the gallery's
-- "Try it" prompts swap it), with HP from the balloon's Toughness. Applies hazard hits,
-- pops it into brick confetti at 0 HP and reinflates it after a few seconds.
-- The real game replaces all of this with FlightService (section 2 of the prompt).

local Players = game:GetService("Players")

local DemoBalloon = {}

local FALLBACK_COLOR = Color3.fromHex("FF3B3B")

local BalloonBuilder: any
local BalloonConfig: any
local kinds: { [Player]: string } = {}
local lastEquip: { [Player]: number } = {}

local function maxHP(player: Player, cfg: any): number
	local t = BalloonConfig.Types[kinds[player] or "Gumball"]
	return if t then t.Toughness else cfg.Demo.BalloonHP
end

local function buildHP(root: BasePart, hp: number, top: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "HP"
	gui.Size = UDim2.fromOffset(math.min(28 * hp, 300), 26)
	gui.StudsOffsetWorldSpace = Vector3.new(0, top + 1.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 5)
	layout.Parent = gui
	for i = 1, hp do
		local pip = Instance.new("Frame")
		pip.Name = "Pip" .. i
		pip.Size = UDim2.fromOffset(20, 20)
		pip.BackgroundColor3 = FALLBACK_COLOR
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
	gui.Parent = root
	return gui
end

local function refreshHP(player: Player)
	local character = player.Character
	local balloon = character and character:FindFirstChild("Balloon")
	local root = balloon and balloon:FindFirstChild("Root")
	local gui = root and root:FindFirstChild("HP")
	if not gui then
		return
	end
	local hp = (player:GetAttribute("BalloonHP") :: number?) or 0
	for _, child in gui:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundColor3 = if child.LayoutOrder <= hp then FALLBACK_COLOR else Color3.fromRGB(42, 36, 64)
		end
	end
end

local function clear(character: Model)
	for _, name in { "Balloon", "BalloonString" } do
		local old = character:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

-- the colour of the biggest part, for the pop confetti
local function mainColor(model: Model): Color3
	local best, bestVol = FALLBACK_COLOR, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.5 then
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > bestVol then
				best, bestVol = d.Color, v
			end
		end
	end
	return best
end

local function build(player: Player, character: Model, cfg: any)
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp then
		return
	end
	clear(character)
	local kind = kinds[player] or "Gumball"
	local knot: Vector3 = BalloonBuilder.KnotOffset(kind)
	local hand = hrp.CFrame * CFrame.new(0, 1, 0)
	local knotWorld = hand * CFrame.new(0, cfg.Demo.StringLength, 0)
	local center = knotWorld * CFrame.new(-knot)

	local model: Model = BalloonBuilder.Build(kind, { Anchored = false, CFrame = center, Name = "Balloon" })
	local root = model.PrimaryPart :: BasePart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = root
	weld.Parent = root
	model:SetAttribute("PopColor", mainColor(model))
	model.Parent = character

	local str = Instance.new("Part")
	str.Name = "BalloonString"
	str.Size = Vector3.new(0.1, 0.1, cfg.Demo.StringLength)
	str.CFrame = CFrame.lookAt((hand.Position + knotWorld.Position) / 2, knotWorld.Position)
	str.Color = Color3.fromHex("F4F6FF")
	str.Material = Enum.Material.SmoothPlastic
	str.CanCollide = false
	str.CanTouch = false
	str.CanQuery = false
	str.Massless = true
	local sw = Instance.new("WeldConstraint")
	sw.Part0 = hrp
	sw.Part1 = str
	sw.Parent = str
	str.Parent = character

	local extent = model:GetExtentsSize()
	buildHP(root, maxHP(player, cfg), extent.Y / 2)
end

function DemoBalloon.Start(cfg: any, _target: any, service: any, remote: RemoteEvent, shared: Instance)
	BalloonBuilder = require((shared :: any).Balloons.BalloonBuilder) :: any
	BalloonConfig = require((shared :: any).Config.BalloonConfig) :: any
	local popping: { [Player]: boolean } = {}

	local function reset(player: Player)
		popping[player] = nil
		player:SetAttribute("BalloonHP", maxHP(player, cfg))
		if player.Character then
			build(player, player.Character, cfg)
			refreshHP(player)
		end
	end

	local function setup(player: Player)
		player:SetAttribute("BalloonHP", maxHP(player, cfg))
		player.CharacterAdded:Connect(function()
			reset(player)
		end)
		if player.Character then
			reset(player)
		end
	end
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(player)
		popping[player] = nil
		kinds[player] = nil
		lastEquip[player] = nil
	end)

	-- "Try it" from the gallery: validated and rate limited
	local equip = Instance.new("RemoteEvent")
	equip.Name = "DemoEquip"
	equip.Parent = remote.Parent
	equip.OnServerEvent:Connect(function(player: Player, kind: unknown)
		if type(kind) ~= "string" or not BalloonConfig.Types[kind] or not BalloonBuilder.Has(kind) then
			return
		end
		local now = os.clock()
		if lastEquip[player] and now - lastEquip[player] < 0.5 then
			return
		end
		lastEquip[player] = now
		kinds[player] = kind
		reset(player)
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
		if character and balloon and balloon.PrimaryPart then
			local color = balloon:GetAttribute("PopColor")
			remote:FireAllClients("Pop", player.UserId, balloon.PrimaryPart.Position, if typeof(color) == "Color3" then color else FALLBACK_COLOR)
			clear(character)
		end
		task.delay(cfg.Demo.RespawnDelay, function()
			if player.Parent == Players and popping[player] then
				reset(player)
			end
		end)
	end)
end

return DemoBalloon
