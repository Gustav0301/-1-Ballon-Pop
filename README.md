# 1+ Ballon Pop

Roblox game (Luau, Rojo). Hold a balloon that grows +1 size every second, float up past the sky islands, bank before something pops you.

- `docs/GAME_PROMPT.md` - the full game design prompt (v3.5)
- `docs/BALLOONS.md` - all 18 stud balloon models, the Lift height formula, demo gallery
- `docs/UI_STYLE.md` - the shop-GUI style every menu follows
- `docs/HAZARDS.md` - the first-island hazards (Sparrow, Plane, Pinwheel, Nimbo): design, install, FlightService hookup
- `default.project.json` - Rojo project (layout follows section 17 of the prompt)
- `docs/MAP.md` - the Balloon Festival start map (`build/StartMap.rbxmx`)
- `docs/FLIGHT.md` - flying (drifty steering), landing, saving (ProfileStore) and the HUD
- `docs/HUD_EDITING.md` - install the HUD in StarterGui and restyle it in Studio
- `docs/MENU_EDITING.md` - Balloon Shop (restocking), Upgrades, My Balloons, the top bar, and editing them
- `docs/SOUNDS.md` - the generated sound pack (`sounds/`), uploading, music sources
- `build/GamePack.rbxmx` - drag-and-drop package with the whole game code: flying, saves, HUD, hazards, balloons (rebuild with `python3 tools/build_rbxmx.py`)
