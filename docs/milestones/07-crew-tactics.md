# Milestone 7 — Crew tactics and ship placement

**Status:** Implemented locally; deployment verification pending. **Outcome:** A battle starts with ship placement and then becomes a sequence of deliberate crew orders. The player decides when to scout, fire, repair, and upgrade.

## Player loop

1. Select a level. The battle is in `SETUP`; the enemy clock is stopped and the player's ship has no position.
2. Tap a valid origin on **Your Waters** to place the level's predefined ship. **ROTATE** turns it around that origin. Invalid placements leave the current position unchanged. **SAIL!** starts combat only after placement.
3. During combat, tap a hidden enemy tile to send a 2×2 sector scout. One of three crew stays busy until the scout arrives. Route and launch cooldowns still apply.
4. Tap a discovered, living ship tile to choose the target. **FIRE** assigns two crew to the gun for three seconds at base speed. Damage resolves when aiming ends. The player must order each shot; no player cannon fires automatically.
5. **REPAIR** assigns two crew for 4.5 seconds and spends four coins. It restores up to the level's repair amount on completion. A destroyed section revived by repair becomes visible and targetable again to any opponent that had discovered it.
6. **ARMORY** pauses the battle while the player buys Damage, Speed, or Scout Tempo with coins. Speed shortens future aim orders; it does not produce automatic shots. Damage from shots and treasure or island discovery still earn coins.
7. Enemy scouting, firing, repair, and upgrades use its own knowledge, coins, and crew. Its current gun or repair order is shown in the top enemy HUD so the player can respond.

## Balance and constraints

- Three crew are shared across orders. Scout uses one; fire and repair use two. A scout can run alongside a gun or repair order, but gun and repair cannot run together.
- Tactical battles multiply authored section HP by two. First Encounter therefore has 12 enemy HP and 24 player HP. The longer fight gives time for scouting, targeting, upgrades, and repair decisions.
- An order locks crew until it completes. Pausing stops all order timers, scouts, and enemy decisions. Retry and next level return to placement with fresh crew, timers, coins, and grids.
- The setup ship can displace hidden special tiles; those tiles move to unoccupied water without changing their counts. No hidden enemy position is disclosed by placement or crew decisions.
- The enemy uses the same worker counts and action durations. Its action choices are automatic because it is the opponent; the player's attack timing is manual.

## Build and verification steps

1. Add tactical rules to `BattleRules` and authored `LevelDefinition` resources with positive validation.
2. Add safe setup placement to `GridModel` and `BattleModel`, including special-tile relocation and no enemy actions before sailing.
3. Add worker occupancy and order timers to `BattleModel`. Scout, fire, and repair reserve the documented crew, then release them when complete. Resolve player completion before enemy completion when both are due.
4. Replace the battle controls in `main_screen.gd` with placement controls, a crew panel, Fire/Repair/Armory actions, and enemy order telegraphs. Keep the large board and small preview.
5. Cover placement, invalid actions, crew conflicts, manual shots, timed repair, enemy scouting, pause, retry, victory, touch input, and presentation effects in tests. Run every test from README, the main-scene smoke test, and a Web export. Check a 390×844 browser layout and the live Pages build.
6. Update README, `GAME_DESIGN.md`, and CI. Confirm the deployment run and record physical iPhone Safari testing as a separate mobile milestone.

## Acceptance gate

- The player cannot start without placing a valid ship, and the enemy cannot act during setup.
- No shot occurs without a player Fire order. Crew occupancy prevents incompatible simultaneous actions and returns on completion.
- A complete level can be won through manually ordered shots; repair and scouts work during combat and respect pause.
- The portrait UI communicates crew availability, order status, enemy threats, and action costs without clipping.
- All automated checks, Web export, CI, and Pages deployment pass. Device-only checks stay open in Milestone 8.
