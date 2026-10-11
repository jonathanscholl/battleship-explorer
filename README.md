# Battleship Explorer

A cozy, portrait pirate game prototype built with Godot 4.7.2. Milestones 1–2 are playable: discover enemy ship tiles on a 6×6 grid, choose a target, and let your cannon fire while an enemy explores and shoots back. Switch between one large enemy grid and a small preview of your waters, or swap them. Coins, upgrades, levels, and finished art are future milestones.

The step-by-step agent build plan is in [docs/ROADMAP.md](docs/ROADMAP.md), with a separate implementation and acceptance guide for each of the six milestones. [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) distinguishes current rules from planned ones.

## Run locally

Install [Godot 4.7.2](https://godotengine.org/download/) and run from this directory:

```sh
godot --path .
```

Or open `project.godot` in the Godot editor and press Play. Mouse clicks and phone taps use the same grid interaction. Discovery has a 0.8-second cooldown.

Tap hidden enemy tiles to reveal them. Tap a found, living ship tile to select a cannon target. The cannon fires every 5 seconds; the enemy discovers a tile every 2.5 seconds and also fires automatically. Tap **SWAP VIEW** or the small preview to inspect your ship and the enemy's discoveries. **RESTART** begins a fresh battle. A win or loss offers **PLAY AGAIN**. Battles currently use placeholder art and no coins or upgrades.

## Test

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --quit-after 2
```

The tests cover ship placement and HP, discovery, hidden information, target validation, automatic fire and retargeting, enemy discovery, pause/restart, player-first simultaneous shots, both terminal results, and touch/view switching. The last command smoke tests the main scene.

## Web preview

Install the matching Godot 4.7.2 export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000` in a browser. The web preset uses the Compatibility renderer and disables threads, so GitHub Pages does not need cross-origin isolation headers. The local battle build was exported and checked in a desktop browser at a 390×844 viewport, including discovery, view switching, and restart. A real iPhone Safari test is still needed.

The [public GitHub repository](https://github.com/jonathanscholl/battleship-explorer) is connected, and Pages uses GitHub Actions. On each push to `main`, Actions imports the project, runs tests, exports Web, uploads the build artifact, and deploys it. Pull requests validate and build without deploying. The [phone preview](https://jonathanscholl.github.io/battleship-explorer/) is live.

## Layout and rendering

The logical portrait canvas is 390×844. Controls and the grid position scale from the current viewport, with generous top and bottom margins for phone safe areas. The game uses Godot 2D's Compatibility renderer and nearest-neighbor canvas texture filtering. Temporary grid art is drawn with simple colors and shapes so final pixel assets can replace it later.
