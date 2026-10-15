"""Paper-and-ink UI (the author's reference: "khung thoại thư pháp mực tàu").

(2026-10-13: the dialogue box and choices moved to lacquer, tools/art/lacquer_ui.py; this box read as a Tết card.
dialogue_frame / plum_branch / petal / seal_tag stay on disk so it can be switched back.)

Frames are xuyến chỉ paper, cream and slightly yellowed toward the edge, held by a black brush line that
thickens, dries and splashes at the corners; names sit on cinnabar seals; a branch of mai blossom in ink and
pink leans in at the left of the dialogue box; choices and the current menu row are strokes of ink.

Everything is drawn at twice the size and scaled down, so the edges are soft like ink rather than pixel steps.
9-patch frames keep their corners free and their straight edges constant along their length, so a frame can
be stretched to any size without smearing.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

INK = np.array([22, 19, 21], float)
PAPER = np.array([236, 227, 205], float)
PAPER_EDGE = np.array([214, 197, 165], float)
CINNABAR = np.array([170, 42, 34], float)
S = 2  # supersampling


def _hash(n, seed):
    return np.random.default_rng(seed).random(n)


def _smooth_noise_1d(t, seed, cells=12):
    """Periodic 1-D value noise over t in [0,1)."""
    v = _hash(cells, seed)
    x = (t % 1.0) * cells
    i = np.floor(x).astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    return v[i % cells] * (1 - f) + v[(i + 1) % cells] * f


def _rounded_sd(xx, yy, x0, y0, x1, y1, r):
    """Signed distance to a rounded rectangle (negative inside)."""
    cx = np.clip(xx, x0 + r, x1 - r)
    cy = np.clip(yy, y0 + r, y1 - r)
    return np.hypot(xx - cx, yy - cy) - r


def _frame(W, H, ml, mt, mr, mb, inset, radius, seed, heavy=1.0):
    """A 9-patch paper frame. Detail that varies along an edge is kept inside the corner regions, faded out
    before it reaches the stretchable part."""
    w, h = W * S, H * S
    yy, xx = np.mgrid[0:h, 0:w].astype(float) / S + 0.5 / S
    rng = np.random.default_rng(seed)
    sd = _rounded_sd(xx, yy, inset, inset, W - inset, H - inset, radius)
    # how far into a corner region a point is (1 deep in a corner, 0 on the stretchable parts)
    cxw = np.clip(np.maximum((ml - xx) / ml, (xx - (W - mr)) / mr), 0, 1)
    cyw = np.clip(np.maximum((mt - yy) / mt, (yy - (H - mb)) / mb), 0, 1)
    corner = np.clip(np.minimum(cxw, cyw) * 3.0, 0, 1)
    # angle around the shape, for detail that follows the outline in the corners
    ang = (np.arctan2(yy - H / 2, (xx - W / 2) * (H / W)) / (2 * math.pi)) % 1.0
    n1 = _smooth_noise_1d(ang, seed, 16)
    n2 = _smooth_noise_1d(ang, seed + 1, 40)
    # the brush line: thicker and wilder in the corners, steady along the edges
    base = 2.6 * heavy
    thick = base + corner * (2.8 * heavy * n1 + 1.2 * n2)
    # a heavy press at the lower left and upper right
    press = np.exp(-(((xx - inset * 1.6) / (ml * 0.5)) ** 2 + ((yy - (H - inset * 1.5)) / (mb * 0.6)) ** 2))
    press += 0.7 * np.exp(-(((xx - (W - inset * 1.6)) / (mr * 0.5)) ** 2 + ((yy - inset * 1.4) / (mt * 0.6)) ** 2))
    thick += press * 4.0 * heavy
    line = np.abs(sd) < thick
    # dry brush: bristle tracks running along the outline; in the corners, breaks where the brush lifted
    track = _hash(64, seed + 2)[np.clip(((sd + 12) * 2.2).astype(int), 0, 63)]
    dry = (track < 0.22) & (np.abs(sd) > thick * 0.35)
    lift = corner * (n2 > 0.72)
    ink_a = np.where(line, 1.0, 0.0) * np.where(dry, 0.35, 1.0) * (1 - 0.75 * lift)
    # grey bleed just outside the line, stronger in the corners
    bleed = np.exp(-np.clip(sd - thick, 0, None) / 3.0) * (sd > thick) * (0.18 + 0.25 * corner)
    # splashes off the corners
    spl = np.zeros_like(sd)
    for (cx, cy, n) in ((inset * 0.6, H - inset * 0.4, 9), (W - inset * 0.5, inset * 0.5, 7), (W - inset * 0.9, H - inset * 0.5, 4)):
        for _ in range(n):
            px = cx + rng.normal(0, inset * 0.9)
            py = cy + rng.normal(0, inset * 0.7)
            pr = rng.uniform(0.4, 1.6) * heavy
            spl = np.maximum(spl, (np.hypot(xx - px, yy - py) < pr) * 1.0)
    spl *= (sd > 0)
    # paper: cream, yellowing toward the edge, fibres only in the corners
    t_edge = np.clip(1 - (-sd) / 14.0, 0, 1)
    paper = PAPER[None, None, :] * (1 - t_edge[..., None] * 0.7) + PAPER_EDGE[None, None, :] * (t_edge[..., None] * 0.7)
    fib = (rng.random((h, w)) - 0.5) * 10 * corner
    paper = paper + fib[..., None]
    inside = sd < 0
    out = np.zeros((h, w, 4), float)
    out[..., :3] = np.where(inside[..., None], paper, INK[None, None, :])
    alpha = np.where(inside, 1.0, 0.0)
    # ink over everything
    a_ink = np.clip(np.maximum(ink_a, spl), 0, 1)
    out[..., :3] = out[..., :3] * (1 - a_ink[..., None]) + INK[None, None, :] * a_ink[..., None]
    alpha = np.maximum(alpha, a_ink)
    # the bleed, where there is no paper and no ink
    grey = np.array([70, 66, 68], float)
    b = bleed * (1 - alpha)
    out[..., :3] = np.where((alpha > 0)[..., None], out[..., :3], grey[None, None, :])
    alpha = alpha + b
    out[..., 3] = np.clip(alpha, 0, 1) * 255
    im = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGBA')
    return im.resize((W, H), Image.LANCZOS)


def _bristle_stroke(dr, pts, wmax, k, rng, dry=0.5, ink=(22, 19, 21)):
    """One brush stroke along a polyline, drawn as bristles: width swells and tapers (sin profile), each bristle
    a thin line offset across the width, dropping out in places toward the end (dry brush)."""
    n = len(pts)
    nb = max(5, int(wmax * 1.4))
    offs = np.linspace(-0.5, 0.5, nb) + rng.normal(0, 0.04, nb)
    life = rng.uniform(0.75, 1.0, nb) - dry * rng.random(nb) * 0.4
    for b in range(nb):
        prev = None
        for i in range(n):
            u = i / (n - 1)
            if u > life[b]:
                break
            x0, y0 = pts[max(i - 1, 0)]
            x1, y1 = pts[min(i + 1, n - 1)]
            tx, ty = x1 - x0, y1 - y0
            L = math.hypot(tx, ty) or 1.0
            nx, ny = -ty / L, tx / L
            wdt = wmax * (math.sin(math.pi * min(1.0, u * 1.15 + 0.05)) ** 0.6)
            x, y = pts[i]
            q = (x + nx * offs[b] * wdt, y + ny * offs[b] * wdt)
            gap = u > 0.55 and rng.random() < dry * (u - 0.55) * 1.6
            if prev is not None and not gap:
                dr.line([prev[0] * k, prev[1] * k, q[0] * k, q[1] * k], fill=ink + (235,), width=max(1, int(wdt / nb * 2.0 * k)))
            prev = q


def _arc(cx, cy, r, a0, a1, n=50, wob=0.0, rng=None):
    pts = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        rr = r + (rng.normal(0, wob) if rng is not None and wob else 0.0)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    return pts


def _dress(im, W, H, ml, mt, mr, mb, inset, radius, seed, heavy, ends):
    """Brush sweeps, grey wash and splashes on the corners of a frame, kept inside the corner regions."""
    k = 3
    rng = np.random.default_rng(seed + 9)
    over = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    wash = Image.new('L', (W * k, H * k), 0)
    dr = ImageDraw.Draw(over)
    dw = ImageDraw.Draw(wash)
    r = radius
    x0, y0, x1, y1 = inset, inset, W - inset, H - inset
    tl, br = (x0 + r, y0 + r), (x1 - r, y1 - r)
    tr = (x1 - r, y0 + r)
    pi = math.pi
    if ends:   # dialogue box: whole semicircular ends
        _bristle_stroke(dr, _arc(tl[0], H / 2, r + 1.5, -pi * 0.47, -pi * 1.55, 60, 0.6, rng), 9.0 * heavy, k, rng, 0.55)
        _bristle_stroke(dr, _arc(tl[0] + 2, H / 2 + 1, r - 2.5, -pi * 0.75, -pi * 1.25, 30, 0.4, rng), 4.0 * heavy, k, rng, 0.8)
        _bristle_stroke(dr, _arc(tr[0], H / 2, r + 1.5, pi * 0.48, -pi * 0.55, 60, 0.6, rng), 8.0 * heavy, k, rng, 0.6)
        _bristle_stroke(dr, [(tr[0] + r * 0.5, y0 + 4), (tr[0] + r * 0.8, y0 - 1), (W - 6, y0 - 5)], 3.0 * heavy, k, rng, 0.7)
        for (cx, cy, rx, ry) in ((x0 + 4, H * 0.6, 24, 56), (x1 - 2, H * 0.36, 18, 40), (x0 + 30, y1 + 2, 30, 8)):
            dw.ellipse([(cx - rx) * k, (cy - ry) * k, (cx + rx) * k, (cy + ry) * k], fill=135)
    else:      # panels: a heavier sweep round the upper left and the lower right corners
        _bristle_stroke(dr, _arc(tl[0], tl[1], r + 1.0, pi * 0.62, pi * 1.5, 30, 0.4, rng), 6.0 * heavy, k, rng, 0.5)
        _bristle_stroke(dr, _arc(br[0], br[1], r + 1.0, -pi * 0.38, pi * 0.5, 30, 0.4, rng), 5.0 * heavy, k, rng, 0.6)
        for (cx, cy) in ((x0 + 2, y0 + 8), (x1 - 2, y1 - 6)):
            dw.ellipse([(cx - 13) * k, (cy - 13) * k, (cx + 13) * k, (cy + 13) * k], fill=105)
    for (cx, cy, n) in ((x0 + 3, y1 - 2, 10), (x1 - 2, y0 + 2, 8), (x1 - 6, y1 + 1, 4)):
        for _ in range(n):
            px, py = cx + rng.normal(0, inset * 0.8), cy + rng.normal(0, inset * 0.6)
            pr = rng.uniform(0.3, 1.4) * heavy
            dr.ellipse([(px - pr) * k, (py - pr) * k, (px + pr) * k, (py + pr) * k], fill=(22, 19, 21, 230))
    wash = wash.filter(ImageFilter.GaussianBlur(7 * k))
    over = over.filter(ImageFilter.GaussianBlur(0.55 * k))
    yy, xx = np.mgrid[0:H * k, 0:W * k].astype(float) / k
    if ends:
        keep = ((xx < ml - 3) | (xx > W - mr + 3)).astype(float)
    else:
        keep = (((xx < ml - 3) | (xx > W - mr + 3)) & ((yy < mt - 3) | (yy > H - mb + 3))).astype(float)
    ov = np.array(over).astype(float)
    ov[..., 3] *= keep
    wa = np.array(wash).astype(float) / 255.0 * keep
    over = Image.fromarray(ov.astype(np.uint8), 'RGBA').resize((W, H), Image.LANCZOS)
    wa = np.array(Image.fromarray((wa * 255).astype(np.uint8)).resize((W, H), Image.LANCZOS)).astype(float) / 255.0
    base = np.array(im).astype(float)
    grey = np.array([60, 56, 58], float)
    a0 = base[..., 3] / 255.0
    wa_eff = wa * (1 - a0) * 0.9
    out_a = a0 + wa_eff
    rgb = np.where((out_a > 0)[..., None], (base[..., :3] * a0[..., None] + grey * wa_eff[..., None]) / np.maximum(out_a, 1e-6)[..., None], 0)
    merged = np.dstack([rgb, out_a * 255])
    m = Image.fromarray(np.clip(merged, 0, 255).astype(np.uint8), 'RGBA')
    m.alpha_composite(over)
    return m


def _pill_alpha(w, h, x0, y0, x1, y1, r, seed, rough=2.0):
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    sd = _rounded_sd(xx, yy, x0, y0, x1, y1, r)
    rng = np.random.default_rng(seed)
    from scipy import ndimage as ndi
    nz = ndi.gaussian_filter(rng.random((h, w)), 3.0)
    nz = (nz - nz.mean()) / max(1e-6, nz.std())
    return np.clip(0.5 - (sd + nz * rough) / 1.5, 0, 1)


def _arc_pts(cx, cy, rx, ry, a0, a1, n=120, wob=0.0, seed=0):
    rng = np.random.default_rng(seed)
    t = np.linspace(a0, a1, n)
    w = np.cumsum(rng.normal(0, wob, n)) * 0.15 if wob else 0
    return np.stack([cx + np.cos(t) * (rx + w), cy + np.sin(t) * (ry + w)], 1)


def dialogue_frame():
    """The dialogue box, drawn at its real size (1000x240; the box itself is 940x176 at (30, 32)), so the brush
    can run the whole way round without being stretched: a heavy C of ink round the left end that runs dry
    along the bottom, a long top stroke that thins to a hair in the middle, a bottom stroke laid back from the
    right, a ) round the right end flicked off up and out, a second, drier stroke over each end, grey water
    bleeding out round the ends, and ink flicked off the lower left and the upper right."""
    import ink_brush as IB
    k = 2
    W, H = 1000 * k, 240 * k
    bx0, by0, bx1, by1 = 30 * k, 32 * k, 970 * k, 208 * k
    r = 88 * k
    cyc = (by0 + by1) / 2
    pa = _pill_alpha(W, H, bx0 + 4 * k, by0 + 3 * k, bx1 - 4 * k, by1 - 3 * k, r - 4 * k, 3, 2.5 * k)
    pr = IB.paper(W, H, 5)
    ink = IB.Ink(W, H)
    lx, rx = bx0 + r, bx1 - r
    # 1. the left end: a heavy C pressed in at the top, round the end, running on and drying out along the
    #    bottom; a second, drier stroke laid over it
    left = _arc_pts(lx + 10 * k, cyc, r + 3 * k, r - 2 * k, -math.pi * 0.4, -math.pi * 1.5, 150, 0.7, 1)
    left = np.concatenate([left, np.stack([np.linspace(left[-1, 0], lx + 330 * k, 90),
                                           by1 - 1 * k + np.sin(np.linspace(0, 2.4, 90)) * 3 * k], 1)])
    ink.stroke(left, lambda u: k * (8 + 30 * math.sin(math.pi * min(1, u * 1.9 + 0.15)) ** 0.6 * (1 - 0.8 * u)),
               seed=11, dry=0.62, rough=0.2, hairs=14)
    ink.stroke(_arc_pts(lx + 22 * k, cyc + 6 * k, r - 14 * k, r - 20 * k, -math.pi * 0.72, -math.pi * 1.36, 80, 0.5, 2),
               lambda u: k * (3 + 11 * math.sin(math.pi * u) ** 0.7), seed=12, dry=0.8, rough=0.22, hairs=9, load=0.8)
    # 2. the top: pressed in past the left end, dragged right and lifted dry a little past the middle
    xs = np.linspace(lx - 20 * k, bx0 + 600 * k, 170)
    top = np.stack([xs, by0 + 1 * k + np.sin(np.linspace(0, 3.4, 170)) * 2.5 * k], 1)
    ink.stroke(top, lambda u: k * (6 + 14 * (1 - u) ** 1.6 + 3 * math.sin(u * 6) ** 2), seed=21, dry=0.55, rough=0.18, hairs=13)
    # a hair of ink carries the top edge on to the right end
    xs = np.linspace(bx0 + 560 * k, rx + 30 * k, 120)
    ink.stroke(np.stack([xs, by0 + 2 * k + np.sin(np.linspace(0, 2, 120)) * 1.5 * k], 1),
               lambda u: k * (1.6 + 2.5 * math.sin(math.pi * u)), seed=22, dry=0.5, rough=0.2, hairs=6, load=0.85)
    # 3. the right end: a ) from low on the bottom edge up round the end, flicked off up and out
    right = _arc_pts(rx - 8 * k, cyc, r + 2 * k, r - 1 * k, math.pi * 0.6, -math.pi * 0.42, 140, 0.7, 4)
    pre = np.stack([np.linspace(rx - 200 * k, right[0, 0], 60), by1 - 1 * k + np.sin(np.linspace(0, 1.6, 60)) * 2 * k], 1)
    flick = np.stack([np.linspace(right[-1, 0], bx1 + 18 * k, 30), np.linspace(right[-1, 1], by0 - 20 * k, 30)], 1)
    right = np.concatenate([pre, right, flick])
    ink.stroke(right, lambda u: k * (5 + 26 * math.sin(math.pi * min(1, u * 1.15)) ** 0.8 * (1 - 0.55 * u)),
               seed=41, dry=0.6, rough=0.2, hairs=13)
    ink.stroke(_arc_pts(rx - 18 * k, cyc - 4 * k, r - 12 * k, r - 18 * k, math.pi * 0.32, -math.pi * 0.28, 70, 0.5, 5),
               lambda u: k * (3 + 9 * math.sin(math.pi * u) ** 0.7), seed=42, dry=0.85, rough=0.22, hairs=8, load=0.78)
    # 4. ink flicked off the lower left and the upper right
    ink.splash(bx0 + 30 * k, by1 + 10 * k, 30 * k, 10 * k, 40, 0.6 * k, 2.8 * k, 6)
    ink.splash(bx1 - 10 * k, by0 - 10 * k, 22 * k, 12 * k, 26, 0.5 * k, 2.2 * k, 7)
    ink.splash(bx0 + 420 * k, by1 + 6 * k, 30 * k, 4 * k, 10, 0.4 * k, 1.2 * k, 8)
    # 6. water bleeding grey round the ends, little along the middle
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    ends = np.clip(1 - np.minimum(np.abs(xx - bx0 - 40 * k), np.abs(xx - bx1 + 40 * k)) / (170 * k), 0.12, 1)
    wash = ink.wash(13 * k, 0.6, 9, ends) * (1 - pa * 0.92)   # the bleed goes out, onto what is behind
    out = IB.compose(pr, pa * 0.98, ink, wash)
    return Image.fromarray(out, 'RGBA').resize((W // k, H // k), Image.LANCZOS)


def paper_frame():
    """Every other text panel: a 9-patch (192x128, texture margins 48 / 36) drawn with the same brush. The
    strokes along the edges are held uniform where the 9-patch stretches; all their character (the press, the
    turn round the corner, the dry lift, the bleed, the splashes) sits in the corners."""
    import ink_brush as IB
    k = 2
    W, H = 192 * k, 128 * k
    ml, mt = 48 * k, 36 * k
    inset = 11 * k
    r = 20 * k
    pa = _pill_alpha(W, H, inset + 2 * k, inset + 2 * k, W - inset - 2 * k, H - inset - 2 * k, r - 2 * k, 13, 1.2 * k)
    # plain paper, yellowing only with the distance to its edge (a 9-patch cannot carry texture that varies
    # along a stretch, and the corners must match the edges they meet)
    yy0, xx0 = np.mgrid[0:H, 0:W].astype(float)
    sdp = _rounded_sd(xx0, yy0, inset + 2 * k, inset + 2 * k, W - inset - 2 * k, H - inset - 2 * k, r - 2 * k)
    tone = np.clip(1 + sdp / (7 * k), 0, 1)[..., None]
    pr = np.array([238, 230, 210], float) * (1 - tone * 0.45) + np.array([216, 199, 166], float) * (tone * 0.45)
    ink = IB.Ink(W, H)
    x0, y0, x1, y1 = inset, inset, W - inset, H - inset
    # top: from the turn of the upper left corner, across, and down round the upper right
    top = np.concatenate([
        _arc_pts(x0 + r, y0 + r, r, r, math.pi * 0.95, math.pi * 1.5, 30),
        np.stack([np.linspace(x0 + r, x1 - r, 120), np.full(120, y0)], 1),
        _arc_pts(x1 - r, y0 + r, r, r, -math.pi * 0.5, -math.pi * 0.1, 20)])
    ink.stroke(top, lambda u: k * (4.6 + 8.0 * (1 - u / 0.18) ** 2 * (u < 0.18) + 2.5 * max(0, (u - 0.85) / 0.15)),
               seed=51, dry=0.4, rough=0.14, hairs=28, hold_axis=0, hold_lo=ml - 2, hold_hi=W - ml + 2, hold_width=4.6 * k)
    # bottom: laid back from the lower right corner to the lower left
    bot = np.concatenate([
        _arc_pts(x1 - r, y1 - r, r, r, -math.pi * 0.05, math.pi * 0.5, 22),
        np.stack([np.linspace(x1 - r, x0 + r, 120), np.full(120, y1)], 1),
        _arc_pts(x0 + r, y1 - r, r, r, math.pi * 0.5, math.pi * 0.95, 20)])
    ink.stroke(bot, lambda u: k * (5.0 + 8.0 * (1 - u / 0.2) ** 2 * (u < 0.2) + 2.0 * max(0, (u - 0.85) / 0.15)),
               seed=52, dry=0.45, rough=0.14, hairs=28, hold_axis=0, hold_lo=ml - 2, hold_hi=W - ml + 2, hold_width=5.0 * k)
    # left and right sides, held through the middle
    left = np.stack([np.full(100, x0), np.linspace(y0 + r * 0.6, y1 - r * 0.6, 100)], 1)
    ink.stroke(left, lambda u: k * (3.2 + 4.0 * (u < 0.15) * (1 - u / 0.15)), seed=53, dry=0.5, rough=0.15, hairs=22,
               hold_axis=1, hold_lo=mt - 2, hold_hi=H - mt + 2, hold_width=3.2 * k)
    right = np.stack([np.full(100, x1), np.linspace(y1 - r * 0.6, y0 + r * 0.6, 100)], 1)
    ink.stroke(right, lambda u: k * (3.0 + 3.5 * (u < 0.15) * (1 - u / 0.15)), seed=54, dry=0.55, rough=0.15, hairs=22,
               hold_axis=1, hold_lo=mt - 2, hold_hi=H - mt + 2, hold_width=3.0 * k)
    # a heavier sweep over the upper left and the lower right corners, splashes off them
    ink.stroke(_arc_pts(x0 + r + 2 * k, y0 + r + 2 * k, r + 3 * k, r + 3 * k, math.pi * 1.0, math.pi * 1.5, 50, 0.3, 6),
               lambda u: k * (4 + 11 * math.sin(math.pi * u) ** 0.8), seed=55, dry=0.6, rough=0.18, hairs=26)
    ink.stroke(_arc_pts(x1 - r - 2 * k, y1 - r - 2 * k, r + 3 * k, r + 3 * k, 0.0, math.pi * 0.5, 50, 0.3, 7),
               lambda u: k * (4 + 10 * math.sin(math.pi * u) ** 0.8), seed=56, dry=0.65, rough=0.18, hairs=26)
    ink.splash(x0 + 4 * k, y1 + 2 * k, 10 * k, 6 * k, 14, 0.4 * k, 1.6 * k, 8)
    ink.splash(x1 - 2 * k, y0 - 2 * k, 9 * k, 6 * k, 10, 0.4 * k, 1.4 * k, 9)
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    corner = (((xx < ml - 4 * k) | (xx > W - ml + 4 * k)) & ((yy < mt - 4 * k) | (yy > H - mt + 4 * k))).astype(float)
    wash = ink.wash(6 * k, 0.45, 19) * (1 - pa * 0.9)
    # the ink in the corners only may vary; make sure the stretched bands stay exactly uniform along the stretch
    # the stretchable bands: one clean row (column) from the middle of each, copied through it
    cy, cx = H // 2, W // 2
    for arr in (ink.a, ink.dark, wash, pa):
        arr[mt:H - mt, :] = arr[cy:cy + 1, :]
        arr[:, ml:W - ml] = arr[:, cx:cx + 1]
    pr[mt:H - mt, :] = pr[cy:cy + 1, :]
    pr[:, ml:W - ml] = pr[:, cx:cx + 1]
    out = IB.compose(pr, pa * 0.98, ink, wash)
    return Image.fromarray(out, 'RGBA').resize((W // k, H // k), Image.LANCZOS)


def _stroke(W, H, seed, dry_end=0.45):
    """A white horizontal brush stroke (tinted when used): a round press at the left, bristle tracks, a dry,
    ragged right end. Stretchable in its middle."""
    w, h = W * S, H * S
    yy, xx = np.mgrid[0:h, 0:w].astype(float) / S
    rng = np.random.default_rng(seed)
    t = xx / W
    cy = H * 0.5 + np.sin(t * math.pi) * H * 0.03
    half = H * (0.36 + 0.05 * np.sin(t * math.pi * 3)) * np.clip(t / 0.06, 0.35, 1.0) * (1 - 0.3 * np.clip((t - 0.85) / 0.15, 0, 1))
    d = np.abs(yy - cy) / np.maximum(half, 0.3)
    rows = _hash(h, seed)[np.clip((yy * S).astype(int), 0, h - 1)]
    end = 1 - np.clip((t - (1 - dry_end * 0.4)) / (dry_end * 0.4), 0, 1) * (rows * 1.6)
    body = (d < 1.0) & (end > 0.15)
    streak = rows > 0.12 + 0.5 * np.clip((t - 0.7) / 0.3, 0, 1) * (d > 0.3)
    a = body & streak
    out = np.zeros((h, w, 4), np.uint8)
    out[..., :3] = 255
    out[..., 3] = (a * 245).astype(np.uint8)
    im = Image.fromarray(out, 'RGBA').filter(ImageFilter.GaussianBlur(0.5))
    return im.resize((W, H), Image.LANCZOS)


def ink_stroke():
    """Under a chosen menu row or dialogue choice (tinted when used): a white stroke pressed in round at the
    left, its hairs drying into flying white toward a ragged right end. 9-patch 60 / 70, held uniform between."""
    import ink_brush as IB
    k = 2
    W, H = 320 * k, 52 * k
    ink = IB.Ink(W, H)
    xs = np.linspace(10 * k, W - 8 * k, 220)
    pts = np.stack([xs, H / 2 + np.sin(np.linspace(0, 3, 220)) * 1.5 * k * (np.abs(xs - W / 2) > 100 * k)], 1)
    ink.stroke(pts, lambda u: k * (34 + 8 * (u < 0.12) * (1 - u / 0.12) - 18 * max(0, (u - 0.8) / 0.2)),
               seed=61, dry=0.75, rough=0.2, hairs=12, hold_axis=0, hold_lo=60 * k, hold_hi=W - 70 * k, hold_width=34 * k)
    a = ink.a
    a[:, 60 * k:W - 70 * k] = a[:, 60 * k:W - 70 * k].mean(axis=1, keepdims=True)
    out = np.zeros((H, W, 4), np.uint8)
    out[..., :3] = 255
    out[..., 3] = (np.clip(a, 0, 1) * 245).astype(np.uint8)
    return Image.fromarray(out, 'RGBA').resize((W // k, H // k), Image.LANCZOS)


def seal_tag():
    """A speaker's name sits on this cinnabar seal: rough edges, a little uneven ink. 9-patch 24 / 10."""
    W, H = 110, 46
    w, h = W * S, H * S
    yy, xx = np.mgrid[0:h, 0:w].astype(float) / S
    rng = np.random.default_rng(7)
    sd = _rounded_sd(xx, yy, 3, 3, W - 3, H - 3, 7)
    rough = (rng.random((h, w)) - 0.5) * 0.9
    inside = (sd + rough) < 0
    tex = 1 - (rng.random((h, w)) < 0.05) * 0.25
    edge_dark = np.clip(1 - (-sd) / 4.0, 0, 1) * 0.22
    col = CINNABAR[None, None, :] * (tex * (1 - edge_dark))[..., None]
    out = np.zeros((h, w, 4), float)
    out[..., :3] = col
    out[..., 3] = inside * 250
    im = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGBA').filter(ImageFilter.GaussianBlur(0.4))
    return im.resize((W, H), Image.LANCZOS)


def _blossom(dr, cx, cy, r, rng):
    pink = (238, 168, 178, 255)
    pale = (250, 220, 224, 255)
    for k in range(5):
        a = rng.uniform(0, 0.4) + k * 2 * math.pi / 5
        px, py = cx + math.cos(a) * r * 0.62, cy + math.sin(a) * r * 0.62
        dr.ellipse([px - r * 0.55, py - r * 0.55, px + r * 0.55, py + r * 0.55], fill=pink)
        dr.ellipse([px - r * 0.3, py - r * 0.3, px + r * 0.3, py + r * 0.3], fill=pale)
    dr.ellipse([cx - r * 0.28, cy - r * 0.28, cx + r * 0.28, cy + r * 0.28], fill=(150, 40, 48, 255))
    for k in range(6):
        a = k * math.pi / 3 + 0.3
        dr.line([cx, cy, cx + math.cos(a) * r * 0.75, cy + math.sin(a) * r * 0.75], fill=(120, 30, 34, 255), width=max(1, int(r * 0.08)))


def _branch(dr, pts, w0, w1):
    n = len(pts)
    for i in range(n - 1):
        t = i / (n - 1)
        wdt = w0 + (w1 - w0) * t
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        dr.line([x0, y0, x1, y1], fill=(24, 20, 22, 255), width=max(1, int(wdt)))
        dr.ellipse([x1 - wdt / 2, y1 - wdt / 2, x1 + wdt / 2, y1 + wdt / 2], fill=(24, 20, 22, 255))


def _curve(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        u = i / n
        v = 1 - u
        out.append((v ** 3 * p0[0] + 3 * v * v * u * p1[0] + 3 * v * u * u * p2[0] + u ** 3 * p3[0],
                    v ** 3 * p0[1] + 3 * v * v * u * p1[1] + 3 * v * u * u * p2[1] + u ** 3 * p3[1]))
    return out


def plum_branch():
    """A branch of mai in ink leaning in at the left end of the dialogue box, a few blossoms and buds on it."""
    W, H = 190, 240
    k = 4
    im = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    rng = np.random.default_rng(5)
    sc = lambda pts: [(x * k, y * k) for x, y in pts]  # noqa: E731
    main = _curve((26, 236), (6, 160), (52, 112), (40, 24))
    _branch(dr, sc(main), 10 * k, 2.0 * k)
    twigs = [
        _curve(main[14], (52, 150), (78, 140), (100, 120), 20),
        _curve(main[24], (68, 102), (102, 88), (124, 72), 18),
        _curve(main[8], (6, 190), (0, 176), (4, 160), 12),
        _curve(main[31], (30, 62), (18, 50), (10, 38), 12),
    ]
    for tw in twigs:
        _branch(dr, sc(tw), 2.6 * k, 0.9 * k)
    # dry brush flecks along the main limb
    for i in range(0, len(main) - 1, 2):
        x, y = main[i]
        if rng.random() < 0.6:
            dr.line([(x + 3) * k, y * k, (x + 3 + rng.uniform(1, 4)) * k, (y - rng.uniform(0, 2)) * k], fill=(24, 20, 22, 120), width=k)
    blossoms = [(100, 120, 9.5), (124, 72, 8.5), (52, 116, 7.5), (34, 50, 8.0), (78, 140, 7.0), (4, 160, 6.5), (40, 26, 6.5), (112, 96, 6.0)]
    for x, y, r in blossoms:
        _blossom(dr, x * k, y * k, r * k, rng)
    for x, y in ((112, 80), (90, 132), (18, 44), (64, 108), (130, 62)):
        dr.ellipse([(x - 2.8) * k, (y - 3.2) * k, (x + 2.8) * k, (y + 3.2) * k], fill=(214, 98, 112, 255))
    return im.filter(ImageFilter.GaussianBlur(0.6 * k / 2)).resize((W, H), Image.LANCZOS)


def petal():
    W, H = 14, 10
    k = 4
    im = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    dr.ellipse([1 * k, 1 * k, 13 * k, 9 * k], fill=(238, 168, 178, 255))
    dr.ellipse([4 * k, 3 * k, 10 * k, 7 * k], fill=(250, 214, 220, 255))
    return im.resize((W, H), Image.LANCZOS)


ALL = {
    'paper_frame': paper_frame, 'dialogue_frame': dialogue_frame, 'ink_stroke': ink_stroke,
    'seal_tag': seal_tag, 'plum_branch': plum_branch, 'petal': petal,
}
