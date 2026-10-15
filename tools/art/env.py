"""Tileable environment textures (pixel art, nearest filtering) for Vô Danh Cốc."""
import math
import numpy as np
from PIL import Image
from pix import hexc


def pnoise(n, cells, seed, octaves=3):
    """Periodic value noise in [0,1], n x n, tileable."""
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n))
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        cc = cells * (2 ** o)
        g = rng.random((cc, cc))
        ys = np.arange(n) * cc / n
        y0 = np.floor(ys).astype(int)
        fy = ys - y0
        fy = fy * fy * (3 - 2 * fy)
        y1 = (y0 + 1) % cc
        x0, x1, fx = y0, y1, fy
        a = g[y0][:, x0]
        b = g[y0][:, x1]
        c = g[y1][:, x0]
        d = g[y1][:, x1]
        top = a + (b - a) * fx[None, :]
        bot = c + (d - c) * fx[None, :]
        out += amp * (top + (bot - top) * fy[:, None])
        tot += amp
        amp *= 0.5
    return out / tot


def quant(v, pal, dither=0.0, seed=0):
    rng = np.random.default_rng(seed)
    v = v + (rng.random(v.shape) - 0.5) * dither
    v = np.clip(v, 0, 0.9999)
    idx = (v * len(pal)).astype(int)
    cols = np.array([hexc(p) for p in pal], np.uint8)
    return cols[idx]


def to_img(rgb, alpha=None):
    h, w = rgb.shape[:2]
    a = np.full((h, w, 1), 255, np.uint8) if alpha is None else alpha.reshape(h, w, 1).astype(np.uint8)
    return Image.fromarray(np.concatenate([rgb, a], axis=2), 'RGBA')


def stretch(v):
    lo, hi = np.percentile(v, 2), np.percentile(v, 98)
    return np.clip((v - lo) / (hi - lo + 1e-9), 0, 1)


def grass(seed=1):
    n = 32
    v = stretch(pnoise(n, 4, seed) * 0.7 + pnoise(n, 8, seed + 1) * 0.3)
    rgb = quant(v, ['#3d5629', '#4a6630', '#567436', '#638340', '#71924a'], 0.18, seed)
    rng = np.random.default_rng(seed + 9)
    for _ in range(26):  # blades
        x, y = rng.integers(n), rng.integers(n)
        for k in range(rng.integers(2, 4)):
            rgb[(y - k) % n, x] = hexc('#86a85a') if k == 0 else hexc('#749650')
        rgb[(y + 1) % n, x] = hexc('#36502a')
    for _ in range(3):
        x, y = rng.integers(n), rng.integers(n)
        rgb[y, x] = hexc(rng.choice(['#e8dc86', '#f0efe2', '#d79ab0']))
    return to_img(rgb)


def dirt(seed=2, light=False):
    n = 32
    v = stretch(pnoise(n, 4, seed) * 0.6 + pnoise(n, 16, seed + 3) * 0.4)
    pal = ['#7e6446', '#8c7050', '#9a7e5c', '#a88b67', '#b59873'] if light else ['#4f3b2a', '#5c4632', '#6a5139', '#7a5e43', '#896b4d']
    rgb = quant(v, pal, 0.22, seed)
    rng = np.random.default_rng(seed + 5)
    for _ in range(10):
        x, y = rng.integers(n), rng.integers(n)
        rgb[y, x] = hexc('#b8ad9c' if not light else '#d2c4a8')
        rgb[(y + 1) % n, x] = hexc('#3c2d20' if not light else '#7a6248')
    if light:
        for _ in range(3):  # hairline cracks
            x, y = rng.integers(n), rng.integers(n)
            for k in range(5):
                rgb[y % n, x % n] = hexc('#7a6248')
                x += rng.integers(-1, 2)
                y += 1
    return to_img(rgb)


def cobble(seed=3):
    n = 32
    rng = np.random.default_rng(seed)
    pts = rng.random((14, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n]
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    idx = np.zeros((n, n), int)
    for i, (px, py) in enumerate(pts):
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d = np.hypot(xx - px - ox, yy - py - oy)
                closer = d < d1
                d2 = np.where(closer, d1, np.minimum(d2, d))
                idx = np.where(closer, i, idx)
                d1 = np.where(closer, d, d1)
    edge = (d2 - d1) < 1.6
    shade = rng.random(14)[idx]
    v = np.clip(shade * 0.6 + 0.4 * (1 - d1 / 8), 0, 1)
    rgb = quant(v, ['#55504a', '#645e57', '#746d64', '#857d72', '#968d80'], 0.1, seed)
    rgb[edge] = hexc('#2f2b27')
    return to_img(rgb)


def rock(seed=4):
    """Cliff face: broad horizontal slabs, bright top lips, dark undersides, a few vertical cracks."""
    n = 32
    rng = np.random.default_rng(seed)
    k = 13
    pts = rng.random((k, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n]
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    idx = np.zeros((n, n), int)
    ny = np.zeros((n, n))
    for i, (px, py) in enumerate(pts):
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                dx = (xx - px - ox) * 0.75
                dy = (yy - py - oy) * 1.15
                d = np.hypot(dx, dy)
                closer = d < d1
                d2 = np.where(closer, d1, np.minimum(d2, d))
                idx = np.where(closer, i, idx)
                ny = np.where(closer, dy, ny)
                d1 = np.where(closer, d, d1)
    edge = (d2 - d1) < 1.0
    face = rng.random(k)[idx]
    lit = np.clip(0.5 - ny / 16.0, 0, 1)
    v = stretch(face * 0.45 + lit * 0.25 + pnoise(n, 8, seed + 3) * 0.3)
    rgb = quant(v, ['#4c4b46', '#595851', '#68665d', '#787569', '#898576', '#9b9684'], 0.16, seed)
    under = edge & (ny > 0)
    top = edge & (ny <= 0)
    rgb[under] = hexc('#363430')
    rgb[top] = np.minimum(rgb[top].astype(int) + 18, 255).astype(np.uint8)
    for _ in range(4):  # vertical cracks
        x, y = rng.integers(n), rng.integers(n)
        for _k in range(rng.integers(4, 8)):
            rgb[y % n, x % n] = hexc('#3a3833')
            x += rng.integers(-1, 2) if rng.random() < 0.3 else 0
            y += 1
    for _ in range(22):  # moss and lichen on the lips
        x, y = rng.integers(n), rng.integers(n)
        if top[y, x] or rng.random() < 0.3:
            rgb[y, x] = hexc(rng.choice(['#4e6a36', '#5f7c40', '#7d8a55']))
    return to_img(rgb)


def thatch(seed=5):
    n = 32
    xx = np.arange(n)[None, :]
    v = stretch(pnoise(n, 8, seed) * 0.4 + ((xx * 7 % 5) / 5.0) * 0.35 + pnoise(n, 16, seed + 7) * 0.25)
    rgb = quant(v, ['#6b5228', '#806332', '#97763e', '#ad8b4c', '#c3a15d'], 0.25, seed)
    for y in (7, 23):  # binding rows
        rgb[y, :] = hexc('#4f3b1c')
        rgb[y + 1, :] = hexc('#6b5228')
    return to_img(rgb)


def roof_tile(seed=6):
    n = 32
    rgb = np.zeros((n, n, 3), np.uint8)
    pal = [hexc(c) for c in ('#5e2a22', '#7a3a2c', '#924836', '#a85a42', '#bb6e52')]
    for y in range(n):
        for x in range(n):
            row = y // 8
            off = 4 if row % 2 else 0
            lx = (x + off) % 8
            ly = y % 8
            curve = (lx - 3.5) ** 2 / 12.25
            t = 1 - ly / 8
            k = int(np.clip(2 + t * 2 - curve * 2, 0, 4))
            if ly == 7 or lx == 0:
                k = 0
            rgb[y, x] = pal[k]
    return to_img(rgb)


def mudwall(seed=7):
    n = 32
    v = stretch(pnoise(n, 4, seed) * 0.7 + pnoise(n, 16, seed + 2) * 0.3)
    rgb = quant(v, ['#7c6346', '#8d7251', '#9d815d', '#ad9069', '#bc9f76'], 0.2, seed)
    rng = np.random.default_rng(seed + 1)
    for _ in range(16):  # straw flecks
        x, y = rng.integers(n), rng.integers(n)
        L = rng.integers(2, 4)
        for k in range(L):
            rgb[y, (x + k) % n] = hexc('#cdb27a')
    return to_img(rgb)


def planks(seed=8, dark=False):
    n = 32
    xx = np.arange(n)[None, :].repeat(n, 0)
    v = stretch(pnoise(n, 2, seed) * 0.3 + np.sin((xx % 8) / 8 * math.pi) * 0.4 + pnoise(n, 16, seed + 4) * 0.3)
    pal = ['#2c2018', '#3a2a1e', '#4a3626', '#5a4430', '#6b523b'] if dark else ['#5a4128', '#6c4f31', '#7d5d3a', '#8f6c45', '#a07c51']
    rgb = quant(v, pal, 0.15, seed)
    rgb[:, ::8] = hexc('#241910' if not dark else '#1a120c')
    rng = np.random.default_rng(seed)
    for _ in range(5):  # knots
        x, y = rng.integers(n), rng.integers(n)
        rgb[y, x] = hexc(pal[0])
    return to_img(rgb)


def bamboo_weave(seed=9):
    n = 32
    rgb = np.zeros((n, n, 3), np.uint8)
    a, b = hexc('#a48a55'), hexc('#c2a86d')
    d = hexc('#6f5a33')
    for y in range(n):
        for x in range(n):
            cell = ((x // 4) + (y // 4)) % 2
            if cell:
                rgb[y, x] = a if y % 4 else d
            else:
                rgb[y, x] = b if x % 4 else d
    return to_img(rgb)


def wood_end(seed=10):
    n = 16
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.hypot(xx - 7.5, yy - 7.5)
    rgb = quant(((r * 0.9) % 2) / 2 * 0.6 + 0.3, ['#7a5a3a', '#94714a', '#b08a5c', '#c39d6c'], 0.1, seed)
    rgb[r > 7.2] = hexc('#4f3a26')
    return to_img(rgb)


def mat(seed=11):
    n = 32
    rgb = np.zeros((n, n, 3), np.uint8)
    base = [hexc('#cdb889'), hexc('#bfa978'), hexc('#d9c597')]
    for y in range(n):
        for x in range(n):
            rgb[y, x] = base[(x + (y // 2)) % 3]
    for y in (4, 5, 26, 27):
        rgb[y, :] = hexc('#8e2f2f')
    for y in (8, 23):
        rgb[y, :] = hexc('#3d6b4a')
    return to_img(rgb)


def water_noise(seed=12):
    v = pnoise(64, 4, seed, 4)
    g = (stretch(v) * 255).astype(np.uint8)
    return Image.fromarray(np.stack([g, g, g, np.full_like(g, 255)], 2), 'RGBA')


def clouds(seed=41):
    """Large smooth tileable noise for sky clouds, cloud shadows and wind gusts."""
    v = pnoise(256, 4, seed, 5)
    g = (stretch(v) * 255).astype(np.uint8)
    return Image.fromarray(np.stack([g, g, g, np.full_like(g, 255)], 2), 'RGBA')


def bark(seed=51):
    """Fibrous vertical bark for 3D trunks (triplanar)."""
    n = 32
    xx = np.arange(n)[None, :]
    v = stretch(pnoise(n, 8, seed) * 0.35 + np.sin(xx / n * math.tau * 5 + pnoise(n, 2, seed + 1) * 5) * 0.35 + pnoise(n, 16, seed + 2) * 0.3)
    rgb = quant(v, ['#3e2f22', '#4d3a2a', '#5c4733', '#6c553e', '#7d6549'], 0.14, seed)
    rng = np.random.default_rng(seed)
    for _ in range(8):  # cracks running down
        x, y = rng.integers(n), rng.integers(n)
        for _k in range(rng.integers(5, 12)):
            rgb[y % n, x % n] = hexc('#2a1f16')
            x += rng.integers(-1, 2) if rng.random() < 0.25 else 0
            y += 1
    for _ in range(10):
        x, y = rng.integers(n), rng.integers(n)
        rgb[y, x] = hexc(rng.choice(['#5d6b3a', '#6d7a44']))
    return to_img(rgb)


def paddy(seed=13):
    n = 32
    v = stretch(pnoise(n, 4, seed))
    rgb = quant(v, ['#3d4a33', '#46553a', '#506040', '#5b6c48'], 0.15, seed)
    return to_img(rgb)


def stele(seed=14):
    """Bia đá: 48x64 face with carved border, text marks, and ten small seals."""
    w, h = 48, 64
    v = stretch(pnoise(64, 4, seed))[:h, :w]
    rgb = quant(v, ['#5a5850', '#67655c', '#747268', '#828075'], 0.12, seed)
    dark = hexc('#3a3832')
    rgb[2, 2:w - 2] = dark
    rgb[h - 3, 2:w - 2] = dark
    rgb[2:h - 2, 2] = dark
    rgb[2:h - 2, w - 3] = dark
    rng = np.random.default_rng(seed)
    for col in range(4):  # vertical text columns, right to left
        x = w - 9 - col * 9
        for k in range(5):
            y = 7 + k * 6
            if rng.random() < 0.85:
                g = rng.integers(0, 3, (3, 3))
                for gy in range(3):
                    for gx in range(3):
                        if g[gy, gx] == 0:
                            rgb[y + gy, x + gx] = dark
    seal = hexc('#7d3b33')
    for i in range(10):
        sx = 6 + (i % 5) * 8
        sy = 41 + (i // 5) * 9
        rgb[sy:sy + 5, sx:sx + 5] = seal
        rgb[sy + 1:sy + 4, sx + 1:sx + 4] = hexc('#93493e')
        k = rng.integers(0, 3)
        rgb[sy + 2, sx + 1 + k] = hexc('#5c2a24')
    return to_img(rgb)


def pegboard():
    w, h = 64, 16
    rgb = np.array(planks(15, dark=True))[:h, :w, :3].copy()
    for i in range(11):
        x = 4 + i * 5 + (2 if i == 10 else 0)
        new = i == 10
        top = hexc('#a07c51') if new else hexc('#6b523b')
        shade = hexc('#7d5d3a') if new else hexc('#4a3626')
        rgb[6:10, x:x + 2] = shade
        rgb[6, x:x + 2] = top
        rgb[10, x - 1:x + 3] = hexc('#1a120c')
    return to_img(rgb)


def marker():
    w, h = 16, 32
    v = stretch(pnoise(32, 4, 21))[:h, :w]
    rgb = quant(v, ['#5f5d55', '#6d6b62', '#7b796f', '#8a887d'], 0.12, 21)
    d = hexc('#3a3832')
    for k in range(4):  # carved diamond
        rgb[8 + k, 7 - k:9 + k] = d if k == 3 else rgb[8 + k, 7 - k:9 + k]
        rgb[8 + k, 7 - k] = d
        rgb[8 + k, 8 + k] = d
        rgb[15 - k, 7 - k] = d
        rgb[15 - k, 8 + k] = d
    return to_img(rgb)


ALL = {
    'grass': grass, 'dirt': dirt, 'yard': lambda: dirt(22, light=True), 'cobble': cobble, 'rock': rock,
    'thatch': thatch, 'roof_tile': roof_tile, 'mudwall': mudwall, 'planks': planks,
    'beam': lambda: planks(31, dark=True), 'bamboo_weave': bamboo_weave, 'wood_end': wood_end,
    'mat': mat, 'water_noise': water_noise, 'paddy': paddy, 'stele': stele, 'pegboard': pegboard,
    'marker': marker, 'clouds': clouds, 'bark': bark,
}
