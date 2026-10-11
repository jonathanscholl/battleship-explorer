# Milestone 6 — Mobile validation and export preparation

**Status:** Planned. **Outcome:** The phone-first Web preview is reliable on real iPhones, with a clear path to native iOS and later Android builds.

## Prerequisite

Milestone 5's content and audio are playable through GitHub Pages. Browser checks on desktop are not a substitute for testing on a physical iPhone.

## Build in this order

1. **Device matrix:** Record the iPhone model, iOS version, Safari version, portrait viewport, and network used for every test. At minimum test one recent iPhone in Safari; add a smaller or older device when available. Do not claim untested device coverage. Keep a simple results table in this file or a linked test log.
2. **Safe areas and layout:** Verify the notch/Dynamic Island, status bar, browser chrome, and home indicator do not cover HUD, grid, preview switch, or upgrade buttons. Check common narrow and tall portrait viewports, text scaling, orientation changes, and touch targets. Fix layout through viewport-relative Control sizing rather than fixed tap coordinates.
3. **Input and lifecycle:** On device, test single taps, rapid taps, holding, switching grids during a shot, buying upgrades while auto-fire runs, reload, background/foreground, and interrupted audio. Ensure backgrounding pauses simulation and resuming does not cause a burst of overdue discoveries or shots. Check that local unlocks survive browser restart and that a new browser/device starts fresh.
4. **Web compatibility and performance:** Keep the Compatibility renderer and no-thread Web export unless a measured need changes that decision. Verify WebAssembly/WebGL startup, loading state, touch behavior, audio unlock after the first gesture, and no visible debug UI. Measure initial load size/time and battle frame rate on the test devices; reduce asset size, overdraw, and particle counts only where evidence shows a problem.
5. **iOS export preparation:** Add only the native export preset and documented prerequisites needed for a future signed build. Confirm the Godot project can be exported to an unsigned Xcode project if the required templates/tools are available. Document bundle identifier, icon/splash asset requirements, Xcode version, signing, and App Store steps as future owner-controlled setup. Do not create credentials or attempt App Store submission in this milestone.
6. **Android path:** Document the later Android export prerequisites and likely checks without building an Android release unless requested. Keep the shared GDScript, assets, and UI platform-neutral.
7. **Final workflow:** Confirm a Codex change pushed to `main` produces a green CI run and updated Pages preview that the owner can open from their phone. Document any remaining manual action in README with exact steps.

## Verification matrix

| Check | Evidence to record |
| --- | --- |
| First load on Safari | Device/iOS, URL, load result, approximate time |
| Portrait layout | Screenshot or notes on safe areas, grid, preview, HUD, upgrades |
| Tap and concurrent play | Discovery, auto-fire, targeting, upgrade, view switch |
| Background/resume | HP and timer state before/after; no catch-up burst |
| Audio | Starts after tap, mute and volumes work, no blocked-playback error |
| Save | Unlock persists in same browser; reset behavior documented |
| Performance | Device and observed frame rate or visible stutter |
| CI/Pages | Successful run URL and live preview URL |

## Acceptance gate

- A physical iPhone Safari session completes the core loop and level progression without layout, touch, audio, save, or timer failures.
- Any defect found on device has a reproducible case, fix, and retest note. Baseline and new tests, Web export, CI, and Pages pass.
- Native iOS preparation is documented honestly; signed builds and store distribution remain future work.

## Boundary

No App Store submission, iOS signing certificates, monetization, backend, or multiplayer. Android implementation follows validated iOS gameplay unless the owner changes priorities.
