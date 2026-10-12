# Spanreed wordmark (shared by Door Ajar and Lamplight)

## The decision

| | |
|---|---|
| Typeface | **Newsreader** (Production Type), variable TTF `Newsreader[opsz,wght].ttf`, SIL OFL 1.1 |
| Instance | **wght 450, opsz 36**. This is not a named static style: Regular is 400, Medium 500 |
| Master size | font size **200 SVG units per em**: cap height 137.00, x-height 91.07, baseline at y = 160.22 |
| Tracking | **0** |
| Kerning (1/1000 em) | **S·p −12, p·a +8, a·n +4, n·r −2, r·e −30, e·e −2, e·d −2** (master units: −2.4, +1.6, +0.8, −0.4, −6.0, −0.4, −0.4) |
| Case | Title case "Spanreed" |
| Ownable detail | **None**, on purpose (reasons below) |
| Wordmark colour | **Ink #26303F**, the family's Ink (`kit/shared/palette/spanreed_palette.py`, `WORDMARK_INK`): the same Ink both kits use for the word in their colour lockups and for type. Also #000000 and #FFFFFF versions. Until the family sync the master used Ink Deep #1D2532; only the fill changed (path data byte-identical) |
| viewBox | `0 0 820 225`: cropped to the ink with 16 units of padding (actual: 16.44 left/right, 16.05 top/bottom, because the box is rounded up to whole units and the ink is centred) |

## Files

- `spanreed-wordmark.svg` (Ink #26303F), `spanreed-wordmark-black.svg`, `spanreed-wordmark-white.svg`. All three are
  one `<path>` (13 overlap-free contours) plus a `<title>`. No text, images, filters, masks or gradients. Title ids
  are unique per file (`wm-ink-title`, `wm-black-title`, `wm-white-title`).
- `wordmark-spec.json` lists the font, axes, font size, tracking, kerning, measured cap height, x-height,
  ascender, descender, baseline, origin, advance, ink bounds, per-glyph origins and advances, the colours, the
  screen and print minimum sizes (`recommended`, computed from the outline) and the final path.
  The path comes in two forms: placed in the master viewBox, and in em units (`path_em`: 1/1000 em, first glyph
  origin at 0,0 on the baseline).
- `src/wordmark.py` is for lockup builders. `place(cap_height=… | font_size=…, x, baseline, ink_left=False)`
  returns the outline and its metrics at any size. It reads only the spec, never the font. I checked that it
  reproduces the master path to within 0.01 units.
- `src/build_wordmark.py` regenerates everything: `python3 kit/shared/wordmark/src/build_wordmark.py`. It runs
  `tools/outline_text.py` through `tools/.venv/bin/python -I` in a subprocess (no cache), removes overlaps, places
  the outline, then writes the masters, the spec, the licence copy and `tests/`.
- `src/union.py` removes the font's overlapping contours. `src/verify_outline.py` checks the result.
- `src/type_study.py` builds `study/type-study.svg/.png`. `src/test_sheets.py` builds `tests/small-sizes*` and
  `tests/in-context.*`. `src/kern_proof.py` builds upright and upside-down kerning proofs into `_work/`.
  `src/spacing.py` measures the white area between letters. `src/wmlib.py` holds shared helpers.
- `OFL-Newsreader.txt` is a verbatim copy of the font's licence.
- `_work/cache/` caches outline-tool output for the study scripts and can be deleted. The build never uses it.

## Why this type

The type study (`study/type-study.png`) set the name in Newsreader (opsz 24/48/72) and Source Serif 4
(opsz 24/42/60) at wght 360–540. It then put six shortlisted instances beside the round-1 Door Ajar and Lamplight
icons, on paper and on dusk, at lockup scale and at 11 px and 8 px cap height.

- **Newsreader over Source Serif 4.** Source Serif reads sturdier and more neutral, close to institutional, with a
  wide set and a plain `r`. Newsreader has a calligraphic stress, bracketed wedge serifs, a teardrop `a` and `r`
  terminal, and an old-style `S` whose spur rises to ascender height. Those make it read as a book on a shelf at
  home: warm, literary, unhurried. It was also designed for long-form reading on screens, which suits a plain-text
  editor.
- **opsz 36.** opsz 24 is text type: lower contrast and looser, it looks like body copy at logo size. opsz 60–72
  is editorial display: high contrast, large x-height, hairlines that get loud on screen. At 11 px and 8 px cap
  height opsz 60's `e` closes up and reads as "Spanrced" (row N3). opsz 36 keeps enough contrast to feel crafted and
  enough hairline to survive small sizes.
- **wght 450.** Next to a solid arched door and a solid lamp, 400 looks thin and the icon outweighs the word. From
  480 up the word starts to sound assertive, louder than the brief wants. 450 sits at the same visual weight as
  the icons' dark shapes without competing.
- **Tracking 0.** Tracking −6 (per 1000 em) looked more "logo" but denser and less calm. +6 looked airy, with gaps
  that start to read as separate letters. Kerning alone gave an even rhythm.

## Kerning

The outline tool applies no GPOS kerning, so every pair was spaced by hand. I judged pairs at 150–320 px font
size, upright and rotated 180°, against the n·r stem-to-stem rhythm. Upside down you see the spaces, not the word.
`src/spacing.py` gives a measured cross-check: the mean clamped white area per pair against the font's own n|n.
It is sensitive to its depth setting, so it advised and the eye decided.

- **r·e −30.** This was the big hole: the space under the r's arm and ball terminal. At −36 the ball crowds the
  e's top, so I settled on −30.
- **S·p −12.** The S's lower bowl and the p's left wedge serif left an open pocket.
- **p·a +8.** Round bowl against round bowl was the tightest pair in both the eye test and the measurement.
- **a·n +4.** The a's foot tail nearly met the n's serif at the baseline.
- **n·r −2, e·e −2, e·d −2.** These were already designed well. The adjustment is a hair, for evenness.

At 5–8 px cap height the r·e gap still stays open (`tests/small-sizes-3x.png`).

## No ownable detail

The wordmark has to sit beside two different symbols. A detail that echoes one of them would be wrong for the
other: a caret-like `d` echoes the door's light sliver, a dog-ear on a letter echoes the lamp's shade. Either one
also makes the quiet partner fussier. The mark is still ownable without one:

- the instance is not a named style, so typing "Spanreed" in Newsreader Regular does not reproduce it;
- the spacing is custom;
- the outline is overlap-free.

If a detail is wanted later, the cleanest candidate is shortening the S spur to cap height, but I would not do it.

## Overlap removal (please read if you edit the outline)

Newsreader is a variable font drawn with overlapping pieces. Stems, serifs, the e's crossbar and the S's spur are
separate, overlapping or self-crossing contours. They render correctly under nonzero fill. They would show seams in
vinyl or plotter cutting, embroidery, evenodd renderers and some boolean or stroke tools.

`src/union.py` merges them into one clean outline per letter. Every piece is an exact sub-curve of the font's own
quadratic Béziers: no flattening, no redraw. Results on this word: 10 contours in, 23 crossings, 13 contours out
(S 1, p 2, a 2, n 1, r 1, e 2, e 2, d 2).

Verification is in `tests/outline-verify.json`:

- **Same shape.** At 40,000 random points, the nonzero fill of the raw font outline and of the clean outline
  disagree at 0 points (points within 0.01 units of an edge are ignored).
- **No overlaps left.** The clean outline's evenodd and nonzero fills disagree at 0 points.
- **Raster check.** At 3000 px wide, Chrome renders the two outlines identically except for about 35 edge pixels.
  These are anti-aliasing differences along the e's crossbar edge, where Skia handles the original self-crossing
  contour differently. They are not shape differences.
- **Junctions.** I inspected every junction at 3600 px wide: no seams, notches or slivers.

## Audit (`tests/audit.txt`, all three files: 91/100)

- **WARN near-miss angles.** 76.6° is the S's lower terminal cut. 178.2° (twice) is the slanted crossbars of the two
  e's. Both are part of Newsreader's design (the slanted crossbar is deliberate), so I left them as drawn. Snapping
  them would make the letters look mechanical.
- **INFO 300 anchors** (library median 75). That is normal for eight serif letters, and every point is the font's.
- No FAIL, no live text, no rasters, no filters, one colour per file.

## Renders I looked at

- `tests/wordmark-ink-on-white-1200.png`, `-black-on-white-1200.png`, `-ink-on-paper-1200.png` and
  `-white-on-dusk-1200.png` (#2C3548). Re-rendered and re-checked after the change to Ink #26303F (the ink renders
  sample as exactly #26303F).
- `tests/small-sizes.png` and `tests/small-sizes-3x.png`, at cap heights 4–24 px on white, paper and dusk.
- `tests/in-context.png`, with the round-1 icons at two scales.
- `study/type-study.png` (drawn in Ink Deep #1D2532 before the wordmark colour became Ink; kept as the record of
  the type study and not rebuilt, so it still shows the old ink).

## Usage notes for lockup builders

- Set the wordmark by cap height: `fontSize = C / 0.685`, or use `wordmark.place(cap_height=C, …)`. Centre symbols
  optically on the cap-height band (`capHeightY` to `baselineY`) and check by eye.
- **Minimum size:** cap height 8 px: ink 46 px wide (file 48 × 13 px). Computed in `wordmark-spec.json`
  (`recommended`): 8 / 137 × 787.11 = 45.96 px of ink; the file (viewBox 820 × 225, with its 16-unit padding) is
  47.88 × 13.14 px. Both kits' guides quote the same figures. (This note used to say "an ink width of about 48 px",
  which was the file width.) It stays legible down to 7 px; below 6 px the n and r begin to merge.
- **Print minimum:** cap height 2.8 mm: ink 16.1 mm wide (file 16.8 × 4.6 mm). It comes from the family's print
  rule: the thinnest hairline stays at least 0.15 mm, positive or knocked out. The figures are computed in
  `wordmark-spec.json` (`recommended.minPrint*`). The thinnest strokes are the e's top stroke and crossbar. Measured
  on the outline at 45, 50 and 55 % of each e's advance, their median is 7.38 units at font size 200 (cap 137), so
  the cap height must be at least 0.15 × 137 / 7.38 = 2.78 mm, rounded up to 2.8 mm. Both kits' guides quote these
  figures. (Before, the kits disagreed: Lamplight gave cap height 2 mm, 11.5 mm of ink, where the hairline is about
  0.11 mm; Door Ajar gave 17 mm wide, the file width from the same 0.15 mm rule.) This is an estimate from the
  geometry, not a test print.
- **Clear space:** at least one x-height around the ink.
- **White version:** same geometry as ink and black, so lockups stay identical. At small sizes, white on dusk reads
  a touch heavier (irradiation), which I judged acceptable. If a thinned reversed cut is ever wanted, rebuild with
  `WGHT = 430`. That changes the advance by a fraction of a percent, so the spec and lockups must be regenerated
  with it. I have not made one.
- Never re-set the word from the font for a lockup. The kerning and the overlap removal live in this outline, not
  in the font.

## Licence

- Newsreader is © 2020 The Newsreader Project Authors, licensed under the **SIL Open Font License 1.1**. The full
  text is copied to `OFL-Newsreader.txt`.
- Outlined lettering in a logo is permitted. The logo artwork is not the Font Software, and the OFL places no
  restriction on documents or artwork made with the font.
- The font file itself is not included in or redistributed by this kit.
- If the font is ever modified and redistributed, the modified version must stay under the OFL. It must not be
  sold by itself, and it must not use the font's Reserved Font Name. Newsreader's copyright line in the licence
  file declares no Reserved Font Name, so that clause is moot here, but the rule stands as a precaution.
- The logo design itself (the kerned, overlap-free outline) belongs to the Spanreed project, not to the font
  authors.

## Not verified / limits

- I did not hash the font or read its version or name table. The brief says to read the font only through the
  outline tool, and the tool does not report them. The font is identified by file name only:
  `Newsreader[opsz,wght].ttf`, 451,664 bytes, in `ROOT/_downloads/fonts/`.
- The OS/2 / hhea values the outline tool reports come from the default master and are not specific to opsz 36.
  The spec uses metrics measured from the glyphs instead (H, x, d, p) and records both.
- The only renderer was headless Chrome. I have not imported the SVG into Illustrator, Figma or Sketch, or tested a
  print or cut. I would expect them to work, since it is plain paths with no overlaps.
- Kerning was judged on screen only, not in print.
- I did not check trademark or name clearance for "Spanreed".
