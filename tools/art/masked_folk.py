"""Bạch Sơn townsfolk for the Duyên glimpse. Run from the project root.

dan_*_porc.png  : the village walkers turned to porcelain (a soft glazed-white ramp, only the outer outline dark).
dan_*_blind.png : the same, with a cobalt band glazed across the eyes (front-facing row only). In the Duyên glimpse
                  the people behind the White Gate look out at the expelled, then turn their backs and go in;
                  a white shape of each, eyes bound, stays at the gate (they chose not to see). Trắng Tay's
                  crown is made of these faces.
"""
import numpy as np
from PIL import Image

LAM = np.array([(59, 95, 174), (42, 70, 137), (88, 125, 203)])   # mid, shadow, light


def porcelain_sheet(src, dst):
    im = np.array(Image.open(src).convert('RGBA')).astype(int)
    a = im[:, :, 3] > 0
    lum = (im[:, :, 0] * 299 + im[:, :, 1] * 587 + im[:, :, 2] * 114) // 1000
    ramp = np.array([(176, 186, 200), (212, 219, 229), (233, 238, 244), (248, 250, 253)])
    idx = np.clip((lum / 255.0) ** 0.5 * 3.2 + 0.4, 0, 3).astype(int)
    out = im.copy()
    out[a, :3] = ramp[idx[a]]
    pad = np.pad(a, 1)
    rim = a & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out[rim, :3] = (70, 80, 96)
    Image.fromarray(out.astype(np.uint8), 'RGBA').save(dst)


def blindfold_sheet(src, porc, dst, rows=4, cols=19):
    """Find each front frame's face on the original sheet, then glaze a cobalt band over the eyes of the
    porcelain sheet, with the knot's loose end at the side of the head."""
    orig = np.array(Image.open(src).convert('RGBA')).astype(int)
    out = np.array(Image.open(porc).convert('RGBA'))
    fh, fw = orig.shape[0] // rows, orig.shape[1] // cols
    for c in range(cols):
        f = orig[0:fh, c * fw:(c + 1) * fw]
        o = out[0:fh, c * fw:(c + 1) * fw]
        rgb = f[:, :, :3]
        skin = (f[:, :, 3] > 0) & (rgb[:, :, 0] > 140) & (rgb[:, :, 0] - rgb[:, :, 1] >= 40) & (rgb[:, :, 1] - rgb[:, :, 2] < 50)
        ys, xs = np.nonzero(skin[:30])
        if len(ys) == 0:
            continue
        top = ys.min()
        face = xs[ys <= top + 3]
        x0, x1 = face.min() - 1, face.max() + 1
        for y, shade in ((top + 1, 2), (top + 2, 0)):
            for x in range(x0, x1 + 1):
                if 0 <= x < fw and o[y, x, 3] > 0:
                    o[y, x, :3] = LAM[shade if x < x1 else 1]
        for (dx, dy) in ((1, 2), (2, 3)):
            x, y = x1 + dx, top + dy
            if x < fw:
                o[y, x, :3] = LAM[1]
                o[y, x, 3] = 255
    Image.fromarray(out, 'RGBA').save(dst)


if __name__ == '__main__':
    for n in ('dan_w', 'dan_m', 'bs_w', 'bs_m'):
        src = 'assets/sprites/chars/%s.png' % n
        porc = 'assets/sprites/chars/%s_porc.png' % n
        porcelain_sheet(src, porc)
        blindfold_sheet(src, porc, 'assets/sprites/chars/%s_blind.png' % n)
    print('ok')
