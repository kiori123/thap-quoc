"""The Nối glimpse painting: Bạch Sơn's White Gate seen from outside, faces behind the bars,
an expelled figure walking away past porcelain statues. Ink-wash look, then pixelised."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from env import pnoise

PAPER = (233, 228, 216)
INK = (22, 19, 22)


def gate(seed=7):
    S = 2  # supersample
    W, H = 480 * S, 270 * S
    rng = np.random.default_rng(seed)
    im = Image.new('RGB', (W, H), PAPER)
    d = ImageDraw.Draw(im)

    def wash(points, col, blur=6):
        layer = Image.new('L', (W, H), 0)
        ImageDraw.Draw(layer).polygon(points, fill=255)
        layer = layer.filter(ImageFilter.GaussianBlur(blur * S))
        base = np.array(im).astype(float)
        a = np.array(layer)[..., None] / 255.0
        base = base * (1 - a) + np.array(col, float) * a
        return Image.fromarray(base.astype(np.uint8))

    # far ridges, pale washes
    for k, (yb, col, amp) in enumerate(((120, (205, 201, 192), 26), (140, (186, 182, 174), 20))):
        pts = [(0, H)]
        for x in range(0, W + 20 * S, 20 * S):
            pts.append((x, (yb - amp * math.sin(x / (80 * S) + k * 1.7) - 10 * math.sin(x / (23 * S) + k)) * S))
        pts.append((W, H))
        im = wash(pts, col, 3)
    d = ImageDraw.Draw(im)
    # the long white wall of the city
    wall_top = 118 * S
    d.rectangle([0, wall_top, W, 214 * S], fill=(244, 243, 238))
    for x in range(0, W, 14 * S):  # crenellations
        d.rectangle([x, wall_top - 6 * S, x + 8 * S, wall_top], fill=(244, 243, 238))
    d.line([(0, wall_top), (W, wall_top)], fill=(120, 118, 116), width=S)
    d.line([(0, 214 * S), (W, 214 * S)], fill=(90, 88, 86), width=2 * S)
    # gate tower
    gx0, gx1 = 168 * S, 312 * S
    d.rectangle([gx0, 62 * S, gx1, 214 * S], fill=(248, 248, 245), outline=(70, 68, 68), width=S)
    roof = [(gx0 - 26 * S, 66 * S), (gx1 + 26 * S, 66 * S), (gx1 + 6 * S, 40 * S), (gx0 - 6 * S, 40 * S)]
    d.polygon(roof, fill=INK)
    d.polygon([(gx0 - 26 * S, 66 * S), (gx0 - 36 * S, 58 * S), (gx0 - 18 * S, 62 * S)], fill=INK)
    d.polygon([(gx1 + 26 * S, 66 * S), (gx1 + 36 * S, 58 * S), (gx1 + 18 * S, 62 * S)], fill=INK)
    # the opening, dark inside
    ox0, ox1, oy0 = 194 * S, 286 * S, 104 * S
    d.rectangle([ox0, oy0, ox1, 214 * S], fill=(30, 28, 32))
    d.pieslice([ox0, oy0 - 46 * S, ox1, oy0 + 46 * S], 180, 360, fill=(30, 28, 32))
    # faces behind the bars: pale ovals, dark eyes, some hands on the bars
    for i in range(7):
        fx = ox0 + (10 + i * 12.0) * S + rng.integers(-2, 3) * S
        fy = (140 + rng.integers(-12, 16)) * S
        r = rng.integers(7, 9) * S
        d.ellipse([fx - r, fy - r * 1.25, fx + r, fy + r * 1.25], fill=(210, 200, 188))
        d.rectangle([fx - r * 0.55, fy - S, fx - r * 0.2, fy + S], fill=INK)
        d.rectangle([fx + r * 0.2, fy - S, fx + r * 0.55, fy + S], fill=INK)
        if i % 3 == 1:
            d.ellipse([fx - 3 * S, fy + r * 2.1, fx + 3 * S, fy + r * 2.1 + 5 * S], fill=(205, 195, 182))
    # heavy bars over the faces
    for x in range(ox0 + 6 * S, ox1 - 2 * S, 13 * S):
        d.rectangle([x, oy0 - 30 * S, x + 4 * S, 214 * S], fill=(238, 237, 232))
        d.line([(x + 4 * S, oy0 - 30 * S), (x + 4 * S, 214 * S)], fill=(150, 148, 146), width=S)
    d.rectangle([ox0, 176 * S, ox1, 180 * S], fill=(238, 237, 232))
    # foreground road leading away, porcelain statues along it, a small red figure walking off
    road = [(220 * S, 214 * S), (260 * S, 214 * S), (380 * S, H), (40 * S, H)]
    im = wash(road, (205, 196, 182), 2)
    d = ImageDraw.Draw(im)
    for (sx, sy, sc) in ((140, 236, 1.0), (330, 228, 0.9), (100, 258, 1.2)):
        sx, sy = sx * S, sy * S
        w = 7 * S * sc
        d.ellipse([sx - w * 0.6, sy - w * 3.2, sx + w * 0.6, sy - w * 2.0], fill=(236, 238, 240))
        d.polygon([(sx - w, sy), (sx + w, sy), (sx + w * 0.5, sy - w * 2.2), (sx - w * 0.5, sy - w * 2.2)], fill=(232, 234, 236))
        d.line([(sx - w * 0.3, sy - w * 2.8), (sx, sy - w * 1.4)], fill=(120, 130, 140), width=S)
    rx, ry = 70 * S, 262 * S
    d.ellipse([rx - 4 * S, ry - 30 * S, rx + 4 * S, ry - 22 * S], fill=(158, 52, 44))
    d.polygon([(rx - 7 * S, ry), (rx + 7 * S, ry), (rx + 4 * S, ry - 22 * S), (rx - 4 * S, ry - 22 * S)], fill=(150, 46, 40))
    # dry-brush texture and ink speckle
    arr = np.array(im).astype(float)
    n = pnoise(256, 8, seed)
    n = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((W, H))) / 255.0
    arr *= (0.94 + 0.08 * n)[..., None]
    sp = rng.random((H, W)) < 0.0006
    arr[sp] = INK
    # vignette like ink soaking in from the edges
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.hypot((xx - W / 2) / (W / 2), (yy - H / 2) / (H / 2))
    arr = arr * (1 - np.clip(r - 0.78, 0, 1)[..., None] * 1.1)
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    im = im.resize((480, 270), Image.LANCZOS)
    # posterise a little so it sits with the pixel art
    a2 = np.array(im).astype(int)
    a2 = (a2 // 12) * 12 + 6
    im = Image.fromarray(np.clip(a2, 0, 255).astype(np.uint8))
    im = im.resize((480 * 2, 270 * 2), Image.NEAREST)
    return im.convert('RGBA')
