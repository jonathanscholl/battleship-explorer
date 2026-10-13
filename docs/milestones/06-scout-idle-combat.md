# Milestone 6 — Scout and idle combat

**Status:** Complete locally and deployed. **Outcome:** Exploration has deliberate timing and choices while cannons keep fighting automatically.

## Build order

1. Model three row-band scout routes for every grid size. A scout scans one bounded 2×2 area that includes the chosen hidden tile. Reject outside, known, pending, and cooldown-blocked targets.
2. Add travel time, a shared launch timer, and per-route cooldowns. Advance them only while battle runs. Reveal each cell and award discoveries on arrival; reset missions on retry or next level.
3. Give the enemy the same scout model. Pick scans from its `GridKnowledge`, with no access to hidden ship or special-tile data. Keep cannons automatic and able to attack only discovered living sections.
4. Add a scout tempo purchase. Preserve the elapsed share of current timers when upgrading. Keep the existing damage, speed, and repair choices.
5. Show route readiness and a visible outline for pending scans. Hidden scan cells must retain the same tile art until arrival. Keep touch input on the main enemy board.
6. Update rules, level resources, tests, Web workflow, game design, and README. Export and verify the portrait Web preview before declaring this milestone deployed.

## Acceptance gate

- A tap dispatches a 2×2 scan in the correct sector and reveals no contents before arrival.
- Shared and route cooldowns prevent rapid repeated exploration; scouts on another ready route can launch once the shared timer ends.
- Enemy scouting reveals only after travel, uses only its own knowledge, and keeps auto combat running.
- Scout purchases shorten launch and route intervals with proportional remaining time; pause, restart, and battle end stop or reset scout actions.
- Model, UI, level, economy, and presentation tests pass; main scene runs; Web export, CI, and Pages succeed.

## Verification

Godot import, all seven test scripts, main-scene smoke, and release Web export passed locally. The 390×844 browser preview showed the scout controls and pending scan outline without revealing hidden cells. [GitHub Actions run 38470019220](https://github.com/jonathanscholl/battleship-explorer/actions/runs/38470019220) passed validation and Pages deployment; the [live phone preview](https://jonathanscholl.github.io/battleship-explorer/) was checked after deployment. Physical iPhone Safari testing remains in Milestone 7.

## Balance notes

The starting player launch interval is 4 seconds, route cooldown 12 seconds, and scan travel 1.6 seconds. Tempo upgrades cost 12 and 22 coins and use 0.75× and 0.55× total interval multipliers. Enemy scout decisions occur every 8, 6.5, and 5.2 seconds across the three levels. These values need playtesting on a physical phone.
