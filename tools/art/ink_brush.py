"""A small sumi brush: strokes laid along a centre line with a pressure (width) and an ink load that runs out.

stroke(canvas, pts, width, ...) paints one stroke into an Ink canvas:
  * the width follows `width(u)` along the stroke (u = 0 at the press, 1 at the lift), with a ragged edge;
  * the hairs leave streaks that run along the stroke; as the ink runs out (`dry`), the streaks break into
    dry-brush gaps, more at the edges of the stroke than in its middle, more toward the lift;
  * where the brush pressed down the ink pools darker at the rim; the dry parts go grey.
Ink.wash() spreads a pale grey bleed round what has been painted (water carrying ink into the paper), with an
irregular edge. Ink.splash() flicks droplets. Everything is drawn at the canvas's own size; callers draw at 2x
or 3x and scale down for soft edges.
"""
import math
import numpy as np
from scipy.spatial import cKDTree
from scipy import ndimage as ndi


def _noise1(n, seed, smooth=1.0):
    v = np.random.default_rng(seed).random(n)
    if smooth > 0:
        v = ndi.gaussian_filter1d(v, smooth, mode='wrap')
        v = (v - v.min()) / max(1e-6, v.max() - v.min())
    return v


def _sample(arr, x):
    """Linear lookup into a 1-D array with x in [0, 1]."""
    n = len(arr)
    f = np.clip(x, 0, 1) * (n - 1)
    i = np.floor(f).astype(int)
    j = np.minimum(i + 1, n - 1)
    t = f - i
    return arr[i] * (1 - t) + arr[j] * t


def resample(pts, step=0.6):
    pts = np.asarray(pts, float)
    seg = np.hypot(*np.diff(pts, axis=0).T)
    L = np.concatenate([[0], np.cumsum(seg)])
    n = max(2, int(L[-1] / step))
    s = np.linspace(0, L[-1], n)
    return np.stack([np.interp(s, L, pts[:, 0]), np.interp(s, L, pts[:, 1])], 1), L[-1]


def bezier(p0, p1, p2, p3, n=80):
    u = np.linspace(0, 1, n)[:, None]
    v = 1 - u
    return (v ** 3) * p0 + 3 * v * v * u * p1 + 3 * v * u * u * p2 + (u ** 3) * p3


class Ink:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.a = np.zeros((h, w))       # ink coverage
        self.dark = np.ones((h, w))     # how black the ink is where it lies (1 = full black)

    def stroke(self, pts, width, seed=0, dry=0.5, load=1.0, rough=0.12, hairs=34, pool=0.25, drag=0.25,
               hold_axis=None, hold_lo=0.0, hold_hi=0.0, hold_width=None):
        """width: callable u -> full width in px (u = 0 at the press, 1 at the lift).
        hold_axis/lo/hi: where the centre line's x (0) or y (1) lies between lo and hi, the stroke is held
        uniform (width hold_width, no ragged edge, no drying): the stretchable middle of a 9-patch edge."""
        P, L = resample(pts)
        n = len(P)
        u_pts = np.linspace(0, 1, n)
        W = np.array([width(u) for u in u_pts])
        hp = np.zeros(n, bool)
        if hold_axis is not None:
            hp = (P[:, hold_axis] > hold_lo) & (P[:, hold_axis] < hold_hi)
            if hold_width is not None:
                W = np.where(hp, hold_width, W)
                W = ndi.gaussian_filter1d(W, 6)
                W = np.where(hp, hold_width, W)
        wmax = W.max()
        x0, y0 = np.floor(P.min(0) - wmax).astype(int)
        x1, y1 = np.ceil(P.max(0) + wmax).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, self.w - 1), min(y1, self.h - 1)
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        q = np.stack([xx.ravel(), yy.ravel()], 1).astype(float)
        d, idx = cKDTree(P).query(q)
        idx_a = np.clip(idx - 2, 0, n - 1)
        idx_b = np.clip(idx + 2, 0, n - 1)
        tan = P[idx_b] - P[idx_a]
        tan /= np.maximum(np.hypot(*tan.T), 1e-6)[:, None]
        nor = np.stack([-tan[:, 1], tan[:, 0]], 1)
        u = u_pts[idx]
        hw = np.maximum(W[idx] * 0.5, 1e-3)
        s = np.sum((q - P[idx]) * nor, 1) / hw          # -1 .. 1 across the stroke
        along = u * L
        hold = hp[idx].astype(float)
        # the edge wavers on the scale of the brush, not in little teeth
        edge_n = (_sample(_noise1(512, seed, 3.0), (along / 26.0) % 1.0) - 0.5) * 2
        edge_f = (_sample(_noise1(2048, seed + 1, 1.2), (along / 5.0) % 1.0) - 0.5) * 2
        lim = 1.0 + rough * (edge_n * 0.85 + edge_f * 0.15) * (1 - hold)
        inside = d < hw * lim   # (by distance, not by |s|: past the ends of the line |s| stays small)
        # flying white: the hairs are bands across the stroke; as the ink runs out, bands go white for a
        # stretch and come back, each on its own rhythm along the stroke
        band = np.clip(((s * 0.5 + 0.5) * hairs).astype(int), 0, hairs - 1)
        rng = np.random.default_rng(seed + 2)
        grid = ndi.gaussian_filter1d(rng.random((hairs, 512)), 4.0, axis=1, mode='wrap')
        grid = (grid - grid.min()) / max(1e-6, grid.max() - grid.min())
        bandv = rng.random(hairs)
        pos = ((along / 70.0) % 1.0) * 511
        runs = grid[band, pos.astype(int)]
        val = bandv[band] * 0.45 + runs * 0.55
        val = np.where(hold > 0, bandv[band] * 0.45 + 0.55 * 0.5, val)
        if hp.any():   # nothing dries before the end of the held part
            u_end = u_pts[np.where(hp)[0][-1]]
            run_out = np.clip((u - u_end) / max(1 - u_end, 1e-3), 0, 1) * min(1.0, dry * 1.6)
        else:
            run_out = np.clip((u - (1 - dry)) / max(dry, 1e-3), 0, 1) if dry > 0 else np.zeros_like(u)
        edge_dry = np.clip((np.abs(s) - 0.6) / 0.4, 0, 1)
        thresh = 0.02 + 1.05 * run_out ** 0.7 + 0.2 * edge_dry * (0.3 + run_out)
        a = inside * np.clip((val - thresh) / 0.06 + 0.5, 0, 1)
        dk = load * (0.86 + pool * np.clip((np.abs(s) - 0.65) / 0.35, 0, 1) * (1 - u) * (1 - hold)) - 0.3 * run_out
        dk = np.clip(dk, 0.3, 1.0)
        a = a.reshape(yy.shape)
        dk = dk.reshape(yy.shape)
        reg_a = self.a[y0:y1 + 1, x0:x1 + 1]
        reg_d = self.dark[y0:y1 + 1, x0:x1 + 1]
        new_a = 1 - (1 - reg_a) * (1 - a)
        reg_d[:] = np.where(a > reg_a, dk, reg_d)
        reg_a[:] = new_a

    def splash(self, cx, cy, spread_x, spread_y, n, rmin, rmax, seed=0):
        rng = np.random.default_rng(seed)
        yy, xx = np.mgrid[0:self.h, 0:self.w]
        for _ in range(n):
            px = cx + rng.normal(0, spread_x)
            py = cy + rng.normal(0, spread_y)
            r = rng.uniform(rmin, rmax) * (1 if rng.random() < 0.85 else 2.2)
            x0, x1 = int(max(px - r - 2, 0)), int(min(px + r + 2, self.w - 1))
            y0, y1 = int(max(py - r - 2, 0)), int(min(py + r + 2, self.h - 1))
            if x1 <= x0 or y1 <= y0:
                continue
            sub = np.hypot(xx[y0:y1 + 1, x0:x1 + 1] - px, yy[y0:y1 + 1, x0:x1 + 1] - py)
            a = np.clip(r - sub + 0.5, 0, 1)
            reg = self.a[y0:y1 + 1, x0:x1 + 1]
            reg[:] = np.maximum(reg, a)

    def wash(self, radius, strength, seed=0, mask=None):
        """A pale bleed round the ink, soft, hugging it, its outer edge wandering a little and a shade darker
        where the water stopped. Returns its alpha (not merged)."""
        b = ndi.gaussian_filter(self.a, radius)
        rng = np.random.default_rng(seed)
        nz = ndi.gaussian_filter(rng.random(self.a.shape), radius * 1.2)
        nz = (nz - nz.mean()) / max(1e-6, nz.std())
        f = b * 2.6 + nz * 0.06
        w = np.clip((f - 0.06) / 0.3, 0, 1) ** 0.8 * strength * np.clip(b * 40.0, 0, 1)
        rim = np.exp(-((f - 0.08) / 0.035) ** 2) * 0.35 * strength * np.clip(b * 40.0, 0, 1)
        w = np.clip(w + rim, 0, 1)
        if mask is not None:
            w *= mask
        return w


def paper(w, h, seed=0, base=(242, 235, 217), edge=(220, 204, 172)):
    """Xuyến chỉ paper: a warm cream, mottled, with fibres and a few faint stains."""
    rng = np.random.default_rng(seed)
    mott = ndi.gaussian_filter(rng.random((h, w)), max(w, h) * 0.03)
    mott = (mott - mott.min()) / max(1e-6, mott.max() - mott.min())
    fib = ndi.gaussian_filter(rng.random((h, w)), (0.4, 2.2))
    fib = (fib - fib.mean()) / max(1e-6, fib.std())
    rgb = np.zeros((h, w, 3))
    for k in range(3):
        rgb[..., k] = base[k] + (mott - 0.5) * 9 + fib * 1.6
    # a few faint tea-coloured stains
    for _ in range(4):
        cx, cy = rng.uniform(0, w), rng.uniform(0, h)
        r = rng.uniform(0.08, 0.2) * max(w, h)
        yy, xx = np.mgrid[0:h, 0:w]
        st = np.exp(-((xx - cx) ** 2 + (yy - cy) ** 2) / (2 * r * r)) * rng.uniform(0.15, 0.3)
        for k in range(3):
            rgb[..., k] = rgb[..., k] * (1 - st) + edge[k] * st
    return rgb


def compose(paper_rgb, paper_a, ink, wash_a, ink_rgb=(18, 16, 19), wash_rgb=(108, 104, 106)):
    """paper under wash under ink -> RGBA uint8"""
    h, w = paper_a.shape
    out = np.zeros((h, w, 4))
    # paper
    out[..., :3] = paper_rgb
    a = paper_a.copy()
    # wash (over paper, or alone on the transparent outside)
    wr = np.array(wash_rgb, float)
    a_w = wash_a
    na = a + a_w * (1 - a)
    rgb = (out[..., :3] * a[..., None] * (1 - a_w[..., None]) + wr * a_w[..., None]) / np.maximum(na, 1e-6)[..., None]
    out[..., :3] = rgb
    a = na
    # ink: its colour goes from black (dark=1) to grey (dark small)
    ir = np.array(ink_rgb, float)
    grey = np.array([120, 116, 118], float)
    col = ir[None, None, :] * ink.dark[..., None] + grey[None, None, :] * (1 - ink.dark[..., None])
    ai = ink.a
    na = a + ai * (1 - a)
    rgb = (out[..., :3] * a[..., None] * (1 - ai[..., None]) + col * ai[..., None]) / np.maximum(na, 1e-6)[..., None]
    out[..., :3] = rgb
    out[..., 3] = na * 255
    return np.clip(out, 0, 255).astype(np.uint8)
