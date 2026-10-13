# Codex project notes

## Milestone workflow

Read [docs/ROADMAP.md](docs/ROADMAP.md) and the guide for the first incomplete milestone before implementing features. Follow its build order and acceptance gate. Milestones 1–6 are complete; Milestone 7 adds ship placement and crew tactics, followed by mobile validation in Milestone 8. Keep every milestone runnable, update tests and documentation with rule changes, and verify the GitHub Pages build after pushing a completed milestone. Do not mark a planned feature as implemented based only on its documentation.

## Architecture

- `scripts/grid/ship_model.gd` owns ship sections and HP. Placement is validated before mutating state.
- `scripts/grid/grid_model.gd` owns tile discovery and the ship's placement. `visible_kind()` is the view-safe API: hidden tiles return `HIDDEN` regardless of contents.
- `scripts/battle/grid_knowledge.gd` is each attacker's only view of the opposing grid; the AI receives this view, never the hidden grid or ship dictionary.
- `scripts/battle/battle_model.gd` owns two grids, setup placement, crew orders, scout travel, simulation order, and terminal results. `scripts/combat/cannon_model.gd` handles target/cooldown rules; `scripts/ai/enemy_ai.gd` chooses scout targets from revealed knowledge. `scripts/scouts/scout_fleet.gd` owns sector routes, scan areas, and mission timing.
- `scripts/battle/battle_rules.gd` holds current balance values. `scripts/upgrades/upgrade_state.gd` owns each side's coins and purchases; both sides use the same costs and effects.
- `resources/levels/level_definition.gd` validates authored level Resources and converts them to battle rules. `scripts/progression/level_catalog.gd` lists level order; `level_progress.gd` stores completed/unlocked IDs in `user://`.
- `scripts/ui/main_screen.gd` handles input, view switching, HUD, and temporary tile drawing. Rules belong in model scripts, not drawing code.
- `scripts/presentation/battle_effects.gd` and `game_audio.gd` consume battle events without affecting game state. They clear or stop safely on view changes, retries, and scene exit. Sprite sources and dimensions are in `assets/sprites/ART_NOTES.md`.
- `scenes/main/main.tscn` is the current entry scene.

## Invariants

- Ships are connected predefined shapes and fit wholly inside the grid.
- A tile is discovered only once. Discovery does not damage a ship.
- Hidden enemy positions must never be rendered or given to future enemy AI.
- Damage and repairs are bounded by section HP; coins from shots use actual damage dealt. A repaired section already discovered by the opponent must refresh in that opponent’s knowledge so it is visible and targetable again, without revealing hidden sections. Treasure and island discovery pay once.
- Use the same model rules for player and enemy in the battle milestone.
- A cannon attacks only revealed, living sections. In tactical battles, each player shot needs a manual order and two free crew; scouts use one crew and repair uses two. Damage resolves before visual effects. Player orders resolve before enemy orders if both are due together; a terminal result stops later actions.
- Focus loss pauses simulation without catch-up time on return. Restart returns tactical battles to ship placement with fresh grids, targets, crew, and timers.

## Style and verification

Keep GDScript typed where practical, use signals between major systems, and keep gameplay independent of animation or sound timing. Preserve the portrait layout, large touch targets, friendly colors, and clear hidden/revealed states. Do not add complex progression or networking.

Run `godot --headless --path . --editor --quit`, all scripts in `tests/`, and a main-scene smoke test after changes. Add meaningful model tests for new rules. Update `docs/GAME_DESIGN.md`, README, and the active milestone guide when gameplay or build behavior changes.
