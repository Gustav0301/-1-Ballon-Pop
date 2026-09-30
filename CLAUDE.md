# 1+ Ballon Pop: project memory

Roblox game by Gustav. You hold a stud balloon that grows every second and lifts you, you earn coins while you fly, and you land on a sky island to bank them before hazards pop you. The full design is in `docs/GAME_PROMPT.md` (v3.5). Read it before designing anything new.

## The three most important rules

1. **Ask questions BEFORE building.** Before starting anything new (a feature, a model, a map piece, a menu), ask Gustav about the choices that are his to make. Give your recommendation with each question, and number the questions so he can answer them one by one. Only then build. If something comes up halfway, ask rather than guess. Small technical details you can decide yourself; tell him what you chose.
2. **Everything connects.** The game is one whole, not separate features. Every new piece has to fit what's already there:
   - The same look: stud style, the same UIKit pieces, colours and fonts.
   - The same systems: flight states, DataService saves, the server-authoritative remotes, SoundConfig sounds, the toasts.
   - The same rules: `GAME_PROMPT.md` and the decisions below.

   Before building, look at how the existing parts do it and reuse or extend them. After building, hook the new thing into the rest: sounds, the HUD, saving, the docs, `CLAUDE.md`, and `build/GamePack.rbxmx`. When one thing changes, update everything that depends on it. A shop balloon should look like the flying balloon and the gallery balloon, and a new window should look like the Shop window.
3. **High detail and high quality, never "AI slop".** Use detailed stud and voxel models with real shapes, not blobs. Polish the UI: gloss, outlines, stripes, pop-in animations, sounds. Motion should feel good. Check your own work before handing it over:
   - Render previews of models and the map.
   - Build HTML mock-ups of UI at the real sizes and screenshot them in headless Chromium (see `docs/hud/`, `docs/menu/`).
   - Look at spectrograms of sounds.
   - Type-check the code.

   Fix what you find, then deliver. If something can't be verified here (it needs Studio), say so plainly.

## Working with Gustav

- **Our style:** stud / voxel art, and the Shop GUI style in `docs/UI_STYLE.md`: red panels, thick dark outline, diagonal stripes, Fredoka One white text with a dark stroke, and chunky buttons with a lip. Reference pictures are in `docs/reference/`.
- He tests in **Roblox Studio on his own PC**. Cloud sessions can't see Studio, so verify through his screenshots and Output errors.
- He installs by **dragging `build/*.rbxmx` into Studio**. After code changes, rebuild `build/GamePack.rbxmx` (`python3 tools/build_rbxmx.py`) and send it to him.
- Anything he should be able to restyle lives in **editable UI templates in StarterGui** (`HUDTemplate` / `MenuTemplate` `Install()`), and the code finds pieces **by name**.
- **Don't set up automatic PR check-ins, scheduled triggers or anything else that runs by itself** unless he asks. He turned them off because they used too much of his usage.
- Keep replies short and plain. He isn't a native English speaker.

## Where things are

- Rojo layout (`default.project.json`): `src/shared` → ReplicatedStorage.Shared, `src/server` → ServerScriptService, `src/client` → StarterPlayerScripts.
- The drag-in `build/GamePack.rbxmx` holds the same files. On Play it moves itself to ReplicatedStorage.GameShared, ServerScriptService.GameServer and ReplicatedStorage.GameClient.
- Server: `ServerMain` starts WorldLook, `DataService` (ProfileStore, vendored in `src/server/Packages`), `HazardService`, `FlightService`, and `BalloonService` (with `ShopService`).
- Client: `ClientMain` starts `HazardFXController`, `FlightController`, `SoundController`, `HUDController` and `MenuController`.
- Config (`src/shared/Config`): `BalloonConfig` (18 balloons, height formula, `StatsFor`), `FlightConfig`, `HazardConfig`, `IslandConfig` (generated), `ShopConfig`, `SoundConfig` (Gustav's uploaded sound ids are in here).
- UI: `src/shared/UI/UIKit.lua` (building blocks), `HUDTemplate.lua`, `MenuTemplate.lua`.
- Map and model generators (Python): `tools/map/build_start_map.py` → `build/StartMap.rbxmx`, `tools/map/build_sky_islands.py` → `build/SkyIslands.rbxmx` + `IslandConfig.lua`, `tools/balloons/build_balloons.py` → `BalloonModels.lua`, `tools/sounds/make_sounds.py` → `sounds/*.ogg`.
- Docs: `docs/FLIGHT.md`, `HUD_EDITING.md`, `MENU_EDITING.md`, `SOUNDS.md`, `HAZARDS.md`, `BALLOONS.md`, `MAP.md`, `UI_STYLE.md`.

## Decisions made together (don't re-ask)

- **Height:** `40 × size^0.6 × Lift` above where you took off, capped at the zone ceiling (1,500 in Phase 1).
- **Premium bundles:** option b, truly stronger (pay-to-win). Not built yet.
- **Map:** the golden arch is decoration only. Invisible walls stand at the mountain border. Everything from his reference picture is on the start map. There are two zones for now (Meadow Sky 0–500, Cloud Shelf 500–1,500) with four islands.
- **Flying:** drifty steering with momentum, wind, lean and a trailing balloon.
  - Space lets out air: you drop at 30 studs/s, lose 5% size per second, and float back up when you let go.
  - Hold E to land. The landing window is up to 45 studs above an island.
  - The start map also counts as a landing zone once you're low.
- **First landing is easy:** 0.6 s, a bigger zone (70 studs above), x2 coins, and 12 s of hazard grace.
- **Saving:** ProfileStore, schema v1 from the prompt plus `tutorial.landed`. Flight state is never saved, so leaving mid-flight counts as a pop.
- **Popped balloons stay** in the inventory.
- **Shop:**
  - Server-wide restock every 5 minutes; each player gets their own quantity of each balloon.
  - All 17 balloons are sold. Cluck is the secret one and isn't sold.
  - Upgrades follow prompt section 3.4.
- **Top bar:** Grow a Garden style studded buttons (BALLOONS / SHOP / SPAWN / UPGRADES) that teleport you.
- **Sounds:** 20 synthesised sound effects that Gustav uploaded. The music is one track for now.

## Before publishing

- Set `ShopConfig.StudioEverything` to false, or leave it: it only applies in Studio. `/coins` also only works in Studio.
- Hazard demo mode is off. The balloon gallery "Try it" only runs in Studio.

## Status and next steps

- M1 (flying, bank, pop, save) and most of M2 (shop, upgrades, inventory) are done and waiting for Gustav's testing.
- Ideas raised but not built yet:
  - The sky changing look as you climb.
  - Confetti coin drops on a pop.
  - Riders.
  - Mutations (M4).
  - Premium bundles.
  - The first pop dropping you gently onto an island (tutorial).
  - The "Index" as its own book (the Index stall opens My Balloons for now).
- All work so far is on branch `claude/inspiring-babbage-w5gtkw` (PR #1). Merge it to `main` so new chats start with everything.

## Checking code (cloud session)

There's no Studio here, so check code with luau-lsp (Roblox definitions and a generated sourcemap) and `luau-compile`. Install them in the scratchpad if they're missing. `.lua` and `.luau` files both count.
