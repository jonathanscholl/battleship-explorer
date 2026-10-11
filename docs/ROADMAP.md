# Milestone execution guide

This is the build order for Battleship Explorer. Read [GAME_DESIGN.md](GAME_DESIGN.md) for current rules and [AGENTS.md](../AGENTS.md) for code invariants. Each milestone has its own checklist and acceptance gate:

| Milestone | Deliverable | State |
| --- | --- | --- |
| [1. Foundation](milestones/01-foundation.md) | Running, tappable 6×6 grid | Complete locally and deployed |
| [2. Battle](milestones/02-battle.md) | Complete battle with two grids and automatic combat | Complete locally and deployed |
| [3. Economy](milestones/03-economy-upgrades.md) | Coins, discoveries, three in-battle upgrades | Next |
| [4. Levels](milestones/04-levels-save.md) | Three data-driven levels and local unlocks | Planned |
| [5. Presentation](milestones/05-visual-audio.md) | Cozy pixel art, effects, and audio | Planned |
| [6. Mobile](milestones/06-mobile.md) | Tested phone web preview and iOS export preparation | Planned |

## How an agent should work

1. Start at the first incomplete milestone. Read its guide, `AGENTS.md`, `GAME_DESIGN.md`, and the code it names. Check `git status` before editing.
2. Implement its steps in order. Keep the game runnable after each coherent change. Use only the systems needed by the current milestone; do not pull later features forward to make an architecture look complete.
3. Add tests for new rules and regressions, especially the milestone's failure cases. Add new test commands to `.github/workflows/web.yml` and README so CI runs them. Update the milestone's acceptance checklist only after the corresponding behavior has been verified.
4. Run the baseline commands below, then the milestone-specific checks. Export Web locally when export settings or browser-facing behavior change.
5. Update `GAME_DESIGN.md`, README, and the milestone guide to match actual behavior. Mark completion only when every required acceptance item is verified. Record any remaining device-only checks explicitly.
6. Push to `main` when the milestone is ready, confirm the GitHub Actions run and Pages deployment, and give the owner the preview link plus a short phone test script. Do not ask the owner to use the Godot editor for routine review.

## Baseline verification

Run from the directory containing `project.godot`:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --quit-after 2
```

Run any new milestone test scripts as well. For a Web build, install matching Godot 4.7.2 export templates, run `mkdir -p build/web && godot --headless --path . --export-release Web build/web/index.html`, then serve `build/web` over HTTP. The [live preview](https://jonathanscholl.github.io/battleship-explorer/) is built by [the workflow](../.github/workflows/web.yml) after successful pushes to `main`.

## Fixed product boundaries

- One large grid and a small opposite-side preview. Never present two equal-sized grids.
- Offline, single-player, level-based play. One currency: coins.
- Predefined connected ships stay fixed during battle. No ship-building, modules, or movement.
- Discovery does not deal damage. Cannons only attack discovered, living sections.
- Player and enemy follow the same rules; enemy decisions use only information it has discovered.
- Simulation applies results before visual or audio effects. Pausing the app stops simulation time.
- Keep interactions simple enough to understand within seconds. Avoid extra screens and explanatory panels during battle.

## Handoff format

At the end of each milestone, report: implemented behavior, tests actually run, browser/device checks actually run, remaining limitations, deployment URL and CI result, and one recommended next task. If an acceptance item fails, keep the milestone open and explain the blocker.
