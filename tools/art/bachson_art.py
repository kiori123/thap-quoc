"""Bạch Sơn: textures and props for the white city (docs/N_bach_son.md 10).

The city reads as white walls under black tile (kiểu tường trắng ngói đen): lime plaster that is never quite
clean, dark tile roofs and dark tile caps on every wall, granite plinths, warm grey flagstones, and windows of
ice-crack lattice (băng liệt), whose pattern is the crackle of the glaze the city is afraid of.
"""
import math
import numpy as np
from PIL import Image
from pix import Canvas, ramp, hexc
from env import pnoise, quant, to_img, stretch

# ---------------------------------------------------------------------------------------------- textures


def lime_wall(seed=61):
    ## lime plaster, made the way the valley's mud walls are (env.mudwall: same noise, same five-tone ramp, same
    ## density), in the whites of the city, with chips of lime where the mud walls have straw
    n = 32
    v = stretch(pnoise(n, 4, seed) * 0.7 + pnoise(n, 16, seed + 2) * 0.3)
    rgb = quant(v, ['#c4bdaf', '#d0c9bc', '#dbd5c9', '#e6e1d6', '#f0ece3'], 0.2, seed)
    rng = np.random.default_rng(seed + 1)
    for _ in range(12):  # lime chips and pits
        x, y = int(rng.integers(n)), int(rng.integers(n))
        rgb[y, x] = hexc('#f7f5ef' if rng.random() < 0.5 else '#b3ab9c')
    return to_img(rgb)
def lime_wall_old(seed=62):
    ## the same lime, older: rain streaks down from the coping, grime toward the foot
    im = np.array(lime_wall(seed))[:, :, :3].astype(float)
    n = 32
    rng = np.random.default_rng(seed)
    for _ in range(6):
        x = int(rng.integers(n))
        L = int(rng.integers(8, 26))
        for y in range(L):
            k = 0.86 + 0.1 * y / L
            im[y, x] *= k
            if rng.random() < 0.4:
                im[y, (x + 1) % n] *= (k + 1) * 0.5
    return to_img(np.clip(im, 0, 255).astype(np.uint8))


def roof_ink(seed=63):
    ## black tile, laid as runs of channel tiles and cover tiles (ngói âm dương), rows lapping every 6 px
    n = 32
    pal = [hexc(c) for c in ('#1f2329', '#272c33', '#30353d', '#3a4049', '#474e58')]
    rgb = np.zeros((n, n, 3), np.uint8)
    noise = pnoise(n, 8, seed)
    for y in range(n):
        for x in range(n):
            col = x // 4
            lx = x % 4
            ly = (y + (3 if col % 2 else 0)) % 6
            cover = col % 2 == 0
            if cover:
                k = [1, 3, 4, 2][lx]
                if ly == 0:
                    k = 3
                elif ly == 5:
                    k = 0
            else:
                k = [1, 2, 2, 1][lx] - (1 if ly == 5 else 0)
            k = int(np.clip(k + (1 if noise[y, x] > 0.72 else 0) - (1 if noise[y, x] < 0.25 else 0), 0, 4))
            rgb[y, x] = pal[k]
    return to_img(rgb)


def plinth(seed=64):
    ## granite blocks at the foot of every wall, and the steps
    n = 32
    v = stretch(pnoise(n, 6, seed) * 0.6 + pnoise(n, 16, seed + 1) * 0.4)
    rgb = quant(v, ['#6f7276', '#7c7f83', '#878a8e', '#93969a', '#a1a4a7'], 0.25, seed)
    joint = hexc('#4e5054')
    for y in range(n):
        row = y // 8
        off = 8 if row % 2 else 0
        for x in range(n):
            if y % 8 == 7 or (x + off) % 16 == 15:
                rgb[y, x] = joint
            elif y % 8 == 0:
                rgb[y, x] = np.minimum(rgb[y, x].astype(int) + 14, 255)
    return to_img(rgb)


def flag_warm(seed=65):
    ## warm grey flagstones, worn, with ash in the joints (the street and the Sân Tro)
    n = 32
    rng = np.random.default_rng(seed)
    pts = rng.random((16, 2)) * n
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
    edge = (d2 - d1) < 0.9
    shade = rng.random(16)[idx] * 0.4 + stretch(pnoise(n, 8, seed + 2)) * 0.6
    rgb = quant(shade, ['#918b82', '#9a948a', '#a39d93', '#aca69c', '#b4aea4'], 0.12, seed)
    rgb[edge] = hexc('#7c766d')
    return to_img(rgb)


def lattice(seed=66):
    ## an ice-crack lattice window (song cửa băng liệt): dark frame, paper behind, the crackle of glaze in wood
    n = 32
    rgb = np.zeros((n, n, 3), np.uint8)
    rgb[:, :] = hexc('#e9dfc6')
    pv = pnoise(n, 3, seed)
    rgb[pv > 0.6] = hexc('#e1d5ba')
    wood = hexc('#3a2a1f')
    wood_hi = hexc('#54402f')
    rng = np.random.default_rng(seed)

    def seg(x0, y0, x1, y1):
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(steps + 1):
            t = i / max(steps, 1)
            x = int(round(x0 + (x1 - x0) * t))
            y = int(round(y0 + (y1 - y0) * t))
            if 0 <= x < n and 0 <= y < n:
                rgb[y, x] = wood

    # cracks: a handful of nodes joined to their neighbours, the way glaze crazes
    nodes = [(rng.uniform(5, 27), rng.uniform(5, 27)) for _ in range(9)]
    for i, (x, y) in enumerate(nodes):
        ds = sorted(range(len(nodes)), key=lambda j: math.hypot(nodes[j][0] - x, nodes[j][1] - y))
        for j in ds[1:3]:
            seg(x, y, nodes[j][0], nodes[j][1])
        # and out to the frame
        side = rng.integers(4)
        tx, ty = [(x, 2), (x, 29), (2, y), (29, y)][side]
        if rng.random() < 0.6:
            seg(x, y, tx, ty)
    rgb[:3, :] = wood
    rgb[-3:, :] = wood
    rgb[:, :3] = wood
    rgb[:, -3:] = wood
    rgb[3, 3:-3] = wood_hi
    rgb[3:-3, 3] = wood_hi
    return to_img(rgb)


def door_wood(seed=67):
    ## a pair of dark plank leaves with a cobalt-glazed ring pull each
    n = 32
    xx = np.arange(n)[None, :].repeat(n, 0)
    v = stretch(pnoise(n, 2, seed) * 0.35 + np.sin((xx % 5) / 5 * math.pi) * 0.35 + pnoise(n, 16, seed + 4) * 0.3)
    rgb = quant(v, ['#21170f', '#2b1e14', '#36271b', '#433223', '#4f3c2b'], 0.15, seed)
    rgb[:, ::5] = hexc('#160f09')
    rgb[:, 15:17] = hexc('#120c07')
    for cx in (12, 19):
        for a in range(16):
            x = int(round(cx + 2 * math.cos(a / 16 * math.tau)))
            y = int(round(16 + 2 * math.sin(a / 16 * math.tau)))
            rgb[y, x] = hexc('#3d5a96')
    return to_img(rgb)


def tent_cloth(seed=68):
    ## a camp tent: old canvas gone grey-brown in the weather, patched with whatever cloth there was (an indigo
    ## rag, a scrap of ochre, a strip of shroud linen), the patches ragged, stitched round in dark thread; rain
    ## has run down it in streaks. 48 px to 2 m, as the sprites.
    n = 48
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n]
    v = stretch(pnoise(n, 4, seed) * 0.6 + pnoise(n, 12, seed + 1) * 0.4)
    rgb = quant(v, ['#5f5850', '#6a6259', '#756c62', '#81776b', '#8c8275'], 0.14, seed)
    for x in range(n):                       # the weave: faint threads across
        if x % 3 == 0:
            rgb[:, x] = (rgb[:, x].astype(int) - 5).clip(0, 255)
    for (cols, cx, cy, w, h, ang) in ((['#3f4658', '#4a5266', '#566075'], 12, 13, 15, 11, 0.12),
                                      (['#8a6f45', '#977b50', '#a3875b'], 35, 31, 12, 15, -0.18),
                                      (['#a8a294', '#b4ae9f', '#bfb9aa'], 33, 7, 13, 8, 0.05),
                                      (['#4f4a43', '#5a544c', '#655e55'], 10, 37, 11, 9, -0.08)):
        # a patch: a crooked oblong of some other cloth, its edge a little ragged
        wob = (pnoise(n, 8, seed + cx) - 0.5) * 1.6
        u = (xx - cx) * np.cos(ang) + (yy - cy) * np.sin(ang)
        q = -(xx - cx) * np.sin(ang) + (yy - cy) * np.cos(ang)
        m = (np.abs(u) < w / 2 + wob) & (np.abs(q) < h / 2 + wob)
        pv = stretch(pnoise(n, 8, seed + cy))
        k = np.clip((pv * 3).astype(int), 0, 2)
        for t in range(3):
            rgb[m & (k == t)] = hexc(cols[t])
        edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        rgb[edge & ((xx + yy) % 2 == 0)] = hexc('#2f2a25')     # running stitch round it
    for _ in range(7):                        # rain streaks, down the slope
        x = int(rng.integers(n))
        L = int(rng.integers(10, 30))
        y0 = int(rng.integers(n))
        for k in range(L):
            yk = (y0 + k) % n
            rgb[yk, x] = (rgb[yk, x].astype(int) * 0.88).astype(np.uint8)
    return to_img(rgb)


def ash_soft(seed=69):
    ## the ash ground outside the gate: the valley's dirt (env.dirt), its colour gone grey with ash
    ## (calmer than before: fine grain, small stones, no big blotches that tile into a pattern)
    n = 32
    v = stretch(pnoise(n, 6, seed) * 0.55 + pnoise(n, 16, seed + 3) * 0.45)
    rgb = quant(v, ['#5d5952', '#67635b', '#716c64', '#7b766d', '#868076'], 0.3, seed)
    rng = np.random.default_rng(seed + 5)
    for _ in range(14):   # pebbles: a lit top, a shadow under
        x, y = int(rng.integers(n)), int(rng.integers(n))
        rgb[y, x] = hexc('#9a948a')
        rgb[(y + 1) % n, x] = hexc('#4f4b45')
    for _ in range(8):    # flecks of white ash
        x, y = int(rng.integers(n)), int(rng.integers(n))
        rgb[y, x] = hexc('#b3ada2')
    return to_img(rgb)
def grass_high(seed=70):
    ## upland grass: the valley's grass (env.grass, same blades and density), cooler and thinner
    n = 32
    v = stretch(pnoise(n, 4, seed) * 0.7 + pnoise(n, 8, seed + 1) * 0.3)
    rgb = quant(v, ['#38452d', '#424f33', '#4d5a3a', '#586441', '#646e49'], 0.18, seed)
    rng = np.random.default_rng(seed + 9)
    for _ in range(26):
        x, y = int(rng.integers(n)), int(rng.integers(n))
        for k in range(int(rng.integers(2, 4))):
            rgb[(y - k) % n, x] = hexc('#7a8758') if k == 0 else hexc('#68764e')
        rgb[(y + 1) % n, x] = hexc('#2f3a27')
    for _ in range(9):     # dry blades, straw-coloured
        x, y = int(rng.integers(n)), int(rng.integers(n))
        rgb[y, x] = hexc('#8e8a62')
    for _ in range(3):
        x, y = int(rng.integers(n)), int(rng.integers(n))
        rgb[y, x] = hexc(['#e8e6dc', '#d0d6e8', '#e6dca0'][int(rng.integers(3))])
    return to_img(rgb)


def cobble_pale(seed=71):
    ## the city's paving: the valley's cobbles (env.cobble: same stones, same domed shading, same dark joints),
    ## in pale limestone, ash in the joints
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
    rgb = quant(v, ['#8c877e', '#979188', '#a29c92', '#ada79c', '#b8b2a7'], 0.1, seed)
    rgb[edge] = hexc('#726c63')
    return to_img(rgb)
def slabs(seed, pal, joint, row=8, lmin=10, lmax=18, crack=3):
    ## laid stone in rows: long slabs with staggered joints, each slab its own shade, a little noise in the face
    ## (env's pnoise and five-tone ramp, as every surface in the game), a lit top edge and a shaded bottom edge,
    ## soft joints. Tiles in both directions.
    n = 32
    rng = np.random.default_rng(seed)
    face = stretch(pnoise(n, 8, seed) * 0.6 + pnoise(n, 16, seed + 1) * 0.4)
    v = np.zeros((n, n))
    jm = np.zeros((n, n), bool)
    lit = np.zeros((n, n), bool)
    shd = np.zeros((n, n), bool)
    for r in range(n // row):
        y0 = r * row
        x = int(rng.integers(0, n))
        left = n
        while left > 0:
            L = int(rng.integers(lmin, lmax + 1))
            if left - L < lmin:
                L = left
            sh = rng.uniform(0.25, 0.85)
            for k in range(L):
                xx = (x + k) % n
                v[y0:y0 + row, xx] = sh * 0.55 + face[y0:y0 + row, xx] * 0.45
            jm[y0:y0 + row, x % n] = True                 # the joint at the slab's start
            lit[y0 + 1, [(x + k) % n for k in range(1, L)]] = True
            shd[y0 + row - 2, [(x + k) % n for k in range(1, L)]] = True
            x += L
            left -= L
        jm[y0, :] = True                                  # the joint along the row
    rgb = quant(np.clip(v, 0, 1), pal, 0.12, seed)
    lighter = np.clip(rgb.astype(int) + 12, 0, 255).astype(np.uint8)
    darker = np.clip(rgb.astype(int) - 14, 0, 255).astype(np.uint8)
    rgb[lit] = lighter[lit]
    rgb[shd] = darker[shd]
    rgb[jm] = hexc(joint)
    for _ in range(crack):                                # a hairline crack or two, a chip
        cx, cy = int(rng.integers(n)), int(rng.integers(n))
        for k in range(int(rng.integers(3, 6))):
            rgb[(cy + k) % n, (cx + k // 2) % n] = hexc(joint)
    return to_img(rgb)


def slab_pale(seed=81):
    ## the city's streets: long granite slabs laid across the way, worn pale, ash in the joints (calm under the feet,
    ## so the people on it read first)
    return slabs(seed, ['#a49e94', '#ada79d', '#b6b0a6', '#bfb9af', '#c7c2b8'], '#8d877d', lmin=12, lmax=22)


def granite(seed=83):
    ## the dressed stone of plinths, door frames, steps and basins' feet: shorter blocks, a cooler grey
    return slabs(seed, ['#8a8a86', '#93938e', '#9c9b96', '#a5a49e', '#aeada7'], '#6c6b67', row=8, lmin=8, lmax=14, crack=2)


def porc_tile(seed=91):
    ## the Bạch Điện, walls and floor: white glazed tiles, a little cool, thin grey joints, a pin of cobalt where
    ## four tiles meet (the Ty's glaze), and here and there a hairline of crackle in the glaze
    n = 32
    rng = np.random.default_rng(seed)
    v = stretch(pnoise(n, 8, seed) * 0.5 + pnoise(n, 16, seed + 1) * 0.5)
    rgb = quant(v, ['#dfe4e8', '#e6eaed', '#ecf0f2', '#f2f4f6', '#f7f9fa'], 0.1, seed)
    for t in range(4):   # each tile its own shade, lit top-left edge
        tx, ty = (t % 2) * 16, (t // 2) * 16
        k = rng.uniform(-6, 6)
        blk = rgb[ty:ty + 16, tx:tx + 16].astype(int) + int(k)
        rgb[ty:ty + 16, tx:tx + 16] = np.clip(blk, 0, 255)
        rgb[ty + 1, tx + 1:tx + 15] = hexc('#fbfcfd')
        rgb[ty + 1:ty + 15, tx + 1] = hexc('#f8fafb')
    joint = hexc('#bcc3c9')
    rgb[0, :] = joint
    rgb[16, :] = joint
    rgb[:, 0] = joint
    rgb[:, 16] = joint
    for cx, cy in [(0, 0), (16, 0), (0, 16), (16, 16)]:
        rgb[cy, cx] = hexc('#4c6cb0')
    for _ in range(2):   # crackle hairlines
        x, y = int(rng.integers(3, 29)), int(rng.integers(3, 29))
        for k in range(int(rng.integers(3, 6))):
            if 0 < x < n and 0 < y < n and x % 16 and y % 16:
                rgb[y, x] = hexc('#cdd4da')
            x += int(rng.integers(-1, 2))
            y += 1
    return to_img(rgb)


TEX = {'porc_tile': porc_tile, 'slab_pale': slab_pale, 'granite': granite, 'cobble_pale': cobble_pale, 'tent_cloth': tent_cloth, 'ash_soft': ash_soft, 'grass_high': grass_high, 'lime_wall': lime_wall, 'lime_wall_old': lime_wall_old, 'roof_ink': roof_ink, 'plinth': plinth,
       'flag_warm': flag_warm, 'lattice': lattice, 'door_wood': door_wood}

# ---------------------------------------------------------------------------------------------- props

BARK_D = ramp('#3e3530', shadow='#2a231f', light='#564a42', outline='#120e0c')
NEEDLE = ramp('#2f4f3c', shadow='#20382b', light='#43694f', outline='#0c1610', hi='#5a8466')
BLOSSOM = ramp('#f1ece6', shadow='#d6c9cf', light='#ffffff', outline='#8a7680', hi='#ffffff')
BLOSSOM_P = ramp('#ecc7cf', shadow='#c99aa6', light='#f8e2e7', outline='#7a4f5a')
LANTERN_W = ramp('#ece6d6', shadow='#c8bfa8', light='#fbf8ef', outline='#4d463a', hi='#ffffff')
COBALT = ramp('#34508f', shadow='#243866', light='#4c6cb0', outline='#101a33')
PORC = ramp('#e8ecef', shadow='#b9c2c9', light='#ffffff', outline='#56606a', hi='#ffffff')


def tung():
    ## a mountain pine (tùng) the way they grow out of white cliffs: a leaning trunk, flat pads of needles
    c = Canvas(72, 80)
    T = c.material(BARK_D)
    N = c.material(NEEDLE)
    c.paint(c.line([(30, 79), (32, 62), (28, 48), (34, 34), (44, 24)], 4), T)
    c.paint(c.line([(31, 56), (16, 50), (8, 46)], 2), T)
    c.paint(c.line([(33, 40), (50, 38), (62, 34)], 2), T)
    for (x, y, rx, ry) in ((10, 44, 10, 4), (24, 46, 9, 4), (54, 32, 12, 4), (40, 22, 14, 5), (52, 18, 8, 3),
                           (30, 30, 9, 3)):
        c.paint(c.ellipse(x, y, rx, ry), N)
    return c.render()


def mai(seed=3, pink=False):
    ## a plum (mai) in flower: a dark crooked trunk and a cloud of small white blossom
    c = Canvas(56, 64)
    T = c.material(BARK_D)
    B = c.material(BLOSSOM_P if pink else BLOSSOM)
    rng = np.random.default_rng(seed)
    c.paint(c.line([(28, 63), (27, 48), (22, 38), (25, 26)], 3), T)
    c.paint(c.line([(27, 46), (38, 38), (46, 30)], 2), T)
    c.paint(c.line([(23, 38), (12, 32), (8, 24)], 2), T)
    c.paint(c.line([(25, 28), (32, 18), (30, 10)], 1), T)
    for _ in range(26):
        x = float(rng.uniform(6, 50))
        y = float(rng.uniform(6, 42))
        c.paint(c.ellipse(x, y, float(rng.uniform(1.5, 3.5)), float(rng.uniform(1.5, 3.0))), B)
    return c.render()


def lantern_w():
    ## a white paper lantern with a cobalt band (no dye in Bạch Sơn but the Ty's glaze)
    c = Canvas(14, 24)
    P = c.material(LANTERN_W)
    K = c.material(COBALT)
    c.paint(c.line([(7, 0), (7, 4)], 1), c.material(BARK_D))
    c.paint(c.ellipse(7, 13, 6, 8), P)
    c.paint(c.rect(2, 12, 12, 13), K)
    c.paint(c.rect(4, 4, 10, 5), K)
    c.paint(c.rect(4, 21, 10, 22), K)
    return c.render()


def cup_step():
    ## the porcelain cup on a doorstep (docs/N_bach_son.md 3.5, 7.4)
    c = Canvas(10, 8)
    P = c.material(PORC)
    K = c.material(COBALT)
    c.paint(c.poly([(1, 2), (9, 2), (7, 7), (3, 7)]), P)
    c.paint(c.rect(1, 2, 9, 2), K)
    return c.render()


def sheet_w(seed=7):
    ## a long sheet of undyed cloth pegged on the line (the city washes white): two pegs, hanging folds, a damp
    ## darker hem where the water gathers, the bottom edge uneven
    rng = np.random.default_rng(seed)
    c = Canvas(22, 36)
    M_ = c.material(LANTERN_W)
    D_ = c.material(ramp('#cfc8b8', shadow='#b3ab99', light='#ddd7c9', outline='#4d463a'), flat=True)
    K = c.material(BARK_D)
    c.paint(c.rect(1, 1, 20, 34), M_)
    for x in (3, 8, 12, 16):                 # long folds from the pegs down, lit on one side
        y0 = int(rng.integers(3, 7))
        c.set_tone(c.rect(x, y0, x, 30), 1)
        c.set_tone(c.rect(x + 1, y0 + 2, x + 1, 30), 3)
    c.paint(c.rect(1, 31, 20, 33), D_)       # the wet hem
    for x in range(1, 21):                   # the hem hangs unevenly
        if rng.random() < 0.35:
            c.erase(c.rect(x, 34, x, 34))
    for x in (4, 17):                        # the pegs
        c.paint(c.rect(x, 0, x + 1, 2), K)
    return c.render()


def shirt_w(seed=8):
    ## an undyed shirt pegged by the shoulders, sleeves hanging, a row of knot buttons down the front
    c = Canvas(26, 24)
    M_ = c.material(LANTERN_W)
    K = c.material(BARK_D)
    D_ = c.material(ramp('#cfc8b8', shadow='#b3ab99', light='#ddd7c9', outline='#4d463a'), flat=True)
    c.paint(c.poly([(3, 1), (22, 1), (25, 12), (21, 13), (19, 7), (19, 22), (6, 22), (6, 7), (4, 13), (0, 12)]), M_)
    c.paint(c.rect(12, 2, 12, 21), D_)                    # the front opening
    for y in (5, 9, 13, 17):
        c.paint(c.rect(13, y, 13, y), K)
    c.set_tone(c.rect(8, 9, 8, 20), 1)
    c.set_tone(c.rect(17, 9, 17, 20), 1)
    for x in (5, 19):
        c.paint(c.rect(x, 0, x + 1, 2), K)
    return c.render()


def towel_w(seed=9):
    ## a cloth folded over the line: the fold on top, two hems hanging a little unevenly
    c = Canvas(16, 16)
    M_ = c.material(LANTERN_W)
    D_ = c.material(ramp('#d8d1c2', shadow='#bdb4a2', light='#e4ded2', outline='#4d463a'), flat=True)
    c.paint(c.rect(1, 1, 14, 14), M_)
    c.paint(c.rect(2, 9, 13, 15), D_)                     # the back half, hanging a little lower
    c.set_tone(c.rect(1, 1, 14, 1), 3)
    c.set_tone(c.rect(1, 8, 14, 8), 1)
    return c.render()


def bowl_rice():
    ## the bowl of rice the servant leaves on the threshold of the Điện every day (docs/N_bach_son.md 6.1)
    c = Canvas(12, 9)
    R = c.material(ramp('#f4f1e8', shadow='#dcd6c6', light='#ffffff', outline='#6a6458'))
    P = c.material(PORC)
    K = c.material(COBALT, flat=True, outline=False)
    c.paint(c.ellipse(6, 3.2, 4.2, 2.6), R)
    c.paint(c.poly([(1, 4), (11, 4), (9, 8), (3, 8)]), P)
    c.paint(c.rect(1, 4, 10, 4), K)
    return c.render()


def ivy(seed=12):
    ## ivy hanging over the parapet of a tier wall: a mat of leaves at the top, strands trailing down unevenly
    rng = np.random.default_rng(seed)
    c = Canvas(30, 44)
    L = c.material(ramp('#3f5a33', shadow='#2c4226', light='#57753f', outline='#1a2614', hi='#6f8d4c'))
    c.paint(c.ellipse(15, 4, 13, 4.5), L)
    for k in range(7):
        x = 4 + k * 3.6 + float(rng.uniform(-1, 1))
        L2 = int(rng.integers(14, 42))
        pts = [(x, 4)]
        for t in range(1, 5):
            pts.append((x + float(rng.uniform(-1.4, 1.4)), 4 + L2 * t / 4))
        c.paint(c.line(pts, 1), L)
        for t in range(int(rng.integers(3, 7))):   # leaves along the strand
            yy = int(rng.integers(6, max(7, 4 + L2)))
            c.paint(c.ellipse(x + float(rng.uniform(-1.2, 1.2)), yy, 1.5, 1.1), L)
    return c.render()


PROPS = {'ivy': ivy, 'bowl_rice': bowl_rice, 'shirt_w': shirt_w, 'towel_w': towel_w, 'tung': tung, 'mai': mai, 'mai_pink': lambda: mai(5, True), 'lantern_w': lantern_w, 'cup_step': cup_step,
         'sheet_w': sheet_w}


if __name__ == '__main__':
    import os
    root = os.path.join(os.path.dirname(__file__), '..', '..', 'assets')
    for k, fn in TEX.items():
        fn().save(os.path.join(root, 'tex', k + '.png'))
    for k, fn in PROPS.items():
        fn().save(os.path.join(root, 'sprites', 'props', k + '.png'))
    print('ok', len(TEX), len(PROPS))
