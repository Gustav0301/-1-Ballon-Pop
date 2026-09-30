--!strict
-- HUDTemplate: builds the flight HUD as a normal ScreenGui ("BalloonHUD") so it can live
-- in StarterGui and be edited in Studio like any other UI.
--
-- Install it once (Studio, edit mode, View > Command Bar), then edit freely:
--   require(workspace.GamePack.Shared.UI.HUDTemplate).Install()          -- drag-in pack
--   require(game.ReplicatedStorage.Shared.UI.HUDTemplate).Install()      -- Rojo
--
-- HUDController finds pieces BY NAME, so you can move, resize, recolour, restyle, change
-- fonts and texts, and add decorations. Just keep the names listed in docs/HUD_EDITING.md.
-- The pieces that get copied at runtime (balloon billboard, island marker, cards, toast,
-- flying coin, HP balloon) are in the "Templates" folder, hidden: tick Visible to edit one.

local UIKit = require(script.Parent.UIKit)

local HUDTemplate = {}

local T = UIKit.Theme
local new = UIKit.new

HUDTemplate.GaugeTop = 1500 -- altitude at the top of the altitude gauge
HUDTemplate.Zones = {
	{ Name = "MEADOW SKY", From = 0, To = 500, Top = Color3.fromHex("8FE3FF"), Bottom = Color3.fromHex("63D56E") },
	{ Name = "CLOUD SHELF", From = 500, To = 1500, Top = Color3.fromHex("E9F1FF"), Bottom = Color3.fromHex("B7CCFF") },
}
HUDTemplate.HPOn = Color3.fromHex("FF3B4E")
HUDTemplate.HPOff = Color3.fromHex("5A4A66")

local function prettyName(name: string): string
	return (name:gsub("(%l)(%u)", "%1 %2"):upper())
end

local function lift(obj: Instance, by: number)
	for _, d in obj:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += by
		end
	end
	if obj:IsA("GuiObject") then
		obj.ZIndex += by
	end
end

-- a top-level container; its "ViewportScale" UIScale is sized to the screen at runtime
local function anchor(gui: Instance, name: string, size: UDim2, pos: UDim2, ap: Vector2): Frame
	local frame = new("Frame", { Name = name, Size = size, Position = pos, AnchorPoint = ap, BackgroundTransparency = 1, Parent = gui })
	new("UIScale", { Name = "ViewportScale", Parent = frame })
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
	return chip
end

local function row(parent: Instance, name: string, size: UDim2, pos: UDim2, pad: number): Frame
	local frame = new("Frame", { Name = name, Size = size, Position = pos, BackgroundTransparency = 1, Parent = parent })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, pad),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})
	return frame
end

local function arrowDown(parent: Instance, size: number, z: number): Frame
	local holder = new("Frame", { Name = "Arrow", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	-- outlines first, white on top, so the three bars read as one arrow
	local function bar(w: number, h: number, x: number, y: number, rot: number, outline: boolean)
		local pad = if outline then 6 else 0
		local b = new("Frame", {
			Name = if outline then "Edge" else "Bar",
			Size = UDim2.fromOffset(w + pad, h + pad),
			Position = UDim2.fromOffset(x, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot,
			BackgroundColor3 = if outline then T.Outline else Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = if outline then z else z + 1,
			Parent = holder,
		})
		UIKit.Corner(b, UDim.new(1, 0))
	end
	local s = size
	for _, outline in { true, false } do
		bar(s * 0.2, s * 0.62, s * 0.5, s * 0.36, 0, outline)
		bar(s * 0.2, s * 0.5, s * 0.36, s * 0.62, -45, outline)
		bar(s * 0.2, s * 0.5, s * 0.64, s * 0.62, 45, outline)
	end
	return holder
end

--------------------------------------------------------------------------------
-- screen pieces

local function buildCoins(gui: Instance)
	-- under the top bar (BalloonMenus.TopBar)
	local root = anchor(gui, "Coins", UDim2.fromOffset(270, 64), UDim2.new(0.5, 0, 0, 100), Vector2.new(0.5, 0))
	local holder = new("Frame", { Name = "Holder", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = root })
	new("UIScale", { Name = "Pop", Parent = holder })
	UIKit.Panel({ Name = "Lip", Size = UDim2.new(1, -22, 0, 52), Position = UDim2.fromOffset(22, 11), Color = T.GoldLip, Radius = 26, Parent = holder })
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.new(1, -22, 0, 52), Position = UDim2.fromOffset(22, 6), Color = T.Gold, Top = T.GoldTop, Radius = 26, Parent = holder })
	local shine = new("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, -60, 0, 6),
		Position = UDim2.new(0.5, 14, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = pill,
	})
	UIKit.Corner(shine, UDim.new(1, 0))
	UIKit.Label({ Name = "Amount", Text = "0", TextSize = 36, Stroke = 4, Size = UDim2.new(1, -62, 1, 0), Position = UDim2.fromOffset(52, -1), Parent = pill })
	local icon = UIKit.Coin(66, holder)
	icon.Position = UDim2.fromOffset(0, -1)
end

local function buildGauge(gui: Instance, spots: { any })
	local h, top = 340, 50
	local function y(alt: number): number
		return top + h * (1 - math.clamp(alt / HUDTemplate.GaugeTop, 0, 1))
	end
	local root = anchor(gui, "Altitude", UDim2.fromOffset(200, h + top + 16), UDim2.new(1, -16, 0.5, -34), Vector2.new(1, 0.5))
	root:SetAttribute("MaxAltitude", HUDTemplate.GaugeTop)
	local barX = 200 - 34
	local tag = UIKit.Panel({ Name = "Tag", Size = UDim2.fromOffset(96, 34), Position = UDim2.fromOffset(barX + 30, 4), AnchorPoint = Vector2.new(1, 0), Color = T.Red, Top = T.RedTop, Radius = 11, Outline = 3.5, Stripes = true, Parent = root })
	UIKit.Label({ Name = "Value", Text = "0m", TextSize = 22, Stroke = 3, ZIndex = 2, Parent = tag })

	local bar = UIKit.Panel({ Name = "Bar", Size = UDim2.fromOffset(30, h), Position = UDim2.fromOffset(barX, top), Color = T.Dark, Radius = 15, Parent = root })
	for i, z in HUDTemplate.Zones do
		local y0, y1 = y(z.To) - top, y(z.From) - top
		local band = new("Frame", {
			Name = z.Name,
			Size = UDim2.new(1, -8, 0, y1 - y0 - (if i == 1 then 4 else 2)),
			Position = UDim2.fromOffset(4, y0 + (if i == #HUDTemplate.Zones then 4 else 1)),
			BorderSizePixel = 0,
			Parent = bar,
		})
		UIKit.Corner(band, UDim.new(0, 11))
		UIKit.Gloss(band, z.Top, z.Bottom, 1)
		UIKit.Label({ Name = "Label", Text = z.Name, TextSize = 13, Stroke = 2, Size = UDim2.fromOffset(y1 - y0, 20), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -90, Parent = band })
	end
	local islands = new("Frame", { Name = "Islands", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = root })
	for _, spot in spots do
		local yy = y(spot.Top.Y)
		local notch = new("Frame", {
			Name = "Notch_" .. spot.Name,
			Size = UDim2.fromOffset(14, 6),
			Position = UDim2.fromOffset(barX - 6, yy),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = islands,
		})
		UIKit.Corner(notch, UDim.new(1, 0))
		UIKit.Stroke(notch, 2)
		UIKit.Label({
			Name = "Label_" .. spot.Name,
			Text = prettyName(spot.Name),
			TextSize = 13,
			Stroke = 2.5,
			Size = UDim2.fromOffset(120, 16),
			Position = UDim2.fromOffset(barX - 16, yy),
			AnchorPoint = Vector2.new(1, 0.5),
			XAlign = Enum.TextXAlignment.Right,
			Parent = islands,
		})
	end
	local you = UIKit.BalloonIcon(26, HUDTemplate.HPOn, root)
	you.Name = "You"
	you.AnchorPoint = Vector2.new(0.5, 0.4)
	you.Position = UDim2.fromOffset(barX + 15, y(318))
	lift(you, 5)
end

local function buildActions(gui: Instance)
	local root = anchor(gui, "Actions", UDim2.fromOffset(360, 150), UDim2.new(0.5, 0, 1, -22), Vector2.new(0.5, 1))

	-- JUMP TO FLY
	local jump = new("Frame", { Name = "JumpToFly", Size = UDim2.fromOffset(340, 70), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Parent = root })
	new("UIScale", { Name = "Pop", Parent = jump })
	UIKit.Panel({ Name = "Lip", Size = UDim2.new(1, 0, 0, 62), Position = UDim2.fromOffset(0, 8), Color = T.RedDark, Radius = 18, Parent = jump })
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.new(1, 0, 0, 62), Color = T.Red, Top = T.RedTop, Radius = 18, Stripes = true, Parent = jump })
	local bob = UIKit.BalloonIcon(30, T.Gold, pill)
	bob.Name = "Bob"
	bob.Position = UDim2.new(0, 20, 0.5, -20)
	lift(bob, 2)
	UIKit.Label({ Name = "Text", Text = "JUMP TO FLY", TextSize = 32, Stroke = 3.5, ZIndex = 3, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(18, -1), Parent = pill })
	keyChip("SPACE", jump, UDim2.new(1, -8, 0, -4), Vector2.new(1, 0.5), 26)
	jump.Visible = false -- tick Visible to see it while editing (the game shows it on the ground)

	-- LAND
	local land = UIKit.Button({ Name = "Land", Size = UDim2.fromOffset(270, 84), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), Face = T.Green, Top = T.GreenTop, Lip = T.GreenLip, Radius = 20, LipDepth = 7, Parent = root })
	local fill = new("Frame", { Name = "Fill", Size = UDim2.new(0.45, -7, 1, -14), Position = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 3, Parent = land.Face })
	UIKit.Corner(fill, UDim.new(0, 14))
	UIKit.Label({ Name = "Title", Text = "LAND", TextSize = 46, Stroke = 4.5, ZIndex = 4, Position = UDim2.fromOffset(0, -1), Parent = land.Face })
	local spotTag = UIKit.Panel({ Name = "Spot", Size = UDim2.fromOffset(200, 30), Position = UDim2.new(0.5, 0, 0, -14), AnchorPoint = Vector2.new(0.5, 1), Color = T.Dark, Radius = 10, Outline = 3, Parent = land.Frame })
	UIKit.Label({ Name = "Text", Text = "WINDMILL HILL", TextSize = 17, Stroke = 2.5, Parent = spotTag })
	local ribbon = UIKit.Panel({ Name = "First", Size = UDim2.fromOffset(150, 30), Position = UDim2.new(1, 12, 0, 6), AnchorPoint = Vector2.new(1, 0.5), Color = T.Gold, Top = T.GoldTop, Radius = 10, Outline = 3, Parent = land.Frame })
	ribbon.Rotation = 6
	ribbon.ZIndex = 25
	UIKit.Label({ Name = "Text", Text = "FIRST LANDING x2", TextSize = 15, Stroke = 2.5, ZIndex = 26, Parent = ribbon })
	keyChip("E", land.Frame, UDim2.fromOffset(4, 4), Vector2.new(0.5, 0.5), 30)

	-- LET OUT AIR (its own corner)
	local corner = anchor(gui, "LetOutAir", UDim2.fromOffset(132, 124), UDim2.new(1, -18, 1, -18), Vector2.new(1, 1))
	local btn = UIKit.Button({ Name = "LetOut", Size = UDim2.fromOffset(124, 110), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), Face = T.Blue, Top = T.BlueTop, Lip = T.BlueLip, Radius = 22, Parent = corner })
	local arrow = arrowDown(btn.Face, 46, 4)
	arrow.Position = UDim2.new(0.5, 0, 0, 12)
	arrow.AnchorPoint = Vector2.new(0.5, 0)
	UIKit.Label({ Name = "Text", Text = "LET OUT\nAIR", TextSize = 19, Stroke = 3, ZIndex = 4, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -50), Parent = btn.Face })
	keyChip("SPACE", btn.Frame, UDim2.new(0.5, 0, 0, -2), Vector2.new(0.5, 0.5), 24)
end

local function buildArrow(gui: Instance)
	local root = anchor(gui, "IslandArrow", UDim2.fromOffset(90, 90), UDim2.new(0, 110, 0.5, 0), Vector2.new(0.5, 0.5))
	local pointer = new("Frame", { Name = "Pointer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = 180, Parent = root })
	local tip = new("Frame", { Name = "Tip", Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = T.Red, BorderSizePixel = 0, Parent = pointer })
	UIKit.Corner(tip, UDim.new(0, 5))
	UIKit.Stroke(tip, 3.5)
	local disc = UIKit.Panel({ Name = "Disc", Size = UDim2.fromOffset(62, 62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Red, Top = T.RedTop, Radius = 31, Parent = root })
	disc.ZIndex = 2
	local icon = UIKit.BalloonIcon(20, T.Gold, disc)
	icon.Position = UDim2.new(0.5, -10, 0, 7)
	lift(icon, 2)
	UIKit.Label({ Name = "Distance", Text = "120m", TextSize = 15, Stroke = 2.5, ZIndex = 5, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -24), Parent = disc })
end

--------------------------------------------------------------------------------
-- templates (copied at runtime)

local function buildBoard(folder: Instance)
	local bb = new("BillboardGui", { Name = "BalloonBoard", Size = UDim2.fromOffset(250, 118), LightInfluence = 0, ResetOnSpawn = false, ClipsDescendants = false, Parent = folder })
	local top = row(bb, "Top", UDim2.new(1, 0, 0, 52), UDim2.new(), 6)
	new("UIScale", { Name = "Pop", Parent = top })
	UIKit.Coin(36, top).LayoutOrder = 1
	local amount = UIKit.Label({ Name = "Amount", Text = "+2,184", TextSize = 40, Stroke = 4.5, Size = UDim2.fromOffset(0, 48), Parent = top })
	amount.AutomaticSize = Enum.AutomaticSize.X
	amount.LayoutOrder = 2

	local mid = row(bb, "Row", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 54), 8)
	local chip = UIKit.Panel({ Name = "Size", Size = UDim2.fromOffset(92, 28), Color = T.Red, Top = T.RedTop, Radius = 9, Outline = 3, Stripes = true, Parent = mid })
	chip.LayoutOrder = 1
	UIKit.Label({ Name = "Text", Text = "SIZE 38", TextSize = 17, Stroke = 2.5, ZIndex = 2, Parent = chip })
	local hp = new("Frame", { Name = "HP", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 2, Parent = mid })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = hp })

	local risk = UIKit.Panel({ Name = "Risk", Size = UDim2.fromOffset(150, 14), Position = UDim2.new(0.5, 12, 0, 94), AnchorPoint = Vector2.new(0.5, 0), Color = T.Dark, Radius = 7, Outline = 2.5, Parent = bb })
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = risk })
	UIKit.Corner(fill, UDim.new(0, 7))
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("6BE35A")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex("FFD23F")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("FF3B3B")),
		}),
		Parent = fill,
	})
	UIKit.Label({ Name = "Label", Text = "RISK", TextSize = 14, Stroke = 2.5, Size = UDim2.fromOffset(60, 14), Position = UDim2.new(0, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), XAlign = Enum.TextXAlignment.Right, Parent = risk })

	local pip = UIKit.BalloonIcon(15, HUDTemplate.HPOn, folder)
	pip.Name = "HPPip"
	pip.Visible = false
end

local function buildMarker(folder: Instance)
	local bb = new("BillboardGui", { Name = "IslandMarker", Size = UDim2.fromOffset(230, 104), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 1e5, ResetOnSpawn = false, Parent = folder })
	local holder = new("Frame", { Name = "Holder", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bb })
	new("UIScale", { Name = "Pop", Parent = holder })
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.fromOffset(200, 34), Position = UDim2.new(0.5, 0, 0, 4), AnchorPoint = Vector2.new(0.5, 0), Color = T.Red, Top = T.RedTop, Radius = 11, Outline = 3, Stripes = true, Parent = holder })
	UIKit.Label({ Name = "Name", Text = "WINDMILL HILL", TextSize = 19, Stroke = 3, ZIndex = 2, Parent = pill })
	UIKit.Label({ Name = "Distance", Text = "84m", TextSize = 17, Stroke = 3, Size = UDim2.fromOffset(220, 20), Position = UDim2.new(0.5, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0), Parent = holder })
	UIKit.Label({ Name = "Hint", Text = "HOLD SPACE", TextSize = 15, Stroke = 3, Color = Color3.fromHex("FFE27A"), Size = UDim2.fromOffset(220, 18), Position = UDim2.new(0.5, 0, 0, 64), AnchorPoint = Vector2.new(0.5, 0), Parent = holder })
	local tip = new("Frame", { Name = "Tip", Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = holder })
	UIKit.Corner(tip, UDim.new(0, 3))
	UIKit.Stroke(tip, 3)
end

local function card(folder: Instance, name: string, title: string, headerTop: Color3, headerBase: Color3): Frame
	local group = new("CanvasGroup", { Name = name, Size = UDim2.fromOffset(460, 250), Position = UDim2.fromScale(0.5, 0.34), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = folder })
	new("UIScale", { Name = "Pop", Parent = group })
	local panel = UIKit.Panel({ Name = "Panel", Size = UDim2.fromOffset(400, 190), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.RedDark, Radius = 18, Outline = 4, Parent = group })
	local header = UIKit.Panel({ Name = "Header", Size = UDim2.new(1, 0, 0, 62), Color = headerBase, Top = headerTop, Radius = 18, Outline = 4, Stripes = true, Parent = panel })
	UIKit.Label({ Name = "Title", Text = title, TextSize = 44, Stroke = 4.5, ZIndex = 3, Position = UDim2.fromOffset(0, -1), Parent = header })
	return panel
end

local function buildCards(folder: Instance)
	local banked = card(folder, "BankedCard", "BANKED!", T.GreenTop, T.Green)
	local r = row(banked, "Row", UDim2.new(1, 0, 0, 64), UDim2.fromOffset(0, 72), 10)
	UIKit.Coin(54, r).LayoutOrder = 1
	local amount = UIKit.Label({ Name = "Amount", Text = "+4,368", TextSize = 56, Stroke = 5, Size = UDim2.fromOffset(0, 60), Parent = r })
	amount.AutomaticSize = Enum.AutomaticSize.X
	amount.LayoutOrder = 2
	UIKit.Label({ Name = "Where", Text = "Landed on Windmill Hill  •  size 38", TextSize = 19, Stroke = 2.5, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 142), Parent = banked })
	local ribbon = UIKit.Panel({ Name = "Bonus", Size = UDim2.fromOffset(210, 36), Position = UDim2.new(0.5, 0, 1, 2), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Gold, Top = T.GoldTop, Radius = 12, Outline = 3.5, Parent = banked })
	ribbon.Rotation = -3
	ribbon.ZIndex = 5
	UIKit.Label({ Name = "Text", Text = "FIRST LANDING x2", TextSize = 20, Stroke = 3, ZIndex = 6, Parent = ribbon })

	local popped = card(folder, "PoppedCard", "POPPED!", Color3.fromHex("6B4A7A"), Color3.fromHex("3A1830"))
	UIKit.Label({ Name = "SizeLine", Text = "Popped at size 42", TextSize = 24, Stroke = 3, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 74), Parent = popped })
	local lr = row(popped, "Row", UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 106), 8)
	UIKit.Coin(38, lr).LayoutOrder = 1
	local lost = UIKit.Label({ Name = "Lost", Text = "-1,234 lost", TextSize = 36, Stroke = 4, Color = Color3.fromHex("FFD0D0"), Size = UDim2.fromOffset(0, 44), Parent = lr })
	lost.AutomaticSize = Enum.AutomaticSize.X
	lost.LayoutOrder = 2
	UIKit.Label({ Name = "Hint", Text = "Land sooner next time!", TextSize = 17, Stroke = 2.5, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 160), Parent = popped })

	local toast = new("CanvasGroup", { Name = "Toast", Size = UDim2.fromOffset(520, 56), Position = UDim2.new(0.5, 0, 1, -200), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = folder })
	local pill = UIKit.Panel({ Name = "Pill", Size = UDim2.new(1, -16, 0, 42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Dark, Radius = 21, Outline = 3, Parent = toast })
	UIKit.Label({ Name = "Text", Text = "Get closer to an island to land", TextSize = 21, Stroke = 3, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), Parent = pill })

	local coin = UIKit.Coin(32, folder)
	coin.Name = "FlyingCoin"
	coin.Visible = false
end

--------------------------------------------------------------------------------

export type BuildOptions = { Spots: { any }? }

-- Builds a fresh "BalloonHUD" ScreenGui (not parented).
function HUDTemplate.Build(opts: BuildOptions?): ScreenGui
	local spots = (opts and opts.Spots) or {}
	if #spots == 0 then
		local ok, IslandConfig = pcall(function()
			return (require :: any)((script.Parent.Parent :: any).Config.IslandConfig)
		end)
		if ok then
			spots = (IslandConfig :: any).Islands
		end
	end
	local gui = new("ScreenGui", {
		Name = "BalloonHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
	})
	gui:SetAttribute("HUDVersion", 1)
	buildCoins(gui)
	buildGauge(gui, spots)
	buildActions(gui)
	buildArrow(gui)
	anchor(gui, "Cards", UDim2.fromOffset(460, 250), UDim2.fromScale(0.5, 0.34), Vector2.new(0.5, 0.5))
	anchor(gui, "Toasts", UDim2.fromOffset(520, 56), UDim2.new(0.5, 0, 1, -200), Vector2.new(0.5, 0.5))
	local templates = new("Folder", { Name = "Templates", Parent = gui })
	buildBoard(templates)
	buildMarker(templates)
	buildCards(templates)
	return gui
end

-- Studio command bar: puts an editable copy in StarterGui. An existing one is kept as
-- "BalloonHUD_Old" so edits are never lost.
function HUDTemplate.Install(): ScreenGui
	local StarterGui = game:GetService("StarterGui")
	local old = StarterGui:FindFirstChild("BalloonHUD")
	if old then
		local prev = StarterGui:FindFirstChild("BalloonHUD_Old")
		if prev then
			prev:Destroy()
		end
		old.Name = "BalloonHUD_Old"
		old:SetAttribute("Disabled", true)
		if old:IsA("ScreenGui") then
			old.Enabled = false
		end
	end
	local gui = HUDTemplate.Build()
	gui.Parent = StarterGui
	print("[HUDTemplate] BalloonHUD installed in StarterGui - edit away. Keep the names (docs/HUD_EDITING.md).")
	return gui
end

return HUDTemplate
