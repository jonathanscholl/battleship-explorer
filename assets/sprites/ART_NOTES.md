# Sprite sources

The logical battle tile is **32×32 art units**. SVG sprites use a 32×32 canvas (16×16 for the coin and cannonball) and square pixel edges. Godot's canvas texture filter is nearest. Transparent PNG illustrations are high-resolution source exports; rendering crops their alpha bounds and fits each into a tile. Check replacements at the smallest 7×7 preview scale.

Palette: navy `#143f55`, deep water `#174b66`, turquoise `#198da5`, foam `#a5e7da`, wood `#a96042`, sand `#f4dda0`, coral `#ee7467`, gold `#ffd166`, and leaf `#65c77a`. Hidden tiles use the same `water_hidden.svg` texture for every hidden content type.

The transparent `ship.png`, `island.png`, and `treasure.png` were created with the built-in image generation tool. Prompt set:

- **Ship:** Single top-down warm wooden pirate ship tile with cream sail and coral flag, hard square pixels, limited navy/wood/cream/turquoise palette, transparent background, centered, no text or border.
- **Island:** Single top-down tiny sandy island and bright green palm with turquoise foam, matching the ship's crisp pixel scale and outline, transparent background, no other objects.
- **Treasure:** Single top-down closed wooden chest with gold lid and turquoise jewel, matching the ship's pixel style, transparent background, no other objects.

The SVG files are editable source assets for water states, target, destroyed section, cannon, cannonball, coin, splash, and impact. `assets/audio/generate_audio.py` is the source for the small original WAV sound set and music loop.

Interface text uses Pixelify Sans from the [Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/pixelifysans), bundled at `assets/fonts/PixelifySans.ttf` under the SIL Open Font License in `assets/fonts/OFL.txt`.

## Tropical battle screen revision

The current battle screen uses `assets/backgrounds/ocean_adventure.png` as a portrait scene and `ship-v2.png` for board tiles and HUD portraits. Both were created with the built-in image generation tool using the user's supplied screenshot as a **style reference**, then copied into the project. The screenshot itself is not shipped. The new colors favor bright cyan water, cobalt hidden tiles, dark ink outlines, warm wood frames, parchment labels, and red, purple, green upgrade cards. UI frames, tile highlights, target brackets, and health bars are code drawn in `scripts/ui/main_screen.gd`; the stopwatch and repair icons are editable SVGs.

The second interface pass moved restart, level select, and audio into a Captain's Log pause panel. Purchase cards now use saturated code-drawn bevels, dedicated icon wells, and coin badges while their transparent Button nodes keep touch and disabled behavior. The board uses layered cyan tile bevels and pixel type; hidden positions remain visually identical.

Final image prompts:

- **Ocean background:** Original 9:16 polished pixel-art tropical archipelago in bright daylight; blue sky, clouds, turquoise foam-lined sea, rocky green islands, small lighthouse and pier at the left, decorative railing at bottom corners. Keep open water across the central 28–78% for the board. No UI, grid, ships, text, buttons, or watermark. Do not copy the reference layout exactly.
- **Ship v2:** One original three-quarter-view pirate ship token with a broad warm wooden hull, gold trim, cream and dark navy sails, a small skull mark, red pennant, and foam below. Chunky deep-navy pixel outline, readable at 72×72, square transparent canvas. No scene, UI, words, or watermark.
