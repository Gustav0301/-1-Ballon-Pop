--!strict
-- BalloonConfig: every balloon type from section 3.2 of the game prompt.
--
-- Height uses decision A (2026-09-30): height target = 40 * size^0.6 * Lift.
-- Lift is tuned so each balloon at max size (level 1) reaches the zone where the
-- next tier is sold, which fixes the unreachable Phase 3-4 zones in the original formula:
--   Gumball 100 -> ~630 studs (Cloud Shelf), Popcorn -> ~1,900 (Kite Fields),
--   Frost -> ~10,200 (Thunderhead), Volt -> ~18,300 (Hail Belt), Flame -> ~36,600
--   (Stratosphere), Whale -> ~63,600 (Orbit), Void -> ~87,500.
-- Riders: the prompt's "+1 rider per 2 Lift" no longer fits these numbers, so riders
-- are set per balloon below (open question for Gustav).

local BalloonConfig = {}

BalloonConfig.HeightBase = 40
BalloonConfig.HeightExponent = 0.6

export type Tier = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type BalloonType = {
	Tier: Tier,
	Sold: string,
	MaxSize: number,
	Growth: number,
	Toughness: number,
	Earn: number,
	Slots: number,
	Lift: number,
	Riders: number,
	Special: string,
	Order: number,
}

BalloonConfig.TierColors = {
	Common = Color3.fromHex("A0A7B8"),
	Uncommon = Color3.fromHex("5BD15B"),
	Rare = Color3.fromHex("3FA9FF"),
	Epic = Color3.fromHex("B266FF"),
	Legendary = Color3.fromHex("FFC21A"),
	Mythic = Color3.fromHex("FF3F7F"),
	Secret = Color3.fromHex("FFFFFF"),
}

-- stylua: ignore
BalloonConfig.Types = {
	Gumball = { Order = 1,  Tier = "Common",    Sold = "Ground",       MaxSize = 100,  Growth = 1.0, Toughness = 3,  Earn = 1,   Slots = 1, Lift = 1,  Riders = 1, Special = "None (the starter)" },
	Bubble  = { Order = 2,  Tier = "Common",    Sold = "Ground",       MaxSize = 90,   Growth = 0.8, Toughness = 6,  Earn = 1,   Slots = 1, Lift = 1,  Riders = 1, Special = "Every hit pops one bubble with a satisfying crackle" },
	Ember   = { Order = 3,  Tier = "Common",    Sold = "Ground",       MaxSize = 120,  Growth = 1.1, Toughness = 3,  Earn = 1.1, Slots = 1, Lift = 1,  Riders = 1, Special = "Glows at night (+10% coins at night)" },
	Spike   = { Order = 4,  Tier = "Uncommon",  Sold = "Cloud Shelf",  MaxSize = 180,  Growth = 1.2, Toughness = 4,  Earn = 1.3, Slots = 1, Lift = 2,  Riders = 1, Special = "After a hit, puffs out spikes for 3 s that pop birds" },
	Popcorn = { Order = 5,  Tier = "Uncommon",  Sold = "Cloud Shelf",  MaxSize = 200,  Growth = 1.3, Toughness = 3,  Earn = 1.3, Slots = 1, Lift = 2,  Riders = 1, Special = "Every 25 size a kernel pops out and drops coins for riders" },
	Jelly   = { Order = 6,  Tier = "Uncommon",  Sold = "Kite Fields",  MaxSize = 220,  Growth = 1.2, Toughness = 4,  Earn = 1.4, Slots = 2, Lift = 5,  Riders = 2, Special = "Tentacles slow any hazard coming from below" },
	Buzz    = { Order = 7,  Tier = "Rare",      Sold = "Kite Fields",  MaxSize = 350,  Growth = 1.5, Toughness = 5,  Earn = 1.8, Slots = 2, Lift = 5,  Riders = 2, Special = "3 bees orbit you and chase off one bird every 15 s" },
	Frost   = { Order = 8,  Tier = "Rare",      Sold = "Windways",     MaxSize = 400,  Growth = 1.4, Toughness = 6,  Earn = 2,   Slots = 2, Lift = 7,  Riders = 2, Special = "First hit each flight freezes nearby hazards for 4 s" },
	Volt    = { Order = 9,  Tier = "Epic",      Sold = "Thunderhead",  MaxSize = 700,  Growth = 1.8, Toughness = 7,  Earn = 3,   Slots = 2, Lift = 9,  Riders = 3, Special = "Absorbs lightning and stores it as bonus coins" },
	Thorn   = { Order = 10, Tier = "Epic",      Sold = "Thunderhead",  MaxSize = 750,  Growth = 1.6, Toughness = 12, Earn = 3,   Slots = 2, Lift = 9,  Riders = 0, Special = "Half damage from everything, but no riders" },
	Clock   = { Order = 11, Tier = "Epic",      Sold = "Hail Belt",    MaxSize = 800,  Growth = 1.6, Toughness = 8,  Earn = 3.2, Slots = 2, Lift = 14, Riders = 3, Special = "Every 20 s, slows nearby hazards by 50% for 5 s" },
	Flame   = { Order = 12, Tier = "Legendary", Sold = "Hail Belt",    MaxSize = 1200, Growth = 2.2, Toughness = 9,  Earn = 5,   Slots = 3, Lift = 13, Riders = 3, Special = "Lava blobs float up and burn hazards above you" },
	Whale   = { Order = 13, Tier = "Legendary", Sold = "Stratosphere", MaxSize = 1600, Growth = 1.8, Toughness = 12, Earn = 5.5, Slots = 3, Lift = 19, Riders = 6, Special = "Carries 6 riders; its song calms birds for 10 s" },
	Iron    = { Order = 14, Tier = "Legendary", Sold = "Stratosphere", MaxSize = 1300, Growth = 2.0, Toughness = 14, Earn = 6,   Slots = 3, Lift = 17, Riders = 3, Special = "Letting out air slams you down, crushing hazards below" },
	Void    = { Order = 15, Tier = "Mythic",    Sold = "Moon Hub",     MaxSize = 2500, Growth = 2.5, Toughness = 12, Earn = 10,  Slots = 3, Lift = 20, Riders = 4, Special = "Eats hazards that get too close (+5 size each)" },
	Sun     = { Order = 16, Tier = "Mythic",    Sold = "Moon Hub",     MaxSize = 2200, Growth = 2.6, Toughness = 11, Earn = 10,  Slots = 3, Lift = 20, Riders = 4, Special = "Melts hail and meteors; the Vacuum can't shrink it" },
	Crown   = { Order = 17, Tier = "Mythic",    Sold = "Sky Boss",     MaxSize = 2000, Growth = 2.5, Toughness = 13, Earn = 9,   Slots = 3, Lift = 20, Riders = 4, Special = "Immune to pins and bounces them back" },
	Cluck   = { Order = 18, Tier = "Secret",    Sold = "Balloon Rain", MaxSize = 3000, Growth = 3.0, Toughness = 10, Earn = 12,  Slots = 3, Lift = 20, Riders = 4, Special = "Squawks every 30 s and triggers a random effect" },
} :: { [string]: BalloonType }

-- Height target in studs above the grass for a balloon of `size` (decision A).
function BalloonConfig.HeightFor(size: number, lift: number): number
	return BalloonConfig.HeightBase * math.max(size, 0) ^ BalloonConfig.HeightExponent * lift
end

-- Balloon names sorted by their order in the Index.
function BalloonConfig.Ordered(): { string }
	local names = {}
	for name in BalloonConfig.Types do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		return BalloonConfig.Types[a].Order < BalloonConfig.Types[b].Order
	end)
	return names
end

return BalloonConfig
