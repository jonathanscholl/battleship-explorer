# Battleship Explorer

A cozy, portrait pirate game prototype built with Godot 4.7.2. Milestone 1 is a tappable 6×6 exploration grid. A hidden three-section ship is placed randomly; tapping reveals water or ship tiles. Battle, coins, upgrades, levels, and finished art are future milestones.

## Run locally

Install [Godot 4.7.2](https://godotengine.org/download/) and run from this directory:

```sh
godot --path .
```

Or open `project.godot` in the Godot editor and press Play. Mouse clicks and phone taps use the same grid interaction. Discovery has a 0.8-second cooldown.

## Test

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --quit-after 2
```

The tests cover valid and invalid ship placement, rotation, grid generation, hidden information in the public view, repeated discovery, damage caps, total HP, repair caps, and a touch input smoke test. The last command smoke tests the main scene.

## Web preview

Install the matching Godot 4.7.2 export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000` in a browser. The web preset uses the Compatibility renderer and disables threads, so GitHub Pages does not need cross-origin isolation headers. The local web build was exported and clicked successfully in a desktop browser, including a 390×844 viewport check. A real iPhone Safari test is still needed.

The [public GitHub repository](https://github.com/jonathanscholl/battleship-explorer) is connected, and Pages is configured to use GitHub Actions. On each push to `main`, Actions imports the project, runs tests, exports Web, uploads the build artifact, and deploys it. Pull requests validate and build without deploying. The phone preview is at [jonathanscholl.github.io/battleship-explorer](https://jonathanscholl.github.io/battleship-explorer/) once the first deployment succeeds.

## Layout and rendering

The logical portrait canvas is 390×844. Controls and the grid position scale from the current viewport, with generous top and bottom margins for phone safe areas. The game uses Godot 2D's Compatibility renderer and nearest-neighbor canvas texture filtering. Temporary grid art is drawn with simple colors and shapes so final pixel assets can replace it later.
