# SlideBeat

A rhythm game built from scratch for LÖVE 11.5. Hold and slide your cursor or finger to the beat.

## Play

[Download SlideBeat.love](https://github.com/toZyn/SlideBeat/raw/refs/heads/main/dist/SlideBeat.love)

Install LÖVE 11.5, then run `love .` in this directory, or open `SlideBeat.love` with LÖVE. On Android, open the package with the LÖVE Android app. No network access or additional libraries are needed.

1. Choose Pulse (quarter notes), Flow (eighth notes), or Flick (sixteenth notes).
2. Press and hold the center circle using the left mouse button or one finger.
3. Slide toward the highlighted arrow when its approach circle reaches the target.
4. Return to the center while continuing to hold, then slide again. You may release and press the center again.

The preview row shows the next six directions. Only one pointer controls the game; extra fingers and touch-generated mouse events are ignored. A stroke triggers once until the pointer returns to the center. Starting a drag outside the center does not arm a stroke.

Space starts a track or pauses/resumes it. Escape pauses/resumes gameplay. Use the pause menu to restart or return to the menu. Losing window focus pauses automatically.

## Timing and score

The original 120 BPM track runs for 46 seconds with an eight-beat lead-in. Notes start at 4 seconds; results appear at 45 seconds. Gameplay follows the audio playback clock. The approach circle and score use the same clock.

Perfect: within 65 ms, 1000 points. Good: within 120 ms, 700 points. Other hits within 180 ms: 400 points. Wrong directions or expired notes break the combo. Accuracy is the weighted score divided by all judged notes. Early strokes outside the hit window do not consume a note.

Settings provide volume and timing offset from -300 to +300 ms. A positive offset moves the expected gesture later than the audible beat. Settings and personal best scores are stored in LÖVE's application save directory.

## Project

- `main.lua`: screens, rendering, audio, mouse and touch input.
- `rhythm.lua`: charts and timing/scoring logic without LÖVE dependencies.
- `conf.lua`: LÖVE configuration.
- `assets/pulse.ogg`: original synthesized music.
- `tests/rhythm.lua`: deterministic scoring and chart checks.
- `tests/input.lua`: input and screen integration checks using a simulated LÖVE API.

Run checks with `lua tests/rhythm.lua` and `lua tests/input.lua` (Lua 5.1+); `texlua` is also supported. Package with `zip -r SlideBeat.love main.lua conf.lua rhythm.lua assets` from this folder.

All visuals are drawn with LÖVE primitives, so they remain sharp when resized. No textures or code were copied from Light-Engine, and that repository was not modified. The previous SlideBeat implementation was removed without reading it. Git history is retained.

Desktop logic checks do not replace testing touch latency, audio latency and lifecycle behavior on physical Android devices.
