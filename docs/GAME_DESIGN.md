# Current game design

## Milestone 1 rules

- The game shows one 6×6 enemy-water grid. The ship is a straight, connected three-tile shape with five HP per section.
- Ship placement is random among valid origins and rotations. Tests can pass a seed for reproducibility.
- All tiles begin hidden. Tapping a hidden tile after the 0.8-second cooldown reveals water or ship. A second tap has no effect.
- Revealing does not damage the ship. There is no battle result yet.

## Next milestones

The next step is two grids with one large view and a small opposite-side preview, automatic cannons, enemy discovery, HP display, and win/loss. Then add one coin currency and three in-battle upgrades, followed by level resources and local unlock saving.

## Open decisions

- Tune discovery cooldown and cannon pace after phone playtesting.
- Define simultaneous sink outcome before implementing battle. Proposed rule: process player action first within a frame, then enemy action only if battle remains active.
- Replace temporary shapes with original cozy pixel art while preserving tile readability.
