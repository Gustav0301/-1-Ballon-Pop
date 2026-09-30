# Start map: Balloon Festival

The grass start map from `reference/start-map-festival.webp`, built entirely from classic stud Parts (about 4,800 anchored parts, no scripts, no uploaded assets).

![Overview](map/overview.png)

| | |
|---|---|
| ![Shop](map/shop-front.png) | ![Index](map/index-front.png) |
| ![Upgrades](map/upgrades-front.png) | ![Arch](map/arch.png) |

*Previews come from the generator's own renderer, not Studio.*

## What's on it

- **Launch plaza** (centre, the origin): three stepped tiers with yellow rims, a blue sun-star mosaic, a cyan target where the **SpawnLocation** sits, stairs on all four sides, and eight lamp posts strung with bunting.
- **Shop** (west): red-and-white striped building under a giant checkered gumball dome. It has a block-letter SHOP sign, a striped awning, three display pedestals (Gumball, Volt, Sun), a restock clock board, crates and lanterns.
- **Index hall** (east): blue hall with a stepped blue-and-white roof, an INDEX sign, and four arched display bays (Gumball, a rainbow Gumball, Frost, Void).
- **Upgrades workshop** (north-east): plank walls, a blue gable roof, an UPGRADES sign with a gear, a workbench with tools and an anvil, and the giant red balloon pump with its gauge and hose.
- **Golden coin arch** (north, decoration for now): a raised terrace with a grand staircase, stone cliff face, fences and coin piles. The arch has lanterns and a giant gold coin on top.
- **River** (south): studded water with stone banks, lily pads and rocks, a wooden bridge on the main path and a small bridge to the west.
- **Scenery:** blocky trees, pines on the back and side hills, flowers, confetti studs on the grass, a picnic table, a signpost and a treasure chest.
- **GalleryAnchor** (south-east field): an invisible part where the demo balloon gallery lays out its two rows.

## Install

1. In your place, **delete the default `Baseplate` and `SpawnLocation`**. The map has its own ground (top at y = 0, matching `HazardConfig.GroundY`) and its own spawn, and the river trench would fill with baseplate otherwise.
2. Drag `build/StartMap.rbxmx` into Studio (or Model tab → Model → Insert from file). It lands as a `StartMap` Model with one sub-model per area (Plaza, Shop, Index, Upgrades, Arch, River, Trees, ...).
3. Everything is anchored plain Parts, so you can move, recolour or delete anything by hand afterwards.

To regenerate after changing the generator: `python3 tools/map/build_start_map.py --preview` (the previews need numpy + pillow).

## Next

Sky islands for Meadow Sky and Cloud Shelf, in the style of `reference/sky-islands.webp`. The two floating islands in the festival picture are where they'll hang.
