# Feel pass mockup (2026-10-06)

Pictures: `island-banner.png`, `zone-banner.png` and `boards-chests-sky.png`, at a 1280×720 layout rendered at 1.5×. The source is `source/feel.html`. The style is the HUD v2 block recipe (see `docs/mockups/hud-v2/README.md`). Every stud surface uses `rbxassetid://6927295847`.

Gustav's decisions: all the recommendations, plus the group chest.

- **Island banner** (when you land on an island). It slides in under the top bar over a soft white sunburst.
  - A small zone chip ("MEADOW SKY", in the zone's colour).
  - A big white stud block with the island name in gold-gradient text.
  - On a first visit: a tilted gold "NEW ISLAND!" tag and a dark pill reading "+500 FIRST VISIT".
  - It plays a sound and holds for about 2.5 s.
- **Zone banner** (when you climb into a new zone). It shows a dark "ENTERING" chip, a big block in the zone's theme ("CLOUD SHELF", blue), and the height range "500 – 1,500m" in a white chip.
- **Sky:** it blends per player with height.
  - Meadow Sky is bright blue.
  - In Cloud Shelf the sky is deeper blue at the top and a golden haze sits at the horizon. A warm sun glow sits up high, and a cloud floor sinks below you.
  - Higher up it is deeper still.
- **Group chest:** a stud chest on each island with a billboard over it.
  - Gold "GROUP CHEST" with "1/2 PLAYERS • NEED 1 MORE" and a progress bar. With 2+ players landed it opens ("2 PLAYERS • OPEN!") and coins pop out.
  - Solo: a purple "YOUR CHEST" with "READY IN 3:42".
  - Reward card: a gold "GROUP CHEST!" header, the amount "+1,200" and "Shared with 3 players".
- **Leaderboards** (world boards on the start map): BIGGEST POP (red header, by size) and MOST BANKED (gold header, coins). Top 10 with gold, silver and bronze rank badges, updated every minute.
- **Coin rain:** 10% of a popped player's unbanked coins fall as coin pickups. Grabbing them shows a green "+48 COIN RAIN!" toast.
