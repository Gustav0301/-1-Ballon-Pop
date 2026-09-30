--!strict
-- ShopService: the restocking Balloon Shop (section 3.3), server authoritative.
--
-- Every 5 minutes the whole server gets a new stock roll, seeded by the server's start
-- time + the restock number, so everyone sees the same balloons. Each player has their
-- own quantity of each (nobody can buy out a Legendary before you get there). A server
-- message goes out when a Legendary or Mythic is in stock.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)

local ShopService = {}

ShopService.Changed = Instance.new("BindableEvent") -- (player?) shop view changed (nil = everyone)
ShopService.Announce = Instance.new("BindableEvent") -- (text) server-wide message

local ShopConfig: any
local BalloonConfig: any
local seed = 0
local startedAt = 0
local index = -1
local stock: { [string]: number } = {} -- kind -> count per player this restock
local bought: { [Player]: { [string]: number } } = {}

export type Item = { kind: string, price: number, left: number, stock: number }

local function roll(i: number): { [string]: number }
	local out = {}
	local rng = Random.new(seed + i * 7919)
	local studio = RunService:IsStudio() and ShopConfig.StudioEverything
	for _, kind in BalloonConfig.Ordered() do
		local price = ShopConfig.Prices[kind]
		local t = BalloonConfig.Types[kind]
		local rule = t and ShopConfig.Stock[t.Tier]
		if price and rule then
			local count = rule.Count
			local n = rng:NextInteger(count[1], count[2])
			if studio or ShopConfig.AlwaysInStock[kind] or rng:NextNumber() < rule.Chance then
				out[kind] = n
			end
		end
	end
	return out
end

local function restock(i: number)
	index = i
	stock = roll(i)
	table.clear(bought)
	for kind in stock do
		local t = BalloonConfig.Types[kind]
		if t and ShopConfig.AnnounceTiers[t.Tier] then
			ShopService.Announce:Fire(`A {string.upper(t.Tier)} {kind} balloon is in the Balloon Shop!`)
		end
	end
	ShopService.Changed:Fire(nil)
end

function ShopService.EndsAt(): number
	return startedAt + (index + 1) * ShopConfig.RestockEvery
end

-- What this player sees: every balloon in stock, in Index order, with how many are left.
function ShopService.View(player: Player): { index: number, endsAt: number, items: { Item } }
	local items = {}
	local mine = bought[player] or {}
	for _, kind in BalloonConfig.Ordered() do
		local n = stock[kind]
		if n then
			table.insert(items, { kind = kind, price = ShopConfig.Prices[kind], left = math.max(0, n - (mine[kind] or 0)), stock = n })
		end
	end
	return { index = index, endsAt = ShopService.EndsAt(), items = items }
end

-- Returns (ok, message).
function ShopService.Buy(player: Player, kind: string): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading your data"
	end
	local n = stock[kind]
	local price = ShopConfig.Prices[kind]
	if not n or not price then
		return false, "Not in stock"
	end
	local mine = bought[player] or {}
	bought[player] = mine
	if (mine[kind] or 0) >= n then
		return false, "Sold out - new stock soon!"
	end
	if data.coins < price then
		return false, "Not enough coins"
	end
	DataService.AddCoins(player, -price)
	mine[kind] = (mine[kind] or 0) + 1
	DataService.GiveBalloon(player, kind)
	return true, `You got a {kind} balloon!`
end

function ShopService.Start(shared: Instance)
	ShopConfig = require((shared :: any).Config.ShopConfig) :: any
	BalloonConfig = require((shared :: any).Config.BalloonConfig) :: any
	startedAt = math.floor(workspace:GetServerTimeNow())
	seed = startedAt
	restock(0)
	Players.PlayerRemoving:Connect(function(player)
		bought[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(math.max(0.5, ShopService.EndsAt() - workspace:GetServerTimeNow()))
			restock(index + 1)
		end
	end)
end

return ShopService
