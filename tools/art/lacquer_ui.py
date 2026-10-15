"""Lacquer UI (cổ trang), the whole of it. Run from the project root: python tools/art/lacquer_ui.py

The first box (paper_ui.py: xuyến chỉ paper in a brush line, a branch of pink mai, a red seal, petals falling) read
as a Tết card ("như coi phim Tết"): calligraphy on cream paper under peach blossom is what the ông đồ sells at New
Year. A period piece speaks through the furniture of a palace instead: a board of black lacquer framed in cánh gián
brown (the old sơn mài brown, not red: red and gold together are Tết again), gold leaf ruled round it, a hồi văn
(key fret) at each corner; the speaker's name on a small plaque of dark son with cut corners, like the board over a
door; choices are lacquer bars, the one picked lighter and edged brighter.

  assets/ui/dlg_lacquer.png     1000x240, the box at (30, 32)-(970, 208) as in dialogue.gd, with its drop shadow
  assets/ui/name_plaque.png     9-patch, margins 22 / 12
  assets/ui/choice_bar.png      9-patch, margins 26 / 10 (a choice not picked)
  assets/ui/choice_bar_sel.png  the same, picked; also the button under the cursor in every menu
  assets/ui/panel_lacquer.png   9-patch, margins 32: every panel (menus, settings, guide cards, Sổ ghi, picture
                                cards, the battle menus, the day slip)
  assets/ui/obj_strip.png       9-patch, margins 44 / 200: the "việc cần làm" strip, fading out to the right
  assets/ui/band_center.png     the chapter card's band, fading at both ends
  assets/ui/band_left.png       the name card's band (a big Nghiệt, Băng Tâm), solid at the left, fading right
  assets/ui/title_plaque.png    the title's board, a hoành phi
  assets/ui/bar_trough.png      9-patch, margins 6: a bar's trough (Hình, Nghi)
  assets/ui/bar_fill_flat.png   9-patch, margins 4: its fill, white, tinted in code
  assets/ui/toggle_on.png / toggle_off.png   a switch in the settings

Drawn three times over and scaled down, so the gold reads as fine lines rather than pixel steps.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 3
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'ui')
LACQ = np.array([20, 15, 14], float)       # black lacquer, a little warm
GIAN = np.array([54, 32, 23], float)       # cánh gián: the brown of old sơn mài
SON = np.array([80, 25, 19], float)        # cinnabar lacquer, dark and old (the name plaque only)
GOLD = (196, 160, 98)
GOLD_HI = (236, 210, 150)
GOLD_LO = (92, 66, 34)


def _chamfer(x0, y0, x1, y1, c):
    return [(x0 + c, y0), (x1 - c, y0), (x1, y0 + c), (x1, y1 - c), (x1 - c, y1), (x0 + c, y1), (x0, y1 - c), (x0, y0 + c)]


def _mask(w, h, poly):
    m = Image.new('L', (w, h), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    return np.asarray(m).astype(float) / 255.0


def _grain(w, h, seed, amp):
    """Lacquer is not flat: long faint streaks along the board, and a finer mottle."""
    rng = np.random.default_rng(seed)
    long = Image.fromarray((rng.random((max(2, h // (S * 3)), max(2, w // (S * 40)))) * 255).astype(np.uint8))
    long = np.asarray(long.resize((w, h), Image.BICUBIC)).astype(float) / 255.0 - 0.5
    fine = Image.fromarray((rng.random((max(2, h // S), max(2, w // S))) * 255).astype(np.uint8))
    fine = np.asarray(fine.resize((w, h), Image.BILINEAR)).astype(float) / 255.0 - 0.5
    return (long * 1.0 + fine * 0.5) * amp


def _gold_line(dr, pts, width, closed=False):
    """A ruled gold line, a darker line under it and to the lower right, so it sits in the lacquer like leaf."""
    if closed:
        pts = list(pts) + [pts[0]]
    o = max(1, S // 2)
    dr.line([(x + o, y + o) for x, y in pts], fill=GOLD_LO + (255,), width=width, joint='curve')
    dr.line(pts, fill=GOLD + (255,), width=width, joint='curve')


def _fret(dr, x, y, s, sx, sy, width):
    """A hồi văn: a squared spiral in an s x s cell whose corner is at (x, y), turning inward (sx, sy = +-1)."""
    unit = [(0.0, 1.0), (0.0, 0.0), (1.0, 0.0), (1.0, 0.74), (0.26, 0.74), (0.26, 0.26), (0.62, 0.26), (0.62, 0.5)]
    _gold_line(dr, [(x + sx * u * s, y + sy * v * s) for u, v in unit], width)


def _compose(w, h, layers):
    """layers: (rgb array, alpha array) bottom to top."""
    rgb = np.zeros((h, w, 3))
    a = np.zeros((h, w))
    for col, al in layers:
        rgb = rgb * (1 - al[..., None]) + col * al[..., None]
        a = a + al * (1 - a)
    rgb = np.where(a[..., None] > 0, rgb, 0)
    return rgb, a


def _board(w, h, outer, inner, seed, center=LACQ, band=GIAN, center_a=0.84, band_a=0.96):
    """A son frame band round a black lacquer field, with grain and a soft sheen from above."""
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    mo = _mask(w, h, outer)
    mi = _mask(w, h, inner)
    g = _grain(w, h, seed, 9.0)
    sheen = np.clip(1.0 - yy / 0.45, 0, 1) ** 2 * 10.0     # light from above on the lacquer
    band_rgb = band[None, None, :] + g[..., None] + sheen[..., None] * 0.6
    cen_rgb = center[None, None, :] + g[..., None] * 0.6 + sheen[..., None]
    rgb, a = _compose(w, h, [(band_rgb, mo * band_a), (cen_rgb, mi * center_a)])
    return rgb, a


def _to_image(rgb, a, w, h):
    arr = np.dstack([np.clip(rgb, 0, 255), np.clip(a * 255, 0, 255)]).astype(np.uint8)
    return Image.fromarray(arr, 'RGBA')


def _shadow(w, h, poly, blur, alpha):
    m = Image.new('L', (w, h), 0)
    ImageDraw.Draw(m).polygon(poly, fill=int(255 * alpha))
    m = m.filter(ImageFilter.GaussianBlur(blur))
    sh = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sh.putalpha(m)
    return sh


def dialogue_box():
    W, H = 1000, 240
    w, h = W * S, H * S
    x0, y0, x1, y1 = 30 * S, 32 * S, 970 * S, 208 * S
    c = 10 * S
    outer = _chamfer(x0, y0, x1, y1, c)
    b = 9 * S                                    # the cánh gián band
    inner = _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 4 * S)
    rgb, a = _board(w, h, outer, inner, 3)
    im = _shadow(w, h, _chamfer(x0 + 3 * S, y0 + 8 * S, x1 + 3 * S, y1 + 10 * S, c), 9 * S, 0.55)
    im.alpha_composite(_to_image(rgb, a, w, h))
    dr = ImageDraw.Draw(im)
    # gold: the outer edge, a line inside the band, the field's edge
    _gold_line(dr, _chamfer(x0 + 2 * S, y0 + 2 * S, x1 - 2 * S, y1 - 2 * S, c - 1 * S), 2 * S, True)
    _gold_line(dr, _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 4 * S), S, True)
    # a hồi văn in each corner of the field, and a short rule running on from it along each edge
    s = 22 * S
    m = b + 6 * S
    for (cx, cy, sx, sy) in ((x0 + m, y0 + m, 1, 1), (x1 - m, y0 + m, -1, 1), (x0 + m, y1 - m, 1, -1), (x1 - m, y1 - m, -1, -1)):
        _fret(dr, cx, cy, s, sx, sy, 2 * S)
        _gold_line(dr, [(cx + sx * (s + 6 * S), cy), (cx + sx * (s + 70 * S), cy)], S)
        _gold_line(dr, [(cx, cy + sy * (s + 6 * S)), (cx, cy + sy * (s + 22 * S))], S)
    # a small gold lozenge at the foot of the board, on the band
    mx, my = (x0 + x1) // 2, y1 - b // 2 - S
    _gold_line(dr, [(mx - 7 * S, my), (mx, my - 4 * S), (mx + 7 * S, my), (mx, my + 4 * S)], S, True)
    _gold_line(dr, [(mx - 40 * S, my), (mx - 12 * S, my)], S)
    _gold_line(dr, [(mx + 12 * S, my), (mx + 40 * S, my)], S)
    return im.resize((W, H), Image.LANCZOS)


def name_plaque():
    W, H = 160, 46
    w, h = W * S, H * S
    c = 8 * S
    outer = _chamfer(1 * S, 1 * S, w - 1 * S, h - 1 * S, c)
    rgb, a = _board(w, h, outer, _chamfer(4 * S, 4 * S, w - 4 * S, h - 4 * S, c - 2 * S), 5,
                    center=SON, band=SON * 0.75, center_a=0.98, band_a=0.98)
    im = _to_image(rgb, a, w, h)
    dr = ImageDraw.Draw(im)
    _gold_line(dr, _chamfer(2 * S, 2 * S, w - 2 * S, h - 2 * S, c - 1 * S), 2 * S, True)
    _gold_line(dr, _chamfer(6 * S, 6 * S, w - 6 * S, h - 6 * S, c - 3 * S), S, True)
    return im.resize((W, H), Image.LANCZOS)


def choice_bar(sel):
    W, H = 300, 44
    w, h = W * S, H * S
    c = 7 * S
    outer = _chamfer(2 * S, 2 * S, w - 2 * S, h - 2 * S, c)
    if sel:
        rgb, a = _board(w, h, outer, _chamfer(5 * S, 5 * S, w - 5 * S, h - 5 * S, c - 2 * S), 7,
                        center=GIAN * 1.15, band=GIAN * 0.8, center_a=0.95, band_a=0.97)
    else:
        rgb, a = _board(w, h, outer, _chamfer(5 * S, 5 * S, w - 5 * S, h - 5 * S, c - 2 * S), 8,
                        center=LACQ, band=LACQ * 1.4, center_a=0.8, band_a=0.86)
    im = _shadow(w, h, _chamfer(4 * S, 6 * S, w, h, c), 4 * S, 0.45)
    im.alpha_composite(_to_image(rgb, a, w, h))
    dr = ImageDraw.Draw(im)
    _gold_line(dr, _chamfer(3 * S, 3 * S, w - 3 * S, h - 3 * S, c - 1 * S), (2 if sel else 1) * S, True)
    if sel:   # a lozenge at each end
        for ex in (14 * S, w - 14 * S):
            _gold_line(dr, [(ex - 4 * S, h // 2), (ex, h // 2 - 4 * S), (ex + 4 * S, h // 2), (ex, h // 2 + 4 * S)], S, True)
    return im.resize((W, H), Image.LANCZOS)


def panel(solid=False):
    W, H = 160, 120
    w, h = W * S, H * S
    c, b = 9 * S, 7 * S
    x0, y0, x1, y1 = 3 * S, 3 * S, w - 3 * S, h - 6 * S
    outer = _chamfer(x0, y0, x1, y1, c)
    rgb, a = _board(w, h, outer, _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 3 * S), 11, center_a=0.99 if solid else 0.88)
    im = _shadow(w, h, _chamfer(x0 + 2 * S, y0 + 5 * S, x1 + 2 * S, y1 + 5 * S, c), 3 * S, 0.5)
    im.alpha_composite(_to_image(rgb, a, w, h))
    dr = ImageDraw.Draw(im)
    _gold_line(dr, _chamfer(x0 + 2 * S, y0 + 2 * S, x1 - 2 * S, y1 - 2 * S, c - S), 2 * S, True)
    _gold_line(dr, _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 3 * S), S, True)
    s_, m = 13 * S, b + 5 * S
    for (cx, cy, sx, sy) in ((x0 + m, y0 + m, 1, 1), (x1 - m, y0 + m, -1, 1), (x0 + m, y1 - m, 1, -1), (x1 - m, y1 - m, -1, -1)):
        _fret(dr, cx, cy, s_, sx, sy, int(1.5 * S))
    return im.resize((W, H), Image.LANCZOS)


def _fade_x(w, h, solid_to, both=False):
    """Alpha along x: 1 up to solid_to (a fraction), then down to 0 at the right end (and mirrored at the left)."""
    x = np.linspace(0, 1, w)[None, :] * np.ones((h, 1))
    f = np.clip((1.0 - x) / max(1.0 - solid_to, 1e-3), 0, 1)
    if both:
        f = np.minimum(f, np.clip(x / max(1.0 - solid_to, 1e-3), 0, 1))
    return f ** 1.4


def _band(W, H, top, bot, solid_to, both, seed, ornament):
    """A lacquer band between top and bot (px), ruled in gold along both edges, fading out along x."""
    w, h = W * S, H * S
    rgb, a = _board(w, h, [(0, top * S), (w, top * S), (w, bot * S), (0, bot * S)],
                    [(0, (top + 4) * S), (w, (top + 4) * S), (w, (bot - 4) * S), (0, (bot - 4) * S)], seed, center_a=0.9)
    im = _to_image(rgb, a, w, h)
    lines = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(lines)
    for y in (top + 1.5, bot - 1.5):
        _gold_line(dr, [(0, y * S), (w, y * S)], 2 * S)
    for y in (top + 5, bot - 5):
        _gold_line(dr, [(0, y * S), (w, y * S)], S)
    if ornament == 'left':      # a small fret at the head of the band, behind a gold upright
        mid = (top + bot) / 2
        _fret(dr, 17 * S, (mid - 7) * S, 14 * S, 1, 1, int(1.5 * S))
        _gold_line(dr, [(10 * S, (top + 5) * S), (10 * S, (bot - 5) * S)], 2 * S)
    elif ornament == 'center':  # a lozenge on the lower rule, in the middle
        mx, my = w // 2, int((bot - 1.5) * S)
        _gold_line(dr, [(mx - 9 * S, my), (mx, my - 5 * S), (mx + 9 * S, my), (mx, my + 5 * S)], int(1.5 * S), True)
    im.alpha_composite(lines)
    arr = np.asarray(im).astype(float)
    arr[..., 3] *= _fade_x(w, h, solid_to, both)
    im = Image.fromarray(arr.astype(np.uint8), 'RGBA')
    return im.resize((W, H), Image.LANCZOS)


def obj_strip():
    return _band(520, 66, 2, 64, 0.55, False, 13, 'left')


def band_center():
    return _band(900, 150, 22, 128, 0.62, True, 17, 'center')


def band_left():
    return _band(830, 184, 16, 168, 0.5, False, 19, None)


def title_plaque():
    W, H = 1000, 210
    w, h = W * S, H * S
    x0, y0, x1, y1 = 24 * S, 20 * S, 976 * S, 186 * S
    c, b = 16 * S, 15 * S
    outer = _chamfer(x0, y0, x1, y1, c)
    rgb, a = _board(w, h, outer, _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 6 * S), 23, center_a=0.86, band_a=0.97)
    im = _shadow(w, h, _chamfer(x0 + 4 * S, y0 + 10 * S, x1 + 4 * S, y1 + 12 * S, c), 10 * S, 0.6)
    im.alpha_composite(_to_image(rgb, a, w, h))
    dr = ImageDraw.Draw(im)
    _gold_line(dr, _chamfer(x0 + 3 * S, y0 + 3 * S, x1 - 3 * S, y1 - 3 * S, c - S), 3 * S, True)
    _gold_line(dr, _chamfer(x0 + 8 * S, y0 + 8 * S, x1 - 8 * S, y1 - 8 * S, c - 3 * S), S, True)
    _gold_line(dr, _chamfer(x0 + b, y0 + b, x1 - b, y1 - b, c - 6 * S), 2 * S, True)
    s_, m = 30 * S, b + 8 * S
    for (cx, cy, sx, sy) in ((x0 + m, y0 + m, 1, 1), (x1 - m, y0 + m, -1, 1), (x0 + m, y1 - m, 1, -1), (x1 - m, y1 - m, -1, -1)):
        _fret(dr, cx, cy, s_, sx, sy, 3 * S)
        _gold_line(dr, [(cx + sx * (s_ + 8 * S), cy), (cx + sx * (s_ + 120 * S), cy)], S)
    for my in (y0 + b // 2 + S, y1 - b // 2 - S):
        mx = (x0 + x1) // 2
        _gold_line(dr, [(mx - 12 * S, my), (mx, my - 5 * S), (mx + 12 * S, my), (mx, my + 5 * S)], int(1.5 * S), True)
    return im.resize((W, H), Image.LANCZOS)


def bar_trough():
    W, H = 64, 16
    w, h = W * S, H * S
    c = 3 * S
    outer = _chamfer(0, 0, w - 1, h - 1, c)
    rgb, a = _board(w, h, outer, _chamfer(2 * S, 2 * S, w - 2 * S, h - 2 * S, c - S), 29,
                    center=LACQ * 0.6, band=GIAN * 0.7, center_a=0.92, band_a=0.95)
    im = _to_image(rgb, a, w, h)
    dr = ImageDraw.Draw(im)
    dr.line(_chamfer(int(0.5 * S), int(0.5 * S), w - S, h - S, c) + [_chamfer(int(0.5 * S), int(0.5 * S), w - S, h - S, c)[0]],
            fill=GOLD_LO + (255,), width=S)
    return im.resize((W, H), Image.LANCZOS)


def bar_fill_flat():
    W, H = 64, 16
    im = np.zeros((H, W, 4), np.uint8)
    for y in range(2, H - 2):
        t = (y - 2) / (H - 5)
        v = 255 if t < 0.25 else int(255 - 70 * (t - 0.25) / 0.75)   # lit along the top, darker below
        im[y, 2:W - 2, :3] = v
        im[y, 2:W - 2, 3] = 255
    return Image.fromarray(im, 'RGBA')


def toggle(on):
    """A switch for the settings: a lacquer track ruled in gold, a gold knob (on: to the right, the track warm)."""
    W, H = 44, 22
    w, h = W * S, H * S
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = h // 2 - S
    d.rounded_rectangle([S, S, w - S, h - S], radius=r, fill=(tuple(int(v) for v in (GIAN * 1.4 if on else LACQ * 1.6)) + (255,)),
                        outline=(GOLD if on else GOLD_LO) + (255,), width=int(1.5 * S))
    kx = w - h // 2 - S if on else h // 2 + S
    kr = r - 3 * S
    d.ellipse([kx - kr, h // 2 - kr, kx + kr, h // 2 + kr], fill=(GOLD_HI if on else (120, 106, 86)) + (255,))
    return im.resize((W, H), Image.LANCZOS)


def build():
    dialogue_box().save(os.path.join(ROOT, 'dlg_lacquer.png'))
    name_plaque().save(os.path.join(ROOT, 'name_plaque.png'))
    choice_bar(False).save(os.path.join(ROOT, 'choice_bar.png'))
    choice_bar(True).save(os.path.join(ROOT, 'choice_bar_sel.png'))
    panel().save(os.path.join(ROOT, 'panel_lacquer.png'))
    panel(True).save(os.path.join(ROOT, 'panel_lacquer_solid.png'))
    obj_strip().save(os.path.join(ROOT, 'obj_strip.png'))
    band_center().save(os.path.join(ROOT, 'band_center.png'))
    band_left().save(os.path.join(ROOT, 'band_left.png'))
    title_plaque().save(os.path.join(ROOT, 'title_plaque.png'))
    bar_trough().save(os.path.join(ROOT, 'bar_trough.png'))
    bar_fill_flat().save(os.path.join(ROOT, 'bar_fill_flat.png'))
    toggle(True).save(os.path.join(ROOT, 'toggle_on.png'))
    toggle(False).save(os.path.join(ROOT, 'toggle_off.png'))


if __name__ == '__main__':
    build()
    print('ok')
