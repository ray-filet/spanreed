# Spanreed · Door Ajar — lockup specification

Built by `../src/build_lockups.py` (run `python3 -B build_lockups.py`). Every lockup is outlined paths: no `<text>`,
`<image>`, filters or masks. The wordmark is the shared outline from `kit/shared/wordmark` (Newsreader wght 450 /
opsz 36, hand-kerned, overlap-free). It is placed through `wordmark.py place()` and never re-set from the font. The
construction drawing is `../guidelines/lockup-construction.svg` / `.png` (kit review round: moved out of
`masters/`, so `masters/*.svg` holds logo artwork only). It is documentation and uses live `<text>` for its labels;
it is not artwork.

## The unit: R

**R = the arch radius of the door as placed** (half the door width). Gaps, clear space and file padding are all
multiples of R, so they scale with the mark. On the 256 symbol grid R = 62. The other parts of the door in R:
height 3.23 R, latch jamb 0.35 R, caret 0.23 R, knob Ø 0.26 R.

All numbers below are in the lockup's own units: wordmark font size 200, so cap height 137, x-height 91.07,
ascender (top of d) 144.17, descender (bottom of p) 48.73.

## Horizontal: `spanreed-door-ajar-horizontal{,-color,-white,-color-dark}.svg`

| | |
|---|---|
| Door height | **descender line → ascender line, + 1.2 % optical overshoot** = 195.21 = **1.425 × cap height**. The floor sits exactly on the p's descender (flat on flat). The round crown rises 2.3 units above the d's ascender serif, so the arch doesn't look short. |
| Door width | 121.03 (2 R, R = 60.52). The wordmark ink is 6.5 × the door width. |
| Gap | door's latch-side edge → the S's leftmost ink = **0.75 R** = 45.39 (≈ ½ x-height). |
| Vertical alignment | Set by the two lines above, not by centring. The door's centre is 48.9 above the baseline, close to the centre of the x-height band (45.5), so the door lines up with the lowercase. |
| Clear space | **1.5 R = 90.8 ≈ 1 x-height** on every side (the same as the wordmark's own rule). |
| File padding | 0.25 R (≈ 15) around the ink. viewBox **984 × 226**. |
| Minimum size | **32 px tall** file (door ≥ 25 px, so the caret stays ≥ 1.75 px; cap height ≈ 19 px). Below that use horizontal-small. |

**Why these proportions** (study: `../tests/lockup-study/sheet-h.png`). Door at cap height with the floor on the
baseline (H1) read as an extra letter. Floor on the baseline at 1.3 cap (H2) and centred at 1.6 cap (H4) let the
solid door outweigh the wght-450 type. Descender-to-ascender (H3) balanced the two. Gap 1 R looked
disconnected; 0.75 R reads as one unit.

## Horizontal, small-size cut: `spanreed-door-ajar-horizontal-small{,-color,-white,-color-dark}.svg`

Same construction with the small symbol cut: W 128 → R = 62.47, gap 0.75 R = 46.85, caret 32/200 and jamb 16/200
of the door height (kit review round; was 24/24). viewBox **991 × 227**. Use it from **14 px to 32 px tall** (cap
8.5–19 px). The wordmark's own minimum is a cap height of 8 px. At 14 px tall the caret is 1.9 px, where the
regular cut's would be 0.85 px. The `-white` and `-color-dark` versions are thinned 0.5 units per edge like every
other dark-ground file. (An earlier version left them unthinned because "the small cut stays on its pixel grid".
That was wrong: inside the lockup the door is scaled 0.976 and the file is used at any height from 14 to 32 px, so
its edges land on no pixel grid. Only the square `-symbol-small*` masters are pixel-exact, at 16 and 32 px.)

## Stacked: `spanreed-door-ajar-stacked{,-color,-white,-color-dark}.svg`

| | |
|---|---|
| Door height | **0.45 × the wordmark ink width** = 354.2 (2.585 × cap). Door width 219.6 (R = 109.8) = 0.279 × the word's width. |
| Horizontal | The door's axis = the centre of the wordmark ink. No optical nudge was needed: the S and the d are both tall, so the word's mass is close to symmetric. |
| Gap | **door floor → x-height line = 1 R** (109.8). That puts the floor 63.9 above the cap line, so the S and d tops stay clear. The gap is measured to the x-height because the lowercase sets the visible gap. |
| Clear space | **1 R** (= 1.2 x-heights) on every side. |
| File padding | 0.25 R (≈ 27). viewBox **843 × 659**. |
| Minimum size | **48 px tall** (door ≥ 25 px; cap ≈ 10 px). |

Study: `../tests/lockup-study/sheet-s.png` and `sheet-s2.png`. 0.40 looked weak and 0.60 dominant. A 1 R gap to
the cap line felt loose; 0.6 R to the cap line (≈ 1 R to the x-height) won.

## Symbol only: `spanreed-door-ajar-symbol-only{,-color,-white,-color-dark}.svg`

The door at 1:1 with the 256 symbol grid, cropped to its ink with 0.25 R padding: viewBox **155 × 231**. Clear
space **1 R**. Use it in layouts where the 256 square's built-in margins get in the way. For avatars, app tiles
and favicons, use the square symbol masters (`-symbol*.svg`, which keep the optical lift) or `../exports/symbol/`.
Minimum: 32 px tall for this cut (print 6 mm tall; the square 256 masters need 7 mm, because their caret is a
smaller share of the file). Below 32 px use `-symbol-small.svg` (`-symbol-small-reversed`, `-symbol-small-color`,
`-symbol-small-color-dark`), and for favicons the export set.

## Wordmark only: `spanreed-door-ajar-wordmark{,-color,-white,-color-dark}.svg`

The shared outline with the shared framing: viewBox **820 × 225** (16 units padding). The path matches
`kit/shared/wordmark/spanreed-wordmark-black.svg` to within 0.01 units. Clear space **1 x-height**. Minimum cap
height **8 px: ink 46 px wide (file 48 × 13 px)**, the shared spec's figure (`kit/shared/wordmark/wordmark-spec.json`,
`recommended`; 8 / 137 × 787.11 = 45.96 px of ink). Family sync: this used to read "≈ 48 px wide, ≈ 14 px file
height"; 48 px is the file width and the file is 13.1 px tall. Print minimum **cap height 2.8 mm: ink 16.1 mm wide
(file 16.8 × 4.6 mm)**, also the shared spec's figure (`recommended.minPrint*`). It is this kit's 0.15 mm hairline
rule applied to the shared outline (hairline 7.38 units at font size 200, cap 137, so cap ≥ 2.78 mm, rounded up to
2.8 mm). Lamplight's guide gives the same figure. The guide used to say "17 mm wide", which was the file width at
the hairline limit.

**Colour variant.** `-wordmark-color.svg` and every Door Ajar colour lockup set the word in **Ink `#26303F`**, the
door colour, which is also the canonical wordmark colour: the shared master `kit/shared/wordmark/spanreed-wordmark.svg`
is Ink `#26303F` (family sync; it used to be Ink Deep `#1D2532`, which next to a solid Ink door differs by ΔE00 3.5
and reads as a mismatch). So kit and shared files now agree, with one ink per lockup. The geometry is unchanged.
`#26303F` on white is 13.3 : 1, on Paper 11.9 : 1.

## App-icon lockup: `spanreed-door-ajar-app-icon-lockup{,-white}.svg`

For README and website headers. The macOS tile artwork (`../app-icon/AppIcon-1024.svg`, without its filter
shadow) sits next to the wordmark.

| | |
|---|---|
| Tile | T = **2.4 × cap height** (328.8), **centred on the cap-height band** (tile centre 68.5 above the baseline). |
| Gap | tile edge → S ink = **0.25 T** (82.2). |
| Shadow | A soft drop shadow drawn **without a filter**: seven stacked translucent squircles, offset 10/824 T. It renders in GitHub, image viewers and design tools that ignore SVG filters. |
| Clear space | **1 x-height** (0.28 T). |
| File padding | 0.06 T (room for the shadow). viewBox **1238 × 369**. |
| Minimum size | **72 px tall** (tile ≥ 64 px, the smallest size where the full icon artwork is used). Below that use the horizontal lockup. |
| Grounds | `-app-icon-lockup.svg` (Ink wordmark) on white, Paper, light grey. `-white` on near-black (e.g. GitHub dark `#0D1117`) or Ink Deep. **Not on Dusk `#46546E`**: the tile's wall is Dusk, so the tile edge disappears. |
| IDs | Gradients prefixed `da-lockup-appicon-` (colour) and `da-lockup-appicon-w-` (white): the two can share a page. |

Study: `../tests/lockup-study/sheet-a.png`, `sheet-a2.png`. At 2.0 cap the tile looked slightly weak. Centring at
0.42 cap (closer to the x-height) made the word float high. The shadow lifts the tile on light grounds and
disappears harmlessly on dark ones.

## Colour variants (all flat)

| Suffix | Door | Light (caret) + knob | Wordmark | Use on |
|---|---|---|---|---|
| *(none)* | `#000000`, caret and knob are real holes (evenodd) | holes | `#000000` | one-colour print, light grounds, cutting |
| `-white` | `#FFFFFF`, **thinned reversed cut** (every edge inset 0.5 on the 256 grid) | holes | `#FFFFFF` | dark grounds, Dusk, photos |
| `-color` | Ink `#26303F` | Amber `#F0A94B` | Ink `#26303F` | white, Paper `#F7F2E8`, light grey |
| `-color-dark` | Dusk Light `#55647F`, thinned reversed cut | Warm Light `#FFE2A3` | Paper `#F7F2E8` | Ink Deep `#1D2532`, near-black, black. **Not** Dusk or Dusk Deep |

- **Stacking in the colour files:** solid door silhouette, then the light exactly the size of the caret on top,
  then the knob on top. No edge pixel is ever part-transparent. The earlier order (light tucked 0.75 under a
  notched door) leaked 10–18 % of the background into the latch-edge pixel column below about 100 px. That
  showed as a pale hairline on light grounds and a dark one on dark grounds.
- **Colour-dark, kit review round.** The first version used a Paper door with an Amber light. That put the light
  (L* 74.5) *below* the door (L* 95.6), so on a dark ground the sliver read as an orange crack in a bright slab,
  the opposite of the light-ground file, and it was only 1.8 : 1 (it needed a 40 px door). Now the door is Dusk
  Light, between the ground and the light: Ink Deep L* 14.5 < door L* 42.1 < Warm Light L* 90.9. Warm Light in the
  door is 4.74 : 1, so the caret holds down to the regular minimums (below 32 px use `-symbol-small-color-dark`).
  The door is a quiet 2.58 : 1 on Ink Deep and 3.17 : 1 on `#0D1117`; on Dusk Deep (2.06 : 1) and Dusk it fades,
  so use `-white` there. The wordmark stays Paper.
- **Never** turn a colour file into one colour by recolouring it (CSS `brightness(0)`, a recolour tool,
  `export_variants.py` on a `-color` file). The amber caret and knob then merge into a solid door. Use the black,
  white or mono files: their caret and knob are real holes.
- Ink artwork on Dusk is only 1.75 : 1, and on black 1.4 : 1. Use `-white` or `-color-dark` there.

## Rules

- Lockups are fixed: never rearrange, rescale the parts separately, or re-set the word.
- Respect the clear space. Never place the logo closer than the clear space to an edge, other logos or text.
- Choose by size: horizontal ≥ 32 px tall; horizontal-small 14–32 px; stacked ≥ 48 px; app-icon lockup ≥ 72 px;
  symbol alone where the name is already present (the app icon, a favicon, an avatar).
- Prefer the colour files on brand grounds and the one-colour files for print, embroidery and cutting.

## Files and exports

- Masters (this folder): 4 horizontal + 4 horizontal-small + 4 stacked + 4 symbol-only + 4 wordmark + 2
  app-icon lockup SVGs. The construction drawing is in `../guidelines/`.
- `../exports/lockups/`: `export_variants.py --only black mono` (mono = Dusk `#46546E`) on the horizontal and
  stacked masters, PNG 1200 on the long side; the `-white` SVGs are copies of the thinned `masters/…-white.svg`
  (kit review round: no longer a recolour of the black geometry) with 1200 px PNGs; 1200 px PNGs of the colour,
  colour-dark and app-icon lockups; and 512 / 1024 / 2048 px PNGs of every symbol-only and wordmark file.
