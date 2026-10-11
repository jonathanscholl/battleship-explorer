# Codex project notes

## Milestone workflow

Read [docs/ROADMAP.md](docs/ROADMAP.md) and the guide for the first incomplete milestone before implementing features. Follow its build order and acceptance gate. Milestone 1 is complete; Milestone 2 is next. Keep every milestone runnable, update tests and documentation with rule changes, and verify the GitHub Pages build after pushing a completed milestone. Do not mark a planned feature as implemented based only on its documentation.

## Architecture

- `scripts/grid/ship_model.gd` owns ship sections and HP. Placement is validated before mutating state.
- `scripts/grid/grid_model.gd` owns tile discovery and the ship's placement. `visible_kind()` is the view-safe API: hidden tiles return `HIDDEN` regardless of contents.
- `scripts/ui/main_screen.gd` handles input and draws temporary tiles. Rules belong in model scripts, not drawing code.
- `scenes/main/main.tscn` is the current entry scene.

## Invariants

- Ships are connected predefined shapes and fit wholly inside the grid.
- A tile is discovered only once. Discovery does not damage a ship.
- Hidden enemy positions must never be rendered or given to future enemy AI.
- Damage and repairs are bounded by section HP; future coin awards must use actual damage dealt.
- Use the same model rules for player and enemy in the battle milestone.

## Style and verification

Keep GDScript typed where practical, use signals between major systems, and keep gameplay independent of animation or sound timing. Preserve the portrait layout, large touch targets, friendly colors, and clear hidden/revealed states. Do not add complex progression or networking.

Run `godot --headless --path . --editor --quit`, both scripts in `tests/`, and a main-scene smoke test after changes. Add meaningful model tests for new rules. Update `docs/GAME_DESIGN.md`, README, and the active milestone guide when gameplay or build behavior changes.
