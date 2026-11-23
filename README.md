# SlideBeat — Light-Engine addon

A radial rhythm mode for **Light-Engine**. Hold the mouse button or one finger in the center, slide toward a highlighted arrow on the beat, and return through the center for the next stroke.

[Download SlideBeat-addon.zip](https://github.com/toZyn/SlideBeat/raw/refs/heads/main/dist/SlideBeat-addon.zip)

## Install

1. Use a current Light-Engine build with native addon modules. This addon was tested against engine commit `eb0d62aa094be1cba9d667c5a941cacee4ae9d14` (0.7.0).
2. Extract the ZIP into the engine's **addons** content directory. The result must be `addons/slidebeat/meta.json`, `addons/slidebeat/global.lua`, and `addons/slidebeat/modules/`.
3. Open the engine's **Mods → Add-ons** tab and enable **SlideBeat**.
4. Return to the main menu, choose the new **SlideBeat** entry, then **Select Music**.

On Android, the current engine uses `/storage/emulated/0/Android/media/com.zyn.lightengine/addons/`. Use the content directory of the installed Light-Engine build if its package name differs. The addon uses the existing engine application; it has no separate APK or LÖVE executable.

## Native integration

- Adds one selectable main-menu entry while enabled.
- Reuses the engine's Freeplay song discovery, installed mods and difficulty selector.
- Reads charts through `Parser.getChart` and uses the instrumental and available vocals resolved by the engine.
- Borrows Light-Engine's textures, font and cached assets directly; no copied engine asset pack is needed.
- Provides a radial playfield, countdown, tutorial, pause/resume, retry, practice, failure, results and separate records.
- Exposes native engine options as well as addon-specific offset, practice and playfield-size settings.
- Uses `game.save.data.slidebeat` for addon data. Normal FNF scores and the engine's key bindings remain separate.
- Restores its temporary input adapters and menu integration when leaving or disabling the addon.

## Controls and rules

The initial press must be inside the center. Hold while sliding toward the bright arrow, then pass through the center again before the next stroke. You can also release and press the center again. Mouse and touch events remain forwarded to the engine; touch-generated mouse events cannot score a second hit.

| Direction | Stroke |
|---|---|
| Up | Slide upward |
| Down | Slide downward |
| Left | Slide left |
| Right | Slide right |

Timing is measured against instrumental playback. Perfect is within 55 ms, Good within 105 ms, and other accepted hits within 160 ms. Misses and wrong directions lower life and reset combo. Practice never fails or writes records. Arrow keys and the engine's Accept/Back controls navigate menus; use the visible pause button or engine pause control during play.

Simultaneous player notes form one chord: slide toward **any highlighted direction** to satisfy that chord. A sustain on the chosen direction requires continuous contact until its tail ends; you can move through the center to play other notes while holding. Releasing early counts a sustain miss. Heads and completed sustain tails are scored separately. If you pause during a sustain, resume waits for a new center press before its countdown, so pausing cannot force a sustain miss. Opponent notes do not require gestures.

This is a separate rhythm mode using the chart's player notes and audio. It does not run the selected mod's FNF stage, cutscenes, song scripts, custom note-type behavior or events. Those remain available through normal FNF Freeplay. It supports the standard four-direction player charts normalized by Light-Engine.

## Preferences and records

SlideBeat settings persist through the engine save system. A positive offset moves the expected stroke later than the audio beat. Volume and display preferences use the engine's existing options. Records are keyed by active mod, song and difficulty and never overwrite normal FNF high scores.

## Source and testing

`slidebeat/` is the complete installable addon. The root of this repository is not an engine replacement. `global.lua` uses the native addon lifecycle and `requireAddon`; private modules implement integration, input, gestures, chart adaptation, profile, drawing and the native State subclass.

```sh
lua tests/model.lua
python3 tools/test_native.py --engine /path/to/Light-Engine --love love
python3 tools/package_addon.py
```

The native test copies the supplied engine code and required resources into a temporary host and loads the real addon through the engine's Script/module system. It checks menu insertion, native options, touch tutorial, native Freeplay and parser, mouse gestures, sustains, pause/resume, consecutive runs, separate scores and cleanup after disabling. Test audio is generated locally. No changes are made to the supplied engine checkout.

Validated with desktop LÖVE 11.5. A physical Android-device test remains outstanding. Runtime tests seek the audio for deterministic note hits; they do not establish physical touch or audio latency.
