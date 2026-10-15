"""Thử Tro, seen close (docs/N_bach_son.md 4.2, 9.2): the open palm laid on paper, the ash rubbed into it, and the
ash that stays after the water (in the lines of the palm, the creases of the fingers, and the fine crackle that
is the city's fear).

Three layers of the same 64x72 sprite, drawn 4x on the card (scripts/ui/ash_test.gd):
  palm.png         the hand: four fingers a little apart, the thumb out to the right, the pads of the palm,
                   its three lines, the joint creases; the skin ramp of the characters (chars.SKIN); a soft
                   shadow on the paper under it
  palm_ash.png     ash rubbed over palm, wrist and fingers, thinning toward the fingertips
  palm_streak.png  what the water leaves: ash caught in the lines and creases, and a fine crackle in the palm
"""
import os
import numpy as np
from PIL import Image
from pix import Canvas, ramp, hexc
from env import pnoise

W, H = 64, 72
SKIN = ramp('#e3b48e', shadow='#b97f5f', light='#f3d1b0', outline='#4a2a22', hi='#f9e2c8')
LINE = hexc('#96583f')        # the palm's lines: the skin's shadow, a little deeper
CREASE = hexc('#b97f5f')
ROOT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'ui')

# fingers, little to index (the thumb is on the right): base centre x, base y, tip y, half width, lean (px over length)
FINGERS = [(20.5, 33, 15, 2.6, -2.5), (27.0, 31, 8, 2.9, -1.0), (33.5, 30, 5, 3.0, 0.5), (40.0, 31, 9, 2.9, 2.0)]


def _finger(c, bx, by, ty, hw, lean):
    tx = bx + lean
    pts = [(bx - hw, by + 3), (tx - hw, ty + hw), (tx + hw, ty + hw), (bx + hw, by + 3)]
    return c.poly(pts) | c.ellipse(tx + 0.5, ty + hw, hw + 0.5, hw + 0.6)


def shape():
    c = Canvas(W, H)
    parts = {}
    palm = c.material(SKIN, flat=True)   # shaded by hand below: its pads, its cup
    # the palm: wide across the knuckles, the heel rounded by its two pads, narrowing into the wrist
    pm = c.poly([(16, 32), (45, 30), (47, 42), (45, 54), (41, 60), (40, 72), (22, 72), (21, 60), (16, 52), (15, 42)])
    pm |= c.ellipse(41.5, 50, 6.5, 8.5)      # the pad under the thumb
    pm |= c.ellipse(20.5, 50, 5.5, 8.0)      # the pad on the little-finger side
    c.paint(pm, palm)
    parts['palm'] = pm
    fm = np.zeros((H, W), bool)
    for i, (bx, by, ty, hw, lean) in enumerate(FINGERS):
        m = c.material(SKIN)
        f = _finger(c, bx, by, ty, hw, lean)
        f &= ~fm   # keep a gap between neighbours
        c.paint(f, m)
        fm |= f
        parts['f%d' % i] = f
    # a hair's gap between the fingers so the outline runs between them
    for i in range(len(FINGERS) - 1):
        bx = (FINGERS[i][0] + FINGERS[i + 1][0]) * 0.5 + (FINGERS[i][4] + FINGERS[i + 1][4]) * 0.25
        gap = c.line([((FINGERS[i][0] + FINGERS[i + 1][0]) * 0.5, 31), (bx, 4)], 1)
        c.erase(gap & ~pm)
    # the thumb, out from the heel of the palm toward the upper right, two segments
    tm = c.material(SKIN)
    th = c.poly([(42, 50), (44, 40), (51, 30), (56, 25), (60, 29), (55, 37), (49, 47), (46, 55)])
    th |= c.ellipse(57.5, 27.0, 3.3, 3.1)
    c.paint(th, tm)
    parts['thumb'] = th
    return c, parts


def palm():
    c, parts = shape()
    im = np.array(c.render(volume=True))
    a = im[:, :, 3] > 0
    hand = parts['palm'] | parts['thumb'] | np.any([parts['f%d' % i] for i in range(4)], axis=0)

    def put(mask, col):
        sel = mask & hand
        im[sel, :3] = col
        im[sel, 3] = 255

    # the palm by hand: the pads round and lit from the upper left, the cup between them in shade, the side
    # under the thumb and the wrist falling away
    yy, xx = np.mgrid[0:H, 0:W]
    pm = parts['palm']
    e = lambda cx, cy, rx, ry: (((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
    half = hexc('#d0a07e')                                   # between the mid tone and the shadow
    cup = e(31, 45.5, 7.5, 5.5)
    put(pm & (cup < 1.0), half)
    put(pm & (cup < 0.35), SKIN[1])
    put(pm & (cup >= 1.0) & (cup < 1.4) & ((xx + yy) % 2 == 0), half)
    put(pm & (e(39.5, 49, 4.0, 5.5) < 1.0), SKIN[3])        # the mound under the thumb
    put(pm & (e(38.5, 47.5, 1.6, 2.2) < 1.0), SKIN[4])
    put(pm & (e(19.5, 50, 3.0, 5.5) < 1.0), SKIN[3])        # the little-finger side
    put(pm & (e(24, 34.5, 7, 2.0) < 1.0), SKIN[3])          # the pads under the fingers
    put(pm & (e(33, 33.5, 5, 1.6) < 1.0), SKIN[3])
    put(pm & (yy > 62) & (xx > 33), SKIN[1])                # the wrist turning away
    put(pm & (yy > 66), SKIN[1])
    # the three lines of the palm
    heart = c.line([(16, 37), (22, 36), (28, 35.5), (33, 34), (37, 32)], 1)
    head = c.line([(45, 39), (39, 40), (32, 42), (26, 44), (21, 46)], 1)
    life = c.line([(45, 39), (40, 42), (37, 47), (36, 53), (37, 60)], 1)
    for m in (heart, head, life):
        put(m & parts['palm'], LINE)
    # creases at the finger joints and the base of the thumb
    for i, (bx, by, ty, hw, lean) in enumerate(FINGERS):
        L = by - ty
        for t in (0.32, 0.62):
            y = int(round(by - L * t))
            x = bx + lean * t
            put(c.rect(x - hw + 1, y, x + hw - 1, y) & parts['f%d' % i], CREASE)
    put(c.line([(51, 34), (54, 36)], 1) & parts['thumb'], CREASE)
    put(c.line([(19, 63), (24, 64), (30, 64.5), (36, 64), (40, 63)], 1) & parts['palm'], CREASE)   # the wrist
    # the forearm fades out into the paper (a drawn study, not a hand cut off at the wrist): an ordered dither
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    fade = np.clip((yy - 61) / 10.0, 0, 1)
    gone = fade > bayer[yy % 4, xx % 4] + 0.02
    im[gone] = 0
    a = im[:, :, 3] > 0
    hand &= ~gone
    for k in parts:
        parts[k] = parts[k] & ~gone
    # a soft shadow on the paper under the hand
    sh = np.zeros((H, W), bool)
    sh[3:, 2:] = a[:-3, :-2]
    sh &= ~a
    im[sh] = (60, 40, 30, 70)
    return Image.fromarray(im, 'RGBA'), hand, (heart | head | life) & parts['palm'], parts


def palm_ash(hand, seed=5):
    ## ash rubbed in: grey-white, clotted, thinner toward the fingertips and the edges
    yy, xx = np.mgrid[0:H, 0:W]
    n = pnoise(64, 8, seed)[:H % 64 or 64, :W]
    n = np.vstack([n, pnoise(64, 8, seed + 3)])[:H, :W]
    fine = pnoise(64, 32, seed + 7)
    fine = np.vstack([fine, fine])[:H, :W]
    v = n * 0.6 + fine * 0.4
    reach = np.clip((yy - 6) / 30.0, 0, 1)          # less on the fingertips
    on = hand & (v + reach * 0.35 > 0.6)
    out = np.zeros((H, W, 4), np.uint8)
    pal = [hexc('#a7a29a'), hexc('#bdb8af'), hexc('#d2cec5'), hexc('#e4e1da')]
    k = np.clip(((v - 0.4) * 6).astype(int), 0, 3)
    for i in range(4):
        s = on & (k == i)
        out[s, :3] = pal[i]
        out[s, 3] = 225
    thin = hand & ~on & (v + reach * 0.35 > 0.5) & ((xx + yy) % 2 == 0)   # a thin dusting at the edges of it
    out[thin, :3] = pal[2]
    out[thin, 3] = 200
    # loose grains on the paper round the hand
    rng = np.random.default_rng(seed)
    near = ~hand & (np.hypot(xx - 31, yy - 42) < 30)
    grains = near & (rng.random((H, W)) < 0.025)
    out[grains, :3] = pal[1]
    out[grains, 3] = 200
    return Image.fromarray(out, 'RGBA')


def palm_streak(hand, lines, parts, seed=9):
    ## after the water: the ash holds in the lines and creases, and in a fine crackle across the palm (the
    ## crackle of the glaze, the thing the city fears)
    out = np.zeros((H, W, 4), np.uint8)
    grey = hexc('#7f7b75')
    pale = hexc('#a19d96')
    out[lines, :3] = grey
    out[lines, 3] = 255
    for i, (bx, by, ty, hw, lean) in enumerate(FINGERS):
        L = by - ty
        for t in (0.32, 0.62):
            y = int(round(by - L * t))
            x = bx + lean * t
            for xx in range(int(x - hw + 1), int(x + hw)):
                if 0 <= xx < W and parts['f%d' % i][y, xx]:
                    out[y, xx, :3] = pale
                    out[y, xx, 3] = 230
    # the crackle: short branching cracks from a few points in the palm
    rng = np.random.default_rng(seed)
    palm_m = parts['palm']
    for sx, sy in [(30, 47), (35, 51), (26, 52), (32, 40)]:
        for _ in range(3):
            x, y = float(sx), float(sy)
            ang = rng.uniform(0, 2 * np.pi)
            for step in range(int(rng.integers(4, 8))):
                ang += rng.uniform(-0.7, 0.7)
                x += np.cos(ang)
                y += np.sin(ang)
                ix, iy = int(round(x)), int(round(y))
                if 0 <= ix < W and 0 <= iy < H and palm_m[iy, ix]:
                    out[iy, ix, :3] = grey if step < 3 else pale
                    out[iy, ix, 3] = 255
    return Image.fromarray(out, 'RGBA')


def build():
    im, hand, lines, parts = palm()
    im.save(os.path.join(ROOT, 'palm.png'))
    palm_ash(hand).save(os.path.join(ROOT, 'palm_ash.png'))
    palm_streak(hand, lines, parts).save(os.path.join(ROOT, 'palm_streak.png'))


if __name__ == '__main__':
    build()
    print('ok')
