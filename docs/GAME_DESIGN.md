# Game design and rule status

Battleship Explorer is a cozy, offline, level-based pirate game. The intended core loop is: reveal enemy waters, target a found ship section, let cannons fire automatically while continuing to explore, earn coins from damage or discoveries, buy a simple upgrade or repair, and sink the enemy before it sinks the player. The interface stays on one large grid with a small opposite-side preview during battle.

## Implemented now — Milestones 1–3

- One 6×6 enemy-water grid with a straight, connected three-tile ship at 5 HP per section. Placement uses random valid origins and rotations; tests can supply a seed.
- All tiles begin hidden. A tap reveals water or ship after a 0.8-second cooldown. Repeat taps do nothing. Discovery does not damage the ship.
- Each battle has separate player/enemy grids and three-section ships. The player's own ship is always visible; enemy ship locations remain hidden until the player discovers them. The enemy AI receives only its revealed knowledge of the player grid.
- The player can select a revealed living enemy ship section. Both cannons deal 1 HP every 5 seconds after acquiring a target. If a target is destroyed, the cannon takes the next revealed living section in row-major order. Without a target, it waits for discovery.
- The enemy reveals a random hidden player-grid tile every 2.5 seconds. Discovery and fire timers run independently. The player can switch one large grid and a small opposite-side preview without interrupting battle.
- A ship sinks at zero total section HP. A player shot resolves before an enemy shot due in the same update; a terminal result skips the later shot. Restart creates fresh grids, timers, and targets. Focus loss pauses simulation without catching up on return.
- Each grid contains two treasure tiles and two island tiles, placed outside the ship. They stay hidden until discovered. Treasure grants 10 coins and islands grant 5, once per tile. Each HP of actual cannon damage grants 1 coin. The player and enemy have separate balances.
- Damage purchases cost 8/16/28 coins and raise shot power through 1/2/3/4 HP. Speed purchases cost 10/20/35 and shorten the interval through 5/4/3/2 seconds. Damage applies to the next shot without resetting its cooldown. Speed preserves the current cooldown's progress proportionally.
- Repair costs 8 coins and restores up to 5 HP, capped at the ship's original maximum. It fills damaged living sections before destroyed sections. Repair is unavailable at full HP or after sinking. Purchases are unavailable after the battle ends.
- The enemy spends its own coins: repair first after at least 5 HP has been lost, then Damage, then Speed. Its purchase decisions use its own HP and balance.
- The UI uses temporary colored tiles, special-tile icons, HP and coin displays, an upgrade row, a target outline, and concise hit/result feedback. There is no level progression yet.
- The Web preview is live through GitHub Pages. Physical iPhone Safari testing remains open.

## Planned rules — Milestone 4

| Rule | Intended behavior | First milestone |
| --- | --- | --- |
| Levels | Three `.tres` level definitions; each starts fresh; victory unlocks the next | 4 |
| Save | Local `user://` unlock/completion data only; no account or sync | 4 |

The current costs are provisional balancing values. Milestone 4 moves parameters to Resources and adds `First Encounter`, `Pirate Scout`, and `Pirate Captain`.

## Planned presentation — Milestones 5–6

Original top-down pixel art should be bright, cute, and readable: turquoise ocean, warm ship wood, colorful sails, tiny islands and treasure, short water and cannon effects, and restrained pirate framing. Animations and audio respond to simulation events; they never determine when damage or rewards occur. The primary grid stays large, with a small preview that swaps roles when the player changes view. The phone Web build is the fast feedback path; native iOS export preparation follows after real Safari validation.

## Open design questions

- Tune discovery and enemy pacing, upgrade costs, and level length from phone playtests while preserving short casual sessions.
- Choose and document one sprite pixel density and palette before final art production.
- Record physical iPhone Safari compatibility and performance rather than inferring them from desktop browser checks.

The [roadmap](ROADMAP.md) contains the implementation sequence and acceptance gates. This file records rules and their implementation status; planned entries must not be treated as shipped behavior.
