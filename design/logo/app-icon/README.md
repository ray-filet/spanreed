# Spanreed · Door Ajar: macOS app icon

| File | Use |
|---|---|
| `AppIcon-1024.svg` | Main artwork. 1024 canvas, 824 tile at 100 px, continuous corners (radius about 184), baked drop shadow, no bloom (kit review round: the old 30 % yellow bloom mixed to a grey haze over the blue slab). Used for 32@2x (64 px) and every larger size. |
| `AppIcon-small.svg` | Small-size cut for 16, 16@2x and 32 px. The door is larger (scale 0.78 instead of 0.72), the gap is 24 units instead of 14, the frame tone is dropped, the wall is lifted to Dusk Light `#55647F → #3A4660` so the door separates, and the shadow is minimal (dy 5, σ 3, 25 %). The knob is flat `#E3AE5E`, 19.2 icon units across (1.2 px at 16 px, 2.4 px at 32 px) and centred on a pixel centre at 16 px, so it renders as a clean amber dot (it was a 0.78 px brown smudge). |
| `AppIcon-1024.png` | Marketing / App Store-style artwork, 1024 × 1024, transparent outside the tile, baked shadow. It is the same file as `icon_512x512@2x.png`. |
| `Sources/Spanreed/Assets.xcassets/AppIcon.appiconset/` | What the app ships: 10 PNGs plus `Contents.json` (idiom `mac`, 16/32/128/256/512 pt at 1x and 2x), selected by `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Each PNG is rendered at its true pixel size from one of the SVGs above (headless Chrome), not downscaled. |
| `icon-composer/` | macOS 26 layer artwork plus assembly notes. Not tested in Icon Composer. |

## Which artwork each size uses

| File | Pixels | Artwork |
|---|---|---|
| `icon_16x16.png` | 16 | `AppIcon-small.svg` |
| `icon_16x16@2x.png` | 32 | `AppIcon-small.svg` |
| `icon_32x32.png` | 32 | `AppIcon-small.svg` |
| `icon_32x32@2x.png` | 64 | `AppIcon-1024.svg` |
| `icon_128x128.png` … `icon_512x512@2x.png` | 128–1024 | `AppIcon-1024.svg` |

The cut-over is at 32 px. At 64 px the full artwork still shows the frame tone, the caret, the knob and the floor
spill, so the small cut is not needed there. The web and PWA icons in `../exports/symbol/` (`icon-192/512`, `apple-touch-icon`, `maskable-512`) are
rendered from this same construction (`frame="tile"` / `"bleed"` in `icon_svg()`), without the shadow. Finder list view (16 pt) on a Retina display uses `icon_16x16@2x`, which is the small cut.

**The filter.** The legacy artwork bakes the Big Sur drop shadow under the tile with one SVG
`<feDropShadow dx="0" dy="10" stdDeviation="6" flood-opacity="0.35">` (`AppIcon-1024.svg`). Any renderer that
ignores SVG filters loses the shadow but keeps everything else. The logo masters in `../masters/` contain no
filters, masks, text or images. (The app-icon lockup in `../masters/` draws its soft shadow with stacked
translucent squircles instead of a filter.)

**Gradients in the icon** (all `userSpaceOnUse`, IDs prefixed `da-appicon-1024-` / `da-appicon-small-`):

- wall and floor: one hard-stop gradient on the tile, so the horizon is crisp without a clip path
- frame and slab: gentle vertical gradients
- light: Warm Light `#FFE2A3` to `#F4B862`
- spill: the light fading out across the floor
- knob: brass, `#EFCB8A` to `#C9944F`

## Rebuild

The build scripts (`build_masters.py`, `build_iconset.py`) live in the design workshop, not in this repo; see
`../README.md`. They regenerate the SVG artwork, the icon-composer layers and the 10 PNGs; copy the PNGs into
`Sources/Spanreed/Assets.xcassets/AppIcon.appiconset/`.
