# Balloon crates on the islands: preview and Studio spec

Open `index.html` in a browser to see all four crates turn, and press OPEN to watch the spin, burst and reveal. Pictures are in `pictures/`.

This file says everything that was decided in the thread, so the Studio build doesn't need the chat.

## What Gustav decided (2026-10-10)

1. **The crate shop is physical.** No crate window as the main way to buy. One crate stands on each island:
   - **Meadow Crate** on the start map, near spawn.
   - **Cloud Crate** on Rainbow Shelf.
   - **Kite Crate** on Kite Harbor.
   - **Storm Crate** on Gust Gate.
2. **Each crate is themed to its island** and is **built from Gustav's imported stud crate in Studio** (ask Gustav for its name and place if you can't find it). Use his crate as the base body for all four, then add the theme pieces from this preview on top. The crate in this preview is a stand-in, because his crate is only in Studio.
3. **Each crate has a stud stall** with a sign (crate name), a price board with the coin picture, and the chances.
4. **The opening plays in the world:** lift, spin faster and faster, shake, burst, the balloon rises with rays, the camera moves in a little, and nearby players see it.
5. **A preview first** (this one). Gustav checks it before the build.
6. The stall that was started on the start map earlier comes out. The crates go on the islands as above.

## The model (all four)

Preview units are about 1 stud = 0.4 units. In the game, aim for a crate about **8 studs wide and 6.5 studs tall**, on a plinth about 12 x 12 studs. If Gustav's crate is near that size, keep his size.

- **Body:** 4 corner posts, 3 rows of planks on each side, alternating two plank colours, a band across the middle.
- **Gold lock** on the front with a dark keyhole (all four crates).
- **Glowing seam** between body and lid (Neon, theme colour). It pulses softly when idle and gets bright during the spin.
- **Lid** on a hinge at the back edge, so it can swing open. It has studs on top and a gold clasp at the front.
- **Plinth:** a stud base with a ring of studs around the edge, a raised top with gold trim, and a glowing ring on the ground (theme colour).

### Themes

| Crate | Planks | Frame | Band | On the lid / sides |
|---|---|---|---|---|
| Meadow | warm wood, two tones | dark wood | green | grass top with 3 flowers, a red ladybird, a small red balloon tied to the back corner, a vine up the front-left post |
| Cloud | white and pale blue | gold | rainbow stripes | cloud puffs and a spinning gold star on a stick |
| Kite | red and yellow | navy | white | a cyan and yellow kite on a stick with a rainbow bow tail that flutters |
| Storm | dusk purple, two tones | steel grey | (none) | glowing yellow lightning bolts on both sides, rivets on the posts, steel corner caps, a lightning rod with a glowing tip and small zaps around it |

### Stall (behind the crate)

- A counter with a trim strip and dots, two posts, and a tilted striped roof with a hanging valance (two theme colours).
- A sign on the roof with the crate name (Fredoka, white with dark stroke).
- A price board on the counter: the coin picture plus the price.
- Two mini crates (about 30% size) and a small coin pile on the counter.
- Two glowing lanterns hanging from the roof corners.
- **Chances:** show them on a SurfaceGui board on the stall (or on a BillboardGui when the player is close): one row per balloon with the rarity pill (rarity colours from the Index), the name and the percent. The look matches the card bottoms in the preview.

### Island scenery in the preview

Only there to show the mood. **Don't add decoration to Gustav's islands unless he asks.** The crate, plinth and stall are the only new pieces.

## Buying

- Walk up and **hold F** (same as the island reward objects), or press the prompt on phone.
- The server checks coins and the island unlock, takes the coins, rolls the balloon, and tells all clients to play the opening at that crate.
- A duplicate balloon gives **+1 level** (as in the window version).
- One opening at a time per crate is fine; if it is busy, other players wait until it closes (about 6 s).

### Prices and chances (first guesses, keep them in CrateConfig)

| Crate | Price | Chances |
|---|---|---|
| Meadow | 400 | Gumball 40, Bubble 30, Ember 22, Spike 6, Popcorn 2 |
| Cloud | 2,500 | Spike 35, Popcorn 30, Jelly 20, Buzz 10, Frost 5 |
| Kite | 20,000 | Jelly 35, Buzz 30, Frost 20, Volt 10, Thorn 5 |
| Storm | 250,000 | Volt 32, Thorn 28, Clock 25, Flame 12, Iron 3 |

## The opening (timings in seconds)

| Time | What happens | Sound |
|---|---|---|
| 0.00 to 0.45 | Crate lifts 1.5 units (about 4 studs) off the plinth, ease out. Seam glows brighter. | rising whoosh |
| 0.45 to 2.05 | Crate spins faster and faster (2 to 32 rad/s, speeding up with time squared), shakes a little more each moment, tilts slightly, pulses in size by 3%. Seam glows brighter and brighter. | ticks that get faster (every 0.22 s down to 0.05 s) |
| 2.05 | **Burst:** white screen flash, sparks in the rarity colour plus white sparks, confetti, coins flying out, a white shock ring. The crate snaps to face front. | boom |
| 2.05 to 2.50 | Crate drops back onto the plinth with a small bounce. The lid swings open (about 117°) with a back-ease overshoot. | |
| 2.15 to 3.05 | The balloon grows from 15% to full size and rises out of the crate until its knot is just above the crate. Gustav's rays turn behind it in the rarity colour, with a soft glow. Small sparkles drift around it. | |
| 2.31 | Toast: "NEW BALLOON!" (or "+1 LEVEL"), the balloon name in big rarity colour, and a rarity pill. Its row on the chances board lights up. | win jingle (more notes for higher rarity) |
| 5.05 | The balloon floats up and away and shrinks; rays fade. | |
| 5.35 to 5.85 | The lid closes. | lid thump |
| 6.25 | Done. Crate is ready again. | |

**Camera (only for the player who opened it):** moves in about 8% and tilts up a little during the spin and reveal, then goes back. Respect the CAMERA SHAKE setting: no shake when it is off.

**Other players** see the whole show in the world, but no camera move and no toast (or a small one above the crate).

## Fits with the rest of the game

- Balloon models come from `BalloonModels` (the same models as the Balloons window and the Index).
- Rarity colours as in the Index: Common #47a6ff, Uncommon #66d83a, Rare #33d2f0, Epic #b25cff, Legendary #ffb028, Mythic #ff4fc8.
- Square stud UI style for the toast and the chances board; Gustav's coin picture is the only coin.
- Sounds go through SoundConfig; button clicks use the admin kit click.
- Parts never overlap or clip, nothing floats, every part is Anchored.
- The old crate window can stay as a way to see the chances, or be removed. Ask Gustav.
