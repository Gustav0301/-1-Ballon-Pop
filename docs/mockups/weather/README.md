# Weather, island rewards and weather mutations: mockup (2026-10-07)

Pictures: `weather.png`, `reward.png`, `mutation.png` and `parts.png`. Each is a 1280×720 layout rendered at 1.5×. The style is the HUD v2 block recipe (see branch `mockups/hud-v2`). Every stud surface uses `rbxassetid://6927295847`.

Gustav's decisions (2026-10-07):
- Every zone gets weather that changes.
- Every island gets its own reward instead of the chest. The group chest and the solo chest are switched off.
- Weather can give a balloon a mutation that stays forever if you land. It works like pets do in Ride a Pet.
- This is built before balloon abilities.

## Weather
- Each zone has its own weather. It is the same for everyone in the server and changes about every 5 minutes. A 30-second warning toast comes first: an orange "FOG COMING IN 0:30".
- When it changes, a banner appears with the zone chip, a big themed block with the weather icon and name ("RAIN!"), and a white line saying what it does. It uses the same sunburst and sound as the zone banner.
- A **weather pill** sits under the coin counter while you fly. It shows the icon, the name and a dark timer chip.
- Rule: bad weather is harder but pays more. Meadow Sky stays gentle for new players.

| Zone | Weather | Theme | Effect | Mutation |
|---|---|---|---|---|
| Meadow Sky | Sunny | gold | calm | none |
| Meadow Sky | Breeze | green | pushes you a bit sideways, +25% coins | none |
| Meadow Sky | Rain | blue | balloon grows x1.5 faster | Wet (x1.5) |
| Meadow Sky | Rainbow | purple | short, only after Rain | Rainbow (x2, the existing rare) |
| Cloud Shelf | Clear | blue | calm | none |
| Cloud Shelf | Fog | grey | islands only visible up close, x1.5 coins | Misty (x1.5) |
| Cloud Shelf | Golden Hour | orange | gold sparkles to grab, x1.5 coins | Sunlit (x2) |

Later zones get Gusts (Kite Fields) and Thunderstorm with lightning (Windways), with a Shocked mutation.

## Weather mutations (`mutation.png`)
These follow GAME_PROMPT section 5.1.
- While you fly in a weather, you can roll its mutation. The roll is pending: a blue glow around the balloon and drips on it, the name tag shows the mutation first ("WET EMBER"), a tilted "WET!" stamp pops in, and a big gold **LAND TO KEEP!** ribbon appears with a dark line under it ("Wet x1.5 coins • pop = lost").
- Landing stamps it onto that balloon forever: a green "MUTATION KEPT!" card, and in My Balloons a badge on the card plus the name "WET EMBER".
- Popping loses it, but the balloon stays.
- Each balloon in the inventory is saved on its own with its own mutation list (`mutations = {...}` in the save schema).

## Island rewards (`reward.png`)
These are already built in Studio, in `FeelConfig.IslandRewards`.
- Landing gives a boost for your next flight. Land there again to get it again.
- The card shows a purple "ISLAND REWARD" chip, a white block with the gradient name ("RAINBOW BALLOON!") and a dark pill ("x1.25 COINS • NEXT FLIGHT").
- While you fly, a chip under the weather pill shows the boost with a "1 FLIGHT" tag.
- The gold and rainbow looks are temporary. They are not mutations.

| Island | Reward |
|---|---|
| Flower Patch | Honey: x1.5 coins |
| Windmill Hill | Tailwind: grow +30% |
| Rainbow Shelf | Rainbow look, x1.25 coins |
| Cotton Castle | Soft Landing: keep half your coins if you pop |
| Summit Cloud | Gold look, x2 coins |
| Candy Cloud | Treat: a random gift |
| Meadow Rest | none |
