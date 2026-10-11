# Milestone 2 — Battle system

**Status:** Next. **Outcome:** One complete battle, with placeholder visuals, that can be won or lost.

## Starting point

Milestone 1 has one enemy-water grid in `main_screen.gd`, plus reusable `GridModel` and `ShipModel`. Read those files and their tests first. Keep the 6×6 size for this milestone; level resources come in Milestone 4.

Use these provisional values until Milestone 4 moves them into level Resources: both ships have three sections at 5 HP each; player discovery cooldown is 0.8 seconds; enemy discovery interval is 2.5 seconds; both cannons start at 5 seconds and 1 damage. Tune only if a tested battle reveals a clear pacing problem.

## Build in this order

1. **Battle state:** Add one battle controller under `scripts/battle/` that owns a player side and an enemy side, with one grid and ship each. Each new battle creates fresh state. Define `RUNNING`, `VICTORY`, and `DEFEAT`; stop accepting gameplay actions after either result. Keep battle rules independent of `Control` drawing.
2. **Information boundary:** Give each side a discovery view of its opponent's grid. The player always sees its own ship. The enemy's search and target selection must receive only cells it has revealed; it must not inspect player ship coordinates or hidden tile contents through `grid.ship`. Add an explicit query such as `revealed_living_ship_cells()` rather than filtering the ship dictionary in AI code.
3. **Discovery:** Move the cooldown out of the UI into battle logic. Player taps reveal hidden enemy-grid tiles; enemy discovery uses an independent timer and chooses randomly among still-hidden player-grid cells. Both use the same reveal rules. A revealed tile cannot be rediscovered or trigger a second event.
4. **Cannon:** Add one cannon per side under `scripts/combat/`. Each cannon tracks damage, interval, selected target, and remaining cooldown. It may fire only at a revealed section with HP above zero. Tapping a revealed living enemy section changes the player's target immediately. If a target dies, choose the next revealed living section in row-major order; otherwise wait for discovery. Fire timers run independently of discovery and view switching.
5. **Damage and results:** Resolve shots in simulation immediately; emit a shot result containing source, target, actual damage, remaining section HP, and remaining ship HP for later effects. A ship sinks at total HP zero. Check for victory or defeat after each resolved action and cancel future simulation work at battle end. For two actions due at the same simulation instant, resolve the player's action first; if it ends the battle, skip the enemy action. Document this player-priority rule in `GAME_DESIGN.md`.
6. **Battle screen:** Replace the single-grid screen with one large main grid and a small, top-right preview of the opposite grid. Start with enemy waters large. A simple control swaps views without changing battle state or timers. Show enemy HP at top and player HP at bottom. On the player's own grid, show its ship plus the enemy's discoveries, damage, and destroyed sections. On enemy waters, keep hidden positions hidden in both main and preview views. Mark the selected target visibly. Keep reserved space for coins and upgrades without adding their rules yet.
7. **Lifecycle:** Provide a restart action and concise victory/defeat overlay. Pause timers when the app loses focus and resume without adding elapsed background time. Effects, if any, must never delay damage or revive actions after battle end.

## Automated checks to add

- Two independently generated grids and valid ship placement.
- Enemy search never chooses a revealed tile and cannot identify hidden ship coordinates from its input.
- A cannon with no discovered target does nothing; it never fires at water, hidden, or destroyed sections.
- Manual target selection and automatic retargeting after section destruction.
- Repeated tap and discovery cooldown enforcement in battle logic.
- Actual damage is capped at section HP; total ship HP matches the sum of sections.
- Independent discovery/fire timers continue when views switch, and pause without catch-up after focus loss.
- Player-first resolution when both shots become due together; exactly one terminal result; no later shots after result or restart.
- UI smoke test for main/preview swapping and hidden-position masking.

## Acceptance gate and phone script

- A player can discover a ship tile, select it, watch the cannon fire repeatedly, and finish a battle; the enemy can also win.
- The enemy visibly explores the player's grid and attacks only discovered sections.
- Switching grids during a shot preserves the one battle state. Restart clears old timers and targets.
- Baseline tests and new battle tests pass; Godot imports and the Web export loads. CI and Pages pass after push.
- Ask the owner to open the preview, find a ship tile, switch views during automatic firing, and try one win or loss. Record only actual feedback; do not mark physical Safari validation complete here.

## Boundary

Coins, treasure, islands, upgrades, multiple levels, finished art, and native export are later milestones. Placeholder HP bars and basic shot feedback are enough here.
