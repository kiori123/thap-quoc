"""Bạch Sơn rock from photographs (assets/tex/_src, Poly Haven, CC0; see SOURCES.md there).

A photo keeps what a noise generator cannot make up: the real way a limestone face splits into beds and joints.
It is not used as a photo. It is brought down to the game's pixel density (about 24 px to a metre at the size it
is mapped), its light read off as tone only, and that tone put into a short ramp of the city's own limestone
colours with an ordered dither, so it sits with the sprites and the rest of the textures.

  assets/tex/cliff_lime.png   the mountain's faces: pale limestone in beds (from "Cliff Side"), 64x64, tiles
  assets/tex/rock_lime.png    loose rock, boulders, the foot of walls (from "Rock Face 03"), 48x48, tiles
"""
import os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..', 'assets', 'tex')
SRC = os.path.join(ROOT, '_src')

BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.5


def hexc(s):
    s = s.lstrip('#')
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], float)


def tileable_down(im, n):
    """Shrink a seamless photo to n x n without seams: shrink it tiled 3 x 3, keep the middle."""
    w, h = im.size
    big = Image.new('RGB', (w * 3, h * 3))
    for i in range(3):
        for j in range(3):
            big.paste(im, (i * w, j * h))
    small = big.resize((n * 3, n * 3), Image.LANCZOS)
    return small.crop((n, n, n * 2, n * 2))


def to_ramp(im, ramp, contrast=1.0, dither=0.6, sharpen=True):
    if sharpen:
        im = im.filter(ImageFilter.UnsharpMask(radius=1, percent=80, threshold=1))
    a = np.asarray(im).astype(float) / 255.0
    lum = a[..., 0] * 0.3 + a[..., 1] * 0.55 + a[..., 2] * 0.15
    lo, hi = np.percentile(lum, 3), np.percentile(lum, 97)
    t = np.clip((lum - lo) / max(hi - lo, 1e-4), 0, 1)
    t = np.clip((t - 0.5) * contrast + 0.5, 0, 1)
    n = len(ramp)
    yy, xx = np.mgrid[0:t.shape[0], 0:t.shape[1]]
    k = np.clip(np.floor(t * n + BAYER[yy % 4, xx % 4] * dither), 0, n - 1).astype(int)
    pal = np.stack([hexc(c) for c in ramp])
    return Image.fromarray(pal[k].astype(np.uint8), 'RGB')


# the mountain: white-grey limestone, cool in the joints, a little warm where the sun lies on the beds
CLIFF = ['#454a52', '#596068', '#6d737a', '#81868a', '#959896', '#a8a9a4', '#babab3']   # grey stone, cooler and darker than the lime of the walls, so the white city stands out against it
# loose rock and boulders: the same stone, a shade darker and greyer (weathered, lichen)
ROCK = ['#4a4c4f', '#5f6163', '#757674', '#8b8a84', '#a19e94', '#b6b2a6']


def build():
    cliff = Image.open(os.path.join(SRC, 'cliff_side_diff_1k.jpg')).convert('RGB')
    to_ramp(tileable_down(cliff, 128), CLIFF, contrast=0.95, dither=0.35).save(os.path.join(ROOT, 'cliff_lime.png'))
    rock = Image.open(os.path.join(SRC, 'rock_face_03_diff_1k.jpg')).convert('RGB')
    to_ramp(tileable_down(rock, 48), ROCK, contrast=1.1, dither=0.4).save(os.path.join(ROOT, 'rock_lime.png'))
    # the flanks: the same jointed rock, larger (beds would stripe a long slope), in the mountain's greys
    to_ramp(tileable_down(rock, 128), CLIFF, contrast=1.0, dither=0.35).save(os.path.join(ROOT, 'flank_lime.png'))


if __name__ == '__main__':
    build()
    print('ok')
