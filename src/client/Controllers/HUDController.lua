--!strict
-- HUDController: the flight HUD in the Shop style (docs/UI_STYLE.md).
--
--   top centre     coin counter (gold pill, the stud coin breaking out of its left edge)
--   over balloons  unbanked coins that wobble as they tick up, SIZE chip, HP balloons,
--                  risk bar (fragility) or landing progress - for every flying player
--   right edge     altitude gauge: zones, islands and you
--   bottom centre  JUMP TO FLY on the ground; a big green LAND button near an island
--   bottom right   LET OUT AIR (touch and mouse; Space on keyboard)
--   in the world   island markers with distance, and an edge arrow to the nearest one
--   cards          BANKED! with a coin fountain into the counter, POPPED!, toasts
--
-- Everything is built from UI instances (no uploaded images) through UIKit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HUDController = {}

local LocalPlayer = Players.LocalPlayer

local UIKit: any
local T: any
local FlightConfig: any
local Flight: any
local Net: RemoteEvent

local gui: ScreenGui
local fxLayer: Frame
local viewportScales: { UIScale } = {}
local keyChips: { GuiObject } = {}

local new: (string, { [string]: any }?, { Instance }?) -> any

local GAUGE_TOP = 1500 -- altitude at the top of the gauge (Cloud Shelf ceiling)
local ZONES = {
	{ Name = "MEADOW SKY", From = 0, To = 500, Top = Color3.fromHex("8FE3FF"), Bottom = Color3.fromHex("63D56E") },
	{ Name = "CLOUD SHELF", From = 500, To = 1500, Top = Color3.fromHex("E9F1FF"), Bottom = Color3.fromHex("B7CCFF") },
}
local HP_ON = Color3.fromHex("FF3B4E")
local HP_OFF = Color3.fromHex("5A4A66")

--------------------------------------------------------------------------------
-- helpers

local function state(p: Player?): string
	return ((p or LocalPlayer):GetAttribute("FlightState") :: string?) or "Ground"
end

local function num(p: Player, name: string, fallback: number): number
	local v = p:GetAttribute(name)
	return if type(v) == "number" then v else fallback
end

-- "WindmillHill" -> "Windmill Hill"
local function titleName(name: string): string
	return (name:gsub("(%l)(%u)", "%1 %2"))
end

-- "WindmillHill" -> "WINDMILL HILL"
local function prettyName(name: string): string
	return titleName(name):upper()
end

-- a top-level container that scales with the screen
local function anchor(name: string, size: UDim2, pos: UDim2, ap: Vector2): Frame
	local frame = new("Frame", {
		Name = name,
		Size = size,
		Position = pos,
		AnchorPoint = ap,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	table.insert(viewportScales, new("UIScale", { Parent = frame }))
	return frame
end

local function keyChip(text: string, parent: Instance, pos: UDim2, ap: Vector2?, h: number?): Frame
	local chip = UIKit.Key(text, parent, h)
	chip.Position = pos
	chip.AnchorPoint = ap or Vector2.new(0.5, 0.5)
	chip.ZIndex = 30
	for _, d in chip:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 31
		end
	end
	table.insert(keyChips, chip)
	return chip
end

local function show(obj: GuiObject, on: boolean, scale: UIScale?)
	if obj.Visible == on then
		return
	end
	obj.Visible = on
	if on and scale then
		scale.Scale = 0.6
		UIKit.Tween(scale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

--------------------------------------------------------------------------------
-- coin counter

local coins = { shown = 0, target = 0, holdUntil = 0, scale = nil :: UIScale?, label = nil :: TextLabel?, icon = nil :: Frame? }

local function buildCoins()
	local root = anchor("Coins", UDim2.fromOffset(270, 64), UDim2.new(0.5, 0, 0, 14), Vector2.new(0.5, 0))
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = root })
	coins.scale = new("UIScale", { Parent = holder })
	local lip = UIKit.Panel({ Name = "Lip", Size = UDim2.new(1, -22, 0, 52), Position = UDim2.fromOffset(22, 11), Color = T.GoldLip, Radius = 26, Parent = holder })
	local _ = lip
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.new(1, -22, 0, 52), Position = UDim2.fromOffset(22, 6), Color = T.Gold, Top = T.GoldTop, Radius = 26, Parent = holder })
	local shine = new("Frame", {
		Size = UDim2.new(1, -60, 0, 6),
		Position = UDim2.new(0.5, 14, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = pill,
	})
	UIKit.Corner(shine, UDim.new(1, 0))
	coins.label = UIKit.Label({
		Name = "Amount",
		Text = "0",
		TextSize = 36,
		Stroke = 4,
		Size = UDim2.new(1, -62, 1, 0),
		Position = UDim2.fromOffset(52, -1),
		Parent = pill,
	})
	local icon = UIKit.Coin(66, holder)
	icon.Position = UDim2.fromOffset(0, -1)
	coins.icon = icon
end

local function stepCoins(dt: number)
	local label = coins.label
	if not label then
		return
	end
	if os.clock() >= coins.holdUntil then
		coins.target = num(LocalPlayer, "Coins", 0)
	end
	local d = coins.target - coins.shown
	if math.abs(d) < 1 then
		coins.shown = coins.target
	else
		coins.shown += d * (1 - math.exp(-7 * dt)) + math.sign(d)
	end
	label.Text = UIKit.Number(coins.shown)
end

--------------------------------------------------------------------------------
-- altitude gauge

local gauge = { root = nil :: Frame?, marker = nil :: Frame?, value = nil :: TextLabel?, height = 340, top = 50 }

local function gaugeY(alt: number): number
	return gauge.top + gauge.height * (1 - math.clamp(alt / GAUGE_TOP, 0, 1))
end

local function buildGauge()
	local h = gauge.height
	local root = anchor("Altitude", UDim2.fromOffset(200, h + gauge.top + 16), UDim2.new(1, -16, 0.5, -34), Vector2.new(1, 0.5))
	gauge.root = root
	local barX = 200 - 34
	-- your altitude, in a red tag on top of the gauge
	local tag = UIKit.Panel({ Name = "Tag", Size = UDim2.fromOffset(96, 34), Position = UDim2.fromOffset(barX + 30, 4), AnchorPoint = Vector2.new(1, 0), Color = T.Red, Top = T.RedTop, Radius = 11, Outline = 3.5, Stripes = true, Parent = root })
	gauge.value = UIKit.Label({ Text = "0m", TextSize = 22, Stroke = 3, ZIndex = 2, Parent = tag })

	local bar = UIKit.Panel({ Name = "Bar", Size = UDim2.fromOffset(30, h), Position = UDim2.fromOffset(barX, gauge.top), Color = T.Dark, Radius = 15, Parent = root })
	for i, z in ZONES do
		local y0, y1 = gaugeY(z.To) - gauge.top, gaugeY(z.From) - gauge.top
		local band = new("Frame", {
			Name = z.Name,
			Size = UDim2.new(1, -8, 0, y1 - y0 - (if i == 1 then 4 else 2)),
			Position = UDim2.fromOffset(4, y0 + (if i == #ZONES then 4 else 1)),
			BorderSizePixel = 0,
			Parent = bar,
		})
		UIKit.Corner(band, UDim.new(0, 11))
		UIKit.Gloss(band, z.Top, z.Bottom, 1)
		UIKit.Label({
			Text = z.Name,
			TextSize = 13,
			Stroke = 2,
			Size = UDim2.fromOffset(y1 - y0, 20),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = -90,
			Parent = band,
		})
	end
	-- island notches with names
	for _, spot in Flight.GetSpots() do
		if spot.Name ~= FlightConfig.Home.Name then
			local y = gaugeY(spot.Top.Y)
			local notch = new("Frame", {
				Size = UDim2.fromOffset(14, 6),
				Position = UDim2.fromOffset(barX - 6, y),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = root,
			})
			UIKit.Corner(notch, UDim.new(1, 0))
			UIKit.Stroke(notch, 2)
			UIKit.Label({
				Text = prettyName(spot.Name),
				TextSize = 13,
				Stroke = 2.5,
				Size = UDim2.fromOffset(120, 16),
				Position = UDim2.fromOffset(barX - 16, y),
				AnchorPoint = Vector2.new(1, 0.5),
				XAlign = Enum.TextXAlignment.Right,
				Parent = root,
			})
		end
	end
	-- you: a balloon riding up the bar
	local marker = UIKit.BalloonIcon(26, HP_ON, root)
	marker.Name = "You"
	marker.AnchorPoint = Vector2.new(0.5, 0.4)
	for _, d in marker:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 5
		end
	end
	gauge.marker = marker
	root.Visible = false
end

local function stepGauge()
	local root = gauge.root
	local marker = gauge.marker
	if not root or not marker then
		return
	end
	root.Visible = state() ~= "Ground"
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local alt = math.max(0, hrp.Position.Y - 3)
	marker.Position = UDim2.fromOffset(200 - 34 + 15, gaugeY(alt))
	if gauge.value then
		gauge.value.Text = UIKit.Number(alt) .. "m"
	end
end

--------------------------------------------------------------------------------
-- bottom actions: JUMP TO FLY, LAND, LET OUT AIR

local actions = {
	jump = nil :: Frame?,
	jumpScale = nil :: UIScale?,
	land = nil :: any,
	landFill = nil :: Frame?,
	landSpot = nil :: TextLabel?,
	landTag = nil :: Frame?,
	landTitle = nil :: TextLabel?,
	firstRibbon = nil :: Frame?,
	letOut = nil :: any,
	launchedOnce = false,
	landShownAt = 0,
}

local function buildJumpPrompt(root: Frame)
	local holder = new("Frame", { Name = "JumpToFly", Size = UDim2.fromOffset(340, 70), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Parent = root })
	actions.jumpScale = new("UIScale", { Parent = holder })
	UIKit.Panel({ Name = "Lip", Size = UDim2.new(1, 0, 0, 62), Position = UDim2.fromOffset(0, 8), Color = T.RedDark, Radius = 18, Parent = holder })
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.new(1, 0, 0, 62), Color = T.Red, Top = T.RedTop, Radius = 18, Stripes = true, Parent = holder })
	local icon = UIKit.BalloonIcon(30, T.Gold, pill)
	icon.Position = UDim2.new(0, 20, 0.5, -20)
	icon.Name = "Bob"
	for _, d in icon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 2
		end
	end
	UIKit.Label({ Text = "JUMP TO FLY", TextSize = 32, Stroke = 3.5, ZIndex = 3, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(18, -1), Parent = pill })
	keyChip("SPACE", holder, UDim2.new(1, -8, 0, -4), Vector2.new(1, 0.5), 26)
	actions.jump = holder
	holder.Visible = false
end

local function buildLand(root: Frame)
	local btn = UIKit.Button({
		Name = "Land",
		Size = UDim2.fromOffset(270, 84),
		Position = UDim2.new(0.5, 0, 1, -8),
		AnchorPoint = Vector2.new(0.5, 1),
		Face = T.Green,
		Top = T.GreenTop,
		Lip = T.GreenLip,
		Radius = 20,
		LipDepth = 7,
		Parent = root,
	})
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, -14),
		Position = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = btn.Face,
	})
	UIKit.Corner(fill, UDim.new(0, 14))
	actions.landTitle = UIKit.Label({ Text = "LAND", TextSize = 46, Stroke = 4.5, ZIndex = 4, Position = UDim2.fromOffset(0, -1), Parent = btn.Face })
	-- where you'll land, on a little tag over the button
	local tag = UIKit.Panel({ Name = "Spot", Size = UDim2.fromOffset(200, 30), Position = UDim2.new(0.5, 0, 0, -14), AnchorPoint = Vector2.new(0.5, 1), Color = T.Dark, Radius = 10, Outline = 3, Parent = btn.Frame })
	actions.landSpot = UIKit.Label({ Text = "", TextSize = 17, Stroke = 2.5, Parent = tag })
	actions.landTag = tag
	-- first landing hint
	local ribbon = UIKit.Panel({ Name = "First", Size = UDim2.fromOffset(150, 30), Position = UDim2.new(1, 12, 0, 6), AnchorPoint = Vector2.new(1, 0.5), Color = T.Gold, Top = T.GoldTop, Radius = 10, Outline = 3, Parent = btn.Frame })
	ribbon.Rotation = 6
	ribbon.ZIndex = 25
	UIKit.Label({ Text = "FIRST LANDING x2", TextSize = 15, Stroke = 2.5, ZIndex = 26, Parent = ribbon })
	actions.firstRibbon = ribbon
	keyChip("E", btn.Frame, UDim2.fromOffset(4, 4), Vector2.new(0.5, 0.5), 30)

	btn.Hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Flight.SetLanding(true)
		end
	end)
	btn.Hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Flight.SetLanding(false)
		end
	end)
	actions.land = btn
	actions.landFill = fill
	btn.Frame.Visible = false
end

local function arrowDown(parent: Instance, size: number, z: number)
	-- a chunky down arrow: a stem and a chevron made of two rounded bars
	local holder = new("Frame", { Name = "Arrow", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local function bar(w: number, h: number, x: number, y: number, rot: number)
		local b = new("Frame", {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = holder,
		})
		UIKit.Corner(b, UDim.new(1, 0))
		UIKit.Stroke(b, 3)
	end
	local s = size
	bar(s * 0.2, s * 0.62, s * 0.5, s * 0.36, 0)
	bar(s * 0.2, s * 0.5, s * 0.36, s * 0.62, -45)
	bar(s * 0.2, s * 0.5, s * 0.64, s * 0.62, 45)
	return holder
end

local function buildLetOut()
	local root = anchor("LetOutAir", UDim2.fromOffset(132, 124), UDim2.new(1, -18, 1, -18), Vector2.new(1, 1))
	local btn = UIKit.Button({
		Name = "LetOut",
		Size = UDim2.fromOffset(124, 110),
		Position = UDim2.new(0.5, 0, 1, -8),
		AnchorPoint = Vector2.new(0.5, 1),
		Face = T.Blue,
		Top = T.BlueTop,
		Lip = T.BlueLip,
		Radius = 22,
		Parent = root,
	})
	local arrow = arrowDown(btn.Face, 46, 4)
	arrow.Position = UDim2.new(0.5, 0, 0, 12)
	arrow.AnchorPoint = Vector2.new(0.5, 0)
	UIKit.Label({ Text = "LET OUT\nAIR", TextSize = 19, Stroke = 3, ZIndex = 4, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -50), Parent = btn.Face })
	keyChip("SPACE", btn.Frame, UDim2.new(0.5, 0, 0, -2), Vector2.new(0.5, 0.5), 24)
	btn.Hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Flight.SetLetOut(true)
		end
	end)
	btn.Hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Flight.SetLetOut(false)
		end
	end)
	actions.letOut = { root = root, btn = btn }
	root.Visible = false
end

local function buildActions()
	local root = anchor("Actions", UDim2.fromOffset(360, 150), UDim2.new(0.5, 0, 1, -22), Vector2.new(0.5, 1))
	buildJumpPrompt(root)
	buildLand(root)
	buildLetOut()
end

local function stepActions(now: number)
	local s = state()
	local flying = s == "Flying" or s == "Landing"
	if flying then
		actions.launchedOnce = true
	end

	-- JUMP TO FLY: until your first take-off this session (always, until you've landed once)
	local jump = actions.jump
	if jump then
		local character = LocalPlayer.Character
		local ready = s == "Ground" and LocalPlayer:GetAttribute("DataLoaded") == true and character ~= nil and character:FindFirstChild("Balloon") ~= nil
		local want = ready and (not actions.launchedOnce or LocalPlayer:GetAttribute("FirstLanding") == true)
		show(jump, want, actions.jumpScale)
		local bob = jump:FindFirstChild("Pill") and (jump :: any).Pill:FindFirstChild("Bob")
		if bob then
			bob.Position = UDim2.new(0, 20, 0.5, -20 + math.sin(now * 3) * 4)
			bob.Rotation = math.sin(now * 2.2) * 8
		end
	end

	-- LAND: only when an island is in range
	local land = actions.land
	if land then
		local spot = Flight.Spot
		local on = flying and spot ~= nil
		if on and not land.Frame.Visible then
			actions.landShownAt = now
		end
		show(land.Frame, on, land.Scale)
		local settled = now - actions.landShownAt > 0.35
		if on then
			local label = actions.landSpot
			if label then
				label.Text = if spot.Label then string.upper(spot.Label) else prettyName(spot.Name)
			end
			if actions.firstRibbon then
				actions.firstRibbon.Visible = LocalPlayer:GetAttribute("FirstLanding") == true
			end
			local fill = actions.landFill :: Frame
			local title = actions.landTitle :: TextLabel
			if s == "Landing" then
				local total = if LocalPlayer:GetAttribute("FirstLanding") == true then FlightConfig.Land.FirstTime else FlightConfig.Land.Time
				local left = num(LocalPlayer, "LandEnd", 0) - workspace:GetServerTimeNow()
				local k = math.clamp(1 - left / total, 0, 1)
				fill.Size = UDim2.new(k, -14 * k, 1, -14)
				title.Text = "LANDING"
				title.TextSize = 38
				if settled then
					land.Scale.Scale = 1 + math.sin(now * 20) * 0.015
				end
			else
				fill.Size = UDim2.new(0, 0, 1, -14)
				title.Text = "LAND"
				title.TextSize = 46
				-- a gentle "press me" breathe
				if settled then
					land.Scale.Scale = 1 + math.sin(now * 5) * 0.03
				end
			end
		end
	end

	local letOut = actions.letOut
	if letOut then
		show(letOut.root, s == "Flying", letOut.btn.Scale)
	end
end

--------------------------------------------------------------------------------
-- over each flying balloon: unbanked coins, size, HP, risk

type Board = {
	gui: BillboardGui,
	amount: TextLabel,
	amountScale: UIScale,
	row: Frame,
	sizeChip: Frame,
	sizeText: TextLabel,
	pips: { Frame },
	pipRow: Frame,
	riskFill: Frame,
	riskBar: Frame,
	riskLabel: TextLabel,
	maxHP: number,
	last: number,
	lastHP: number,
	flip: number,
	shakeUntil: number,
	radius: number,
	radiusAt: number,
}

local boards: { [Player]: Board } = {}
local boardFolder: Folder

local function buildPips(b: Board, maxHP: number)
	for _, pip in b.pips do
		pip:Destroy()
	end
	b.pips = {}
	local count = math.min(10, math.max(1, math.floor(maxHP + 0.5)))
	for i = 1, count do
		local pip = UIKit.BalloonIcon(15, HP_ON, b.pipRow)
		pip.LayoutOrder = i
		table.insert(b.pips, pip)
	end
	b.maxHP = maxHP
end

local function buildBoard(player: Player): Board
	local isMe = player == LocalPlayer
	local bb = new("BillboardGui", {
		Name = "Balloon_" .. player.Name,
		Size = UDim2.fromOffset(250, 118),
		LightInfluence = 0,
		AlwaysOnTop = isMe,
		MaxDistance = if isMe then 1e5 else 260,
		ResetOnSpawn = false,
		ClipsDescendants = false,
		Parent = boardFolder,
	})
	-- unbanked coins: the big number
	local top = new("Frame", { Name = "Top", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = bb })
	local amountScale = new("UIScale", { Parent = top })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = top,
	})
	local coin = UIKit.Coin(36, top)
	coin.LayoutOrder = 1
	local amount = UIKit.Label({ Name = "Amount", Text = "+0", TextSize = 40, Stroke = 4.5, Size = UDim2.fromOffset(0, 48), Parent = top })
	amount.AutomaticSize = Enum.AutomaticSize.X
	amount.LayoutOrder = 2

	-- size chip + HP balloons
	local row = new("Frame", { Name = "Row", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 54), BackgroundTransparency = 1, Parent = bb })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local chip = UIKit.Panel({ Name = "Size", Size = UDim2.fromOffset(92, 28), Color = T.Red, Top = T.RedTop, Radius = 9, Outline = 3, Stripes = true, Parent = row })
	chip.LayoutOrder = 1
	local sizeText = UIKit.Label({ Text = "SIZE 1", TextSize = 17, Stroke = 2.5, ZIndex = 2, Parent = chip })
	local pipRow = new("Frame", { Name = "HP", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 2, Parent = row })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pipRow,
	})

	-- risk (fragility) bar, or landing progress
	local riskBar = UIKit.Panel({ Name = "Risk", Size = UDim2.fromOffset(150, 14), Position = UDim2.new(0.5, 12, 0, 94), AnchorPoint = Vector2.new(0.5, 0), Color = T.Dark, Radius = 7, Outline = 2.5, Parent = bb })
	local riskFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = riskBar })
	UIKit.Corner(riskFill, UDim.new(0, 7))
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("6BE35A")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex("FFD23F")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("FF3B3B")),
		}),
		Parent = riskFill,
	})
	local riskLabel = UIKit.Label({ Text = "RISK", TextSize = 14, Stroke = 2.5, Size = UDim2.fromOffset(60, 14), Position = UDim2.new(0, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), XAlign = Enum.TextXAlignment.Right, Parent = riskBar })

	local b: Board = {
		gui = bb,
		amount = amount,
		amountScale = amountScale,
		row = row,
		sizeChip = chip,
		sizeText = sizeText,
		pips = {},
		pipRow = pipRow,
		riskFill = riskFill,
		riskBar = riskBar,
		riskLabel = riskLabel,
		maxHP = 0,
		last = -1,
		lastHP = -1,
		flip = 1,
		shakeUntil = 0,
		radius = 3,
		radiusAt = 0,
	}
	buildPips(b, num(player, "MaxHP", 3))
	return b
end

local function stepBoard(player: Player, b: Board, root: BasePart, now: number)
	if b.gui.Adornee ~= root then
		b.gui.Adornee = root
	end
	-- the balloon grows: re-measure it a few times a second, not every frame
	if now - b.radiusAt > 0.25 then
		b.radiusAt = now
		local model = root.Parent
		if model and model:IsA("Model") then
			b.radius = model:GetExtentsSize().Y / 2
		end
		b.gui.StudsOffsetWorldSpace = Vector3.new(0, b.radius + 2.2, 0)
	end

	-- unbanked: pop + tilt every tick so it feels alive
	local unbanked = num(player, "Unbanked", 0)
	if unbanked ~= b.last then
		if b.last >= 0 and unbanked > b.last then
			b.flip = -b.flip
			b.amountScale.Scale = 1.09
			UIKit.Tween(b.amountScale, 0.18, { Scale = 1 })
			b.amount.Rotation = 3 * b.flip
			UIKit.Tween(b.amount, 0.25, { Rotation = 0 }, Enum.EasingStyle.Back)
		end
		b.last = unbanked
		b.amount.Text = "+" .. UIKit.Number(unbanked)
	end

	-- size chip goes gold at max size
	local size = num(player, "Size", 1)
	local maxed = player:GetAttribute("Maxed") == true
	b.sizeText.Text = if maxed then "MAX " .. UIKit.Number(size) else "SIZE " .. UIKit.Number(size)
	b.sizeChip.Size = UDim2.fromOffset(math.max(92, 30 + #b.sizeText.Text * 9), 28)
	local gold = b.sizeChip:FindFirstChildOfClass("UIGradient")
	if gold then
		local c0 = if maxed then T.GoldTop else T.RedTop
		local c1 = if maxed then T.GoldDark else T.Red
		gold.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(0.55, c1), ColorSequenceKeypoint.new(1, c1) })
	end

	-- HP balloons (partial HP shows as a half-deflated balloon)
	local maxHP = num(player, "MaxHP", 3)
	if maxHP ~= b.maxHP then
		buildPips(b, maxHP)
	end
	local hp = num(player, "HP", maxHP)
	if b.lastHP >= 0 and hp < b.lastHP then
		b.shakeUntil = now + 0.35
	end
	b.lastHP = hp
	local perPip = maxHP / #b.pips
	for i, pip in b.pips do
		local v = math.clamp((hp - (i - 1) * perPip) / perPip, 0, 1)
		local body = pip:FindFirstChild("Body") :: Frame?
		local knot = pip:FindFirstChild("Knot") :: Frame?
		if body and knot then
			local color = if v <= 0 then HP_OFF else HP_ON
			body.BackgroundColor3 = color
			knot.BackgroundColor3 = color
			local s = if v <= 0 then 0.8 else 0.62 + 0.38 * v
			body.Size = UDim2.fromOffset(15 * s, 15 * s)
			body.Position = UDim2.fromOffset(15 * (1 - s) / 2, 15 * (1 - s))
		end
	end
	local shake = if now < b.shakeUntil then math.sin(now * 70) * 4 else 0
	b.pipRow.Position = UDim2.fromOffset(shake, 0)

	-- risk: fragility (1 + size / 200) fills the bar; while landing it's the landing timer
	if state(player) == "Landing" then
		local first = player:GetAttribute("FirstLanding") == true
		local total = if first then FlightConfig.Land.FirstTime else FlightConfig.Land.Time
		local k = math.clamp(1 - (num(player, "LandEnd", 0) - workspace:GetServerTimeNow()) / total, 0, 1)
		b.riskFill.Size = UDim2.fromScale(k, 1)
		b.riskFill.BackgroundColor3 = Color3.fromHex("3CCB4A")
		local grad = b.riskFill:FindFirstChildOfClass("UIGradient")
		if grad then
			grad.Enabled = false
		end
		b.riskLabel.Text = "LANDING"
	else
		local risk = math.clamp(size / FlightConfig.Fragility, 0, 1)
		b.riskFill.Size = UDim2.fromScale(math.max(risk, 0.06), 1)
		b.riskFill.BackgroundColor3 = Color3.new(1, 1, 1)
		local grad = b.riskFill:FindFirstChildOfClass("UIGradient")
		if grad then
			grad.Enabled = true
		end
		b.riskLabel.Text = "RISK"
	end
end

local function stepBoards(now: number)
	for _, player in Players:GetPlayers() do
		local s = state(player)
		local character = player.Character
		local balloon = character and character:FindFirstChild("Balloon")
		local root = balloon and (balloon :: Model).PrimaryPart
		local want = (s == "Flying" or s == "Landing") and root ~= nil
		local b = boards[player]
		if want and root then
			if not b then
				b = buildBoard(player)
				boards[player] = b
			end
			stepBoard(player, b :: Board, root, now)
		elseif b then
			b.gui:Destroy()
			boards[player] = nil
		end
	end
	for player, b in boards do
		if player.Parent ~= Players then
			b.gui:Destroy()
			boards[player] = nil
		end
	end
end

--------------------------------------------------------------------------------
-- island markers and the edge arrow

type Marker = { spot: any, gui: BillboardGui, pill: Frame, name: TextLabel, dist: TextLabel, scale: UIScale, part: BasePart }
local markers: { Marker } = {}
local arrow = { root = nil :: Frame?, pointer = nil :: Frame?, dist = nil :: TextLabel? }

local function setPillColor(pill: Frame, top: Color3, base: Color3)
	local g = pill:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.55, base), ColorSequenceKeypoint.new(1, base) })
	end
end

local function buildMarkers()
	local folder = new("Folder", { Name = "IslandMarkers", Parent = workspace })
	for _, spot in Flight.GetSpots() do
		if spot.Name ~= FlightConfig.Home.Name then
			local part = new("Part", {
				Name = spot.Name,
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Transparency = 1,
				Size = Vector3.one,
				Position = spot.Top + Vector3.new(0, 16, 0),
				Parent = folder,
			})
			local bb = new("BillboardGui", {
				Name = "Marker_" .. spot.Name,
				Adornee = part,
				Size = UDim2.fromOffset(210, 86),
				AlwaysOnTop = true,
				LightInfluence = 0,
				MaxDistance = 1e5,
				ResetOnSpawn = false,
				Enabled = false,
				Parent = boardFolder,
			})
			local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bb })
			local scale = new("UIScale", { Parent = holder })
			local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0.5, 0, 0, 4), AnchorPoint = Vector2.new(0.5, 0), Color = T.Red, Top = T.RedTop, Radius = 11, Outline = 3, Stripes = true, Parent = holder })
			local name = UIKit.Label({ Text = prettyName(spot.Name), TextSize = 19, Stroke = 3, ZIndex = 2, Parent = pill })
			local dist = UIKit.Label({ Text = "", TextSize = 17, Stroke = 3, Size = UDim2.fromOffset(190, 20), Position = UDim2.new(0.5, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0), Parent = holder })
			-- a stud diamond pointing down at the island
			local tip = new("Frame", {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0.5, 0, 0, 74),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = 45,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = holder,
			})
			UIKit.Corner(tip, UDim.new(0, 3))
			UIKit.Stroke(tip, 3)
			table.insert(markers, { spot = spot, gui = bb, pill = pill, name = name, dist = dist, scale = scale, part = part })
		end
	end

	-- the edge arrow (nearest island when it's off screen)
	local root = anchor("IslandArrow", UDim2.fromOffset(90, 90), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	local pointer = new("Frame", { Name = "Pointer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = root })
	local tip = new("Frame", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		BackgroundColor3 = T.Red,
		BorderSizePixel = 0,
		Parent = pointer,
	})
	UIKit.Corner(tip, UDim.new(0, 5))
	UIKit.Stroke(tip, 3.5)
	local disc = UIKit.Panel({ Name = "Disc", Size = UDim2.fromOffset(62, 62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Red, Top = T.RedTop, Radius = 31, Parent = root })
	disc.ZIndex = 2
	local icon = UIKit.BalloonIcon(20, T.Gold, disc)
	icon.Position = UDim2.new(0.5, -10, 0, 7)
	for _, d in icon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 2
		end
	end
	arrow.dist = UIKit.Label({ Text = "", TextSize = 15, Stroke = 2.5, ZIndex = 5, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -24), Parent = disc })
	arrow.root = root
	arrow.pointer = pointer
	root.Visible = false
end

local function stepMarkers(now: number)
	local s = state()
	local flying = s == "Flying" or s == "Landing"
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local pos = if hrp then hrp.Position else Vector3.zero
	for _, m in markers do
		local d = (m.spot.Top - pos).Magnitude
		local on = flying and hrp ~= nil and d > 28
		if on ~= m.gui.Enabled then
			m.gui.Enabled = on
			if on then
				m.scale.Scale = 0.5
				UIKit.Tween(m.scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
		if on then
			local landable = Flight.Spot == m.spot
			if landable then
				m.name.Text = "LAND HERE!"
				setPillColor(m.pill, T.GreenTop, T.Green)
				m.scale.Scale = 1 + math.sin(now * 6) * 0.05
			else
				m.name.Text = prettyName(m.spot.Name)
				setPillColor(m.pill, T.RedTop, T.Red)
			end
			m.dist.Text = UIKit.Number(d) .. "m"
		end
	end

	-- edge arrow to the nearest island when it's off screen
	local root = arrow.root
	local pointer = arrow.pointer
	local nearest = Flight.Nearest
	local cam = workspace.CurrentCamera
	if not root or not pointer then
		return
	end
	if not flying or not nearest or not cam or Flight.Spot ~= nil then
		root.Visible = false
		return
	end
	local world = nearest.Top + Vector3.new(0, 16, 0)
	local sp, onScreen = cam:WorldToViewportPoint(world)
	local vp = cam.ViewportSize
	if onScreen and sp.X > 60 and sp.X < vp.X - 60 and sp.Y > 60 and sp.Y < vp.Y - 60 then
		root.Visible = false
		return
	end
	local center = vp / 2
	local dir = Vector2.new(sp.X, sp.Y) - center
	if sp.Z < 0 then
		dir = -dir
	end
	if dir.Magnitude < 1 then
		dir = Vector2.new(0, -1)
	end
	local unit = dir.Unit
	local margin = 80
	local hx, hy = center.X - margin, center.Y - margin
	local t = math.min(hx / math.max(math.abs(unit.X), 1e-3), hy / math.max(math.abs(unit.Y), 1e-3))
	local at = center + unit * t
	root.Position = UDim2.fromOffset(at.X, at.Y)
	pointer.Rotation = math.deg(math.atan2(unit.Y, unit.X))
	if arrow.dist then
		arrow.dist.Text = UIKit.Number((nearest.Top - (if hrp then hrp.Position else Vector3.zero)).Magnitude) .. "m"
	end
	root.Visible = true
end

--------------------------------------------------------------------------------
-- cards: BANKED!, POPPED!, toasts

local cardSlot: Frame
local toastSlot: Frame
local cardToken = 0

local function card(title: string, headerTop: Color3, headerBase: Color3): (CanvasGroup, Frame)
	for _, old in cardSlot:GetChildren() do
		if old:IsA("CanvasGroup") then
			old:Destroy()
		end
	end
	local group = new("CanvasGroup", {
		Name = "Card",
		Size = UDim2.fromOffset(460, 250),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		GroupTransparency = 0,
		Parent = cardSlot,
	})
	local scale = new("UIScale", { Scale = 0.3, Parent = group })
	local panel = UIKit.Panel({ Name = "Panel", Size = UDim2.fromOffset(400, 190), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.RedDark, Radius = 18, Outline = 4, Parent = group })
	local header = UIKit.Panel({ Name = "Header", Size = UDim2.new(1, 0, 0, 62), Color = headerBase, Top = headerTop, Radius = 18, Outline = 4, Stripes = true, Parent = panel })
	UIKit.Label({ Text = title, TextSize = 44, Stroke = 4.5, ZIndex = 3, Position = UDim2.fromOffset(0, -1), Parent = header })
	UIKit.Tween(scale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
	return group, panel
end

local function dismiss(group: CanvasGroup, after: number)
	cardToken += 1
	local token = cardToken
	task.delay(after, function()
		if token ~= cardToken or not group.Parent then
			return
		end
		UIKit.Tween(group, 0.35, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -30) })
		task.delay(0.4, function()
			if group.Parent then
				group:Destroy()
			end
		end)
	end)
end

function HUDController.Toast(text: string, color: Color3?)
	for _, old in toastSlot:GetChildren() do
		old:Destroy()
	end
	local group = new("CanvasGroup", { Size = UDim2.fromOffset(520, 56), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, GroupTransparency = 1, Parent = toastSlot })
	local pill = UIKit.Panel({ Size = UDim2.new(1, -16, 0, 42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = color or T.Dark, Radius = 21, Outline = 3, Parent = group })
	UIKit.Label({ Text = text, TextSize = 21, Stroke = 3, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), Parent = pill })
	UIKit.Tween(group, 0.2, { GroupTransparency = 0 })
	task.delay(2.2, function()
		if group.Parent then
			UIKit.Tween(group, 0.3, { GroupTransparency = 1 })
			task.delay(0.35, function()
				group:Destroy()
			end)
		end
	end)
end

-- coins fly from the card into the counter, which counts up as they land
local function coinFountain(from: GuiObject, amount: number)
	local target = coins.icon
	if not target then
		return
	end
	local startCoins = coins.shown
	local finalCoins = num(LocalPlayer, "Coins", startCoins + amount)
	coins.holdUntil = os.clock() + 2
	coins.target = startCoins
	local n = math.clamp(6 + math.floor(math.log10(math.max(amount, 1)) * 3), 6, 18)
	local origin = fxLayer.AbsolutePosition
	local a = from.AbsolutePosition + from.AbsoluteSize / 2 - origin
	local b = target.AbsolutePosition + target.AbsoluteSize / 2 - origin
	local arrived = 0
	for i = 1, n do
		task.delay(0.35 + i * 0.05, function()
			local size = math.random(26, 38)
			local c = UIKit.Coin(size, fxLayer)
			c.AnchorPoint = Vector2.new(0.5, 0.5)
			c.ZIndex = 50
			for _, d in c:GetDescendants() do
				if d:IsA("GuiObject") then
					d.ZIndex = 51
				end
			end
			local burst = Vector2.new(math.random(-130, 130), math.random(-120, -30))
			local mid = a + burst
			local t0 = os.clock()
			local dur = 0.55 + math.random() * 0.25
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local t = math.clamp((os.clock() - t0) / dur, 0, 1)
				local e = t * t * (3 - 2 * t)
				local p = a:Lerp(mid, e):Lerp(mid:Lerp(b, e), e)
				c.Position = UDim2.fromOffset(p.X, p.Y)
				c.Rotation = (1 - t) * 180
				local s = 1 - 0.35 * t
				c.Size = UDim2.fromOffset(size * s, size * s)
				if t >= 1 then
					conn:Disconnect()
					c:Destroy()
					arrived += 1
					coins.target = startCoins + (finalCoins - startCoins) * arrived / n
					if coins.scale then
						UIKit.Pop(coins.scale, 0.12)
					end
					if arrived >= n then
						coins.holdUntil = 0
					end
				end
			end)
		end)
	end
end

local function onBanked(amount: number, spotName: string, bonus: number, size: number)
	local group, panel = card("BANKED!", T.GreenTop, T.Green)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 64), Position = UDim2.fromOffset(0, 72), BackgroundTransparency = 1, Parent = panel })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local coin = UIKit.Coin(54, row)
	coin.LayoutOrder = 1
	local label = UIKit.Label({ Text = "+0", TextSize = 56, Stroke = 5, Size = UDim2.fromOffset(0, 60), Parent = row })
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = 2
	local where = if spotName ~= "" then "Landed on " .. titleName(spotName) else "Landed"
	UIKit.Label({ Text = where .. "  •  size " .. UIKit.Number(size), TextSize = 19, Stroke = 2.5, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 142), Parent = panel })
	if bonus > 1 then
		local ribbon = UIKit.Panel({ Name = "Bonus", Size = UDim2.fromOffset(210, 36), Position = UDim2.new(0.5, 0, 1, 2), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Gold, Top = T.GoldTop, Radius = 12, Outline = 3.5, Parent = panel })
		ribbon.Rotation = -3
		ribbon.ZIndex = 5
		UIKit.Label({ Text = "FIRST LANDING x" .. bonus, TextSize = 20, Stroke = 3, ZIndex = 6, Parent = ribbon })
	end
	-- count the card number up quickly, then send the coins flying
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - t0) / 0.5, 0, 1)
		label.Text = "+" .. UIKit.Number(amount * (1 - (1 - t) ^ 3))
		if t >= 1 or not label.Parent then
			conn:Disconnect()
		end
	end)
	coinFountain(coin, amount)
	dismiss(group, 2.8)
end

local function onPopped(size: number, lost: number)
	local group, panel = card("POPPED!", Color3.fromHex("6B4A7A"), Color3.fromHex("3A1830"))
	UIKit.Label({ Text = "Popped at size " .. UIKit.Number(size), TextSize = 24, Stroke = 3, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 74), Parent = panel })
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 106), BackgroundTransparency = 1, Parent = panel })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local coin = UIKit.Coin(38, row)
	coin.LayoutOrder = 1
	local lostLabel = UIKit.Label({ Text = "-" .. UIKit.Number(lost) .. " lost", TextSize = 36, Stroke = 4, Color = Color3.fromHex("FFD0D0"), Size = UDim2.fromOffset(0, 44), Parent = row })
	lostLabel.AutomaticSize = Enum.AutomaticSize.X
	lostLabel.LayoutOrder = 2
	UIKit.Label({ Text = "Land sooner next time!", TextSize = 17, Stroke = 2.5, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 160), Parent = panel })
	dismiss(group, 3.4)
end

--------------------------------------------------------------------------------
-- start

local function rescale()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local vp = cam.ViewportSize
	local s = math.clamp(math.min(vp.X / 1280, vp.Y / 760), 0.62, 1.25)
	for _, sc in viewportScales do
		sc.Scale = s
	end
end

local function refreshKeys()
	local last = UserInputService:GetLastInputType()
	local keyboard = last == Enum.UserInputType.Keyboard or last.Name:find("Mouse") ~= nil
	if not UserInputService.KeyboardEnabled then
		keyboard = false
	end
	for _, chip in keyChips do
		chip.Visible = keyboard
	end
end

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
	Flight: any,
}

function HUDController.Start(opts: StartOptions)
	local shared = opts.Shared
	UIKit = require(shared:WaitForChild("UI"):WaitForChild("UIKit") :: ModuleScript) :: any
	T = UIKit.Theme
	new = UIKit.new
	local config = shared:WaitForChild("Config")
	FlightConfig = require(config:WaitForChild("FlightConfig") :: ModuleScript) :: any
	Flight = opts.Flight
	Net = opts.RemoteParent:WaitForChild("FlightNet") :: RemoteEvent

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("BalloonHUD")
	if old then
		old:Destroy()
	end
	gui = new("ScreenGui", {
		Name = "BalloonHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
		Parent = playerGui,
	})
	boardFolder = new("Folder", { Name = "BalloonHUDWorld", Parent = playerGui })
	fxLayer = new("Frame", { Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = gui })

	buildCoins()
	buildGauge()
	buildActions()
	buildMarkers()
	cardSlot = anchor("Cards", UDim2.fromOffset(460, 250), UDim2.fromScale(0.5, 0.34), Vector2.new(0.5, 0.5))
	toastSlot = anchor("Toasts", UDim2.fromOffset(520, 56), UDim2.new(0.5, 0, 1, -200), Vector2.new(0.5, 0.5))

	rescale()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		rescale()
		local c = workspace.CurrentCamera
		if c then
			c:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
		end
	end)
	refreshKeys()
	UserInputService.LastInputTypeChanged:Connect(refreshKeys)

	coins.shown = num(LocalPlayer, "Coins", 0)
	coins.target = coins.shown

	local maxToastFor = -1
	Net.OnClientEvent:Connect(function(kind: string, ...)
		if kind == "Banked" then
			local amount, spotName, bonus, size = ...
			onBanked(amount, spotName, bonus, size)
		elseif kind == "Popped" then
			local size, lost = ...
			onPopped(size, lost)
		elseif kind == "Toast" then
			HUDController.Toast((...))
		end
	end)

	local launches = 0
	LocalPlayer:GetAttributeChangedSignal("FlightState"):Connect(function()
		if state() == "Flying" and LocalPlayer:GetAttribute("Size") == 1 then
			launches += 1
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("Maxed"):Connect(function()
		if LocalPlayer:GetAttribute("Maxed") == true and launches ~= maxToastFor and state() == "Flying" then
			maxToastFor = launches
			HUDController.Toast("MAX SIZE! Land to bank it", T.GoldLip)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		stepCoins(dt)
		stepGauge()
		stepActions(now)
		stepBoards(now)
		stepMarkers(now)
	end)
end

return HUDController
