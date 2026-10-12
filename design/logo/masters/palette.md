# Spanreed · Door Ajar palette

Family hexes = round-1 starting palette, unchanged, so the Door Ajar and Lamplight kits stay one family. Family hexes, names, keys and order, and every RGB / CMYK / Lab / Pantone number of a family colour, come from kit/shared/palette/spanreed_palette.py (shared by Door Ajar and Lamplight). CMYK is a naive device conversion (K = 1 − max(R,G,B); C = (1−R−K)/(1−K), …) with no ICC profile: for print, convert from sRGB in a colour-managed app with the printer's profile (e.g. PSO Coated v3 / GRACoL 2013) and proof. Pantone matches are the nearest CIEDE2000 hit in the shared table of approximate sRGB previews (kit/shared/palette/pantone_approx.py), not an official Pantone library: verify every one against a physical Pantone Formula Guide (Solid Coated) before print.

## Family (brand colours, shared with Lamplight)

Shared columns are identical in `kit/lamplight/masters/palette.md` (same order, same numbers); only the Role column is this kit's own.

| Name | HEX | RGB | CMYK (naive) | L* | Nearest Pantone C (approx., verify) | ΔE00 | Match | Role |
|---|---|---|---|---|---|---|---|---|
| Dusk | `#46546E` | 70 84 110 | 36 24 0 57 | 35.5 | PANTONE 7545 C | 7.1 | no close solid | Primary brand colour. App-icon wall (top of the gradient); brand backgrounds; reversed mark sits on it. |
| Dusk Deep | `#2C3548` | 44 53 72 | 39 26 0 72 | 22.1 | PANTONE 533 C | 4.7 | noticeable | Bottom of the dusk gradient; the family's flat dark brand ground (use -white on it); icon floor (top) and frame (bottom). |
| Ink | `#26303F` | 38 48 63 | 40 24 0 75 | 19.6 | PANTONE 7546 C | 4.0 | noticeable | The door. One-colour mark on light grounds, wordmark (the shared wordmark colour), type. |
| Ink Deep | `#1D2532` | 29 37 50 | 42 26 0 80 | 14.5 | PANTONE 7547 C | 3.2 | noticeable | Darkest ground (dark-mode surfaces): the ground for -color-dark; bottom of the door gradient; icon floor (bottom). |
| Warm Light | `#FFE2A3` | 255 226 163 | 0 11 36 0 | 90.9 | PANTONE 7401 C | 2.7 | noticeable | The light: caret and knob in the -color-dark files; top of the icon's light gradient. |
| Warm Light Deep | `#F4B862` | 244 184 98 | 0 25 60 4 | 78.7 | PANTONE 1365 C | 3.6 | noticeable | The light, bottom of its icon gradient; floor spill (icon only). |
| Paper | `#F7F2E8` | 247 242 232 | 0 2 6 3 | 95.6 | PANTONE Cool Gray 1 C | 6.6 | no close solid | Light ground; the wordmark in the -color-dark files; the dark-mode favicon. |
| Paper Deep | `#EAE1D0` | 234 225 208 | 0 4 11 8 | 89.8 | PANTONE 7527 C | 4.3 | noticeable | Secondary light ground, cards, print stock tint. |
| Amber | `#F0A94B` | 240 169 75 | 0 30 69 6 | 74.5 | PANTONE 7410 C | 3.5 | noticeable | Accent: the light and the knob in flat colour artwork; small highlights. Never as text on Paper. |
| Slate | `#2F3644` | 47 54 68 | 31 21 0 73 | 22.5 | PANTONE 7546 C | 4.6 | noticeable | Shared family neutral (UI text, secondary). Not used in the Door Ajar artwork. |

## Door Ajar only

Not a family colour: Lamplight does not use it. Same columns, same shared matcher.

| Name | HEX | RGB | CMYK (naive) | L* | Nearest Pantone C (approx., verify) | ΔE00 | Match | Role |
|---|---|---|---|---|---|---|---|---|
| Dusk Light | `#55647F` | 85 100 127 | 33 21 0 50 | 42.1 | PANTONE 431 C | 8.1 | no close solid | Door Ajar only: the door in the -color-dark files; the wall of the 16/32 px icon cut and the favicon tile. |

ΔE00 ≤ 2 is a close match, 2–6 noticeable, > 6 means no close solid in the table. No close solid: Dusk (7.1), Paper (6.6), Dusk Light (8.1). Paper is best reproduced as a warm off-white stock, or unprinted.

## Icon-only shades (derived, not brand colours)

| Name | Top | Bottom | Use |
|---|---|---|---|
| Frame (architrave) | `#37435B` | `#2C3548` | Doorway frame in the 1024 icon: lighter than the slab, darker than the wall (reads as a recessed doorway). |
| Floor | `#2C3548` | `#222A39` | Floor below the horizon in the icon. |
| Brass knob | `#EFCB8A` | `#C9944F` | Knob gradient in the 1024 icon. |
| Small-cut wall | `#55647F` | `#3A4660` | Wall of the 16/32 px icon cut and the favicon tile (top = Dusk Light): lifted so the door separates at 16 px. |
| Small-cut knob | `#E3AE5E` | — | Flat knob of the 16/32 px icon cut. |

## Contrast (WCAG 2.x, computed)

Logos are exempt from WCAG, but any text, and the mark as a meaningful graphic, should reach 3 : 1.

| Pair | FG | BG | Ratio | ≥ 3 | ≥ 4.5 | ≥ 7 | ΔL* (greyscale) |
|---|---|---|---|---|---|---|---|
| Ink mark / type on Paper | `#26303F` | `#F7F2E8` | 11.93 : 1 | yes | yes | yes | 76.0 |
| Ink mark / type on white | `#26303F` | `#FFFFFF` | 13.32 : 1 | yes | yes | yes | 80.4 |
| Paper (reversed) on Ink Deep | `#F7F2E8` | `#1D2532` | 13.81 : 1 | yes | yes | yes | 81.1 |
| White reversed mark on Dusk | `#FFFFFF` | `#46546E` | 7.63 : 1 | yes | yes | yes | 64.5 |
| Paper on Dusk | `#F7F2E8` | `#46546E` | 6.83 : 1 | yes | yes | no | 60.1 |
| Amber light / knob inside the Ink door | `#F0A94B` | `#26303F` | 6.65 : 1 | yes | yes | no | 54.9 |
| Warm Light in the gap against the slab | `#FFE2A3` | `#26303F` | 10.56 : 1 | yes | yes | yes | 71.3 |
| Warm Light Deep spill on the floor | `#F4B862` | `#2C3548` | 6.95 : 1 | yes | yes | no | 56.6 |
| Warm Light caret / knob inside the Dusk Light door (-color-dark) | `#FFE2A3` | `#55647F` | 4.74 : 1 | yes | yes | no | 48.8 |
| Dusk Light door on Ink Deep (-color-dark) | `#55647F` | `#1D2532` | 2.58 : 1 | no | no | no | 27.6 |
| Dusk Light door on near-black #0D1117 (-color-dark) | `#55647F` | `#0D1117` | 3.17 : 1 | yes | no | no | 37.2 |
| Dusk Light door on Dusk Deep (not approved: use -white) | `#55647F` | `#2C3548` | 2.06 : 1 | no | no | no | 20.0 |
| Amber inside a Paper door (old -color-dark scheme, replaced) | `#F0A94B` | `#F7F2E8` | 1.8 : 1 | no | no | no | 21.2 |
| Amber on white (never for text) | `#F0A94B` | `#FFFFFF` | 2.0 : 1 | no | no | no | 25.5 |
| Slate text on Paper | `#2F3644` | `#F7F2E8` | 10.87 : 1 | yes | yes | yes | 73.1 |
| Dusk on Paper | `#46546E` | `#F7F2E8` | 6.83 : 1 | yes | yes | no | 60.1 |
| Door slab against the wall (icon) | `#26303F` | `#46546E` | 1.75 : 1 | no | no | no | 16.0 |
| Icon frame vs slab (depth step) | `#37435B` | `#26303F` | 1.34 : 1 | no | no | no | 8.8 |
| Small-cut slab vs small-cut wall | `#1D2532` | `#55647F` | 2.58 : 1 | no | no | no | 27.6 |

## Greyscale separation

Ordered by CIE L* (what survives a greyscale or colour-blind view):

-  95.6  Paper `#F7F2E8`
-  90.9  Warm Light `#FFE2A3`
-  89.8  Paper Deep `#EAE1D0`
-  78.7  Warm Light Deep `#F4B862`
-  74.5  Amber `#F0A94B`
-  42.1  Dusk Light `#55647F`
-  35.5  Dusk `#46546E`
-  22.5  Slate `#2F3644`
-  22.1  Dusk Deep `#2C3548`
-  19.6  Ink `#26303F`
-  14.5  Ink Deep `#1D2532`

The mark depends on two value steps only: the dark door (Ink, L* 19.6) against a light ground or the light (Amber / Warm Light, L* 74.5-90.9), and, in the icon, the door against the Dusk wall (ΔL* 16.0; lifted to 27.6 in the 16/32 px cut, whose wall is lighter). On dark grounds the order of values is kept: the -color-dark files use a Dusk Light door (L* 42.1) between the dark ground (Ink Deep, L* 14.5) and the light (Warm Light, L* 90.9), so the light is always the brightest part of the mark (4.74 : 1 inside the door). The door itself is quiet on Ink Deep (2.58 : 1) and too weak on Dusk Deep (2.06 : 1) or Dusk: use -white there. (The earlier -color-dark, a Paper door with an Amber light, put the light 21.2 L* *below* the door.)
