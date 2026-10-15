"""十字 (Thập Tự), written with the brush of ink_brush.py, for the title screen. Run from the project root.

The author's concept for the title screen has its title in two big brush characters stacked over the sky, pale on the dark,
the name in small capitals under them. The game's name is now Thập Tự - Đoạn Nghiệt (2026-10-13); Tự is 字
(docs/B_luat_the_gioi.md, A2 A12a), so the characters are 十字: two strokes crossing, then the character for a
written word. No font is used: each stroke is laid by hand along its centre line, pressed at the start, thin
through the middle, pressed again where a calligrapher stops, drying out toward the lift.

  assets/ui/title_hanzi.png   十 over 字, white ink, a soft glow behind it so it reads on the sky
"""
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ink_brush import Ink, bezier  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'ui')
G = 330          # one character, px (at 3x; shown about 110 px high)
M = 0.11         # margin, fraction of G


def W(*knots):
    """width(u) through (u, width) knots, in units of the character's box (0..100)."""
    us = np.array([k[0] for k in knots])
    ws = np.array([k[1] for k in knots])
    return lambda u: float(np.interp(u, us, ws))


def P(*pts):
    return np.array(pts, float)


# each stroke: centre line (0..100 box), width curve, dryness, seed
SHI = [
    (P((7, 48), (26, 46), (52, 44), (76, 42), (93, 40)), W((0, 12.5), (0.12, 9.5), (0.8, 9.0), (0.93, 11.0), (1, 7.5)), 0.45, 3),
    (P((51, 5), (50.5, 30), (49.6, 58), (48.8, 82), (48.4, 98)), W((0, 14.0), (0.15, 12.0), (0.6, 11.0), (0.85, 7.0), (1, 1.2)), 0.55, 7),
]
ZI = [
    (P((46, 2), (49, 6), (53, 12)), W((0, 7.0), (0.5, 11.5), (1, 5.0)), 0.08, 11),                       # the dot
    (P((17, 20), (16.0, 29), (14.0, 39)), W((0, 9.5), (0.5, 8.0), (1, 4.5)), 0.1, 12),                 # the short drop
    (P((17, 22), (40, 20.5), (66, 18.5), (82, 17), (86, 19.5), (82, 28), (75, 36)),
     W((0, 8.5), (0.15, 7.0), (0.7, 7.0), (0.8, 10.5), (0.9, 7.0), (1, 2.5)), 0.18, 13),               # the roof's top and hook
    (P((29, 41), (45, 40), (60, 38.6), (70, 38), (64, 43), (57, 48), (52, 52)),
     W((0, 8.5), (0.2, 7.0), (0.55, 7.0), (0.62, 10.0), (0.8, 7.5), (1, 6.0)), 0.15, 17),             # 子: across, then down left
    (P((51.5, 50), (52, 64), (51.6, 78), (50.8, 90), (45, 95), (35, 88)),
     W((0, 12.0), (0.2, 11.0), (0.7, 10.0), (0.82, 11.5), (0.9, 7.0), (1, 2.0)), 0.22, 19),            # down, the hook
    (P((7, 69), (30, 67.5), (55, 66), (80, 64), (93, 62.5)), W((0, 10.5), (0.15, 8.0), (0.8, 8.0), (0.93, 10.5), (1, 7.0)), 0.38, 23),
]


def glyph(strokes):
    ink = Ink(G, G)
    k = G * (1 - 2 * M) / 100.0
    off = G * M
    for pts, wf, dry, seed in strokes:
        pts_px = pts * k + off
        # smooth the centre line a little (a hand does not move in straight segments)
        fine = []
        for a, b in zip(pts_px[:-1], pts_px[1:]):
            for t in np.linspace(0, 1, 8, endpoint=False):
                fine.append(a * (1 - t) + b * t)
        fine.append(pts_px[-1])
        fine = ndi.gaussian_filter1d(np.array(fine), 1.6, axis=0, mode='nearest')
        ink.stroke(fine, lambda u, wf=wf: wf(u) * k * 1.42, seed=seed, dry=dry, rough=0.16, hairs=40, pool=0.2)
    return ink


def render(ink):
    a = ink.a
    white = np.array([240, 238, 232], float)
    grey = np.array([170, 176, 188], float)
    col = white[None, None, :] * ink.dark[..., None] + grey[None, None, :] * (1 - ink.dark[..., None])
    glow = ndi.gaussian_filter(a, G * 0.045)
    glow = np.clip(glow * 1.4, 0, 1) * 0.42
    shade = ndi.gaussian_filter(a, G * 0.02)
    out = np.zeros(a.shape + (4,))
    # a dark halo under the ink (it sits on a bright sky in places), then a pale glow, then the ink
    sa = np.clip(shade * 1.2, 0, 1) * 0.35
    out[..., :3] = 0
    out[..., 3] = sa
    gc = np.array([200, 214, 236], float)
    na = out[..., 3] + glow * (1 - out[..., 3])
    out[..., :3] = (out[..., :3] * out[..., 3:4] * (1 - glow[..., None]) + gc * glow[..., None]) / np.maximum(na, 1e-6)[..., None]
    out[..., 3] = na
    na = out[..., 3] + a * (1 - out[..., 3])
    out[..., :3] = (out[..., :3] * out[..., 3:4] * (1 - a[..., None]) + col * a[..., None]) / np.maximum(na, 1e-6)[..., None]
    out[..., 3] = na
    out[..., 3] *= 255
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGBA')


def build():
    a = render(glyph(SHI))
    b = render(glyph(ZI))
    im = Image.new('RGBA', (G, G * 2 - int(G * 0.12)), (0, 0, 0, 0))
    im.alpha_composite(a, (0, 0))
    im.alpha_composite(b, (0, G - int(G * 0.12)))
    im.save(os.path.join(ROOT, 'title_hanzi.png'))


if __name__ == '__main__':
    build()
    print('ok')
