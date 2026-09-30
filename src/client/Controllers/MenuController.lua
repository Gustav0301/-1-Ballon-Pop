--!strict
-- MenuController: the top bar (BALLOONS / SHOP / SPAWN / UPGRADES) and the three windows
-- (Balloon Shop, Upgrades, My Balloons). Like the HUD, the look lives in a ScreenGui
-- ("BalloonMenus") you can edit in Studio - this file fills it in and makes it work.
--
-- Walk up to a stall and press E (or tap) to open its window; the top-bar buttons
-- teleport you to the stalls (Grow a Garden style). Every purchase, upgrade and equip is
-- checked on the server (BalloonService / ShopService).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local MenuController = {}

local LocalPlayer = Players.LocalPlayer

local UIKit: any
local T: any
local BalloonConfig: any
local ShopConfig: any
local BalloonBuilder: any
local Net: RemoteFunction
local HUD: any
local Sound: any

local gui: ScreenGui
local templates: Folder
local snapshot: any = nil
local viewportScales: { UIScale } = {}

type Window = { name: string, root: GuiObject, win: GuiObject, pop: UIScale?, list: ScrollingFrame, sub: TextLabel?, cards: { [string]: GuiObject }, stall: string? }
local windows: { [string]: Window } = {}
local openName: string? = nil

--------------------------------------------------------------------------------
-- helpers

local function find(root: Instance, path: string): any
	local node: Instance? = root
	for part in path:gmatch("[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	return node
end

local function state(): string
	return (LocalPlayer:GetAttribute("FlightState") :: string?) or "Ground"
end

local function coins(): number
	return (LocalPlayer:GetAttribute("Coins") :: number?) or 0
end

local function tint(frame: Instance?, color: Color3)
	local g = frame and frame:FindFirstChildOfClass("UIGradient")
	if g then
		local top = color:Lerp(Color3.new(1, 1, 1), 0.28)
		local base = color:Lerp(Color3.new(0, 0, 0), 0.18)
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.55, base), ColorSequenceKeypoint.new(1, base) })
	end
end

local function toast(text: string, color: Color3?)
	if HUD and text ~= "" then
		HUD.Toast(text, color)
	end
end

local function statLine(stats: any): string
	return `MAX {UIKit.Number(stats.MaxSize)}  •  GROW {string.format("%.1f", stats.Growth)}/s  •  HP {stats.Toughness}  •  EARN x{string.format("%.3g", stats.Earn)}`
end

--------------------------------------------------------------------------------
-- 3D balloon art in ViewportFrames (models are built once and cloned)

local modelCache: { [string]: Model } = {}

local function modelFor(kind: string): Model?
	local cached = modelCache[kind]
	if not cached then
		if not BalloonBuilder.Has(kind) then
			return nil
		end
		cached = BalloonBuilder.Build(kind, { Anchored = true, CFrame = CFrame.new() })
		modelCache[kind] = cached
	end
	return (cached :: Model):Clone()
end

local function fillViewport(vp: ViewportFrame, kinds: { string }, silhouette: boolean?)
	for _, child in vp:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	local models = {}
	local spread = { Vector3.new(0, 0, 0), Vector3.new(-6.5, -2.5, 1.5), Vector3.new(6.5, -2.5, 1.5) }
	for i, kind in kinds do
		local m = modelFor(kind)
		if m then
			local off = spread[i] or Vector3.zero
			m:PivotTo(CFrame.new(off) * CFrame.Angles(0, math.rad(if i == 1 then 18 else (if i == 2 then 35 else -5)), 0))
			m.Parent = vp
			table.insert(models, m)
		end
	end
	if #models == 0 then
		return
	end
	-- frame everything: bounding box of all models
	local minV, maxV = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, m in models do
		local cf, size = m:GetBoundingBox()
		local half = size / 2
		minV = minV:Min(cf.Position - half)
		maxV = maxV:Max(cf.Position + half)
	end
	local centre = (minV + maxV) / 2
	local extent = (maxV - minV).Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = extent / math.tan(math.rad(cam.FieldOfView / 2)) * 1.02
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0.3, 0.22, -1).Unit * dist, centre)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Ambient = Color3.fromRGB(190, 190, 205)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-0.6, -1, 0.8)
	vp.ImageColor3 = if silhouette then Color3.fromRGB(20, 12, 30) else Color3.new(1, 1, 1)
	vp.ImageTransparency = if silhouette then 0.35 else 0
end

--------------------------------------------------------------------------------
-- server calls

local function call(kind: string, arg: string?): (boolean, string)
	local ok, a, b, c = pcall(function()
		return Net:InvokeServer(kind, arg)
	end)
	if not ok then
		return false, "Couldn't reach the server"
	end
	if c ~= nil then
		snapshot = c
	end
	return a == true, (b :: string?) or ""
end

--------------------------------------------------------------------------------
-- windows

local renderers: { [string]: (Window) -> () } = {}

local function renderOpen()
	if openName then
		local w = windows[openName]
		local render = renderers[openName]
		if w and render then
			render(w)
		end
	end
end

local function openWindow(name: string, stall: string?)
	local w = windows[name]
	if not w then
		return
	end
	for other, ow in windows do
		if other ~= name then
			ow.root.Visible = false
		end
	end
	w.stall = stall
	local was = w.root.Visible
	w.root.Visible = true
	openName = name
	if not was then
		Sound.Play("Open")
		if w.pop then
			w.pop.Scale = 0.6
			UIKit.Tween(w.pop, 0.34, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	renderOpen()
end

local function closeAll(silent: boolean?)
	local any = false
	for _, w in windows do
		if w.root.Visible then
			any = true
		end
		w.root.Visible = false
	end
	openName = nil
	if any and not silent then
		Sound.Play("Close")
	end
end

local function bindButton(frame: GuiObject?, onClick: () -> ())
	if not frame then
		return
	end
	local hit = frame:FindFirstChild("Hit") :: TextButton?
	if frame:FindFirstChild("Face") and frame:FindFirstChild("Hit") then
		UIKit.BindButton(frame)
	end
	if hit then
		hit.Activated:Connect(function()
			Sound.Play("Click")
			onClick()
		end)
	end
end

-- keeps one card per key, re-using existing ones (so their 3D art is built only once)
local function cardFor(w: Window, key: string, template: string, order: number): (GuiObject?, boolean)
	local card = w.cards[key]
	local fresh = false
	if not card then
		local t = templates:FindFirstChild(template)
		if not t then
			return nil, false
		end
		local c = t:Clone() :: GuiObject
		c.Name = key
		c.Visible = true
		UIKit.BindStripes(c)
		c.Parent = w.list
		w.cards[key] = c
		card = c
		fresh = true
	end
	(card :: GuiObject).LayoutOrder = order
	return card, fresh
end

local function dropUnused(w: Window, keep: { [string]: boolean })
	for key, card in w.cards do
		if not keep[key] then
			card:Destroy()
			w.cards[key] = nil
		end
	end
end

local function setButton(frame: any, enabled: boolean, text: string?)
	if not frame then
		return
	end
	local face = frame:FindFirstChild("Face")
	if face then
		local g = face:FindFirstChildOfClass("UIGradient")
		if g then
			local top = if enabled then T.GreenTop else Color3.fromHex("C9C3D6")
			local base = if enabled then T.Green else Color3.fromHex("8C8499")
			g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.5, base), ColorSequenceKeypoint.new(1, base) })
		end
	end
	if text then
		local label = find(frame, "Face.Row.Price") or find(frame, "Face.Text")
		if label then
			label.Text = text
		end
	end
end

-- a price button that can't be bought at all (sold out / max): no coin, smaller words
local function setPriceMode(frame: any, price: boolean)
	local coin = frame and find(frame, "Face.Row.Coin")
	local label = frame and find(frame, "Face.Row.Price")
	if coin then
		coin.Visible = price
	end
	if label then
		if label:GetAttribute("BaseSize") == nil then
			label:SetAttribute("BaseSize", label.TextSize)
		end
		local base = label:GetAttribute("BaseSize") :: number
		label.TextSize = if price then base else math.floor(base * 0.78)
	end
end

--------------------------------------------------------------------------------
-- Balloon Shop

renderers.Shop = function(w: Window)
	local shop = snapshot and snapshot.shop
	if not shop then
		return
	end
	local owned: { [string]: number } = {}
	for _, b in snapshot.balloons do
		owned[b.type] = (owned[b.type] or 0) + 1
	end
	local keep = {}
	for i, item in shop.items do
		local kind = item.kind
		local t = BalloonConfig.Types[kind]
		local card, fresh = cardFor(w, kind, "ShopCard", i)
		if card and t then
			keep[kind] = true
			local color = BalloonConfig.TierColors[t.Tier] or T.Blue
			if fresh then
				tint(card, color)
				local art = find(card, "ArtBox.Art")
				if art then
					fillViewport(art, { kind })
				end
				local tierChip = find(card, "Tier")
				if tierChip then
					tierChip.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.45)
					find(tierChip, "Text").Text = string.upper(t.Tier)
				end
				find(card, "Name").Text = string.upper(kind)
				find(card, "Stats").Text = statLine(BalloonConfig.StatsFor(kind, 1))
				local special = find(card, "Special")
				if special then
					special.Text = t.Special
				end
				bindButton(find(card, "Buy"), function()
					local ok, msg = call("Buy", kind)
					Sound.Play(if ok then "Buy" else "Error")
					toast(msg, if ok then T.GreenLip else nil)
					renderOpen()
				end)
			end
			local newTag = find(card, "New")
			if newTag then
				newTag.Visible = not snapshot.found[kind]
			end
			local left = find(card, "Left")
			if left then
				left.Text = if item.left > 0 then `x{item.left} IN STOCK` else "SOLD OUT"
			end
			local ownedLabel = find(card, "Owned")
			if ownedLabel then
				ownedLabel.Text = if owned[kind] then `OWNED x{owned[kind]}` else ""
			end
			setButton(find(card, "Buy"), item.left > 0 and coins() >= item.price, if item.left > 0 then UIKit.Short(item.price) else "SOLD OUT")
			setPriceMode(find(card, "Buy"), item.left > 0)
		end
	end
	dropUnused(w, keep)
end

--------------------------------------------------------------------------------
-- Upgrades

local MILESTONES = { [10] = "+1 TOUGHNESS", [20] = "+1 MUTATION SLOT", [30] = "+1 TOUGHNESS", [40] = "SPECIAL UPGRADED", [50] = "GOLDEN EDGE (+25% EARN)" }

local function nextMilestone(level: number): string
	for _, at in { 10, 20, 30, 40, 50 } do
		if level < at then
			return `LV {at}: {MILESTONES[at]}`
		end
	end
	return "MAX LEVEL - GOLDEN EDGE!"
end

renderers.Upgrades = function(w: Window)
	if not snapshot then
		return
	end
	local keep = {}
	for i, b in snapshot.balloons do
		local t = BalloonConfig.Types[b.type]
		local card, fresh = cardFor(w, b.uid, "UpgradeCard", i)
		if card and t then
			keep[b.uid] = true
			if fresh then
				tint(card, BalloonConfig.TierColors[t.Tier] or T.Blue)
				local art = find(card, "ArtBox.Art")
				if art then
					fillViewport(art, { b.type })
				end
				find(card, "Name").Text = string.upper(b.type)
				local uid = b.uid
				bindButton(find(card, "Upgrade"), function()
					local ok, msg = call("Upgrade", uid)
					Sound.Play(if ok then "Upgrade" else "Error")
					toast(msg, if ok then T.GoldLip else nil)
					renderOpen()
				end)
			end
			local level = find(card, "Level.Text")
			if level then
				level.Text = `LV {b.level}`
			end
			local eq = find(card, "Equipped")
			if eq then
				eq.Visible = snapshot.equipped == b.uid
			end
			local now = BalloonConfig.StatsFor(b.type, b.level)
			local maxed = b.level >= ShopConfig.MaxLevel
			local stats = find(card, "Stats")
			if stats then
				if maxed then
					stats.Text = `SIZE {UIKit.Number(now.MaxSize)}   •   EARN x{string.format("%.2f", now.Earn)}`
				else
					local nxt = BalloonConfig.StatsFor(b.type, b.level + 1)
					stats.Text = `SIZE {UIKit.Number(now.MaxSize)} → {UIKit.Number(nxt.MaxSize)}   •   EARN x{string.format("%.2f", now.Earn)} → x{string.format("%.2f", nxt.Earn)}`
				end
			end
			local nextLabel = find(card, "Next")
			if nextLabel then
				nextLabel.Text = nextMilestone(b.level)
			end
			local cost = ShopConfig.UpgradeCost(t.Tier, b.level)
			setButton(find(card, "Upgrade"), not maxed and coins() >= cost, if maxed then "MAX" else UIKit.Short(cost))
			setPriceMode(find(card, "Upgrade"), not maxed)
		end
	end
	dropUnused(w, keep)
end

--------------------------------------------------------------------------------
-- My Balloons (collection + equip)

renderers.Balloons = function(w: Window)
	if not snapshot then
		return
	end
	local keep = {}
	local order = 0
	local sold = 0
	local found = 0
	for _, b in snapshot.balloons do
		order += 1
		local t = BalloonConfig.Types[b.type]
		local card, fresh = cardFor(w, b.uid, "BalloonCard", order)
		if card and t then
			keep[b.uid] = true
			if fresh then
				tint(card, BalloonConfig.TierColors[t.Tier] or T.Blue)
				local art = find(card, "ArtBox.Art")
				if art then
					fillViewport(art, { b.type })
				end
				find(card, "Name").Text = string.upper(b.type)
				local uid = b.uid
				bindButton(find(card, "Equip"), function()
					if snapshot and snapshot.equipped == uid then
						return
					end
					local ok, msg = call("Equip", uid)
					Sound.Play(if ok then "Equip" else "Error")
					toast(msg, if ok then T.GreenLip else nil)
					renderOpen()
				end)
			end
			local level = find(card, "Level.Text")
			if level then
				level.Text = `LV {b.level}`
			end
			local equipped = snapshot.equipped == b.uid
			local btn = find(card, "Equip")
			if btn then
				btn.Visible = true
				setButton(btn, not equipped, if equipped then "EQUIPPED" else "EQUIP")
			end
		end
	end
	-- balloons you haven't found yet, as dark silhouettes
	for _, kind in BalloonConfig.Ordered() do
		if ShopConfig.Prices[kind] then
			sold += 1
			if snapshot.found[kind] then
				found += 1
			else
				order += 1
				local key = "unfound_" .. kind
				local card, fresh = cardFor(w, key, "BalloonCard", 1000 + order)
				if card then
					keep[key] = true
					if fresh then
						tint(card, Color3.fromHex("55506A"))
						local art = find(card, "ArtBox.Art")
						if art then
							fillViewport(art, { kind }, true)
						end
						find(card, "Name").Text = "???"
						local lvl = find(card, "Level")
						if lvl then
							lvl.Visible = false
						end
						local btn = find(card, "Equip")
						if btn then
							btn.Visible = false
						end
					end
				end
			end
		end
	end
	dropUnused(w, keep)
	if w.sub then
		w.sub.Text = `FOUND {found} / {sold}`
	end
end

--------------------------------------------------------------------------------
-- start

local function acquireGui(playerGui: Instance, MenuTemplate: any): ScreenGui
	if StarterGui:FindFirstChild("BalloonMenus") then
		local found = playerGui:WaitForChild("BalloonMenus", 10) :: ScreenGui?
		if found then
			return found
		end
	end
	local existing = playerGui:FindFirstChild("BalloonMenus") :: ScreenGui?
	if existing then
		return existing
	end
	local built = MenuTemplate.Build()
	built.Parent = playerGui
	return built
end

local function rescale()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local vp = cam.ViewportSize
	local s = math.clamp(math.min(vp.X / 1280, vp.Y / 760), 0.55, 1.25)
	for _, sc in viewportScales do
		sc.Scale = s
	end
end

export type StartOptions = { Shared: Instance, RemoteParent: Instance, HUD: any, Sound: any }

function MenuController.Start(opts: StartOptions)
	local shared = opts.Shared
	local ui = shared:WaitForChild("UI")
	UIKit = require(ui:WaitForChild("UIKit") :: ModuleScript) :: any
	local MenuTemplate = require(ui:WaitForChild("MenuTemplate") :: ModuleScript) :: any
	T = UIKit.Theme
	local config = shared:WaitForChild("Config")
	BalloonConfig = require(config:WaitForChild("BalloonConfig") :: ModuleScript) :: any
	ShopConfig = require(config:WaitForChild("ShopConfig") :: ModuleScript) :: any
	BalloonBuilder = require(shared:WaitForChild("Balloons"):WaitForChild("BalloonBuilder") :: ModuleScript) :: any
	HUD = opts.HUD
	Sound = opts.Sound
	Net = opts.RemoteParent:WaitForChild("BalloonNet") :: RemoteFunction
	local sync = opts.RemoteParent:WaitForChild("BalloonSync") :: RemoteEvent

	gui = acquireGui(LocalPlayer:WaitForChild("PlayerGui"), MenuTemplate)
	gui.ResetOnSpawn = false
	gui.Enabled = true
	local t = gui:FindFirstChild("Templates") :: Folder?
	if not t then
		warn("[Menus] BalloonMenus has no Templates folder - reinstall it with MenuTemplate.Install()")
		t = Instance.new("Folder")
	end
	templates = t :: Folder
	templates.Parent = nil
	for _, d in gui:GetDescendants() do
		if d:IsA("UIScale") and d.Name == "ViewportScale" then
			table.insert(viewportScales, d)
		end
	end
	UIKit.BindStripes(gui)

	-- windows
	for _, name in { "Shop", "Upgrades", "Balloons" } do
		local root = find(gui, name)
		local win = root and root:FindFirstChild("Window")
		local list = win and win:FindFirstChild("List")
		if root and win and list then
			local w: Window = { name = name, root = root, win = win, pop = win:FindFirstChild("Pop"), list = list, sub = find(win, "Sub.Text"), cards = {}, stall = nil }
			windows[name] = w
			root.Visible = false
			bindButton(win:FindFirstChild("Close"), function()
				closeAll()
			end)
			local icon = win:FindFirstChild("Icon")
			if icon and icon:IsA("ViewportFrame") then
				local kinds = {}
				for kind in string.gmatch(tostring(icon:GetAttribute("Balloons") or "Gumball"), "[^,%s]+") do
					table.insert(kinds, kind)
				end
				task.spawn(fillViewport, icon, kinds)
			end
		end
	end

	-- top bar
	local bar = find(gui, "TopBar")
	local function teleport(place: string)
		closeAll(true)
		local ok, msg = call("Teleport", place)
		if ok then
			Sound.Play("Teleport")
		elseif msg ~= "" then
			Sound.Play("Error")
			toast(msg)
		end
	end
	if bar then
		bindButton(find(bar, "Row.Balloons"), function()
			if openName == "Balloons" then
				closeAll()
			else
				openWindow("Balloons")
			end
		end)
		bindButton(find(bar, "Row.Shop"), function()
			teleport("Shop")
		end)
		bindButton(find(bar, "Row.Spawn"), function()
			teleport("Spawn")
		end)
		bindButton(find(bar, "Row.Upgrades"), function()
			teleport("Upgrades")
		end)
	end

	-- stall prompts
	local stallMenus = { Shop = "Shop", Upgrades = "Upgrades", Index = "Balloons" }
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if player ~= LocalPlayer then
			return
		end
		local stall = prompt:GetAttribute("Menu")
		local menu = if type(stall) == "string" then stallMenus[stall] else nil
		if menu and state() == "Ground" then
			openWindow(menu, stall :: string)
		end
	end)

	-- server pushes
	sync.OnClientEvent:Connect(function(kind: string, payload: any)
		if kind == "Snapshot" then
			local restocked = snapshot and snapshot.shop and payload.shop and payload.shop.index ~= snapshot.shop.index
			snapshot = payload
			if restocked then
				Sound.Play("Restock")
				if openName == "Shop" then
					toast("The Balloon Shop restocked!")
				end
			end
			renderOpen()
		elseif kind == "Announce" then
			Sound.Play("Fanfare")
			toast(payload, T.GoldLip)
			pcall(function()
				local channels = TextChatService:FindFirstChild("TextChannels")
				local general = channels and channels:FindFirstChild("RBXGeneral") :: TextChannel?
				if general then
					general:DisplaySystemMessage(`<font color="#FFC83D"><b>{payload}</b></font>`)
				end
			end)
		end
	end)
	task.spawn(function()
		local ok, snap = pcall(function()
			return Net:InvokeServer("Sync")
		end)
		if ok and snap then
			snapshot = snap
			renderOpen()
		end
	end)

	-- close with Escape-like keys, when you fly, or when you walk away from the stall
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB) and openName then
			closeAll()
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("Coins"):Connect(renderOpen)

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

	local tick = 0
	RunService.RenderStepped:Connect(function(dt)
		local s = state()
		if bar then
			bar.Visible = s == "Ground"
		end
		if s ~= "Ground" and openName and openName ~= "Balloons" then
			closeAll()
		end
		tick += dt
		if tick < 0.2 then
			return
		end
		tick = 0
		local w = openName and windows[openName]
		if not w then
			return
		end
		-- walked away from the stall?
		if w.stall then
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local stall = ShopConfig.Stalls[w.stall]
			if hrp and stall then
				local spot = ShopConfig.StallPoint(w.stall, stall.Prompt, 0)
				if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(spot.X, 0, spot.Z)).Magnitude > 32 then
					closeAll()
					return
				end
			end
		end
		-- restock countdown
		if w.name == "Shop" and w.sub and snapshot and snapshot.shop then
			local left = math.max(0, math.floor(snapshot.shop.endsAt - workspace:GetServerTimeNow()))
			w.sub.Text = string.format("NEW STOCK IN %d:%02d", left // 60, left % 60)
		end
	end)
end

return MenuController
