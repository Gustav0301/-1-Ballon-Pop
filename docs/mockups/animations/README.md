# Character animations: idle, take-off, float

Preview page: `index.html` here (open it in a browser). Gustav approved the plan on 2026-10-09.

## The three animations (all R15)

| Animation | Made by | Length | Loop | Priority | When it plays |
|---|---|---|---|---|---|
| `BalloonIdle` | Claude (`BalloonIdle.lua`) | 4.0 s | yes | Idle | Standing on the ground holding the balloon. Walking uses the normal walk. |
| `BalloonTakeOff` | Claude (`BalloonTakeOff.lua`) | 1.85 s | no | Action | When the player presses Space to take off. The player can't move while it plays. |
| `BalloonGentleGlideandLookAround` | Gustav (Rig Director) | 5.6 s | yes | play as Action | The whole flight, from the end of the take-off until landing or popping. |

Gustav's float animation is `BalloonGentleGlideandLookAround.lua` (his own Rig Director export). Each `.lua` file is a command-bar script in the same format as Rig Director. It creates a KeyframeSequence in ServerStorage. Gustav publishes each one (right-click > Save to Roblox) and gives the animation ids. Put the ids in a config (for example `FlightConfig.Anim = { Idle = ..., TakeOff = ..., Float = ... }`) so they can be swapped without code changes.

## Published ids (from Gustav, 2026-10-09)

| Animation | Id |
|---|---|
| `BalloonIdle` | `rbxassetid://130255973398557` |
| `BalloonTakeOff` | `rbxassetid://74498154196893` |
| `BalloonGentleGlideandLookAround` (float) | not given yet: use the KeyframeSequence in Studio until it comes |

## Testing in Studio before the ids exist

Until Gustav publishes the three animations, run the three `.lua` files to make the KeyframeSequences and play them with `KeyframeSequenceProvider:RegisterKeyframeSequence(seq)` (this only works in Studio). Keep the KeyframeSequences in ServerStorage.Animations and have the code use the published ids from the config when they are set, and fall back to the registered sequences in Studio when they aren't.

## Take-off markers (the game listens with `track:GetMarkerReachedSignal`)

| Time | Marker | What the game does |
|---|---|---|
| 0.00 | (track starts) | Tween the balloon from its string position down to the player's mouth over 0.22 s (knot at the mouth, balloon tilted forward and up). Lock movement. |
| 0.22 | `Grab` | Balloon is at the mouth. Small grab sound. |
| 0.48 | `Puff` "1" | Balloon grows one step (with a quick squash-and-stretch wobble). Puff sound, little white cloud from the mouth, ring of air bits around the balloon, "PUFF 1!" pop text. |
| 0.76 | `Puff` "2" | Same, a bit bigger. |
| 1.06 | `Puff` "3" | Same, the biggest step. |
| 1.26 | `Release` | Let the balloon go: it shoots up on its string to the normal flight position and grows to flight size. |
| 1.60 | `LiftOff` | Send the existing `Launch` intent (the flight starts here, the server is unchanged). Dust ring of stud bits at the feet, whoosh sound, "LIFT OFF!" text. |
| 1.85 | (end) | Crossfade 0.35 s into the float animation, which loops for the whole flight. |

Sizes used in the preview: ground balloon 0.30 scale, puffs 0.34 / 0.39 / 0.44, flight 0.52. In game, use the balloon's own visual scale for the last step.

## Rules

- The take-off ends exactly on the float animation's first pose, so the hand-over has no jump.
- Stop the float animation when landing, banking or popping, and go back to the idle on the ground.
- Use the game's existing sounds from `SoundConfig` where one fits. The preview sounds are only stand-ins.
- Don't press Play in Studio while Gustav is working unless he says it's OK.
