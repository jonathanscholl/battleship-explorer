# Game design and rule status

Battleship Explorer is a cozy, offline, level-based pirate game. The intended core loop is: reveal enemy waters, target a found ship section, let cannons fire automatically while continuing to explore, earn coins from damage or discoveries, buy a simple upgrade or repair, and sink the enemy before it sinks the player. The interface stays on one large grid with a small opposite-side preview during battle.

## Implemented now — Milestones 1–5 and scout and idle combat

- Each battle has separate player/enemy grids and connected ships. Level Resources set grid size, shapes, HP, starting coins, tile rewards, timers, upgrade values/costs, and enemy repair threshold. Placement uses random valid origins and rotations; tests can supply a seed.
- All tiles begin hidden. A tap sends a scout to a 2×2 area in the north, center, or south row band. The scout reveals the area after travel; a shared launch timer and a separate cooldown on each route limit repeated scans. Already known or pending tiles cannot be targeted. Discovery does not damage the ship. The player's own ship is always visible; enemy ship locations remain hidden until discovered. The enemy AI receives only its revealed knowledge of the player grid.
- The player can select a revealed living enemy ship section. Both cannons fire automatically at the level's starting damage and interval. If a target is destroyed, the cannon takes the next revealed living section in row-major order. Without a target, it waits for discovery.
- The enemy chooses a 2×2 scan using its knowledge only and launches a scout at the level's configured decision interval. Scout travel, route cooldowns, and cannon timers run independently. The player can switch one large grid and a small opposite-side preview without interrupting battle.
- A ship sinks at zero total section HP. A player shot resolves before an enemy shot due in the same update; a terminal result skips the later shot. Restart creates fresh grids, timers, and targets. Focus loss pauses simulation without catching up on return.
- Treasure and island counts and rewards vary by level. They stay hidden until discovered and pay once per tile. Each HP of actual cannon damage grants 1 coin. The player and enemy have separate balances.
- Damage and Speed values and costs vary by level. Damage applies to the next shot without resetting its cooldown. Speed preserves the current cooldown's progress proportionally. Scout Tempo has two upgrades costing 12 and 22 coins; each reduces launch and route cooldown durations while preserving progress.
- Repair restores up to the level's configured HP amount, capped at the ship's original maximum. It fills damaged living sections before destroyed sections. Repair is unavailable at full HP or after sinking. Purchases are unavailable after the battle ends.
- The enemy spends its own coins: repair first after at least the level threshold has been lost, then Damage, Scout, and Speed. Its purchase decisions use its own HP and balance.
- Three authored levels are selectable: `First Encounter` (5×5, enemy ship 2×3 HP, player ship 3×4 HP, enemy scout decision every 8 seconds), `Pirate Scout` (6×6, enemy ship 4×4 HP, player ship 3×5 HP, enemy scout decision every 6.5 seconds), and `Pirate Captain` (7×7, enemy ship 5×5 HP, player ship 4×5 HP, enemy scout decision every 5.2 seconds). First Encounter has 1 treasure and 1 island; Pirate Scout has 2 of each; Pirate Captain has 3 treasure and 2 islands. Their `.tres` files contain the full values.
- A first victory unlocks the next level. A loss leaves unlocks unchanged; completed levels remain replayable. Progress stores only completed and unlocked IDs in a versioned local `user://` JSON file. Missing, corrupt, or outdated saves start at level 1. In Web, storage belongs to the current browser and device.
- The UI uses original top-down ship, island, and treasure pixel artwork with matching editable water, target, wreck, cannon, coin, and effect sprites. The shared art grid is 32×32 logical units with nearest filtering and a compact navy/turquoise/wood/gold palette. Hidden enemy tiles use exactly the same visual until revealed.
- Discovery, shots, coins, target selection, and sinking have short visual effects. The model resolves damage and rewards before projectiles travel; switching views or restarting clears effects. A small generated WAV sound set covers discoveries, cannon, impact, coins, purchases, sink, victory, and defeat. Audio starts only after a gesture. MENU pauses battle and exposes restart, level selection, and the AUDIO panel with separate music and sound-effect sliders.
- The Web preview is live through GitHub Pages. Physical iPhone Safari testing remains open.

Level costs and pacing are provisional until phone playtests. There is no cross-device save sync.

## Planned mobile validation — Milestone 7

The phone Web build is the fast feedback path; physical Safari validation and native iOS export preparation follow. Final art and sound balance should be refined from phone playtests.

## Open design questions

- Tune scout and enemy pacing, upgrade costs, and level length from phone playtests while preserving short casual sessions.
- Tune sprite scale and sound levels on a physical phone before final art production.
- Record physical iPhone Safari compatibility and performance rather than inferring them from desktop browser checks.

The [roadmap](ROADMAP.md) contains the implementation sequence and acceptance gates. This file records rules and their implementation status; planned entries must not be treated as shipped behavior.
