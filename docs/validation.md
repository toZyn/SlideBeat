# Validation

Validated on 2026-11-23 with LÖVE 11.5 and Lua 5.1 on Linux. Rendering used a virtual X display; audio used OpenAL's null output driver. This verifies execution, rendering, playback clocks and input routing, not the sound of physical speakers or Android touch latency.

## Automated logic checks

`lua tests/core.lua` passed all 12 complete charts: 2,450 notes. Checks cover perfect runs, untouched source charts, timing grades, wrong directions, overlapping judgement windows, combo, score, life failure, practice, center-only activation, extra-pointer rejection, fast center crossings, release cleanup, invalid chart rejection, profile round-trips and difficulty-specific records.

The screen lifecycle regression test first failed when screen modules were reused as instances. The dispatcher was changed to create a fresh screen instance for each entry, then the test passed. This prevents the previous run's completion flag from blocking a subsequent song's results.

## Real LÖVE execution

`love . --test` exited with code 0 after visiting title, menu, selection, settings, calibration, records, credits, tutorial, failure and pause/resume. It drove center-to-arrow gestures through all four Hard charts and verified that every note scored Perfect and each song reached its results screen. These deterministic runs seek the actual audio Source to note timestamps; they are not uninterrupted human playthroughs.

A second run at 360 × 800 visited the same screens and completed First Steps on Hard. Screenshots were inspected for the selector, settings, tutorial, gameplay and results. A separate run opened the distributed `.love` archive itself, completed that shortened flow and exited with code 0.

The testing harness originally sought repeatedly to the end of a Source while waiting for completion; it now seeks once. That harness correction was kept separate from the real screen-instance bug found by running consecutive songs.

## Asset and package checks

All 20 copied Light-Engine resources matched their original files byte for byte and matched the SHA-256 values in `assets/light/manifest.json`. The reference checkout's working tree and diff remained clean. All Lua files passed syntax checks. The final `.love` archive was checked for duplicate paths, required resources and exact agreement with the packaged source files.

## Remaining physical-device verification

A physical Android device was not available. Touch latency, output-device latency, Android file opening and app background/foreground behavior still need testing on a phone. Tap calibration and manual offset controls are provided, but desktop automated tests cannot establish those device-specific measurements.
