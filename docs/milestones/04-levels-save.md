# Milestone 4 — Levels and local saving

**Status:** Complete locally and deployed. **Outcome:** Three distinct levels can be selected, replayed, completed, and unlocked across app launches.

## Prerequisite

Milestone 3's full battle loop works with a single configurable ruleset. Keep its economy and combat behavior while moving values into level definitions.

## Build in this order

1. **Resource types:** Add small custom `Resource` scripts and `.tres` files under `resources/levels/` for grid size, player/enemy connected ship shapes, section HP, starting coins, treasure/island counts and rewards, discovery cooldown, enemy discovery interval, cannon interval and damage, upgrade costs/caps, repair amount, and enemy purchase thresholds. Validate positive intervals/HP, connected shapes, attainable placement, and special-tile capacity before a battle starts. Keep shared rules in code where they are truly invariant.
2. **Three authored levels:** Create `First Encounter`, `Pirate Scout`, and `Pirate Captain`. Start with the brief's intent: small/slow/tutorial-friendly, then larger/faster/more treasure, then higher HP/more aggressive. Set actual numeric values and record them in `GAME_DESIGN.md`. Balance for short casual sessions rather than grinding.
3. **Fresh battles:** A level start or retry creates new grids, ships, coins, timers, targets, upgrades, and AI state from its Resource. Never carry temporary battle state into another level. Seed placement for automated tests; use random seeds for normal play.
4. **Progression:** Present a minimal level select or Next Level action outside the active battle view. Completing level N unlocks N+1, up to the final authored level. Losing never unlocks a level. Completed levels remain replayable. Victory and defeat screens offer clear Next/Retry/Level Select actions where valid.
5. **Save format:** Store only completed/unlocked level IDs in `user://` with a small schema version. Load defensively: missing or corrupt data starts with level 1 unlocked; unknown IDs are ignored; writes are atomic enough to avoid a truncated save after interruption. Keep saves local and offline. Document the reset path for development.
6. **UI and workflow:** Keep active battle uncluttered. Show level name briefly before battle or in a small HUD label. Ensure every level reaches the same GitHub Pages preview from a fresh browser session, noting that browser local storage is device/browser specific.

## Automated checks to add

- Every `.tres` loads, validates, and can generate a legal grid with no overlapping ship/treasure/island tiles across representative seeds.
- Starting each level sets its exact configured HP, coins, cooldowns, and AI parameters.
- Victory unlocks only the next level; loss does not unlock; replay does not erase progress.
- Retry and next level reset all transient state, including timers, selected targets, and purchases.
- A saved unlock survives restart; missing, corrupt, and outdated saves fall back safely.
- The last level completes cleanly without offering a nonexistent next level.

## Acceptance gate and phone script

- A new player can play level 1, win, reach level 2, close/reopen the browser, and still select levels 1–2. A loss offers Retry without changing unlocks.
- Levels 2 and 3 feel distinct through ship size/HP, enemy pacing, and discoveries, while the core interaction stays the same.
- Baseline and new level/save tests pass; all three levels load in Web; CI and Pages pass.
- Ask the owner to try the three-level path and report session length and difficulty. Do not claim cross-device sync: saves are local.

## Boundary

No campaign story, procedural run structure, accounts, cloud saves, or permanent equipment. More levels can reuse the Resource format later.

## Local verification

- Three authored `.tres` levels validate and generate across representative seeds. The level/save test covers exact starting state, victory and loss unlocks, retry and next level resets, replay, corrupt and outdated saves, and the final level boundary.
- In a 390×844 desktop browser viewport, a full First Encounter win displayed Next Level. Reloading the page preserved First Encounter completion and unlocked Pirate Scout; Pirate Scout loaded its 6×6 battle. The Web build reported no browser errors.
- Physical iPhone Safari and balance playtests remain open. Progress is local to each browser/device.
- [GitHub Actions run 38160879164](https://github.com/jonathanscholl/battleship-explorer/actions/runs/38160879164) passed validation and Pages deployment. The live preview loaded its level selection without browser errors.
