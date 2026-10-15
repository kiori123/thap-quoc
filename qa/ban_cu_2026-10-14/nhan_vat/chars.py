"""Procedural pixel characters for Thập Quốc (32x48 frames, feet on y=45).

Sheet layout produced by build_walk_sheet():
  rows: 0 down, 1 left, 2 right (mirror of left), 3 up
  cols: 0 idle_a, 1 idle_b, 2..5 walk cycle
"""
import math
import numpy as np
from PIL import Image, ImageOps
from pix import Canvas, ramp, hexc, mix

W, H = 32, 48
GROUND = 45

# ---------------------------------------------------------------- palettes
SKIN = ramp('#e3b48e', shadow='#b97f5f', light='#f3d1b0', outline='#4a2a22')
SKIN_TAN = ramp('#c98f66', shadow='#9a6347', light='#dfac84', outline='#3d2219')
SKIN_OLD = ramp('#d6a382', shadow='#a8775c', light='#e9c2a2', outline='#432720')
HAIR_BLACK = ramp('#2b2227', shadow='#18121a', light='#4a3d47', outline='#0c080c', hi='#6e6070')
HAIR_WHITE = ramp('#d9d4cc', shadow='#a49e98', light='#f2eee6', outline='#4c4642', hi='#ffffff')
HAIR_GREY = ramp('#8d8780', shadow='#625d58', light='#b0aaa2', outline='#2e2a28')
CLOTH_BROWN = ramp('#7a5238', shadow='#53352a', light='#9c6d4a', outline='#26170f')
CLOTH_BROWN_OLD = ramp('#6b4a36', shadow='#4a3226', light='#86604a', outline='#21150e')
CLOTH_INDIGO = ramp('#34405c', shadow='#232b40', light='#4b5b7e', outline='#0f121c')
CLOTH_BLACK = ramp('#2e2a2e', shadow='#1d1a1e', light='#454046', outline='#0b0a0c')
CLOTH_CREAM = ramp('#d8ccb4', shadow='#a99c86', light='#ece3d0', outline='#4b4235')
CLOTH_GREEN = ramp('#56663f', shadow='#3b4a2c', light='#73845a', outline='#1b2213')
CLOTH_RED = ramp('#9a3a32', shadow='#6b2522', light='#bd5a48', outline='#2c0f0e')
CLOTH_ASH = ramp('#a6a3a0', shadow='#77746f', light='#c6c3be', outline='#33312f')
CLOTH_ASH_DARK = ramp('#77736f', shadow='#55524f', light='#94908b', outline='#252321')
# Bạch Sơn: undyed white hemp, the cobalt of the Ty (the same glaze as Trắng Tay's blindfolds)
CLOTH_WHITE = ramp('#e6e2d8', shadow='#b3aea2', light='#f6f3ec', outline='#4e4a42')
CLOTH_WHITE_DIM = ramp('#cdc8bc', shadow='#9e998e', light='#e2ddd2', outline='#45413a')
CLOTH_COBALT = ramp('#34508f', shadow='#243866', light='#4c6cb0', outline='#101a33')
STRAW = ramp('#c9a45c', shadow='#9c7a3d', light='#e2c47f', outline='#4a3818')
WOOD = ramp('#7a5a3a', shadow='#56402a', light='#987552', outline='#24180e')
IRON = ramp('#6d7279', shadow='#494d53', light='#9aa0a8', outline='#1d1f23', hi='#d6dbe0')
SHOE = ramp('#3b2c24', shadow='#271c16', light='#54402f', outline='#120c09')
PORCELAIN = ramp('#dde3e8', shadow='#a3afba', light='#f4f7fa', outline='#4d5965', hi='#ffffff')
CRACK = ramp('#5d6e7d', shadow='#47566a', light='#7d8d9b', outline='#2e3844')
EYE = ramp('#1a1216', shadow='#1a1216', light='#1a1216', outline='#1a1216')
BEARD = HAIR_WHITE
HEADBAND = CLOTH_RED


# ---------------------------------------------------------------- the look in the world (HD-2D)
# The sprites stand in a lit 3D world, so their tones follow its light: shadows lean to the blue-violet of the sky
# that fills them, lights to the warm sun; a sixth, deepest tone where one part shadows another; whites a step down,
# so a white robe in the sun is no brighter than the lime of the walls around it.
COOL = (64, 72, 118)
WARM = (255, 232, 184)


def _octo(r):
    ol, sh, m, li, hi = r[:5]
    cool = 0.16
    if (m[0] * 299 + m[1] * 587 + m[2] * 114) / 1000 > 195:
        # a white: the body of it a step down, its lit side kept, its shade the blue of the sky
        m, hi = mix(m, sh, 0.28), mix(hi, li, 0.5)
        sh, cool = mix(sh, (110, 122, 170), 0.3), 0.0
    deep = mix(mix(sh, ol, 0.45), COOL, 0.2)
    return [mix(ol, (28, 20, 44), 0.2), mix(sh, COOL, cool), m, mix(li, WARM, 0.12), mix(hi, WARM, 0.15), deep]


class Spec:
    def __init__(self, **kw):
        self.skin = SKIN
        self.hair = HAIR_BLACK
        self.shirt = CLOTH_BROWN
        self.pants = CLOTH_INDIGO
        self.sash = None
        self.shoe = SHOE
        self.hair_style = 'short'
        self.hat = None
        self.headband = None
        self.beard = False
        self.oy = 0            # vertical offset of upper body (positive = shorter)
        self.hunch = 0         # forward lean in side view / lower head in front view
        self.kid = False
        self.long_tunic = False
        self.skirt = False
        self.patches = False   # porcelain patches (Lúa)
        self.statue = False    # whole figure porcelain
        self.rolled = False    # rolled trousers (bare calves)
        self.patch_cloth = False
        self.hood = False
        self.holds = None      # 'child', 'cane', 'sack'
        self.__dict__.update(kw)


def _mk(spec, w=W, h=H):
    c = Canvas(w, h)
    O = _octo
    if spec.statue:
        m = c.material(O(PORCELAIN))
        mats = dict(skin=m, hair=m, shirt=m, pants=m, sash=m, shoe=m, eye=c.material(CRACK, flat=True),
                    hat=m, band=m, beard=m, crack=c.material(CRACK, flat=True, outline=False),
                    patch=m, tool=m, wood=m, sleeve=m)
    else:
        mats = dict(
            skin=c.material(O(spec.skin)),
            hair=c.material(O(spec.hair)),
            shirt=c.material(O(spec.shirt)),
            pants=c.material(O(spec.pants)),
            sash=c.material(O(spec.sash or spec.shirt)),
            shoe=c.material(O(spec.shoe)),
            eye=c.material(EYE, flat=True, outline=False),
            hat=c.material(O(STRAW)),
            band=c.material(O(spec.headband or HEADBAND)),
            beard=c.material(O(BEARD)),
            crack=c.material(CRACK, flat=True, outline=False),
            patch=c.material(O(PORCELAIN)),
            tool=c.material(O(IRON)),
            wood=c.material(O(WOOD)),
            sleeve=c.material(O(spec.shirt)),
        )
    return c, mats


def _dims(spec):
    if spec.kid:
        return dict(hy=21, rx=5.2, ry=5.4, top=27, bot=36, legtop=35, sw=5)
    return dict(hy=12 + spec.oy, rx=5.1, ry=5.5, top=18 + spec.oy, bot=31, legtop=30, sw=6)


# ---------------------------------------------------------------- front / back
def _front(spec, view, legs=(0, 0), arms=(0, 0), bob=0, pose=None, fr=None):
    """fr (animated frames): lift (L, R) knee raise, fy (L, R) foot nearer/further, back (L, R) leg behind,
    arm (L, R) hand up(-)/down(+), armx (L, R) hand in(+)/out(-), hb head bob, sway hair/hem, blink."""
    c, M = _mk(spec)
    d = _dims(spec)
    cx = 16
    hb = fr.get('hb', 0) if fr else 0
    hy = d['hy'] + bob + hb + spec.hunch
    top = d['top'] + bob + spec.hunch
    bot = d['bot'] + bob
    sw = d['sw'] - (1 if spec.hunch else 0)
    # legs
    if pose in ('sit', 'sword_sit'):
        c.paint(c.ellipse(cx, GROUND - 3, 9, 3.2), M['pants'])
        c.paint(c.rect(cx - 9, GROUND - 2, cx - 7, GROUND - 1), M['shoe'])
        c.paint(c.rect(cx + 7, GROUND - 2, cx + 9, GROUND - 1), M['shoe'])
        shift = GROUND - 4 - bot
        hy += shift
        top += shift
        bot += shift
    elif fr is not None and not spec.skirt:
        # back leg first so the forward one overlaps it
        order = sorted((0, 1), key=lambda i: -fr['back'][i])
        for i in order:
            side = (-1, 1)[i]
            lift, fy = fr['lift'][i], fr['fy'][i]
            x0 = (cx - 4 if side < 0 else cx + 1) + fr.get('stance', 0) * side
            y_end = GROUND - 2 - lift + fy
            tn = 1 if fr['back'][i] else 0
            c.paint(c.rect(x0, d['legtop'] + bob, x0 + 2, y_end), M['pants'], tone=tn)
            if spec.rolled and not spec.kid:
                c.paint(c.rect(x0, y_end - 4, x0 + 2, y_end), M['skin'], tone=tn)
            if spec.kid and not spec.rolled:
                c.paint(c.rect(x0, y_end - 3, x0 + 2, y_end), M['skin'], tone=tn)
            c.paint(c.rect(x0 - (1 if lift == 0 and side < 0 else 0), y_end + 1, x0 + 2 + (1 if lift == 0 and side > 0 else 0), y_end + 2), M['shoe'], tone=tn)
    else:
        for i, side in enumerate((-1, 1)):
            lift = legs[i]
            x0 = cx - 4 if side < 0 else cx + 1
            y_end = GROUND - 2 - lift
            if spec.skirt:
                continue
            c.paint(c.rect(x0, d['legtop'] + bob, x0 + 2, y_end), M['pants'])
            if spec.rolled and not spec.kid:
                c.paint(c.rect(x0, y_end - 4, x0 + 2, y_end), M['skin'])
            if spec.kid and not spec.rolled:
                c.paint(c.rect(x0, y_end - 3, x0 + 2, y_end), M['skin'])
            c.paint(c.rect(x0, y_end + 1, x0 + 2, y_end + 2), M['shoe'])
    if spec.skirt and pose not in ('sit', 'sword_sit'):
        sw_ = fr.get('sway', 0) if fr else 0
        c.paint(c.poly([(cx - 6, bot - 2), (cx + 5, bot - 2), (cx + 6 + sw_, GROUND - 1), (cx - 7 + sw_, GROUND - 1)]), M['pants'])
        lf = fr['lift'] if fr else (0, 0)
        c.paint(c.rect(cx - 4, GROUND - lf[0], cx - 2, GROUND - lf[0]), M['shoe'])
        c.paint(c.rect(cx + 1, GROUND - lf[1], cx + 3, GROUND - lf[1]), M['shoe'])
    # far side items (back view: child / sack behind)
    # torso
    hem = bot + (6 if spec.long_tunic else 0)
    c.paint(c.poly([(cx - sw, top), (cx + sw - 1, top), (cx + sw, hem), (cx - sw - 1, hem)]), M['shirt'])
    if not spec.statue:
        _folds_front(c, M, spec, view, cx, top, bot, hem, sw, fr.get('sway', 0) if fr else 0)
    if spec.patch_cloth and view == 'down':
        c.paint(c.rect(cx + 1, top + 6, cx + 3, top + 8), M['shirt'], tone=3)
    if spec.sash and not spec.statue:
        c.paint(c.rect(cx - sw, bot - 4, cx + sw - 1, bot - 3), M['sash'])
    # arms
    for i, side in enumerate((-1, 1)):
        a = arms[i]
        if pose in SWORD_POSES:   # the arms are drawn with the sword (title_frames)
            continue
        if pose == 'hand_side' and side > 0:
            # bent arm, hand pressed to the side
            c.paint(c.rect(cx + sw - 1, top + 1, cx + sw + 1, top + 5), M['sleeve'])
            c.paint(c.rect(cx + sw - 2, top + 5, cx + sw, top + 7), M['sleeve'])
            c.paint(c.rect(cx + sw - 3, top + 6, cx + sw - 2, top + 8), M['skin'])
            continue
        if pose == 'arm_up' and side > 0:
            c.paint(c.line([(cx + sw, top + 2), (cx + sw + 3, top - 6), (cx + sw + 3, top - 13)], 3), M['sleeve'])
            c.paint(c.rect(cx + sw + 2, top - 16, cx + sw + 4, top - 14), M['skin'])
            continue
        x0 = cx - sw - 2 if side < 0 else cx + sw - 1
        alen = 8 if not spec.kid else 6
        if fr is not None:
            ay = fr['arm'][i]
            ax = fr['armx'][i] * (-side)
            tn = 1 if ay < 0 else 0
            c.paint(c.line([(x0 + 1, top + 1), (x0 + 1 + ax, top + alen + ay)], 3), M['sleeve'], tone=tn)
            c.paint(c.rect(x0 + ax, top + alen + 1 + ay, x0 + 2 + ax, top + alen + 2 + ay), M['skin'], tone=tn)
            continue
        c.paint(c.rect(x0, top + 1 + a, x0 + 2, top + alen + a), M['sleeve'])
        c.paint(c.rect(x0, top + alen + 1 + a, x0 + 2, top + alen + 2 + a), M['skin'])
    if spec.holds == 'child' and view == 'down':
        c.paint(c.ellipse(cx - 1, top + 6, 4.5, 3.6), c.material(CLOTH_CREAM) if not spec.statue else M['shirt'])
        c.paint(c.ellipse(cx - 4, top + 4, 2.4, 2.4), M['skin'])
    # neck
    c.paint(c.rect(cx - 1, hy + 5, cx, hy + 6), M['skin'])
    # head
    c.paint(c.ellipse(cx, hy, d['rx'], d['ry']), M['skin'])
    _hair_front(c, M, spec, view, cx, hy, d, fr.get('sway', 0) if fr else 0)
    if not spec.statue:
        _head_detail(c, M, spec, view, cx, hy, d)
    if view == 'down':
        _face_front(c, M, spec, cx, hy, pose, fr.get('blink', False) if fr else False)
    if spec.hat == 'nonla':
        c.paint(c.poly([(cx - 10, hy - 1), (cx + 10, hy - 1), (cx, hy - 10)]), M['hat'])
        c.paint(c.rect(cx - 10, hy - 1, cx + 10, hy - 1), M['hat'], tone=1)
    if spec.patches and not spec.statue and view == 'down':
        c.paint(c.ellipse(cx - 3, hy + 2, 1.8, 1.5), M['patch'])
        c.paint(c.rect(cx - sw - 2, top + 3, cx - sw, top + 6), M['patch'])
        c.paint(c.px(cx - 3, hy + 2), M['crack'])
    if spec.statue:
        _cracks(c, M)
    return c


def _folds_front(c, M, spec, view, cx, top, bot, hem, sw, sway=0):
    """Cloth, not a slab: the robe falls in folds from the sash, and a robe crosses over the chest at the collar
    (right panel over the left); a seam down the back."""
    if spec.long_tunic or spec.skirt:
        for fx, k in ((cx - 3, 0), (cx + 2, 1)):
            x1 = fx + (sway if k else 0)
            c.set_tone(c.line([(fx, bot - 1), (x1, hem - 1)], 1), 1)
            c.set_tone(c.line([(fx - 1, bot), (x1 - 1, hem - 2)], 1), 3)
    else:
        c.set_tone(c.line([(cx - 2, bot - 2), (cx - 3, bot)], 1), 1)
    if view == 'down':
        if spec.long_tunic:
            c.set_tone(c.line([(cx - 2, top), (cx + 2, top + 4), (cx + sw - 2, top + 7)], 1), 1)
            c.set_tone(c.line([(cx - 3, top + 1), (cx + 1, top + 5)], 1), 3)
        else:
            c.set_tone(c.line([(cx - 1, top + 1), (cx - 1, bot - 5)], 1), 1)
    else:
        c.set_tone(c.line([(cx - 1, top + 2), (cx - 1, hem - 1)], 1), 1)


def _folds_side(c, spec, cx, hip_x, top, bot, hem, sway=0):
    if spec.long_tunic or spec.skirt:
        c.set_tone(c.line([(hip_x + 1, bot - 1), (hip_x + 1 + sway, hem - 1)], 1), 1)
        c.set_tone(c.line([(hip_x, bot), (hip_x + sway, hem - 2)], 1), 3)
    c.set_tone(c.line([(cx - 3, top + 1), (cx - 2, top + 5)], 1), 1)   # the collar's edge


def _head_detail(c, M, spec, view, cx, hy, d):
    """Hair is not a ball of one colour: a sheen arcs across the crown on the side toward the light, strands part
    it; a hood is cloth, deep in shadow where it frames the face."""
    xx, yy = c.grid()
    hair = c.mat == M['hair']
    if spec.hood or (spec.hair_style == 'scarf'):
        cloth = (c.mat == M['shirt']) if spec.hood else (c.mat == M['band'])
        sheen = c.ellipse(cx - 1.6, hy - 3.2, d['rx'] - 0.6, d['ry'] - 2.6) & ~c.ellipse(cx - 0.6, hy - 2.0, d['rx'] - 0.4, d['ry'] - 2.2)
        c.set_tone(sheen & cloth, 3)
        if view == 'down':
            rim = c.ellipse(cx, hy + 1.2, d['rx'] - 0.4, d['ry'] - 0.8) & ~c.ellipse(cx, hy + 1.6, d['rx'] - 1.4, d['ry'] - 1.6)
            c.set_tone(rim & cloth & (yy > hy - 1), 1)
        elif view == 'up':
            c.set_tone(c.line([(cx + 1, hy - 3), (cx + 2, hy + 4)], 1) & cloth, 1)
        else:
            c.set_tone(c.line([(cx - 3, hy - 3), (cx - 4, hy + 4)], 1) & cloth, 5)
        return
    if not hair.any():
        return
    # the sheen: a short arc on the upper left of the crown
    sheen = c.ellipse(cx - 1.4, hy - 2.6, d['rx'] - 0.8, d['ry'] - 2.2) & ~c.ellipse(cx - 0.4, hy - 1.4, d['rx'] - 0.8, d['ry'] - 2.0)
    c.set_tone(sheen & hair & (yy < hy - 1), 4)
    if view == 'up':
        for x0, x1 in ((cx - 2.5, cx - 3.5), (cx + 1.5, cx + 2.5)):
            c.set_tone(c.line([(x0, hy - 4), (x1, hy + 3)], 1) & hair, 1)
        c.set_tone(c.line([(cx - 4, hy + 2), (cx + 3, hy + 2)], 1) & hair & (xx > cx), 5)
    elif view == 'down':
        c.set_tone(c.line([(cx + 1, hy - 4), (cx + 2, hy - 1)], 1) & hair, 1)
    else:
        c.set_tone(c.line([(cx + 1, hy - 4), (cx + 3, hy + 1)], 1) & hair, 1)


def _hair_front(c, M, spec, view, cx, hy, d, sway=0):
    s = spec.hair_style
    if s == 'none':
        return
    if spec.hood:
        hood = c.ellipse(cx, hy - 0.5, d['rx'] + 1.6, d['ry'] + 1.2)
        if view == 'down':
            hood &= ~c.ellipse(cx, hy + 1.5, d['rx'] - 1.2, d['ry'] - 1.5)
        c.paint(hood, M['shirt'])
        return
    if view == 'up':
        c.paint(c.ellipse(cx, hy - 0.5, d['rx'] + 0.6, d['ry'] + 0.4), M['hair'])
        if s == 'short':
            c.paint(c.rect(cx - 4, hy + 4, cx + 3, hy + 5), M['hair'])
        if s in ('bun_old', 'bun'):
            c.paint(c.ellipse(cx, hy - 6, 2.4, 2.0), M['hair'])
        if s == 'braid':
            c.paint(c.line([(cx - 0.5, hy + 4), (cx - 0.5 + sway, hy + 16)], 2), M['hair'])
            c.paint(c.rect(cx - 1 + (sway > 0), hy + 9, cx + (sway > 0), hy + 9), M['band'])
        if s == 'pigtails':
            c.paint(c.ellipse(cx - 6, hy + 1, 1.8, 3), M['hair'])
            c.paint(c.ellipse(cx + 6, hy + 1, 1.8, 3), M['hair'])
        if s == 'scarf':
            c.paint(c.ellipse(cx, hy - 1, d['rx'] + 1, d['ry'] + 0.5), M['band'])
        if spec.headband:
            c.paint(c.rect(cx - 6, hy - 2, cx + 5, hy - 1), M['band'])
            c.paint(c.rect(cx + 1, hy - 1, cx + 2, hy + 4), M['band'])
        return
    # front view
    if s == 'short':
        cap = c.ellipse(cx, hy - 1.8, d['rx'] + 0.8, d['ry'] - 1.2) & (c.grid()[1] < hy - 0.5)
        c.paint(cap, M['hair'])
        for x in (cx - 5, cx - 3, cx + 1, cx + 4):
            c.paint(c.px(x, hy - 0), M['hair'])
        c.paint(c.rect(cx - 6, hy - 2, cx - 5, hy + 2), M['hair'])
        c.paint(c.rect(cx + 5, hy - 2, cx + 6, hy + 2), M['hair'])
        c.set_tone(c.rect(cx - 3, hy - 5, cx - 1, hy - 5), 4)
    elif s in ('bun_old', 'bun'):
        cap = c.ellipse(cx, hy - 2.6, d['rx'] + 0.6, d['ry'] - 2.2) & (c.grid()[1] < hy - 2)
        c.paint(cap, M['hair'])
        c.paint(c.ellipse(cx, hy - 7, 2.4, 2.0), M['hair'])
        c.paint(c.rect(cx - 6, hy - 2, cx - 5, hy + 1), M['hair'])
        c.paint(c.rect(cx + 5, hy - 2, cx + 6, hy + 1), M['hair'])
    elif s == 'braid' or s == 'tied':
        cap = c.ellipse(cx, hy - 1.5, d['rx'] + 0.8, d['ry'] - 0.8) & (c.grid()[1] < hy)
        c.paint(cap, M['hair'])
        c.paint(c.rect(cx - 6, hy - 2, cx - 5, hy + 4), M['hair'])
        c.paint(c.rect(cx + 5, hy - 2, cx + 6, hy + 4), M['hair'])
        c.paint(c.rect(cx - 2, hy - 3, cx + 1, hy - 3), M['hair'], tone=1)
    elif s == 'pigtails':
        cap = c.ellipse(cx, hy - 1.5, d['rx'] + 0.6, d['ry'] - 1) & (c.grid()[1] < hy - 0.5)
        c.paint(cap, M['hair'])
        c.paint(c.ellipse(cx - 7, hy + 1, 1.8, 3), M['hair'])
        c.paint(c.ellipse(cx + 7, hy + 1, 1.8, 3), M['hair'])
    elif s == 'tuft':
        c.paint(c.ellipse(cx, hy - 5.5, 1.8, 1.6), M['hair'])
    elif s == 'scarf':
        sc = c.ellipse(cx, hy - 1, d['rx'] + 1.2, d['ry'] + 0.6) & ~c.ellipse(cx, hy + 1.8, d['rx'] - 1.2, d['ry'] - 1.6)
        c.paint(sc, M['band'])
        c.paint(c.poly([(cx - 3, hy - 5), (cx + 3, hy - 5), (cx, hy - 10)]), M['band'])
        c.set_tone(c.rect(cx - 1, hy - 8, cx, hy - 6), 3)
    if spec.headband:
        c.paint(c.rect(cx - 6, hy - 2, cx + 5, hy - 1), M['band'])


def _face_front(c, M, spec, cx, hy, pose, blink=False):
    ey = hy + 1
    if spec.statue:
        return
    if blink:
        c.paint(c.rect(cx - 3, ey + 1, cx - 3, ey + 1), M['eye'])
        c.paint(c.rect(cx + 2, ey + 1, cx + 2, ey + 1), M['eye'])
    else:
        c.paint(c.rect(cx - 3, ey, cx - 3, ey + 1), M['eye'])
        c.paint(c.rect(cx + 2, ey, cx + 2, ey + 1), M['eye'])
    if spec.beard:
        c.paint(c.rect(cx - 4, ey - 2, cx - 2, ey - 2), M['beard'])
        c.paint(c.rect(cx + 1, ey - 2, cx + 3, ey - 2), M['beard'])
        beard = c.poly([(cx - 4, hy + 3), (cx + 3, hy + 3), (cx + 1, hy + 10), (cx - 2, hy + 10)])
        c.paint(beard, M['beard'])
        if pose == 'near_smile':
            c.paint(c.rect(cx - 2, hy + 3, cx + 1, hy + 3), M['skin'], tone=1)
            c.paint(c.px(cx - 3, hy + 2), M['skin'], tone=1)
            c.paint(c.px(cx + 2, hy + 2), M['skin'], tone=1)
        else:
            c.paint(c.rect(cx - 2, hy + 3, cx + 1, hy + 3), M['skin'], tone=1)
    else:
        if pose == 'near_smile':
            c.paint(c.rect(cx - 1, hy + 4, cx, hy + 4), M['skin'], tone=1)
        # tiny mouth hint
        c.paint(c.px(cx - 1, hy + 4), M['skin'], tone=1)


def _cracks(c, M):
    rng = np.random.default_rng(7)
    filled = c.mat >= 0
    ys, xs = np.where(filled)
    for _ in range(9):
        i = rng.integers(len(xs))
        x, y = xs[i], ys[i]
        for _k in range(4):
            if 0 <= x < c.w and 0 <= y < c.h and c.mat[y, x] >= 0:
                c.paint(c.px(x, y), M['crack'])
            x += rng.integers(-1, 2)
            y += 1


# ---------------------------------------------------------------- side view (facing left)
def _ik(a, b, seg, bend_x):
    """Joint between a and b for two segments of length seg, bent toward bend_x (-1 forward, +1 back)."""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    dist = max((dx * dx + dy * dy) ** 0.5, 1e-3)
    mx, my = (ax + bx) / 2, (ay + by) / 2
    if dist >= 2 * seg:
        return (mx, my)
    off = (seg * seg - (dist / 2) ** 2) ** 0.5
    px, py = -dy / dist, dx / dist
    if px * bend_x < 0:
        px, py = -px, -py
    return (mx + px * off, my + py * off)


def _limb(c, pts, w):
    """Union of quads of width w along a polyline (cleaner pixels than a thick line)."""
    m = np.zeros((c.h, c.w), bool)
    for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
        dx, dy = bx - ax, by - ay
        L = max((dx * dx + dy * dy) ** 0.5, 1e-3)
        nx, ny = -dy / L * w / 2, dx / L * w / 2
        m |= c.poly([(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)])
    for (x, y) in pts:
        m |= c.ellipse(x, y, w / 2, w / 2)
    return m


def _side(spec, legs=(0, 0), arms=(0, 0), bob=0, pose=None, tool=None, lean=0, fr=None):
    """legs: (front_leg_dx, back_leg_dx); arms: (near_arm_dx, far_arm_dx).
    fr (animated frames): feet [(dx, lift) near, far], hands [(dx, dy) near, far], lean (upper body),
    hb head bob, sway, blink."""
    if fr is not None:
        return _side_anim(spec, fr)
    c, M = _mk(spec)
    d = _dims(spec)
    cx = 16 + lean
    hy = d['hy'] + bob + spec.hunch
    top = d['top'] + bob + spec.hunch
    bot = d['bot'] + bob
    hx = cx - spec.hunch  # head forward when hunched
    # far arm (behind body)
    fa = arms[1]
    if pose not in ('windup', 'strike', 'follow', 'guard', 'sweep_wind', 'sweep_strike', 'broom_a', 'broom_b', 'give', 'bandage', 'item',
                    'windup_deep', 'smear', 'recover', 'sweep_smear', 'parry', 'victory', 'hurt_b'):
        c.paint(c.rect(cx + 1 + fa, top + 1, cx + 3 + fa, top + 8), M['sleeve'], tone=1)
        c.paint(c.rect(cx + 1 + fa, top + 9, cx + 3 + fa, top + 10), M['skin'], tone=1)
    # legs
    if not spec.skirt:
        fl, bl = legs
        y_end = GROUND - 2
        # back leg (darker)
        c.paint(c.rect(cx + bl, d['legtop'] + bob, cx + 2 + bl, y_end), M['pants'], tone=1)
        c.paint(c.rect(cx + bl - 1, y_end + 1, cx + 2 + bl, y_end + 2), M['shoe'], tone=1)
        c.paint(c.rect(cx - 2 + fl, d['legtop'] + bob, cx + fl, y_end), M['pants'])
        if spec.rolled or spec.kid:
            c.paint(c.rect(cx - 2 + fl, y_end - 3, cx + fl, y_end), M['skin'])
        c.paint(c.rect(cx - 3 + fl, y_end + 1, cx + fl, y_end + 2), M['shoe'])
    else:
        c.paint(c.poly([(cx - 4, bot - 2), (cx + 3, bot - 2), (cx + 4 + legs[1] // 2, GROUND - 1), (cx - 5 + legs[0] // 2, GROUND - 1)]), M['pants'])
        c.paint(c.rect(cx - 5 + legs[0] // 2, GROUND, cx - 3 + legs[0] // 2, GROUND), M['shoe'])
    # torso
    hem = bot + (6 if spec.long_tunic else 0)
    c.paint(c.poly([(cx - 4 - spec.hunch, top), (cx + 3, top), (cx + 4, hem), (cx - 4, hem)]), M['shirt'])
    if spec.sash and not spec.statue:
        c.paint(c.rect(cx - 4, bot - 4, cx + 3, bot - 3), M['sash'])
    if spec.holds == 'sack':
        c.paint(c.ellipse(cx + 5, top + 5, 3.5, 5), c.material(STRAW) if not spec.statue else M['shirt'])
    # head
    c.paint(c.rect(hx - 1, hy + 5, hx + 1, hy + 6), M['skin'])
    c.paint(c.ellipse(hx - 0.5, hy, d['rx'] - 0.3, d['ry']), M['skin'])
    c.paint(c.px(hx - 6, hy + 2), M['skin'])  # nose
    _hair_side(c, M, spec, hx, hy, d)
    if not spec.statue:
        c.paint(c.rect(hx - 3, hy + 1, hx - 3, hy + 2), M['eye'])
        if spec.beard:
            c.paint(c.poly([(hx - 5, hy + 3), (hx - 1, hy + 3), (hx - 1, hy + 9), (hx - 4, hy + 8)]), M['beard'])
            c.paint(c.rect(hx - 4, hy - 1, hx - 2, hy - 1), M['beard'])
    if spec.hat == 'nonla':
        c.paint(c.poly([(hx - 10, hy - 1), (hx + 9, hy - 1), (hx, hy - 10)]), M['hat'])
    if spec.patches and not spec.statue:
        c.paint(c.ellipse(hx - 2, hy + 3, 1.6, 1.4), M['patch'])
    # near arm + tool
    _near_arm(c, M, spec, cx, top, arms[0], pose, tool)
    if spec.holds == 'cane':
        c.paint(c.line([(cx - 7, top + 8), (cx - 9, GROUND)], 1), M['wood'])
    if spec.holds == 'child':
        c.paint(c.ellipse(cx - 4, top + 6, 3.5, 3.5), c.material(CLOTH_CREAM) if not spec.statue else M['shirt'])
        c.paint(c.ellipse(cx - 6, top + 4, 2.2, 2.2), M['skin'])
    if spec.statue:
        _cracks(c, M)
    return c


def _side_anim(spec, fr):
    c, M = _mk(spec)
    d = _dims(spec)
    bob = fr['bob']
    lean = fr.get('lean', 0)
    hip_x = 16
    cx = hip_x + lean                      # shoulders / head shift with the lean
    hy = d['hy'] + bob + fr.get('hb', 0) + spec.hunch
    top = d['top'] + bob + spec.hunch
    bot = d['bot'] + bob
    hx = cx - spec.hunch
    leg_top = d['legtop'] + bob
    seg = (GROUND - 2 - d['legtop']) / 2 + 0.05
    aseg = 4.6 if not spec.kid else 3.6
    sh = (cx - 0.5, top + 1.5)

    def leg(foot, tn, near):
        fx = hip_x + 0.5 + foot[0]
        fy = GROUND - 2 - foot[1]
        hip = (hip_x + 0.5 + (-0.5 if near else 1.0), leg_top + 0.5)
        knee = _ik(hip, (fx, fy), seg, -1)
        c.paint(_limb(c, [hip, knee, (fx, fy)], 2.6), M['pants'], tone=tn)
        if spec.rolled or spec.kid:
            kx, ky = knee
            c.paint(_limb(c, [(kx + (fx - kx) * 0.45, ky + (fy - ky) * 0.45), (fx, fy)], 2.6), M['skin'], tone=tn)
        c.paint(c.rect(fx - 3, fy + 1, fx, fy + 2), M['shoe'], tone=tn)

    def arm(hand, tn, bent=False):
        hxp = sh[0] + hand[0]
        hyp = top + 9 + hand[1]
        elbow = _ik(sh, (hxp, hyp), aseg, 1)
        c.paint(_limb(c, [sh, elbow, (hxp, hyp)], 2.6), M['sleeve'], tone=tn)
        c.paint(c.rect(hxp - 1, hyp - 0.5, hxp, hyp + 0.5), M['skin'], tone=tn)

    (nf, ff) = fr['feet']
    (nh, fh) = fr['hands']
    # far arm, far leg (behind), then body
    if not spec.holds:
        arm(fh, 1)
    if not spec.skirt:
        leg(ff, 1, False)
        leg(nf, 0, True)
    else:
        sw_ = fr.get('sway', 0)
        c.paint(c.poly([(hip_x - 4, bot - 2), (hip_x + 3, bot - 2), (hip_x + 4 + sw_, GROUND - 1), (hip_x - 5 + sw_, GROUND - 1)]), M['pants'])
        c.paint(c.rect(hip_x - 5 + nf[0] // 2, GROUND - nf[1], hip_x - 3 + nf[0] // 2, GROUND - nf[1]), M['shoe'])
    hem = bot + (6 if spec.long_tunic else 0)
    c.paint(c.poly([(cx - 4 - spec.hunch, top), (cx + 3, top), (hip_x + 4, hem), (hip_x - 4, hem)]), M['shirt'])
    if not spec.statue:
        _folds_side(c, spec, cx, hip_x, top, bot, hem, fr.get('sway', 0))
    if spec.sash and not spec.statue:
        c.paint(c.poly([(hip_x - 4 + lean, bot - 4), (hip_x + 3 + lean, bot - 4), (hip_x + 3 + lean, bot - 3), (hip_x - 4 + lean, bot - 3)]), M['sash'])
    if spec.holds == 'sack':
        c.paint(c.ellipse(cx + 5, top + 5, 3.5, 5), c.material(STRAW) if not spec.statue else M['shirt'])
    c.paint(c.rect(hx - 1, hy + 5, hx + 1, hy + 6), M['skin'])
    c.paint(c.ellipse(hx - 0.5, hy, d['rx'] - 0.3, d['ry']), M['skin'])
    c.paint(c.px(hx - 6, hy + 2), M['skin'])
    _hair_side(c, M, spec, hx, hy, d, fr.get('sway', 0))
    if not spec.statue:
        _head_detail(c, M, spec, 'left', hx + 0.8, hy, d)
    if not spec.statue:
        if fr.get('blink'):
            c.paint(c.rect(hx - 3, hy + 2, hx - 3, hy + 2), M['eye'])
        else:
            c.paint(c.rect(hx - 3, hy + 1, hx - 3, hy + 2), M['eye'])
        if spec.beard:
            c.paint(c.poly([(hx - 5, hy + 3), (hx - 1, hy + 3), (hx - 1, hy + 9), (hx - 4, hy + 8)]), M['beard'])
            c.paint(c.rect(hx - 4, hy - 1, hx - 2, hy - 1), M['beard'])
    if spec.hat == 'nonla':
        c.paint(c.poly([(hx - 10, hy - 1), (hx + 9, hy - 1), (hx, hy - 10)]), M['hat'])
    if spec.patches and not spec.statue:
        c.paint(c.ellipse(hx - 2, hy + 3, 1.6, 1.4), M['patch'])
    if spec.holds == 'cane':
        c.paint(c.line([(cx - 7, top + 8), (cx - 9 + nh[0] // 2, GROUND)], 1), M['wood'])
        arm((-6, -1), 0)
    elif spec.holds == 'child':
        c.paint(c.ellipse(cx - 4, top + 6, 3.5, 3.5), c.material(CLOTH_CREAM) if not spec.statue else M['shirt'])
        c.paint(c.ellipse(cx - 6, top + 4, 2.2, 2.2), M['skin'])
        arm((-4, -3), 0)
    else:
        arm(nh, 0)
    if spec.statue:
        _cracks(c, M)
    return c


def _hair_side(c, M, spec, hx, hy, d, sway=0):
    s = spec.hair_style
    if spec.hood:
        hood = c.ellipse(hx + 0.5, hy - 0.5, d['rx'] + 1.4, d['ry'] + 1.2) & ~c.ellipse(hx - 2.5, hy + 1.5, 3.5, 4.5)
        c.paint(hood, M['shirt'])
        return
    xx, yy = c.grid()
    if s == 'short':
        cap = c.ellipse(hx + 0.8, hy - 1.5, d['rx'] + 0.6, d['ry'] - 0.6) & ((yy < hy - 0.5) | (xx > hx + 1))
        c.paint(cap, M['hair'])
        c.paint(c.rect(hx - 5, hy - 2, hx - 3, hy - 1), M['hair'])
        c.set_tone(c.rect(hx - 2, hy - 5, hx, hy - 5), 4)
    elif s in ('bun_old', 'bun'):
        cap = c.ellipse(hx + 1, hy - 2.5, d['rx'] + 0.2, d['ry'] - 2) & ((yy < hy - 1.5) | (xx > hx + 2))
        c.paint(cap, M['hair'])
        c.paint(c.ellipse(hx + 3, hy - 6, 2.4, 2.0), M['hair'])
    elif s in ('braid', 'tied'):
        cap = c.ellipse(hx + 0.8, hy - 1.2, d['rx'] + 0.6, d['ry'] - 0.4) & ((yy < hy) | (xx > hx + 1))
        c.paint(cap, M['hair'])
        c.paint(c.line([(hx + 5.5, hy + 1), (hx + 5.5 + sway, hy + 14)], 2), M['hair'])
        c.paint(c.rect(hx + 5 + (sway > 0), hy + 8, hx + 6 + (sway > 0), hy + 8), M['band'])
    elif s == 'pigtails':
        cap = c.ellipse(hx + 0.8, hy - 1.5, d['rx'] + 0.4, d['ry'] - 1) & ((yy < hy - 0.5) | (xx > hx + 1))
        c.paint(cap, M['hair'])
        c.paint(c.ellipse(hx + 6, hy + 1, 1.8, 3), M['hair'])
    elif s == 'tuft':
        c.paint(c.ellipse(hx + 1, hy - 5.5, 1.8, 1.6), M['hair'])
    elif s == 'scarf':
        sc = c.ellipse(hx + 0.5, hy - 1, d['rx'] + 1.2, d['ry'] + 0.6) & ~c.ellipse(hx - 2.5, hy + 1.5, 3.6, 4.4)
        c.paint(sc, M['band'])
    if spec.headband:
        c.paint(c.rect(hx - 5, hy - 2, hx + 5, hy - 1), M['band'])
        c.paint(c.line([(hx + 5.5, hy - 1), (hx + 7.5 + sway, hy + 2)], 2), M['band'])


def _near_arm(c, M, spec, cx, top, a, pose, tool):
    sh = (cx - 1, top + 1)  # shoulder
    def arm_to(hx, hy, width=2):
        c.paint(c.line([sh, (hx, hy)], width + 1), M['sleeve'])
        c.paint(c.rect(hx - 1, hy - 1, hx, hy), M['skin'])

    def axe(handle_from, handle_to, head_at, head_dir):
        c.paint(c.line([handle_from, handle_to], 1), M['wood'])
        hx, hy = head_at
        if head_dir == 'up':
            c.paint(c.poly([(hx - 1, hy), (hx + 2, hy - 3), (hx + 3, hy + 1), (hx + 1, hy + 2)]), M['tool'])
        elif head_dir == 'down':
            c.paint(c.poly([(hx - 3, hy - 1), (hx + 1, hy - 2), (hx + 1, hy + 2), (hx - 2, hy + 3)]), M['tool'])
        else:  # 'left'
            c.paint(c.poly([(hx - 3, hy - 3), (hx, hy - 2), (hx, hy + 1), (hx - 3, hy + 2)]), M['tool'])

    def broom(base, tip):
        c.paint(c.line([base, tip], 1), M['wood'])
        bx, by = tip
        c.paint(c.poly([(bx - 4, by + 1), (bx + 3, by - 1), (bx + 4, by + 4), (bx - 5, by + 5)]), c.material(STRAW))

    if pose is None or pose in ('idle', 'walk'):
        x0 = cx - 2 + a
        c.paint(c.rect(x0, top + 1, x0 + 2, top + 8), M['sleeve'])
        c.paint(c.rect(x0, top + 9, x0 + 2, top + 10), M['skin'])
        return
    if pose == 'ready':
        arm_to(cx - 5, top + 9)
        if tool == 'axe':
            axe((cx - 5, top + 9), (cx - 10, top + 3), (cx - 11, top + 2), 'left')
        elif tool == 'sword':
            c.paint(c.line([(cx - 5, top + 9), (cx - 13, top + 1)], 1), M['tool'])
    elif pose == 'windup':
        arm_to(cx + 3, top - 6)
        if tool == 'axe':
            axe((cx + 3, top - 6), (cx + 8, top - 10), (cx + 8, top - 11), 'up')
        elif tool == 'sword':
            c.paint(c.line([(cx + 3, top - 6), (cx + 11, top - 13)], 1), M['tool'])
    elif pose == 'strike':
        arm_to(cx - 7, top + 6)
        if tool == 'axe':
            axe((cx - 7, top + 6), (cx - 12, top + 13), (cx - 12, top + 15), 'down')
        elif tool == 'sword':
            c.paint(c.line([(cx - 7, top + 6), (cx - 15, top + 13)], 1), M['tool'])
    elif pose == 'follow':
        arm_to(cx - 6, top + 10)
        if tool == 'axe':
            axe((cx - 6, top + 10), (cx - 9, top + 18), (cx - 9, top + 20), 'down')
    elif pose == 'sweep_wind':
        arm_to(cx + 5, top + 7)
        if tool == 'axe':
            axe((cx + 5, top + 7), (cx + 12, top + 9), (cx + 13, top + 9), 'up')
    elif pose == 'sweep_strike':
        arm_to(cx - 8, top + 8)
        if tool == 'axe':
            axe((cx - 8, top + 8), (cx - 14, top + 9), (cx - 14, top + 9), 'left')
    elif pose == 'guard':
        arm_to(cx - 4, top + 5)
        if tool == 'axe':
            c.paint(c.line([(cx - 5, top - 2), (cx - 5, top + 12)], 1), M['wood'])
            axe((cx - 5, top - 2), (cx - 5, top - 2), (cx - 6, top - 3), 'up')
    elif pose == 'hurt':
        arm_to(cx + 4, top + 4)
    elif pose == 'item':
        arm_to(cx - 4, top + 1)
        c.paint(c.ellipse(cx - 5, top, 2, 1.6), c.material(CLOTH_GREEN))
    elif pose == 'kneel':
        arm_to(cx - 4, top + 9)
    elif pose == 'broom_a':
        arm_to(cx + 3, top + 8)
        broom((cx + 3, top + 6), (cx + 10, GROUND - 4))
    elif pose == 'broom_b':
        arm_to(cx - 5, top + 8)
        broom((cx - 4, top + 6), (cx - 11, GROUND - 4))
    elif pose == 'give':
        arm_to(cx - 8, top + 6)
        c.paint(c.ellipse(cx - 10, top + 5, 2.2, 1.8), c.material(CLOTH_GREEN))
    elif pose == 'bandage':
        arm_to(cx - 7, top + 7)
        c.paint(c.rect(cx - 9, top + 6, cx - 8, top + 8), c.material(CLOTH_CREAM))
    elif pose == 'windup_deep':
        # the blade drawn far back over the shoulder, held: the charge of a stroke
        arm_to(cx + 5, top - 8)
        if tool == 'axe':
            axe((cx + 5, top - 8), (cx + 10, top - 11), (cx + 11, top - 12), 'up')
    elif pose == 'smear':
        # strike frame with a pale smear arc trailing the blade
        sm = c.material(ramp('#efe9dc', shadow='#d8d0c0', light='#ffffff', outline='#efe9dc'), flat=True, outline=False)
        c.paint(c.line([(cx + 9, top - 11), (cx + 3, top - 9), (cx - 6, top - 3), (cx - 12, top + 4), (cx - 15, top + 11)], 2), sm)
        c.paint(c.line([(cx + 5, top - 6), (cx - 4, top + 1), (cx - 10, top + 8)], 1), sm)
        arm_to(cx - 8, top + 8)
        if tool == 'axe':
            axe((cx - 8, top + 8), (cx - 14, top + 13), (cx - 15, top + 14), 'down')
    elif pose == 'recover':
        arm_to(cx - 4, top + 11)
        if tool == 'axe':
            axe((cx - 4, top + 11), (cx - 7, top + 18), (cx - 8, top + 19), 'down')
    elif pose == 'sweep_smear':
        sm = c.material(ramp('#efe9dc', shadow='#d8d0c0', light='#ffffff', outline='#efe9dc'), flat=True, outline=False)
        c.paint(c.line([(cx + 11, top + 6), (cx + 2, top + 9), (cx - 13, top + 9)], 2), sm)
        arm_to(cx - 9, top + 8)
        if tool == 'axe':
            axe((cx - 9, top + 8), (cx - 15, top + 8), (cx - 16, top + 8), 'left')
    elif pose == 'parry':
        arm_to(cx - 5, top + 4)
        if tool == 'axe':
            c.paint(c.line([(cx - 8, top - 4), (cx - 4, top + 12)], 1), M['wood'])
            axe((cx - 8, top - 4), (cx - 8, top - 4), (cx - 9, top - 5), 'up')
    elif pose == 'hurt_b':
        arm_to(cx + 6, top + 2)
    elif pose == 'thau':
        arm_to(cx - 10, top + 5)
        c.paint(c.rect(cx - 13, top + 4, cx - 11, top + 6), M['skin'])
        c.paint(c.px(cx - 14, top + 4), M['skin'])
    elif pose == 'victory':
        arm_to(cx + 1, top + 4)
        if tool == 'axe':
            axe((cx + 1, top + 4), (cx + 7, top - 4), (cx + 8, top - 5), 'up')


# ---------------------------------------------------------------- sheets
WALK_FRONT = [  # (legs lift L,R), (arm L,R), bob
    ((0, 0), (0, 0), 0),
    ((0, 0), (0, 0), 1),
    ((2, 0), (1, -1), 1),
    ((0, 0), (0, 0), 0),
    ((0, 2), (-1, 1), 1),
    ((0, 0), (0, 0), 0),
]
WALK_SIDE = [  # legs (front_dx, back_dx), arms (near_dx, far_dx), bob
    ((0, 0), (0, 0), 0),
    ((0, 0), (0, 0), 1),
    ((-3, 3), (2, -2), 0),
    ((0, 0), (0, 0), 1),
    ((3, -3), (-2, 2), 0),
    ((0, 0), (0, 0), 1),
]


def _r(c, spec):
    if spec.statue:
        return c.render(side_shade=0.35, shadow_band=2, volume=True, selout=True, deep=True)
    return c.render(volume=True, side_shade=0.34, side_light=0.2, selout=True, deep=True)


def frame_front(spec, view, i, pose=None):
    legs, arms, bob = WALK_FRONT[i]
    return _r(_front(spec, view, legs, arms, bob, pose=pose), spec)


def frame_side(spec, i, pose=None):
    legs, arms, bob = WALK_SIDE[i]
    return _r(_side(spec, legs, arms, bob, pose=pose), spec)


# ---------------------------------------------------------------- animated sheet
# columns: 0-3 idle (breathing), 4 blink, 5-12 walk (8), 13-18 run (6)
IDLE_N, WALK_N, RUN_N = 4, 8, 6
SHEET_COLS = IDLE_N + 1 + WALK_N + RUN_N
WALK_BOB = (0, 1, 0, -1, 0, 1, 0, -1)
RUN_BOB = (1, 0, -1, 1, 0, -1)


def _cos(i, n, shift=0.0):
    return math.cos(2 * math.pi * (i / n + shift))


def _sin(i, n, shift=0.0):
    return math.sin(2 * math.pi * (i / n + shift))


def _front_frame(kind, i):
    if kind == 'idle':
        b = (0, 0, 1, 1)[i]
        return dict(bob=b, lift=(0, 0), fy=(0, 0), back=(0, 0), arm=(0, 0), armx=(0, 0), sway=(0, 0, 1, 1)[i])
    n = WALK_N if kind == 'walk' else RUN_N
    lift_amp = 3.0 if kind == 'walk' else 4.0
    lifts, fys, backs, arms, armxs = [], [], [], [], []
    for leg in range(2):
        sh = 0.0 if leg == 0 else 0.5
        fwd = _cos(i, n, sh)
        lifts.append(int(round(max(0.0, -_sin(i, n, sh)) * lift_amp)))
        fys.append(1 if fwd > 0.5 else (-1 if fwd < -0.5 else 0))
        backs.append(1 if fwd < -0.2 else 0)
    for arm_ in range(2):
        fwd = _cos(i, n, 0.5 if arm_ == 0 else 0.0)  # arms swing against the legs
        big = 2 if kind == 'run' else 1
        arms.append(-big if fwd < -0.5 else (1 if fwd > 0.5 and kind == 'run' else 0))
        armxs.append(1 if fwd > 0.5 else 0)
    bob = (WALK_BOB if kind == 'walk' else RUN_BOB)[i]
    prev = (WALK_BOB if kind == 'walk' else RUN_BOB)[i - 1]
    return dict(bob=bob, hb=(prev - bob) + (1 if kind == 'run' else 0), lift=tuple(lifts), fy=tuple(fys),
                back=tuple(backs), arm=tuple(arms), armx=tuple(armxs), sway=1 if bob < 0 else 0,
                stance=0)


def _side_frame(kind, i):
    if kind == 'idle':
        b = (0, 0, 1, 1)[i]
        return dict(bob=b, feet=[(0, 0), (1, 0)], hands=[(-0.5, 0), (1.5, 0)], sway=(0, 0, 1, 1)[i])
    if kind == 'walk':
        n, stride, lift, swing = WALK_N, 4.5, 3.0, 3.6
    else:
        n, stride, lift, swing = RUN_N, 6.5, 4.5, 5.0
    feet = []
    for leg in range(2):
        sh = 0.0 if leg == 0 else 0.5
        dx = -stride * _cos(i, n, sh)
        lf = max(0.0, -_sin(i, n, sh)) * lift
        feet.append((int(round(dx)), int(round(lf))))
    hands = []
    for arm_ in range(2):
        sh = 0.0 if arm_ == 0 else 0.5
        c_ = _cos(i, n, sh)
        if kind == 'walk':
            hands.append((swing * c_, -abs(c_) * 1.2))
        else:
            hands.append((swing * c_ - 1.0, -3.5 - abs(c_)))
    bob = (WALK_BOB if kind == 'walk' else RUN_BOB)[i]
    prev = (WALK_BOB if kind == 'walk' else RUN_BOB)[i - 1]
    return dict(bob=bob, hb=prev - bob, feet=feet, hands=hands, lean=0 if kind == 'walk' else -2,
                sway=1 if bob < 0 else 0)


def anim_frame(spec, row, kind, i, blink=False):
    if row in ('down', 'up'):
        fr = _front_frame(kind, i)
        fr['blink'] = blink
        return _r(_front(spec, row, fr=fr, bob=fr['bob']), spec)
    fr = _side_frame(kind, i)
    fr['blink'] = blink
    im = _r(_side(spec, fr=fr), spec)
    return ImageOps.mirror(im) if row == 'right' else im


def build_walk_sheet(spec):
    frames = []
    for row in ('down', 'left', 'right', 'up'):
        for i in range(IDLE_N):
            frames.append(anim_frame(spec, row, 'idle', i))
        frames.append(anim_frame(spec, row, 'idle', 0, blink=row != 'up'))
        for i in range(WALK_N):
            frames.append(anim_frame(spec, row, 'walk', i))
        for i in range(RUN_N):
            frames.append(anim_frame(spec, row, 'run', i))
    from pix import sheet
    return sheet(frames, SHEET_COLS)


def action(spec, pose, tool=None, legs=(-2, 3), bob=0, lean=0):
    if pose == 'kneel':
        legs, bob, lean = (-4, 4), 5, -1
    elif pose == 'hurt':
        legs, bob, lean = (-1, 2), 1, 2
    elif pose in ('strike', 'follow', 'sweep_strike'):
        lean = lean - 1
        bob = bob + 1
    elif pose == 'ready_b':
        pose, bob = 'ready', bob + 1
    elif pose == 'windup_deep':
        legs, bob, lean = (-3, 4), 1, 1
    elif pose in ('smear', 'sweep_smear'):
        legs, bob, lean = (-4, 4), 1, -2
    elif pose == 'recover':
        legs, bob, lean = (-3, 3), 1, -1
    elif pose == 'parry':
        legs, lean = (-3, 3), -1
    elif pose == 'hurt_b':
        legs, bob, lean = (-1, 3), 2, 3
    elif pose == 'thau':
        legs, lean = (-2, 3), -1
    elif pose == 'victory':
        legs, bob = (0, 1), 0
    c = _side(spec, legs=legs, bob=bob, pose=pose, tool=tool, lean=lean)
    if pose == 'kneel':
        # fold the legs: erase the lower shins and draw a kneeling shin along the ground
        c.erase(c.rect(0, GROUND - 6, W - 1, GROUND + 2))
        m = 3  # pants material index (see _mk order)
        c.paint(c.rect(9, GROUND - 2, 19, GROUND - 1), m)
        c.paint(c.rect(18, GROUND - 1, 21, GROUND), 5)
    return _r(c, spec)


def front_pose(spec, pose, view='down'):
    return _r(_front(spec, view, pose=pose), spec)


# ---------------------------------------------------------------- the title: sitting with the sword, the cut
SWORD_POSES = ('sword_sit', 'sword_pull', 'sword_stand', 'sword_wind', 'sword_up', 'sword_cut_a', 'sword_cut',
               'sword_cut_b', 'sword_follow', 'sword_settle')
# the sword: a steel blade with a bright edge, a brass guard and pommel, a grip wrapped in dark cord
BLADE = ramp('#aab3bd', shadow='#77818c', light='#dce3e9', outline='#2c3138', hi='#ffffff')
BRASS = ramp('#a8823e', shadow='#7a5a28', light='#d0aa5c', outline='#3a2810', hi='#f0d590')
WRAP = ramp('#2c2a33', shadow='#1b1a21', light='#4a4754', outline='#0c0b10')
TW, TH, TOX, TOY = 64, 64, 16, 16     # the title frames: a bigger canvas, the figure where it is in a 32x48 frame


def _grow(c, w, h, ox, oy):
    """Put a canvas's painting in a bigger canvas (room for a sword held out or raised)."""
    for name, fill in (('mat', -1), ('tone', 0), ('order', 0)):
        a = getattr(c, name)
        b = np.full((h, w), fill, a.dtype)
        b[oy:oy + c.h, ox:ox + c.w] = a
        setattr(c, name, b)
    c.w, c.h = w, h


def _title_sword(c, pommel, tip, mats):
    """The sword from pommel to tip: a wrapped grip (4 px), a brass guard across, the blade tapering to its point,
    its edge bright along the side toward the light."""
    blade_m, brass_m, wrap_m = mats
    px, py = pommel
    tx, ty = tip
    L = ((tx - px) ** 2 + (ty - py) ** 2) ** 0.5
    ux, uy = (tx - px) / L, (ty - py) / L
    nx, ny = -uy, ux                      # across the blade
    if nx > 0:                            # the side toward the upper left (the light)
        nx, ny = -nx, -ny
    guard = (px + ux * 5, py + uy * 5)
    taper = (guard[0] + (tx - guard[0]) * 0.8, guard[1] + (ty - guard[1]) * 0.8)
    grip = c.line([(px + ux, py + uy), guard], 2)
    c.paint(grip, wrap_m)
    for k in range(1, 5, 2):              # the cord wound round it
        c.set_tone(c.px(int(round(px + ux * k)), int(round(py + uy * k))) & grip, 3)
    c.paint(c.px(int(round(px)), int(round(py))), brass_m)
    blade = c.line([guard, taper], 2) | c.line([taper, tip], 1)
    c.paint(blade, blade_m)
    edge = c.line([(guard[0] + nx * 0.7, guard[1] + ny * 0.7), (taper[0] + nx * 0.7, taper[1] + ny * 0.7)], 1)
    c.set_tone(edge & blade, 4)
    c.set_tone(c.line([guard, tip], 1) & blade & ~edge, 3)
    gd = c.line([(guard[0] - nx * 3, guard[1] - ny * 3), (guard[0] + nx * 3, guard[1] + ny * 3)], 1)
    c.paint(gd, brass_m)


def _sword_frame(spec, pose, bob=0):
    """The protagonist seen from behind (the title's vista), with the sword. Their right hand is on our right.
    Sitting is the walking figure's sitting pose with the sword beside it; the poses on the feet are _title_figure."""
    if pose != 'sword_sit':
        return _title_figure(spec, pose)
    c = _front(spec, 'up', bob=bob, pose=pose)
    _grow(c, TW, TH, TOX, TOY)
    # the materials _mk made, in its order
    names = ['skin', 'hair', 'shirt', 'pants', 'sash', 'shoe', 'eye', 'hat', 'band', 'beard', 'crack', 'patch', 'tool', 'wood', 'sleeve']
    M = {n: i for i, n in enumerate(names)}
    d = _dims(spec)
    top = d['top'] + bob + spec.hunch
    bot = d['bot'] + bob
    top += GROUND - 4 - bot
    cx = 16 + TOX
    top += TOY
    sw = d['sw']
    rs = (cx + sw - 1, top + 1)      # right shoulder
    ls = (cx - sw, top + 1)          # left shoulder

    def arm(sh, hand):
        c.paint(c.line([sh, hand], 3), M['sleeve'])
        c.paint(c.rect(hand[0] - 1, hand[1] - 1, hand[0], hand[1]), M['skin'])

    mats = tuple(c.material(_octo(r)) for r in (BLADE, BRASS, WRAP))
    # seated, the sword planted point down in the rock at the right side, the hand resting on its hilt; the left
    # hand on the knee
    arm(ls, (cx - sw - 2, top + 9))
    h = (cx + sw + 4, top - 3)
    _title_sword(c, (h[0], h[1] - 3), (h[0] + 1, GROUND + TOY - 1), mats)
    arm(rs, h)
    return c


def _rnd(v):
    return int(math.floor(v + 0.5))


def _strip(c, pts, w=3):
    """A limb w pixels thick along a polyline, laid as runs of w pixels across each row (or down each column where
    it runs flatter than 45 degrees): clean stair steps, the same thickness at any angle, a square at each joint."""
    m = np.zeros((c.h, c.w), bool)
    lo = (w - 1) / 2.0

    def run(x, y, steep):
        if steep:
            yy, x0 = _rnd(y), _rnd(x - lo)
            if 0 <= yy < c.h:
                m[yy, max(0, x0):max(0, min(c.w, x0 + w))] = True
        else:
            xx, y0 = _rnd(x), _rnd(y - lo)
            if 0 <= xx < c.w:
                m[max(0, y0):max(0, min(c.h, y0 + w)), xx] = True

    for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
        dx, dy = bx - ax, by - ay
        steep = abs(dy) >= abs(dx)
        n = max(1, _rnd(abs(dy) if steep else abs(dx)))
        for k in range(n + 1):
            run(ax + dx * k / n, ay + dy * k / n, steep)
    for (x, y) in pts[1:-1]:
        x0, y0 = _rnd(x - lo), _rnd(y - lo)
        m[max(0, y0):max(0, y0 + w), max(0, x0):max(0, x0 + w)] = True
    return m


def _spline(keys, s):
    """The value at s of a smooth curve through keys [(s, value), ...]: a cubic through each pair of keys, its
    slope at a key that of the keys either side (no overshoot between them)."""
    n = len(keys)
    i = 0
    while i < n - 2 and s > keys[i + 1][0]:
        i += 1
    (s0, v0), (s1, v1) = keys[i], keys[i + 1]

    def slope(j):
        a, b = keys[max(j - 1, 0)], keys[min(j + 1, n - 1)]
        return (b[1] - a[1]) / (b[0] - a[0])

    h = s1 - s0
    t = (s - s0) / h
    m0, m1 = slope(i) * h, slope(i + 1) * h
    return ((2 * t ** 3 - 3 * t ** 2 + 1) * v0 + (t ** 3 - 2 * t ** 2 + t) * m0 + (-2 * t ** 3 + 3 * t ** 2) * v1
            + (t ** 3 - t ** 2) * m1)


# The swings of the cut, for the trails it leaves: along each (s, 0 to 1) where the guard is, the blade's angle on
# screen (degrees, y down) and its length on screen. Both begin with the blade standing up to the right over the
# head, where the arc of light starts. 'over' ends where frame 6 has it: the hands come over past the left of the head
# on their way down, the blade tipping over to the upper left, partly away from us so it looks shorter. 'cut' goes
# on down to where it lands at the low left (frame 7, at 1), its point drawing one even arc; halfway it points ahead
# and down past the left of the head, away from us, so it is short then; at 1.2 it has run on toward the ground
# (frame 8). The sword in those frames is put where its swing says, so the light always leaves from the blade.
TITLE_SWINGS = {
    'over': [(0.0, 38.0, 22.0, -55.0, 18.0), (0.5, 28.7, 23.1, -105.9, 15.2), (1.0, 21.0, 26.0, -150.0, 13.0)],
    'cut': [(0.0, 38.0, 22.0, -55.0, 18.0), (0.5, 25.0, 30.0, -160.0, 9.0), (1.0, 11.5, 50.5, -225.0, 11.0),
            (1.2, 12.0, 52.0, -240.0, 9.0)],
}


def _swing_at(swing, s):
    """(guard x, guard y, angle in degrees, length) of the blade at s along a swing of the cut."""
    keys = TITLE_SWINGS[swing]
    return tuple(_spline([(k[0], k[i]) for k in keys], s) for i in range(1, 5))


def _swing_sword(swing, s):
    """The sword (pommel, tip) where a swing of the cut has it at s."""
    gx, gy, ang, L = _swing_at(swing, s)
    ux, uy = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    return ((gx - ux * 5, gy - uy * 5), (gx + ux * L, gy + uy * L))


# The poses on the feet, seen from behind: the camera is behind and a little above, so a foot set forward (away from
# us) sits higher in the frame than the one behind, which keeps to the ground line (its sole on y=61).
#   hip: the middle of the hips (x as the torso's cx) and where the legs leave the tunic; the tunic ends a pixel lower
#   legs: left then right, each [hip joint, knee, ankle] or [hip joint, ankle]; the shoe below the ankle
#   far: the leg set forward (painted first, in shade); heel: the back heel lifted, the toe pushing off
#   top: the torso's top (the shoulders), sx its middle there (leaning over the hips), sw half its width there (less
#   when it turns), tilt: how far (left, right) each shoulder drops
#   seam: where the spine shows, moved by the turn (turned to their right it moves to our left)
#   head: its middle; tails: where the ends of the headband blow, from the knot
#   sword: (pommel, tip); larm, rarm: the joints between the shoulder and the hand; lhand, rhand: a free hand (else
#   the left hand holds the grip by the pommel, the right by the guard)
#   order: what is painted first (farthest from us) to last; Lu/Lf, Ru/Rf: an upper arm or a forearm alone
TITLE_BODY = {
    # rising from the rock: knees still bent and wide, leaning over them, the sword drawn up in the right hand with
    # its point just leaving the stone; the left hand pushing on the left knee
    'sword_pull': dict(hip=(32, 50), legs=([(29, 50), (26, 54), (26, 59)], [(34, 50), (37, 54), (37, 59)]),
                       far=None, top=39, sx=32, head=(32, 34),
                       sword=((41, 40), (43, 60)), larm=[(24, 45)], lhand=(25, 51), rarm=[],
                       order=['legs', 'torso', 'head', 'L', 'sword', 'R', 'rhand']),
    # up, the feet set apart, the left a little ahead, the knees soft; both hands on the grip low at the right hip,
    # the blade slanting down ahead of the right foot; the left arm reaching across in front
    'sword_stand': dict(hip=(32, 47), legs=([(29, 47), (27, 58)], [(34, 47), (37, 59)]),
                        far=0, top=35, sx=32, head=(32, 29),
                        sword=((39, 42), (51, 57)), larm=[(24, 42), (30, 45)], rarm=[(40, 41)],
                        order=['Lf', 'legs', 'torso', 'Lu', 'head', 'sword', 'R', 'hands']),
    # the wind-up: sunk low over the bent right leg, the left reaching forward, the body coiled to the right; both
    # hands high over the right shoulder, the right elbow out, the left arm across in front of the face; the blade
    # laid back across the head and shoulders, its point out past the left shoulder
    'sword_wind': dict(hip=(35, 51), legs=([(32, 51), (29, 54), (25, 57)], [(37, 51), (41, 55), (41, 59)]),
                       far=0, top=39, sx=38, sw=5, tilt=(-1, 2), seam=-2, head=(37, 34),
                       sword=((48, 25), (22, 42)), larm=[(32, 33)], rarm=[(50, 33)],
                       order=['legs', 'torso', 'L', 'head', 'R', 'sword', 'hands']),
    # the blade coming over: the weight swinging left off the right leg, the body leaning after it and starting to
    # turn; the hands come over past the left of the head on their way down (the right arm across in front of the
    # face, the left up beside it), the blade tipping over to the upper left; behind it the arc of light it is
    # drawing, from where it stood up to the right
    'sword_cut_a': dict(hip=(31, 50), legs=([(28, 50), (25, 54), (23, 57)], [(33, 50), (37, 54), (39, 59)]),
                        far=0, top=38, sx=28, tilt=(2, -1), seam=1, head=(29, 32), tails=(3, 2),
                        sword=_swing_sword('over', 1.0), larm=[(18, 34)], rarm=[(30, 31)],
                        order=['legs', 'torso', 'R', 'head', 'L', 'sword', 'hands'],
                        trails=[dict(swing='over', s0=0.0, s1=1.0, f_head=0.35, f_tail=1.0, tones=(1, 2, 3, 4))]),
    # the cut lands: lunged onto the bent left knee, the right leg driven out straight behind, the body thrown
    # forward and down to the left after the blade, turned to the left; both arms driven down to the low left (the
    # right one across under the left), the blade going on from them in the same line; behind it the arc its point
    # drew, from the upper right over and down to it
    'sword_cut': dict(hip=(30, 51), legs=([(27, 51), (23, 53), (21, 57)], [(32, 51), (39, 58)]),
                      far=0, heel=True, top=40, sx=26, sw=5, tilt=(2, 0), seam=2, head=(25, 35), tails=(5, -1),
                      sword=_swing_sword('cut', 1.0), larm=[], rarm=[(27, 47)],
                      order=['R', 'legs', 'torso', 'head', 'sword', 'L', 'hands'],
                      trails=[dict(swing='cut', s0=0.0, s1=1.0, f_head=0.2, f_tail=1.0, tones=(1, 1, 2, 2, 3, 4))]),
    # just after: the same lunge a pixel deeper, the blade run on past the low left toward the ground, the arc
    # thinning and paling behind it
    'sword_cut_b': dict(hip=(29, 52), legs=([(26, 52), (23, 54), (21, 57)], [(31, 52), (39, 58)]),
                        far=0, heel=True, top=41, sx=25, sw=5, tilt=(2, 0), seam=2, head=(24, 36), tails=(5, 1),
                        sword=_swing_sword('cut', 1.2), larm=[], rarm=[(27, 49)],
                        order=['R', 'legs', 'torso', 'head', 'sword', 'L', 'hands'],
                        trails=[dict(swing='cut', s0=0.3, s1=1.0, f_head=0.85, f_tail=1.0, tones=(None, None, 1, 1, 2)),
                                dict(swing='cut', s0=1.0, s1=1.2, f_head=0.5, f_tail=0.8, tones=(1, 2))]),
    # the follow-through: coming up out of the lunge, the back heel down again, the hands at the left hip, the blade
    # still low, its point near the ground
    'sword_follow': dict(hip=(30, 50), legs=([(27, 50), (24, 54), (22, 57)], [(32, 50), (38, 59)]),
                         far=0, top=38, sx=28, seam=1, head=(28, 32), tails=(2, 4),
                         sword=((21, 45), (8, 59)), larm=[(18, 42)], rarm=[(31, 46)],
                         order=['R', 'legs', 'torso', 'head', 'sword', 'L', 'hands']),
    # at rest: upright on a wide stance, the left foot still ahead; both hands low at the left hip, the blade let
    # down ahead of the left foot, the point to the ground
    'sword_settle': dict(hip=(31, 47), legs=([(28, 47), (25, 58)], [(33, 47), (37, 59)]),
                         far=0, top=35, sx=30, seam=1, head=(30, 29),
                         sword=((24, 43), (15, 60)), larm=[(20, 40)], rarm=[(31, 44)],
                         order=['R', 'legs', 'torso', 'head', 'sword', 'L', 'hands']),
}

# frame 5 (sword_up, unused by the cut): the blade coming over, without its light
TITLE_BODY['sword_up'] = {k: v for k, v in TITLE_BODY['sword_cut_a'].items() if k != 'trails'}

# the trail of light behind the blade: white at its brightest, a pale cold blue where it fades
TRAIL = ramp('#d7e4ef', shadow='#a4b8cb', light='#f1f6fa', outline='#d7e4ef', hi='#ffffff')
# The same trail as light (title_trail_frames): the game draws it unshaded over the lit figure, so these colours are
# what is seen against the cloud (a light blue grey). Every tone stays lighter and colder than the cloud: white where
# the blade is, then blue white, paling to a cold pale blue toward the tail; the white is held inside a rim of the
# blue white, so the band keeps its edge even where the cloud is brightest.
TRAIL_LIGHT = {4: '#ffffff', 3: '#eef7ff', 2: '#d8ecff', 1: '#c6e2fc'}


def _title_figure(spec, pose):
    """The protagonist from behind on their feet, with the sword in both hands from the wind-up to the end of the cut
    (title frames 2-10), placed by TITLE_BODY. The blade coming over and the cut leave a trail of light: the band the
    blade swept, bright and wide at the blade and thinning to nothing where it began."""
    c, M = _mk(spec, TW, TH)
    d = _dims(spec)
    B = TITLE_BODY[pose]
    mats = tuple(c.material(_octo(r)) for r in (BLADE, BRASS, WRAP))
    trail_m = c.material(TRAIL, flat=True, outline=False)
    sx, top, sw = B['sx'], B['top'], B.get('sw', d['sw'])
    tl, tr = B.get('tilt', (0, 0))
    hx, hy = B['hip']
    pommel, tip = B['sword']

    def on_grip(k):
        """The point k pixels along the grip from the pommel (the hands hold it at about 2 and 4)."""
        L = math.hypot(tip[0] - pommel[0], tip[1] - pommel[1])
        return (_rnd(pommel[0] + (tip[0] - pommel[0]) * k / L), _rnd(pommel[1] + (tip[1] - pommel[1]) * k / L))

    lhand = B.get('lhand') or on_grip(2)
    rhand = B.get('rhand') or on_grip(4)
    larm = [(sx - sw - 1, top + 1 + tl)] + B['larm'] + [lhand]     # from the middle of the sleeve at the shoulder
    rarm = [(sx + sw, top + 1 + tr)] + B['rarm'] + [rhand]

    def legs():
        far = B['far']
        for i in sorted((0, 1), key=lambda i: 0 if i == far else 1):
            pts = B['legs'][i]
            side = (-1, 1)[i]
            c.paint(_strip(c, pts, 3), M['pants'], tone=1 if i == far else 0)
            ax, ay = pts[-1]
            if B.get('heel') and i != far:
                # the heel up, the toe pushing: we see the sole, standing on its end
                c.paint(c.rect(ax - 1, ay + 1, ax + 1, ay + 3), M['shoe'])
            else:
                c.paint(c.rect(ax - 1 - (side < 0), ay + 1, ax + 1 + (side > 0), ay + 2), M['shoe'],
                        tone=1 if i == far else 0)

    def torso():
        hem = hy + 1
        seam = B.get('seam', 0)
        m = c.poly([(sx - sw, top + tl), (sx + sw - 1, top + tr), (hx + d['sw'], hem), (hx - d['sw'] - 1, hem)])
        c.paint(m, M['shirt'])
        # the seam down the back, and a fold where the tunic gathers above the sash
        c.set_tone(c.line([(sx - 1 + seam, top + 2), (hx - 1 + seam, hem - 1)], 1) & m, 1)
        c.set_tone(c.line([(hx - 2 + seam, hem - 2), (hx - 3 + seam, hem)], 1) & m, 1)
        if spec.sash:
            c.paint(m & c.rect(0, hem - 4, TW - 1, hem - 3), M['sash'])

    def head():
        x, y = B['head']
        c.paint(c.rect(x - 1, y + 5, x, y + 6), M['skin'])
        c.paint(c.ellipse(x, y, d['rx'], d['ry']), M['skin'])
        _hair_front(c, M, spec, 'up', x, y, d)
        if spec.headband and B.get('tails'):
            # the ends of the headband thrown out behind the head as it moves
            c.paint(c.rect(x + 1, y, x + 2, y + 4) & (c.mat == M['band']), M['hair'])
            tx, ty = B['tails']
            c.paint(_strip(c, [(x + 1.5, y - 1), (x + 1.5 + tx, y - 1 + ty)], 2), M['band'])
        _head_detail(c, M, spec, 'up', x, y, d)

    def sleeve(pts):
        c.paint(_strip(c, pts, 3), M['sleeve'])

    def hand(p):
        c.paint(c.rect(p[0] - 1, p[1] - 1, p[0], p[1]), M['skin'])

    def trail(swing, s0, s1, f_head, f_tail, tones, n=240):
        """The band the blade swept from s0 to s1 along a swing of the cut (TITLE_SWINGS): from f along the blade out
        to its tip, f falling from f_tail (only the tip, at the oldest end) to f_head (most of the blade, where it is
        now); toned by age, the newest brightest (tones from oldest to newest, None for none). Only where nothing is
        (it is beyond the figure), a pixel off everything so the outline keeps between them."""
        age = np.full((TH, TW), -1.0)
        for k in range(n + 1):
            u = k / n
            gx, gy, ang, L = _swing_at(swing, s0 + (s1 - s0) * u)
            ux, uy = math.cos(math.radians(ang)), math.sin(math.radians(ang))
            f = f_tail + (f_head - f_tail) * u ** 1.5
            seg = c.line([(gx + ux * L * f, gy + uy * L * f), (gx + ux * L, gy + uy * L)], 2)
            age[seg] = np.maximum(age[seg], u)
        filled = c.mat >= 0
        p = np.pad(filled, 1)
        near = filled | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
        free = (age >= 0) & ~near
        edges = np.linspace(0, 1, len(tones) + 1)
        for i, t in enumerate(tones):
            if t is not None:
                c.paint(free & (age >= edges[i]) & (age <= edges[i + 1]), trail_m, tone=t)

    for part in B['order']:
        if part == 'legs':
            legs()
        elif part == 'torso':
            torso()
        elif part == 'head':
            head()
        elif part in ('L', 'R'):
            sleeve(larm if part == 'L' else rarm)
            if B.get(part.lower() + 'hand'):
                hand(lhand if part == 'L' else rhand)
        elif part in ('Lu', 'Ru'):
            sleeve((larm if part == 'Lu' else rarm)[:2])
        elif part in ('Lf', 'Rf'):
            sleeve((larm if part == 'Lf' else rarm)[1:])
        elif part == 'sword':
            _title_sword(c, pommel, tip, mats)
        elif part == 'rhand':
            hand(rhand)
        elif part == 'hands':
            hand(lhand)
            hand(rhand)
    for t in B.get('trails', ()):
        trail(**t)
    return c


# the title's frames on the feet, 2 to 10
TITLE_POSES = ('sword_pull', 'sword_stand', 'sword_wind', 'sword_up', 'sword_cut_a', 'sword_cut', 'sword_cut_b',
               'sword_follow', 'sword_settle')


def title_frames(spec):
    """The title, 64x64 each: 0-1 sitting (breathing), 2 drawing the sword from the rock as they rise, 3 standing,
    4 the wind-up (sunk low, coiled), 5 the sword up (unused by the cut), 6 the blade coming over, 7 the cut, 8 just
    after, 9 the follow-through, 10 at rest."""
    frames = []
    sit = _r(_sword_frame(spec, 'sword_sit'), spec)
    frames.append(sit)
    b = sit.copy()   # breathing: the upper body a pixel lower
    upper = sit.crop((0, 0, TW, 52))
    b.paste((0, 0, 0, 0), (0, 0, TW, 52))
    b.alpha_composite(upper, (0, 1))
    frames.append(b)
    for pose in TITLE_POSES:
        frames.append(_r(_sword_frame(spec, pose), spec))
    return frames


def title_trail_frames(spec):
    """Only the light of the cut, frame for frame over title_frames (hero_title_trail.png): the very pixels of the
    trail in each frame, in TRAIL_LIGHT, everything else clear. The game draws it unshaded on top of the lit figure,
    where it covers the trail exactly, so the trail shines instead of taking the figure's shade."""
    frames = [Image.new('RGBA', (TW, TH), (0, 0, 0, 0)) for _ in range(2)]   # sitting: no light
    for pose in TITLE_POSES:
        c = _sword_frame(spec, pose)
        out = np.zeros((TH, TW, 4), np.uint8)
        trail = np.zeros((TH, TW), bool)
        for m, r in enumerate(c.mats):
            if r is not TRAIL:
                continue
            trail |= c.mat == m
            for tone, col in TRAIL_LIGHT.items():
                sel = (c.mat == m) & (c.tone == tone)
                out[sel, :3] = hexc(col)
                out[sel, 3] = 255
        p = np.pad(trail, 1)
        inner = trail & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
        out[trail & ~inner & (c.tone >= 3), :3] = hexc(TRAIL_LIGHT[2])
        frames.append(Image.fromarray(out, 'RGBA'))
    return frames


# ---------------------------------------------------------------- characters
def specs():
    return {
        'hero': Spec(shirt=CLOTH_BROWN, pants=CLOTH_INDIGO, sash=CLOTH_RED, headband=HEADBAND,
                     hair_style='short'),
        'ong': Spec(skin=SKIN_OLD, hair=HAIR_WHITE, shirt=CLOTH_BROWN_OLD, pants=CLOTH_BLACK,
                    hair_style='bun_old', beard=True, oy=2, hunch=1, patch_cloth=True),
        'lua': Spec(shirt=CLOTH_CREAM, pants=CLOTH_BLACK, hair_style='braid', headband=CLOTH_RED,
                    patches=True),
        'baca': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_BROWN_OLD, pants=CLOTH_BLACK,
                     hair_style='scarf', headband=CLOTH_BLACK, oy=3, hunch=1, skirt=True, long_tunic=True),
        'chunam': Spec(skin=SKIN_TAN, shirt=CLOTH_BROWN, pants=CLOTH_BLACK, hat='nonla', hair_style='short',
                       rolled=True),
        'ti': Spec(kid=True, skin=SKIN_TAN, shirt=CLOTH_INDIGO, pants=CLOTH_BROWN, hair_style='tuft'),
        'na': Spec(kid=True, shirt=CLOTH_RED, pants=CLOTH_BLACK, hair_style='pigtails'),
        'peddler': Spec(skin=SKIN_TAN, shirt=CLOTH_GREEN, pants=CLOTH_BROWN, hat='nonla', hair_style='short',
                        holds='sack', rolled=True),
        'refugee_w': Spec(shirt=CLOTH_ASH, pants=CLOTH_ASH_DARK, hood=True, long_tunic=True, holds='child'),
        'refugee_m': Spec(shirt=CLOTH_ASH_DARK, pants=CLOTH_ASH, hood=True, long_tunic=True),
        'refugee_o': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_ASH, pants=CLOTH_ASH_DARK, hood=True,
                          long_tunic=True, oy=2, hunch=1, holds='cane'),
        'statue_w': Spec(statue=True, hood=True, long_tunic=True, holds='child'),
        'statue_o': Spec(statue=True, hood=True, long_tunic=True, oy=2, hunch=1, holds='cane'),
        'dan_w': Spec(shirt=CLOTH_INDIGO, pants=CLOTH_BLACK, hat='nonla', hair_style='bun', long_tunic=True,
                      sash=CLOTH_GREEN),
        'dan_m': Spec(skin=SKIN_TAN, shirt=CLOTH_CREAM, pants=CLOTH_BROWN, hat='nonla', hair_style='short',
                      rolled=True, holds='sack'),
        # ---- Bạch Sơn (docs/N_bach_son.md)
        'can': Spec(skin=SKIN_TAN, hair=HAIR_GREY, shirt=CLOTH_WHITE, pants=CLOTH_WHITE_DIM, sash=CLOTH_COBALT,
                    hat='nonla', hair_style='short', holds='cane', oy=1),
        'khamsu': Spec(shirt=CLOTH_WHITE, pants=CLOTH_WHITE, sash=CLOTH_COBALT, hood=True, long_tunic=True),
        'khiet': Spec(shirt=CLOTH_WHITE, pants=CLOTH_WHITE, sash=CLOTH_COBALT, headband=CLOTH_COBALT, hair_style='bun',
                      long_tunic=True),
        # Băng Tâm: skin white as porcelain (her Thân Nghiệt), white robe, nothing else
        'tam': Spec(skin=PORCELAIN, shirt=CLOTH_WHITE, pants=CLOTH_WHITE, hair_style='bun', long_tunic=True, skirt=True),
        'hau_cam': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_WHITE_DIM, pants=CLOTH_WHITE_DIM, hair_style='bun',
                        oy=3, hunch=1, long_tunic=True, skirt=True),
        'seo': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_WHITE_DIM, pants=CLOTH_WHITE_DIM, hair_style='short',
                    oy=2, hunch=1, rolled=True),
        'bamau': Spec(skin=SKIN_OLD, hair=HAIR_WHITE, shirt=CLOTH_WHITE, pants=CLOTH_WHITE_DIM, sash=CLOTH_GREEN,
                      hair_style='bun', oy=2, long_tunic=True, skirt=True),
        'maty': Spec(skin=SKIN_TAN, shirt=CLOTH_WHITE, pants=CLOTH_WHITE_DIM, sash=CLOTH_COBALT, hair_style='short',
                     long_tunic=True),
        'gam': Spec(skin=SKIN_TAN, shirt=CLOTH_WHITE_DIM, pants=CLOTH_WHITE_DIM, hair_style='scarf', headband=CLOTH_ASH,
                    rolled=True, long_tunic=True),
        'balanh': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_ASH, pants=CLOTH_ASH_DARK, hair_style='scarf',
                       headband=CLOTH_BROWN_OLD, oy=3, hunch=1, skirt=True, long_tunic=True, patch_cloth=True),
        'co': Spec(kid=True, skin=SKIN_TAN, shirt=CLOTH_ASH, pants=CLOTH_ASH_DARK, hair_style='tuft', patch_cloth=True),
        'suong': Spec(shirt=CLOTH_BLACK, pants=CLOTH_BLACK, hair_style='bun', long_tunic=True, sash=CLOTH_CREAM,
                      holds='sack'),
        'dieu': Spec(shirt=CLOTH_ASH_DARK, pants=CLOTH_ASH, hair_style='braid', long_tunic=True, headband=CLOTH_ASH),
        'me_manh': Spec(skin=SKIN_OLD, hair=HAIR_GREY, shirt=CLOTH_ASH_DARK, pants=CLOTH_ASH, hair_style='scarf',
                        headband=CLOTH_ASH, oy=2, long_tunic=True, skirt=True),
        # the people of Bạch Sơn: undyed white, and the nón lá their faces wear in Trắng Tay's crown (and in the
        # glimpse at the pass, scripts/fx/vision_gate.gd)
        'bs_w': Spec(shirt=CLOTH_WHITE, pants=CLOTH_WHITE_DIM, hat='nonla', hair_style='bun', long_tunic=True),
        'bs_m': Spec(skin=SKIN_TAN, shirt=CLOTH_WHITE, pants=CLOTH_WHITE_DIM, hat='nonla', hair_style='short', rolled=True,
                     holds='sack'),
    }
