"""Generate the Mundial War terrain layer (what the land and sea LOOK like).

Inputs (public domain, NASA Visible Earth via the three-globe examples):
  data/nasa/earth-day-1600.jpg     summer satellite colour with shaded relief, equirectangular
  data/nasa/topology-2048.png      elevation, equirectangular (0 = sea level)
  data/world-map.json              the game grid (from tools/generate_map.py)

Output:
  src/shared/MapTerrain.lua        per-cell terrain code, run-length encoded
  data/terrain-preview.png         the neutral world as the client paints it

Each cell gets one code (one base62 char):
  0      water (one flat sea colour, the game's usual blue)
  5..    land: 5 + tone * 3 + shade  (tone = satellite colour cluster,
         shade 0/1/2 = hillshade dark/flat/lit from the north-west)
Only the client uses this module; the rules never read it.
"""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
LAT_TOP = 84.0
SS = 4
TONES = 19              # 5 + 19*3 = 62 codes, exactly one base62 char
SHADE = (0.86, 1.0, 1.1)
WATER = [(46, 92, 138)]  # Palette.Water: the sea is one flat colour


def b62(n, width):
    out = ""
    for _ in range(width):
        out = B62[n % 62] + out
        n //= 62
    assert n == 0
    return out


def miller(lat):
    return 1.25 * math.log(math.tan(math.pi / 4 + 0.4 * math.radians(lat)))


def decode_grid(data):
    W, H = data["width"], data["height"]
    grid = np.zeros((H, W), dtype=np.int32)
    for y, row in enumerate(data["rows"]):
        x = 0
        for k in range(0, len(row), 4):
            v = B62.index(row[k]) * 62 + B62.index(row[k + 1])
            n = B62.index(row[k + 2]) * 62 + B62.index(row[k + 3])
            grid[y, x:x + n] = v
            x += n
        assert x == W
    return grid


def sample_coords(W, H, img_w, img_h):
    """Pixel coordinates in an equirectangular image for SS x SS samples per cell."""
    y_top = miller(LAT_TOP)
    y_span = 2 * math.pi * H / W
    fy = (np.arange(H * SS) + 0.5) / (H * SS)
    my = y_top - fy * y_span
    lat = np.degrees(2.5 * np.arctan(np.exp(0.8 * my)) - 0.625 * np.pi)
    lon = (np.arange(W * SS) + 0.5) / (W * SS) * 360.0 - 180.0
    px = np.clip(((lon + 180.0) / 360.0 * img_w).astype(int), 0, img_w - 1)
    py = np.clip(((90.0 - lat) / 180.0 * img_h).astype(int), 0, img_h - 1)
    return px, py


def per_cell(img, W, H):
    arr = np.asarray(img, dtype=np.float32)
    px, py = sample_coords(W, H, arr.shape[1], arr.shape[0])
    s = arr[py][:, px]                                   # (H*SS, W*SS[, C])
    if s.ndim == 2:
        s = s[..., None]
    s = s.reshape(H, SS, W, SS, s.shape[-1]).transpose(0, 2, 1, 3, 4).reshape(H, W, SS * SS, -1)
    return s


def kmeans(x, k, iters=30, seed=7):
    rng = np.random.default_rng(seed)
    c = x[rng.choice(len(x), k, replace=False)].copy()
    for _ in range(iters):
        d = ((x[:, None, :] - c[None, :, :]) ** 2).sum(-1)
        lab = d.argmin(1)
        for j in range(k):
            m = lab == j
            if m.any():
                c[j] = x[m].mean(0)
    d = ((x[:, None, :] - c[None, :, :]) ** 2).sum(-1)
    return c, d.argmin(1)


def stylize(rgb):
    """Satellite colours -> the bright, slightly pastel look of a strategy map."""
    c = np.clip(rgb / 255.0, 0, 1) ** 0.8
    lum = c.mean(-1, keepdims=True)
    c = lum + (c - lum) * 1.05
    paper = np.array([0.93, 0.89, 0.79])
    c = c * 0.84 + paper * 0.16
    return np.clip(c * 255, 0, 255)


def main():
    data = json.loads((ROOT / "data" / "world-map.json").read_text())
    W, H = data["width"], data["height"]
    grid = decode_grid(data)
    land = grid > 0

    # --- satellite colour per land cell, ignoring samples that are sea in the photo
    s = per_cell(Image.open(ROOT / "data" / "nasa" / "earth-day-1600.jpg").convert("RGB"), W, H)
    r, g, b = s[..., 0], s[..., 1], s[..., 2]
    sea_like = (b > r + 40) & (b > g + 10)
    ok = ~sea_like
    cnt = ok.sum(-1)
    col = np.where(cnt[..., None] > 0,
                   (s * ok[..., None]).sum(2) / np.maximum(cnt, 1)[..., None],
                   np.nan)
    col[~land] = np.nan
    # fill land cells with no usable sample from the nearest coloured cell
    missing = land & np.isnan(col[..., 0])
    if missing.any():
        idx = ndimage.distance_transform_edt(np.isnan(col[..., 0]), return_distances=False, return_indices=True)
        col[missing] = col[idx[0][missing], idx[1][missing]]
    col[~land] = 0

    sty = stylize(col)
    # gentle smoothing so tones form regions, not speckle
    for ch in range(3):
        sm = ndimage.uniform_filter(np.where(land, sty[..., ch], 0), 3)
        wt = ndimage.uniform_filter(land.astype(float), 3)
        sty[..., ch] = np.where(land, 0.55 * sty[..., ch] + 0.45 * sm / np.maximum(wt, 1e-6), 0)

    pts = sty[land]
    centres, lab = kmeans(pts, TONES)
    order = np.argsort(centres.mean(1))                 # dark -> light, stable codes
    rank = np.empty(TONES, dtype=int)
    rank[order] = np.arange(TONES)
    centres = centres[order]
    tone = np.zeros((H, W), dtype=int)
    tone[land] = rank[lab]
    # majority filter removes single-cell noise inside regions
    votes = np.stack([ndimage.uniform_filter((tone == t).astype(float) * land, 3) for t in range(TONES)])
    tone = np.where(land, votes.argmax(0), 0)

    # --- hillshade from the elevation map
    e = per_cell(Image.open(ROOT / "data" / "nasa" / "topology-2048.png").convert("L"), W, H)[..., 0].mean(-1)
    e = ndimage.gaussian_filter(e, 0.7)
    gy, gx = np.gradient(e)
    light = -(gx * 1.0 + gy * 1.0) / math.sqrt(2)       # sun in the north-west
    shade = np.ones((H, W), dtype=int)
    shade[light > 2.2] = 2
    shade[light < -2.2] = 0
    shade[~land] = 0

    code = np.where(land, 5 + tone * 3 + shade, 0)
    assert code.max() < 62

    rows = []
    for y in range(H):
        out, x = [], 0
        while x < W:
            v = int(code[y, x])
            stop = x + 1
            while stop < W and code[y, stop] == v:
                stop += 1
            out.append(B62[v] + b62(stop - x, 2))
            x = stop
        rows.append("".join(out))

    tones = [[int(round(v)) for v in c] for c in centres]
    lua = ["-- GENERATED by tools/generate_terrain.py from NASA Visible Earth colour + elevation (public domain).",
           "-- Do not edit by hand. Client-only: how the land and sea look; the rules never read it.",
           "-- rows: run-length encoded; each run = 1 base62 char code + 2 base62 chars length.",
           "-- code 0 = water (flat sea colour); code >= 5 = land: 5 + tone*3 + shade.",
           "return {",
           f"\tW = {W},", f"\tH = {H},",
           "\tShade = { " + ", ".join(f"{v}" for v in SHADE) + " },",
           "\tWater = { " + ", ".join("{ %d, %d, %d }" % c for c in WATER) + " },",
           "\tTones = {"]
    for i in range(0, TONES, 5):
        lua.append("\t\t" + " ".join("{ %d, %d, %d }," % tuple(t) for t in tones[i:i + 5]))
    lua += ["\t},", "\tRows = {"]
    lua += [f'\t\t"{r}",' for r in rows]
    lua += ["\t},", "}", ""]
    out = ROOT / "src" / "shared" / "MapTerrain.lua"
    out.write_text("\n".join(lua))

    # preview of the neutral world exactly as MapRenderer computes it
    pal = np.zeros((62, 3))
    pal[0] = WATER[0]
    for t in range(TONES):
        for sh in range(3):
            pal[5 + t * 3 + sh] = np.clip(np.array(tones[t]) * SHADE[sh], 0, 255)
    img = pal[code].astype(np.uint8)
    Image.fromarray(img).resize((W * 2, H * 2), Image.NEAREST).save(ROOT / "data" / "terrain-preview.png")
    print(f"{out.relative_to(ROOT)}: {out.stat().st_size // 1024} KB, {sum(len(r) for r in rows) // 3} runs")


if __name__ == "__main__":
    main()
