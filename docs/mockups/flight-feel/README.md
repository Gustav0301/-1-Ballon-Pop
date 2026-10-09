# Flight feel + Air Dash (preview, 2026-10-09)

Preview page: `index.html` here (open it in a browser). It has NEW and OLD buttons to compare.
Gustav's picks: dash on **Shift** plus a phone button, cost **6% of size**, all four flying effects together, a bigger landing and a bigger pop, at the "1000x cooler" quality level.

## Air Dash
- Key: Shift (Q is the ability, Space lets air out, E lands). On phones, a round blue button next to the Q button.
- Cost: 6% of the balloon size, at least 2. You can't dash below size 6.
- Movement: 0.07 s squeeze (slow down), then a 0.35 s burst. Speed = max(190 × (1 − u)², 0.9 × top speed), where u goes 0 → 1 over the burst. That is about 24 studs. After the burst you keep going at top speed in the dash direction.
- Direction: your steering input, else your current movement, else the camera's forward direction (flat).
- You sink for 0.9 s afterwards (the vertical speed moves towards −6), then you float back up.
- Wait: 2 s. The button shows a dark sweep and a number, then gleams with a "ready" ding.
- Server: the client asks for the dash. The server checks the flight state, the wait and the size, takes the size, and moves the character. The client plays the effects.
- Effects: the balloon squashes (Y −28%, XZ +18%) during the squeeze. Then a white air puff blows out of the back of the balloon, a ring of air appears around the player (facing between the dash direction and the camera), and wind streaks show. FOV kicks +7. The camera lags for 0.45 s. The knees tuck and the body pitches forward. The balloon wobbles back on a spring. "-3 SIZE" floats up, and the SIZE pill shakes.
- A bird that passes within 1.6 s after a dash shows "NICE DODGE!" (yellow). Any other near miss shows "CLOSE!" (cyan).

## Flying (all four together)
- Steering: Accel 30 → 42, Drag 0.7 → 1.1, MaxSpeed 22 → 24, and input against your movement is ×1.8 (snappy turn-around).
- Body: it faces the way you move, banks into turns (lateral acceleration × 0.016, up to 26°) and pitches forward with speed (up to 17°). These use springs with a little overshoot. Legs trail back with speed and swing. The free arm drifts back.
- Balloon: it is stretched along its velocity (up to 30%). Every +1 gives a small bump and a "+1" text. It is spring-trailed behind you (k 22, c 5), always stays above the hand, and pulls harder during a dash.
- Rope: a bending rope with 10 segments (Verlet) instead of a straight line. In Studio, a few small parts on a RopeConstraint, or a Beam with CurveSize, is enough.
- Wind: white streaks spawn when your speed is over 11 (more at higher speed), plus a wind loop sound that gets louder with speed. FOV goes up to +5 with speed.

## Landing
- Dive: 0.75 s with a small hop at the start. The vertical move eases in (k³), so you slam down. The hero landing animation starts 0.26 s before touchdown (the same as now).
- Touchdown: 0.1 s freeze, then 0.3 s slow motion at 30% speed and a camera shake of 0.42. Two shock rings (cream and dirt), a dust puff, and 24 grass, dirt and gold studs that bounce on the ground. 22 coins fly into the coin counter, which counts up as each coin arrives. "LANDED! +N".
- Use the game's existing touchdown sound and add a low boom and a debris rattle.

## Pop
- 0.1 s freeze, then a camera shake of 0.5. 28 flat rubber pieces in the balloon's own top 3 colours fly out, spin and fall. There is a white ring and a puff, and a big "POP!".
- The rope goes loose and hangs and flutters from the hand.
- You flail while falling: arms waving, legs kicking, the body wobbling, with a whoosh sound three times a second. Lost coins show in red ("-58 coins").

Everything that can be tuned goes into `FlightConfig` (Dash, Drift, Feel, Land, Pop tables) so Gustav can change it.
