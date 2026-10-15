"""Bạch Sơn, Part C: the things looked at closely (docs/N_bach_son.md 8.3), drawn to the same standard as the
Thử Tro hand (tools/art/bs_palm.py) and the character sprites.

  assets/ui/so_cot.png, so_sac.png, so_ban.png, so_pk21.png, so_pk395.png
      the Sổ Tro, open on the clerk's table: a spread of real, readable entries in the Ty's hand, one image
      per thing the protagonist finds (the empty black column, the decrees, the sale list, the first volume,
      the PK 395 entry). Drawn at the card's own size (520x330), text in Noto Serif like all paper UI.
  assets/tex/chen_ran.png   Bà Mẫn's crazed cup on the Y Viện table, ash left in the crackle (130x82, shown 4x)
  assets/tex/tranh_tho.png  the hanging scroll in the Đền Thầy (72x110, shown 3x; also on the temple wall)
  assets/ui/nong_close.png  bà Lành's tray of broken ash tags (128x82, shown 4x)
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pix import Canvas, ramp, hexc
from env import pnoise

HERE = os.path.dirname(__file__)
ROOT = os.path.join(HERE, '..', '..', 'assets')
FONT = os.path.join(ROOT, 'fonts', 'NotoSerif.ttf')

INK = (46, 36, 34)
INK_OLD = (122, 98, 76)
ASH = (150, 146, 140)
CINNABAR = (168, 44, 36)

NAMES = ["Lý Thoa", "Đào Mộc", "Hà Lũy", "Phan Nhẫn", "Vũ Liên", "Tô Bình", "Kha Tứ", "Lục Hòa", "Mạc Quyên",
         "Ninh Đạt", "Âu Cần", "Triệu Nga", "Quách Sinh", "Lâm Huệ", "Đinh Tùng", "Mai Thiện", "Giáp Lộc",
         "Từ Hạnh", "Viên Khang", "Cù Mỹ", "Bạch Dung", "Tôn Hiếu", "Diêm Lựu", "Lò Nhân", "Kiều Tâm",
         "Hồ Lạc", "Thái Mận", "Nghiêm Sử", "Văn Thắm", "La Khôi"]
JOBS = ["thợ vôi", "thợ muối", "giặt liệm", "dọn cống", "thợ gốm", "gánh nước", "thợ đá", "lò sứ"]


def font(size):
    return ImageFont.truetype(FONT, size)


# ================================================================================ the Sổ Tro, open
W, H = 520, 330
L0, R0, PW = 16, 264, 240     # left page x, right page x, page width
TOP, BOT = 16, 314


def spread(seed, age=0.0):
    """An open ledger on its cloth cover: two pages, darker toward the gutter, the stack of leaves at the edges.
    `age` yellows the paper and spots it."""
    rng = np.random.default_rng(seed)
    out = np.zeros((H, W, 4), float)
    # the cover
    cover = np.zeros((H, W), bool)
    cover[8:H - 6, 6:W - 6] = True
    out[cover, :3] = (62, 52, 50)
    out[cover, 3] = 255
    # the stack of leaves under each page
    for k in range(4):
        c = 214 - k * 10
        out[TOP + 2 + k:BOT + 2 + k, L0 - 2 - k:L0 + PW, :3] = (c, c - 8, c - 26)
        out[TOP + 2 + k:BOT + 2 + k, R0:R0 + PW + 2 + k, :3] = (c, c - 8, c - 26)
    # the paper
    n = pnoise(256, 16, seed)
    n = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR)) / 255.0
    base = np.array([236, 228, 207], float) * (1 - age) + np.array([226, 206, 166], float) * age
    yy, xx = np.mgrid[0:H, 0:W]
    paper = np.zeros((H, W), bool)
    paper[TOP:BOT, L0:L0 + PW] = True
    paper[TOP:BOT, R0:R0 + PW] = True
    col = base[None, None, :] * (0.95 + 0.07 * n)[..., None]
    gut = 1 - 0.28 * np.exp(-((xx - (L0 + PW + R0) / 2) / 16.0) ** 2)
    edge = 1 - 0.06 * np.exp(-np.minimum(np.abs(xx - L0), np.abs(xx - (R0 + PW))) / 6.0)
    col *= (gut * edge)[..., None]
    out[paper, :3] = col[paper]
    out[paper, 3] = 255
    im = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGBA')
    d = ImageDraw.Draw(im)
    if age > 0:
        for _ in range(int(40 * age)):     # foxing
            x, y = rng.integers(L0, R0 + PW), rng.integers(TOP, BOT)
            r = rng.uniform(0.8, 2.6)
            d.ellipse([x - r, y - r, x + r, y + r], fill=(176, 140, 96, int(rng.uniform(40, 110))))
    return im, d


def write(d, xy, s, size=13, col=INK, rng=None, alpha=235):
    """Handwriting, near enough: word by word, each a pixel up or down, the ink a little uneven."""
    f = font(size)
    x, y = xy
    for w in s.split(' '):
        jy = int(rng.integers(-1, 2)) if rng is not None and rng.random() < 0.3 else 0
        a = int(alpha * (rng.uniform(0.82, 1.0) if rng is not None else 1.0))
        d.text((x, y + jy), w, font=f, fill=col + (a,))
        x += d.textlength(w + ' ', font=f)
    return x


def tick(d, x, y, col=INK):
    d.line([(x, y + 5), (x + 3, y + 8), (x + 10, y)], fill=col + (230,), width=2)


def ash_strike(im, x0, x1, y, seed):
    """A line struck through with ash, not ink: smeared, grey, uneven."""
    rng = np.random.default_rng(seed)
    lay = Image.new('RGBA', im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    pts = [(x, y + math.sin(x * 0.08 + seed) * 1.2) for x in range(int(x0), int(x1), 6)]
    d.line(pts, fill=ASH + (190,), width=4)
    for _ in range(int((x1 - x0) / 5)):
        x = rng.uniform(x0, x1)
        d.ellipse([x - 1.5, y - 3 + rng.uniform(-1, 1), x + 1.5, y + 3], fill=ASH + (int(rng.uniform(60, 140)),))
    lay = lay.filter(ImageFilter.GaussianBlur(0.6))
    im.alpha_composite(lay)


def seal(im, cx, cy, size, lines, col=CINNABAR, round_=False, seed=1):
    """A cinnabar seal pressed on the page: rough edged, the ink uneven, the characters left in paper."""
    rng = np.random.default_rng(seed)
    S = 3
    w = size * S
    lay = Image.new('RGBA', (w, w), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    if round_:
        d.ellipse([2, 2, w - 3, w - 3], fill=col + (235,))
    else:
        d.rectangle([2, 2, w - 3, w - 3], fill=col + (235,))
    longest = max(len(t) for t in lines)
    f = font(int(size * S * min(0.34, (1.15 if round_ else 1.5) / max(longest, 1))))
    total = len(lines)
    for i, t in enumerate(lines):
        tw = d.textlength(t, font=f)
        y = w * (0.5 + (i - (total - 1) / 2) * 0.38) - f.size * 0.62
        d.text(((w - tw) / 2, y), t, font=f, fill=(0, 0, 0, 0))
    a = np.array(lay).astype(float)
    holes = rng.random(a.shape[:2]) < 0.07
    a[holes, 3] *= 0.35
    lay = Image.fromarray(a.astype(np.uint8), 'RGBA').resize((size, size), Image.LANCZOS)
    lay = lay.rotate(rng.uniform(-6, 6), resample=Image.BICUBIC, expand=False)
    im.alpha_composite(lay, (int(cx - size / 2), int(cy - size / 2)))


def ledger_page(im, d, x0, title, rows, rng, col=INK, cols=("Trắng", "Xám", "Đen"), seed=0):
    """A ruled page: a heading, a row of column heads, then entries. rows: [name, job, mark(0 trắng 1 xám
    2 đen or None), struck, note]."""
    write(d, (x0 + 10, TOP + 6), title, 12, col, rng)
    hy = TOP + 26
    cx = [x0 + 140, x0 + 176, x0 + 210]
    for i, c in enumerate(cols):
        d.text((cx[i] - 3, hy + 1), c, font=font(10), fill=col + (220,))
    d.line([(x0 + 8, hy + 17), (x0 + PW - 8, hy + 17)], fill=col + (200,), width=1)
    for x in [cx[0] - 6, cx[1] - 6, cx[2] - 6]:
        d.line([(x, hy), (x, BOT - 8)], fill=col + (90,), width=1)
    y = hy + 22
    for k, (name, job, mark, struck, note) in enumerate(rows):
        end = write(d, (x0 + 10, y), name + ("," if job else ""), 12, col, rng)
        if job:
            write(d, (end, y), job, 10, col, rng, 200)
        if mark is not None:
            tick(d, cx[mark] + 4, y + 2, col)
        if note:
            write(d, (x0 + 22, y + 15), note, 10, col, rng, 210)
        if struck:
            ash_strike(im, x0 + 8, x0 + 132, y + 8, seed + k)
        y += 19 + (14 if note else 0)


def _rows(rng, n, xam_every=4, struck_xam=True):
    rows = []
    names = list(rng.permutation(NAMES))
    for i in range(n):
        xam = (i % xam_every == xam_every - 1)
        rows.append([names[i % len(names)], JOBS[int(rng.integers(len(JOBS)))], 1 if xam else 0, xam and struck_xam, ""])
    return rows


def so_cot():
    rng = np.random.default_rng(11)
    im, d = spread(11)
    ledger_page(im, d, L0, "Tầng Rửa, tập PK 409", _rows(rng, 13, 4), rng, seed=10)
    ledger_page(im, d, R0, "Tầng Rửa, tập PK 410", _rows(rng, 13, 3), rng, seed=40)
    return im


def _decree(im, d, x0, head, body, year, rng, seed):
    write(d, (x0 + 98, TOP + 12), head, 20, INK, rng)
    f = font(13)
    y = TOP + 50
    for para in body:
        line = ""
        for w in para.split(' '):
            t = (line + " " + w).strip()
            if d.textlength(t, font=f) > PW - 36:
                write(d, (x0 + 18, y), line, 13, INK, rng)
                y += 21
                line = w
            else:
                line = t
        write(d, (x0 + 18, y), line, 13, INK, rng)
        y += 27
    write(d, (x0 + 18, y + 4), year, 12, INK, rng)
    write(d, (x0 + 18, BOT - 88), "Chánh Ty Ngọc Khiết soạn.", 13, INK, rng)
    seal(im, x0 + PW - 46, BOT - 38, 48, ["BẠCH", "ĐIỆN"], seed=seed)


def so_sac():
    rng = np.random.default_rng(12)
    im, d = spread(12)
    _decree(im, d, L0, "SẮC", ["Thầy thuốc nào đã chữa cho người nhiễm, từ nay coi như nhiễm.",
                               "Khám sư các cổng thử lại ngay, không đợi năm."], "Năm PK 409.", rng, 3)
    _decree(im, d, R0, "SẮC", ["Họ hàng của người đã bị đuổi phải ra khỏi cổng trước Lễ Quét Vôi.",
                               "Không xét từng người."], "Năm PK 412.", rng, 5)
    return im


def so_ban():
    rng = np.random.default_rng(13)
    im, d = spread(13)
    write(d, (L0 + 14, TOP + 8), "Giao, mùa thu", 13, INK, rng)
    names = list(rng.permutation(NAMES))
    y = TOP + 36
    f = font(12)
    for i in range(12):
        nm = names[i]
        write(d, (L0 + 16, y), nm, 12, INK, rng)
        num = str(int(rng.integers(6, 15)))
        x1 = L0 + PW - 30
        xs = L0 + 20 + d.textlength(nm, font=f)
        x = xs + 6
        while x < x1 - 8:
            d.point((x, y + 11), fill=INK + (150,))
            x += 4
        write(d, (x1, y), num, 12, INK, rng)
        y += 21
    names2 = names[12:]
    y = TOP + 36
    for i in range(8):
        nm = names2[i % len(names2)]
        write(d, (R0 + 16, y), nm, 12, INK, rng)
        num = str(int(rng.integers(6, 15)))
        x1 = R0 + PW - 30
        x = R0 + 22 + d.textlength(nm, font=f)
        while x < x1 - 8:
            d.point((x, y + 11), fill=INK + (150,))
            x += 4
        write(d, (x1, y), num, 12, INK, rng)
        y += 21
    write(d, (R0 + 16, y + 8), "Cộng, đủ số. Đã nhận.", 12, INK, rng)
    seal(im, R0 + PW - 56, BOT - 46, 62, ["VĂN LỤC", "VẠN THƯ"], col=(120, 30, 34), round_=True, seed=9)
    return im


def so_pk21():
    rng = np.random.default_rng(14)
    im, d = spread(14, age=0.75)
    rows = []
    names = list(rng.permutation(NAMES))
    marks = [1, 1, 2, 1, 0, 1, 2, 1, 1, 0]
    notes = {0: "giữ lại ở Nhà Rửa.", 1: "giữ lại. Bà đã rửa.", 3: "giữ lại. Bà đã rửa.", 5: "giữ lại ở Nhà Rửa.",
             7: "giữ lại. Bà đã rửa."}
    for i, m in enumerate(marks[:7]):
        rows.append([names[i], "", m, m == 2, notes.get(i, "")])
    ledger_page(im, d, L0, "Tập đầu, năm PK 21", rows, rng, col=INK_OLD, seed=70)
    # the rule, written at the head of the right page in the same faded hand
    write(d, (R0 + 14, TOP + 10), "Lệ của Ty Khám:", 13, INK_OLD, rng)
    y = TOP + 36
    for t in ["Người bị Nghiệt chạm không vào.", "Người bị Nghiệt đuổi không vào.", "Đêm không mở cổng.",
              "Xám thì giữ lại ở Nhà Rửa, đợi Bà."]:
        write(d, (R0 + 20, y), t, 13, INK_OLD, rng)
        y += 24
    rows2 = []
    for i, m in enumerate(marks[7:] + [1, 0, 1]):
        rows2.append([names[10 + i], "", m, False, "giữ lại. Bà đã rửa." if m == 1 else ""])
    y += 8
    for name, _, m, _, note in rows2:
        write(d, (R0 + 20, y), name + ", " + ["trắng", "xám", "đen"][m] + ".", 12, INK_OLD, rng)
        if note:
            write(d, (R0 + 32, y + 15), note, 10, INK_OLD, rng, 210)
        y += 19 + (14 if note else 0)
    return im


def so_pk395():
    rng = np.random.default_rng(15)
    im, d = spread(15, age=0.25)
    rows = _rows(rng, 4, 5)
    ledger_page(im, d, L0, "Tầng Rửa, tập PK 395", rows, rng, seed=80)
    # the house put out under the Luật Cả Nhà: five lines, the name of the house under a thumb of ash
    y = TOP + 48 + 4 * 19 + 6
    x = write(d, (L0 + 10, y), "Nhà", 12, INK, rng)
    write(d, (x + 52, y), "Luật Cả Nhà. Năm người.", 12, INK, rng)
    write(d, (L0 + 150, y + 15), "không thử", 9, INK, rng, 190)
    blot = Image.new('RGBA', im.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(blot)
    for _ in range(26):
        bx, by = x + rng.uniform(2, 44), y + rng.uniform(2, 14)
        r = rng.uniform(3, 7)
        bd.ellipse([bx - r, by - r * 0.7, bx + r, by + r * 0.7], fill=(118, 112, 106, int(rng.uniform(90, 170))))
    im.alpha_composite(blot.filter(ImageFilter.GaussianBlur(1.2)))
    y += 22
    for k, (who, job) in enumerate([("Chồng", "thợ muối"), ("Vợ", "giặt liệm"), ("Mẹ chồng", ""),
                                    ("Con trai", "mười hai tuổi"), ("Trẻ nhỏ, chưa tên.", "")]):
        e = write(d, (L0 + 22, y), who + ("," if job else ""), 12, INK, rng)
        if job:
            write(d, (e, y), job, 11, INK, rng, 200)
        ash_strike(im, L0 + 18, L0 + 132, y + 8, 300 + k)   # struck out with no mark in any column
        y += 19
    ledger_page(im, d, R0, "", _rows(rng, 12, 4), rng, seed=90)
    return im


# ================================================================================ pixel pieces
WOOD = ramp('#7a5a3e', shadow='#5c4230', light='#957152', outline='#2e2018')
PORC = ramp('#e9edf0', shadow='#c3cbd2', light='#ffffff', outline='#4e5862', hi='#ffffff')
COBALT = ramp('#34508f', shadow='#243866', light='#4c6cb0', outline='#101a33')
ASHR = ramp('#a39f98', shadow='#8a867f', light='#bab6ae', outline='#5e5a55')


def _voronoi_edges(mask, n_pts, seed, w=0.9):
    h, wd = mask.shape
    rng = np.random.default_rng(seed)
    ys, xs = np.where(mask)
    pts = np.stack([rng.uniform(xs.min(), xs.max(), n_pts), rng.uniform(ys.min(), ys.max(), n_pts)], 1)
    yy, xx = np.mgrid[0:h, 0:wd]
    d1 = np.full((h, wd), 1e9)
    d2 = np.full((h, wd), 1e9)
    for px, py in pts:
        d = np.hypot(xx - px, (yy - py) * 1.3)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        d1 = np.where(closer, d, d1)
    return mask & ((d2 - d1) < w)


def chen_ran():
    """The cup on the Y Viện table, after the ash and the water: white glaze, cobalt rim, the crackle dark."""
    Wd, Hd = 130, 82
    c = Canvas(Wd, Hd)
    wood = c.material(WOOD)
    c.paint(c.rect(0, 60, Wd - 1, Hd - 1), wood)
    shadow_m = c.material(ramp('#634833', shadow='#563e2c', light='#6c4f38', outline='#2e2018'), flat=True, outline=False)
    c.paint(c.ellipse(68, 63, 30, 3.5), shadow_m)
    body = c.material(PORC)
    pts = []
    for i in range(21):   # the bowl's side: a curve from the rim to the foot
        t = i / 20
        pts.append((28 + 18 * t ** 1.6, 20 + 38 * t))
    rpts = [(130 - x, y) for x, y in pts[::-1]]
    bowl = c.poly(pts + rpts) | c.ellipse(65, 20, 37, 7)
    c.paint(bowl, body)
    foot = c.material(PORC)
    c.paint(c.rect(50, 57, 80, 62), foot)
    inner = c.material(ramp('#cfd5da', shadow='#b5bdc4', light='#dde2e6', outline='#4e5862'), flat=True)
    c.paint(c.ellipse(65, 20, 34, 5.6), inner)
    rim = c.material(COBALT, flat=True, outline=False)
    band = c.ellipse(65, 20, 37, 7) & ~c.ellipse(65, 20, 34.5, 5.8)
    c.paint(band & (np.mgrid[0:Hd, 0:Wd][0] >= 20), rim)
    # a little ash left on the table, and water spilt
    ash = c.material(ASHR)
    c.paint(c.ellipse(108, 66, 9, 3) | c.ellipse(112, 64, 4, 2), ash)
    im = np.array(c.render())
    # the crackle on the outer face, filled with ash: thin dark lines
    face = bowl & ~c.ellipse(65, 20, 37, 7)
    cr = _voronoi_edges(face, 46, 5, 0.6)
    im[cr, :3] = (78, 80, 86)
    cr2 = _voronoi_edges(c.ellipse(65, 20, 33, 5.2), 9, 8, 0.7)
    im[cr2, :3] = (120, 126, 132)
    # a pale reflection on the glaze
    hl = c.line([(36, 26), (40, 38)], 1) & face
    im[hl, :3] = (255, 255, 255)
    for x, y in [(96, 70), (90, 73), (101, 75)]:
        im[y, x, :3] = (120, 140, 150)
    return Image.fromarray(im, 'RGBA')


def tranh_tho():
    """The hanging scroll in the Đền Thầy (K 6, N 3.5): the teacher's stroke parting the clean from the unclean.
    Ink on silk: the teacher in white at the top, the stroke just made, the blade down; from its tip a white line
    runs straight down to the bottom edge of the silk and stops nowhere. People in white stand on the left,
    upright, hands together; people in ink bow and kneel on the right."""
    Wd, Hd = 72, 110
    rng = np.random.default_rng(21)
    c = Canvas(Wd, Hd)
    roller = c.material(ramp('#4a3528', shadow='#33241b', light='#634837', outline='#1a120d'))
    mount = c.material(ramp('#5d6b82', shadow='#4a566a', light='#71809a', outline='#222833'), flat=True)
    silk = c.material(ramp('#e2d6bc', shadow='#d2c4a6', light='#ece2cc', outline='#6a5c48'), flat=True)
    c.paint(c.rect(2, 4, Wd - 3, Hd - 7), mount)
    c.paint(c.rect(6, 13, Wd - 7, Hd - 15), silk)
    c.paint(c.rect(0, 0, Wd - 1, 3), roller)
    c.paint(c.rect(0, Hd - 6, Wd - 1, Hd - 2), roller)
    c.paint(c.rect(34, 0, 37, 1), roller)
    im = np.array(c.render()).astype(int)
    yy, xx = np.mgrid[0:Hd, 0:Wd]
    inside = (xx >= 6) & (xx <= Wd - 7) & (yy >= 13) & (yy <= Hd - 15)
    # silk grain, and two washes of ink mountains far behind
    g = pnoise(128, 32, 4)[:Hd, :Wd]
    im[inside, :3] = np.clip(im[inside, :3] + ((g[inside] - 0.5) * 10)[:, None], 0, 255)
    for base, amp, fq, ph, kk in [(22, 5, 0.21, 0.0, 0.1), (29, 4, 0.17, 2.0, 0.13)]:
        ridge = base + amp * np.sin(xx * fq + ph) + 2 * np.sin(xx * 0.53 + ph)
        wash = inside & (yy > ridge) & (yy < ridge + 7)
        im[wash, :3] = (im[wash, :3] * (1 - kk) + np.array([130, 126, 122]) * kk).astype(int)
    # the figures, painted on their own sheet so each gets its ink outline
    f = Canvas(Wd, Hd)
    WHITE = ramp('#f2efe6', shadow='#d6d0c2', light='#ffffff', outline='#2c2729')
    INKF = ramp('#3b3637', shadow='#2b2627', light='#585253', outline='#151213')
    robe = f.material(WHITE)
    head = f.material(WHITE)
    hair = f.material(INKF, flat=True)
    # the teacher: a long robe in a wide stance, the stroke just finished, both hands on the hilt low in front
    f.paint(f.poly([(33, 36), (39, 36), (41, 46), (46, 58), (40, 59), (36, 50), (32, 59), (26, 58), (31, 46)]), robe)
    f.paint(f.poly([(38, 38), (42, 42), (40, 48), (37, 45)]), f.material(WHITE))   # the sleeves, forward and down
    f.paint(f.ellipse(36, 32.5, 2.8, 3.2), head)
    f.paint(f.ellipse(36.5, 29.5, 2.2, 1.3) | f.rect(36, 27, 37, 28), hair)       # hair and topknot
    blade = f.material(ramp('#9aa0a6', shadow='#7b8187', light='#c9ced2', outline='#2c2729'), flat=True, outline=False)
    f.paint(f.line([(40, 47), (37, 62)], 1), blade)
    # the clean: upright, robes to the ground, hands together, all facing the teacher
    for (x, y) in [(11, 66), (19, 64), (27, 67), (12, 81), (20, 79), (28, 82)]:
        f.paint(f.poly([(x - 1.5, y), (x + 1.5, y), (x + 2.5, y + 10), (x - 2.5, y + 10)]), f.material(WHITE))
        f.paint(f.ellipse(x + 0.3, y - 2, 1.7, 1.9), f.material(WHITE))
        f.paint(f.rect(x - 1, y - 4, x + 1, y - 4), hair)
    # the unclean: in ink, bent, kneeling, smaller toward the edge
    for (x, y, sc, kneel) in [(45, 67, 1.0, False), (54, 70, 0.9, True), (62, 65, 0.85, False),
                              (47, 82, 0.95, True), (56, 84, 0.85, True), (63, 79, 0.75, False)]:
        m = f.material(INKF)
        h = 9 * sc if not kneel else 6 * sc
        f.paint(f.poly([(x - 1, y), (x + 2, y + 1), (x + 3, y + h), (x - 3, y + h)]), m)
        f.paint(f.ellipse(x - 1.2, y + 0.5, 1.6 * sc + 0.2, 1.6 * sc + 0.2), m)   # the head bowed forward
    fim = np.array(f.render())
    on = (fim[:, :, 3] > 0) & inside
    im[on] = fim[on]
    # the cut: from the blade's tip straight down through the ground to the edge of the silk
    cut = c.line([(37, 62), (37, Hd - 15)], 2)
    im[cut & inside, :3] = (252, 250, 244)
    im[c.line([(36, 63), (36, Hd - 15)], 1) & inside, :3] = (232, 228, 216)
    # a column of writing at the top right, and the painter's seal under it
    for kk in range(7):
        if rng.random() < 0.85:
            im[16 + kk * 4:18 + kk * 4, 58:61, :3] = (52, 46, 46)
    im[46:50, 57:61, :3] = (168, 44, 36)
    im[47:49, 58:60, :3] = (214, 120, 100)
    return Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), 'RGBA')


def nong_close():
    """Bà Lành's winnowing tray, seen from above at a slant: woven bamboo, and on it the ash tags of the camp,
    broken, one tag a person, laid in rows. A tag is a finger of white porcelain with a hole for the cord it
    hung on and a notch for every year it was tested. Five at the front are tied on one string: a house."""
    Wd, Hd = 128, 82
    rng = np.random.default_rng(31)
    c = Canvas(Wd, Hd)
    shadow_m = c.material(ramp('#6a5a44', shadow='#5c4e3a', light='#76664e', outline='#3a2f22'), flat=True, outline=False)
    c.paint(c.ellipse(66, 46, 60, 34), shadow_m)
    BAM = ramp('#b4925e', shadow='#97784a', light='#c8a873', outline='#4a3720')
    rim = c.material(BAM)
    weave = c.material(ramp('#c4a46e', shadow='#a98a58', light='#d4b783', outline='#4a3720'), flat=True)
    tray = c.ellipse(64, 42, 60, 34)
    c.paint(tray, rim)
    c.paint(c.ellipse(64, 42, 55, 30.5), weave)
    im = np.array(c.render()).astype(int)
    yy, xx = np.mgrid[0:Hd, 0:Wd]
    inner = c.ellipse(64, 42, 55, 30.5)
    r = np.hypot((xx - 64) / 55.0, (yy - 42) / 30.5)
    a = np.arctan2((yy - 42) / 30.5, (xx - 64) / 55.0)
    ring = (np.floor(r * 18) % 2 == 0)
    spoke = (np.floor((a + math.pi) / (2 * math.pi) * 64) % 2 == 0)
    im[inner & (ring ^ spoke), :3] = np.array(hexc('#b3935f'))
    im[inner & (np.floor(r * 18 * 4) % 4 == 0), :3] = np.array(hexc('#9f8052'))
    sc = Canvas(Wd, Hd)
    holes, notches = [], []

    def tag(x, y, broken):
        m = sc.material(PORC)
        hgt = 9 if not broken else int(rng.integers(5, 8))
        sc.paint(sc.rect(x, y, x + 3, y + hgt - 1), m)
        if broken:    # the break, ragged
            sc.erase(sc.px(x + int(rng.integers(0, 4)), y + hgt - 1))
        holes.append((x + 1, y + 1))
        for kk in range(int(rng.integers(1, 4))):
            notches.append((x + 1 + (kk % 2), y + 4 + kk))
    for row in range(2):
        for col in range(9):
            if rng.random() < 0.15:
                continue
            tag(22 + col * 9 + int(rng.integers(-1, 2)) + row * 3, 19 + row * 14 + int(rng.integers(-1, 2)), rng.random() < 0.5)
    family = [(46 + kk * 6, 56) for kk in range(5)]
    for x, y in family:
        tag(x, y, False)
    sim = np.array(sc.render())
    on = sim[:, :, 3] > 0
    im[on] = sim[on]
    for x, y in holes:
        im[y, x, :3] = (70, 60, 48)
    for x, y in notches:
        if on[y, x]:
            im[y, x, :3] = (120, 128, 136)
    # one cord through the five holes, its loose ends trailing
    cord = c.line([(41, 54), (46, 57), (75, 57), (80, 55), (84, 52)], 1)
    cord &= ~(on & (yy != 57))
    im[cord, :3] = np.array(hexc('#d8c69a'))
    im[cord, 3] = 255
    return Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), 'RGBA')


def giay_tam():
    """Variant (b) (docs/N_bach_son.md 8.7): the sheet the mute servant brings down. Tâm teaches the stroke on
    paper instead of on a hand: how to wash, and where to stop. Her hand: small, upright, careful."""
    rng = np.random.default_rng(41)
    Wd, Hd = 360, 330
    im = Image.new('RGBA', (Wd, Hd), (0, 0, 0, 0))
    n = pnoise(256, 16, 41)
    n = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((Wd, Hd), Image.BILINEAR)) / 255.0
    paper = np.zeros((Hd, Wd, 4), float)
    paper[..., :3] = np.array([238, 231, 212])[None, None, :] * (0.95 + 0.07 * n)[..., None]
    paper[..., 3] = 255
    yy, xx = np.mgrid[0:Hd, 0:Wd]
    fold = 1 - 0.07 * np.exp(-((yy - Hd / 2) / 3.0) ** 2)     # folded once, to be carried down
    paper[..., :3] *= fold[..., None]
    im = Image.fromarray(np.clip(paper, 0, 255).astype(np.uint8), 'RGBA')
    d = ImageDraw.Draw(im)
    y = 30
    for t, size in [("Rửa.", 18), ("", 8), ("Rắc tro cho kẽ hiện ra.", 15), ("Kẽ men thẳng, gãy góc, trên nền trắng.", 15),
                    ("Kẽ da cong theo chỉ tay. Đừng nhầm.", 15), ("Lần theo kẽ men. Tới mép thì dừng.", 15), ("", 8),
                    ("Cắt phần đã thối, không cắt người.", 16)]:
        if t:
            write(d, (34, y), t, size, INK, rng)
        y += size + 14
    seal(im, Wd - 64, Hd - 58, 52, ["BẠCH", "ĐIỆN"], seed=11)
    return im


def build():
    for name, fn in [('so_cot', so_cot), ('so_sac', so_sac), ('so_ban', so_ban), ('so_pk21', so_pk21),
                     ('so_pk395', so_pk395), ('nong_close', nong_close)]:
        fn().save(os.path.join(ROOT, 'ui', name + '.png'))
    chen_ran().save(os.path.join(ROOT, 'tex', 'chen_ran.png'))
    giay_tam().save(os.path.join(ROOT, 'ui', 'giay_tam.png'))
    tranh_tho().save(os.path.join(ROOT, 'tex', 'tranh_tho.png'))


if __name__ == '__main__':
    build()
    print('ok')
