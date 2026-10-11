# Sprite sources

The logical battle tile is **32×32 art units**. SVG sprites use a 32×32 canvas (16×16 for the coin and cannonball) and square pixel edges. Godot's canvas texture filter is nearest. The three transparent PNG illustrations are high-resolution editable source exports; rendering crops their alpha bounds and fits each into a tile. Keep future replacements inside a 32×32 logical tile and check them at the smallest 7×7 preview scale.

Palette: navy `#143f55`, deep water `#174b66`, turquoise `#198da5`, foam `#a5e7da`, wood `#a96042`, sand `#f4dda0`, coral `#ee7467`, gold `#ffd166`, and leaf `#65c77a`. Hidden tiles use the same `water_hidden.svg` texture for every hidden content type.

The transparent `ship.png`, `island.png`, and `treasure.png` were created with the built-in image generation tool. Prompt set:

- **Ship:** Single top-down warm wooden pirate ship tile with cream sail and coral flag, hard square pixels, limited navy/wood/cream/turquoise palette, transparent background, centered, no text or border.
- **Island:** Single top-down tiny sandy island and bright green palm with turquoise foam, matching the ship's crisp pixel scale and outline, transparent background, no other objects.
- **Treasure:** Single top-down closed wooden chest with gold lid and turquoise jewel, matching the ship's pixel style, transparent background, no other objects.

The SVG files are editable source assets for water states, target, destroyed section, cannon, cannonball, coin, splash, and impact. `assets/audio/generate_audio.py` is the source for the small original WAV sound set and music loop.
