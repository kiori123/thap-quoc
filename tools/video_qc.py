"""Frame-by-frame QC of a recorded run (a Movie Maker capture): what a viewer would notice that a still does not show.

  python tools/video_qc.py <video> <out_dir> [--every=4]

Per frame: brightness, clipped white, sharpness (Laplacian), motion (difference from the frame before). Then:
  snaps   one frame that changes far more than its neighbours, outside a fade (a camera cut or jump mid-move)
  black   stretches darker than a fade-through-black should last
  clip    frames where a lot of the picture is burnt white
  blur    stretches much softer than the run around them
Writes report.json, a thumbnail every --every seconds and one at each event (out_dir/thumbs), and prints a summary.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

FF = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Microsoft', 'WinGet', 'Packages',
                  'Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe', 'ffmpeg-8.1.2-full_build', 'bin')
W, H = 320, 180


def frames(path):
    p = subprocess.Popen([os.path.join(FF, 'ffmpeg'), '-v', 'error', '-i', path, '-vf', 'scale=%d:%d' % (W, H),
                          '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
    n = W * H * 3
    while True:
        b = p.stdout.read(n)
        if len(b) < n:
            break
        yield np.frombuffer(b, np.uint8).reshape(H, W, 3)


def fps_of(path):
    out = subprocess.run([os.path.join(FF, 'ffprobe'), '-v', 'error', '-select_streams', 'v:0', '-show_entries',
                          'stream=r_frame_rate', '-of', 'csv=p=0', path], capture_output=True, text=True).stdout.strip()
    a, b = out.split('/')
    return float(a) / float(b)


def main():
    path, out = sys.argv[1], sys.argv[2]
    every = 4.0
    for a in sys.argv[3:]:
        if a.startswith('--every='):
            every = float(a.split('=')[1])
    os.makedirs(os.path.join(out, 'thumbs'), exist_ok=True)
    fps = fps_of(path)
    lum, clip, sharp, motion = [], [], [], []
    prev = None
    keep = {}
    for i, f in enumerate(frames(path)):
        g = f.mean(2)
        lum.append(float(g.mean()))
        clip.append(float((f.max(2) >= 250).mean() * 100))
        sharp.append(float(np.abs(g[1:-1, 1:-1] * 4 - g[:-2, 1:-1] - g[2:, 1:-1] - g[1:-1, :-2] - g[1:-1, 2:]).mean()))
        # how much the whole picture moved: the median over a grid of blocks, so a box of text popping up in one part
        # of the frame does not count, and a camera jumping (which moves every block) does
        if prev is not None:
            dd = np.abs(g - prev)[:H // 6 * 6, :W // 8 * 8].reshape(6, H // 6, 8, W // 8).mean((1, 3))
            motion.append(float(np.median(dd)))
        else:
            motion.append(0.0)
        prev = g
        if i % int(round(every * fps)) == 0:
            Image.fromarray(f).save(os.path.join(out, 'thumbs', 't_%06.1f.png' % (i / fps)))
        keep[i] = f   # (a short window, for the event thumbnails)
        if i - 4 in keep:
            del keep[i - 4]
        # an event is decided two frames late; keep the frames round it
        j = i - 2
        if j >= 2:
            nb = np.median([motion[j - 2], motion[j - 1], motion[j + 1], motion[j + 2]])
            if motion[j] > 8 and motion[j] > 4 * nb and lum[j] > 35 and lum[j - 1] > 35:
                for k in (j - 1, j):
                    if k in keep:
                        Image.fromarray(keep[k]).save(os.path.join(out, 'thumbs', 'snap_%06.2f_%s.png' % (j / fps, 'a' if k < j else 'b')))
    n = len(lum)
    lum, clip, sharp, motion = map(np.array, (lum, clip, sharp, motion))
    ev = {'snaps': [], 'black': [], 'clip': [], 'blur': []}
    for j in range(2, n - 2):
        nb = np.median([motion[j - 2], motion[j - 1], motion[j + 1], motion[j + 2]])
        if motion[j] > 8 and motion[j] > 4 * nb and lum[j] > 35 and lum[j - 1] > 35:
            ev['snaps'].append([round(j / fps, 2), round(float(motion[j]), 1)])
    # black stretches
    j = 0
    while j < n:
        if lum[j] < 12:
            k = j
            while k < n and lum[k] < 12:
                k += 1
            if (k - j) / fps >= 0.5:
                ev['black'].append([round(j / fps, 2), round((k - j) / fps, 2)])
            j = k
        else:
            j += 1
    # clipping
    j = 0
    while j < n:
        if clip[j] > 4:
            k = j
            while k < n and clip[k] > 4:
                k += 1
            ev['clip'].append([round(j / fps, 2), round((k - j) / fps, 2), round(float(clip[j:k].max()), 1)])
            j = k
        else:
            j += 1
    # blur: much softer than the 20 s around it, for over a second, not dark
    win = int(20 * fps)
    j = 0
    while j < n:
        ref = np.median(sharp[max(0, j - win):j + win])
        if lum[j] > 30 and sharp[j] < 0.35 * ref:
            k = j
            while k < n and lum[k] > 30 and sharp[k] < 0.35 * ref:
                k += 1
            if (k - j) / fps >= 1.0:
                ev['blur'].append([round(j / fps, 2), round((k - j) / fps, 2)])
            j = k
        else:
            j += 1
    json.dump({'fps': fps, 'frames': n, 'events': ev, 'lum': lum.round(1).tolist(), 'clip': clip.round(2).tolist(),
               'sharp': sharp.round(2).tolist(), 'motion': motion.round(2).tolist()}, open(os.path.join(out, 'report.json'), 'w'))
    print('frames', n, 'at', fps, 'fps =', round(n / fps, 1), 's')
    for k, v in ev.items():
        print(k, len(v), v[:40])


if __name__ == '__main__':
    main()
