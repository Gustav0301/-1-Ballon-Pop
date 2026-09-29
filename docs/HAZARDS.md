# Hazards: Meadow Sky + Cloud Shelf

The first four enemies of **1+ Ballon Pop** (Phase 1: Float). Each one hunts the balloon you're holding, has one signature attack lit in its own color, and is built from stud Parts with cube particles (game prompt, section 14).

Concept boards with animated attack loops: https://claude.ai/artifact/Gm3oj1oxrdM2QMzJXzEvoM

| Hazard | Zone | Attack | Color | Dmg | Lock → Hit | Hit shape | Cooldown |
|---|---|---|---|---|---|---|---|
| Sparrow | Meadow Sky (20–500) | Corkscrew Dive | `#FFD21F` | 1 | 0.70 → 1.00s | point, r 4 | 4s |
| Plane | Meadow Sky (150–500) | Crease Cutter | `#7CFF3A` | 1 | 0.90 → 1.20s | line, r 3.5 | 5s |
| Pinwheel | Cloud Shelf (500–1,500) | Saw Bloom | `#FF3FD0` | 1 | 1.10 → 1.45s | point, r 5 | 6s |
| Nimbo | Cloud Shelf (800–1,500) | Pin Drizzle | `#38C8FF` | 2 | 0.80 → 1.60s | column, r 8 | 7s |

Every number lives in `src/shared/Config/HazardConfig.lua`. Damage is the base value. FlightService applies fragility (`damage × (1 + size / 200)`) when it receives the hit.

## How it works

- **Server authoritative** (`src/server/Services/HazardService.lua`). Each hazard is an invisible anchored root Part in `workspace.Hazards`. The server moves it, starts attacks, locks the aim point at `LockTime`, and checks hits at `HitTime` against every flying balloon. Bigger balloons are easier to hit (`HitRadius + balloonRadius × 0.6`). There is no client-to-server remote.
- **Client visuals** (`src/client/Controllers/HazardFXController.lua` + `src/shared/Hazards/`). Clients build the stud model for each root and animate it at 60 fps with `BulkMoveTo`. They play the attack from the server's `Begin`/`Lock`/`Hit` messages, synced with `workspace:GetServerTimeNow()`.
- **VFX without any uploaded assets** (`src/shared/Hazards/VFX.lua`). Everything uses Neon/Plastic Parts, Trails, PointLights, one sparkle ParticleEmitter on the engine's built-in texture, and a ColorCorrection tint. Particles are real cube and plate Parts from a pool, so the package imports into any place 1:1.
- **Counterplay**. The aim locks before the hit, so steering or letting out air after the lock dodges the attack. `HazardService.Swat(player, hazardId)` is ready for RiderService: a swat before the hit cancels the attack and knocks the hazard away.

## Install

**Rojo (recommended):** `rojo serve` with `default.project.json`. The layout matches section 17 of the game prompt: `ReplicatedStorage/Shared/Config/HazardConfig`, `ServerScriptService/Services/HazardService`, `StarterPlayerScripts/Controllers/HazardFXController`.

**Drag and drop:** drag `build/HazardPack.rbxmx` into Studio and press Play. On Play it moves itself into ReplicatedStorage and ServerScriptService and starts in demo mode. Rebuild it after code changes with `python3 tools/build_rbxmx.py`.

## Demo mode

`Demo = true` in `src/server/HazardBootstrap.server.lua` (and `DEMO` in the pack's Start script) gives every player a stud balloon over their head (HP = its Toughness) and builds the balloon gallery by the spawn, where **Try it** swaps balloons. It cycles Sparrow → Plane → Pinwheel → Nimbo around them at any height. At 0 HP the balloon pops into brick confetti and reinflates after 3 s.

## Hooking up FlightService (milestone M1)

```lua
local Target = require(ReplicatedStorage.Shared.Hazards.Target)
Target.Resolver = function(player) -- return balloon position and radius
	return FlightService.GetBalloonPosition(player)
end

HazardService.IsFlying = function(player)
	return FlightService.IsFlying(player)
end

HazardService.Hit.Event:Connect(function(player, damage, kind, hazardId)
	FlightService.DamageBalloon(player, damage) -- fragility, HP, pop, fall
end)
```

`Target.Resolver` must be set on the client as well: its default finds a Model or Part named `Balloon` in the character, or at `workspace.Balloons[player.Name]`. Then set `Demo = false`.

## Adding a hazard

1. Add an entry to `HazardConfig.Types` (zone heights, timings, colors).
2. Add `src/shared/Hazards/Visuals/<Name>.lua` with `Build(cfg)`, `Reset(rig)`, `Animate(rig, dt)` and `Attack(rig, ctx)`. Copy the closest existing one.
3. Use `ctx:WaitUntil(t)`, `ctx:WaitLock()`, `ctx:Target()` and `ctx:Add(item)` so the attack stays in sync and cleans up after a swat.
