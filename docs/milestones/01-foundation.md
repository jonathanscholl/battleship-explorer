# Milestone 1 — Foundation

**Status:** Implemented and deployed. This file records the delivered baseline and its regression gate; it is not a request to rebuild it.

## Goal

A runnable Godot 4.7.2 project with a portrait, tappable 6×6 exploration grid, validated hidden ship placement, and a working Web preview.

## Delivered

1. `project.godot` sets a 390×844 logical portrait canvas, Compatibility renderer, and nearest texture filtering.
2. `scenes/main/main.tscn` runs `scripts/ui/main_screen.gd`. The screen draws readable temporary hidden, water, and ship tiles, accepts mouse and touch input, and applies a 0.8-second discovery cooldown.
3. `scripts/grid/ship_model.gd` validates connected shapes, bounds, rotation, section HP, damage, and repair.
4. `scripts/grid/grid_model.gd` places a ship from valid seeded or random positions, tracks one-time discovery, and returns `HIDDEN` from `visible_kind()` until discovery.
5. `tests/test_core.gd` covers 20 model checks; `tests/test_ui.gd` checks touch discovery. `export_presets.cfg` and `.github/workflows/web.yml` build and deploy the no-thread Web export.
6. README, `AGENTS.md`, and `GAME_DESIGN.md` document the current project. GitHub Pages serves the playable prototype.

## Regression gate

- Run every baseline command in [ROADMAP.md](../ROADMAP.md) after changes to the grid, ship, UI, project settings, or export preset.
- Confirm a fresh load shows 0/36 discovered, a tap reveals exactly one tile, and another tap of that tile does not reveal it again.
- Confirm hidden ship locations stay hidden in every public enemy-grid view.
- Confirm the web export loads and accepts a click. A desktop browser and a 390×844 viewport were checked; a physical iPhone Safari check belongs to Milestone 8.

## Handoff to Milestone 2

Keep the existing model tests and visual readability. The current screen owns the only grid; Milestone 2 should move battle state into a battle controller and make the screen a view of two grids. `ShipModel` already holds HP, but the current UI does not show or use it for combat.
