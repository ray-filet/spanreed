# Spanreed · Door Ajar: layers for a macOS 26 `.icon` (Icon Composer)

I could not run Icon Composer when making these files, so nothing here has been tested in it. The layers were checked
by rendering each SVG and stacking them (`../../tests/icon-composer-stack.png`). Settle the
final glass settings by eye in Icon Composer.

## Files

All six files use a 1024 × 1024 canvas, with no tile mask and no shadow (each file's `<title>` says so). The door is laid out so the icon shape
fills the whole canvas, the way Icon Composer treats macOS/iOS icons. If your Icon Composer shows the shape inset
from the canvas edges, scale the foreground groups to fit (the legacy artwork puts the same door on an 824 px tile).

| # | File | What it is | Fill |
|---|---|---|---|
| 00 | `00-background.svg` | Wall and floor: Dusk `#46546E` → Dusk Deep `#2C3548`, with a hard horizon at the floor line, then floor `#2C3548` → `#222A39` | gradient |
| 01 | `01-spill.svg` | Light spilling onto the floor from the gap (60° / 25° fan, fades to 0) | gradient + alpha |
| 02 | `02-light.svg` | The light in the gap (the caret). 1 unit wider than the gap so it tucks under the door | flat `#FACD82` |
| 03 | `03-frame.svg` | Doorway frame (architrave, jamb and head). This is the full door silhouette with the gap notched in, and the slab sits on top of it, so no hairline seam can show | flat `#323C52` |
| 04 | `04-slab.svg` | The door slab. Its straight latch edge forms the left side of the gap | flat |
| 05 | `05-knob.svg` | Brass knob | flat |

The flat colours are the midpoints of the legacy gradients: frame `#323C52`, slab `#222A38`, light `#FACD82`,
knob `#DCB06C`. Icon Composer can put its own gradient on any layer. Suggested gradients, top to bottom: light
`#FFE2A3` → `#F4B862`, slab `#26303F` → `#1D2532`, frame `#37435B` → `#2C3548`, knob `#EFCB8A` → `#C9944F`.

## Assembling the `.icon`

1. Open **Icon Composer** (it ships with Xcode 26 and can also be downloaded from developer.apple.com). Choose
   *File ▸ New* and select macOS (add iOS if you want).
2. **Background:** pick the document's Background fill and either drop in `00-background.svg` as an image, or
   build the gradient in the inspector (Dusk `#46546E` at the top to Dusk Deep `#2C3548`). The floor horizon only
   exists in the SVG. A plain gradient also works, because the spill keeps the door grounded.
3. **Groups** (Icon Composer allows up to four). Drag in the SVGs and arrange them from back to front:
   - **Group 1, "floor light":** `01-spill`. Liquid Glass off. If a lighten blend mode such as *Plus Lighter* or
     *Screen* is offered, try it.
   - **Group 2, "light":** `02-light`. Liquid Glass off, or on with high translucency so it reads as light rather
     than as a solid. Shadow: none.
   - **Group 3, "door":** `03-frame` with `04-slab` on top of it. Liquid Glass on, specular on, shadow *Neutral*.
     This group is the physical object. The glass edge highlight on the slab's latch edge should help the door
     look ajar.
   - **Group 4, "details":** `05-knob`. Liquid Glass on, small specular.
   (Kit review round: the legacy icon no longer has a bloom around the gap, so there is no glow layer. If you
   want more glow, try Icon Composer's own lighting settings on the light group (I have not seen which ones it
   offers) rather than a tinted layer over the door: a pale-yellow layer over the blue slab mixes to grey.)
4. **Check the order.** The light must sit under the door group, because it shows only through the gap.
5. **Appearances:**
   - *Default:* as delivered.
   - *Dark:* darken the background to Ink Deep `#1D2532` → `#141A24`. Keep the light and knob warm and the door
     group as it is. The light then becomes the brightest thing on screen, which is the point of the idea.
   - *Clear / Tinted (mono):* make the light layer white at full opacity and leave the door layers neutral.
     Turn the spill off, or down to about 30 %, so the gap still reads as the brightest element.
6. Look at it in the preview at 1024, 128, 64, 32 and 16 px, on light and dark, in each appearance. At 16/32 px the
   glass rendering does the job that `AppIcon-small.svg` does for the legacy icon. If the gap closes at 16 px,
   widen `02-light` by moving the jamb out (in `src/build_masters.py`, use the small-cut door `_S` for the
   composer layers) and re-export.
7. *File ▸ Save* as `AppIcon.icon` and add it to the Xcode project. In the app target, under *General ▸ App
   Icons*, set the icon name to `AppIcon`.

## Legacy (macOS 13–15)

Spanreed supports macOS 13 and later. Xcode 26 can derive older-format icons from a `.icon` file. Check whether
those derived icons look as good as the hand-made `../AppIcon.appiconset`. If they don't, ship the asset-catalog
set for older systems. I have not verified how Xcode decides between the two when both exist, so confirm before
you rely on it.

## Regenerating

`python3 ../../src/build_masters.py` rewrites these layers, the masters and the app-icon SVGs from the parameters
in that script. Then `python3 ../../src/build_iconset.py` re-renders the PNGs, `.icns` and `.appiconset`.
