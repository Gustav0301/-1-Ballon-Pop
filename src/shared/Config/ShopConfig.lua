--!strict
-- ShopConfig: the Balloon Shop (section 3.3), balloon upgrades (section 3.4) and the
-- stalls on the start map. Starting values - tune freely.

local ShopConfig = {}

ShopConfig.RestockEvery = 300 -- seconds (5 minutes), same for everyone in the server

-- Studio play-tests only: every balloon is in stock, so you can see the whole shop.
-- (Live servers always roll the stock.) Type "/coins 1000000" in chat for test money.
ShopConfig.StudioEverything = true

-- Price per balloon, inside the prompt's tier ranges. Not listed = not sold in the shop
-- (Cluck is the Secret balloon from Balloon Rain).
-- stylua: ignore
ShopConfig.Prices = {
	Gumball = 100,       Bubble = 250,        Ember = 500,
	Spike = 2_000,       Popcorn = 5_000,     Jelly = 10_000,
	Buzz = 50_000,       Frost = 150_000,
	Volt = 1_000_000,    Thorn = 2_000_000,   Clock = 3_000_000,
	Flame = 25_000_000,  Iron = 40_000_000,   Whale = 60_000_000,
	Void = 500_000_000,  Sun = 750_000_000,   Crown = 1_000_000_000,
} :: { [string]: number }

-- chance a balloon of this tier is in a restock, and how many you can buy of it
-- stylua: ignore
ShopConfig.Stock = {
	Common    = { Chance = 0.7,   Count = { 3, 8 } }, -- Gumball is always in stock
	Uncommon  = { Chance = 0.4,   Count = { 2, 4 } },
	Rare      = { Chance = 0.2,   Count = { 1, 2 } },
	Epic      = { Chance = 0.05,  Count = { 1, 1 } },
	Legendary = { Chance = 0.01,  Count = { 1, 1 } },
	Mythic    = { Chance = 0.002, Count = { 1, 1 } },
} :: { [string]: { Chance: number, Count: { number } } }
ShopConfig.AlwaysInStock = { Gumball = true }
ShopConfig.AnnounceTiers = { Legendary = true, Mythic = true } -- server message when in stock

-- upgrades: cost = UpgradeBase[tier] x 1.15 ^ level, levels 1 to 50
-- stylua: ignore
ShopConfig.UpgradeBase = {
	Common = 40, Uncommon = 400, Rare = 4_000, Epic = 60_000,
	Legendary = 1_000_000, Mythic = 20_000_000, Secret = 20_000_000,
} :: { [string]: number }
ShopConfig.MaxLevel = 50
ShopConfig.UpgradeGrowth = 1.15

function ShopConfig.UpgradeCost(tier: string, level: number): number
	local base = ShopConfig.UpgradeBase[tier] or ShopConfig.UpgradeBase.Common
	return math.floor(base * ShopConfig.UpgradeGrowth ^ level)
end

-- The stalls on the start map (tools/map/build_start_map.py): where each one stands,
-- which way it faces (towards the plaza centre) and its build scale.
--   Prompt: how far in front of the stall's centre the ProximityPrompt sits
--   Stand:  how far in front you're put when you teleport there
-- stylua: ignore
ShopConfig.Stalls = {
	Shop     = { Pos = Vector3.new(-84, 0, -6),  Scale = 1.5,  Prompt = 5,  PromptY = 4.5, Stand = 19, Action = "Open Shop",     Object = "Balloon Shop" },
	Upgrades = { Pos = Vector3.new(54, 0, -58),  Scale = 1.35, Prompt = 9,  PromptY = 4,   Stand = 16, Action = "Upgrade",       Object = "Upgrades" },
	Index    = { Pos = Vector3.new(94, 0, 8),    Scale = 1.45, Prompt = 9,  PromptY = 4,   Stand = 16, Action = "Open Balloons", Object = "Balloon Index" },
} :: { [string]: { Pos: Vector3, Scale: number, Prompt: number, PromptY: number, Stand: number, Action: string, Object: string } }
ShopConfig.Spawn = Vector3.new(0, 7, 6)

-- a point `depth` studs (in the stall's own units) in front of a stall, `y` studs up
function ShopConfig.StallPoint(name: string, depth: number, y: number): Vector3
	local stall = ShopConfig.Stalls[name]
	local flat = Vector3.new(stall.Pos.X, 0, stall.Pos.Z)
	local toCentre = if flat.Magnitude > 0.01 then -flat.Unit else Vector3.new(0, 0, -1)
	return stall.Pos + toCentre * depth * stall.Scale + Vector3.new(0, y, 0)
end

-- where the teleport puts you: in front of the stall, looking at it
function ShopConfig.StandCFrame(name: string): CFrame
	local stall = ShopConfig.Stalls[name]
	local at = ShopConfig.StallPoint(name, stall.Stand, 3.5)
	local look = Vector3.new(stall.Pos.X, at.Y, stall.Pos.Z)
	return CFrame.lookAt(at, look)
end

return ShopConfig
