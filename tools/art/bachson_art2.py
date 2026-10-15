"""Bạch Sơn, second half of the chapter: the glimpse of the source (Duyên), the temple painting, a page of the
Sổ Tro, and the battle icons for Rửa, changing sides and closing the gate (docs/N_bach_son.md 8.3 to 8.6)."""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from env import pnoise

PAPER = (233, 228, 216)
INK = (22, 19, 22)
ROOT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets')


def _finish(im, W, H, seed, out=(480, 270)):
    rng = np.random.default_rng(seed)
    arr = np.array(im).astype(float)
    n = pnoise(256, 8, seed)
    n = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((W, H))) / 255.0
    arr *= (0.93 + 0.09 * n)[..., None]
    sp = rng.random((H, W)) < 0.0006
    arr[sp] = INK
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.hypot((xx - W / 2) / (W / 2), (yy - H / 2) / (H / 2))
    arr = arr * (1 - np.clip(r - 0.74, 0, 1)[..., None] * 1.2)
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).resize(out, Image.LANCZOS)
    a2 = (np.array(im).astype(int) // 12) * 12 + 6
    im = Image.fromarray(np.clip(a2, 0, 255).astype(np.uint8)).resize((out[0] * 2, out[1] * 2), Image.NEAREST)
    return im.convert('RGBA')


def source(seed=11):
    """Glimpse at the camp (8.3): the source of Trắng Tay. The city's windows at night, people behind the
    curtains looking down at the camp, a mother pulling her child back from the sill, porcelain cups set out on the
    doorsteps. Far below, the camp's three fires. No words."""
    S = 2
    W, H = 480 * S, 270 * S
    im = Image.new('RGB', (W, H), (206, 200, 190))
    d = ImageDraw.Draw(im)
    # night wash from the top
    sky = np.array(im).astype(float)
    t = np.linspace(0, 1, H)[:, None, None]
    sky = sky * (0.55 + 0.45 * t)
    im = Image.fromarray(sky.astype(np.uint8))
    d = ImageDraw.Draw(im)
    # three house fronts, white, black roofs with stepped gables
    for (x0, x1, top) in ((20, 170, 70), (180, 320, 52), (330, 470, 78)):
        x0, x1, top = x0 * S, x1 * S, top * S
        d.rectangle([x0, top, x1, 200 * S], fill=(222, 219, 210))
        d.polygon([(x0 - 8 * S, top + 2 * S), (x1 + 8 * S, top + 2 * S), (x1 - 6 * S, top - 16 * S), (x0 + 6 * S, top - 16 * S)], fill=INK)
        for gx in (x0 - 2 * S, x1 - 10 * S):
            d.rectangle([gx, top - 26 * S, gx + 12 * S, top + 4 * S], fill=(222, 219, 210))
            d.rectangle([gx - 3 * S, top - 30 * S, gx + 15 * S, top - 25 * S], fill=INK)
    # lit windows with figures behind the paper
    wins = [(50, 110), (110, 110), (210, 92), (270, 92), (360, 116), (420, 116)]
    for i, (wx, wy) in enumerate(wins):
        wx, wy = wx * S, wy * S
        d.rectangle([wx, wy, wx + 34 * S, wy + 40 * S], fill=(236, 196, 120))
        # a head and shoulders, dark against the lamp, turned down toward the camp
        hx = wx + (12 + (i % 3) * 4) * S
        d.ellipse([hx, wy + 8 * S, hx + 11 * S, wy + 20 * S], fill=(54, 40, 34))
        d.polygon([(hx - 5 * S, wy + 40 * S), (hx + 16 * S, wy + 40 * S), (hx + 12 * S, wy + 20 * S), (hx - 1 * S, wy + 20 * S)], fill=(54, 40, 34))
        if i == 2:
            # a mother drawing her child back from the sill
            d.ellipse([wx + 22 * S, wy + 22 * S, wx + 29 * S, wy + 30 * S], fill=(54, 40, 34))
            d.line([(hx + 10 * S, wy + 26 * S), (wx + 24 * S, wy + 30 * S)], fill=(54, 40, 34), width=3 * S)
        # the ice-crack lattice of the city's windows, over the lamplit paper (as in the street: tex lattice.png)
        lrng = np.random.default_rng(40 + i)
        nodes = [(wx + lrng.uniform(4, 30) * S, wy + lrng.uniform(4, 36) * S) for _ in range(6)]
        for (ax, ay) in nodes:
            for (bx, by) in sorted(nodes, key=lambda q: (q[0] - ax) ** 2 + (q[1] - ay) ** 2)[1:3]:
                d.line([(ax, ay), (bx, by)], fill=(70, 50, 34), width=S)
        d.rectangle([wx, wy, wx + 34 * S, wy + 40 * S], outline=(58, 42, 30), width=3 * S)
        # and a white paper lantern with its cobalt band by each door below
        lx, ly = wx + 40 * S, 168 * S
        d.ellipse([lx, ly, lx + 9 * S, ly + 14 * S], fill=(240, 236, 224))
        d.rectangle([lx, ly + 6 * S, lx + 9 * S, ly + 7 * S], fill=(60, 84, 146))
    # the doorsteps, and a white cup on each
    d.rectangle([0, 200 * S, W, 214 * S], fill=(150, 146, 138))
    for cx in range(30, 470, 52):
        cx = cx * S
        d.polygon([(cx, 194 * S), (cx + 12 * S, 194 * S), (cx + 9 * S, 202 * S), (cx + 3 * S, 202 * S)], fill=(246, 246, 244))
        d.line([(cx, 194 * S), (cx + 12 * S, 194 * S)], fill=(60, 84, 146), width=2 * S)
    # below the city wall, in the dark, the camp's fires
    d.rectangle([0, 214 * S, W, H], fill=(40, 36, 40))
    for (fx, fy) in ((90, 246), (140, 252), (300, 244)):
        fx, fy = fx * S, fy * S
        glow = Image.new('L', (W, H), 0)
        ImageDraw.Draw(glow).ellipse([fx - 18 * S, fy - 10 * S, fx + 18 * S, fy + 10 * S], fill=160)
        glow = glow.filter(ImageFilter.GaussianBlur(8 * S))
        base = np.array(im).astype(float)
        a = np.array(glow)[..., None] / 255.0
        base = base * (1 - a) + np.array((230, 140, 60), float) * a
        im = Image.fromarray(base.astype(np.uint8))
        d = ImageDraw.Draw(im)
        d.ellipse([fx - 3 * S, fy - 4 * S, fx + 3 * S, fy + 2 * S], fill=(255, 210, 120))
    return _finish(im, W, H, seed)


def tranh_tho():
    """The temple painting (K 6, N 3.5): the teacher's stroke parting the clean from the unclean. A white
    stroke down the middle; white robes on one side, dark on the other. (The player has seen him split firewood.)"""
    W, H = 64, 96
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([4, 4, W - 5, H - 5], fill=(214, 202, 172))
    d.rectangle([2, 2, W - 3, 5], fill=(70, 46, 30))
    d.rectangle([2, H - 6, W - 3, H - 3], fill=(70, 46, 30))
    # the figure above, sword up, in grey ink
    d.ellipse([28, 12, 35, 19], fill=(64, 60, 58))
    d.polygon([(25, 40), (38, 40), (36, 20), (27, 20)], fill=(84, 80, 76))
    d.line([(36, 22), (44, 12)], fill=(40, 38, 40), width=1)
    # the stroke: white, down the middle
    d.polygon([(30, 42), (34, 42), (33, 86), (31, 86)], fill=(250, 250, 248))
    # the clean, in white, left; the unclean, dark, right
    for i, x in enumerate((9, 16, 23)):
        y = 60 + (i % 2) * 6
        d.ellipse([x, y, x + 5, y + 5], fill=(236, 232, 224))
        d.rectangle([x, y + 5, x + 5, y + 17], fill=(240, 238, 232))
    for i, x in enumerate((38, 45, 52)):
        y = 62 + (i % 2) * 6
        d.ellipse([x, y, x + 5, y + 5], fill=(58, 50, 46))
        d.rectangle([x, y + 5, x + 5, y + 17], fill=(46, 40, 38))
    d.rectangle([4, 4, W - 5, H - 5], outline=(120, 100, 72))
    return im


def so_tro():
    """A page of the Sổ Tro: three columns, trắng, xám, đen. Lines struck through with ash. The black column
    is empty all the way down (4.2, tier 1)."""
    W, H = 420, 300
    im = Image.new('RGBA', (W, H), (232, 224, 204, 255))
    d = ImageDraw.Draw(im)
    rng = np.random.default_rng(3)
    font = ImageFont.truetype(os.path.join(ROOT, 'fonts', 'NotoSerif.ttf'), 20)
    cols = [(250, 'Trắng'), (310, 'Xám'), (370, 'Đen')]
    for x, t in cols:
        d.text((x - 18, 14), t, fill=(50, 40, 34), font=font)
        d.line([(x - 26, 44), (x - 26, H - 16)], fill=(150, 130, 104), width=1)
    d.line([(16, 46), (W - 16, 46)], fill=(70, 56, 44), width=2)
    for r in range(10):
        y = 60 + r * 23
        # a name: a short run of strokes
        x = 22
        while x < 200:
            w = int(rng.integers(6, 16))
            d.line([(x, y + 6), (x + w, y + 4 + int(rng.integers(0, 4)))], fill=(46, 36, 30), width=2)
            x += w + int(rng.integers(3, 9))
        mark = 0 if rng.random() < 0.55 else 1
        mx = cols[mark][0] - 6
        d.line([(mx, y + 2), (mx + 10, y + 10)], fill=(46, 36, 30), width=2)
        if mark == 1 and rng.random() < 0.7:
            # struck out with ash: put out of the gate
            d.rectangle([18, y + 1, 220, y + 11], fill=(150, 146, 140, 255))
    return im


def chen_ran():
    """Bà Mẫn's cup (8.3): the same white cup with the cobalt rim that stands on every doorstep, its glaze crazed,
    ash rubbed in and washed off: the crackle stays dark."""
    W, H = 96, 72
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(10, 14), (86, 14), (70, 64), (26, 64)], fill=(232, 236, 239))
    d.polygon([(70, 14), (86, 14), (70, 64), (62, 64)], fill=(196, 204, 211))
    d.rectangle([10, 12, 86, 17], fill=(60, 84, 146))
    d.rectangle([30, 64, 66, 68], fill=(196, 204, 211))
    rng = np.random.default_rng(5)
    nodes = [(rng.uniform(16, 78), rng.uniform(22, 60)) for _ in range(14)]
    for (ax, ay) in nodes:
        for (bx, by) in sorted(nodes, key=lambda q: (q[0] - ax) ** 2 + (q[1] - ay) ** 2)[1:3]:
            d.line([(ax, ay), (bx, by)], fill=(70, 72, 76), width=1)
    d.polygon([(10, 14), (86, 14), (70, 64), (26, 64)], outline=(86, 96, 106))
    return im


TEX = {'tranh_tho': tranh_tho, 'chen_ran': chen_ran}
UI = {'so_tro': so_tro}


def main():
    source().save(os.path.join(ROOT, 'vision', 'source.png'))
    for k, fn in TEX.items():
        fn().save(os.path.join(ROOT, 'tex', k + '.png'))
    for k, fn in UI.items():
        fn().save(os.path.join(ROOT, 'ui', k + '.png'))
    print('ok')


if __name__ == '__main__':
    main()
