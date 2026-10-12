"""Draw original concept geometry. All artwork uses filled vector paths."""

from pathlib import Path
import argparse

ROOT = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument("--version", type=int, default=1)
args = parser.parse_args()
V = args.version

SYMBOLS = {
    "a-scribe": (
        "Scribe",
        '<path d="M104 36 H220 L184 72 H104 C86.33 72 72 86.33 72 104 '
        'C72 121.67 86.33 136 104 136 H152 C189.56 136 220 154.8 220 180 '
        'C220 205.2 189.56 224 152 224 H36 L72 188 H152 C169.67 188 184 184.42 184 180 '
        'C184 175.58 169.67 172 152 172 H104 C66.44 172 36 141.56 36 104 '
        'C36 66.44 66.44 36 104 36 Z"/>',
    ),
    "b-twin-reeds": (
        "Twin reeds",
        '<path d="M32 208 C32 110.8 110.8 32 208 32 Z '
        'M224 48 C224 145.2 145.2 224 48 224 Z"/>',
    ),
    "c-return": (
        "Return",
        '<path d="M80 32 H176 C202.51 32 224 53.49 224 80 V176 '
        'C224 202.51 202.51 224 176 224 H80 C53.49 224 32 202.51 32 176 '
        'V152 H64 V176 C64 184.84 71.16 192 80 192 H176 '
        'C184.84 192 192 184.84 192 176 V80 C192 71.16 184.84 64 176 64 '
        'H80 C71.16 64 64 71.16 64 80 V104 H144 V136 H32 V80 '
        'C32 53.49 53.49 32 80 32 Z"/>',
    ),
}

if V >= 2:
    SYMBOLS["a-scribe"] = (
        "Scribe",
        '<path d="M104 32 H220 L184 68 H104 A20 20 0 0 0 104 108 '
        'H152 A58 58 0 0 1 152 224 H36 L72 188 H152 '
        'A22 22 0 0 0 152 144 H104 A56 56 0 0 1 104 32 Z"/>',
    )
    SYMBOLS["b-twin-reeds"] = (
        "Twin reeds",
        '<path d="M32 200 C32 107.22 107.22 32 200 32 Z '
        'M224 56 C224 148.78 148.78 224 56 224 Z"/>',
    )
    name, art = SYMBOLS["c-return"]
    SYMBOLS["c-return"] = (name, art.replace("V152 H64", "V160 H64"))

# Round letters overshoot their flat neighbours by 1.5 units.
LETTERS = {
    "s": (69, "M63 87 C55 80 44 76.5 33 76.5 C13 76.5 1 87 1 103 "
          "C1 119 13 125 32 130 C46 134 53 138 53 146 C53 156 44 162 32 162 "
          "C20 162 10 158 2 151 V168 C11 175 22 179.5 34 179.5 "
          "C55 179.5 69 167 69 149 C69 132 57 125 37 120 "
          "C23 116 17 112 17 104 C17 96 24 92 34 92 C44 92 55 96 63 103 Z"),
    "p": (80, "M0 78 H16 V88 C23 80 33 76.5 44 76.5 "
          "C67 76.5 80 96 80 128 C80 160 67 179.5 44 179.5 "
          "C33 179.5 23 175 16 168 V218 H0 Z "
          "M16 128 C16 150 24 164 42 164 C57 164 64 150 64 128 "
          "C64 106 57 92 42 92 C24 92 16 106 16 128 Z"),
    "a": (80, "M64 78 H80 V178 H64 V168 C57 175 47 179.5 36 179.5 "
          "C13 179.5 0 160 0 128 C0 96 13 76.5 36 76.5 "
          "C47 76.5 57 80 64 88 Z "
          "M16 128 C16 150 23 164 38 164 C56 164 64 150 64 128 "
          "C64 106 56 92 38 92 C23 92 16 106 16 128 Z"),
    "n": (78, "M0 78 H16 V90 C24 81 35 76.5 47 76.5 "
          "C67 76.5 78 89 78 111 V178 H62 V115 C62 99 55 92 43 92 "
          "C28 92 16 103 16 121 V178 H0 Z"),
    "r": (54, "M0 78 H16 V93 C24 81 35 76.5 47 76.5 H54 V93 H47 "
          "C29 93 16 107 16 127 V178 H0 Z"),
    "e": (80, "M80 132 H16 C17 152 28 164 45 164 C58 164 69 160 78 154 "
          "V171 C69 177 57 179.5 44 179.5 C17 179.5 0 159 0 128 "
          "C0 98 16 76.5 42 76.5 C67 76.5 80 95 80 122 Z "
          "M16 117 H64 C63 100 56 92 42 92 C28 92 19 102 16 117 Z"),
    "d": (80, "M64 36 H80 V178 H64 V168 C57 175 47 179.5 36 179.5 "
          "C13 179.5 0 160 0 128 C0 96 13 76.5 36 76.5 "
          "C47 76.5 57 80 64 88 Z "
          "M16 128 C16 150 23 164 38 164 C56 164 64 150 64 128 "
          "C64 106 56 92 38 92 C23 92 16 106 16 128 Z"),
}

def wordmark():
    x = 0
    chunks = []
    for letter in "spanreed":
        width, path = LETTERS[letter]
        chunks.append(f'<path transform="translate({x} 0)" fill-rule="evenodd" d="{path}"/>')
        x += width + 19
    return "".join(chunks), x - 19

wm, width = wordmark()
for slug, (name, art) in SYMBOLS.items():
    doc = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" '
           f'role="img" aria-labelledby="title"><title id="title">Spanreed, {name} concept</title>'
           f'<g fill="#000000">{art}</g></svg>\n')
    (ROOT / f"{slug}-v{V}.svg").write_text(doc)
    lockup = ('<svg xmlns="http://www.w3.org/2000/svg" '
              f'viewBox="0 0 {300 + width} 256" role="img" aria-labelledby="title">'
              f'<title id="title">Spanreed, {name} concept lockup</title>'
              f'<g fill="#000000"><g transform="translate(0 16) scale(0.875)">{art}</g>'
              f'<g transform="translate(284 0)">{wm}</g></g></svg>\n')
    (ROOT / f"{slug}-lockup-v{V}.svg").write_text(lockup)

print(f"Wrote three symbols and three outlined lockups, version {V}.")
