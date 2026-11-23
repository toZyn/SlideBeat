# SlideBeat

A rhythm game inspired by Osu! — hold and slide your cursor/finger to the beat.

Hold the center, slide toward the highlighted arrow as its approach ring closes, then return to the center while still holding. Every flick needs a fresh return to the center. Releasing is allowed; start again at the center. Wrong directions and expired notes break your combo.

## Play

Run `npm start`, then open http://localhost:3000. Any static host works, including GitHub Pages. No installation or build step is required. Use a modern browser with Web Audio and Pointer Events.

- Flow: 100 BPM, 64 notes.
- Pulse: 128 BPM, 64 notes.
- Rush: 150 BPM, 128 notes with half-beat flicks.

Music is synthesized locally with the Web Audio clock. The same clock controls note judgments. Pause freezes both; hiding the tab pauses automatically. Touch input uses pointer capture and disables page gestures only inside the playfield. Best scores are saved locally when browser storage is available.

Perfect hits award 300 points, good hits 150, plus a combo bonus. Accuracy weights perfect hits at 100%, good hits at 65%, and misses at 0%.

## Development

`npm test` runs chart, timing and direction checks. The app uses native browser modules and has no runtime dependencies. Artwork and synth loops were created for this implementation; no assets from Light-Engine were copied and that repository was not modified.
