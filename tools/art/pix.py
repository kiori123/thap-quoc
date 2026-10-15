"""Tiny pixel-art toolkit: paint material masks, then shade + outline them.

A Canvas stores, per pixel, which material covers it. Rendering turns each
material into a 4-5 tone ramp lit from the top-left, then adds a dark
selective outline around the silhouette.
"""
import numpy as np
from PIL import Image, ImageDraw


def hexc(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ramp(mid, shadow=None, light=None, outline=None, hi=None):
    """Build a tone ramp [outline, shadow, mid, light, highlight] from a mid colour."""
    m = hexc(mid) if isinstance(mid, str) else mid
    sh = hexc(shadow) if isinstance(shadow, str) else (shadow or mix(m, (20, 14, 30), 0.38))
    li = hexc(light) if isinstance(light, str) else (light or mix(m, (255, 246, 222), 0.30))
    ol = hexc(outline) if isinstance(outline, str) else (outline or mix(sh, (12, 8, 14), 0.55))
    h = hexc(hi) if isinstance(hi, str) else (hi or mix(li, (255, 255, 245), 0.45))
    return [ol, sh, m, li, h]


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.mat = np.full((h, w), -1, dtype=np.int32)
        self.tone = np.zeros((h, w), dtype=np.int32)  # forced tone overrides (0 = auto)
        self.order = np.zeros((h, w), dtype=np.int32)  # paint order: later = in front
        self._ctr = 0
        self.mats = []
        self.flat = set()      # materials that skip auto shading
        self.no_outline = set()

    # ---- masks -------------------------------------------------------
    def grid(self):
        yy, xx = np.mgrid[0:self.h, 0:self.w]
        return xx + 0.5, yy + 0.5

    def ellipse(self, cx, cy, rx, ry):
        xx, yy = self.grid()
        return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0

    def rect(self, x0, y0, x1, y1):
        m = np.zeros((self.h, self.w), bool)
        x0, x1 = max(0, int(x0)), min(self.w - 1, int(x1))
        y0, y1 = max(0, int(y0)), min(self.h - 1, int(y1))
        if x1 >= x0 and y1 >= y0:
            m[y0:y1 + 1, x0:x1 + 1] = True
        return m

    def poly(self, pts):
        im = Image.new('L', (self.w, self.h), 0)
        ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in pts], fill=255)
        return np.array(im) > 0

    def line(self, pts, width=1):
        im = Image.new('L', (self.w, self.h), 0)
        ImageDraw.Draw(im).line([(float(x), float(y)) for x, y in pts], fill=255, width=width)
        return np.array(im) > 0

    def px(self, x, y):
        m = np.zeros((self.h, self.w), bool)
        if 0 <= x < self.w and 0 <= y < self.h:
            m[int(y), int(x)] = True
        return m

    # ---- painting ----------------------------------------------------
    def material(self, r, flat=False, outline=True):
        self.mats.append(r)
        idx = len(self.mats) - 1
        if flat:
            self.flat.add(idx)
        if not outline:
            self.no_outline.add(idx)
        return idx

    def paint(self, mask, m, tone=0):
        self._ctr += 1
        self.mat[mask] = m
        self.tone[mask] = tone
        self.order[mask] = self._ctr

    def erase(self, mask):
        self.mat[mask] = -1

    def set_tone(self, mask, tone):
        """Force a tone (1 shadow .. 4 highlight) on already painted pixels."""
        sel = mask & (self.mat >= 0)
        self.tone[sel] = tone

    # ---- render ------------------------------------------------------
    def render(self, light_band=1, shadow_band=1, side_shade=0.0, outline=True, volume=False, selout=False, deep=False,
               side_light=0.0, clean=False):
        """selout: the outline on the lit side (top, left) is a softer tone of the part than on the shadow side.
        deep: a sixth tone (ramp[5]) where a part is shadowed by a part in front of it (needs 6-entry ramps).
        clean: a pixel whose tone none of its neighbours in the same part shares takes theirs (lone pixels of a tone
        read as noise at a sprite's size; the shading reads in clusters)."""
        h, w = self.h, self.w
        mat = self.mat
        out = np.zeros((h, w, 4), np.uint8)
        pad = np.pad(mat, 1, constant_values=-1)
        up = pad[0:h, 1:w + 1]
        down = pad[2:h + 2, 1:w + 1]
        left = pad[1:h + 1, 0:w]
        right = pad[1:h + 1, 2:w + 2]
        tone = np.full((h, w), 2, np.int32)
        filled = mat >= 0
        lit = filled & ((up != mat) | (left != mat))
        shd = filled & ((down != mat) | (right != mat))
        if shadow_band > 1:
            pad2 = np.pad(mat, 2, constant_values=-1)
            down2 = pad2[4:h + 4, 2:w + 2]
            right2 = pad2[2:h + 2, 4:w + 4]
            shd |= filled & ((down2 != mat) | (right2 != mat))
        tone[lit] = 3
        tone[shd] = 1
        tone[lit & shd] = 2
        if volume:
            tone = self._volume_tones(tone, deep)
        if side_shade > 0:
            # cylinder shading: right part of each material's horizontal run darker
            for m in range(len(self.mats)):
                ys, xs = np.where(mat == m)
                if len(xs) == 0:
                    continue
                for y in np.unique(ys):
                    row = xs[ys == y]
                    x0, x1 = row.min(), row.max()
                    span = x1 - x0 + 1
                    if span < 4:
                        continue
                    cut = x1 - int(span * side_shade)
                    sel = (mat[y] == m) & (np.arange(w) > cut)
                    tone[y][sel & (tone[y] == 2)] = 1
                    if side_light > 0 and span >= 5:   # and the left of it toward the light
                        lit_to = x0 + max(1, int(span * side_light))
                        sel = (mat[y] == m) & (np.arange(w) < lit_to)
                        tone[y][sel & (tone[y] == 2)] = 3
        forced = self.tone > 0
        if clean:
            tone = _clean_tones(mat, tone, forced, self.flat)
        tone[forced] = self.tone[forced]
        for m, r in enumerate(self.mats):
            sel = mat == m
            if not sel.any():
                continue
            t = tone.copy()
            if m in self.flat:
                t[sel & ~forced] = 2
            for k in range(1, 6):
                s = sel & (t == k)
                out[s, :3] = r[k] if k < len(r) else r[1]
                out[s, 3] = 255
        if outline:
            # selective outline: empty pixels touching a filled pixel take that material's outline tone
            # (selout: shadow sides first, so a corner takes the dark tone)
            for dy, dx in (((0, 1), (1, 0), (0, -1), (-1, 0)) if selout else ((0, 1), (0, -1), (1, 0), (-1, 0))):
                lit_side = dy < 0 or dx < 0
                src = np.roll(np.roll(mat, dy, 0), dx, 1)
                if dy == 1:
                    src[0, :] = -1
                if dy == -1:
                    src[-1, :] = -1
                if dx == 1:
                    src[:, 0] = -1
                if dx == -1:
                    src[:, -1] = -1
                edge = (mat < 0) & (src >= 0) & (out[:, :, 3] == 0)
                for m, r in enumerate(self.mats):
                    if m in self.no_outline:
                        continue
                    s = edge & (src == m)
                    # selout: on the lit side the edge is the part's own shadow tone, not a dark line (a dark ring
                    # all round is what makes a sprite read as a sticker); on the shadow side and under the feet, dark
                    out[s, :3] = mix(r[1], r[0], 0.3) if (selout and lit_side) else r[0]
                    out[s, 3] = 255
        return Image.fromarray(out, 'RGBA')

    def normal_map(self, img):
        """The shape of the drawing for the engine's lights (shaders/sprite_lit.gdshader ntex), alpha as img's: each
        part bevelled from its own edge (a pixel deep inside a part faces out, one at its edge turns away toward
        that edge), a part painted in front of another standing a little proud of it, and the outline pixels turned
        out from the figure. RGB = normal (x right, y up, z out) * 0.5 + 0.5."""
        mat = self.mat
        h, w = mat.shape
        a = np.array(img)[:, :, 3] > 0
        nx = np.zeros((h, w))
        ny = np.zeros((h, w))
        nz = np.ones((h, w))
        for m in range(len(self.mats)):
            sel = mat == m
            if not sel.any() or m in self.flat:
                continue
            d = _erode_depth(sel).astype(float)
            d = np.minimum(d, 3.0)   # (a bevel three pixels deep: the middle of a broad part faces out, flat)
            gy, gx = np.gradient(d)
            nx[sel] = -gx[sel]
            ny[sel] = gy[sel]          # (image rows run down; y up in the map)
            nz[sel] = (0.35 + 0.65 * np.clip(d[sel] / 3.0, 0.0, 1.0))
        # the outline and anything else drawn but not a part: turned out from the figure's silhouette
        fig = a.astype(float)
        gy, gx = np.gradient(fig)
        rest = a & (mat < 0)
        nx[rest] = -gx[rest] * 2.0
        ny[rest] = gy[rest] * 2.0
        nz[rest] = 0.4
        n = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
        out = np.zeros((h, w, 4), np.uint8)
        out[:, :, 0] = np.clip((nx / n * 0.5 + 0.5) * 255, 0, 255)
        out[:, :, 1] = np.clip((ny / n * 0.5 + 0.5) * 255, 0, 255)
        out[:, :, 2] = np.clip((nz / n * 0.5 + 0.5) * 255, 0, 255)
        out[:, :, 3] = np.where(a, 255, 0)
        return Image.fromarray(out, 'RGBA')


def _clean_tones(mat, tone, forced, flat):
    h, w = mat.shape
    pm = np.pad(mat, 1, constant_values=-1)
    pt = np.pad(tone, 1, constant_values=-9)
    nm = [pm[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))]
    nt = [pt[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))]
    same = [m_ == mat for m_ in nm]
    match = sum(((t_ == tone) & s_).astype(int) for t_, s_ in zip(nt, same))
    n_same = sum(s_.astype(int) for s_ in same)
    lone = (mat >= 0) & (match == 0) & (n_same >= 3) & ~forced & (tone != 5)
    for m in flat:
        lone &= mat != m
    out = tone.copy()
    for y, x in zip(*np.where(lone)):
        votes = {}
        for k in range(4):
            if same[k][y, x]:
                votes[nt[k][y, x]] = votes.get(nt[k][y, x], 0) + 1
        out[y, x] = max(votes.items(), key=lambda kv: (kv[1], kv[0] == 2))[0]
    return out


def _erode_depth(mask):
    """Steps of 4-neighbour erosion each pixel survives (1 = on the edge)."""
    d = np.zeros(mask.shape, np.int32)
    cur = mask.copy()
    k = 0
    while cur.any():
        k += 1
        d[cur] = k
        p = np.pad(cur, 1)
        cur = cur & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return d


LIGHT = np.array([-0.55, -0.62, 0.56])  # from the upper left, a little in front
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def _volume(self, base, deep=False):
    """Round each part: a pseudo-normal from how deep a pixel sits inside its part, lit from the
    upper left; parts painted in front cast a one-pixel shadow down/right onto parts behind."""
    mat = self.mat
    h, w = mat.shape
    tone = base.copy()
    for m in range(len(self.mats)):
        sel = mat == m
        if not sel.any() or m in self.flat:
            continue
        d = _erode_depth(sel).astype(float)
        dmax = max(d.max(), 1.0)
        gy, gx = np.gradient(d)
        nx, ny = -gx, -gy
        nz = np.clip(d / min(dmax, 3.0), 0.25, 1.0) * 1.1
        n = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
        sh = (nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) / n
        t = np.full((h, w), 2, np.int32)
        t[sh > 0.78] = 3
        t[sh < 0.32] = 1
        # keep the crisp edge rule where it is stronger
        t = np.where(base == 1, 1, t)
        t = np.where((base == 3) & (t == 2), 3, t)
        tone[sel] = t[sel]
    # cast shadows from parts in front
    order = self.order
    pad_m = np.pad(mat, 1, constant_values=-1)
    pad_o = np.pad(order, 1, constant_values=0)
    for dy, dx in ((-1, 0), (0, -1)):
        nm = pad_m[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
        no = pad_o[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
        cast = (mat >= 0) & (nm >= 0) & (nm != mat) & (no > order)
        if deep:   # already in shadow and shadowed again: the deepest tone
            tone[cast & (tone == 1)] = 5
        tone[cast & (tone != 5)] = np.maximum(tone[cast & (tone != 5)] - 1, 1)
    return tone


Canvas._volume_tones = _volume


def sheet(frames, cols=None):
    """Pack equally sized RGBA frames into a grid (row-major)."""
    cols = cols or len(frames)
    fw, fh = frames[0].size
    rows = (len(frames) + cols - 1) // cols
    im = Image.new('RGBA', (fw * cols, fh * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        im.paste(f, ((i % cols) * fw, (i // cols) * fh))
    return im


def preview(img, scale=4, bg=(70, 74, 82)):
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    base = Image.new('RGBA', big.size, bg + (255,))
    base.alpha_composite(big)
    return base
