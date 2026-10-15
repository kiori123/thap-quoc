import sys
from PIL import Image
from pix import sheet, preview
import chars as C
S = C.specs()
rows = []
for name in ('hero', 'ong', 'lua', 'baca', 'chunam', 'ti', 'na', 'peddler', 'refugee_w', 'refugee_o', 'statue_w'):
    sp = S[name]
    fr = [C.frame_front(sp, 'down', 0), C.frame_front(sp, 'down', 2), C.frame_side(sp, 0), C.frame_side(sp, 2), C.frame_side(sp, 4), C.frame_front(sp, 'up', 0)]
    rows += fr
h = S['hero']
acts = [C.action(h, p, 'axe') for p in ('ready', 'windup', 'strike', 'follow', 'sweep_wind', 'sweep_strike')]
acts2 = [C.action(h, p, 'axe') for p in ('guard', 'hurt', 'item', 'kneel', 'broom_a', 'broom_b')]
o = S['ong']
ongx = [C.front_pose(o, 'near_smile'), C.front_pose(o, 'hand_side'), C.front_pose(o, 'sit'), C.action(o, 'bandage', legs=(0,0)), C.front_pose(o, 'arm_up', 'up'), C.action(o, 'give', legs=(0,0))]
img = sheet(rows + acts + acts2 + ongx, 6)
preview(img, 4).save(sys.argv[1])
print(img.size)
