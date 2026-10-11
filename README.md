# Battleship Explorer

A cozy, portrait pirate game prototype built with Godot 4.7.2. Milestones 1–5 are playable: choose one of three levels, discover enemy waters, target a found ship, earn coins, and buy upgrades while the enemy explores and shoots back. Victories unlock the next level and progress is saved locally. Original pixel art, effects, and audio now bring the battles to life.

The step-by-step agent build plan is in [docs/ROADMAP.md](docs/ROADMAP.md), with a separate implementation and acceptance guide for each of the six milestones. [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) distinguishes current rules from planned ones.

## Run locally

Install [Godot 4.7.2](https://godotengine.org/download/) and run from this directory:

```sh
godot --path .
```

Or open `project.godot` in the Godot editor and press Play. Mouse clicks and phone taps use the same grid interaction. Discovery timing varies by level.

Choose **First Encounter** to begin. Win to unlock **Pirate Scout**, then **Pirate Captain**. Tap hidden enemy tiles to reveal them; treasure and islands award coins once. Tap a found, living ship tile to select a cannon target. Each HP of actual cannon damage grants 1 coin. Buy **DAMAGE**, **SPEED**, or **REPAIR** during battle. Tap **SWAP** or the small preview to inspect your ship. **MENU** pauses the battle and offers **RESUME**, **RESTART**, **LEVELS**, and **AUDIO**; the audio panel has separate music and sound-effect controls. Results offer **RETRY**, **LEVEL SELECT**, and **NEXT LEVEL** when unlocked. Browser audio begins after your first interaction.

Progress is stored offline in `user://battleship_progress.json`. In the Web preview, it belongs to that browser and device; private browsing or cleared site data can erase it. For local development, delete that file from Godot's user data directory to reset progression. The save contains only completed and unlocked level IDs.

## Test

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_economy.gd
godot --headless --path . --script res://tests/test_levels.gd
godot --headless --path . --script res://tests/test_presentation.gd
godot --headless --path . --quit-after 2
```

The tests cover ship placement and HP, discovery, hidden information, combat, coin rewards, purchases, repairs, level validation and generation, progression, defensive save loading, presentation timing and cleanup, and touch/view switching. The last command smoke tests the main scene.

## Web preview

Install the matching Godot 4.7.2 export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000` in a browser. The web preset uses the Compatibility renderer and disables threads, so GitHub Pages does not need cross-origin isolation headers. The local build was checked in a desktop browser at a 390×844 viewport, including tile states, effects, and audio controls. A real iPhone Safari test is still needed.

The [public GitHub repository](https://github.com/jonathanscholl/battleship-explorer) is connected, and Pages uses GitHub Actions. On each push to `main`, Actions imports the project, runs tests, exports Web, uploads the build artifact, and deploys it. Pull requests validate and build without deploying. The [phone preview](https://jonathanscholl.github.io/battleship-explorer/) is live.

## Layout and rendering

The logical portrait canvas is 390×844. Controls and the grid position scale from the current viewport, with generous top and bottom margins for phone safe areas. The game uses Godot 2D's Compatibility renderer and nearest-neighbor canvas texture filtering. [Sprite source notes](assets/sprites/ART_NOTES.md) document the 32×32 art grid, palette, asset names, and generation prompts. `assets/audio/generate_audio.py` regenerates the compact WAV set.
