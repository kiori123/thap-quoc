"""Preview the animated walk sheets: python tools/art/preview_anim.py out.png [names...]"""
import sys
from PIL import Image
from pix import preview
import chars as C
S = C.specs()
names = sys.argv[2:] or ['hero', 'ong', 'lua', 'baca', 'ti']
rows = []
for n in names:
    rows.append(C.build_walk_sheet(S[n]))
w = rows[0].width
img = Image.new('RGBA', (w, sum(r.height for r in rows)), (0, 0, 0, 0))
y = 0
for r in rows:
    img.paste(r, (0, y))
    y += r.height
preview(img, 2).save(sys.argv[1])
print(img.size)
