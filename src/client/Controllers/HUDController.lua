--!strict
-- HUDController: brings the flight HUD to life (docs/UI_STYLE.md, docs/HUD_EDITING.md).
--
-- The HUD itself is a normal ScreenGui called "BalloonHUD". If you've installed one in
-- StarterGui (HUDTemplate.Install() from the command bar) and edited it, THAT one is used;
-- otherwise the default is built from HUDTemplate. Everything is found by name, so the
-- look is yours to change in Studio - this file only moves, fills in and animates it.
--
--   Coins         coin counter; counts up as banked coins fly in
--   Altitude      zones, island notches, your balloon riding up the bar
--   Actions       JUMP TO FLY on the ground, LAND near an island
--   LetOutAir     hold to drop
--   IslandArrow   points at the nearest island when it's off screen
--   Templates     BalloonBoard (over every flying balloon), IslandMarker, cards, toast

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local HUDController = {}

local LocalPlayer = Players.LocalPlayer

local UIKit: any
local HUDTemplate: any
local T: any
local FlightConfig: any
local Flight: any
local Net: RemoteEvent

local gui: ScreenGui
local templates: Folder
local fxLayer: Frame
local viewportScales: { UIScale } = {}
local keyChips: { GuiObject } = {}

local HP_ON: Color3
local HP_OFF: Color3

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

local function prettyName(spot: any): string
	return string.upper(spot.Label or titleName(spot.Name))
end

local function find(root: Instance, path: string): any
	local node: Instance? = root
	for part in path:gmatch("[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	return node
end

local function show(obj: GuiObject?, on: boolean, scale: UIScale?)
	if not obj or obj.Visible == on then
		return
	end
	obj.Visible = on
	if on and scale then
		scale.Scale = 0.6
		UIKit.Tween(scale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

local function gradientColor(frame: Instance?, top: Color3, base: Color3)
	local g = frame and frame:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.55, base), ColorSequenceKeypoint.new(1, base) })
	end
end

local function copy(name: string): any
	local t = templates:FindFirstChild(name)
	if not t then
		return nil
	end
	local c = t:Clone()
	if c:IsA("GuiObject") then
		c.Visible = true
	end
	UIKit.BindStripes(c)
	return c
end

--------------------------------------------------------------------------------
-- coin counter

local coins = { shown = 0, target = 0, holdUntil = 0, scale = nil :: UIScale?, label = nil :: TextLabel?, icon = nil :: GuiObject? }

local function bindCoins()
	coins.scale = find(gui, "Coins.Holder.Pop")
	coins.label = find(gui, "Coins.Holder.Pill.Amount")
	coins.icon = find(gui, "Coins.Holder.Coin")
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
-- altitude gauge (reads the bar's own position and size, so you can move/resize it)

local gauge = { root = nil :: GuiObject?, bar = nil :: GuiObject?, you = nil :: GuiObject?, value = nil :: TextLabel? }

local function bindGauge()
	gauge.root = find(gui, "Altitude")
	gauge.bar = find(gui, "Altitude.Bar")
	gauge.you = find(gui, "Altitude.You")
	gauge.value = find(gui, "Altitude.Tag.Value")
	if gauge.root then
		(gauge.root :: GuiObject).Visible = false
	end
end

local function stepGauge()
	local root, bar, you = gauge.root, gauge.bar, gauge.you
	if not root or not bar then
		return
	end
	root.Visible = state() ~= "Ground"
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or not root.Visible then
		return
	end
	local alt = math.max(0, hrp.Position.Y - 3)
	local top = num(root :: any, "MaxAltitude", HUDTemplate.GaugeTop)
	if you then
		local k = 1 - math.clamp(alt / top, 0, 1)
		you.Position = UDim2.new(
			bar.Position.X.Scale,
			bar.Position.X.Offset + bar.Size.X.Offset / 2,
			bar.Position.Y.Scale,
			bar.Position.Y.Offset + bar.Size.Y.Offset * k
		)
	end
	if gauge.value then
		gauge.value.Text = UIKit.Number(alt) .. "m"
	end
end

--------------------------------------------------------------------------------
-- JUMP TO FLY, LAND, LET OUT AIR

local actions = {
	jump = nil :: GuiObject?,
	jumpScale = nil :: UIScale?,
	bob = nil :: GuiObject?,
	bobRest = UDim2.new(),
	land = nil :: any,
	landFill = nil :: GuiObject?,
	landFillSize = UDim2.new(),
	landTitle = nil :: TextLabel?,
	landTitleText = "LAND",
	landSpot = nil :: TextLabel?,
	firstRibbon = nil :: GuiObject?,
	letOut = nil :: any,
	letOutRoot = nil :: GuiObject?,
	launchedOnce = false,
	landShownAt = 0,
}

local function holdButton(btn: any, on: (boolean) -> ())
	btn.Hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			on(true)
		end
	end)
	btn.Hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			on(false)
		end
	end)
end

local function bindActions()
	local jump = find(gui, "Actions.JumpToFly")
	actions.jump = jump
	actions.jumpScale = jump and jump:FindFirstChild("Pop")
	actions.bob = find(gui, "Actions.JumpToFly.Pill.Bob")
	if actions.bob then
		actions.bobRest = (actions.bob :: GuiObject).Position
	end
	if jump then
		jump.Visible = false
	end

	local landFrame = find(gui, "Actions.Land")
	if landFrame then
		local btn = UIKit.BindButton(landFrame)
		actions.land = btn
		actions.landFill = find(landFrame, "Face.Fill")
		actions.landTitle = find(landFrame, "Face.Title")
		actions.landSpot = find(landFrame, "Spot.Text")
		actions.firstRibbon = find(landFrame, "First")
		if actions.landTitle then
			actions.landTitleText = (actions.landTitle :: TextLabel).Text
		end
		if actions.landFill then
			actions.landFillSize = (actions.landFill :: GuiObject).Size
		end
		holdButton(btn, Flight.SetLanding)
		landFrame.Visible = false
	end

	local letFrame = find(gui, "LetOutAir.LetOut")
	if letFrame then
		local btn = UIKit.BindButton(letFrame)
		actions.letOut = btn
		actions.letOutRoot = find(gui, "LetOutAir")
		holdButton(btn, Flight.SetLetOut)
		if actions.letOutRoot then
			(actions.letOutRoot :: GuiObject).Visible = false
		end
	end
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
		show(jump, ready and (not actions.launchedOnce or LocalPlayer:GetAttribute("FirstLanding") == true), actions.jumpScale)
		local bob = actions.bob
		if bob and jump.Visible then
			bob.Position = actions.bobRest + UDim2.fromOffset(0, math.sin(now * 3) * 4)
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
			if actions.landSpot then
				actions.landSpot.Text = prettyName(spot)
			end
			if actions.firstRibbon then
				actions.firstRibbon.Visible = LocalPlayer:GetAttribute("FirstLanding") == true
			end
			local fill = actions.landFill
			local title = actions.landTitle
			local full = actions.landFillSize
			if s == "Landing" then
				local total = if LocalPlayer:GetAttribute("FirstLanding") == true then FlightConfig.Land.FirstTime else FlightConfig.Land.Time
				local k = math.clamp(1 - (num(LocalPlayer, "LandEnd", 0) - workspace:GetServerTimeNow()) / total, 0, 1)
				if fill then
					fill.Size = UDim2.new(k, (full.X.Offset - 7) * k, full.Y.Scale, full.Y.Offset)
					fill.Visible = true
				end
				if title then
					title.Text = "LANDING"
				end
				if settled then
					land.Scale.Scale = 1 + math.sin(now * 20) * 0.015
				end
			else
				if fill then
					fill.Visible = false
				end
				if title then
					title.Text = actions.landTitleText
				end
				if settled then
					land.Scale.Scale = 1 + math.sin(now * 5) * 0.03 -- a gentle "press me" breathe
				end
			end
		end
	end

	local letOut = actions.letOut
	if letOut and actions.letOutRoot then
		show(actions.letOutRoot, s == "Flying", letOut.Scale)
	end
end

--------------------------------------------------------------------------------
-- over each flying balloon: unbanked coins, size, HP, risk

type Board = {
	gui: BillboardGui,
	amount: TextLabel?,
	amountScale: UIScale?,
	sizeChip: GuiObject?,
	sizeText: TextLabel?,
	sizeWidth: number,
	pipRow: GuiObject?,
	pips: { GuiObject },
	pipBody: UDim2,
	riskFill: GuiObject?,
	riskFillColor: Color3,
	riskLabel: TextLabel?,
	maxHP: number,
	last: number,
	lastHP: number,
	flip: number,
	shakeUntil: number,
	radius: number,
	radiusAt: number,
}

local boards: { [Player]: Board } = {}
local worldFolder: Folder

local function buildPips(b: Board, maxHP: number)
	for _, pip in b.pips do
		pip:Destroy()
	end
	b.pips = {}
	local row = b.pipRow
	if not row then
		return
	end
	local count = math.min(10, math.max(1, math.floor(maxHP + 0.5)))
	for i = 1, count do
		local pip = copy("HPPip")
		if pip then
			pip.LayoutOrder = i
			pip.Parent = row
			table.insert(b.pips, pip)
		end
	end
	b.maxHP = maxHP
end

local function newBoard(player: Player): Board?
	local bb = copy("BalloonBoard") :: BillboardGui?
	if not bb then
		return nil
	end
	local isMe = player == LocalPlayer
	bb.Name = "Balloon_" .. player.Name
	bb.AlwaysOnTop = isMe
	bb.MaxDistance = if isMe then 1e5 else 260
	bb.Parent = worldFolder
	local chip = find(bb, "Row.Size")
	local fill = find(bb, "Risk.Fill")
	local pipTemplate = templates:FindFirstChild("HPPip")
	local body = pipTemplate and pipTemplate:FindFirstChild("Body") :: GuiObject?
	local b: Board = {
		gui = bb,
		amount = find(bb, "Top.Amount"),
		amountScale = find(bb, "Top.Pop"),
		sizeChip = chip,
		sizeText = find(bb, "Row.Size.Text"),
		sizeWidth = if chip then chip.Size.X.Offset else 92,
		pipRow = find(bb, "Row.HP"),
		pips = {},
		pipBody = if body then body.Size else UDim2.fromOffset(15, 15),
		riskFill = fill,
		riskFillColor = if fill then fill.BackgroundColor3 else Color3.new(1, 1, 1),
		riskLabel = find(bb, "Risk.Label"),
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
	local amount = b.amount
	if amount and unbanked ~= b.last then
		if b.last >= 0 and unbanked > b.last then
			b.flip = -b.flip
			if b.amountScale then
				b.amountScale.Scale = 1.09
				UIKit.Tween(b.amountScale, 0.18, { Scale = 1 })
			end
			amount.Rotation = 3 * b.flip
			UIKit.Tween(amount, 0.25, { Rotation = 0 }, Enum.EasingStyle.Back)
		end
		b.last = unbanked
		amount.Text = "+" .. UIKit.Number(unbanked)
	end

	-- size chip goes gold at max size
	local size = num(player, "Size", 1)
	local maxed = player:GetAttribute("Maxed") == true
	if b.sizeText and b.sizeChip then
		b.sizeText.Text = if maxed then "MAX " .. UIKit.Number(size) else "SIZE " .. UIKit.Number(size)
		local chip = b.sizeChip :: GuiObject
		chip.Size = UDim2.new(chip.Size.X.Scale, math.max(b.sizeWidth, 30 + #b.sizeText.Text * 9), chip.Size.Y.Scale, chip.Size.Y.Offset)
		gradientColor(chip, if maxed then T.GoldTop else T.RedTop, if maxed then T.GoldDark else T.Red)
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
	if #b.pips > 0 then
		local perPip = maxHP / #b.pips
		local full = b.pipBody
		for i, pip in b.pips do
			local v = math.clamp((hp - (i - 1) * perPip) / perPip, 0, 1)
			local body = pip:FindFirstChild("Body") :: GuiObject?
			local knot = pip:FindFirstChild("Knot") :: GuiObject?
			if body then
				local color = if v <= 0 then HP_OFF else HP_ON
				body.BackgroundColor3 = color
				if knot then
					knot.BackgroundColor3 = color
				end
				local s = if v <= 0 then 0.8 else 0.62 + 0.38 * v
				local w, h = full.X.Offset, full.Y.Offset
				body.Size = UDim2.fromOffset(w * s, h * s)
				body.Position = UDim2.fromOffset(w * (1 - s) / 2, h * (1 - s))
			end
		end
	end
	if b.pipRow then
		b.pipRow.Position = UDim2.fromOffset(if now < b.shakeUntil then math.sin(now * 70) * 4 else 0, 0)
	end

	-- risk: fragility (1 + size / 200) fills the bar; while landing it's the landing timer
	local fill = b.riskFill
	if fill then
		local grad = fill:FindFirstChildOfClass("UIGradient")
		if state(player) == "Landing" then
			local total = if player:GetAttribute("FirstLanding") == true then FlightConfig.Land.FirstTime else FlightConfig.Land.Time
			local k = math.clamp(1 - (num(player, "LandEnd", 0) - workspace:GetServerTimeNow()) / total, 0, 1)
			fill.Size = UDim2.fromScale(k, 1)
			fill.BackgroundColor3 = T.Green
			if grad then
				grad.Enabled = false
			end
			if b.riskLabel then
				b.riskLabel.Text = "LANDING"
			end
		else
			fill.Size = UDim2.fromScale(math.max(math.clamp(size / FlightConfig.Fragility, 0, 1), 0.06), 1)
			fill.BackgroundColor3 = b.riskFillColor
			if grad then
				grad.Enabled = true
			end
			if b.riskLabel then
				b.riskLabel.Text = "RISK"
			end
		end
	end
end

local function stepBoards(now: number)
	for _, player in Players:GetPlayers() do
		local s = state(player)
		local character = player.Character
		local balloon = character and character:FindFirstChild("Balloon")
		local root = balloon and (balloon :: Model).PrimaryPart
		local want = (s == "Flying" or s == "Landing") and root ~= nil
		local b: Board? = boards[player]
		if want and root then
			if not b then
				local created = newBoard(player)
				if created then
					boards[player] = created
				end
				b = created
			end
			if b then
				stepBoard(player, b, root, now)
			end
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

type Marker = { spot: any, gui: BillboardGui, pill: GuiObject?, name: TextLabel?, dist: TextLabel?, hint: TextLabel?, scale: UIScale? }
local markers: { Marker } = {}
local arrow = { root = nil :: GuiObject?, pointer = nil :: GuiObject?, dist = nil :: TextLabel? }
local ORANGE_TOP = Color3.fromHex("FFC35A")
local ORANGE = Color3.fromHex("FF8A1F")

local function bindMarkers()
	local folder = Instance.new("Folder")
	folder.Name = "IslandMarkers"
	folder.Parent = workspace
	for _, spot in Flight.GetSpots() do
		if spot.Name ~= FlightConfig.Home.Name then
			local part = Instance.new("Part")
			part.Name = spot.Name
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Transparency = 1
			part.Size = Vector3.one
			part.Position = spot.Top + Vector3.new(0, 16, 0)
			part.Parent = folder
			local bb = copy("IslandMarker") :: BillboardGui?
			if bb then
				bb.Name = "Marker_" .. spot.Name
				bb.Adornee = part
				bb.Enabled = false
				bb.Parent = worldFolder
				table.insert(markers, {
					spot = spot,
					gui = bb,
					pill = find(bb, "Holder.Pill"),
					name = find(bb, "Holder.Pill.Name"),
					dist = find(bb, "Holder.Distance"),
					hint = find(bb, "Holder.Hint"),
					scale = find(bb, "Holder.Pop"),
				})
			end
		end
	end
	arrow.root = find(gui, "IslandArrow")
	arrow.pointer = find(gui, "IslandArrow.Pointer")
	arrow.dist = find(gui, "IslandArrow.Disc.Distance")
	if arrow.root then
		(arrow.root :: GuiObject).Visible = false
	end
end

local function stepMarkers(now: number)
	local s = state()
	local flying = s == "Flying" or s == "Landing"
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local pos = if hrp then hrp.Position else Vector3.zero
	local first = LocalPlayer:GetAttribute("FirstLanding") == true
	for _, m in markers do
		local d = (m.spot.Top - pos).Magnitude
		local on = flying and hrp ~= nil and d > 20
		if on ~= m.gui.Enabled then
			m.gui.Enabled = on
			if on and m.scale then
				m.scale.Scale = 0.5
				UIKit.Tween(m.scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
		if on then
			-- tell the player what to do: LAND HERE / DROP DOWN / FLOAT UP
			local status, off = FlightConfig.LandStatus(m.spot, pos, first)
			local label, hint = prettyName(m.spot), ""
			if status == "ok" then
				label = "LAND HERE!"
				hint = "HOLD E"
				gradientColor(m.pill, T.GreenTop, T.Green)
				if m.scale then
					m.scale.Scale = 1 + math.sin(now * 6) * 0.05
				end
			elseif status == "high" then
				label = "DROP DOWN!"
				hint = "HOLD SPACE  •  " .. UIKit.Number(off) .. "m too high"
				gradientColor(m.pill, ORANGE_TOP, ORANGE)
			elseif status == "low" then
				label = "FLOAT UP"
				hint = UIKit.Number(off) .. "m too low"
				gradientColor(m.pill, ORANGE_TOP, ORANGE)
			else
				gradientColor(m.pill, T.RedTop, T.Red)
			end
			if m.name then
				m.name.Text = label
			end
			if m.hint then
				m.hint.Text = hint
				m.hint.Visible = hint ~= ""
			end
			if m.dist then
				m.dist.Text = UIKit.Number(d) .. "m"
			end
		end
	end

	-- edge arrow to the nearest island when it's off screen
	local root, pointer = arrow.root, arrow.pointer
	local nearest = Flight.Nearest
	local cam = workspace.CurrentCamera
	if not root or not pointer then
		return
	end
	if not flying or not nearest or not cam or Flight.Spot ~= nil then
		root.Visible = false
		return
	end
	local sp, onScreen = cam:WorldToViewportPoint(nearest.Top + Vector3.new(0, 16, 0))
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
	local t = math.min((center.X - margin) / math.max(math.abs(unit.X), 1e-3), (center.Y - margin) / math.max(math.abs(unit.Y), 1e-3))
	local at = center + unit * t
	root.Position = UDim2.fromOffset(at.X, at.Y)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Rotation = math.deg(math.atan2(unit.Y, unit.X))
	if arrow.dist then
		arrow.dist.Text = UIKit.Number((nearest.Top - pos).Magnitude) .. "m"
	end
	root.Visible = true
end

--------------------------------------------------------------------------------
-- cards: BANKED!, POPPED!, toasts

local cardSlot: GuiObject
local toastSlot: GuiObject
local cardToken = 0

local function showCard(name: string): (CanvasGroup?, Instance?)
	for _, old in cardSlot:GetChildren() do
		if old:IsA("CanvasGroup") then
			old:Destroy()
		end
	end
	local group = copy(name) :: CanvasGroup?
	if not group then
		return nil, nil
	end
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.GroupTransparency = 0
	group.Parent = cardSlot
	local scale = group:FindFirstChild("Pop") :: UIScale?
	if scale then
		scale.Scale = 0.3
		UIKit.Tween(scale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	return group, group:FindFirstChild("Panel")
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
		if old:IsA("CanvasGroup") then
			old:Destroy()
		end
	end
	local group = copy("Toast") :: CanvasGroup?
	if not group then
		return
	end
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.GroupTransparency = 1
	group.Parent = toastSlot
	local label = find(group, "Pill.Text") :: TextLabel?
	if label then
		label.Text = text
	end
	local pill = group:FindFirstChild("Pill") :: GuiObject?
	if pill and color then
		pill.BackgroundColor3 = color
	end
	UIKit.Tween(group, 0.2, { GroupTransparency = 0 })
	task.delay(2.4, function()
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
			local c = copy("FlyingCoin") :: GuiObject?
			if not c then
				return
			end
			local base = c.Size
			local size = 0.8 + math.random() * 0.4
			c.AnchorPoint = Vector2.new(0.5, 0.5)
			c.ZIndex = 50
			for _, d in c:GetDescendants() do
				if d:IsA("GuiObject") then
					d.ZIndex = 51
				end
			end
			c.Parent = fxLayer
			local mid = a + Vector2.new(math.random(-130, 130), math.random(-120, -30))
			local t0 = os.clock()
			local dur = 0.55 + math.random() * 0.25
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local t = math.clamp((os.clock() - t0) / dur, 0, 1)
				local e = t * t * (3 - 2 * t)
				local p = a:Lerp(mid, e):Lerp(mid:Lerp(b, e), e)
				c.Position = UDim2.fromOffset(p.X, p.Y)
				c.Rotation = (1 - t) * 180
				local s = size * (1 - 0.35 * t)
				c.Size = UDim2.fromOffset(base.X.Offset * s, base.Y.Offset * s)
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
	local group, panel = showCard("BankedCard")
	if not group or not panel then
		return
	end
	local label = find(panel, "Row.Amount") :: TextLabel?
	local where = find(panel, "Where") :: TextLabel?
	if where then
		where.Text = (if spotName ~= "" then "Landed on " .. titleName(spotName) else "Landed") .. "  •  size " .. UIKit.Number(size)
	end
	local ribbon = find(panel, "Bonus") :: GuiObject?
	if ribbon then
		ribbon.Visible = bonus > 1
		local text = find(ribbon, "Text") :: TextLabel?
		if text then
			text.Text = "FIRST LANDING x" .. bonus
		end
	end
	if label then
		-- count the number up quickly, then send the coins flying
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = math.clamp((os.clock() - t0) / 0.5, 0, 1)
			label.Text = "+" .. UIKit.Number(amount * (1 - (1 - t) ^ 3))
			if t >= 1 or not label.Parent then
				conn:Disconnect()
			end
		end)
	end
	local coin = find(panel, "Row.Coin") :: GuiObject?
	coinFountain(coin or group, amount)
	dismiss(group, 2.8)
end

local function onPopped(size: number, lost: number)
	local group, panel = showCard("PoppedCard")
	if not group or not panel then
		return
	end
	local line = find(panel, "SizeLine") :: TextLabel?
	if line then
		line.Text = "Popped at size " .. UIKit.Number(size)
	end
	local lostLabel = find(panel, "Row.Lost") :: TextLabel?
	if lostLabel then
		lostLabel.Text = "-" .. UIKit.Number(lost) .. " lost"
	end
	dismiss(group, 3.4)
end

-- pressed E / LAND out of range: say exactly why
local function onLandDenied(status: string, spot: any?, off: number)
	local name = if spot then titleName(spot.Label or spot.Name) else "an island"
	if status == "high" then
		HUDController.Toast(`Too high by {UIKit.Number(off)}m - hold SPACE to drop onto {name}`, T.Orange)
	elseif status == "low" then
		HUDController.Toast(`Too low by {UIKit.Number(off)}m - float up beside {name}`, T.Orange)
	else
		HUDController.Toast(`Drift closer to {name} to land`)
	end
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
	local keyboard = UserInputService.KeyboardEnabled and (last == Enum.UserInputType.Keyboard or last.Name:find("Mouse") ~= nil)
	for _, chip in keyChips do
		chip.Visible = keyboard
	end
end

-- the edited HUD from StarterGui, or the default one
local function acquireGui(playerGui: Instance): ScreenGui
	if StarterGui:FindFirstChild("BalloonHUD") then
		local found = playerGui:WaitForChild("BalloonHUD", 10) :: ScreenGui?
		if found then
			return found
		end
	end
	local existing = playerGui:FindFirstChild("BalloonHUD") :: ScreenGui?
	if existing then
		return existing
	end
	local built = HUDTemplate.Build({ Spots = (function()
		local list = {}
		for _, spot in Flight.GetSpots() do
			if spot.Name ~= FlightConfig.Home.Name then
				table.insert(list, spot)
			end
		end
		return list
	end)() })
	built.Parent = playerGui
	return built
end

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
	Flight: any,
}

function HUDController.Start(opts: StartOptions)
	local shared = opts.Shared
	local ui = shared:WaitForChild("UI")
	UIKit = require(ui:WaitForChild("UIKit") :: ModuleScript) :: any
	HUDTemplate = require(ui:WaitForChild("HUDTemplate") :: ModuleScript) :: any
	T = UIKit.Theme
	HP_ON, HP_OFF = HUDTemplate.HPOn, HUDTemplate.HPOff
	local config = shared:WaitForChild("Config")
	FlightConfig = require(config:WaitForChild("FlightConfig") :: ModuleScript) :: any
	Flight = opts.Flight
	Net = opts.RemoteParent:WaitForChild("FlightNet") :: RemoteEvent

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	gui = acquireGui(playerGui)
	gui.ResetOnSpawn = false
	gui.Enabled = true

	-- templates are copied at runtime; keep them out of the live screen
	local t = gui:FindFirstChild("Templates") :: Folder?
	if not t then
		warn("[HUD] BalloonHUD has no Templates folder - reinstall it with HUDTemplate.Install()")
		t = Instance.new("Folder")
	end
	templates = t :: Folder
	templates.Parent = nil

	worldFolder = Instance.new("Folder")
	worldFolder.Name = "BalloonHUDWorld"
	worldFolder.Parent = playerGui
	local fx = Instance.new("Frame")
	fx.Name = "FX"
	fx.Size = UDim2.fromScale(1, 1)
	fx.BackgroundTransparency = 1
	fx.ZIndex = 50
	fx.Parent = gui
	fxLayer = fx

	for _, d in gui:GetDescendants() do
		if d:IsA("UIScale") and d.Name == "ViewportScale" then
			table.insert(viewportScales, d)
		elseif d:IsA("GuiObject") and d.Name == "Key" then
			table.insert(keyChips, d)
		end
	end
	UIKit.BindStripes(gui)

	bindCoins()
	bindGauge()
	bindActions()
	bindMarkers()
	cardSlot = find(gui, "Cards") or gui
	toastSlot = find(gui, "Toasts") or gui

	rescale()
	local function watchCamera()
		local c = workspace.CurrentCamera
		if c then
			c:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
		end
		rescale()
	end
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	refreshKeys()
	UserInputService.LastInputTypeChanged:Connect(refreshKeys)

	coins.shown = num(LocalPlayer, "Coins", 0)
	coins.target = coins.shown

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
	Flight.LandDenied.Event:Connect(onLandDenied)

	local launches, maxToastFor = 0, -1
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
