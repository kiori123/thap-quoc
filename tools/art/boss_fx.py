"""The pieces of Trắng Tay's entrance (the author's reference: a monumental low shot, a great ring of light
behind its head, broken stone and porcelain lifting off the ground, black ink flung out round its base, its
name brushed across the lower left).

halo_ring    additive ring of cold light with faint spokes, for behind the crown        -> sprites/fx
ink_burst    a black splash flung out on the ground (projected as a decal)              -> sprites/fx
debris       three chunks of broken stone, pixel art                                     -> sprites/fx
name_banner  a heavy, ragged stroke of ink with splashes, under a boss's name            -> ui
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import paper_ui as PU


def halo_ring():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n].astype(float)
    c = n / 2
    r = np.hypot(xx - c, yy - c) / c
    ang = np.arctan2(yy - c, xx - c)
    ring = np.exp(-((r - 0.78) / 0.018) ** 2) + 0.55 * np.exp(-((r - 0.78) / 0.07) ** 2)
    inner = np.exp(-((r - 0.62) / 0.008) ** 2) * 0.5
    disc = np.clip(1 - r / 0.8, 0, 1) ** 1.6 * 0.28
    spokes = (np.cos(ang * 12) * 0.5 + 0.5) ** 30 * np.clip((r - 0.3) / 0.3, 0, 1) * np.clip((0.95 - r) / 0.2, 0, 1) * 0.35
    glow = np.exp(-((r - 0.78) / 0.25) ** 2) * 0.25
    v = np.clip(ring + inner + disc + spokes + glow, 0, 1)
    out = np.zeros((n, n, 4), np.uint8)
    out[..., 0] = 200
    out[..., 1] = 222
    out[..., 2] = 255
    out[..., 3] = (v * 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def ink_burst():
    n = 512
    k = 2
    im = Image.new('L', (n * k, n * k), 0)
    dr = ImageDraw.Draw(im)
    rng = np.random.default_rng(13)
    c = n * k / 2
    dr.ellipse([c - 70 * k, c - 60 * k, c + 70 * k, c + 60 * k], fill=230)
    for i in range(46):   # streaks flung outward, thick at the root, thin and broken at the tip
        a = rng.uniform(0, 2 * math.pi)
        L = rng.uniform(90, 240) * k
        w0 = rng.uniform(8, 22) * k
        steps = 24
        for s in range(steps):
            u = s / steps
            rr = 50 * k + L * u
            w = w0 * (1 - u) ** 1.3
            if u > 0.6 and rng.random() < 0.3:
                continue
            x, y = c + math.cos(a) * rr, c + math.sin(a) * rr * 0.92
            dr.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=230)
    for i in range(160):  # droplets
        a = rng.uniform(0, 2 * math.pi)
        rr = rng.uniform(120, 250) * k
        w = rng.uniform(2, 9) * k
        x, y = c + math.cos(a) * rr, c + math.sin(a) * rr
        dr.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=220)
    im = im.filter(ImageFilter.GaussianBlur(1.2 * k)).resize((n, n), Image.LANCZOS)
    a = np.array(im)
    out = np.zeros((n, n, 4), np.uint8)
    out[..., :3] = (14, 12, 16)
    out[..., 3] = a
    return Image.fromarray(out, 'RGBA')


def debris():
    """Three chunks of broken stone, 16x16 each in a row (pixel art: dark slate, a lit top edge)."""
    out = Image.new('RGBA', (48, 16), (0, 0, 0, 0))
    rng = np.random.default_rng(3)
    for f in range(3):
        im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        pts = []
        m = 7
        for i in range(m):
            a = i / m * 2 * math.pi + rng.uniform(-0.3, 0.3)
            rr = rng.uniform(4.0, 7.0)
            pts.append((8 + math.cos(a) * rr, 8 + math.sin(a) * rr * 0.85))
        dr.polygon(pts, fill=(52, 54, 66, 255), outline=(18, 18, 24, 255))
        top = [p for p in pts if p[1] < 8]
        if len(top) >= 2:
            dr.line(top, fill=(120, 128, 152, 255), width=1)
        dr.point([(8 + rng.integers(-2, 3), 8 + rng.integers(-2, 3)) for _ in range(4)], fill=(80, 84, 100, 255))
        out.alpha_composite(im, (f * 16, 0))
    return out


def name_banner():
    """A heavy stroke of ink, ragged at both ends, splashes flung off its tail, for under a boss's name."""
    import ui_art
    W, H = 780, 180
    base = ui_art.brush_stroke(W, H, 23)
    k = 2
    im = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    im.alpha_composite(base.resize((W * k, H * k), Image.LANCZOS))
    dr = ImageDraw.Draw(im)
    rng = np.random.default_rng(17)
    for i in range(90):    # splashes off the tail and a few off the head
        tail = rng.random() < 0.8
        x = rng.uniform(W * 0.62, W - 4) if tail else rng.uniform(4, W * 0.12)
        y = H * 0.5 + rng.normal(0, 34)
        w = rng.uniform(0.8, 5.5)
        dr.ellipse([(x - w) * k, (y - w) * k, (x + w) * k, (y + w) * k], fill=(18, 15, 18, 235))
    for i in range(6):     # dry flicks off the end
        y = H * 0.5 + rng.normal(0, 18)
        x0 = W * rng.uniform(0.8, 0.9)
        dr.line([x0 * k, y * k, (x0 + rng.uniform(40, 90)) * k, (y + rng.normal(0, 6)) * k], fill=(18, 15, 18, 200), width=k * 2)
    return im.filter(ImageFilter.GaussianBlur(0.6 * k)).resize((W, H), Image.LANCZOS)


FX = {'halo_ring': halo_ring, 'ink_burst': ink_burst, 'debris': debris}
UI = {'name_banner': name_banner}
