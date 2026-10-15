"""Billboard prop sprites: vegetation and village objects."""
import math
import numpy as np
from PIL import Image
from pix import Canvas, ramp

LEAF = ramp('#4f7a36', shadow='#355a26', light='#6d9a48', outline='#1a2c12', hi='#8fb85c')
LEAF_DARK = ramp('#3c5f2c', shadow='#2a451f', light='#527a3a', outline='#121f0c', hi='#6a9149')
LEAF_YEL = ramp('#7c8f3c', shadow='#5c6b2b', light='#9db150', outline='#26300f')
BAMBOO = ramp('#7f9a46', shadow='#5c7333', light='#9fba5c', outline='#22300f', hi='#c4d986')
BAMBOO_OLD = ramp('#a39253', shadow='#7a6c3c', light='#c0ae6a', outline='#302814')
TRUNK = ramp('#6a5038', shadow='#4a3626', light='#86684a', outline='#1e150d')
TRUNK_GREY = ramp('#7d776c', shadow='#5b564e', light='#9a958a', outline='#25221e')
BANANA_STEM = ramp('#7d8a4a', shadow='#5d6836', light='#9aa962', outline='#262c14')
PINE = ramp('#2f4a34', shadow='#1f3324', light='#41634a', outline='#0b140d')
WOODP = ramp('#8a6440', shadow='#62452c', light='#a67d55', outline='#24170c')
WOOD_END = ramp('#c39d6c', shadow='#9b7a50', light='#d9b886', outline='#4a3424')
CLAY = ramp('#7b4a32', shadow='#563222', light='#9a6143', outline='#1f110a', hi='#c08260')
STRAWP = ramp('#c9a45c', shadow='#9c7a3d', light='#e2c47f', outline='#4a3818')
DRYLEAF = ramp('#9a6a35', shadow='#6e4a24', light='#b98845', outline='#2c1c0c')
PAPER = ramp('#e8dcc0', shadow='#c0ad88', light='#f6eedc', outline='#4d4232')
RED = ramp('#a33a30', shadow='#74261f', light='#c45a45', outline='#2c0f0c')
RICE = ramp('#d8d2bf', shadow='#b3ab95', light='#efeadb', outline='#4f4a3c')
BOWL = ramp('#c6cfd2', shadow='#94a0a6', light='#e2e8ea', outline='#3c4448')
FLOWER = ramp('#e2d27a', shadow='#b8a654', light='#f4e9a6', outline='#4a4120')
IRONP = ramp('#6d7279', shadow='#494d53', light='#9aa0a8', outline='#1d1f23', hi='#d6dbe0')


def _leaf_cluster(c, m, cx, cy, r, seed, n=7):
    rng = np.random.default_rng(seed)
    for _ in range(n):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, r * 0.6)
        c.paint(c.ellipse(cx + math.cos(a) * d, cy + math.sin(a) * d * 0.7, r * rng.uniform(0.45, 0.7), r * rng.uniform(0.35, 0.55)), m)


def bamboo():
    c = Canvas(72, 136)
    S = c.material(BAMBOO)
    S2 = c.material(BAMBOO_OLD)
    L = c.material(LEAF)
    L2 = c.material(LEAF_DARK)
    base = (36, 134)
    tops = [(10, 18), (22, 6), (36, 2), (50, 8), (62, 20), (28, 30), (46, 26)]
    for i, (tx, ty) in enumerate(tops):
        bx = base[0] + (i - 3) * 2
        c.paint(c.line([(bx, base[1]), (bx + (tx - bx) * 0.5, (base[1] + ty) * 0.55), (tx, ty)], 2 if i % 3 else 3), S if i % 4 else S2)
    rng = np.random.default_rng(12)
    # feathery drooping leaves: many short strokes hanging from the upper stalks
    for i, (tx, ty) in enumerate(tops):
        bx = base[0] + (i - 3) * 2
        for k in range(46):
            t = rng.uniform(0.0, 0.55)
            sx = tx + (bx - tx) * t + rng.uniform(-3, 3)
            sy = ty + (base[1] - ty) * t * 0.9 + rng.uniform(-2, 2)
            side = -1 if rng.random() < 0.5 else 1
            L_ = rng.uniform(4, 8)
            ex = sx + side * L_ * 0.8
            ey = sy + L_ * 0.55
            c.paint(c.line([(sx, sy), (ex, ey)], 1), L2 if (k + i) % 3 == 0 else L)
    for y in range(110, 134, 8):  # nodes on low stalks
        c.set_tone(c.rect(24, y, 48, y), 1)
    return c.render(outline=False)


def banana():
    c = Canvas(72, 88)
    St = c.material(BANANA_STEM)
    L = c.material(LEAF)
    Ly = c.material(LEAF_YEL)
    c.paint(c.poly([(32, 86), (40, 86), (38, 40), (34, 40)]), St)
    for i, ang in enumerate((-160, -120, -75, -40, -10, -200)):
        a = math.radians(ang)
        ex, ey = 36 + math.cos(a) * 32, 40 + math.sin(a) * 26
        mx, my = 36 + math.cos(a) * 16, 40 + math.sin(a) * 18 - 4
        nx, ny = -math.sin(a) * 6, math.cos(a) * 6
        pts = [(36, 40), (mx + nx, my + ny), (ex, ey), (mx - nx, my - ny)]
        c.paint(c.poly(pts), Ly if i == 5 else L)
        c.paint(c.line([(36, 40), (mx, my), (ex, ey)], 1), St)
    return c.render()


def areca():
    c = Canvas(48, 152)
    T = c.material(TRUNK_GREY)
    L = c.material(LEAF)
    L2 = c.material(LEAF_DARK)
    c.paint(c.poly([(22, 150), (27, 150), (26, 30), (23, 30)]), T)
    for y in range(40, 150, 7):
        c.set_tone(c.rect(23, y, 26, y), 1)
    for i, ang in enumerate(range(-180, 1, 30)):
        a = math.radians(ang)
        ex, ey = 24 + math.cos(a) * 22, 26 + math.sin(a) * 12 + 10
        c.paint(c.line([(24, 26), (24 + math.cos(a) * 12, 20 + math.sin(a) * 10), (ex, ey)], 3), L if i % 2 else L2)
    c.paint(c.ellipse(24, 30, 3, 4), c.material(LEAF_YEL))
    return c.render()


def banyan():
    c = Canvas(208, 184)
    T = c.material(TRUNK)
    L = c.material(LEAF_DARK)
    L2 = c.material(LEAF)
    c.paint(c.poly([(86, 182), (124, 182), (114, 120), (110, 80), (98, 80), (94, 120)]), T)
    for x in (70, 80, 132, 142, 60, 150):  # aerial roots
        c.paint(c.line([(x, 92), (x + (3 if x < 104 else -3), 180)], 1), T)
    rng = np.random.default_rng(4)
    for i in range(16):
        cx = rng.uniform(30, 178)
        cy = rng.uniform(26, 88) - abs(cx - 104) * 0.05
        c.paint(c.ellipse(cx, cy, rng.uniform(22, 34), rng.uniform(16, 24)), L)
    for i in range(10):
        cx = rng.uniform(40, 168)
        cy = rng.uniform(18, 66)
        c.paint(c.ellipse(cx, cy, rng.uniform(14, 22), rng.uniform(10, 15)), L2)
    return c.render(shadow_band=2)


def pine():
    c = Canvas(48, 104)
    T = c.material(TRUNK)
    P = c.material(PINE)
    c.paint(c.rect(22, 80, 25, 102), T)
    for i, y in enumerate((12, 28, 44, 60)):
        w = 8 + i * 5
        c.paint(c.poly([(24, y - 12), (24 + w, y + 18), (24 - w, y + 18)]), P)
    return c.render()


def bush(seed=1):
    c = Canvas(36, 26)
    L = c.material(LEAF_DARK)
    L2 = c.material(LEAF)
    _leaf_cluster(c, L, 18, 16, 14, seed, 6)
    _leaf_cluster(c, L2, 16, 12, 9, seed + 5, 4)
    return c.render()


def flowers():
    c = Canvas(18, 16)
    L = c.material(LEAF)
    F = c.material(FLOWER)
    R = c.material(RED)
    for x in (3, 8, 13):
        c.paint(c.line([(x, 15), (x + 1, 8)], 1), L)
    c.paint(c.ellipse(4, 7, 2, 2), F)
    c.paint(c.ellipse(9, 6, 2, 2), R)
    c.paint(c.ellipse(14, 8, 2, 2), F)
    return c.render()


def tuft():
    c = Canvas(16, 14)
    L = c.material(LEAF)
    L2 = c.material(LEAF_YEL)
    for i, x in enumerate((3, 5, 7, 9, 11, 13)):
        c.paint(c.line([(8, 13), (x, 2 + (i % 3) * 2)], 1), L if i % 2 else L2)
    return c.render(outline=False)


def rice():
    c = Canvas(10, 18)
    L = c.material(LEAF)
    L2 = c.material(LEAF_YEL)
    for i, x in enumerate((1, 3, 5, 7, 9)):
        c.paint(c.line([(5, 17), (x, 1 + (i % 2) * 3)], 1), L if i % 2 else L2)
    return c.render(outline=False)


def reeds():
    c = Canvas(18, 28)
    L = c.material(LEAF_YEL)
    T = c.material(TRUNK)
    for i, x in enumerate((3, 7, 10, 14)):
        c.paint(c.line([(9, 27), (x, 4 + i)], 1), L)
        c.paint(c.ellipse(x, 4 + i, 1, 2.5), T)
    return c.render()


def woodpile():
    c = Canvas(52, 34)
    W_ = c.material(WOODP)
    E = c.material(WOOD_END)
    for row in range(3):
        for k in range(5 - row):
            x = 8 + row * 4 + k * 8
            y = 28 - row * 7
            c.paint(c.ellipse(x, y, 4.2, 3.8), E)
            c.set_tone(c.ellipse(x, y, 1.3, 1.1), 1)
    return c.render()


def log():
    c = Canvas(16, 18)
    W_ = c.material(WOODP)
    E = c.material(WOOD_END)
    c.paint(c.rect(3, 5, 12, 16), W_)
    c.paint(c.ellipse(7.5, 5, 5, 2.2), E)
    return c.render(side_shade=0.3)


def log_split():
    c = Canvas(26, 16)
    W_ = c.material(WOODP)
    E = c.material(WOOD_END)
    c.paint(c.poly([(1, 14), (5, 4), (10, 4), (11, 14)]), W_)
    c.paint(c.poly([(14, 14), (16, 4), (21, 4), (25, 14)]), W_)
    c.paint(c.rect(9, 5, 10, 13), E)
    c.paint(c.rect(15, 5, 16, 13), E)
    return c.render()


def yoke():
    c = Canvas(56, 30)
    Wd = c.material(WOODP)
    B = c.material(TRUNK)
    c.paint(c.line([(2, 4), (54, 4)], 2), Wd)
    for x in (6, 50):
        c.paint(c.line([(x, 5), (x - 3, 14)], 1), B)
        c.paint(c.line([(x, 5), (x + 3, 14)], 1), B)
        c.paint(c.poly([(x - 6, 14), (x + 6, 14), (x + 5, 28), (x - 5, 28)]), Wd)
        c.set_tone(c.rect(x - 5, 18, x + 5, 18), 1)
    return c.render(side_shade=0.25)


def broom():
    c = Canvas(14, 36)
    Wd = c.material(WOODP)
    S = c.material(STRAWP)
    c.paint(c.line([(9, 1), (6, 22)], 1), Wd)
    c.paint(c.poly([(3, 22), (9, 21), (12, 34), (1, 34)]), S)
    return c.render()


def chum():
    c = Canvas(28, 30)
    C = c.material(CLAY)
    c.paint(c.ellipse(14, 17, 12, 11.5), C)
    c.paint(c.rect(7, 4, 21, 7), C)
    c.paint(c.ellipse(14, 4, 7, 1.6), c.material(ramp('#2a3a44', shadow='#1b262d', light='#3d5260')))
    return c.render(side_shade=0.3)


def pots():
    c = Canvas(26, 16)
    C = c.material(CLAY)
    c.paint(c.ellipse(7, 10, 6, 5.5), C)
    c.paint(c.ellipse(18, 11, 5, 4.5), C)
    c.paint(c.rect(4, 3, 10, 5), C)
    c.paint(c.rect(16, 5, 20, 7), C)
    return c.render(side_shade=0.3)


def strawstack():
    """A rick of rice straw built round a bamboo pole, as they stand in the yards after the harvest: a rounded
    stack, fullest at the shoulders, a small cap of straw tied at the top with the tip of the pole showing,
    strands hanging loose at the foot. The older straw underneath is a duller brown than the fresh top."""
    import numpy as np
    c = Canvas(52, 58)
    S = c.material(STRAWP)
    S2 = c.material(ramp('#b08a48', shadow='#86663a', light='#cba965', outline='#40301a'))
    Wd = c.material(BAMBOO_OLD)
    c.paint(c.line([(26, 0), (26, 9)], 1), Wd)                                      # the pole's tip
    rng0 = np.random.default_rng(11)
    body = c.ellipse(26, 33, 21.5, 19.5) | c.poly([(6, 42), (46, 42), (48, 54), (4, 54)])
    for k in range(9):                                                               # a ragged, uneven outline
        a = k / 9.0 * math.pi + 0.15
        bx, by = 26 + math.cos(a) * 21 * (1 if k % 2 else 0.96), 33 - math.sin(a) * 19
        body |= c.ellipse(bx, by, rng0.uniform(2.0, 3.2), rng0.uniform(1.6, 2.6))
    c.paint(body, S)
    c.set_tone(c.ellipse(20, 26, 9, 8) & body, 3)                                    # sunlit shoulder
    c.paint(c.poly([(19, 15), (26, 5), (33, 15), (29, 17), (23, 17)]), S2)           # the cap
    c.paint(c.line([(20, 15), (32, 15)], 1), Wd)                                     # tied
    rng = np.random.default_rng(5)
    for i in range(90):                                                              # strands, following the curve
        x = rng.uniform(7, 45)
        y = rng.uniform(14, 52)
        if not body[int(y), int(x)]:
            continue
        dx = (x - 26) * 0.09
        c.set_tone(c.line([(x, y), (x + dx, y + rng.uniform(2, 4.5))], 1) & body, 1 if rng.random() < 0.55 else 3)
    for i in range(12):                                                              # loose straws at the foot
        x = rng.uniform(4, 48)
        c.paint(c.line([(x, 53), (x + rng.uniform(-3, 3), 57)], 1), S)
    return c.render(volume=True, side_shade=0.18)


def lantern():
    """A red paper lantern, 16x26, 5 frames. 0-3 lit from inside: the flame breathes and leans, so the glow
    through the paper shifts (ribs dark against it, top and bottom caps of dark wood, a cord to hang it by).
    4: unlit, for the day."""
    import numpy as np
    from pix import Canvas, ramp, sheet
    frames = []
    PAPER = ramp('#c8402c', shadow='#8e2a22', light='#e5643a', outline='#4a1612', hi='#f4935a')
    GLOW = ramp('#ffb35a', shadow='#f08a3a', light='#ffd27a', outline='#c25a24', hi='#fff1b8')
    WOOD = ramp('#3d2a20', shadow='#281a14', light='#5a3e2c', outline='#140c08')
    for f in range(5):
        c = Canvas(16, 26)
        P = c.material(PAPER)
        G = c.material(GLOW, flat=True, outline=False)
        Wd = c.material(WOOD)
        c.paint(c.line([(8, 0), (8, 4)], 1), Wd)                       # the cord
        c.paint(c.ellipse(8, 14, 6.4, 8.2), P)                         # the paper body
        # the glow from the flame: an off-centre bloom that breathes and leans
        if f < 4:
            dx = [0.0, 0.6, -0.4, 0.3][f]
            r = [3.2, 3.7, 3.0, 3.5][f]
            c.paint(c.ellipse(8 + dx, 15, r * 0.9, r * 1.25) & c.ellipse(8, 14, 6.0, 7.8), G)
            c.set_tone(c.ellipse(8 + dx, 15.5, r * 0.45, r * 0.6) & c.ellipse(8, 14, 6.0, 7.8), 4)
        for x in (5, 8, 11):                                              # paper ribs
            for y in range(7, 22):
                if c.mat[y, x] == P or c.mat[y, x] == G:
                    c.set_tone(c.px(x, y), 1)
        c.paint(c.rect(4, 5, 12, 6), Wd)                               # caps
        c.paint(c.rect(5, 22, 11, 23), Wd)
        c.paint(c.line([(8, 24), (8, 25)], 1), Wd)                     # tassel
        frames.append(c.render())
    return sheet(frames, 5)


def leaves_pile(seed=3):
    c = Canvas(28, 14)
    D = c.material(DRYLEAF)
    L = c.material(LEAF_YEL)
    rng = np.random.default_rng(seed)
    for i in range(18):
        x, y = rng.uniform(4, 24), rng.uniform(6, 12)
        c.paint(c.ellipse(x, y, 2.2, 1.3), D if i % 4 else L)
    return c.render()


def leaf_particle():
    c = Canvas(5, 5)
    D = c.material(DRYLEAF)
    c.paint(c.ellipse(2.5, 2.5, 2.2, 1.4), D)
    return c.render(outline=False)


def tray():
    c = Canvas(40, 20)
    Wd = c.material(WOODP)
    B = c.material(BOWL)
    R = c.material(RICE)
    G = c.material(LEAF)
    c.paint(c.ellipse(20, 13, 19, 6), Wd)
    for x, y, food in ((9, 9, R), (19, 7, G), (30, 9, R), (20, 13, R)):
        c.paint(c.ellipse(x, y + 1, 4.5, 2.5), B)
        c.paint(c.ellipse(x, y, 3.5, 1.6), food)
    c.paint(c.line([(24, 15), (36, 12)], 1), c.material(TRUNK))
    return c.render()


def bowl_up():
    c = Canvas(12, 9)
    B = c.material(BOWL)
    c.paint(c.ellipse(6, 6, 5, 3.5), B)
    c.erase(c.rect(0, 7, 11, 8))
    c.paint(c.rect(4, 2, 7, 2), B)
    return c.render()


def bowls_ten():
    """Ten clean bowls set out upside down beside the dinner tray, in two staggered rows of five: one for each
    of the ten who once ate at this house (the old man lays them out every evening and never says for whom)."""
    c = Canvas(48, 17)
    B = c.material(BOWL)
    for (base, x0) in ((8, 5), (15, 9)):
        for i in range(5):
            x = x0 + 9 * i
            dome = c.ellipse(x, base, 3.6, 4.2) & c.rect(x - 4, base - 5, x + 4, base)
            c.paint(dome, B)
            c.paint(c.rect(x - 1, base - 5, x + 1, base - 5), B)              # the foot ring, turned up
    return c.render()


def sword_dull():
    c = Canvas(36, 10)
    I = c.material(IRONP)
    Wd = c.material(TRUNK)
    c.paint(c.rect(2, 4, 26, 5), I)
    c.paint(c.rect(26, 2, 27, 7), Wd)
    c.paint(c.rect(28, 4, 34, 5), Wd)
    c.set_tone(c.rect(8, 4, 20, 4), 4)
    return c.render()


def coinjar():
    c = Canvas(14, 16)
    C = c.material(CLAY)
    c.paint(c.ellipse(7, 10, 6, 5.5), C)
    c.paint(c.rect(4, 2, 10, 5), C)
    c.paint(c.ellipse(7, 2.5, 2.5, 1), c.material(ramp('#b39a4a', shadow='#8a7536', light='#d1b968')))
    return c.render(side_shade=0.3)


def fence():
    c = Canvas(32, 26)
    B = c.material(BAMBOO_OLD)
    for x in range(1, 32, 4):
        c.paint(c.rect(x, 3 + (x % 3), x + 1, 25), B)
    for y in (8, 18):
        c.paint(c.rect(0, y, 31, y + 1), B)
    return c.render()


def smoke():
    n = 24
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.hypot(xx - 11.5, yy - 11.5) / 11.5
    a = np.clip(1 - r, 0, 1) ** 1.6 * 255
    rgb = np.full((n, n, 3), 235, np.uint8)
    return Image.fromarray(np.concatenate([rgb, a[..., None].astype(np.uint8)], 2), 'RGBA')


def firefly():
    n = 8
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.hypot(xx - 3.5, yy - 3.5) / 3.5
    a = (np.clip(1 - r, 0, 1) ** 1.2 * 255).astype(np.uint8)
    rgb = np.zeros((n, n, 3), np.uint8)
    rgb[...] = (255, 238, 150)
    return Image.fromarray(np.concatenate([rgb, a[..., None]], 2), 'RGBA')


def shrine():
    c = Canvas(40, 44)
    Wd = c.material(TRUNK)
    R = c.material(ramp('#7a3a2c', shadow='#5e2a22', light='#a85a42', outline='#2a0f0b'))
    S = c.material(ramp('#8a877d', shadow='#67645c', light='#a5a297', outline='#2a2924'))
    c.paint(c.rect(10, 22, 30, 42), S)
    c.paint(c.rect(16, 28, 24, 38), c.material(ramp('#2a2420', shadow='#1a1512', light='#3a322c')))
    c.paint(c.poly([(4, 24), (36, 24), (30, 12), (10, 12)]), R)
    c.paint(c.poly([(6, 12), (34, 12), (20, 4)]), R)
    c.paint(c.rect(18, 31, 22, 33), c.material(RED))
    return c.render()


def leafclump(seed=1, palette=None):
    """One clump of foliage for 3D canopies: ragged leafy edge, rounded shading, a few lit leaf tips."""
    c = Canvas(30, 24)
    pal = palette or LEAF
    L = c.material(pal)
    rng = np.random.default_rng(seed)
    base = c.ellipse(15, 13, 12.5, 9.5)
    # ragged edge: small leaf blobs around the rim
    for _ in range(26):
        a = rng.uniform(0, math.tau)
        rr = rng.uniform(0.75, 1.05)
        x = 15 + math.cos(a) * 12.5 * rr
        y = 13 + math.sin(a) * 9.5 * rr
        base |= c.ellipse(x, y, rng.uniform(1.6, 2.8), rng.uniform(1.2, 2.2))
    for _ in range(10):  # gaps between leaves
        a = rng.uniform(0, math.tau)
        x = 15 + math.cos(a) * 11.5
        y = 13 + math.sin(a) * 8.6
        base &= ~c.ellipse(x, y, 1.0, 0.9)
    c.paint(base, L)
    # inner leaf shapes: lighter tips facing the light, dark pockets below
    for _ in range(14):
        x, y = rng.uniform(5, 25), rng.uniform(4, 19)
        if not base[int(y), int(x)]:
            continue
        up = y < 12
        c.set_tone(c.ellipse(x, y, rng.uniform(1.2, 2.2), rng.uniform(0.8, 1.4)) & base, 3 if up else 1)
    for _ in range(5):
        x, y = rng.uniform(6, 22), rng.uniform(4, 11)
        c.set_tone(c.px(x, y) & base, 4)
    return c.render(volume=True)


def chicken(variant='brown'):
    """Side view (facing left), 16x14 frames: 0-1 walk, 2-3 peck."""
    body = {'brown': ramp('#9a5c2e', shadow='#6e3f1e', light='#bf7c42', outline='#26140a'),
            'white': ramp('#e4ddcf', shadow='#b8ae9c', light='#f6f1e6', outline='#4a4238'),
            'black': ramp('#3a3436', shadow='#252022', light='#57504f', outline='#0c0a0b')}[variant]
    frames = []
    for f in range(4):
        c = Canvas(16, 14)
        B_ = c.material(body)
        R_ = c.material(RED)
        Y_ = c.material(ramp('#d8a640', shadow='#a87a28', light='#efc865', outline='#3e2a0c'))
        peck = f >= 2
        dip = 3 if f == 3 else (1 if f == 2 else 0)
        step = f % 2
        # legs
        c.paint(c.rect(7 + step, 10, 7 + step, 12), Y_)
        c.paint(c.rect(9 - step, 10, 9 - step, 12), Y_)
        # body + tail
        c.paint(c.ellipse(9, 7.5, 4.6, 3.4), B_)
        c.paint(c.poly([(12, 6), (15, 2), (15, 7), (13, 8)]), B_)
        # head (dips when pecking)
        hx, hy = 5, 4 + dip
        c.paint(c.ellipse(hx + 1, hy + 2, 2.0, 2.2), B_)
        c.paint(c.ellipse(hx, hy, 2.2, 2.0), B_)
        c.paint(c.rect(hx - 1, hy - 3, hx + 1, hy - 2), R_)       # comb
        c.paint(c.rect(hx - 3, hy, hx - 2, hy), Y_)               # beak
        c.paint(c.px(hx - 1, hy + 1), R_)                          # wattle
        c.paint(c.ellipse(10, 7, 2.6, 1.6), B_, tone=1)           # wing
        im = c.render(volume=True).copy()
        px = im.load()
        px[hx, hy - 1] = (20, 14, 16, 255)                         # eye
        frames.append(im)
    from pix import sheet
    return sheet(frames, 4)


def butterfly():
    frames = []
    for f, (col, sh) in enumerate([('#f0e6b8', '#c9b878'), ('#f0e6b8', '#c9b878'), ('#e9a24a', '#b8742c'), ('#e9a24a', '#b8742c')]):
        c = Canvas(8, 6)
        W_ = c.material(ramp(col, shadow=sh, outline='#3a2a14'))
        Bd = c.material(ramp('#2a2420', outline='#0c0a08'))
        if f % 2 == 0:
            c.paint(c.ellipse(2, 2.5, 1.8, 1.8) | c.ellipse(6, 2.5, 1.8, 1.8), W_)
        else:
            c.paint(c.rect(2, 1, 3, 3) | c.rect(5, 1, 6, 3), W_)
        c.paint(c.rect(4, 1, 4, 4), Bd)
        frames.append(c.render(outline=False))
    from pix import sheet
    return sheet(frames, 4)


def bird():
    frames = []
    for f in range(2):
        c = Canvas(11, 6)
        K = c.material(ramp('#2b2629', outline='#2b2629'), flat=True)
        if f == 0:
            c.paint(c.line([(0, 1), (3, 3), (5, 3), (7, 3), (10, 1)], 1), K)
        else:
            c.paint(c.line([(0, 4), (3, 3), (5, 3), (7, 3), (10, 4)], 1), K)
        c.paint(c.rect(4, 3, 6, 3), K)
        frames.append(c.render(outline=False))
    from pix import sheet
    return sheet(frames, 2)


def cloth(base, stripe):
    """Hanging laundry: 16x22 with a hem, stripes and a few folds."""
    c = Canvas(16, 22)
    M_ = c.material(ramp(base))
    S_ = c.material(ramp(stripe), flat=True)
    c.paint(c.rect(1, 1, 14, 20), M_)
    for y in (6, 7, 15, 16):
        c.paint(c.rect(1, y, 14, y), S_)
    for x in (4, 9, 12):
        c.set_tone(c.rect(x, 2, x, 19), 1)
    c.paint(c.rect(1, 0, 14, 0), M_, tone=1)
    return c.render(volume=True)


def axe_block():
    """The axe left standing in the chopping block: the head bitten into the wood, the handle up at a slant."""
    c = Canvas(20, 26)
    Wd = c.material(WOODP)
    Fe = c.material(IRONP)
    c.paint(c.line([(6, 2), (11, 18)], 2), Wd)                                 # the handle
    c.paint(c.poly([(8, 16), (16, 14), (17, 20), (10, 21)]), Fe)               # the head, half sunk
    c.set_tone(c.line([(15, 14), (17, 20)], 1), 4)                             # the bit catches the light
    return c.render(side_shade=0.2)


def well_bucket():
    """A wooden bucket with its rope bail. The rope up to the pulley on the beam is a 3D line in the scene."""
    c = Canvas(14, 16)
    R = c.material(ramp('#8a7448', shadow='#5e4e30', light='#a8915e', outline='#2a2214'))
    Wd = c.material(WOODP)
    c.paint(c.line([(3, 7), (7, 2), (11, 7)], 1), R)                          # the bail
    c.paint(c.rect(6, 0, 8, 2), R)                                           # the knot where the rope ties on
    c.paint(c.poly([(2, 6), (12, 6), (11, 15), (3, 15)]), Wd)
    c.set_tone(c.rect(3, 6, 11, 6), 0)                                       # the dark inside of the rim
    c.set_tone(c.rect(2, 9, 12, 9) | c.rect(3, 13, 11, 13), 1)               # hoops
    return c.render(side_shade=0.25)


def marker():
    """Where to go next: a gold arrow pointing down, dark-edged so it reads on any ground."""
    c = Canvas(14, 16)
    G = c.material(ramp('#f2c14e', shadow='#c98f2a', light='#ffe08a', outline='#3a2508', hi='#fff4c4'))
    c.paint(c.poly([(1, 6), (13, 6), (7, 15)]), G)
    c.paint(c.rect(4, 0, 9, 6), G)
    return c.render(volume=True)


ALL = {
    'bamboo': bamboo, 'banana': banana, 'areca': areca, 'banyan': banyan, 'pine': pine,
    'bush': bush, 'bush2': lambda: bush(9), 'flowers': flowers, 'tuft': tuft, 'rice': rice, 'reeds': reeds,
    'woodpile': woodpile, 'log': log, 'log_split': log_split, 'yoke': yoke, 'broom': broom, 'chum': chum,
    'pots': pots, 'strawstack': strawstack, 'lantern': lantern, 'leaves_pile': leaves_pile,
    'leaf': leaf_particle, 'tray': tray, 'bowl_up': bowl_up, 'bowls_ten': bowls_ten, 'sword_dull': sword_dull, 'coinjar': coinjar,
    'fence': fence, 'smoke': smoke, 'firefly': firefly, 'shrine': shrine,
    'axe_block': axe_block, 'well_bucket': well_bucket, 'marker': marker,
    'leafclump': leafclump, 'leafclump2': lambda: leafclump(7), 'leafclump_dark': lambda: leafclump(3, LEAF_DARK),
    'leafclump_yel': lambda: leafclump(11, LEAF_YEL),
    'chicken_brown': chicken, 'chicken_white': lambda: chicken('white'), 'chicken_black': lambda: chicken('black'),
    'butterfly': butterfly, 'bird': bird,
    'cloth_a': lambda: cloth('#3d4f78', '#d9d2c0'), 'cloth_b': lambda: cloth('#8c3a2e', '#d6a446'),
    'cloth_c': lambda: cloth('#d6cbb2', '#7a5a3a'),
    'cloth_w': lambda: cloth('#e8e4da', '#c6c1b4'),
}
