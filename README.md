# Battleship Explorer

A portrait pirate tactics game built with Godot 4.7.2. Place your ship, send sector scouts, and manage a three-person crew. Scouts use one crew; aiming a shot or repairing uses two. You choose when to fire, while the enemy scouts and issues its own orders. Victories unlock three levels, with progress saved locally.

The [roadmap](docs/ROADMAP.md) and [current game design](docs/GAME_DESIGN.md) describe the rules and step-by-step milestone guides.

## Play

Choose **First Encounter**. Tap **Your Waters** to place your ship; use **ROTATE** to change its direction and **SAIL!** to begin. The enemy does not act during placement.

Tap hidden enemy waters to send a 2×2 scout. The crew member returns when the scan arrives. Once a ship section is found, tap it to select a target, then press **FIRE** to assign two crew to aim. The shot lands after the aim timer; press Fire again for another shot. Use **REPAIR** to assign two crew and spend four coins on a timed repair. You can scout while gunners aim or repairers work, but firing and repairing cannot run together. **ARMORY** pauses play while you buy Damage, Speed, or Scout Tempo upgrades with coins.

Tap **SWAP** or the small preview to inspect your ship. **MENU** offers resume, restart, level selection, and audio controls. Restart returns to ship placement. Coins come from treasure, islands, and actual cannon damage. Browser audio begins after your first interaction.

Progress is stored offline in `user://battleship_progress.json`. In the Web preview, it belongs to that browser and device; cleared site data can erase it. The save contains only completed and unlocked level IDs.

## Run and test locally

Install [Godot 4.7.2](https://godotengine.org/download/), then run:

```sh
godot --path .
```

From this directory, validate with:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_scouts.gd
godot --headless --path . --script res://tests/test_tactical.gd
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_economy.gd
godot --headless --path . --script res://tests/test_levels.gd
godot --headless --path . --script res://tests/test_presentation.gd
godot --headless --path . --quit-after 2
```

The tactical tests cover setup, invalid placement, crew conflicts, timed orders, pause, enemy scouting, retry, and manual victory. The other tests cover grids, combat, coins, saves, effects, and touch controls.

## Web preview

Install matching Godot 4.7.2 export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000`. The Web preset uses the Compatibility renderer without threads. GitHub Actions imports, tests, exports, and deploys pushes to `main`. The [public repository](https://github.com/jonathanscholl/battleship-explorer) and [phone preview](https://jonathanscholl.github.io/battleship-explorer/) are available. A physical iPhone Safari playtest remains open.

## Layout and art

The logical portrait canvas is 390×844. Controls and the grid adapt to the viewport. The game uses nearest-neighbor texture filtering. [Sprite notes](assets/sprites/ART_NOTES.md) document the art grid and palette; `assets/audio/generate_audio.py` regenerates the compact WAV set.
