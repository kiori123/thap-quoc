"""The characters only (not the rest of tools/gen_art.py): every walk sheet, each person's emote sheet (<name>_emo.png:
faces and body language, chars.EMOTES; scripts/world/actor.gd emo()), the hero's action sheet, the old man's extra
poses, the sitters, and for each its normal map (<name>_n.png, the same layout) for shaders/sprite_lit.gdshader; then
the porcelain and blindfolded townsfolk (tools/art/masked_folk.py) from the walkers, with the walkers' maps.

Run from the project root: python tools/art/gen_chars.py
"""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import chars as C  # noqa: E402
import pix  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.dirname(HERE)), 'assets', 'sprites', 'chars')


def save(name, frames, cols):
    pix.sheet(frames, cols).save(os.path.join(ROOT, name + '.png'))
    pix.sheet(C.NORMALS, cols).save(os.path.join(ROOT, name + '_n.png'))


def main():
    S = C.specs()
    for name, sp in S.items():
        C.NORMALS = []
        sheet = C.build_walk_sheet(sp)
        sheet.save(os.path.join(ROOT, name + '.png'))
        pix.sheet(C.NORMALS, C.SHEET_COLS).save(os.path.join(ROOT, name + '_n.png'))
        if not sp.statue:
            C.NORMALS = []
            C.build_emo_sheet(sp).save(os.path.join(ROOT, name + '_emo.png'))
            pix.sheet(C.NORMALS, len(C.EMOTE_NAMES) * 2).save(os.path.join(ROOT, name + '_emo_n.png'))
        print(name)
    h = S['hero']
    act_names = ['ready', 'windup', 'strike', 'follow', 'sweep_wind', 'sweep_strike', 'guard', 'hurt', 'item',
                 'kneel', 'broom_a', 'broom_b',
                 'ready_b', 'windup_deep', 'smear', 'recover', 'sweep_smear', 'parry', 'hurt_b', 'thau', 'victory']
    C.NORMALS = []
    acts = [C.action(h, p, 'axe') for p in act_names]
    save('hero_act', acts, len(acts))
    C.NORMALS = []   # from Bạch Sơn on: the old sword ông gave at the departure, in place of the axe
    acts = [C.action(h, p, 'sword') for p in act_names]
    save('hero_act_sword', acts, len(acts))
    o = S['ong']
    C.NORMALS = []
    ong_x = [C.front_pose(o, 'near_smile'), C.front_pose(o, 'hand_side'), C.front_pose(o, 'sit'),
             C.action(o, 'bandage', legs=(0, 0)), C.front_pose(o, 'arm_up', 'down'), C.action(o, 'give', legs=(0, 0))]
    save('ong_x', ong_x, len(ong_x))
    C.NORMALS = []
    extra = [C.front_pose(S['baca'], 'sit'), C.front_pose(S['lua'], 'sit'), C.front_pose(h, 'sit')]
    save('sitters', extra, len(extra))
    C.NORMALS = None
    import masked_folk as MF
    for k in ('dan_w', 'dan_m', 'bs_w', 'bs_m'):
        src = os.path.join(ROOT, '%s.png' % k)
        porc = os.path.join(ROOT, '%s_porc.png' % k)
        MF.porcelain_sheet(src, porc)
        MF.blindfold_sheet(src, porc, os.path.join(ROOT, '%s_blind.png' % k))
        for v in ('porc', 'blind'):   # the same figures, the same shapes
            shutil.copyfile(os.path.join(ROOT, '%s_n.png' % k), os.path.join(ROOT, '%s_%s_n.png' % (k, v)))
    print('done')


if __name__ == '__main__':
    main()
