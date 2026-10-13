# Game design and rule status

Battleship Explorer is an offline, level-based pirate game. Its current core loop is **place → scout → choose a target → assign crew → fire or repair → upgrade → win or lose**. The screen shows one large board and a small opposite-side preview. The player controls the timing of every shot; the opponent makes its own crew decisions.

## Current rules — Milestone 7

### Setup

- Selecting a level opens **Your Waters** in a setup phase. The enemy clock does not run. Tap a tile to place the level's predefined connected ship, rotate it around that origin, and press **SAIL!**. Invalid or out-of-bounds placements are rejected. Hidden special tiles move out of the ship's footprint when needed; their counts are unchanged.
- Ship shape and section HP come from the level Resource. Tactical battles multiply authored section HP by two. First Encounter has 12 enemy HP and 24 player HP. Restart and next level return to setup with fresh grids and crew.

### Crew and orders

- Each side has three crew. A scout occupies one until its 2×2 scan arrives. Fire and repair each occupy two until their order completes. Crew return afterward. This permits a scout alongside a gun or repair order while forcing a choice between firing and repairing.
- Tap hidden enemy waters to send a sector scout. North, center, and south routes cover limited rows, with a shared launch timer and per-route cooldowns. Tile contents stay hidden until the scout arrives; discovery does no damage.
- Tap a discovered living enemy ship section to select it, then press **FIRE**. Two crew aim for three seconds at base speed, then the shot resolves. **There is no automatic player fire.** Damage upgrades increase damage; Speed shortens later aiming orders. A new shot needs a new Fire order.
- **REPAIR** uses two crew for 4.5 seconds and four coins, then restores up to the authored repair amount. It cannot start at full HP or after sinking. If repair revives a section already discovered by the opponent, that section visibly becomes targetable again. Hidden sections remain hidden.
- **ARMORY** pauses battle and offers Damage, Speed, and Scout Tempo upgrades. Treasure, islands, and actual shot damage earn coins; rewards occur once or per actual damage dealt. Scout Tempo shortens launch and route cooldowns. Coin balances are separate for the player and enemy.
- The enemy uses only `GridKnowledge` when choosing scans and targets. Its scouts, gun, and repair orders reserve the same crew counts and use the same action durations and costs. The top HUD telegraphs its current aim or repair order.

### Resolution, levels, and presentation

- A ship sinks when total section HP reaches zero. Player orders complete before enemy orders in the same update; a terminal result stops later actions. Pausing or losing focus freezes scouts, orders, and enemy decisions without catch-up.
- Three authored levels—First Encounter, Pirate Scout, and Pirate Captain—unlock in order. Progress saves completed and unlocked IDs locally in `user://`; it does not sync across devices.
- The portrait UI uses original ship, island, treasure, water, target, and effect sprites. Discovery, shots, coins, and sinking have short effects and audio. Damage and rewards resolve in the model before visuals. Browser audio starts after a gesture.

## Deliberate limitations and next validation

Balance values are provisional. The desktop browser preview has been checked at 390×844; a physical iPhone Safari session and native export preparation remain in [Milestone 8](milestones/08-mobile.md). There is no multiplayer, ship construction, or cross-device save sync.

The [roadmap](ROADMAP.md) contains the implementation sequence and acceptance gates. Earlier milestone guides record the rules that existed when those milestones were completed; this file describes current gameplay.
