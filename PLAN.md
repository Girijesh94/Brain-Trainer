# Recall Quest — native memory arcade

## Outcome
A real offline Godot game, using one GDScript project for Windows, Android and iOS. No browser wrapper, account, ads or online dependency.

## Daily loop
1. Kim's game: inspect illustrated objects, then select remembered objects from a mixed board. Incorrect selections reduce the score. Adapt the number of objects from recent results.
2. Leitner: type an answer before revealing a card. Correct answers move a due card through 1/3/7/14/30-day review intervals; mistakes return it to daily review. New cards enter the queue gradually. Early practice does not advance due dates.
3. Blurting: study a short story, then write a recall. Show the five target ideas and transparent keyword suggestions; the player confirms their recalled ideas because automated keyword matching cannot reliably judge comprehension.

The three completed missions finish the daily quest, grant a daily bonus and count toward a calendar-day streak. Practice stays available. Partial daily progress is saved. Scores measure performance in these exercises, not intelligence or overall memory capacity.

## Features
- Touch, mouse and keyboard controls; portrait mobile layout with safe margins and scrollable content.
- Local atomic save with backup and validation; daily quest, XP, levels, history and per-mode statistics.
- Personal flashcards, focus mode with a slower study timer, optional sound and reduced motion.
- Pause, quit/back, instructions, answer feedback and retry.
- Original vector illustrations and a calm blue/mint arcade identity.

## Delivery and verification
- Import and parse scripts in Godot.
- Automated checks for scoring, review scheduling, date rollover, streaks, save/reload and game flows.
- Capture actual native game screens at mobile and desktop sizes.
- Export and launch the Windows executable.
- Export Android APK if an isolated local SDK can be provisioned. State device testing status.
- Deliver iOS export configuration and instructions; a signed iPhone build requires macOS, Xcode and the owner's signing team.

## Evidence boundary
The game practises observation, retrieval and spaced review. It does not promise photographic memory or a general increase in cognitive capacity. Useful improvement is assessed by recall accuracy and later reviews of learned material.

## Version 1.1 — clearer first play

Replace the dashboard's abstract names, top-level XP panels and multiple competing Play buttons with a guided session. Show the purpose, approximate daily duration and three ordered, plain-language game explanations. Use one primary Start/Continue action that names the next game. Put flashcards, progress and optional practice after the explanation. Provide an untimed playable example that has no effect on real progress, and concise numbered instructions with a specific start action for each real game. Preserve saves and the native platform builds.

## Version 1.2 — visual arcade

Replace the word-heavy home and intros with one primary action, a native 3D core and short illustrated steps. Apply the four requested visual skills as original Godot effects: aurora colour, liquid metal, refractive glass and native 3D. Keep memory tasks, scoring, honest self-checks and local saves intact. Provide reduced motion and a static performance fallback. Verify native renders, the full daily flow and compact layouts; then rebuild Windows and Android with the existing signing key. iOS export continues to require a Mac and signing.
