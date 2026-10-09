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

## Round 2: ten extras (Gustav said yes to all ten, 2026-10-09 22:36: "1000% effort, detail, 1000x cooler")
1. **Bird warnings:** every bird that hunts you (within 80 studs and coming closer) gets a round red "!" bubble above it. The bubble is studded, has a thick dark outline and pulses. If the bird is off screen, the bubble sits at the screen edge with an arrow pointing at the bird. The colour goes yellow (far) → orange → red (close), and the pulse gets faster and the bubble bigger as it closes in. A two-tone warning beep plays when a bird starts hunting you. Put it in the HUD template as a BillboardGui or ScreenGui pool so Gustav can restyle it.
2. **Dodge streak:** every "NICE DODGE!" (a bird passes within 1.6 s after a dash) or "CLOSE!" (a bird misses by 7 studs or less) adds 1 to the streak. The bonus is 10 × streak coins, added to the coins at risk (you still have to land to keep them). The text reads "NICE DODGE! x3  +30". An orange "DODGE x3" pill appears under the HUD pills and bumps each time, and a chime plays that goes up a note per streak step. Landing or popping resets the streak, and a pop with a streak above 1 shows "STREAK LOST" in red. The server decides the near misses and pays the bonus (it already knows where the hazards and the balloon are).
3. **Dash ghosts:** 3 afterimages of the character and the balloon, at 0.02, 0.085 and 0.15 s into the burst. Each is a single light-cyan colour (C6F1FF) with no glow, starts at 55% visible and fades out over 0.38 s. They write depth, so they look like clean silhouettes and not see-through mush. Client-only.
4. **Studded landing glow:** while you are in the landing window over an island (the same check as the existing landing), the gold pad glows (pulsing). The 24 gold studs around the pad's rim hop up in a running wave and glow, a chunky studded gold arrow with a dark outline bobs 12 studs above the pad and faces the camera, and a gold "LAND! [E]" chip in stud-button style floats above the arrow. Entering the window plays a two-note ding. Client-only. Each island needs a rim-stud ring (or the code builds it around the LandingPad). On mobile, the chip shows the LAND button instead of E.
5. **Pop flash:** when you get hit, the balloon turns pure white and swells +16% for 0.1 s (with a short high "tink"), then the existing pop plays (freeze, rubber pieces and so on).
6. **Height pops:** a purple "HEIGHT 212 m" pill always shows. Every 50 m on the way up (each step only once per flight), a big "250 m!" banner slides in on the right (stud text, white to purple), a 4-note chime plays that goes up a note each step, and a purple ring and sparkles burst around you.
7. **Big vs small landing:** the full landing (freeze, slow motion, big rings, 24 bouncing studs, 22 coins) happens only when you bank 200+ coins or land on an island for the first time. Otherwise there is a quick, light landing: no freeze or slow motion, a light shake of 0.16, one ring, 10 studs, 10 coins and a "+N" text. The slow motion slows only your own screen (camera, your character and your effects), never the server or other players.
8. **Less shake:** a setting that turns off the camera shake and the FOV kicks. It goes in the new stud-style settings menu (sound, music, shake) that comes next.
9. **Soft +1:** every second there is only a small balloon bump (6%) and a very quiet tick, with no "+1" text.
10. **TOO SMALL:** below size 6 the dash button turns grey and its centre reads "TOO SMALL". Pressing it plays a short "no" buzz and shakes the button.

Also new in the preview: a **Climb** demo, and a land demo that shows a small landing and then a big one.

Everything that can be tuned goes into `FlightConfig` (Dash, Drift, Feel, Land, Pop tables) so Gustav can change it.
