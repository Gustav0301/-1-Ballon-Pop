# HUD v2 mockup (approved by Gustav 2026-10-06)

Pictures: `hud-ground.png`, `hud-flying.png`, `hud-parts.png` (1280×720 layout, rendered at 1.5×). Source: `source/hud.html`.

The mockup uses look-alike studs because Roblox images can't load in the cloud. **In Studio, use the stud texture `rbxassetid://6927295847` for every stud surface** (Gustav's rule for all stud designs).

## What changes

Everything on screen gets the new look **except the coin bar and the height meter**. Those keep their shape; the coin bar only swaps its stud texture to 6927295847. The shop and Index windows also swap to 6927295847.

Restyle: the top bar (BALLOONS / SHOP / SPAWN / UPGRADES), the left Shop button, JUMP TO FLY, LAND (hold E), LET OUT AIR, the island arrow, the balloon billboard (+coins, SIZE chip, HP pips, RISK bar), island markers, the BANKED! and POPPED! cards and the toasts. Keep every name the code uses (see `docs/HUD_EDITING.md`, "Keep these names"; the Studio `BalloonHUD` is the live version).

## The block recipe (every button, chip, tag and card)

- Face: Frame + UICorner + UIStroke 3.5 px, colour `1A0E22`.
- UIGradient with 3 stops: 0 = Light, 0.48 = Mid, 1 = Dark; Rotation ≈ 70 (mostly top-to-bottom, slightly diagonal).
- Studs: ImageLabel `rbxassetid://6927295847`, ScaleType Tile, TileSize about 26×26 (16–20 on small chips), clipped to the face. Dimmer on dark panels.
- Gloss: white frame over the top 44 %, inset 5 px, UIGradient transparency 0.58 → 0.94.
- Lip: the same shape 5–8 px lower, Lip colour, same outline.
- Shadow: the same shape another 5 px lower, black at 0.72 transparency.
- Text: Fredoka One, white, UIStroke in the theme's text-stroke colour (3–4.5 px), plus a drop-shadow copy 3 px lower in black at 0.65 transparency.
- Key chips (E, SPACE): small white block, dark text, no studs.

| Theme | Light | Mid | Dark | Lip | Text stroke | Used for |
|---|---|---|---|---|---|---|
| red | FF9A66 | FF3F66 | D41450 | 8C0B38 | 4A0520 | JUMP TO FLY, Shop button, POPPED!, SIZE chip |
| green | CFFF70 | 45E07F | 0DAE6B | 07744A | 053D26 | LAND, BANKED!, SPAWN, marker "land here" |
| blue | 8AF5FF | 3D9EFF | 5A46F2 | 2C209A | 0D1A58 | LET OUT AIR, top-bar SHOP |
| purple | FFA8EC | B46CFF | 6B42F0 | 3D21A2 | 280E5A | BALLOONS, edge arrow, far-away marker |
| gold | FFF48C | FFC530 | FF8B1F | B0500B | 5A2400 | FIRST LANDING x2 ribbon, coin bar |
| orange | FFDB75 | FF9E38 | FF5C3C | AE3514 | 561700 | UPGRADES, marker "drop down / float up" |
| dark | 5E4C86 | 3B2D5E | 251B40 | 130C24 | 120A20 | card bodies, toasts, small info tabs |
| grey | E9ECF3 | C3C8D6 | 9AA0B4 | 5F657A | 2A2D38 | LAND when out of range |

## Pieces

- **Top bar:** icon + label blocks. BALLOONS (purple, balloon picture), SHOP (blue, basket icon), SPAWN (green, a bit taller, grass cap with drips, house icon), UPGRADES (orange, up arrow).
- **Left Shop button:** red square block, basket picture, "SHOP". It still hides while flying.
- **JUMP TO FLY:** red block, balloon picture on the left, SPACE chip on the top-right corner, gentle bob.
- **LAND:** big green block, E chip top-left, island name in a dark tab above, gold "FIRST LANDING x2" ribbon tilted on the top-right corner. Holding E sweeps a white fill (0.5 transparency) from left to right; the text reads LANDING. Out of range it turns grey.
- **LET OUT AIR:** blue square block, big white down arrow, SPACE chip on top.
- **Balloon billboard:** coin + "+2,184" with a gold gradient on the text (UIGradient on the TextLabel: FFFBD0 → FFE04A → FFA51F) and a dark brown stroke, two small white sparkles. Below: red SIZE chip, HP balloon pips (lost ones grey), RISK bar with a green → yellow → red fill.
- **Island marker:** a block in the state colour with the island name and a round white badge on the left (✓ green = in the landing window, ↓/↑ orange = drop down / float up, dot purple = far away). Under it is a dark tab: "LAND HERE! 46m" / "DROP DOWN 72m" / "FLOAT UP 30m" / "▲ 240m", then a small pointer triangle in the state colour. Far markers are smaller and slightly see-through.
- **Edge arrow:** a round purple block with a small island picture and the distance, and a triangle pointer that rotates around it towards the island. Left edge, where the Shop button sits on the ground.
- **Cards:** a dark stud body, a big header block (green BANKED! / red POPPED!) overlapping the top, and a slowly spinning white sunburst behind. BANKED: coin + gold gradient amount (counts up), "Windmill Hill • size 38", gold ribbon. POPPED: "Popped at size 42", "-1,234 lost" in pink FFB8C6, "Land sooner next time!" in yellow FFE04A.
- **Toasts:** pill blocks (dark by default; green for coin bonuses, red for warnings, gold for rare stock) with an icon on the left.
