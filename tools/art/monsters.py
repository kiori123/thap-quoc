"""Nghiệt sprites for the prologue.

Trắng Tay: the fear of the people behind the White Gate, in their shape (they themselves live on in the city):
one white porcelain statue of mercy with a thousand hands and its eyes bound: a hooded robe on a lotus, a fan of the crowd's arms behind it, a crown of the crowd's
faces under conical hats, every face blindfolded in cobalt. Two crown faces have broken away.
Mảnh Sành: one of those crown faces, broken off at the neck, crawling on porcelain fingers.
Both are glazed white porcelain with cobalt (men lam) brushwork and dark cracks.

Both are drawn facing LEFT (gen_art mirrors them to face the party on the right).
"""
import math
import numpy as np
from PIL import Image
import os
from pix import Canvas, ramp

PORC = ramp('#e6ebef', shadow='#a9b6c2', light='#f7fafc', outline='#36424f', hi='#ffffff')
PORC_DARK = ramp('#c4ced8', shadow='#8e9cab', light='#dae2e9', outline='#2f3a46', hi='#eef3f7')
LAM = ramp('#3b5fae', shadow='#2a4689', light='#587dcb', outline='#1a2850', hi='#7e9fe0')
CRACK = ramp('#4a5b6c', shadow='#3a4856', light='#5f7284', outline='#222b35')
GLOW = ramp('#c4f1ff', shadow='#95d8ef', light='#e8fbff', outline='#4d8aa3', hi='#ffffff')
VOID = ramp('#20242d', shadow='#14171d', light='#2e3440', outline='#0b0d11')


def _hollow(im, x, y, rx, ry):
    """Knock a dark hole with a jagged rim into an RGBA image (a piece that has broken away)."""
    a = np.array(im)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    d = ((xx - x) / rx) ** 2 + ((yy - y) / ry) ** 2
    jag = (np.sin(np.arctan2(yy - y, xx - x) * 5.0) * 0.18)
    hole = (d <= 1.0 + jag) & (a[:, :, 3] > 0)
    rim = (d <= 1.35 + jag) & ~hole & (a[:, :, 3] > 0)
    a[hole, :3] = (28, 32, 40)
    a[rim, :3] = (96, 108, 124)
    return Image.fromarray(a, 'RGBA')


# ------------------------------------------------------------------ shape helpers
def _bez(p0, p1, p2, n=10):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in np.linspace(0, 1, n)]


def _taper(c, pts, w0, w1):
    """Mask of a limb following pts, its width going from w0 to w1."""
    n = len(pts)
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L, dx / L
        w = (w0 + (w1 - w0) * i / max(n - 1, 1)) / 2.0
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return c.poly(left + right[::-1])


def _hand(c, x, y, ang, s=1.0, spread=1.0):
    """An open porcelain hand at wrist (x, y), pointing along ang (radians): palm, four fingers, a thumb."""
    ux, uy = math.cos(ang), math.sin(ang)
    px_, py_ = -uy, ux
    pcx, pcy = x + ux * 2.2 * s, y + uy * 2.2 * s
    palm = c.poly([(x + px_ * 1.6 * s, y + py_ * 1.6 * s), (pcx + ux * 1.6 * s + px_ * 2.0 * s, pcy + uy * 1.6 * s + py_ * 2.0 * s),
                   (pcx + ux * 1.6 * s - px_ * 2.0 * s, pcy + uy * 1.6 * s - py_ * 2.0 * s), (x - px_ * 1.6 * s, y - py_ * 1.6 * s)])
    m = palm
    base_x, base_y = pcx + ux * 1.4 * s, pcy + uy * 1.4 * s
    for k, off in enumerate((-1.5, -0.5, 0.5, 1.5)):
        a = ang + off * 0.22 * spread
        L = (3.6 - abs(off) * 0.5) * s
        sx, sy = base_x + px_ * off * 1.1 * s, base_y + py_ * off * 1.1 * s
        m = m | c.line([(sx, sy), (sx + math.cos(a) * L, sy + math.sin(a) * L)], 1)
    ta = ang - 1.15 * spread
    tx, ty = pcx - px_ * 1.6 * s, pcy - py_ * 1.6 * s
    m = m | c.line([(tx, ty), (tx + math.cos(ta) * 2.6 * s, ty + math.sin(ta) * 2.6 * s)], 1)
    return m


def _crack(c, m, x, y, ang, length, rng, region, branch=True):
    """A crack: a jittered line that may fork once."""
    pts = []
    for i in range(int(length)):
        pts.append((int(round(x)), int(round(y))))
        ang += rng.uniform(-0.6, 0.6)
        x += math.cos(ang)
        y += math.sin(ang)
    for (px_, py_) in pts:
        if 0 <= px_ < c.w and 0 <= py_ < c.h and region[py_, px_]:
            c.paint(c.px(px_, py_), m)
    if branch and len(pts) > 5:
        bx, by = pts[len(pts) // 2]
        _crack(c, m, bx, by, ang + rng.choice([-1.0, 1.0]), length * 0.45, rng, region, branch=False)


def _brighten(im, amt):
    a = np.array(im)
    m = a[:, :, 3] > 0
    a[m, :3] = np.clip(a[m, :3].astype(int) + amt, 0, 255)
    return Image.fromarray(a, 'RGBA')


# ------------------------------------------------------------------ Mảnh Sành 48x48
def manh_tinh(frame):
    """Mảnh Sành: one of the small faces from Trắng Tay's crown, hat, blindfold and all, broken off at the neck and
    crawling on porcelain fingers like a crab. Facing LEFT.
    frames: 0 idle_a, 1 idle_b, 2 rear (front fingers raised), 3 lunge (thrown forward), 4 hurt (tipped, curled), 5 shatter"""
    if frame == 5:
        c = Canvas(48, 48)
        D = c.material(PORC_DARK)
        P = c.material(PORC)
        B = c.material(LAM, flat=True, outline=False)
        rr = np.random.default_rng(7)
        for i in range(13):
            a_ = rr.uniform(0, math.tau)
            r = rr.uniform(4, 17)
            x, y = 24 + math.cos(a_) * r, 36 + math.sin(a_) * r * 0.45
            if i % 3 == 0:
                ang = rr.uniform(0, math.tau)
                c.paint(_taper(c, [(x, y), (x + math.cos(ang) * 4, y + math.sin(ang) * 4)], 2.4, 1.8), P)
            else:
                s_ = rr.uniform(2.0, 3.8)
                c.paint(c.poly([(x, y - s_), (x + s_, y + s_ * 0.6), (x - s_ * 0.8, y + s_ * 0.5)]), P if i % 2 else D)
                if i % 4 == 1:
                    c.paint(c.px(int(x), int(y)), B)
        return c.render(volume=True)

    G = 44
    lift = {0: 0, 1: 1, 2: -3, 3: -6, 4: 2}[frame]
    shift = {0: 0, 1: 0, 2: 2, 3: -5, 4: 2}[frame]
    tilt = {0: 0, 1: 0, 2: -14, 3: 8, 4: 22}[frame]
    cx, cy = 25 + shift, 30 + lift          # where the neck sits, just above the legs

    def legs(near):
        c = Canvas(48, 48)
        D = c.material(PORC_DARK)
        P = c.material(PORC)
        roots = [(-5, 1), (0, 2), (5, 1)]
        for i, (rx0, ry0) in enumerate(roots):
            rx, ry = cx + rx0 + (1 if near else -1), cy + ry0 + (1 if near else 0)
            out = [-1, 0, 1][i]
            gy = G if near else G - 2
            if frame == 2 and i == 0:
                j, t = (rx - 6, ry - 5), (rx - 10, ry - 11 + (0 if near else 2))
            elif frame == 3:
                j, t = (rx - 5 + out * 2, ry + 3), (rx - 9 + out * 5, ry + 8)
            elif frame == 4:
                j, t = (rx - 2, ry + 4), (rx + 2, ry + 5)
            else:
                step = (1 if (frame == 1 and (i + (1 if near else 0)) % 2) else 0)
                j = (rx + out * 6, ry - 2 + abs(out))
                t = (rx + out * 9 + step, gy)
            m = P if near else D
            c.paint(_taper(c, _bez((rx, ry), j, t, 10), 2.6, 1.4), m)
            c.paint(c.ellipse(j[0], j[1], 1.4, 1.3), m)
            c.set_tone(c.px(int(round(t[0])), int(round(t[1])) - 1), 4)
        return c.render(volume=True)

    out = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    out.alpha_composite(legs(False))
    # the head: one of the crown's faces, broken off. A porcelain hat over a smooth face, the cobalt blindfold
    # still knotted on, the back of the skull and the neck snapped off dark and jagged
    hc = Canvas(32, 24)
    Hh = hc.material(PORC_DARK)
    Hf = hc.material(PORC)
    Hb = hc.material(LAM, flat=True, outline=False)
    Hk = hc.material(CRACK, flat=True, outline=False)
    Hv = hc.material(VOID, flat=True)
    hc.paint(hc.ellipse(16, 13.5, 7.0, 7.4), Hf)
    hc.paint(hc.poly([(5, 8.5), (16, 0), (27, 8.5)]), Hh)
    hc.paint(hc.rect(9, 10, 23, 12), Hb)                                        # the blindfold
    hc.paint(_taper(hc, _bez((23, 11), (26, 13), (28, 16), 6), 2.2, 1.0), Hb)   # its loose tail
    hc.paint(hc.px(16, 16) | hc.px(15, 16), Hk)                                # mouth
    hc.paint(hc.px(12, 13) | hc.px(12, 14) | hc.px(11, 15), Hk)                # the tear-crack
    for x in range(10, 23):                                                     # the snapped neck
        cut = 19 + (1 if (x * 7) % 5 < 2 else 0)
        hc.erase(hc.rect(x, cut + 1, x, 23))
        hc.paint(hc.px(x, cut), Hv)
    head = hc.render(volume=True)
    head = _hollow(head, 21, 5, 2.0, 1.5)                   # a chip knocked out of the hat
    if tilt:
        head = head.rotate(tilt, resample=Image.NEAREST, expand=True)
    out.alpha_composite(head, (int(cx - head.width / 2), int(cy - head.height + 2)))
    out.alpha_composite(legs(True))
    im = out
    if frame == 4:
        im = _brighten(im, 55)
    return im


# ------------------------------------------------------------------ Trắng Tay 112x144
def nghiet_tinh(frame):
    """Trắng Tay: the crowd behind the White Gate, in shape (their fear, not the people), one white porcelain statue
    of mercy, a thousand hands and its eyes bound. One standing figure in a hooded white robe on a lotus, hands joined; behind it
    a great fan of arms (the crowd's arms); on its head a crown of small faces under conical hats (the crowd's
    faces), every one of them blindfolded in cobalt. Two crown faces have broken off: those are the Mảnh Sành.
    Built in layers so each part keeps its own dark outline: back arms, near arms, the figure, the crown/hands.
    frames: 0-2 idle (arms sway, blindfold tails stir), 3 reach (the near-side arms swing at the target, left),
    4 purify (every arm flung wide, cracks and halo glowing), 5 hurt, 6 recoil (the lotus and robe shattering)"""
    W_, H_ = 112, 144
    cx = 56
    rng = np.random.default_rng(13 + frame)
    lift = {0: 0, 1: -1, 2: 0, 3: 1, 4: -3, 5: 0, 6: 2}[frame]
    up = frame == 4
    hx, hy = cx + (-1 if frame == 3 else 0), 45 + lift            # face centre
    sway = [math.sin(i * 1.3 + frame * 2.1) * 3.0 for i in range(40)]

    def arm(c, mat, B, ang_deg, length, root_r, w0, w1, hand_s, spread, oy=62):
        a_ = math.radians(ang_deg)
        r0 = (cx + math.cos(a_) * root_r, oy + lift + math.sin(a_) * root_r)
        bend = a_ - 0.12 * (1 if math.cos(a_) >= 0 else -1)
        el = (cx + math.cos(bend) * (root_r + length) * 0.55, oy + lift + math.sin(bend) * (root_r + length) * 0.55)
        wr = (cx + math.cos(a_) * (root_r + length), oy + lift + math.sin(a_) * (root_r + length))
        c.paint(_taper(c, _bez(r0, el, wr, 12), w0, w1), mat)
        ha = math.atan2(wr[1] - el[1], wr[0] - el[0])
        c.paint(_hand(c, wr[0], wr[1], ha, hand_s, spread), mat)
        c.paint(c.px(int(round(wr[0] - math.cos(ha) * 1.5)), int(round(wr[1] - math.sin(ha) * 1.5))), B)   # cobalt cuff

    def fan(n, a0, a1, off):
        return [a0 + (a1 - a0) * (k + off) / (n - 1 + 2 * off) for k in range(n)]

    # ---- layer A: the far ring of arms, the aureole's outer edge
    A = Canvas(W_, H_)
    Da = A.material(PORC_DARK)
    Ba = A.material(LAM, flat=True, outline=False)
    outer = fan(15, -202, 22, 0.0)
    for i, ang in enumerate(outer):
        if up:
            ang, L, sp = ang + (ang + 90) * 0.12, 42, 1.5
        elif frame == 6:
            ang, L, sp = ang + (12 if math.cos(math.radians(ang)) > 0 else -12) * -1, 32, 0.6
        else:
            ang, L, sp = ang + sway[i], 36 + (2 if i % 2 else 0), 1.0 + 0.25 * math.sin(frame * 2.1 + i)
        arm(A, Da, Ba, ang, L, 12, 4.4, 2.8, 1.15, sp)

    # ---- layer B: the near ring of arms, shorter, between the far ones; the cobalt halo behind the head
    Bc = Canvas(W_, H_)
    Pb = Bc.material(PORC)
    Bb = Bc.material(LAM, flat=True, outline=False)
    Gb = Bc.material(GLOW, flat=True, outline=False)
    near = fan(12, -196, 16, 0.5)
    for i, ang in enumerate(near):
        left = math.cos(math.radians(ang)) < -0.3
        if frame == 3 and left:                      # the arms on the target's side all swing at it
            ang, L, sp = -180 + (ang + 180) * 0.55 + (i % 3 - 1) * 3, 36 + (i % 3) * 4, 1.5
        elif up:
            ang, L, sp = ang + (ang + 90) * 0.12, 34, 1.5
        elif frame == 6:
            ang, L, sp = ang + (14 if math.cos(math.radians(ang)) > 0 else -14) * -1, 24, 0.6
        else:
            ang, L, sp = ang + sway[i + 20], 26 + (2 if i % 2 == 0 else 0), 1.0
        arm(Bc, Pb, Bb, ang, L, 10, 5.0, 3.2, 1.3, sp)
    ring = Bc.ellipse(hx, hy - 8, 23.5, 23.5) & ~Bc.ellipse(hx, hy - 8, 21.6, 21.6)
    Bc.paint(ring, Gb if up else Bb)

    # ---- the figure, in layers so each part keeps its own outline: lotus, robe, hood, sleeves, face, crown, hands
    L_ = lift
    layers = []

    def lay():
        c = Canvas(W_, H_)
        layers.append(c)
        return c

    # lotus: a back row of petals, the seat with its rounded underside, a front row of round petals with
    # pointed tips, each with a cobalt vein
    c = lay()
    Pl = c.material(PORC_DARK)
    Pl2 = c.material(PORC_DARK)
    for k in range(7):
        x0 = cx - 21 + k * 7
        c.paint(c.ellipse(x0, 119 + L_, 4.2, 4.5) | c.poly([(x0 - 3.5, 118 + L_), (x0, 111 + L_), (x0 + 3.5, 118 + L_)]), Pl if k % 2 else Pl2)
    c.paint(c.ellipse(cx, 127 + L_, 27, 5) | c.ellipse(cx, 130 + L_, 22, 5), Pl)
    for k in range(7):
        x0 = cx - 21 + k * 7
        c.paint(c.ellipse(x0, 134 + L_, 3.6, 2.6), Pl2 if k % 2 else Pl)
    c = lay()
    Pf_ = c.material(PORC)
    Pf2 = c.material(PORC)
    Bf = c.material(LAM, flat=True, outline=False)
    for k, dx in enumerate((-22, -13.5, -4.5, 4.5, 13.5, 22)):
        x0, y0 = cx + dx, 126 + L_ - (1 if abs(dx) < 10 else 0)
        lean_ = (-2 if dx < 0 else 2) * (abs(dx) > 10)
        tip = (x0 + lean_, y0 - 10)
        c.paint(c.ellipse(x0, y0 - 1, 5.2, 4.6) | c.poly([(x0 - 4.2, y0 - 2.5), tip, (x0 + 4.2, y0 - 2.5)]), Pf_ if k % 2 else Pf2)
        c.paint(c.line([(tip[0], tip[1] + 3), (x0, y0 - 2)], 1), Bf)
    # the robe, standing, flaring a little to the hem, a cobalt wave along the hem
    c = lay()
    Pr = c.material(PORC)
    Br = c.material(LAM, flat=True, outline=False)
    K = c.material(CRACK, flat=True, outline=False)
    G = c.material(GLOW, flat=True, outline=False)
    robe = c.poly([(cx - 9, 58 + L_), (cx + 9, 58 + L_), (cx + 13, 66 + L_), (cx + 13, 90 + L_), (cx + 17, 121 + L_),
                   (cx - 17, 121 + L_), (cx - 13, 90 + L_), (cx - 13, 66 + L_)])
    c.paint(robe, Pr)
    c.paint(c.line([(cx, 82 + L_), (cx + 1, 100 + L_), (cx - 1, 120 + L_)], 1), K)
    for x in range(cx - 17, cx + 18):
        y = 116 + L_ + (1 if (x // 2) % 2 else 0)
        if robe[y, x]:
            c.paint(c.px(x, y) | c.px(x, y + 1), Br)
    for k in range(3):
        ys, xs = np.where(robe)
        i = rng.integers(len(xs))
        _crack(c, G if up else K, xs[i], ys[i], rng.uniform(0, math.tau), rng.integers(7, 12), rng, robe)
    # the hood, white, over head and shoulders, cobalt-edged
    c = lay()
    Ph = c.material(PORC)
    Bh = c.material(LAM, flat=True, outline=False)
    c.paint(c.ellipse(hx, hy - 1, 12, 13) | c.poly([(hx - 12, hy), (hx + 12, hy), (cx + 17, 70 + L_), (cx - 17, 70 + L_)]), Ph)
    c.paint(c.line([(hx - 11, hy + 3), (cx - 16, 69 + L_)], 1) | c.line([(hx + 11, hy + 3), (cx + 16, 69 + L_)], 1), Bh)
    c.paint(c.ellipse(hx, hy + 1, 8.2, 10) & ~c.ellipse(hx, hy + 1, 7.0, 9.0), Bh)          # the opening round the face
    # the sleeves, hanging wide from forearms raised to the chest
    c = lay()
    Ps = c.material(PORC)
    Ps2 = c.material(PORC)
    Bs = c.material(LAM, flat=True, outline=False)
    Ks = c.material(CRACK, flat=True, outline=False)
    for s in (-1, 1):
        sl = c.poly([(cx + s * 4, 74 + L_), (cx + s * 12, 66 + L_), (cx + s * 18, 72 + L_), (cx + s * 22, 100 + L_),
                     (cx + s * 18, 107 + L_), (cx + s * 11, 104 + L_), (cx + s * 6, 86 + L_)])
        c.paint(sl, Ps if s < 0 else Ps2)
        c.paint(c.line([(cx + s * 11, 104 + L_), (cx + s * 18, 107 + L_), (cx + s * 22, 101 + L_)], 1), Bs)
        c.paint(c.line([(cx + s * 13, 72 + L_), (cx + s * 16, 92 + L_)], 1), Ks)               # a fold
    # the face, set into the hood: the blindfold across the eyes, its knot and tails, a mouth shut, a crack like a tear
    c = lay()
    Pfa = c.material(PORC)
    Bfa = c.material(LAM, flat=True, outline=False)
    Kf = c.material(CRACK, flat=True, outline=False)
    Gf = c.material(GLOW, flat=True, outline=False)
    c.paint(c.ellipse(hx, hy + 1, 6.6, 8.6), Pfa)
    c.paint(c.rect(hx - 7, hy - 2, hx + 7, hy + 1), Bfa)
    c.paint(c.line([(hx - 6, hy - 2), (hx + 6, hy - 2)], 1), c.material(LAM, flat=True, outline=False), tone=3)
    for t_ in range(2):
        lt = -5 if up else 0
        wob = math.sin(frame * 1.9 + t_) * 2.0
        pts = [(hx + 7, hy - 1), (hx + 13 + t_ * 2, hy + 2 + t_ * 3 + wob * 0.5 + lt), (hx + 16 + t_ * 3, hy + 8 + t_ * 4 + wob + lt * 1.5)]
        c.paint(_taper(c, _bez(*pts, 8), 2.6, 1.2), Bfa)
    c.paint(c.rect(hx - 1, hy + 5, hx + 1, hy + 5), Kf)                                      # mouth
    c.paint(c.px(hx, hy + 3), Kf)                                                            # nose shadow
    for (x, y) in ((hx - 4, hy + 2), (hx - 4, hy + 3), (hx - 5, hy + 4), (hx - 5, hy + 5), (hx - 4, hy + 6), (hx - 4, hy + 7)):
        c.paint(c.px(x, y), Gf if up else Kf)
    # the crown: three tiers of small faces under conical hats, all blindfolded; the back tier drawn first
    tiers = [((-5, -9), (5, -9)), ((-10, 0), (0, 1), (10, 0))]
    broken = {(0, 0), (1, 2)}
    for ti, tier in enumerate(tiers):
        c = lay()
        Ht = c.material(PORC_DARK)
        Ft = c.material(PORC)
        Ft2 = c.material(PORC)
        Bt = c.material(LAM, flat=True, outline=False)
        Vt = c.material(VOID, flat=True)
        for hi_, (dx, dy) in enumerate(tier):
            x, y = hx + dx, hy - 16 + dy - (1 if up else 0)
            c.paint(c.ellipse(x, y + 1.5, 3.6, 4.0), Ft if hi_ % 2 else Ft2)
            c.paint(c.poly([(x - 5.8, y - 0.5), (x, y - 6.5), (x + 5.8, y - 0.5)]), Ht)
            if (ti, hi_) in broken:
                c.paint(c.ellipse(x, y + 2, 2.5, 2.8), Vt)
                continue
            c.paint(c.rect(x - 3, y + 1, x + 3, y + 2), Bt)
    # the hands joined at the chest (frames 3-4: torn apart, palms out)
    c = lay()
    Pd = c.material(PORC)
    Bd = c.material(LAM, flat=True, outline=False)
    if frame in (3, 4):
        for s in (-1, 1):
            hxp, hyp = cx + s * 8, 70 + lift
            c.paint(c.ellipse(hxp, hyp, 3.2, 3.6), Pd)
            for f_ in range(4):
                fa = math.radians(-90 + s * (25 + f_ * 16))
                c.paint(c.line([(hxp, hyp), (hxp + math.cos(fa) * 6, hyp + math.sin(fa) * 6)], 1), Pd)
            c.paint(c.px(hxp, hyp + 3), Bd)
    else:
        c.paint(c.poly([(cx - 3, 79 + lift), (cx - 3, 71 + lift), (cx, 64 + lift), (cx + 3, 71 + lift), (cx + 3, 79 + lift)]), Pd)
        c.paint(c.line([(cx, 67 + lift), (cx, 78 + lift)], 1), Bd)

    im = Image.new('RGBA', (W_, H_), (0, 0, 0, 0))
    for cv in [A, Bc] + layers:
        im.alpha_composite(cv.render(volume=True, side_shade=0.12))
    a = np.array(im)
    # shards drifting under the lotus
    sh = Canvas(W_, H_)
    Ds = sh.material(PORC_DARK)
    for k in range(7):
        x = cx - 20 + k * 7 + (frame * 2 + k * 3) % 4
        y = 138 + (k * 5 + frame * 3) % 5
        s_ = 1.4 + (k % 3) * 0.5
        sh.paint(sh.poly([(x, y - s_), (x + s_ * 1.3, y + s_ * 0.4), (x - s_ * 0.5, y + s_)]), Ds)
    shi = np.array(sh.render(volume=True))
    m = (shi[:, :, 3] > 0) & (a[:, :, 3] == 0)
    a[m] = shi[m]
    if frame == 5:
        a = np.array(_brighten(Image.fromarray(a, 'RGBA'), 50))
    if frame == 6:
        rr = np.random.default_rng(9)
        top = 96
        src = a.copy()
        a[top:, :, 3] = 0
        seeds = [(rr.uniform(26, 86), rr.uniform(top, H_)) for _ in range(30)]
        yy, xx = np.mgrid[top:H_, 0:W_]
        d = np.stack([(xx - sx_) ** 2 + (yy - sy_) ** 2 for (sx_, sy_) in seeds])
        owner = d.argmin(0)
        for k, (sx_, sy_) in enumerate(seeds):
            if rr.random() < 0.25:
                continue
            depth = (sy_ - top) / (H_ - top)
            dy = int(depth * 10 + rr.integers(0, 2))
            dx = int(round((sx_ - cx) * 0.08 * depth * 3 + rr.integers(-1, 2)))
            ys_, xs_ = np.nonzero(owner == k)
            ys_ = ys_ + top
            keep = src[ys_, xs_, 3] > 0
            ys_, xs_ = ys_[keep], xs_[keep]
            ty, tx = ys_ + dy, xs_ + dx
            ok = (ty < H_) & (tx >= 0) & (tx < W_)
            a[ty[ok], tx[ok]] = src[ys_[ok], xs_[ok]]
    return Image.fromarray(a, 'RGBA')


# ------------------------------------------------------------------ Trắng Tay's reaching arm (battle FX)
def reach_segment_frames():
    """One link of a stretched porcelain arm, pointing right, 10x8: 0 plain, 1 a joint with a cobalt band."""
    frames = []
    for f in range(2):
        c = Canvas(10, 8)
        P = c.material(PORC)
        B = c.material(LAM, flat=True, outline=False)
        if f == 0:
            c.paint(c.ellipse(5, 4, 5.2, 2.6), P)
        else:
            c.paint(c.ellipse(5, 4, 5.2, 2.6) | c.ellipse(5, 4, 2.6, 3.4), P)
            c.paint(c.rect(4, 1, 4, 6) | c.rect(6, 1, 6, 6), B)
        frames.append(c.render(volume=True))
    from pix import sheet
    return sheet(frames, 2)


def reach_hand_frames():
    """The hand at the end of a reaching arm, wrist on the left, pointing right, 20x20: 0 open, 1 snapping shut."""
    frames = []
    for f in range(2):
        c = Canvas(20, 20)
        P = c.material(PORC)
        B = c.material(LAM, flat=True, outline=False)
        c.paint(c.ellipse(3, 10, 3.0, 2.5), P)                                  # wrist
        c.paint(c.poly([(4, 7), (10, 6), (12, 9), (11, 14), (5, 13)]), P)       # palm
        if f == 0:   # fingers fanned wide, gaps between them
            for (r, tip) in (((11, 7), (16, 1)), ((12, 9), (19, 6)), ((12, 11), (19, 12)), ((11, 13), (16, 17))):
                c.paint(_taper(c, [r, ((r[0] + tip[0]) / 2 + 0.5, (r[1] + tip[1]) / 2), tip], 2.4, 1.5), P)
            c.paint(_taper(c, [(6, 13), (6, 16), (8, 19)], 2.4, 1.6), P)         # thumb, hooked down
        else:        # snapping shut into a claw
            for (r, k, tip) in (((11, 7), (15, 5), (16, 8)), ((12, 9), (16, 8), (16, 10)), ((12, 11), (16, 11), (15, 12)),
                                ((11, 13), (15, 14), (14, 12))):
                c.paint(_taper(c, [r, k, tip], 2.4, 1.8), P)
            c.paint(_taper(c, [(6, 13), (10, 15), (12, 13)], 2.4, 1.8), P)
        c.paint(c.rect(2, 8, 2, 12), B)                                         # cobalt cuff
        frames.append(c.render(volume=True))
    from pix import sheet
    return sheet(frames, 2)
