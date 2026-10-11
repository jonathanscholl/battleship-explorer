# Game design and rule status

Battleship Explorer is a cozy, offline, level-based pirate game. The intended core loop is: reveal enemy waters, target a found ship section, let cannons fire automatically while continuing to explore, earn coins from damage or discoveries, buy a simple upgrade or repair, and sink the enemy before it sinks the player. The interface stays on one large grid with a small opposite-side preview during battle.

## Implemented now — Milestone 1

- One 6×6 enemy-water grid with a straight, connected three-tile ship at 5 HP per section. Placement uses random valid origins and rotations; tests can supply a seed.
- All tiles begin hidden. A tap reveals water or ship after a 0.8-second cooldown. Repeat taps do nothing. Discovery does not damage the ship.
- The UI shows temporary colored tiles. Ship HP exists in the model but no cannon, battle outcome, currency, or level progression uses it yet.
- The Web preview is live through GitHub Pages. Physical iPhone Safari testing remains open.

## Planned rules — Milestones 2–4

| Rule | Intended behavior | First milestone |
| --- | --- | --- |
| Two sides | Each side owns one grid, one fixed ship, one discovery timer, and one cannon | 2 |
| Information | Enemy AI sees only its revealed player-grid cells; player sees own ship and revealed enemy cells | 2 |
| Cannon | One target at a time; only revealed living ship sections; 5-second interval and 1 damage initially | 2 |
| Retarget | Manual tap selects a found living section; after destruction, choose the next found living section in row-major order | 2 |
| Results | Ship HP is the sum of section HP; at zero HP it sinks. Player action resolves first when actions share an instant; a terminal result stops further actions | 2 |
| Coins | +1 per actual damage HP, +10 treasure, +5 island; each reward occurs once | 3 |
| Upgrades | Damage 1–4, fire interval 5/4/3/2 seconds, and repair up to 5 HP per purchase | 3 |
| Levels | Three `.tres` level definitions; each starts fresh; victory unlocks the next | 4 |
| Save | Local `user://` unlock/completion data only; no account or sync | 4 |

Milestone 2 starts with two three-section ships at 5 HP per section, a 0.8-second player discovery cooldown, 2.5-second enemy discovery interval, and 5-second cannons at 1 damage. Milestone 3's initial purchase costs are Damage 8/16/28, Speed 10/20/35, and Repair 8 coins. These are provisional balancing values, not current gameplay. Milestone 4 moves parameters to Resources and adds `First Encounter`, `Pirate Scout`, and `Pirate Captain`.

## Planned presentation — Milestones 5–6

Original top-down pixel art should be bright, cute, and readable: turquoise ocean, warm ship wood, colorful sails, tiny islands and treasure, short water and cannon effects, and restrained pirate framing. Animations and audio respond to simulation events; they never determine when damage or rewards occur. The primary grid stays large, with a small preview that swaps roles when the player changes view. The phone Web build is the fast feedback path; native iOS export preparation follows after real Safari validation.

## Open design questions

- Tune discovery and enemy pacing, upgrade costs, and level length from phone playtests while preserving short casual sessions.
- Choose and document one sprite pixel density and palette before final art production.
- Record physical iPhone Safari compatibility and performance rather than inferring them from desktop browser checks.

The [roadmap](ROADMAP.md) contains the implementation sequence and acceptance gates. This file records rules and their implementation status; planned entries must not be treated as shipped behavior.
