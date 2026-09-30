--!strict
-- BalloonService: your balloons (inventory, equip, upgrade), the stalls on the start map
-- (ProximityPrompts + top-bar teleports) and the menus' remote.
--
--   BalloonNet (RemoteFunction, client -> server, every call rate limited):
--     "Sync"                  -> snapshot
--     "Buy", kind             -> ok, message, snapshot
--     "Equip", uid            -> ok, message, snapshot
--     "Upgrade", uid          -> ok, message, snapshot
--     "Teleport", place       -> ok, message        (Shop / Spawn / Upgrades / Index)
--   BalloonSync (RemoteEvent, server -> client):
--     "Snapshot", snapshot    after anything changes (and on join / restock)
--     "Announce", text        server message (a Legendary is in stock, ...)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local FlightService = require(script.Parent.FlightService)

local BalloonService = {}

local BalloonConfig: any
local ShopConfig: any
local Sync: RemoteEvent
local lastCall: { [Player]: number } = {}
local lastTeleport: { [Player]: number } = {}

export type Snapshot = {
	balloons: { { uid: string, type: string, level: number, stars: number } },
	equipped: string?,
	found: { [string]: boolean },
	shop: any,
}

function BalloonService.Snapshot(player: Player): Snapshot?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local list = {}
	for uid, b in data.balloons do
		table.insert(list, { uid = uid, type = b.type, level = b.level, stars = b.stars or 0 })
	end
	-- best first: tier order, then level
	table.sort(list, function(a, b)
		local oa = (BalloonConfig.Types[a.type] or {}).Order or 99
		local ob = (BalloonConfig.Types[b.type] or {}).Order or 99
		if oa ~= ob then
			return oa > ob
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		return a.uid < b.uid
	end)
	return {
		balloons = list,
		equipped = data.equipped.primary,
		found = table.clone(data.index.balloons),
		shop = ShopService.View(player),
	}
end

local function push(player: Player)
	local snap = BalloonService.Snapshot(player)
	if snap then
		Sync:FireClient(player, "Snapshot", snap)
	end
end

function BalloonService.Equip(player: Player, uid: string): (boolean, string)
	local data = DataService.Get(player)
	local entry = data and data.balloons[uid]
	if not data or not entry then
		return false, "You don't own that balloon"
	end
	data.equipped.primary = uid
	FlightService.Refresh(player)
	local flying = FlightService.GetState(player) ~= "Ground"
	return true, if flying then `{entry.type} equipped - you'll hold it next flight` else `{entry.type} equipped!`
end

function BalloonService.Upgrade(player: Player, uid: string): (boolean, string)
	local data = DataService.Get(player)
	local entry = data and data.balloons[uid]
	if not data or not entry then
		return false, "You don't own that balloon"
	end
	local t = BalloonConfig.Types[entry.type]
	if not t then
		return false, "Unknown balloon"
	end
	if entry.level >= ShopConfig.MaxLevel then
		return false, "Already max level!"
	end
	local cost = ShopConfig.UpgradeCost(t.Tier, entry.level)
	if data.coins < cost then
		return false, "Not enough coins"
	end
	DataService.AddCoins(player, -cost)
	entry.level += 1
	if data.equipped.primary == uid then
		FlightService.Refresh(player)
	end
	local milestone = if entry.level == 10 or entry.level == 30
		then " +1 Toughness!"
		elseif entry.level == 20 then " +1 mutation slot!"
		elseif entry.level == 50 then " GOLDEN EDGE!"
		else ""
	return true, `{entry.type} is now level {entry.level}!{milestone}`
end

function BalloonService.Teleport(player: Player, place: string): (boolean, string)
	if FlightService.GetState(player) ~= "Ground" then
		return false, "Land first!"
	end
	if os.clock() - (lastTeleport[player] or 0) < 1.5 then
		return false, ""
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return false, ""
	end
	local cf: CFrame
	if place == "Spawn" then
		cf = CFrame.lookAt(ShopConfig.Spawn, ShopConfig.Spawn + Vector3.new(0, 0, -1))
	elseif ShopConfig.Stalls[place] then
		cf = ShopConfig.StandCFrame(place)
	else
		return false, ""
	end
	lastTeleport[player] = os.clock()
	character:PivotTo(cf)
	return true, ""
end

--------------------------------------------------------------------------------
-- stall prompts (the menu opens on the client when the prompt is triggered)

local function buildPrompts()
	local folder = workspace:FindFirstChild("StallPrompts") or Instance.new("Folder")
	folder.Name = "StallPrompts"
	folder.Parent = workspace
	for name, stall in ShopConfig.Stalls do
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(2, 2, 2)
		part.Position = ShopConfig.StallPoint(name, stall.Prompt, stall.PromptY)
		part.Parent = folder
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Open" .. name
		prompt.ActionText = stall.Action
		prompt.ObjectText = stall.Object
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt:SetAttribute("Menu", name)
		prompt.Parent = part
	end
end

--------------------------------------------------------------------------------

local LIMIT = 0.2

local function onInvoke(player: Player, kind: unknown, arg: unknown): ...any
	if type(kind) ~= "string" then
		return false, ""
	end
	local now = os.clock()
	if kind ~= "Sync" and now - (lastCall[player] or 0) < LIMIT then
		return false, "Slow down!"
	end
	lastCall[player] = now
	if kind == "Sync" then
		return BalloonService.Snapshot(player)
	end
	if type(arg) ~= "string" or #arg > 40 then
		return false, ""
	end
	local ok, msg
	if kind == "Buy" then
		ok, msg = ShopService.Buy(player, arg)
	elseif kind == "Equip" then
		ok, msg = BalloonService.Equip(player, arg)
	elseif kind == "Upgrade" then
		ok, msg = BalloonService.Upgrade(player, arg)
	elseif kind == "Teleport" then
		return BalloonService.Teleport(player, arg)
	else
		return false, ""
	end
	return ok, msg, BalloonService.Snapshot(player)
end

export type StartOptions = { Shared: Instance, RemoteParent: Instance }

function BalloonService.Start(opts: StartOptions)
	local shared: any = opts.Shared
	BalloonConfig = require(shared.Config.BalloonConfig) :: any
	ShopConfig = require(shared.Config.ShopConfig) :: any

	local net = Instance.new("RemoteFunction")
	net.Name = "BalloonNet"
	net.OnServerInvoke = onInvoke
	net.Parent = opts.RemoteParent
	local sync = Instance.new("RemoteEvent")
	sync.Name = "BalloonSync"
	sync.Parent = opts.RemoteParent
	Sync = sync

	ShopService.Start(opts.Shared)
	ShopService.Changed.Event:Connect(function(player: Player?)
		if player then
			push(player)
		else
			for _, p in Players:GetPlayers() do
				push(p)
			end
		end
	end)
	ShopService.Announce.Event:Connect(function(text: string)
		Sync:FireAllClients("Announce", text)
	end)
	DataService.Loaded.Event:Connect(function(player: Player)
		push(player)
	end)
	buildPrompts()

	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
		lastTeleport[player] = nil
	end)

	-- Studio only: "/coins 1000000" in chat for test money
	if RunService:IsStudio() then
		local function listen(player: Player)
			player.Chatted:Connect(function(msg)
				local amount = tonumber(msg:match("^/coins%s+(%d+)"))
				if amount then
					DataService.AddCoins(player, amount)
					push(player)
				end
			end)
		end
		for _, p in Players:GetPlayers() do
			listen(p)
		end
		Players.PlayerAdded:Connect(listen)
	end
end

return BalloonService
