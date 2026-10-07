# Island reward objects: 3D preview v2 ("1000x cooler")

Gustav approved this look on 2026-10-07: "the new models always remember to make it this 1000x cooler".

- Pictures: `preview.png` (all six objects) and `preview-use.png` (the moment after USE, with the pop-ups).
- Live page: https://claude.ai/artifact/VWTFoutaD6Dp6riBvSqytF. Opening `index.html` here in a browser gives the same page, and you can drag to turn each object.
- `index.html` holds every object's exact shape. Each section from `// 1. BEEHIVE` to `// 6. GUMBALL MACHINE` builds its object from boxes, cylinders and balls, with positions and colours. Build them in Studio from these.

These are **different designs** from the stand-ins now in Workspace.IslandRewards (wind spinner, paint bucket, pillows, three-bowl fountain, candy machine). They replace those stand-ins. Before swapping, move the old ones to ServerStorage.OldShopImports.

## Building them in Studio

- **Scale:** 1 preview unit = 2 studs, so each object is about 12 to 20 studs tall.
- **Parts only:** Block, Cylinder, Ball and Wedge, with the Studs surface on top faces. Where a texture is used, use the stud texture rbxassetid://6927295847. No meshes or unions.
- **Build rules:**
  - Nothing floats and nothing sinks.
  - No two parts share a face or overlap.
  - Moving parts keep space all the way round while they move.
- **Placement:**
  - On the island path, 15 to 30 studs from the gold landing pad, facing the pad. Never on the pad.
  - Keep the names and the hold-F reward system the game uses now.
- **Glow:** the wheel bulbs, the lanterns and the gold rims use Neon or a PointLight, so they glow like in the preview.

## The five to build

Flower Patch already has Gustav's own beehive, so it isn't on this list.

| Island | Object | What makes it look like the preview |
|---|---|---|
| Windmill Hill | Spin Wheel | A wooden A-frame stand on a stepped brick base. The wheel has 8 coloured segments: 500, x2, 1K, GROW, 250, NEON, 2K and AGAIN. Each segment is one flat face with a SurfaceGui label, so nothing flickers. A thick gold rim with 16 bulbs that chase while it spins, and a gold hub with a red ball. A red pointer flapper on a gold bracket at the top ticks against white pegs. A "SPIN!" sign on top, and lanterns on both sides. |
| Rainbow Shelf | Rainbow Pool | A round pool with a stepped rim in 6 rainbow colours. A full rainbow arch of blocks over it, with no gaps. Clear, glossy water, and a balloon on a string floating over the water. Pastel cloud ground, candy-coloured blocks around the rim, and a "RAINBOW POOL" sign. |
| Cotton Castle | Wishing Well | A grey-lilac well of two-tone stones with clear water inside. Two wooden posts and a stepped pink-and-white roof with a little ball on top. The axle goes through both posts, and the **crank sits outside the right post** so it never goes through it. A rope and a wooden bucket with metal bands. A "MAKE A WISH" sign and coins around the base. |
| Summit Cloud | Gold Fountain | Three gold tiers that get smaller as they go up, each with a basin and water. A big gold ball spout on top with sparkles. A wide basin with piles of gold coins and gold blocks around it, a "GOLD FOUNTAIN" sign and lanterns. |
| Candy Cloud | Gumball Machine | A red octagon body with flat faces. On the front faces: a silver coin-slot plate, a silver chute with a gold tray, and a **silver crank on its own hub plate, with the handle in front and space around it**. Red ball knobs. A silver collar and a big clear glass globe (Transparency 0.6 to 0.7). The globe is full of gumballs in 9 colours that touch each other and the bottom and never poke through the glass. A red cap with a gold ball on top. Lollipops and big gumballs around it, and a "CANDY" sign. |

## Use animations

These play in game when the player holds F.

- **Spin Wheel:** spins for about 3.5 s and slows down while the flapper ticks. It stops exactly on the prize segment, with confetti and a pop-up like "+1,000 COINS".
- **Rainbow Pool:** the balloon dips into the water and comes up rainbow, with "RAINBOW!".
- **Wishing Well:** a coin flies in, then the bucket goes down and back up, with "MYSTERY PRIZE!".
- **Gold Fountain:** the balloon goes down into the top tier and comes out gold, with "GOLD BALLOON!".
- **Gumball Machine:** the crank turns twice and a gumball rolls out of the chute, with "SUGAR RUSH!".
