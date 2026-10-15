"""Generate every pixel-art asset for the prologue demo.

Usage:  python tools/gen_art.py            (writes into assets/)
        python tools/gen_art.py --preview  (also writes contact sheets into qa/)
"""
import os
import sys
from PIL import Image, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'art'))
ROOT = os.path.dirname(HERE)

import pix  # noqa: E402
import chars as C  # noqa: E402
import monsters as Mo  # noqa: E402
import env as E  # noqa: E402
import props as P  # noqa: E402
import ui_art as U  # noqa: E402
import paper_ui as PU  # noqa: E402
import boss_fx as BF  # noqa: E402


def out(*parts):
    p = os.path.join(ROOT, 'assets', *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def main(preview=False):
    S = C.specs()
    made = []
    # characters: walk sheets
    for name, sp in S.items():
        im = C.build_walk_sheet(sp)
        im.save(out('sprites', 'chars', name + '.png'))
        made.append(('chars/' + name, im))
    h = S['hero']
    # the first twelve keep their old indices; the rest were added for the battle animation pass
    act_names = ['ready', 'windup', 'strike', 'follow', 'sweep_wind', 'sweep_strike', 'guard', 'hurt', 'item',
                 'kneel', 'broom_a', 'broom_b',
                 'ready_b', 'windup_deep', 'smear', 'recover', 'sweep_smear', 'parry', 'hurt_b', 'thau', 'victory']
    acts = [C.action(h, p, 'axe') for p in act_names]
    im = pix.sheet(acts, len(acts))
    im.save(out('sprites', 'chars', 'hero_act.png'))
    made.append(('chars/hero_act', im))
    o = S['ong']
    ong_x = [C.front_pose(o, 'near_smile'), C.front_pose(o, 'hand_side'), C.front_pose(o, 'sit'),
             C.action(o, 'bandage', legs=(0, 0)), C.front_pose(o, 'arm_up', 'down'), C.action(o, 'give', legs=(0, 0))]
    im = pix.sheet(ong_x, len(ong_x))
    im.save(out('sprites', 'chars', 'ong_x.png'))
    made.append(('chars/ong_x', im))
    extra = [C.front_pose(S['baca'], 'sit'), C.front_pose(S['lua'], 'sit'), C.front_pose(h, 'sit')]
    im = pix.sheet(extra, len(extra))
    im.save(out('sprites', 'chars', 'sitters.png'))
    made.append(('chars/sitters', im))
    # the title: the protagonist seen from behind, sitting with the sword, then the cut (scripts/world/vista.gd)
    tf = C.title_frames(h)
    im = pix.sheet(tf, len(tf))
    im.save(out('sprites', 'chars', 'hero_title.png'))
    made.append(('chars/hero_title', im))
    im = pix.sheet(C.title_trail_frames(h), len(tf))   # the blade's light, drawn unshaded over the hero
    im.save(out('sprites', 'chars', 'hero_title_trail.png'))
    # monsters (generated facing left, mirrored to face right toward the party)
    im = pix.sheet([ImageOps.mirror(Mo.manh_tinh(i)) for i in range(6)], 6)
    im.save(out('sprites', 'monsters', 'manh_tinh.png'))
    made.append(('monsters/manh_tinh', im))
    im = pix.sheet([ImageOps.mirror(Mo.nghiet_tinh(i)) for i in range(7)], 7)
    im.save(out('sprites', 'monsters', 'nghiet_tinh.png'))
    made.append(('monsters/nghiet_tinh', im))
    Mo.reach_segment_frames().save(out('sprites', 'fx', 'reach_segment.png'))
    Mo.reach_hand_frames().save(out('sprites', 'fx', 'reach_hand.png'))
    # props
    for name, fn in P.ALL.items():
        im = fn()
        im.save(out('sprites', 'props', name + '.png'))
        made.append(('props/' + name, im))
    # textures
    for name, fn in E.ALL.items():
        im = fn()
        im.save(out('tex', name + '.png'))
        made.append(('tex/' + name, im))
    # ui + fx
    for name, fn in U.ALL.items():
        im = fn()
        im.save(out('ui', name + '.png'))
        made.append(('ui/' + name, im))
    U.brush_stroke().save(out('ui', 'brush_one.png'))
    for name, fn in BF.FX.items():    # Trắng Tay's entrance
        fn().save(out('sprites', 'fx', name + '.png'))
    for name, fn in BF.UI.items():
        fn().save(out('ui', name + '.png'))
    for name, fn in PU.ALL.items():   # the paper-and-ink frames, seals, branch
        im = fn()
        im.save(out('ui', name + '.png'))
        made.append(('ui/' + name, im))
    for name, fn in U.FX.items():
        im = fn()
        im.save(out('sprites', 'fx', name + '.png'))
        made.append(('fx/' + name, im))
    import vision as V
    V.gate().save(out('vision', 'gate.png'))
    print('wrote', len(made) + 2, 'images')
    if preview:
        qa = os.path.join(ROOT, 'qa')
        os.makedirs(qa, exist_ok=True)
        groups = {}
        for key, im in made:
            groups.setdefault(key.split('/')[0], []).append((key, im))
        for g, items in groups.items():
            pad = 6
            scale = 3 if g != 'tex' else 4
            wmax = 1400
            x = y = 0
            rowh = 0
            pos = []
            for key, im in items:
                w, hh = im.width * scale, im.height * scale
                if x + w > wmax:
                    x = 0
                    y += rowh + pad
                    rowh = 0
                pos.append((x, y, im))
                x += w + pad
                rowh = max(rowh, hh)
            canvas = Image.new('RGBA', (wmax, y + rowh + pad), (62, 66, 74, 255))
            for (px_, py_, im) in pos:
                canvas.alpha_composite(im.resize((im.width * scale, im.height * scale), Image.NEAREST), (px_, py_))
            canvas.save(os.path.join(qa, 'sheet_' + g + '.png'))


if __name__ == '__main__':
    main('--preview' in sys.argv)
