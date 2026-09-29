# 1+ Ballon Pop: full game prompt (v3.5)

Written 2026-09-28. v3 follows Gustav's direction: **you hold a balloon** (you are not the balloon). Balloons grow in size, you buy different ones in a shop and upgrade them, and each balloon type rolls its own mutations. It keeps the pop risk from v2 so the game is about choices, not waiting. v3.1 adds the art style: classic Roblox stud models (section 14). v3.2 replaces the balloon list with all-original balloons and mutations. v3.4 gives everything short, simple one-word names (section 5.1b). v3.5 renames the game to 1+ Ballon Pop, adds the grass start map, and removes the parachute.

This file is written as a prompt. You can paste the whole thing into a new Claude thread, or give it to anyone building the game. Every number is a starting value for tuning, not a final one.

---

## 0. The prompt

> You are building a Roblox game called **1+ Ballon Pop** in Luau (same name as the Roblox Studio place and the GitHub repo). Players spawn on a **studded grass start map** on the ground. The player's avatar **holds a balloon** that grows +1 size every second and lifts them into the sky. A bigger balloon lifts higher and earns more, but it's a bigger target and easier to pop. Floating **sky islands** hang above the start map at rising heights. At any time the player can **land on a sky island to bank** their earnings as coins. If a hazard pops the balloon first, they lose everything unbanked and **fall straight down** (no parachute). Coins buy **new balloon types** from a restocking **Balloon Shop**. Each balloon has its own stats, its own **upgrade levels**, and its own **mutation pool**. Mutations roll as the balloon grows and stick to that balloon permanently once you bank. The game moves through **five phases** (Float, Climb, Storm, Space, Ascension), each with new sky zones, hazards, balloons and mutations. Friends can **grab your string** to ride along, defend you and share the bank. **Art style: classic Roblox stud models.** Everything (balloons, islands, hazards, hubs) is built from simple Parts with the stud surface texture, bright flat colors and chunky blocky shapes, like the popular stud-style simulators. Follow the spec below exactly. Keep all tunable numbers in `ReplicatedStorage/Shared/Config`, make the server authoritative for size, coins, pops, balloons and mutations, and never trust the client.

---

## 1. Pillars

1. **One more second.** Every second is a choice between growing more and landing now. Everything feeds that tension.
2. **Collect and grow your balloons.** Every balloon in your collection is worth leveling, and every shop restock might have something new.
3. **The pop is the payoff.** Popping looks and sounds amazing, even when it's you. Big pops are the clips people share.
4. **Friends make you go higher.** Riders make a balloon heavier but safer, and everyone earns when it banks.

## 2. Core loop (one "flight")

1. **Equip** a balloon from your inventory on the grass start map (or on your highest unlocked island) and jump. Size = 1.
2. **Grow:** the balloon gains `GrowthRate` size per second (base 1, set by the balloon type and its upgrades). It keeps growing until it reaches the balloon's **Max Size**.
3. **Rise:** lift comes from size. `height target = 40 × size^0.6` studs, capped by the zone ceiling. Your avatar dangles from the string with a hanging animation.
4. **Earn:** each second you earn **unbanked coins** = size × balloon earn bonus × multipliers, shown in a big counter above the balloon.
5. **Dodge:** hazards spawn based on altitude. Hits cost **Balloon HP**. HP comes from the balloon's Toughness. **Fragility** rises with size: damage taken = `hazardDamage × (1 + size / 200)`.
6. **Decide:**
   - **Land** on any island in range (hold E for `LandTime` seconds, which is vulnerable). Unbanked coins are banked, any new mutations stick to the balloon, and size resets.
   - **Keep going** for more.
   - **Get popped:** lose all unbanked coins and any mutations rolled this flight. You **fall straight down** with no parachute, arms flailing, and land wherever you land: back on the grass, or on an island if one is under you. Drop 10% of unbanked coins as **Confetti** for players below to grab.
7. **Spend** coins at island shops and the shops on the grass start map, then fly again.

**Starting numbers:**
- Balloon HP: from Toughness (see section 3).
- LandTime: 2.0 s base, down to 0.5 s with the Quick Knot upgrade.
- A typical early flight: 30 to 60 s. A late flight: 3 to 6 min.
- Hitting Max Size makes the balloon stop growing and glow. You can keep floating there for steady income, but hazards still come for you.

## 3. Balloons

Balloons are the main collectible. You own many, equip one at a time (a second "Duo" slot unlocks in Phase 3, see section 3.5), and upgrade each one separately.

### 3.1 Balloon stats
Every balloon type has five base stats:
- **Max Size:** how big it can grow (so how high and how much it can earn in one flight).
- **Growth:** size per second.
- **Toughness:** HP (how many hits it takes).
- **Lift:** how fast it climbs to its height target, and how many riders it can carry before slowing down.
- **Earn Bonus:** a multiplier on coins per second.

It also has a **Mutation Pool** (section 5), a **Mutation Slot count** (1 to 3), and a **special ability** from Rare upward.

### 3.2 Balloon list

All original. Every balloon is a real-world object turned into a floating stud model, and each one changes how you play, not just how much you earn.

| Balloon | Tier | Where sold | Max Size | Growth | Toughness | Earn | Slots | Special |
|---|---|---|---|---|---|---|---|---|
| Gumball | Common | Ground | 100 | 1.0 | 3 | x1 | 1 | none (the starter) |
| Bubble | Common | Ground | 90 | 0.8 | 6 | x1 | 1 | Every hit pops one bubble with a satisfying crackle |
| Ember | Common | Ground | 120 | 1.1 | 3 | x1.1 | 1 | Glows, so it's easy to spot on the night cycle (+10% coins at night) |
| Spike | Uncommon | Cloud Shelf | 180 | 1.2 | 4 | x1.3 | 1 | After a hit, puffs out spikes for 3 s that pop birds touching it |
| Popcorn | Uncommon | Cloud Shelf | 200 | 1.3 | 3 | x1.3 | 1 | Every 25 size a kernel pops out and drops coins for riders |
| Jelly | Uncommon | Kite Fields | 220 | 1.2 | 4 | x1.4 | 2 | Dangling tentacles slow any hazard coming from below |
| Buzz | Rare | Kite Fields | 350 | 1.5 | 5 | x1.8 | 2 | 3 bees orbit you and chase off one bird every 15 s |
| Frost | Rare | Windways | 400 | 1.4 | 6 | x2 | 2 | The first hit each flight freezes all hazards nearby for 4 s |
| Volt | Epic | Thunderhead | 700 | 1.8 | 7 | x3 | 2 | Absorbs lightning instead of taking damage and stores it as bonus coins |
| Thorn | Epic | Thunderhead | 750 | 1.6 | 12 | x3 | 2 | Half damage from everything, but nobody can grab your string (no riders) |
| Clock | Epic | Hail Belt | 800 | 1.6 | 8 | x3.2 | 2 | Every 20 s, slows time for nearby hazards by 50% for 5 s |
| Flame | Legendary | Hail Belt | 1,200 | 2.2 | 9 | x5 | 3 | Lava blobs float up out of the top and burn hazards above you |
| Whale | Legendary | Stratosphere | 1,600 | 1.8 | 12 | x5.5 | 3 | Huge and slow; carries up to 6 riders, and its song calms birds for 10 s |
| Iron | Legendary | Stratosphere | 1,300 | 2.0 | 14 | x6 | 3 | A balloon that shouldn't float. Letting out air slams you down and crushes every hazard below you |
| Void | Mythic | Moon Hub | 2,500 | 2.5 | 12 | x10 | 3 | Eats hazards that get too close, and each one it eats adds +5 size |
| Sun | Mythic | Moon Hub | 2,200 | 2.6 | 11 | x10 | 3 | Melts hail and meteors, and the Space vacuum can't shrink it |
| Crown | Mythic | Sky Boss only | 2,000 | 2.5 | 13 | x9 | 3 | Immune to pins, and bounces them back at whoever threw them |
| Cluck | Secret | Balloon Rain only (0.1%) | 3,000 | 3.0 | 10 | x12 | 3 | Squawks every 30 s and triggers a random effect: a coin shower, a speed boost, a free mutation roll, or it honks and does nothing |

### 3.3 The Balloon Shop (restocking)
- Each island hub has a shop. **Stock restocks every 5 minutes** for everyone in the server, with a visible countdown.
- Each restock rolls which balloons are in stock and how many (e.g. Gumball always in stock; Rare balloons appear ~20% of restocks, Epic ~5%, Legendary ~1%).
- A server message goes out when a Legendary is in stock. That creates the "everyone rush to the shop" moment.
- Players can buy **Restock Tokens** (earned from quests, or a Robux product) to restock their own shop view early.
- Prices scale by tier: Common 100 to 500, Uncommon 2k to 10k, Rare 50k to 150k, Epic 1M to 3M, Legendary 25M to 60M, Mythic 500M+.

### 3.4 Upgrading balloons
Each owned balloon has its own **level (1 to 50)**. Leveling costs coins and raises all its stats a little. Milestone levels give bigger jumps:
- Every level: +2% Max Size, +1% Growth, +1% Earn.
- Level 10: +1 Toughness. Level 20: +1 mutation slot (max 3). Level 30: +1 Toughness. Level 40: special ability upgraded (e.g. Buzz bees chase a bird every 10 s). Level 50: **Golden Edge**, a gold rim and +25% Earn.
- Cost: `baseCost(tier) × 1.15^level`.
- **Merging (Phase 3+):** combine 3 copies of the same balloon to raise its **Star rank** (1 to 5 stars). Each star gives +20% to all stats and a visual upgrade. This gives duplicate buys from the shop a use.

### 3.5 Duo slot (Phase 3)
Hold **two balloons** at once. Both grow, sizes add up for lift, and both roll mutations from their own pools. Two balloons also means two targets: either one popping drops you to the other's lift. Unlocked by a Phase 3 quest or a gamepass.

## 4. Phases of the game (the overhaul)

The game unfolds in five phases. Each unlocks new sky zones, hazards, balloons, mutations and systems, so the game changes every few hours of play rather than being one long number climb.

### Phase 1: Float (first 10 minutes)
- **Start map:** a studded grass map on the ground (designed by Gustav, or together). It holds the spawn, the first Balloon Shop, the balloon inventory stand and the leaderboards, with the first sky islands visible overhead so players always see where to go.
- **Zones:** Meadow Sky (0 to 500 studs), Cloud Shelf (500 to 1,500).
- **Hazards:** sparrows (1 dmg, slow), paper planes (drift in straight lines).
- **Balloons:** Gumball, Bubble, Ember, then Spike and Popcorn at Cloud Shelf.
- **Systems unlocked:** grow, land, fall, Balloon Shop, balloon leveling.
- **Tutorial via play:** the first bird is scripted to miss; the first landing gives a bonus x2; the first pop drops you gently onto an island with a "you'll get it next time" toast. No text walls.
- **Goal:** buy your second balloon and reach Cloud Shelf.

### Phase 2: Climb (10 minutes to 1 hour)
- **Zones:** Kite Fields (1,500 to 4,000), Windways (4,000 to 8,000).
- **Hazards:** spiky kites (patrol loops), gust walls (push you sideways into other hazards), seagull flocks (3 to 5 birds that dive together).
- **Balloons:** Jelly, Buzz, Frost.
- **Systems unlocked:** **Mutations** (section 5), **Riders** (section 7), trails, daily quests.
- **New mechanic: Updrafts.** Glowing columns that give +50% growth while you're inside. They move, so chasing them is a risk.
- **Goal:** first mutation, first Rebirth.

### Phase 3: Storm (1 to 5 hours)
- **Zones:** Thunderhead (8,000 to 15,000), Hail Belt (15,000 to 25,000).
- **Hazards:** lightning clouds (telegraphed strike after 1.5 s of charge-up), hail (area rain, chip damage), storm eagles (track the biggest balloon in range).
- **Balloons:** Volt, Thorn, Clock, Flame.
- **Systems unlocked:** **Storm Events** (section 10), **Patches** (consumable heals), **Merging**, **Duo slot**, owned islands (section 9).
- **New mechanic: Static.** Floating inside a storm cloud charges static. At full charge, release a **Shock Burst** that clears hazards around you, or save it for +25% coins at your next landing.
- **Goal:** first Epic balloon, own an island.

### Phase 4: Space (5 to 20 hours)
- **Zones:** Stratosphere (25,000 to 50,000), Orbit (50,000+, low gravity).
- **Hazards:** satellites (fast straight lines), meteor showers, **the Vacuum** (above a height line your balloon slowly shrinks unless you have Pressure Suit upgrades).
- **Balloons:** Whale, Iron, then Void and Sun at the Moon Hub.
- **Systems unlocked:** Pressure Suit upgrades, Space mutations, the Moon Hub with its own shop.
- **New mechanic: Orbit Slingshot.** Moons pull you around in arcs. Timing the release gives a burst of height and coins.
- **Goal:** reach the Moon, get a Mythic balloon or mutation.

### Phase 5: Ascension (endgame, 20+ hours)
- **Systems:** Ascension (section 6), **Weekly Sky Boss** (section 10), global leaderboards, seasonal balloons and mutations.
- **Goal:** climb Ascension ranks, max-star a Legendary, complete the Balloon and Mutation Index, top the Biggest Pop leaderboard.

## 5. Mutation system

Mutations are rare traits that roll **on the balloon you're holding** as it grows. They change how it looks and multiply what it earns. **Different balloons give different mutations**: each balloon type has its own themed pool.

### 5.1 How mutations roll
- Every **25 size** during a flight, the server rolls once on the held balloon's pool.
- Other sources: flying through a **Mutation Cloud** (rare, glowing, one per zone at a time), Storm Events (x3 chance), Sky Boss drops, Mutation Potions (section 11).
- **A new mutation is "pending" until you land.** Landing makes it stick to that balloon permanently. Popping loses it. This is the big "should I land now?" moment when something rare rolls.
- Each balloon has 1 to 3 **mutation slots**. If a new mutation rolls and the slots are full, you choose on landing: **replace** one, or **discard** the new one.
- A **Mutation Lock** (item) protects one slot so it can never be replaced by accident.
- A **Mutation Jar** (rare item or Robux product) saves pending mutations even if you pop.

### 5.1b Naming (the hook)
Every balloon and mutation has a **short, one-word name**, so together they read like a title: mutation first, then balloon. **Nova Sun**, **Venom Spike**, **Freeze Frost**, **Gold Flame**, **Infinity Void**. Players say these out loud and type them in chat ("I just got a Nova Sun!!"), which makes rare rolls spread. The UI always shows the full name above the balloon, colored by the rarest mutation. A balloon with 2 or 3 mutations lists them all ("Gold Venom Spike").

### 5.2 Rarity tiers and base chances (per roll)

| Tier | Chance | Earn multiplier | Visual level |
|---|---|---|---|
| Common | 20% | x1.2 | color tint |
| Uncommon | 8% | x1.5 | tint + particle |
| Rare | 2.5% | x2 | material change |
| Epic | 0.6% | x3.5 | material + aura + sound |
| Legendary | 0.12% | x6 | full effect, server announcement |
| Mythic | 0.02% | x12 | full effect, server-wide announcement + sky flash |
| Celestial (Space only) | 0.004% | x25 | custom model, global announcement |

Luck upgrades, balloon tier and events multiply these chances. Multipliers from a balloon's mutations **multiply together**, then with the balloon's own Earn stat.

### 5.3 Universal mutations (any balloon can roll these)
- **Common:** Chrome (shiny), Shadow (dark smoky tint), Stripes (bold stripes).
- **Uncommon:** Neon (glows, +5% coins at night), Sparkle (sparkle trail, +5% Confetti pickup), Steel (rises 20% slower, takes 15% less damage).
- **Rare:** Gold (gold material, +10% coins on landing), Rainbow (color cycles, riders earn +20%).

### 5.4 Balloon-specific pools (what makes each balloon different)
Each balloon adds its own themed mutations on top of the universal pool, and these **only** come from that balloon. That's the reason to collect them all.

| Balloon | Exclusive mutations |
|---|---|
| Gumball | Sour (U: +10% growth), Tough (R: +2 HP) |
| Bubble | Thick (U: +1 HP), Shield (R: the first pop each flight is only a bubble, and you keep flying) |
| Ember | Wisp (U: fireflies fly out and grab Confetti for you), Ghost (E: when popped, you glide down slowly and keep 25% of your coins) |
| Spike | Sharp (U: spikes last twice as long), Venom (E: anything that touches you is destroyed) |
| Popcorn | Butter (R: +20% coins), Chain (E: kernels drop twice as often) |
| Jelly | Glow (U: tentacles glow, +5% coins), Sting (L: tentacles pop every hazard below you) |
| Buzz | Honey (R: riders earn +20%), Queen (L: the swarm doubles to 6 bees) |
| Frost | Ice (R: +1 HP per 100 size), Freeze (E: freeze radius doubled) |
| Volt | Charged (R: static charges twice as fast), Thunder (L: every lightning strike also rolls a free mutation) |
| Thorn | Bloom (R: a flower opens and allows 1 rider), Mirage (E: 25% of hits miss) |
| Clock | Slowmo (E: slow radius doubled), Rewind (M: once per flight, undo the last hit) |
| Flame | Lava (E: burns kites on contact), Blast (L: when popped, the blast destroys everything nearby and saves 25% of your coins) |
| Whale | Shell (U: +1 HP), Song (L: song lasts 20 s and also stops meteors) |
| Iron | Anchor (R: +3 HP), Quake (L: slam radius tripled) |
| Void | Gravity (L: pulls in coins and Confetti from twice as far), Infinity (M: +100% Max Size) |
| Sun | Flare (L: once per flight, a flash clears every hazard on screen), Nova (M: when popped, you get back 50% of lost coins) |
| Crown | Royal (M: all riders earn +50%) |
| Cluck | Crazy (M: its random effect triggers twice as often) |

(U = Uncommon, R = Rare, E = Epic, L = Legendary, M = Mythic.)

**Celestial mutations** (Space zones only, any Legendary+ balloon): Orion, Draco, Lyra. Each turns the balloon into a star constellation and adds a unique power (e.g. Draco: a star serpent circles you and blocks one hit every 20 s).

### 5.5 Combos (hidden, discoverable)
Specific pairs on the same balloon give a secret bonus and a new name. They show as "???" in the Index until someone finds them.
- Gold + Butter = **Caramel** (x2 extra, coins drip off the bucket).
- Neon + Wisp = **Spirit** (x2 at night, lantern trail).
- Steel + Anchor = **Dead Weight** (x3 coins, but rises 50% slower).
- Rainbow + Honey = **Sugar** (rainbow bees, riders +50%).
- Sparkle + Ice = **Diamond** (glittering snow trail, +1 HP per 50 size).
Add 4 to 6 more over updates, including combos only possible with the Duo slot (one mutation from each balloon, e.g. Freeze + Lava = **Steam**, which makes a fog cloud that birds can't see through).

### 5.6 Index (collection book)
- Two tabs: **Balloons** and **Mutations**. Silhouettes until found.
- First discovery rewards: coins, a title, and a permanent +1% coins per entry found.
- Completing a row (e.g. all Popcorn mutations, all Epic balloons) gives a badge and a cosmetic.

## 6. Rebirth and Ascension

### Rebirth (Phase 2+)
- **Requirement:** total coins banked ≥ `1,000,000 × 2.5^rebirths`.
- **Resets:** coins, balloon levels (back to 1), general upgrades, unlocked zones.
- **Keeps:** all owned balloons, their mutations and Star ranks, cosmetics, the Index, owned island.
- **Gives:** permanent +0.5x coin multiplier per rebirth (rebirth 4 = x3.0), +1 Rebirth Token.
- **Presentation:** "Pop from the Top." You rise to your max height, let go, and pop every balloon you own in a giant firework show visible to the whole server, then fall all the way back to the grass. Your balloons come back reinflated.
- **Rebirth tree** (tokens): start flights at a higher size, faster landing, +1 HP on all balloons, +5% luck, auto-land at a chosen size (QoL), +1 shop stock slot.

### Ascension (Phase 5)
- **Requirement:** 25 rebirths.
- **Resets:** rebirths and the Rebirth tree.
- **Gives:** Ascension rank (Bronze, Silver, Gold, Diamond, Celestial), +1 mutation slot on every balloon at Silver and Diamond (up to 5), an Ascension aura, and a permanent x2 multiplier per rank (multiplicative).

## 7. Riders (social system)

- Any player can **grab another player's string** (walk up and press E, or get invited). Max riders: 1 base, +1 per 2 points of the balloon's Lift, up to 4.
- **Cost:** each rider adds weight (rise speed −10% each).
- **What riders do:** swing a **swatter** (click or tap) to knock away birds, kites and meteors in range; block pins; grab Confetti on the way.
- **Reward:** when the balloon lands, riders get **20%** of the bank *on top* (the owner loses nothing). +10% more if they're Roblox friends.
- **If it pops:** riders fall with you and keep what they grabbed.
- **Rider level:** separate XP from swats and landings, unlocking swatter skins and a bigger swat range.

## 8. PvP: pins (optional, opt-in)

- Players with **PvP on** (toggle at the hub, off by default) can throw **pins** at other PvP-on balloons.
- A pin hit does 1 damage. Popping another player's balloon gives you **15%** of their unbanked coins.
- Balloons above size 500 get a red outline for PvP players.
- Safe zones: every island and 30 studs around it.

## 9. Islands

- **Public islands** at fixed heights in each zone: landing points, Balloon Shops, quest givers.
- **Owned islands (Phase 3+):** buy a small floating island in your server. It becomes **your personal landing point** at any height you choose (within unlocked zones), gives +10% bank bonus, and can be decorated with a **Balloon Display** that shows off your best balloons and mutations to visitors.
- Friends can land on your island and give you a 5% tip.

## 10. Events and bosses

- **Storm Events** (every 20 min, Phase 3+ zones): 3 minutes of double hazards and x3 mutation chance.
- **Balloon Rain** (every 10 min): small free balloons fall from the sky. Popping them gives coins; catching a rare one gives a free balloon (low chance).
- **Lucky Restock** (random, about once an hour): every shop in the server gets a guaranteed Epic+ in stock for 2 minutes.
- **Sky Boss** (weekly, plus a server vote when 8+ players are in Phase 3+): the **Pin King**, a giant spiked hot-air balloon, crosses the map. Players ram it with their balloons (size = damage) while riders swat its minions. Rewards by damage share: coins, Mutation Jars, a guaranteed Rare+ roll, and a chance at the **Crown** balloon.
- **Seasons** (every 4 to 6 weeks): a limited seasonal balloon with its own mutation pool (e.g. Halloween: **Pumpkin** balloon with Haunted, Candy Corn and Jack-o'-Lantern mutations), a seasonal Index row and leaderboard.

## 11. General upgrades and items

| Upgrade | Effect per level | Max | Cost formula |
|---|---|---|---|
| Quick Knot | −0.075 s landing time | 20 | 200 × 2^lvl |
| Luck | +5% mutation chance | 20 | 500 × 2.3^lvl |
| Magnet | +3 studs pickup range | 10 | 300 × 2^lvl |
| Pressure Suit (Space) | −20% vacuum shrink | 5 | 1M × 3^lvl |

**Items:** Patch (heal 1 HP mid-flight), Mutation Potion (next roll is guaranteed Rare+), Mutation Lock, Mutation Jar, Restock Token.

**Cosmetics:** strings, trails, hanging animations, pop effects (confetti, fireworks, glitter bomb, cartoon "POP!" text), fall animations.

## 12. What this game deliberately leaves out

- **No pets and no eggs.** Balloons are the collection. This keeps scope down and the identity clear.
- No trading at launch. Add it later only if balloons and mutations prove valuable enough (and add trade locks for Mythic+).
- No combat outside opt-in pins.

## 13. Monetization (fair, Roblox-standard)

**Gamepasses:** x2 Coins, Duo slot early, +1 rider slot, Auto Land, VIP trail + chat tag, Lucky (x1.5 mutation luck), Shop Alerts (notifies you of Legendary stock anywhere).
**Developer products:** Mutation Jar, Mutation Potion, Restock Token, Patch pack, 15-minute x2 Luck, server-wide Lucky Restock (everyone benefits), coin packs.
**Rules:** nothing that pops other players. Mythic balloons can't be bought with Robux directly, only earned or rolled in shop stock.

## 14. Art style: stud models

The whole game uses the **classic studded-brick look**, like the popular stud-style Roblox games. It's cheap to build, it reads well on phones, and it makes the game look like it belongs on the front page.

**Rules**
- Build everything from basic **Parts** (Block, Wedge, Cylinder, Ball) with the **Studs** surface texture on top and inlets underneath. No MeshParts for world objects and no realistic materials.
- Use **Plastic** (or SmoothPlastic with a stud texture) and **bright, saturated flat colors** from one shared palette in `Config/Palette`. No gradients except on mutation effects.
- Keep shapes **chunky and blocky**: low part counts, stepped curves, big readable silhouettes. A good model reads at a glance from 200 studs away.
- Scale: 1 stud = the base unit. Islands, launch pads and shop stalls snap to a 1-stud grid (or 0.5 for details).

**Balloons**
- Each balloon is a small stud model: a stepped round body built from stacked blocks (a blocky "voxel sphere"), a knot made of a wedge, and a string made of thin parts or a `RopeConstraint` with a stud-colored beam.
- Every balloon type needs a distinct silhouette, not just a new color: Gumball = stepped sphere on a little stand, Popcorn = striped block bucket with kernel cubes on top, Spike = round body with wedge spikes, Clock = two stepped pyramids, Iron = a chunky grey block anvil, Whale = long blue block whale, and so on.
- Build each balloon at one base size and grow it with `Model:ScaleTo` so the studs stay crisp.

**Mutations on stud models**
- Tint mutations recolor the parts (Pastel, Neon uses Neon material).
- Material mutations swap parts to a themed look but keep the blocky shape (Gold = gold-colored studs with a shine, Diamond = Glass/ForceField parts, Lava = Neon orange cracks between blocks).
- Epic and up add extra parts: small blocky attachments (Queen adds more cube bees, Infinity adds a spinning ring of dark cubes around the Void).
- Particles stay square and chunky (square confetti, cube sparkles) to match.

**World**
- Sky islands are floating stud platforms with blocky trees, fences and shop stalls; each zone has its own color set (Meadow = green and yellow, Storm = dark blue and purple with neon yellow bolts, Space = grey moon studs with black sky).
- Hazards are blocky: square-bodied birds with wedge beaks, kites made of flat plates, lightning as stacked neon blocks, meteors as rough block clusters.
- Pops explode into **brick confetti**: the balloon breaks into its individual studded parts that tumble down. That's the clip moment, and it's cheap because the parts already exist.

**Pipeline**
- If Nest Riders' `build_eggs.py` voxel pipeline builds stud models, reuse it to generate balloon shapes from small voxel grids (e.g. a 9×9×11 grid per balloon), otherwise build them by hand in Studio.
- Keep part counts low: about 40 to 120 parts per balloon, and weld everything to one root part.

## 15. UI and feel

- **Above the balloon:** size and unbanked coins in big numbers that wobble as they tick up.
- **Risk ring:** fills red around the coin counter as fragility rises.
- **Pending mutations:** shown as glowing icons on the balloon with a "LAND TO KEEP" label. This is the most important piece of UI in the game.
- **Landing prompt:** appears when an island is in range, with an arrow to the nearest island at all times.
- **Pop:** 0.2 s slow-motion, screen shake, big confetti burst, sound scaled by size, then a card: "Popped at size 812. Lost 45,000 coins and a Legendary Sting Jelly." with a Retry button that relaunches instantly.
- **Landing:** coin-fountain into the counter; new mutations "stamp" onto the balloon.
- **Shop:** restock countdown, stock cards with rarity glow, a "NEW" tag for balloons not in your Index.
- **Balloon inventory:** grid with level, stars and mutation icons; tap to equip, upgrade or merge.
- **Mobile-first:** one big LAND button, tap to swat as a rider, joystick to steer.

## 16. Controls

- **Steer:** WASD or joystick sways you horizontally (slow and floaty).
- **Rising is automatic.** Hold Space or a button to **let out air** (drop height fast by losing 5% size per second) to dodge threats from above.
- **E or LAND button:** land when near an island.
- **Click or tap:** swat (riders) or throw a pin (PvP on).
- **After a pop:** no input. You just fall.

## 17. Technical spec

**Structure**
- `ReplicatedStorage/Shared/Config/` : `BalloonConfig` (all balloon types, stats, pools, specials), `GrowthConfig`, `ZoneConfig`, `HazardConfig`, `MutationConfig`, `ShopConfig`, `UpgradeConfig`, `RebirthConfig`, `EventConfig`.
- `ServerScriptService/Services/` : `DataService`, `FlightService` (size, coins, height targets, landing, pop, fall), `BalloonService` (inventory, equip, level, merge), `ShopService` (restock timer, stock rolls), `HazardService`, `MutationService` (rolls, pending, apply on landing), `RiderService`, `EventService`, `IslandService`, `PvPService`.
- `StarterPlayerScripts/Controllers/` : `FlightController` (steer, let out air), `UIController`, `ShopController`, `InventoryController`, `EffectsController` (pops, mutation visuals), `RiderController`.

**Authority**
- The server owns size, coins, HP, balloons, mutations and shop stock. The client only sends intents (steer, let out air, land, swat, throw, buy, equip, upgrade).
- Hazard hits are checked on the server (or client-reported and server-verified by distance and timestamp).
- Rate-limit every remote. Landing checks island range on the server. Shop purchases check stock and price on the server.

**Save data (v1 schema)**
```lua
{
  v = 1,
  coins = 0,
  totalBanked = 0,
  rebirths = 0, rebirthTokens = 0, rebirthTree = {},
  ascension = 0,
  balloons = {
    -- [uid] = { type = "Gumball", level = 1, stars = 0, mutations = { "Chrome" }, locked = { [1] = true } }
  },
  equipped = { primary = nil, duo = nil },   -- balloon uids
  upgrades = { quickKnot = 0, luck = 0, magnet = 0, pressure = 0 },
  items = { patch = 0, potion = 0, lock = 0, jar = 0, restockToken = 0 },
  index = { balloons = {}, mutations = {}, combos = {} },
  cosmetics = { owned = {}, equipped = { string = "Basic", trail = nil, pop = "Confetti" } },
  riderXP = 0,
  island = nil,            -- { height, display = {} }
  stats = { biggestSize = 0, biggestPop = 0, totalPops = 0 },
  settings = { pvp = false },
}
```
- Use ProfileStore (or Nest Riders' DataService if it has session locking; that repo was empty when last checked).
- Flight state (size, unbanked coins, pending mutations) is **not saved**. Leaving mid-flight counts as a pop. Show a warning on leave.
- Shop stock is per server and not saved; the restock seed is `serverStartTime + restockIndex` so everyone in the server sees the same stock.

**Performance**
- Hazards pooled and spawned only near players (per-player spawn budget by zone).
- Balloon visuals scale with `Model:ScaleTo`; cap the visual size and zoom the camera out for the rest so giant balloons don't break physics.
- Lift is a `VectorForce`/`AlignPosition` on the character, not real buoyancy.
- Mutation effects have particle budgets per tier; distant players' particles are disabled.

## 18. Build milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Grow and bank | You hold a Gumball balloon, it grows and lifts you, you land and bank, sparrows pop it, you fall back down, and it saves. The grass start map and first sky islands are in place. |
| M2 | Balloons + shop | 6 balloons, restocking shop, inventory, equip, per-balloon leveling. |
| M3 | Phase 1 & 2 content | Four zones, five hazard types, updrafts, daily quests. |
| M4 | Mutations | Rolls, pending until landing, per-balloon pools, slots, Lock/Jar, combos, Index. |
| M5 | Riders + Rebirth | Grab-the-string riders, swat, shared bank, Rebirth + tree. |
| M6 | Launch polish | Pop effects, mobile UI, gamepasses, leaderboards. **Publish here.** |
| M7 | Storm update | Storm zones, Static, Storm Events, merging, Duo slot, owned islands, PvP pins. |
| M8 | Space + Ascension | Space zones, Moon Hub, Celestial mutations, Ascension. |
| M9 | Sky Boss + Seasons | Pin King, Crown, first seasonal balloon. |

M1 to M6 is the launchable game, roughly 4 to 5 weeks. Storm, Space, bosses and seasons come as updates, which also gives players a reason to come back.

## 19. Open questions for Gustav

1. (Answered: the game is named "1+ Ballon Pop", exactly as in Studio.)
2. Do popped balloons stay in your inventory (current design), or can a balloon be lost for good on a pop? Losing it is more exciting but much harsher.
3. Is PvP pins in at launch, or saved for an update?
4. Build now, or park it until your other game is done?
