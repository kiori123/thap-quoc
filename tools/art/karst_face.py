"""A limestone cliff face for the title's karst towers (assets/tex/karst_face.png and its relief karst_face_n.png),
tileable both ways, meant to be laid on at about 14 m a tile so its shapes read from far off.

Rock breaks, it is not laid: the face is a net of fractures, mostly running down (the cells are taller than wide),
their lines wandering. Each fragment is a facet tilted its own way, so under a side light the face breaks into chips
of light and shade; inside the big fragments, smaller facets, fainter. The fractures are dark, some wide, some
closed. Rain streaks run down, there are pale patches of lichen. The tone is baked lit a little from above (the sky)
so it reads even in shade; the normal map carries the facets for the sun. Quantised to a few tones, as pixel art.

Run: python tools/art/karst_face.py
"""
import os

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

N = 256
HERE = os.path.dirname(__file__)
OUT = os.path.join(HERE, '..', '..', 'assets', 'tex', 'karst_face.png')
OUT_N = os.path.join(HERE, '..', '..', 'assets', 'tex', 'karst_face_n.png')


def fbm(rng, beta, lo, hi):
    fy = np.fft.fftfreq(N)[:, None] * N
    fx = np.fft.rfftfreq(N)[None, :] * N
    f = np.sqrt(fx * fx + fy * fy)
    amp = np.where((f >= lo) & (f <= hi), 1.0 / np.maximum(f, 1.0) ** beta, 0.0)
    n = np.fft.irfft2(amp * np.exp(2j * np.pi * rng.random(amp.shape)), s=(N, N))
    n -= n.min()
    return n / n.max()


def cells(rng, cols, rows, q):
    """Jittered cells (cols x rows over the tile, so taller than wide when cols > rows), tileable. For each point of
    q (n x 2, in 0..1 as y, x): the nearest cell, and how far it is from the fracture with the next one (0 on it)."""
    g = np.stack(np.meshgrid((np.arange(rows) + 0.5) / rows, (np.arange(cols) + 0.5) / cols, indexing='ij'), -1).reshape(-1, 2)
    g += (rng.random(g.shape) - 0.5) * np.array([0.8 / rows, 0.8 / cols])
    g %= 1.0
    # measure in a space where the cells are round, so the fractures run down
    sc = np.array([rows, cols], dtype=float) / max(rows, cols)
    tree = cKDTree(g * sc, boxsize=sc)
    d, i = tree.query((q % 1.0) * sc, k=2)
    return i[:, 0], (d[:, 1] - d[:, 0]) * max(rows, cols), len(g)


def main():
    rng = np.random.default_rng(31)
    yy, xx = np.meshgrid((np.arange(N) + 0.5) / N, (np.arange(N) + 0.5) / N, indexing='ij')
    # the fractures wander
    wy = (fbm(rng, 2.2, 2, 16) - 0.5) * 0.07
    wx = (fbm(rng, 2.2, 2, 16) - 0.5) * 0.05
    q = np.stack([yy + wy, xx + wx], -1).reshape(-1, 2)
    big, gap_b, nb = cells(rng, 9, 3, q)
    small, gap_s, ns = cells(rng, 16, 8, q + 0.013)
    big = big.reshape(N, N)
    small = small.reshape(N, N)
    gap_b = gap_b.reshape(N, N)
    gap_s = gap_s.reshape(N, N)
    # each fragment a facet tilted its own way (x across, y up the face)
    tb = rng.normal(0.0, 0.42, (nb, 2))
    ts = rng.normal(0.0, 0.2, (ns, 2))
    tone_b = rng.uniform(0.52, 0.86, nb)
    tone_s = rng.uniform(-0.06, 0.06, ns)
    tilt = tb[big] + ts[small]
    # the fractures: big ones dark and open (wider in places), small ones fine and often closed
    width = 0.05 + 0.07 * fbm(rng, 1.5, 3, 20)
    crack_b = (1.0 - np.clip(gap_b / width, 0.0, 1.0)) * np.clip((fbm(rng, 1.6, 2, 14) - 0.3) * 2.5, 0.15, 1.0)
    crack_s = (1.0 - np.clip(gap_s / 0.05, 0.0, 1.0)) * (fbm(rng, 1.5, 4, 30) > 0.45)
    edge = np.clip(gap_b / 0.25, 0.0, 1.0) ** 0.5   # how far into the fragment (its edges round over)
    # the relief: rounded over at the fragment's edges, sunk at the fractures (the facet's tilt goes in the normal)
    h = 0.55 + 0.45 * edge - 0.6 * crack_b - 0.25 * crack_s
    h += 0.15 * fbm(rng, 1.4, 8, 64)
    # the normal of the face: the facet's tilt and the relief
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * N * 0.04
    gy = (np.roll(h, 1, 0) - np.roll(h, -1, 0)) * 0.5 * N * 0.04
    nx = -gx + tilt[:, :, 0]
    ny = -gy + tilt[:, :, 1]
    nrm = np.stack([nx, ny, np.ones_like(h)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    # tone: the fragment's own, lit a little from the sky above and a little from the left
    sky = 0.78 + 0.22 * nrm[:, :, 1] + 0.1 * nrm[:, :, 0]
    lum = (tone_b[big] + tone_s[small]) * sky
    lum *= 1.0 - 0.62 * crack_b - 0.3 * crack_s
    lum *= 0.82 + 0.18 * edge
    # rain streaks running down; lichen
    streak = np.clip((fbm(rng, 1.1, 5, 60) - 0.56) * 4.0, 0.0, 1.0) * (0.5 + 0.5 * fbm(rng, 2.0, 1, 6))
    lum *= 1.0 - 0.3 * streak
    lich = np.clip((fbm(rng, 1.8, 4, 40) - 0.74) * 6.0, 0.0, 1.0) * edge
    grain = fbm(rng, 0.8, 24, 128)
    lum = lum * (0.92 + 0.16 * grain) + 0.1 * lich
    r = lum * 1.02 + 0.015 * lich
    g = lum
    b = lum * 0.97 + 0.03 * crack_b
    rgb = np.stack([r, g, b], -1)
    levels = 10
    qv = np.floor(np.clip(rgb, 0, 1) * (levels - 1) + 0.5 + (grain[:, :, None] - 0.5) * 0.5) / (levels - 1)
    Image.fromarray((np.clip(qv, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGB').save(OUT)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8), 'RGB').save(OUT_N)
    print('wrote', os.path.normpath(OUT), os.path.normpath(OUT_N))


if __name__ == '__main__':
    main()
