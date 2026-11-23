# Light-Engine reference study

Reference: toZyn/Light-Engine at `eb0d62aa094be1cba9d667c5a941cacee4ae9d14`.

The previous SlideBeat implementation was deleted before reading it. Light-Engine was inspected as a separate reference checkout. No commits, source edits or asset edits were made in that repository.

## Screen lifecycle and navigation

`loxel/state.lua` defines enter, substate and transition lifecycles. `funkin/states/title.lua` owns the intro, beat-reactive visuals and confirmation. `funkin/states/mainmenu.lua` owns menu selection and navigation to Freeplay, options and credits. SlideBeat implements its own smaller state dispatcher in `core/app.lua`, with separate modules in `screens/`, explicit enter/leave hooks and a short transition fade. It does not embed the FNF gameplay framework or its mod runtime.

## Music selection

`funkin/states/freeplay.lua` discovers songs from metadata and lists, retains a selected difficulty, tints the background from the selected song, queries a difficulty-specific high score and hands loading to LoadState. SlideBeat applies those responsibilities to a four-song catalogue: metadata, descriptions, previews, Easy/Normal/Hard maps, practice selection and independent records. Selection uses real song audio, not a placeholder. Keyboard, wheel and touch select the same catalogue entries.

## Assets and loading

`funkin/backend/paths/init.lua` centralizes image, atlas, font and audio caches. Music streams; short effects are cached. Its scene ownership code separates cache membership from objects still used by a drawable. `funkin/backend/scene.lua` enumerates scene resources; `scenejob.lua` yields preparation work; `funkin/states/load.lua` handles readiness and failed loads. `funkin/ui/loadscreen.lua` waits for presented work, tracks completed resources and hands the loading view to the incoming state.

SlideBeat preloads the shared UI resources through a counted task queue, showing each real completed task. Song loading separately validates the chart, opens a streaming Source and prepares gameplay before switching screens. Charts are cached rather than reread every frame. Short effects, fonts, images and arrow quads are reused. A gameplay Source is explicitly stopped and released when leaving play; a preview Source is released before loading a different preview or song. No song is fully decoded into memory for playback.

## Timing, preferences and scores

`funkin/backend/gameplay/conductor.lua` derives musical position and beat events from playback. SlideBeat uses the Source playback position for note judgement, approach rings and progress. Its original songs have fixed BPM, so a variable-tempo conductor is unnecessary. A three-beat countdown precedes audio playback; pause/resume freezes the Source and clears gestures.

`clientprefs.lua` separates persistent gameplay, audio and display choices. `highscore.lua` keys records by song and difficulty. SlideBeat follows those separations, with validated preference ranges, a profile backup, visible save errors and score records for completed non-practice runs. Its calibration screen estimates an offset from repeated taps; it cannot measure hardware latency directly.

## Pause and results

`funkin/substates/pause.lua` supplies resume, restart, difficulty changes, options and exit, while cleaning up its audio and controls on close. SlideBeat preserves the gameplay scene under a pause overlay, resumes with a short countdown, supports restart/difficulty changes and exposes hit-sound control. Failure offers retry, practice retry or return to music selection. Results show rank, judgement counts, accuracy, maximum combo, timing offsets and records.

## Actual reused assets

`assets/light/manifest.json` lists all 20 copied resources, their exact original paths and SHA-256 hashes. The game uses Light-Engine's menu backgrounds, NOTE_assets arrow atlas, Ready/Set/Go countdown, four rating images, health bar, character icons, VCR font and menu/hit sound effects. Its arrow atlas is read from the original XML; its up-arrow frame is rotated and tinted for four directions. The menu background image is also used on the title screen, while the desaturated background is tinted per song.

Original notices and terms are retained in `assets/light/LICENSE.md`. The copied assets remain subject to those terms; SlideBeat does not relabel them as original or unrestricted. The music and charts in `songs/` are original to SlideBeat and reproducible through `tools/build_content.py`.
