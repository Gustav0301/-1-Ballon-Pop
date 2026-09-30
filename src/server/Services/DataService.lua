--!strict
-- DataService: player saves through ProfileStore (session locked, auto-saving).
-- Save schema v1 from section 17 of the game prompt, plus a small `tutorial` table.
-- Flight state (size, unbanked coins) is never saved: leaving mid-flight counts as a pop.
--
-- In Studio without "Enable Studio Access to API Services", ProfileStore runs in mock
-- mode: everything works, nothing is written.

local Players = game:GetService("Players")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)

local DataService = {}

local STORE_NAME = "PlayerData_v1"

local TEMPLATE = {
	v = 1,
	coins = 0,
	totalBanked = 0,
	rebirths = 0,
	rebirthTokens = 0,
	rebirthTree = {},
	ascension = 0,
	balloons = {}, -- [uid] = { type = "Gumball", level = 1, stars = 0, mutations = {}, locked = {} }
	nextUid = 1,
	equipped = {}, -- { primary = uid?, duo = uid? }
	upgrades = { quickKnot = 0, luck = 0, magnet = 0, pressure = 0 },
	items = { patch = 0, potion = 0, lock = 0, jar = 0, restockToken = 0 },
	index = { balloons = {}, mutations = {}, combos = {} },
	cosmetics = { owned = {}, equipped = { string = "Basic", pop = "Confetti" } },
	riderXP = 0,
	stats = { biggestSize = 0, biggestPop = 0, totalPops = 0, flights = 0 },
	settings = { pvp = false },
	tutorial = { landed = false },
}

export type BalloonEntry = { type: string, level: number, stars: number, mutations: { string }, locked: { [number]: boolean } }

local Store = ProfileStore.New(STORE_NAME, TEMPLATE)
local profiles: { [Player]: any } = {}

DataService.Loaded = Instance.new("BindableEvent") -- (player, data)

local function giveBalloon(data: any, kind: string): string
	local uid = "b" .. tostring(data.nextUid)
	data.nextUid += 1
	data.balloons[uid] = { type = kind, level = 1, stars = 0, mutations = {}, locked = {} }
	data.index.balloons[kind] = true
	return uid
end

-- every profile owns at least a Gumball and has something equipped
local function ensureStarter(data: any)
	if next(data.balloons) == nil then
		data.equipped.primary = giveBalloon(data, "Gumball")
	end
	if not data.equipped.primary or not data.balloons[data.equipped.primary] then
		data.equipped.primary = next(data.balloons)
	end
end

local function leaderstats(player: Player, coins: number)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		local value = Instance.new("IntValue")
		value.Name = "Coins"
		value.Parent = folder
		folder.Parent = player
		stats = folder
	end
	local value = (stats :: Instance):FindFirstChild("Coins") :: IntValue?
	if value then
		value.Value = math.floor(coins)
	end
	player:SetAttribute("Coins", math.floor(coins))
end

local function onPlayerAdded(player: Player)
	local profile = Store:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		-- only happens while the server is shutting down
		player:Kick("Couldn't load your data - please rejoin")
		return
	end
	profile:AddUserId(player.UserId) -- GDPR
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was opened on another server - please rejoin")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	ensureStarter(profile.Data)
	profiles[player] = profile
	leaderstats(player, profile.Data.coins)
	player:SetAttribute("DataLoaded", true)
	DataService.Loaded:Fire(player, profile.Data)
end

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		profiles[player] = nil
		if profile then
			profile:EndSession()
		end
	end)
end

-- The live save table (nil until loaded). Mutate it directly; ProfileStore auto-saves.
function DataService.Get(player: Player): any?
	local profile = profiles[player]
	return profile and profile.Data
end

-- Waits (up to `timeout` seconds) for a player's data.
function DataService.Wait(player: Player, timeout: number?): any?
	local limit = os.clock() + (timeout or 30)
	while player.Parent == Players and os.clock() < limit do
		local data = DataService.Get(player)
		if data then
			return data
		end
		task.wait(0.1)
	end
	return nil
end

function DataService.AddCoins(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.coins = math.max(0, math.floor(data.coins + amount))
	if amount > 0 then
		data.totalBanked += math.floor(amount)
	end
	leaderstats(player, data.coins)
end

-- The equipped balloon: (uid, entry) or nil.
function DataService.Equipped(player: Player): (string?, BalloonEntry?)
	local data = DataService.Get(player)
	if not data then
		return nil, nil
	end
	local uid = data.equipped.primary
	return uid, uid and data.balloons[uid]
end

DataService.GiveBalloon = function(player: Player, kind: string): string?
	local data = DataService.Get(player)
	return data and giveBalloon(data, kind)
end

return DataService
