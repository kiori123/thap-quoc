"""UI pieces, battle FX sprites, the ink-brush title stroke and the Nối vision painting."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from pix import Canvas, ramp, hexc
from env import pnoise, stretch

INK = (16, 14, 18)
GOLD = hexc('#b89a5a')
GOLD_D = hexc('#7a6236')
RED = hexc('#a33a30')


def panel():
    """9-patch panel (128x128, texture margins 32): one broad stroke of sumi ink laid across the paper. The left
    end is the heavy, rounded press of the brush; the top and bottom edges waver and break into bristle lines;
    the right end runs dry, each bristle stopping at its own place; a thin grey bleed shows where the ink crept
    into the paper; a small cinnabar seal is stamped at the lower right. Edge detail runs along the edge's own
    length, so stretching the 9-patch only lengthens the bristles."""
    n = 128
    rng = np.random.default_rng(11)
    yy, xx = np.mgrid[0:n, 0:n].astype(float)
    yi = yy.astype(int)
    row_a = rng.random(n)
    row_b = rng.random(n)
    row_c = rng.random(n)
    # wavering top and bottom edges
    top = 4.0 + 1.8 * np.sin(xx * 0.07 + 1.3) + 1.0 * np.sin(xx * 0.23)
    bot = (n - 5.0) + 1.6 * np.sin(xx * 0.06 + 4.0) + 1.0 * np.sin(xx * 0.19 + 2.0)
    dv = np.minimum(yy - top, bot - yy)                 # distance inside the stroke from its edge
    # the rows next to the edge are bristles: some there, some not
    filled = (dv >= 5) | ((dv >= 0) & (row_a[yi] > 0.2 + 0.1 * (5 - dv)))
    # the left end: round where the brush pressed down
    dvc = np.clip(np.minimum(yy, n - 1 - yy), 0, 16)
    x0 = 4.0 + 16.0 - np.sqrt(np.clip(256.0 - (16.0 - dvc) ** 2, 0, None)) + row_b[yi] * 1.2
    # the right end: dry, every bristle ends at its own place
    x1 = (n - 1) - (2.0 + row_c[yi] * 15.0 + np.clip(14.0 - dvc, 0, None) ** 2 / 9.0)
    body = filled & (xx >= x0) & (xx <= x1)
    gap = (xx > x1 - 8 - row_a[yi] * 18) & (row_b[yi] < 0.35)
    body &= ~(gap & (rng.random((n, n)) < 0.55))
    # bleed: just outside the stroke, a thin grey halo where the ink crept into the paper
    from scipy import ndimage as ndi  # noqa: E402
    near = ndi.binary_dilation(body, iterations=2) & ~body
    a = np.zeros((n, n, 4), np.float64)
    streak = (row_a[yi] - 0.5) * 12.0 + (pnoise(n, 3, 21) - 0.5) * 8.0
    dry = np.clip((xx - (x1 - 30)) / 30.0, 0, 1) * 10.0           # lighter where the brush ran dry
    pool = np.exp(-np.clip(xx - x0, 0, None) / 9.0) * 8.0          # darker where it came down
    shade = 22 + streak + dry - pool
    a[..., 0] = shade
    a[..., 1] = shade * 0.94
    a[..., 2] = shade * 1.06
    a[..., 3] = np.where(body, 238, np.where(near, 70, 0))
    # the seal
    sx, sy, sz = 104, 100, 11
    seal = np.zeros((n, n), bool)
    seal[sy:sy + sz, sx:sx + sz] = True
    bite = rng.random((n, n)) < 0.2
    edge_px = seal & ~np.pad(seal[1:-1, 1:-1], 1)
    seal &= ~(edge_px & bite)
    glyph = np.zeros((n, n), bool)
    glyph[sy + 3, sx + 2:sx + 9] = True
    glyph[sy + 7, sx + 2:sx + 9] = True
    glyph[sy + 2:sy + 9, sx + 5] = True
    glyph[sy + 5, sx + 3] = True
    glyph[sy + 5, sx + 7] = True
    cin = np.array([172, 46, 36], float)
    paper = np.array([226, 208, 172], float)
    for k in range(3):
        a[..., k] = np.where(seal, np.where(glyph, paper[k], cin[k]), a[..., k])
    a[..., 3] = np.where(seal, 245, a[..., 3])
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def _swash(w, h, rgb, seed, dry=0.55, taper=True):
    """A short horizontal brush stroke: full-bodied at the start, ragged and dry at the end."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    t = xx / (w - 1)
    center = h * 0.5 + np.sin(t * math.pi) * h * 0.04
    thick = h * (0.40 + 0.06 * np.sin(t * math.pi * 2.0)) * (1.0 - (0.35 * np.clip((t - 0.8) / 0.2, 0, 1) if taper else 0))
    thick *= np.clip(t / 0.05, 0.55, 1.0)
    d = np.abs(yy - center) / np.maximum(thick, 0.5)
    rows = rng.random(h)
    streak = rows[yy.astype(int)] > dry * np.clip((t - 0.55) / 0.45, 0, 1) * (d > 0.25)
    ragged = (pnoise(64, 8, seed) - 0.5)
    ragged = np.array(Image.fromarray(((ragged + 0.5) * 255).astype(np.uint8)).resize((w, h))) / 255.0 - 0.5
    body = d < (1.0 + ragged * 0.35)
    alpha = body & streak
    a = np.zeros((h, w, 4), np.uint8)
    shade = 1.0 - 0.18 * np.clip(d, 0, 1) ** 2
    for k in range(3):
        a[..., k] = np.clip(rgb[k] * shade, 0, 255).astype(np.uint8)
    a[..., 3] = (alpha * 240).astype(np.uint8)
    return Image.fromarray(a, 'RGBA')


def nameplate():
    """The speaker's name sits on a swash of cinnabar ink (9-patch, margins 20 / 6)."""
    return _swash(96, 30, (150, 40, 32), 4)


def bar_bg():
    """Under a health bar: a stroke of dark ink, ragged at the ends."""
    return _swash(64, 14, (18, 16, 20), 6, dry=0.3)


def bar_fill():
    """A health bar's fill: a white brush stroke, tinted per bar (StyleBoxTexture.modulate_color)."""
    return _swash(64, 12, (255, 255, 255), 8, dry=0.4)


def cursor():
    c = Canvas(10, 10)
    R = c.material(ramp('#b8402f', shadow='#7d2a24', light='#e06a50', outline='#2c0f0c'))
    c.paint(c.poly([(5, 0), (9, 5), (5, 9), (1, 5)]), R)
    return c.render()


def icons():
    """16x16 icons: 0 Bổ, 1 Quét, 2 Thủ, 3 Thấu, 4 Thuốc, 5 Chấp shield, 6 unknown, 7 heart,
    8 Nhất Nét (one ink stroke), 9 Xâm (a red flame of want), 10 Tịnh (a still drop)"""
    frames = []
    IR = ramp('#9aa0a8', shadow='#6d7279', light='#c9ced4', outline='#1d1f23', hi='#eef1f3')
    WD = ramp('#9a6d45', shadow='#6e4c2f', light='#bb8a5c', outline='#2a1a0d')
    GR = ramp('#5f8f43', shadow='#41672e', light='#80b25c', outline='#14230c')
    PO = ramp('#e3e8ec', shadow='#a7b3be', light='#f6f9fb', outline='#3f4b58', hi='#ffffff')
    RD = ramp('#c0453a', shadow='#86302a', light='#e2705f', outline='#2c0f0c')
    GD = ramp('#d0b060', shadow='#9c8240', light='#ecd38a', outline='#3a2e12')
    # Bổ: axe chop
    c = Canvas(16, 16)
    w = c.material(WD); i = c.material(IR)
    c.paint(c.line([(3, 14), (11, 4)], 2), w)
    c.paint(c.poly([(9, 1), (15, 4), (12, 8), (8, 5)]), i)
    frames.append(c.render())
    # Quét: sweep arc
    c = Canvas(16, 16)
    i = c.material(IR)
    xx, yy = c.grid()
    r = np.hypot(xx - 8, yy - 14)
    c.paint((r > 8) & (r < 11) & (yy < 13), i)
    c.paint(c.poly([(1, 10), (4, 7), (5, 12)]), i)
    frames.append(c.render())
    # Thủ: shield
    c = Canvas(16, 16)
    w = c.material(WD); g = c.material(GD)
    c.paint(c.poly([(2, 2), (14, 2), (14, 8), (8, 15), (2, 8)]), w)
    c.paint(c.rect(7, 3, 8, 12), g)
    frames.append(c.render())
    # Thấu: eye
    c = Canvas(16, 16)
    p = c.material(PO); k = c.material(ramp('#3a5a7a', shadow='#22384d', light='#5f86ad', outline='#0c1620'))
    c.paint(c.ellipse(8, 8, 7, 4), p)
    c.paint(c.ellipse(8, 8, 2.6, 2.6), k)
    frames.append(c.render())
    # Thuốc: herb bundle
    c = Canvas(16, 16)
    g = c.material(GR); w = c.material(WD)
    c.paint(c.ellipse(6, 6, 4, 3), g)
    c.paint(c.ellipse(10, 7, 4, 3), g)
    c.paint(c.rect(7, 9, 9, 14), w)
    frames.append(c.render())
    # Chấp: porcelain shield
    c = Canvas(16, 16)
    p = c.material(PO); k = c.material(ramp('#4f6274', shadow='#3e4e5e', light='#6c8193', outline='#26313c'), flat=True, outline=False)
    c.paint(c.poly([(2, 2), (14, 2), (14, 8), (8, 15), (2, 8)]), p)
    c.paint(c.line([(8, 3), (7, 7), (9, 10)], 1), k)
    frames.append(c.render())
    # unknown
    c = Canvas(16, 16)
    k = c.material(ramp('#6a6f78', shadow='#4a4e55', light='#8a9099', outline='#1a1c20'))
    c.paint(c.ellipse(8, 8, 7, 7), k)
    q = c.material(ramp('#f0ece2', shadow='#c8c2b4', light='#ffffff', outline='#f0ece2'), flat=True, outline=False)
    for (x, y) in ((6, 4), (7, 4), (8, 4), (9, 5), (9, 6), (8, 7), (7, 8), (7, 9), (7, 11)):
        c.paint(c.px(x, y), q)
    frames.append(c.render())
    # heart
    c = Canvas(16, 16)
    r = c.material(RD)
    c.paint(c.ellipse(5.5, 6, 3.5, 3.5), r)
    c.paint(c.ellipse(10.5, 6, 3.5, 3.5), r)
    c.paint(c.poly([(2, 7), (14, 7), (8, 14)]), r)
    frames.append(c.render())
    # Nhất Nét: a single horizontal ink stroke, thick at the start, tapering to a clean stop
    c = Canvas(16, 16)
    ink = c.material(ramp('#1c1a1e', shadow='#0e0d10', light='#3a3640', outline='#e8dfcc'))
    c.paint(c.poly([(1, 6), (4, 5), (14, 7), (14, 8), (4, 10), (1, 9)]), ink)
    frames.append(c.render())
    # Xâm: a red flame
    c = Canvas(16, 16)
    f = c.material(ramp('#d8452f', shadow='#9c2a1c', light='#ff8a5a', outline='#3a0e08', hi='#ffd08a'))
    c.paint(c.poly([(8, 1), (12, 7), (13, 11), (10, 15), (6, 15), (3, 11), (4, 7), (6, 9)]), f)
    c.set_tone(c.ellipse(8.5, 11, 2.0, 2.5), 4)
    frames.append(c.render())
    # Tịnh: a still drop of clear water
    c = Canvas(16, 16)
    w = c.material(ramp('#8fc6d8', shadow='#5f9ab0', light='#c8eaf2', outline='#1c3a46', hi='#ffffff'))
    c.paint(c.poly([(8, 1), (12, 8), (12, 11), (8, 15), (4, 11), (4, 8)]), w)
    c.set_tone(c.rect(6, 8, 6, 10), 4)
    frames.append(c.render())
    # 11 Rửa: a shard of glaze with a crack in it, a drop of water over it (Bạch Sơn's skill)
    c = Canvas(16, 16)
    p = c.material(PO)
    k = c.material(ramp('#3a4652', shadow='#26303a', light='#56636f', outline='#e3e8ec'), flat=True, outline=False)
    w = c.material(ramp('#8fc6d8', shadow='#5f9ab0', light='#c8eaf2', outline='#1c3a46', hi='#ffffff'))
    c.paint(c.poly([(2, 9), (8, 6), (14, 9), (12, 15), (4, 15)]), p)
    c.paint(c.line([(5, 10), (8, 12), (7, 14)], 1), k)
    c.paint(c.line([(8, 12), (11, 11)], 1), k)
    c.paint(c.poly([(8, 0), (10, 3), (8, 5), (6, 3)]), w)
    frames.append(c.render())
    # 12 Sang bên: step across to the other side
    c = Canvas(16, 16)
    g = c.material(GD)
    c.paint(c.poly([(1, 5), (5, 2), (5, 4), (11, 4), (11, 6), (5, 6), (5, 8)]), g)
    c.paint(c.poly([(15, 11), (11, 8), (11, 10), (5, 10), (5, 12), (11, 12), (11, 14)]), g)
    frames.append(c.render())
    # 13 Đóng cổng: the barred leaves under the arch
    c = Canvas(16, 16)
    p = c.material(PO)
    for x in (3, 6, 9, 12):
        c.paint(c.rect(x, 4, x, 15), p)
    c.paint(c.rect(2, 12, 13, 12), p)
    xx, yy = c.grid()
    r = np.hypot(xx - 7.5, yy - 7)
    c.paint((r > 5.2) & (r < 6.6) & (yy < 7), p)
    frames.append(c.render())
    from pix import sheet
    return sheet(frames, len(frames))


def brush_stroke(w=640, h=120, seed=2):
    """A horizontal ink brush stroke (一) with dry-brush streaks, black on transparent."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    t = xx / w
    center = h * 0.5 + np.sin(t * math.pi * 1.2) * h * 0.06 - t * h * 0.05
    thick = h * (0.28 + 0.14 * np.sin(t * math.pi) + 0.1 * np.exp(-((t - 0.04) / 0.05) ** 2) - 0.12 * np.clip((t - 0.85) / 0.15, 0, 1))
    d = np.abs(yy - center) / np.maximum(thick, 1)
    body = d < 1.0
    streak_noise = np.repeat(rng.random((h, 1)), w, axis=1)
    streak = (streak_noise < 0.75 + 0.25 * (1 - t))
    grain = pnoise(256, 16, seed)
    grain = np.array(Image.fromarray((grain * 255).astype(np.uint8)).resize((w, h))) / 255.0
    alpha = body & (streak | (d < 0.55)) & (grain > 0.15 + 0.5 * np.clip((t - 0.75) / 0.25, 0, 1) * (d > 0.3))
    a = np.zeros((h, w, 4), np.uint8)
    a[..., :3] = (18, 15, 18)
    a[..., 3] = (alpha * 235).astype(np.uint8)
    im = Image.fromarray(a, 'RGBA').filter(ImageFilter.GaussianBlur(0.6))
    return im


def slash_frames():
    frames = []
    for k in range(4):
        w, h = 72, 40
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        start = 200 + k * 25
        for i, (wid, col) in enumerate(((7 - k, (210, 240, 255, 230 - k * 50)), (3, (255, 255, 255, 255 - k * 55)))):
            dr.arc([4, -30, 68, 36], start=start - 80, end=start, fill=col, width=max(1, wid))
        frames.append(im)
    from pix import sheet
    return sheet(frames, 4)


def spark():
    c = Canvas(16, 16)
    s = c.material(ramp('#fff3b0', shadow='#f2cf5a', light='#ffffff', outline='#8a6a1a'), flat=True)
    c.paint(c.poly([(8, 0), (9, 7), (16, 8), (9, 9), (8, 16), (7, 9), (0, 8), (7, 7)]), s)
    return c.render(outline=False)


def shard():
    c = Canvas(7, 7)
    s = c.material(ramp('#e3e8ec', shadow='#a7b3be', light='#ffffff', outline='#5a6772'))
    c.paint(c.poly([(1, 1), (6, 3), (2, 6)]), s)
    return c.render()


def spike():
    """Nghiệt Tịnh's thrown arm: a long porcelain arm ending in a clawed, grasping hand, pointing right."""
    c = Canvas(60, 26)
    P = c.material(ramp('#e6ebef', shadow='#a3afba', light='#ffffff', outline='#222a33', hi='#ffffff'))
    K = c.material(ramp('#3f5163', outline='#1c242c'), flat=True, outline=False)
    R = c.material(ramp('#ff5a3c', shadow='#c0301c', light='#ff9a78', outline='#5a120a'), flat=True, outline=False)
    c.paint(c.poly([(0, 11), (34, 8), (38, 13), (34, 18), (0, 15)]), P)          # forearm, thick, tapering back
    c.paint(c.ellipse(39, 13, 6.0, 6.2), P)                                        # palm
    for dy, ln in ((-5, 13), (-2, 17), (2, 17), (5, 13)):                         # long fingers with hooked tips
        tip = (40 + ln, 13 + dy * 1.4)
        c.paint(c.line([(41, 13 + dy * 0.7), tip], 3), P)
        c.paint(c.line([tip, (tip[0] + 1, tip[1] + (2 if dy > 0 else -2) * -1)], 2), P)
    c.paint(c.line([(37, 19), (45, 23)], 3), P)                                    # thumb
    for x in (5, 12, 20, 28):
        c.paint(c.line([(x, 10), (x + 2, 12), (x + 1, 14), (x + 3, 15)], 1), K)   # cracks
    c.paint(c.line([(2, 13), (30, 12)], 1), R)                                     # red seam glowing through
    c.paint(c.ellipse(39, 13, 2.2, 2.0), R)                                        # the eye in the palm
    return c.render(volume=True)


def burst_frames():
    """Impact burst, 4 frames 48x48: white core, jagged rays that fly out and thin."""
    frames = []
    rng = np.random.default_rng(8)
    rays = [(rng.uniform(0, math.tau), rng.uniform(0.7, 1.0)) for _ in range(11)]
    for k in range(4):
        im = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        r0 = 6 + k * 5
        r1 = 14 + k * 6
        for a, L in rays:
            w = max(1, 4 - k)
            x0, y0 = 24 + math.cos(a) * r0 * 0.5, 24 + math.sin(a) * r0 * 0.5
            x1, y1 = 24 + math.cos(a) * r1 * L * 1.4, 24 + math.sin(a) * r1 * L * 1.4
            dr.line([(x0, y0), (x1, y1)], fill=(255, 255, 255, 255 - k * 45), width=w)
        core = max(0, 9 - k * 3)
        if core:
            dr.ellipse([24 - core, 24 - core, 24 + core, 24 + core], fill=(255, 255, 255, 255))
        frames.append(im)
    from pix import sheet
    return sheet(frames, 4)


def shock_frames():
    """Parry shock ring, 4 frames 48x48."""
    frames = []
    for k in range(4):
        im = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        r = 6 + k * 6
        dr.ellipse([24 - r, 24 - r * 0.6, 24 + r, 24 + r * 0.6], outline=(255, 255, 255, 255 - k * 55), width=max(1, 4 - k))
        frames.append(im)
    from pix import sheet
    return sheet(frames, 4)


def ground_hand():
    """Porcelain hand bursting up out of the earth: 3 frames 24x34 (breaking out, reaching, cracked)."""
    frames = []
    for f in range(3):
        c = Canvas(24, 34)
        P = c.material(ramp('#e3e8ec', shadow='#a7b3be', light='#f8fbfd', outline='#2f3944', hi='#ffffff'))
        K = c.material(ramp('#4f6274', outline='#26313c'), flat=True, outline=False)
        D = c.material(ramp('#5a4632', shadow='#3e3022', light='#735a40', outline='#1e150d'))
        R = c.material(ramp('#e2543f', outline='#5a120a'), flat=True, outline=False)
        h = (14, 24, 23)[f]
        base = 31
        c.paint(c.poly([(9, base), (15, base), (14, base - h + 6), (10, base - h + 6)]), P)    # arm
        top = base - h + 6
        c.paint(c.ellipse(12, top, 4.0, 3.4), P)                                              # palm
        for dx, ln in ((-3, 6), (-1, 8), (1, 8), (3, 6)):
            c.paint(c.line([(12 + dx * 0.9, top), (12 + dx * 1.5, top - ln * (0.6 if f == 0 else 1.0))], 2), P)
        c.paint(c.line([(10, base - 4), (11, base - h * 0.5), (13, base - h * 0.6)], 1), K)
        if f == 2:
            c.paint(c.line([(14, top + 2), (12, top + 8), (14, top + 12)], 1), K)
            c.paint(c.px(12, top + 1), R)
        c.paint(c.ellipse(12, base + 1, 9, 2.6) & ~c.ellipse(12, base + 1, 5, 1.4), D)        # broken earth ring
        frames.append(c.render(volume=True))
    from pix import sheet
    return sheet(frames, 3)


def vision_gate(seed=5):
    """Ink-wash vision: the white gate of a city, people behind it, staring out with fear."""
    w, h = 384, 216
    im = Image.new('RGB', (w, h), (232, 228, 218))
    dr = ImageDraw.Draw(im)
    # paper texture
    v = pnoise(256, 8, seed)
    paper = np.array(Image.fromarray((v * 255).astype(np.uint8)).resize((w, h)))
    base = np.array(im).astype(int)
    base -= ((paper[..., None] / 255.0) * 22).astype(int)
    im = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8))
    dr = ImageDraw.Draw(im)
    # distant mountains in washes
    for k, (yb, col) in enumerate(((120, (200, 198, 192)), (140, (178, 176, 170)))):
        pts = [(0, h)]
        for x in range(0, w + 16, 16):
            pts.append((x, yb - 30 * math.sin(x / 70 + k) - 18 * math.sin(x / 23 + k * 2)))
        pts.append((w, h))
        dr.polygon(pts, fill=col)
    # the wall and the great white gate
    dr.rectangle([0, 110, w, 200], fill=(208, 206, 200))
    dr.rectangle([118, 40, 266, 200], fill=(246, 246, 244), outline=(60, 58, 60))
    dr.polygon([(104, 44), (280, 44), (262, 22), (122, 22)], fill=(70, 66, 66))
    dr.rectangle([150, 92, 234, 200], fill=(34, 32, 36))
    # bars of the gate
    for x in range(156, 232, 9):
        dr.rectangle([x, 92, x + 3, 200], fill=(236, 236, 232))
    # faces behind the bars: pale ovals with dark eyes
    rng = np.random.default_rng(seed)
    for i in range(7):
        x = 160 + i * 11 + int(rng.integers(-2, 3))
        y = 120 + int(rng.integers(-6, 10))
        dr.ellipse([x - 4, y - 6, x + 4, y + 6], fill=(214, 206, 196))
        dr.rectangle([x - 2, y - 1, x - 1, y], fill=(20, 18, 20))
        dr.rectangle([x + 1, y - 1, x + 2, y], fill=(20, 18, 20))
    # a lone figure outside, small, in red
    dr.ellipse([56, 168, 64, 176], fill=(160, 52, 44))
    dr.polygon([(54, 200), (66, 200), (63, 176), (57, 176)], fill=(140, 44, 38))
    # ink splatter vignette
    out = np.array(im).astype(int)
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2))
    out = out * (1 - np.clip(r - 0.7, 0, 1)[..., None] * 0.9)
    im = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).convert('RGBA')
    # pixelate slightly for consistency with the game
    im = im.resize((w // 2, h // 2), Image.BILINEAR).resize((w, h), Image.NEAREST)
    return im


def keycap():
    c = Canvas(18, 16)
    k = c.material(ramp('#e8e2d2', shadow='#b9b1a0', light='#ffffff', outline='#3a3530'))
    c.paint(c.rect(1, 1, 16, 13), k)
    c.set_tone(c.rect(1, 12, 16, 13), 1)
    return c.render()


ALL = {
    'panel': panel, 'nameplate': nameplate, 'bar_bg': bar_bg, 'bar_fill': bar_fill, 'cursor': cursor, 'icons': icons, 'keycap': keycap,
}
def _bezier(P, u):
    a, b, c, d = P
    v = 1.0 - u
    return (v ** 3 * a[0] + 3 * v * v * u * b[0] + 3 * v * u * u * c[0] + u ** 3 * d[0],
            v ** 3 * a[1] + 3 * v * v * u * b[1] + 3 * v * u * u * c[1] + u ** 3 * d[1])


def _brush_frames(W, H, P, wmax, seed):
    """A calligraphy stroke cut through the air, 6 frames (W x H each).
    0-1: the blade's light runs along the path. 2: the ink lands, heavy at the press, dry at the tail.
    3-5: the ink breaks into flecks that fly off the cut and fade.
    Drawn at 3x and filtered down so the edges are soft (it is shown with linear filtering)."""
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
    S = 3
    rng = np.random.default_rng(seed)
    n = 420
    pts = [_bezier(P, i / (n - 1)) for i in range(n)]

    def width(u):
        press = min(1.0, 0.55 + u / 0.07)
        return wmax * press * (1.0 - u) ** 0.75 + 0.6

    # unit normals along the path, for the dry-brush streaks and the flying flecks
    nrm = []
    for i in range(n):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = max(1e-6, (dx * dx + dy * dy) ** 0.5)
        nrm.append((-dy / L, dx / L))
    streaks = [rng.uniform(-0.8, 0.8) for _ in range(5)]
    flecks = []
    for _ in range(26):
        i = int(rng.uniform(0.05, 0.95) * (n - 1))
        side = rng.choice([-1.0, 1.0])
        flecks.append((i, side * rng.uniform(0.6, 1.6), rng.uniform(1.0, 3.2), rng.uniform(0.6, 1.4)))

    def stamp(dr, reach, wscale, col, core=False):
        last = max(1, int(reach * (n - 1)))
        for i in range(last + 1):
            u = i / (n - 1)
            w = width(u) * wscale * S
            x, y = pts[i][0] * S, pts[i][1] * S
            dr.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=col)

    def carve_streaks(im, start_u, strength):
        # dry brush (phi bạch): thin gaps that open toward the tail
        a = np.array(im)
        dr = ImageDraw.Draw(Image.new('L', (1, 1)))
        mask = Image.new('L', im.size, 0)
        md = ImageDraw.Draw(mask)
        for off in streaks:
            line = []
            for i in range(int(start_u * (n - 1)), n):
                u = i / (n - 1)
                w = width(u) * 0.5 * S
                line.append((pts[i][0] * S + nrm[i][0] * off * w, pts[i][1] * S + nrm[i][1] * off * w))
            if len(line) > 1:
                md.line(line, fill=int(255 * strength), width=max(1, int(S * 1.2)))
        m = np.array(mask).astype(float) / 255.0
        a[..., 3] = (a[..., 3] * (1.0 - m)).astype(np.uint8)
        return Image.fromarray(a)

    frames = []
    for k in range(6):
        im = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        if k <= 1:
            reach = [0.55, 1.0][k]
            # halo, then the white-hot core
            glow = Image.new('RGBA', im.size, (0, 0, 0, 0))
            stamp(ImageDraw.Draw(glow), reach, 1.5, (255, 236, 200, 120))
            glow = glow.filter(ImageFilter.GaussianBlur(4 * S))
            im = Image.alpha_composite(im, glow)
            dr = ImageDraw.Draw(im)
            if k == 1:
                stamp(dr, 0.45, 1.0, (22, 20, 26, 255))
            stamp(dr, reach, 0.42, (255, 252, 240, 255))
        else:
            wscale = [1.0, 0.92, 0.7, 0.45][k - 2]
            alpha = [255, 235, 190, 110][k - 2]
            halo = Image.new('RGBA', im.size, (0, 0, 0, 0))
            stamp(ImageDraw.Draw(halo), 1.0, wscale * 1.35, (238, 228, 206, int(alpha * 0.55)))
            halo = halo.filter(ImageFilter.GaussianBlur(2 * S))
            im = Image.alpha_composite(im, halo)
            ink = Image.new('RGBA', im.size, (0, 0, 0, 0))
            stamp(ImageDraw.Draw(ink), 1.0, wscale, (22, 20, 26, alpha))
            ink = carve_streaks(ink, 0.5 - 0.12 * (k - 2), min(1.0, 0.55 + 0.15 * (k - 2)))
            im = Image.alpha_composite(im, ink)
            dr = ImageDraw.Draw(im)
            if k == 2:
                stamp(dr, 1.0, 0.16, (255, 250, 236, 200))  # the last of the light along the edge
            if k >= 3:
                drift = (k - 2) * 5.0
                for (i, side, r, sp) in flecks:
                    u = i / (n - 1)
                    w = width(u) * 0.5
                    x = pts[i][0] + nrm[i][0] * side * (w + drift * sp)
                    y = pts[i][1] + nrm[i][1] * side * (w + drift * sp) + (k - 2) * 1.5
                    rr = r * (1.0 - 0.18 * (k - 3)) * S
                    dr.ellipse([x * S - rr, y * S - rr, x * S + rr, y * S + rr], fill=(22, 20, 26, alpha))
        frames.append(im.resize((W, H), Image.LANCZOS))
    from pix import sheet
    return sheet(frames, 6)


def ink_slash_frames():
    """One diagonal cut, upper right to lower left (the hero faces left), 6 frames 160x128."""
    return _brush_frames(160, 128, [(150, 10), (128, 46), (66, 98), (10, 120)], 26, 3)


def ink_sweep_frames():
    """A wide low sweep across a group, right to left with a slight sag, 6 frames 256x96."""
    return _brush_frames(256, 96, [(248, 30), (180, 74), (80, 78), (8, 44)], 22, 5)


FX = {'slash': slash_frames, 'ink_slash': ink_slash_frames, 'ink_sweep': ink_sweep_frames, 'spark': spark, 'shard': shard, 'spike': spike, 'burst': burst_frames,
      'shock': shock_frames, 'ground_hand': ground_hand}
