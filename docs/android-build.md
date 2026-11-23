# Android APK workflow

`.github/workflows/android.yml` adapts only the Android portion of Light-Engine's release workflow. It runs on game/Android changes pushed to `main`, and can also be started through Actions → Android APK → Run workflow.

The workflow uses Java 17, Android SDK 34, NDK 25.2.9519653 and the pinned LÖVE Android 11.5a runtime. It rebuilds the game archive from source, extracts its unchanged files directly into APK assets and compiles `assembleEmbedNoRecordRelease`. Already compressed images and audio remain uncompressed inside the APK for direct seeking, matching Light-Engine's packaging approach.

The app is named SlideBeat, uses `com.zyn.slidebeat` and supports portrait and landscape. It uses the standard LÖVE launcher, without Light-Engine's storage-permission launcher, recorder or engine-specific patches.

Each successful run uploads an artifact named `SlideBeat-Android-<run number>` containing:

- `SlideBeat-android.apk` — universal ARM64 + ARMv7.
- `SlideBeat-android-arm64-v8a.apk` — ARM64.
- `SlideBeat-android-armeabi-v7a.apk` — ARMv7.
- `SHA256SUMS.txt`.

Download the artifact from the completed Actions run, extract it and install the appropriate APK. No separate LÖVE installation is needed. Each APK is aligned, signed and checked for native libraries and exact embedded game content before upload.

`android/build-signing.jks` is this project's dedicated public development signing key. It is separate from Light-Engine's key and keeps development APK updates compatible. Its public build credentials are alias `slidebeat` and password `android`; it is not a private store-release signing identity. Version codes increase with the workflow run number.

Light-Engine remains unchanged. No desktop builds or release publishing are added by this workflow.
