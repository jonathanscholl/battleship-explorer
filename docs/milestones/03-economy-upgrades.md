# Milestone 3 — Economy and upgrades

**Status:** Implemented locally; CI/Pages verification pending. **Outcome:** The discover → shoot → earn → upgrade → repair battle loop runs without leaving the battle screen.

## Prerequisite

Milestone 2's two-sided battle, shot-result events, and terminal-state handling pass. Read its battle tests before changing reward logic.

Use these initial costs for the first balance pass, then revise only with playtest evidence: Damage 8/16/28 coins for levels 2/3/4; Speed 10/20/35 coins for levels 2/3/4; Repair 8 coins for up to 5 HP. Keep the values in one place so Milestone 4 can move them into Resources.

## Build in this order

1. **Tile contents:** Extend grid generation with water, treasure, and island tiles. Place treasure and islands only in unoccupied cells after ship placement. Keep counts and reward values configurable in one small rules/config object until level resources arrive in Milestone 4. Hidden special tiles must use the same view-safe `HIDDEN` result as hidden ships.
2. **One-time discovery rewards:** A first reveal of treasure grants 10 coins; an island grants 5. Use a discovery result/event to grant rewards in gameplay logic exactly once. Water and ship discovery grant no coins. Discovery still causes no damage.
3. **Shot rewards:** Grant 1 coin per HP of actual damage dealt by a successful shot. A shot against a section with 1 HP that has 4 incoming damage grants only 1 coin. No reward follows a miss, invalid target, or already destroyed section. Give the enemy its own coin balance under the same rule.
4. **Purchases:** Add a small economy/upgrade component under `scripts/upgrades/` or `scripts/battle/`. A purchase atomically checks running state, cost, max level, and eligibility, then spends coins and changes stats. Never compute or mutate costs in UI code. Keep definitions data driven enough to move into Resources in Milestone 4 without changing purchase behavior.
5. **Three upgrades:** Damage levels 1–4 deal 1, 2, 3, and 4 HP. Speed levels 1–4 use 5, 4, 3, and 2 seconds between shots; clamp intervals to a safe positive minimum. Define increasing costs in one table and display the next cost. Repair restores a configured HP amount without exceeding the original maximum. Reuse `ShipModel.repair()`: damaged living sections are filled first, then destroyed sections in stable coordinate order. Repair is unavailable at full HP or after sinking.
6. **Cooldown behavior:** Purchasing damage during a fire cooldown changes the next shot's damage without creating an immediate extra shot. Purchasing speed preserves the current shot's progress proportionally, so the next shot remains predictable and no burst occurs. Document the chosen rule in `GAME_DESIGN.md` and test it.
7. **Enemy purchases:** Give the enemy a simple deterministic priority: repair when meaningfully damaged and affordable, otherwise buy damage, then speed if affordable. It may use its own known HP, coins, and upgrade state, but no hidden player-grid information. Keep this strategy configurable later through level data.
8. **Battle UI:** Add a coin counter in the top HUD and three large bottom buttons for Damage, Speed, and Repair. Show current effect and next cost or “MAX.” Disable unaffordable or invalid actions. Reveal treasure and islands with distinct temporary icons and brief feedback. Exploration, auto-fire, and purchases continue concurrently.

## Automated checks to add

- Treasure and islands never overlap ships or each other, including crowded-grid generation.
- Repeated reveal grants no second reward; hidden special tiles remain hidden in the preview.
- Damage rewards use actual HP lost; destroyed sections cannot farm coins.
- Exact-cost purchase succeeds, insufficient-cost purchase changes nothing, and max-level purchase is rejected.
- Damage and speed upgrades behave correctly during an active cooldown; fire interval never becomes invalid.
- Repairs prefer living sections, may restore destroyed sections afterward, never exceed max HP, and are disabled at full HP or after sinking.
- Enemy coins and purchases obey the same economics and do not inspect hidden player tiles.
- Buttons update after coins, HP, levels, and battle status change.

## Acceptance gate and phone script

- In one uninterrupted battle, the player can discover treasure/island, earn coins from cannon damage, buy Damage and Speed, and use Repair after taking damage.
- All three buttons show clear availability and update without leaving the battle view. The enemy can spend earned coins.
- Baseline and new economy tests pass; a local Web build and CI/Pages deployment pass.
- Ask the owner to test whether rewards arrive once, whether upgrades feel affordable, and whether battle remains easy to understand. Capture balance feedback for Milestone 4.

## Boundary

No second currency, inventory, skill tree, permanent upgrades, or meta progression. Do not add more cannons, critical hits, or faster-discovery upgrades yet.
