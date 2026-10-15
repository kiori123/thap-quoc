"""The noise the title's cloud sea is shaped from (assets/tex/cloud_noise.png), tileable in both directions.

R: the billows: domes of three sizes heaped on one another (the cauliflower tops of a sea of cumulus), over a slow
   swell, so the deck has round heads with creases between them, not an even speckle.
G: a smooth swell (fbm), for the slow drift and the ragged edges of the cut.
B: small domes, for the fine knobbling of the light on the cloud's skin.
A: fbm of finer grain, for wisps.

Run: python tools/art/cloud_noise.py
"""
import os

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

N = 512
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'tex', 'cloud_noise.png')


def fbm(rng, beta, lo, hi):
    """Tileable fractal noise by spectral synthesis: random phases, amplitude falling as 1/f^beta between lo and hi
    cycles per tile. Returns 0..1."""
    fy = np.fft.fftfreq(N)[:, None] * N
    fx = np.fft.rfftfreq(N)[None, :] * N
    f = np.sqrt(fx * fx + fy * fy)
    amp = np.where((f >= lo) & (f <= hi), 1.0 / np.maximum(f, 1.0) ** beta, 0.0)
    spec = amp * np.exp(2j * np.pi * rng.random(amp.shape))
    n = np.fft.irfft2(spec, s=(N, N))
    n -= n.min()
    return n / n.max()


def domes(rng, cells, jitter=0.85):
    """Round heads: for each pixel the height of the nearest of a jittered grid of domes (tileable)."""
    g = (np.stack(np.meshgrid(np.arange(cells), np.arange(cells), indexing='ij'), -1).reshape(-1, 2) + 0.5)
    pts = (g + (rng.random(g.shape) - 0.5) * jitter) / cells
    pts %= 1.0
    tree = cKDTree(pts, boxsize=1.0)
    yy, xx = np.meshgrid((np.arange(N) + 0.5) / N, (np.arange(N) + 0.5) / N, indexing='ij')
    q = np.stack([yy.ravel(), xx.ravel()], -1)
    d, _ = tree.query(q, k=2)
    r = 0.62 / cells
    h = np.sqrt(np.clip(1.0 - (d[:, 0] / r) ** 2, 0.0, 1.0))
    # where two heads meet, a crease
    crease = np.clip((d[:, 1] - d[:, 0]) * cells * 3.0, 0.0, 1.0)
    return (h * (0.55 + 0.45 * crease)).reshape(N, N)


def main():
    rng = np.random.default_rng(14)
    swell = fbm(rng, 2.2, 1, 12)
    billow = domes(rng, 6) * 1.0 + domes(rng, 13) * 0.5 + domes(rng, 27) * 0.24 + swell * 0.6
    billow = (billow - billow.min()) / (billow.max() - billow.min())
    fine = domes(rng, 48) * 0.7 + domes(rng, 90) * 0.3
    fine = (fine - fine.min()) / (fine.max() - fine.min())
    wisp = fbm(rng, 1.6, 4, 96)
    img = np.stack([billow, swell, fine, wisp], -1)
    Image.fromarray((img * 255.0 + 0.5).astype(np.uint8), 'RGBA').save(OUT)
    print('wrote', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
