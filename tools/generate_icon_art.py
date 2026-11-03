"""Draw the coloured Construir/Armamentos icons and embed them for the client.

Original vector art made for Mundial War (no third-party assets). Each icon is a
64x64 SVG, rendered with rsvg-convert, packed into the same 5x5 atlas layout the
game already uses (assets/military/manifest.json order), then embedded as
src/client/MilitaryIconArt.lua (palette + run-length pixels), so the client builds
one EditableImage texture at runtime without any uploaded Roblox asset.

Outputs:
  assets/military/color/<kind>.svg / .png   the art, editable
  assets/military/military-atlas-color.png  320x320 atlas
  src/client/MilitaryIconArt.lua            embedded atlas for MilitaryIcons
"""
from pathlib import Path
import subprocess, io
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "military" / "color"
B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
ORDER = ["city", "factory", "port", "bunker", "tower", "machinegun", "artillery", "tankfactory",
         "airfield", "airdefense", "silo", "wall", "trench", "antinaval", "flak", "oilwell",
         "airlift", "airstrike", "cluster", "firebomb", "emp", "atomic", "hydrogen", "endofera",
         "biohazard"]

INK = "#141b24"
S = f'stroke="{INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"'
SHADOW = '<ellipse cx="32" cy="58" rx="22" ry="3.2" fill="#000" opacity="0.28"/>'

ART = {
    "city": f"""{SHADOW}
<rect x="7" y="30" width="15" height="26" rx="1.5" fill="#4fb3a9" {S}/>
<rect x="22" y="12" width="18" height="44" rx="1.5" fill="#4a86d4" {S}/>
<rect x="40" y="24" width="16" height="32" rx="1.5" fill="#e09a4a" {S}/>
<path d="M27 12 V7 h8 v5" fill="#8fb7ea" {S}/>
<g fill="#ffe08a">
<rect x="26" y="17" width="4" height="4"/><rect x="32" y="17" width="4" height="4"/>
<rect x="26" y="25" width="4" height="4"/><rect x="32" y="25" width="4" height="4"/>
<rect x="26" y="33" width="4" height="4"/><rect x="32" y="33" width="4" height="4"/>
<rect x="26" y="41" width="4" height="4"/><rect x="32" y="41" width="4" height="4"/>
<rect x="11" y="35" width="3" height="3"/><rect x="16" y="35" width="3" height="3"/>
<rect x="11" y="42" width="3" height="3"/><rect x="16" y="42" width="3" height="3"/>
<rect x="44" y="29" width="3" height="3"/><rect x="49" y="29" width="3" height="3"/>
<rect x="44" y="36" width="3" height="3"/><rect x="49" y="36" width="3" height="3"/>
<rect x="44" y="43" width="3" height="3"/><rect x="49" y="43" width="3" height="3"/>
</g>
<rect x="29" y="49" width="5" height="7" fill="#2a3a52"/>""",

    "factory": f"""{SHADOW}
<circle cx="46" cy="9" r="5" fill="#e6ebf0" {S}/><circle cx="54" cy="6" r="3.6" fill="#e6ebf0" {S}/>
<rect x="40" y="13" width="9" height="22" fill="#c4553f" {S}/>
<path d="M6 56 V30 L17 22 V30 L28 22 V30 L39 22 V56 Z" fill="#9aa6b2" {S}/>
<rect x="38" y="33" width="20" height="23" fill="#7d8996" {S}/>
<g fill="#ffd36b"><rect x="11" y="38" width="6" height="6"/><rect x="21" y="38" width="6" height="6"/><rect x="31" y="38" width="5" height="6"/></g>
<rect x="44" y="42" width="8" height="14" fill="#3c4652"/>
<path d="M40 19 h9 M40 25 h9" stroke="#8e3526" stroke-width="1.6"/>""",

    "port": f"""<path d="M4 56 q7 -5 14 0 t14 0 t14 0 t14 0 V62 H4Z" fill="#3e8fd0" {S}/>
<circle cx="32" cy="11" r="5.5" fill="none" {S.replace('2.4','6')}/><circle cx="32" cy="11" r="5.5" fill="none" stroke="#f2c14e" stroke-width="2.6"/>
<path d="M32 16 V50" stroke="{INK}" stroke-width="8"/><path d="M32 16 V50" stroke="#f2c14e" stroke-width="3.6"/>
<path d="M22 22 H42" stroke="{INK}" stroke-width="7.5"/><path d="M22 22 H42" stroke="#f2c14e" stroke-width="3.2"/>
<path d="M12 36 Q14 50 32 52 Q50 50 52 36" fill="none" stroke="{INK}" stroke-width="8"/>
<path d="M12 36 Q14 50 32 52 Q50 50 52 36" fill="none" stroke="#f2c14e" stroke-width="3.6"/>
<path d="M7 38 L12 31 L17 38Z M47 38 L52 31 L57 38Z" fill="#f2c14e" {S}/>""",

    "bunker": f"""{SHADOW}
<path d="M8 50 Q8 22 32 20 Q56 22 56 50 Z" fill="#6f8a4a" {S}/>
<path d="M16 34 Q32 28 48 34" fill="none" stroke="#56703a" stroke-width="2"/>
<rect x="20" y="36" width="24" height="5" rx="2" fill="#1b2128"/>
<g fill="#cdb889" {S}>
<rect x="4" y="48" width="14" height="8" rx="3.5"/><rect x="18" y="48" width="14" height="8" rx="3.5"/>
<rect x="32" y="48" width="14" height="8" rx="3.5"/><rect x="46" y="48" width="14" height="8" rx="3.5"/>
</g>""",

    "tower": f"""{SHADOW}
<path d="M18 57 L24 28 M46 57 L40 28 M21 44 H43 M20 50 L44 38 M44 50 L20 38" stroke="{INK}" stroke-width="5" fill="none"/>
<path d="M18 57 L24 28 M46 57 L40 28 M21 44 H43 M20 50 L44 38 M44 50 L20 38" stroke="#a66f3f" stroke-width="2.6" fill="none"/>
<rect x="17" y="18" width="30" height="12" fill="#c88a50" {S}/>
<path d="M13 19 L32 7 L51 19 Z" fill="#c4553f" {S}/>
<rect x="22" y="21" width="20" height="5" fill="#1b2128"/>
<circle cx="48" cy="44" r="9" fill="#fff" fill-opacity="0.92" {S}/>
<path d="M48 36 V52 M40 44 H56" stroke="#d23b3b" stroke-width="2.2"/><circle cx="48" cy="44" r="3.4" fill="none" stroke="#d23b3b" stroke-width="2"/>""",

    "machinegun": f"""{SHADOW}
<path d="M24 38 L12 57 M28 38 L32 57 M30 38 L46 57" stroke="{INK}" stroke-width="5"/>
<path d="M24 38 L12 57 M28 38 L32 57 M30 38 L46 57" stroke="#6b7480" stroke-width="2.4"/>
<rect x="14" y="24" width="24" height="14" rx="3" fill="#4b5563" {S}/>
<rect x="36" y="27" width="24" height="6" rx="2" fill="#2f3742" {S}/>
<rect x="6" y="27" width="10" height="9" rx="2" fill="#7a4f2e" {S}/>
<path d="M18 38 q3 8 0 14 M22 38 q3 8 0 14" stroke="#e0b44a" stroke-width="3" fill="none"/>
<rect x="22" y="18" width="10" height="7" rx="2" fill="#38414c" {S}/>""",

    "artillery": f"""{SHADOW}
<path d="M24 38 L58 10" stroke="{INK}" stroke-width="11" stroke-linecap="round"/>
<path d="M24 38 L58 10" stroke="#5f7d3c" stroke-width="6" stroke-linecap="round"/>
<path d="M10 46 L28 34 L42 44 L20 52 Z" fill="#6f8f45" {S}/>
<path d="M8 54 L20 46" stroke="{INK}" stroke-width="5"/><path d="M8 54 L20 46" stroke="#556b35" stroke-width="2.4"/>
<circle cx="24" cy="48" r="9" fill="#3a3f45" {S}/><circle cx="24" cy="48" r="3.4" fill="#9aa6b2"/>
<circle cx="42" cy="48" r="8" fill="#3a3f45" {S}/><circle cx="42" cy="48" r="3" fill="#9aa6b2"/>""",

    "tankfactory": f"""{SHADOW}
<path d="M30 26 H60" stroke="{INK}" stroke-width="7" stroke-linecap="round"/><path d="M30 26 H60" stroke="#5c7a38" stroke-width="3.4" stroke-linecap="round"/>
<path d="M18 20 Q20 14 32 14 Q42 14 42 20 L44 30 H16 Z" fill="#6f8f45" {S}/>
<path d="M6 34 H58 L52 42 H12 Z" fill="#7d9c50" {S}/>
<rect x="6" y="42" width="52" height="13" rx="6.5" fill="#3a3f45" {S}/>
<g fill="#9aa6b2"><circle cx="14" cy="48.5" r="3.4"/><circle cx="24" cy="48.5" r="3.4"/><circle cx="34" cy="48.5" r="3.4"/><circle cx="44" cy="48.5" r="3.4"/><circle cx="52" cy="48.5" r="3"/></g>
<circle cx="29" cy="21" r="3" fill="#f2c14e" {S.replace('2.4','1.4')}/>""",

    "airfield": f"""<path d="M14 60 L24 8 H40 L50 60 Z" fill="#59626d" {S}/>
<path d="M32 12 V56" stroke="#f0f3f6" stroke-width="2.4" stroke-dasharray="5 4"/>
<path d="M32 10 C35 10 36 14 36 20 L36 26 L56 36 V42 L36 37 V48 L42 53 V57 L32 54 L22 57 V53 L28 48 V37 L8 42 V36 L28 26 L28 20 C28 14 29 10 32 10 Z" fill="#e8eef5" {S}/>
<path d="M30 16 h4" stroke="#4a86d4" stroke-width="3"/>""",

    "airdefense": f"""{SHADOW}
<path d="M44 12 a14 14 0 0 1 10 10 M47 6 a20 20 0 0 1 13 13" fill="none" stroke="#4fd1e0" stroke-width="3" stroke-linecap="round"/>
<path d="M26 44 L22 56 H42 L38 44 Z" fill="#7d8996" {S}/>
<path d="M10 30 A20 20 0 0 0 44 16 Z" fill="#e8eef5" {S}/>
<path d="M27 23 L40 12" stroke="{INK}" stroke-width="2.4"/><circle cx="41" cy="11" r="3" fill="#d23b3b" {S.replace('2.4','1.6')}/>
<path d="M27 26 V44" stroke="{INK}" stroke-width="6"/><path d="M27 26 V44" stroke="#9aa6b2" stroke-width="2.6"/>""",

    "silo": f"""<rect x="10" y="40" width="44" height="18" rx="2" fill="#8d96a0" {S}/>
<rect x="20" y="40" width="24" height="6" fill="#4b5563"/>
<path d="M32 4 C38 10 40 16 40 24 V44 H24 V24 C24 16 26 10 32 4 Z" fill="#f0f3f6" {S}/>
<path d="M32 4 C36 8 38 12 39 16 H25 C26 12 28 8 32 4 Z" fill="#d23b3b" {S}/>
<path d="M24 36 L17 44 H24 Z M40 36 L47 44 H40 Z" fill="#d23b3b" {S}/>
<rect x="30" y="22" width="4" height="10" rx="1" fill="#4a86d4"/>
<path d="M14 52 H50" stroke="#f2c14e" stroke-width="2.2" stroke-dasharray="4 3"/>""",

    "wall": f"""{SHADOW}
<path d="M4 18 h8 v-6 h8 v6 h8 v-6 h8 v6 h8 v-6 h8 v6 h8 V56 H4 Z" fill="#b5653f" {S}/>
<g stroke="#7a3d24" stroke-width="1.8" fill="none">
<path d="M4 27 H60 M4 36 H60 M4 45 H60"/>
<path d="M18 18 V27 M36 18 V27 M50 18 V27 M10 27 V36 M27 27 V36 M44 27 V36 M18 36 V45 M36 36 V45 M50 36 V45 M10 45 V56 M27 45 V56 M44 45 V56"/>
</g>""",

    "trench": f"""<path d="M2 44 Q32 34 62 44 V62 H2 Z" fill="#6b4a2e" {S}/>
<path d="M14 50 Q32 44 50 50 L48 58 Q32 54 16 58 Z" fill="#3b2a1b"/>
<g fill="#d8c08a" {S}>
<rect x="6" y="34" width="16" height="9" rx="4.5"/><rect x="24" y="32" width="16" height="9" rx="4.5"/><rect x="42" y="34" width="16" height="9" rx="4.5"/>
<rect x="14" y="24" width="16" height="9" rx="4.5"/><rect x="33" y="24" width="16" height="9" rx="4.5"/>
</g>
<path d="M30 20 V8 L42 12 L30 16" fill="#d23b3b" {S}/>""",

    "antinaval": f"""<path d="M2 54 q7 -5 14 0 t14 0 t14 0 t14 0 V62 H2Z" fill="#3e8fd0" {S}/>
<path d="M8 52 L14 36 H40 L48 52 Z" fill="#7d8996" {S}/>
<path d="M28 34 L58 22" stroke="{INK}" stroke-width="10" stroke-linecap="round"/><path d="M28 34 L58 22" stroke="#4b5563" stroke-width="5" stroke-linecap="round"/>
<path d="M18 38 Q18 26 30 26 Q38 27 38 38 Z" fill="#5c6672" {S}/>
<path d="M54 8 l2 5 5 1 -4 3 1 5 -4 -3 -4 3 1 -5 -4 -3 5 -1z" fill="#ffb03b" {S.replace('2.4','1.4')}/>""",

    "flak": f"""{SHADOW}
<path d="M28 34 L14 6 M36 34 L50 6" stroke="{INK}" stroke-width="8" stroke-linecap="round"/>
<path d="M28 34 L14 6 M36 34 L50 6" stroke="#4b5563" stroke-width="4" stroke-linecap="round"/>
<g fill="#cfd5db" {S.replace('2.4','1.6')}><circle cx="9" cy="10" r="4.5"/><circle cx="56" cy="9" r="4.5"/><circle cx="32" cy="8" r="3.4"/></g>
<path d="M16 46 Q16 30 32 30 Q48 30 48 46 Z" fill="#6f8f45" {S}/>
<rect x="8" y="46" width="48" height="10" rx="3" fill="#556b35" {S}/>""",

    "oilwell": f"""{SHADOW}
<path d="M18 56 L28 26 L38 56" fill="none" stroke="{INK}" stroke-width="6"/><path d="M18 56 L28 26 L38 56" fill="none" stroke="#7d8996" stroke-width="2.8"/>
<path d="M8 22 L50 14" stroke="{INK}" stroke-width="9" stroke-linecap="round"/><path d="M8 22 L50 14" stroke="#e0a43a" stroke-width="4.6" stroke-linecap="round"/>
<path d="M50 10 Q60 14 54 24 L48 22 Q52 16 46 14 Z" fill="#e0a43a" {S}/>
<path d="M52 24 V44" stroke="{INK}" stroke-width="2.4"/>
<rect x="46" y="44" width="12" height="12" fill="#5c6672" {S}/>
<circle cx="28" cy="24" r="3.4" fill="#3a3f45" {S.replace('2.4','1.6')}/>
<path d="M14 36 C14 36 8 44 8 48 a6 6 0 0 0 12 0 C20 44 14 36 14 36 Z" fill="#1b1f24" {S.replace(INK,'#e8eef5').replace('2.4','1.6')}/>""",

    "airlift": f"""<path d="M8 26 Q32 -2 56 26 Q50 21 44 26 Q38 21 32 26 Q26 21 20 26 Q14 21 8 26 Z" fill="#f08a3c" {S}/>
<path d="M20 26 Q26 10 32 4 Q38 10 44 26" fill="none" stroke="#c4622a" stroke-width="1.8"/>
<path d="M10 26 L26 44 M54 26 L38 44 M32 26 V44" stroke="{INK}" stroke-width="1.6"/>
<rect x="22" y="42" width="20" height="16" rx="2" fill="#a8763f" {S}/>
<path d="M22 50 H42 M32 42 V58" stroke="#7a5229" stroke-width="2"/>""",

    "airstrike": f"""<path d="M32 4 C35 4 36 9 36 14 V22 L58 34 V40 L36 34 V46 L44 52 V57 L32 53 L20 57 V52 L28 46 V34 L6 40 V34 L28 22 V14 C28 9 29 4 32 4 Z" fill="#8d9aa8" {S}/>
<path d="M30 10 h4" stroke="#4a86d4" stroke-width="3"/>
<path d="M14 36 v6 M50 36 v6" stroke="{INK}" stroke-width="2.4"/>
<circle cx="14" cy="45" r="3.4" fill="#d23b3b" {S.replace('2.4','1.6')}/><circle cx="50" cy="45" r="3.4" fill="#d23b3b" {S.replace('2.4','1.6')}/>""",

    "cluster": f"""<path d="M24 4 H40 L36 12 H28 Z" fill="#6b7480" {S}/>
<path d="M32 10 V14" stroke="{INK}" stroke-width="2.4"/>
<path d="M32 12 C42 12 46 20 46 28 C46 38 40 44 32 44 C24 44 18 38 18 28 C18 20 22 12 32 12 Z" fill="#4b5563" {S}/>
<path d="M18 26 H46" stroke="#f2c14e" stroke-width="3"/>
<path d="M24 20 C26 17 28 16 31 16" stroke="#8d96a0" stroke-width="2.4" fill="none" stroke-linecap="round"/>
<g fill="#f2c14e" {S.replace('2.4','1.8')}>
<circle cx="12" cy="48" r="4"/><circle cx="24" cy="54" r="4"/><circle cx="40" cy="54" r="4"/><circle cx="52" cy="48" r="4"/><circle cx="32" cy="59" r="3"/>
</g>
<path d="M18 44 L14 46 M26 47 L25 50 M38 47 L39 50 M46 44 L50 46" stroke="#f2a03a" stroke-width="2" stroke-linecap="round"/>""",

    "firebomb": f"""{SHADOW}
<path d="M32 4 C36 14 48 20 48 36 C48 48 40 56 32 56 C24 56 16 48 16 38 C16 28 22 24 24 16 C28 22 28 26 30 28 C32 20 30 12 32 4 Z" fill="#f2672e" {S}/>
<path d="M32 26 C36 32 42 36 42 44 C42 50 38 54 32 54 C26 54 22 50 22 45 C22 40 26 38 27 33 C29 36 30 38 31 39 C33 34 32 30 32 26 Z" fill="#ffc23d"/>
<path d="M32 40 C34 44 36 46 36 49 C36 52 34 54 32 54 C30 54 28 52 28 50 C28 47 31 45 32 40 Z" fill="#fff3c4"/>""",

    "emp": f"""<circle cx="32" cy="32" r="26" fill="#1d3a5c" {S}/>
<circle cx="32" cy="32" r="20" fill="none" stroke="#4fd1e0" stroke-width="2" stroke-dasharray="3 4"/>
<path d="M36 6 L18 36 H30 L26 58 L46 26 H34 Z" fill="#ffe34d" {S}/>""",

    "atomic": f"""<circle cx="32" cy="32" r="27" fill="#ffd23d" {S}/>
<circle cx="32" cy="32" r="5" fill="{INK}"/>
<g fill="{INK}">
<path d="M32 32 L20.5 12.1 A23 23 0 0 1 43.5 12.1 Z" transform="rotate(0 32 32)"/>
<path d="M32 32 L20.5 12.1 A23 23 0 0 1 43.5 12.1 Z" transform="rotate(120 32 32)"/>
<path d="M32 32 L20.5 12.1 A23 23 0 0 1 43.5 12.1 Z" transform="rotate(240 32 32)"/>
</g>
<circle cx="32" cy="32" r="8.5" fill="#ffd23d"/><circle cx="32" cy="32" r="5" fill="{INK}"/>""",

    "hydrogen": f"""<path d="M8 58 Q8 50 22 50 H42 Q56 50 56 58 Z" fill="#8d4a2a" {S}/>
<path d="M26 52 L28 30 H36 L38 52 Z" fill="#e0763a" {S}/>
<path d="M32 4 C46 4 56 10 56 20 C56 28 48 32 40 30 C38 34 26 34 24 30 C16 32 8 28 8 20 C8 10 18 4 32 4 Z" fill="#f2672e" {S}/>
<path d="M18 18 C22 12 30 10 36 12 C44 12 48 16 48 20" fill="none" stroke="#ffc23d" stroke-width="3.2" stroke-linecap="round"/>
<path d="M14 40 H50" stroke="#f2a03a" stroke-width="3" stroke-linecap="round"/>""",

    "endofera": f"""<circle cx="32" cy="34" r="24" fill="#3e8fd0" {S}/>
<path d="M14 24 C20 20 24 26 30 24 C34 30 28 36 22 34 C18 38 12 34 12 30 Z M36 14 C42 12 48 18 46 24 C50 28 52 36 48 40 C42 38 40 30 36 28 C34 22 32 18 36 14 Z M26 44 C32 42 38 46 36 52 C30 54 24 50 26 44 Z" fill="#5fae4e"/>
<path d="M32 6 L36 22 L44 18 L38 32 L48 34 L36 40 L40 56 L30 42 L22 50 L24 38 L12 36 L24 30 L18 18 L28 24 Z" fill="#ff5a3c" fill-opacity="0.9" {S.replace('2.4','1.6')}/>
<circle cx="32" cy="32" r="5" fill="#fff3c4"/>""",

    "biohazard": f"""<circle cx="32" cy="32" r="27" fill="#9be05a" {S}/>
<g fill="none" stroke="{INK}" stroke-width="5">
<circle cx="32" cy="19" r="9"/><circle cx="20.7" cy="38.5" r="9"/><circle cx="43.3" cy="38.5" r="9"/>
</g>
<circle cx="32" cy="32" r="5" fill="{INK}"/>""",
}


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{body}</svg>'


def b62(n, width):
    out = ""
    for _ in range(width):
        out = B62[n % 62] + out
        n //= 62
    assert n == 0
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    for i, kind in enumerate(ORDER):
        src = svg(ART[kind])
        (OUT / f"{kind}.svg").write_text(src)
        png = subprocess.run(["rsvg-convert", "-w", "64", "-h", "64"], input=src.encode(),
                             capture_output=True, check=True).stdout
        im = Image.open(io.BytesIO(png)).convert("RGBA")
        im.save(OUT / f"{kind}.png")
        atlas.paste(im, ((i % 5) * 64, (i // 5) * 64))
    atlas.save(ROOT / "assets" / "military" / "military-atlas-color.png")

    # palette: snap alpha to 5 levels, quantize colour; index 0 = transparent
    px = list(atlas.get_flattened_data())
    rgb = Image.new("RGB", atlas.size)
    rgb.putdata([(r, g, b) for r, g, b, a in px])
    q = rgb.quantize(colors=60, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    qpal = q.getpalette()
    qidx = list(q.get_flattened_data())
    entries, codes = {(0, 0, 0, 0): 0}, []
    palette = [(0, 0, 0, 0)]
    for (r, g, b, a), k in zip(px, qidx):
        a5 = min(4, round(a / 255 * 4))
        if a5 == 0:
            codes.append(0)
            continue
        key = (qpal[k * 3], qpal[k * 3 + 1], qpal[k * 3 + 2], a5 * 255 // 4)
        if key not in entries:
            entries[key] = len(palette)
            palette.append(key)
        codes.append(entries[key])
    assert len(palette) <= 62 * 62
    width = 1 if len(palette) <= 62 else 2

    runs, i = [], 0
    while i < len(codes):
        j = i + 1
        while j < len(codes) and codes[j] == codes[i] and j - i < 3843:
            j += 1
        runs.append(b62(codes[i], width) + b62(j - i, 2))
        i = j
    data = "".join(runs)
    chunks = [data[k:k + 4000] for k in range(0, len(data), 4000)]
    lua = ["-- GENERATED by tools/generate_icon_art.py: coloured Construir/Armamentos icons.",
           "-- Original art for Mundial War. 320x320 RGBA atlas, 5x5 tiles of 64px in",
           "-- assets/military/manifest.json order; palette index runs (see Width).",
           "return {",
           "\tSize = 320,",
           f"\tWidth = {width},",
           "\tPalette = {"]
    for k in range(0, len(palette), 6):
        lua.append("\t\t" + " ".join("{ %d, %d, %d, %d }," % p for p in palette[k:k + 6]))
    lua += ["\t},", "\tRuns = table.concat({"]
    lua += [f'\t\t"{c}",' for c in chunks]
    lua += ["\t}),", "}", ""]
    out = ROOT / "src" / "client" / "MilitaryIconArt.lua"
    out.write_text("\n".join(lua))
    print(f"{len(palette)} colours, {len(runs)} runs, {out.stat().st_size // 1024} KB")

    # sheet preview on the card colour at the in-game sizes
    sheet = Image.new("RGBA", (5 * 84, 5 * 84), (30, 40, 52, 255))
    for i, kind in enumerate(ORDER):
        im = Image.open(OUT / f"{kind}.png")
        sheet.alpha_composite(im, ((i % 5) * 84 + 10, (i // 5) * 84 + 10))
    sheet.save(ROOT / "assets" / "military" / "color-preview.png")


if __name__ == "__main__":
    main()
