# SlideBeat

Hold the center. Slide to the beat. A complete desktop and touch rhythm game built in **LÖVE 11.5**, using real textures from **toZyn/Light-Engine**.

## Run

Open `dist/SlideBeat.love` with LÖVE 11.5, or run `love .` from the repository root. On Android, open the same `.love` package with the LÖVE Android application. The game runs offline and needs no Lua libraries beyond LÖVE.

[Download SlideBeat.love](https://github.com/toZyn/SlideBeat/raw/refs/heads/main/dist/SlideBeat.love)

## Included

- Title screen and main menu.
- Music selection with previews, song descriptions and personal bests.
- Four original complete songs, each with Easy, Normal and Hard charts.
- Interactive tutorial and practice mode.
- Light-Engine textures for arrows, backgrounds, countdown, judgements, health bar and icons; its font and menu sounds are also used.
- Audio-based judgement, approach rings, upcoming-note previews, combo, accuracy, life and progress.
- Pause, resume countdown, restart, difficulty change, failure and retry.
- Results with rank, timing distribution, full-combo status and personal records.
- Saved audio/display/gameplay settings and tap calibration.
- Mouse and single-finger input, keyboard menu navigation, wheel selection and responsive layouts with safe-area handling.

## How to play

Press the mouse button or touch **inside the center**. Keep holding and slide toward the bright arrow when its approach ring reaches the target. Return through the center before the next stroke. You may release and press the center again. Starting outside the center does not arm a stroke.

An outward stroke triggers once. Passing through the center rearms it, including fast movements whose sampled endpoints are on opposite sides of the center. Additional fingers and synthetic touch-to-mouse events cannot score duplicate hits.

Perfect: ±55 ms, 1000 points. Good: ±105 ms, 700 points. Other accepted hits: ±160 ms, 400 points. Wrong directions and expired notes break combo and lower life. Empty life fails the track. Practice continues without failing and never writes records. Striking far outside the timing window does not consume a note. When windows overlap, the nearest pending note takes priority.

## Songs

| Song | BPM | Length | Focus |
|---|---:|---:|---|
| First Steps | 80 | 0:48 | Center return and deliberate strokes |
| Neon Circuit | 120 | 1:20 | Alternation and syncopation |
| Moonlit | 98 | 1:28 | Space, rests and flowing phrases |
| Redline | 160 | 1:12 | Rapid bursts and direction changes |

The original music and 12 charts are included as files. `tools/build_content.py` reproducibly builds this content using Python, NumPy and ffmpeg. These tools are development dependencies only; players do not need them.

## Controls

| Screen | Controls |
|---|---|
| Menus | Up/Down or Tab to focus; Enter/Space to activate; click/tap buttons |
| Music | Up/Down or wheel: song; Left/Right: difficulty; P: practice; Enter: play |
| Settings | Up/Down: setting; Left/Right: value; click/tap -/+ |
| Gameplay | Hold and slide with mouse or one finger; Space/P/Escape: pause |
| Pause | Buttons or menu keys; R: restart; Escape: resume |
| Other screens | Escape / Android Back: return |
| Desktop | F11: fullscreen |

Losing focus, hiding the window or resizing during play pauses the track and releases the active gesture. Audio is frozen during pause. Resume provides a one-second preparation countdown.

## Settings and records

Music and sound volume, timing offset, background dim, playfield size, animations and hit sounds are saved in LÖVE's `slidebeat-v2` application directory. A positive timing offset moves the expected gesture later than the audible beat. Tap calibration uses repeated rhythmic taps; manual adjustment remains available in 10 ms steps. Use the same output device and headphones you intend to play with.

Scores are separate for each song and difficulty. Only completed non-practice runs are saved. The previous profile is backed up before writing a new one, and write failures appear in the UI.

## Add songs

Create a folder `songs/my-song/` in the source tree or in LÖVE's application save directory. Restart the game after adding content. No executable scripts are loaded from song packs.

Required files:

- `music.ogg`
- `meta.txt`
- `easy.txt`, `normal.txt`, `hard.txt`

Example `meta.txt`:

```text
title=My Song
artist=Artist Name
bpm=120
duration=60
color=90 190 255
icon=bf
description=A short description.
order=10
preview=8
```

Each chart line is a timestamp in seconds and a direction: `1` up, `2` down, `3` left, `4` right. Timestamps must be strictly increasing and end at least 0.2 seconds before the audio duration. `duration` must match the actual music length. A short lead-in and a tail of at least two beats are recommended.

```text
2.000000 1
2.500000 4
3.000000 2
3.500000 3
```

Bad metadata is skipped during discovery. Missing or invalid charts display an error screen with a path back to the menu.

## Structure and reference

`core/` owns assets, UI, navigation, discovery, scoring, gestures and persistence. `screens/` owns the separate screens. `songs/` contains actual audio, metadata and charts. `assets/light/` contains copied Light-Engine resources, hashes and original licensing notices. `docs/light-engine-study.md` records the source files studied and how the findings informed this implementation.

The original SlideBeat implementation was deleted without reading it. Light-Engine was only inspected and used as the requested reference/resource source. Its repository was not modified.

## Verify and package

```sh
lua tests/core.lua
love . --test
python3 tools/package.py
```

The first command checks all 12 charts, scoring, life, practice, gesture rearming, invalid charts and profile round-trips. `--test` drives the real LÖVE screens and gesture callbacks through tutorial, failure, pause/resume and complete hard-chart runs, saving screenshots in the application's `test-captures/` directory. The runtime test seeks through audio for deterministic checks; it does not replace a real-time playthrough or physical Android latency testing.

The package contains Lua source, not compiled bytecode. Original third-party asset notices are included. Copied content retains its upstream terms; see `assets/light/LICENSE.md` and `assets/light/manifest.json`.
