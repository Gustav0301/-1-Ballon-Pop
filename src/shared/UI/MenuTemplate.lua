--!strict
-- MenuTemplate: builds the menus as a normal ScreenGui ("BalloonMenus") you can put in
-- StarterGui and edit in Studio, like the HUD:
--   require(workspace.GamePack.Shared.UI.MenuTemplate).Install()          -- drag-in pack
--   require(game.ReplicatedStorage.Shared.UI.MenuTemplate).Install()      -- Rojo
--
--   TopBar     BALLOONS / SHOP / SPAWN / UPGRADES buttons (Grow a Garden style, studded)
--   Shop       the restocking Balloon Shop (Shop GUI reference)
--   Upgrades   level your balloons up
--   Balloons   your collection: equip, and the ones you haven't found yet
--   Templates  ShopCard, UpgradeCard, BalloonCard (copied once per balloon)
--
-- MenuController finds pieces by name (docs/MENU_EDITING.md lists them).

local UIKit = require(script.Parent.UIKit)

local MenuTemplate = {}

local T = UIKit.Theme
local new = UIKit.new

local WHITE = Color3.new(1, 1, 1)

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

local function anchor(gui: Instance, name: string, size: UDim2, pos: UDim2, ap: Vector2): Frame
	local frame = new("Frame", { Name = name, Size = size, Position = pos, AnchorPoint = ap, BackgroundTransparency = 1, Parent = gui })
	new("UIScale", { Name = "ViewportScale", Parent = frame })
	return frame
end

--------------------------------------------------------------------------------
-- studded plate (the Grow a Garden button look): little inset studs in a grid

local function studs(parent: GuiObject, w: number, h: number, dark: Color3, light: Color3, z: number, top: number?)
	local holder = new("Frame", { Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local size, gap = 12, 24
	local cols = math.max(1, math.floor((w - 8) / gap))
	local rows = math.max(1, math.floor((h - 8 - (top or 0)) / gap))
	local x0 = (w - (cols - 1) * gap - size) / 2
	local y0 = (top or 0) + (h - (top or 0) - (rows - 1) * gap - size) / 2
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local x, y = x0 + c * gap, y0 + r * gap
			local lit = new("Frame", { Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(x + 2, y + 2), BackgroundColor3 = light, BorderSizePixel = 0, ZIndex = z, Parent = holder })
			UIKit.Corner(lit, UDim.new(0, 3))
			local stud = new("Frame", { Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(x, y), BackgroundColor3 = dark, BorderSizePixel = 0, ZIndex = z, Parent = holder })
			UIKit.Corner(stud, UDim.new(0, 3))
		end
	end
	return holder
end

export type TopButtonProps = {
	Name: string,
	Text: string,
	Width: number,
	Height: number,
	Base: Color3,
	Dark: Color3,
	Light: Color3,
	Border: Color3,
	Grass: boolean?,
	TextSize: number?,
	Parent: Instance,
	Order: number,
}

local function topButton(p: TopButtonProps): Frame
	local w, h = p.Width, p.Height
	local frame = new("Frame", { Name = p.Name, Size = UDim2.fromOffset(w, h + 5), BackgroundTransparency = 1, LayoutOrder = p.Order, Parent = p.Parent })
	new("UIScale", { Name = "Hover", Parent = frame })
	local lip = new("Frame", { Name = "Lip", Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(0, 5), BackgroundColor3 = p.Dark, BorderSizePixel = 0, Parent = frame })
	UIKit.Corner(lip, UDim.new(0, 5))
	local face = new("Frame", { Name = "Face", Size = UDim2.fromOffset(w, h), BackgroundColor3 = p.Base, BorderSizePixel = 0, ZIndex = 2, Parent = frame })
	UIKit.Corner(face, UDim.new(0, 5))
	new("UIStroke", { Thickness = 3, Color = p.Border, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = face })
	local grassH = if p.Grass then 13 else 0
	studs(face, w, h, p.Dark, p.Light, 2, grassH)
	if p.Grass then
		-- a strip of grass along the top, with lighter blades
		local grass = new("Frame", { Name = "Grass", Size = UDim2.new(1, 0, 0, grassH), BackgroundColor3 = Color3.fromHex("5BC43B"), BorderSizePixel = 0, ZIndex = 3, Parent = face })
		UIKit.Corner(grass, UDim.new(0, 4))
		local fill = new("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Color3.fromHex("5BC43B"), BorderSizePixel = 0, ZIndex = 3, Parent = grass })
		local _ = fill
		for i = 0, math.floor(w / 18) do
			new("Frame", { Size = UDim2.fromOffset(9, 4), Position = UDim2.fromOffset(4 + i * 18, 2), BackgroundColor3 = Color3.fromHex("86E35F"), BorderSizePixel = 0, ZIndex = 4, Parent = grass })
			new("Frame", { Size = UDim2.fromOffset(6, 5), Position = UDim2.fromOffset(12 + i * 18, grassH - 2), BackgroundColor3 = Color3.fromHex("4AAE31"), BorderSizePixel = 0, ZIndex = 4, Parent = grass })
		end
	end
	UIKit.Label({ Name = "Text", Text = p.Text, TextSize = p.TextSize or 34, Stroke = 4, ZIndex = 6, Position = UDim2.fromOffset(0, grassH / 2), Parent = face })
	new("TextButton", { Name = "Hit", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 20, AutoButtonColor = false, Parent = frame })
	return frame
end

-- a tiny balloon-cluster icon for the square BALLOONS button
local function bouquet(parent: Instance, z: number)
	local holder = new("Frame", { Name = "Icon", Size = UDim2.fromOffset(44, 44), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local specs: { { x: number, y: number, color: Color3 } } = {
		{ x = -11, y = 4, color = T.Blue },
		{ x = 11, y = 4, color = T.Gold },
		{ x = 0, y = -4, color = T.Red },
	}
	for i, spec in specs do
		local b = UIKit.BalloonIcon(22, spec.color, holder)
		b.Position = UDim2.new(0.5, spec.x - 11, 0.5, spec.y - 14)
		lift(b, z + i)
	end
	return holder
end

local function buildTopBar(gui: Instance)
	local root = anchor(gui, "TopBar", UDim2.fromOffset(820, 84), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))
	local row = new("Frame", { Name = "Row", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = root })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local balloons = topButton({ Name = "Balloons", Text = "", Width = 64, Height = 64, Base = Color3.fromHex("9B7BFF"), Dark = Color3.fromHex("7E5CF0"), Light = Color3.fromHex("B7A2FF"), Border = Color3.fromHex("C9B8FF"), Parent = row, Order = 1 })
	bouquet(balloons:FindFirstChild("Face") :: Instance, 8)
	topButton({ Name = "Shop", Text = "SHOP", Width = 190, Height = 64, Base = Color3.fromHex("2E9BF0"), Dark = Color3.fromHex("1F7FD0"), Light = Color3.fromHex("5DB8FF"), Border = Color3.fromHex("7CCBFF"), Parent = row, Order = 2 })
	topButton({ Name = "Spawn", Text = "SPAWN", Width = 250, Height = 78, Base = Color3.fromHex("8B4A2B"), Dark = Color3.fromHex("6E3720"), Light = Color3.fromHex("A5603A"), Border = Color3.fromHex("86D95E"), Grass = true, TextSize = 40, Parent = row, Order = 3 })
	topButton({ Name = "Upgrades", Text = "UPGRADES", Width = 230, Height = 64, Base = Color3.fromHex("E3161C"), Dark = Color3.fromHex("BC0F14"), Light = Color3.fromHex("FF4148"), Border = Color3.fromHex("FF6A6E"), Parent = row, Order = 4 })
end

--------------------------------------------------------------------------------
-- windows (the Shop GUI reference: red frame, striped header, big X, header art)

local function closeButton(parent: Instance): Frame
	local btn = UIKit.Button({ Name = "Close", Size = UDim2.fromOffset(66, 62), Position = UDim2.new(1, 14, 0, -14), AnchorPoint = Vector2.new(1, 0), Face = T.Red, Top = T.RedTop, Lip = T.RedDark, Radius = 14, Parent = parent })
	btn.Frame.ZIndex = 10
	-- the X: both outlines first, then both white bars on top, so it reads as one shape
	for _, rot in { 45, -45 } do
		local edge = new("Frame", { Name = "XEdge", Size = UDim2.fromOffset(47, 18), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = rot, BackgroundColor3 = T.Outline, BorderSizePixel = 0, ZIndex = 5, Parent = btn.Face })
		UIKit.Corner(edge, UDim.new(0, 7))
	end
	for _, rot in { 45, -45 } do
		local bar = new("Frame", { Name = "XBar", Size = UDim2.fromOffset(40, 11), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = rot, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6, Parent = btn.Face })
		UIKit.Corner(bar, UDim.new(0, 4))
	end
	lift(btn.Frame, 10)
	return btn.Frame
end

local function window(gui: Instance, name: string, title: string, width: number, height: number): Frame
	local root = anchor(gui, name, UDim2.fromOffset(width + 60, height + 60), UDim2.fromScale(0.5, 0.57), Vector2.new(0.5, 0.5))
	root.Visible = false
	local win = UIKit.Panel({ Name = "Window", Size = UDim2.fromOffset(width, height), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = T.Red, Radius = 20, Outline = 4.5, Parent = root })
	new("UIScale", { Name = "Pop", Parent = win })
	local header = UIKit.Panel({ Name = "Header", Size = UDim2.new(1, 0, 0, 74), Color = T.Red, Top = T.RedTop, Radius = 20, Outline = 4.5, Stripes = true, Parent = win })
	UIKit.Label({ Name = "Title", Text = title, TextSize = 46, Stroke = 5, ZIndex = 3, Position = UDim2.fromOffset(20, -2), Parent = header })
	-- header art breaking out of the top-left corner (filled with balloon models at runtime)
	local icon = new("ViewportFrame", { Name = "Icon", Size = UDim2.fromOffset(130, 130), Position = UDim2.fromOffset(-40, -58), BackgroundTransparency = 1, ZIndex = 8, Parent = win })
	icon:SetAttribute("Balloons", "Gumball,Volt,Frost")
	closeButton(win)
	-- sub bar under the header (restock timer / found count)
	local sub = UIKit.Panel({ Name = "Sub", Size = UDim2.fromOffset(300, 34), Position = UDim2.new(0.5, 0, 0, 84), AnchorPoint = Vector2.new(0.5, 0), Color = T.Dark, Radius = 17, Outline = 3, Parent = win })
	UIKit.Label({ Name = "Text", Text = "NEW STOCK IN 4:59", TextSize = 19, Stroke = 3, ZIndex = 2, Parent = sub })
	-- the list
	local list = new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, -36, 1, -178),
		Position = UDim2.fromOffset(18, 130),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 14,
		ScrollBarImageColor3 = T.Orange,
		ScrollBarImageTransparency = 0,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		Parent = win,
	})
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6), Parent = list })
	-- footer strip
	local footer = new("Frame", { Name = "Footer", Size = UDim2.new(1, -8, 0, 34), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = T.RedDark, BorderSizePixel = 0, Parent = win })
	UIKit.Corner(footer, UDim.new(0, 16))
	UIKit.Label({ Name = "Text", Text = "SCROLL TO EXPLORE  •  BALLOONS & ABILITIES", TextSize = 15, Stroke = 2.5, Parent = footer })
	return win
end

local function buildShop(gui: Instance)
	local win = window(gui, "Shop", "Balloon Shop", 660, 500)
	local list = win:FindFirstChild("List") :: Instance
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	local footer: any = win:FindFirstChild("Footer")
	footer.Text.Text = "SCROLL TO EXPLORE  •  RESTOCKS EVERY 5 MINUTES"
end

local function upArrow(parent: Instance, z: number)
	local holder = new("Frame", { Name = "UpArrow", Size = UDim2.fromOffset(84, 96), Position = UDim2.fromOffset(-24, -46), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local head = new("Frame", { Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0.5, 0, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = T.Green, BorderSizePixel = 0, ZIndex = z, Parent = holder })
	UIKit.Corner(head, UDim.new(0, 8))
	UIKit.Stroke(head, 4.5)
	UIKit.Gloss(head, T.GreenTop, T.Green, 0.5)
	local stem = new("Frame", { Size = UDim2.fromOffset(32, 46), Position = UDim2.new(0.5, 0, 0, 48), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = T.Green, BorderSizePixel = 0, ZIndex = z + 1, Parent = holder })
	UIKit.Corner(stem, UDim.new(0, 6))
	UIKit.Stroke(stem, 4.5)
	UIKit.Gloss(stem, T.Green, T.GreenLip, 0.8)
	return holder
end

local function buildUpgrades(gui: Instance)
	local win = window(gui, "Upgrades", "Upgrades", 660, 500)
	local icon = win:FindFirstChild("Icon") :: Instance
	icon:Destroy()
	upArrow(win, 8)
	local list = win:FindFirstChild("List") :: Instance
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	local sub: any = win:FindFirstChild("Sub")
	sub.Text.Text = "EVERY LEVEL: +2% SIZE  +1% GROWTH  +1% EARN"
	sub.Size = UDim2.fromOffset(460, 34)
	local footer: any = win:FindFirstChild("Footer")
	footer.Text.Text = "LV 10 & 30: +1 HP  •  LV 20: +1 SLOT  •  LV 50: GOLDEN EDGE"
end

local function buildBalloons(gui: Instance)
	local win = window(gui, "Balloons", "My Balloons", 700, 510)
	local icon = win:FindFirstChild("Icon") :: Instance
	icon:SetAttribute("Balloons", "Gumball")
	local list = win:FindFirstChild("List") :: Instance
	new("UIGridLayout", { CellSize = UDim2.fromOffset(150, 196), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	local sub: any = win:FindFirstChild("Sub")
	sub.Text.Text = "FOUND 3 / 17"
	local footer: any = win:FindFirstChild("Footer")
	footer.Text.Text = "TAP A BALLOON TO EQUIP IT  •  FIND THEM ALL IN THE SHOP"
end

--------------------------------------------------------------------------------
-- card templates

local function artBox(parent: Instance, size: number, x: number, y: number): Frame
	local box = new("Frame", { Name = "ArtBox", Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(x, y), BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 2, Parent = parent })
	UIKit.Corner(box, UDim.new(0, 14))
	new("UIStroke", { Thickness = 2.5, Color = T.Outline, Transparency = 0.35, Parent = box })
	new("ViewportFrame", { Name = "Art", Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3, Parent = box })
	return box
end

local function card(parent: Instance, name: string, w: number, h: number): Frame
	local c = UIKit.Panel({ Name = name, Size = UDim2.fromOffset(w, h), Color = T.Blue, Top = T.BlueTop, Radius = 16, Outline = 3.5, Parent = parent })
	c.Visible = false
	c:SetAttribute("TierTinted", true) -- the controller recolours it by the balloon's tier
	return c
end

local function priceButton(parent: Instance, name: string, text: string, w: number): Frame
	local btn = UIKit.Button({ Name = name, Size = UDim2.fromOffset(w, 54), Position = UDim2.new(1, -14, 1, -18), AnchorPoint = Vector2.new(1, 1), Face = T.Green, Top = T.GreenTop, Lip = T.GreenLip, Radius = 14, Parent = parent })
	btn.Frame.ZIndex = 4
	local row = new("Frame", { Name = "Row", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Parent = btn.Face })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	local coin = UIKit.Coin(30, row)
	coin.LayoutOrder = 1
	local label = UIKit.Label({ Name = "Price", Text = text, TextSize = 28, Stroke = 3.5, Size = UDim2.fromOffset(0, 40), Parent = row })
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = 2
	lift(btn.Frame, 4)
	return btn.Frame
end

local function chip(parent: Instance, name: string, text: string, color: Color3, pos: UDim2, w: number): Frame
	local c = UIKit.Panel({ Name = name, Size = UDim2.fromOffset(w, 26), Position = pos, Color = color, Radius = 8, Outline = 2.5, Parent = parent })
	c.ZIndex = 3
	UIKit.Label({ Name = "Text", Text = text, TextSize = 15, Stroke = 2.5, ZIndex = 4, Parent = c })
	return c
end

local function buildShopCard(folder: Instance)
	local c = card(folder, "ShopCard", 600, 128)
	artBox(c, 108, 10, 10)
	UIKit.Label({ Name = "Name", Text = "VOLT", TextSize = 32, Stroke = 4, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(280, 36), Position = UDim2.fromOffset(132, 10), ZIndex = 3, Parent = c })
	chip(c, "Tier", "EPIC", T.Dark, UDim2.fromOffset(132, 50), 96)
	UIKit.Label({ Name = "Stats", Text = "MAX 700  •  GROW 1.8/s  •  HP 7  •  EARN x3", TextSize = 15, Stroke = 2.5, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 20), Position = UDim2.fromOffset(132, 84), ZIndex = 3, Parent = c })
	UIKit.Label({ Name = "Special", Text = "Absorbs lightning and stores it as bonus coins", TextSize = 13, Stroke = 2, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 16), Position = UDim2.fromOffset(132, 104), ZIndex = 3, Parent = c })
	local newTag = UIKit.Panel({ Name = "New", Size = UDim2.fromOffset(56, 26), Position = UDim2.fromOffset(2, 2), Color = T.Gold, Top = T.GoldTop, Radius = 8, Outline = 2.5, Parent = c })
	newTag.Rotation = -10
	newTag.ZIndex = 6
	UIKit.Label({ Name = "Text", Text = "NEW!", TextSize = 16, Stroke = 2.5, ZIndex = 7, Parent = newTag })
	UIKit.Label({ Name = "Left", Text = "x3 IN STOCK", TextSize = 17, Stroke = 2.5, Size = UDim2.fromOffset(160, 20), Position = UDim2.new(1, -94, 0, 16), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 3, Parent = c })
	UIKit.Label({ Name = "Owned", Text = "OWNED x1", TextSize = 13, Stroke = 2, Color = Color3.fromHex("D8FFD0"), Size = UDim2.fromOffset(160, 16), Position = UDim2.new(1, -94, 0, 38), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 3, Parent = c })
	priceButton(c, "Buy", "1M", 160)
end

local function buildUpgradeCard(folder: Instance)
	local c = card(folder, "UpgradeCard", 600, 128)
	artBox(c, 108, 10, 10)
	UIKit.Label({ Name = "Name", Text = "GUMBALL", TextSize = 30, Stroke = 4, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(240, 34), Position = UDim2.fromOffset(132, 8), ZIndex = 3, Parent = c })
	chip(c, "Level", "LV 3", T.GoldLip, UDim2.fromOffset(132, 46), 74)
	chip(c, "Equipped", "EQUIPPED", T.GreenLip, UDim2.fromOffset(214, 46), 104)
	UIKit.Label({ Name = "Stats", Text = "SIZE 104 → 106   •   EARN x1.02 → x1.03", TextSize = 15, Stroke = 2.5, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 20), Position = UDim2.fromOffset(132, 80), ZIndex = 3, Parent = c })
	UIKit.Label({ Name = "Next", Text = "LV 10: +1 TOUGHNESS", TextSize = 14, Stroke = 2.5, Color = Color3.fromHex("FFE27A"), XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 18), Position = UDim2.fromOffset(132, 101), ZIndex = 3, Parent = c })
	priceButton(c, "Upgrade", "61", 168)
end

local function buildBalloonCard(folder: Instance)
	local c = card(folder, "BalloonCard", 150, 196)
	artBox(c, 120, 15, 12)
	UIKit.Label({ Name = "Name", Text = "GUMBALL", TextSize = 20, Stroke = 3, Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, 134), ZIndex = 3, Parent = c })
	local level = UIKit.Panel({ Name = "Level", Size = UDim2.fromOffset(58, 24), Position = UDim2.fromOffset(6, 6), Color = T.GoldLip, Radius = 8, Outline = 2.5, Parent = c })
	level.ZIndex = 6
	UIKit.Label({ Name = "Text", Text = "LV 1", TextSize = 14, Stroke = 2.5, ZIndex = 7, Parent = level })
	local btn = UIKit.Button({ Name = "Equip", Size = UDim2.fromOffset(122, 32), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 1), Face = T.Green, Top = T.GreenTop, Lip = T.GreenLip, Radius = 10, LipDepth = 4, Parent = c })
	UIKit.Label({ Name = "Text", Text = "EQUIP", TextSize = 18, Stroke = 3, ZIndex = 4, Parent = btn.Face })
	lift(btn.Frame, 3)
end

--------------------------------------------------------------------------------

function MenuTemplate.Build(): ScreenGui
	local gui = new("ScreenGui", {
		Name = "BalloonMenus",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
	})
	gui:SetAttribute("MenuVersion", 1)
	buildTopBar(gui)
	buildShop(gui)
	buildUpgrades(gui)
	buildBalloons(gui)
	local templates = new("Folder", { Name = "Templates", Parent = gui })
	buildShopCard(templates)
	buildUpgradeCard(templates)
	buildBalloonCard(templates)
	return gui
end

-- Studio command bar: an editable copy in StarterGui (an existing one is kept as
-- "BalloonMenus_Old" and switched off, so edits are never lost).
function MenuTemplate.Install(): ScreenGui
	local StarterGui = game:GetService("StarterGui")
	local old = StarterGui:FindFirstChild("BalloonMenus")
	if old then
		local prev = StarterGui:FindFirstChild("BalloonMenus_Old")
		if prev then
			prev:Destroy()
		end
		old.Name = "BalloonMenus_Old"
		if old:IsA("ScreenGui") then
			old.Enabled = false
		end
	end
	local gui = MenuTemplate.Build()
	gui.Parent = StarterGui
	print("[MenuTemplate] BalloonMenus installed in StarterGui - edit away. Keep the names (docs/MENU_EDITING.md).")
	return gui
end

return MenuTemplate
