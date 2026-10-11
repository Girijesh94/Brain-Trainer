# Verification and delivery status

Version 1.2.0 verified on 11 October 2026 with Godot 4.6.3 on Windows.

## Game checks

102 automated checks passed, with no failures. They cover object scoring and duplicate guesses; due-card scheduling and early review; date, year and leap-day rollover; daily XP and bonus rules; streaks; daily reset; save/reload and backup recovery; personal cards; adaptive challenge; no-due-card completion without a false recall score; and the complete daily session through all three native game screens. Pause/resume, timer expiry, library, settings, progress, credits and horizontal layout are checked too.

The redesigned landing screen is checked for a visible main start action on a narrow display. The untimed example is exercised through study, hiding objects, selection, feedback and entry to the real daily session, with a check that it never changes saved scores or daily progress. Resume skips completed games; the completed-day action opens optional practice. A new card remains reviewable when a session crosses midnight.

## Windows

The locally exported unsigned runtime was blocked by this computer's Application Control policy. The delivered Windows package therefore uses Godot's **unchanged official signed executable** with a companion `RecallQuest.pck`. Windows reports a valid Prehensile Tales B.V. signature. The native game launches from that package, passes a headless smoke run with exit code 0, and renders its actual game screen with exit code 0. No Windows security settings were changed.

Extract the Windows ZIP and keep the executable and `.pck` together. No separate engine install, browser or server is needed to play.

## Android

The installable APK has a verified signature, aligned archive and valid ZIP entries. Both `arm64-v8a` and `x86_64` native libraries are present. The package is `org.recallquest.memorygame`, version 1.2.0 (version code 3), minimum Android API 24 (Android 7.0), target API 36. Its only declared permission is vibration. It is signed with the same development key as version 1.0 so existing installations can be updated without removing their saves. It is not configured for Google Play publication.

**Android gameplay on a physical device or emulator has not been tested.** No Android device is connected here. Shared game flow and small-screen layout were exercised in the native Windows engine.

## iOS

The shared source and iOS export preset are included, but **an installable iOS build has not been created or tested**. Godot's iOS export requires macOS with Xcode. A build for the user's iPhone additionally needs the appropriate Apple signing team and provisioning. Those tools and credentials are unavailable here. The Mac steps are in the README.

## Artifacts

- `builds/RecallQuest-Windows.zip`: native Windows game and notices.
- `builds/android/RecallQuest.apk`: Android sideload build.
- `builds/RecallQuest-Source.zip`: editable game source, original assets, plan, licences, instructions and build helpers.
- `builds/verification.json`: verification results, package metadata and binary hashes.
- `builds/screenshots/`: actual native renders, not design mockups.

## Product limits

Progress is local to each device; there is no automatic account sync or reminder notification. Eight stories rotate in daily sessions. Flashcard and story scores partly rely on self-assessment. These games practise specific memory tasks and do not claim to produce photographic memory or measure general cognitive capacity.

## Visual arcade checks

Home has a 45-word budget; visual intros have a 35-word budget. Tests also check native 3D geometry, the 480x320 rendering ceiling, scene disposal on navigation, hidden-scene suspension, static rendering under reduced motion, gradient freeze, the SVG fallback and selection ticks. Actual native Windows renders were inspected at 480x860, 360x720 and 360x600, with no reported shader compilation errors. Headless tests alone do not validate GPU rendering. Android and iOS device/GPU testing remain outstanding.
