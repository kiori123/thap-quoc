"""The sounds of the title's cut (scripts/world/vista.gd cut, part_and_go_in), made to carry weight: stereo, 44.1 kHz,
with low end that still reads on small speakers (the booms are driven into soft saturation, so their overtones carry
what a laptop cannot play), and mastered loud. Writes assets/audio/sfx/title_*.wav; touches nothing else.

draw   the sword drawn up out of the rock: stone rasping, then the steel ringing as it comes free
breath the wind-up: a low wind and a drone swelling while the breath is held
slash  the stroke: air torn from right to left along the blade's path, a hard crack where it lands, and the blade
       left singing through the held second after
split  the cloud giving way: a crack, a deep blow, thunder rolling, and a roar of air spreading out to both sides
dive   the camera going in down the channel: wind rising past

Run: python tools/gen_title_audio.py
"""
import os
import wave

import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'audio', 'sfx')
rng = np.random.default_rng(7)


def t_of(dur):
    return np.arange(int(dur * SR)) / SR


def filt(x, kind, fc, order=2):
    return sosfilt(butter(order, fc, kind, fs=SR, output='sos'), x)


def sweep_lp(x, fc):
    """x low-passed with a cutoff that moves (fc: one value per sample): a bank of fixed filters, crossfaded."""
    bank = [200, 400, 800, 1600, 3200, 6400, 12800]
    ys = np.stack([filt(x, 'low', f) for f in bank])
    pos = np.clip(np.log2(np.maximum(fc, 200) / 200.0), 0, len(bank) - 1.001)
    i = pos.astype(int)
    w = pos - i
    n = np.arange(len(x))
    return ys[i, n] * (1 - w) + ys[i + 1, n] * w


def sweep_bp(x, fc, q=1.5):
    """x band-passed round a centre that moves."""
    bank = [300, 450, 700, 1000, 1500, 2200, 3300, 5000, 7500, 11000]
    ys = []
    for f in bank:
        lo, hi = f / (1 + 0.5 / q), min(f * (1 + 0.5 / q), SR / 2 - 100)
        ys.append(sosfilt(butter(2, [lo, hi], 'band', fs=SR, output='sos'), x))
    ys = np.stack(ys)
    fb = np.array(bank, dtype=float)
    pos = np.interp(np.log(np.clip(fc, fb[0], fb[-1])), np.log(fb), np.arange(len(fb)))
    pos = np.clip(pos, 0, len(bank) - 1.001)
    i = pos.astype(int)
    w = pos - i
    n = np.arange(len(x))
    return ys[i, n] * (1 - w) + ys[i + 1, n] * w


def reverb(l, r, secs=2.8, wet=0.3, dark=2500):
    """A wide open space (the sky over the cloud sea): an exponentially decaying noise impulse per side, darker as it
    dies."""
    t = t_of(secs)
    env = np.exp(-6.9 * t / secs)
    out = []
    for x in (l, r):
        ir = rng.normal(0, 1, len(t)) * env
        ir = filt(ir, 'low', dark) * 0.6 + ir * 0.4 * np.exp(-t * 3)
        ir[:int(0.012 * SR)] *= np.linspace(0, 1, int(0.012 * SR))   # (a little gap before the room answers)
        ir /= np.sqrt(np.sum(ir ** 2))
        y = fftconvolve(x, ir)[:len(x)]
        out.append(x * (1 - wet) + y * wet * 2.2)
    return out


def drive(x, k):
    """Soft saturation: louder, and a deep tone grows the overtones small speakers can play."""
    return np.tanh(x * k) / np.tanh(k)


def pan(x, p):
    """p from -1 (left) to 1 (right), one value or one per sample; equal power."""
    a = (np.asarray(p) + 1) * np.pi / 4
    return x * np.cos(a), x * np.sin(a)


def ring(t, parts, t0=0.0, beat=0.0):
    """Steel ringing from t0: partials (f, decay per s, amplitude), each doubled a hair off so it shimmers."""
    tt = np.clip(t - t0, 0, None)
    on = (t >= t0).astype(float)
    s = np.zeros_like(t)
    for f, d, a in parts:
        s += (np.sin(2 * np.pi * f * tt) + np.sin(2 * np.pi * (f + beat) * tt + 1.3)) * 0.5 * np.exp(-tt * d) * a
    return s * on * np.minimum(tt / 0.002, 1)


def write(name, l, r, level=0.97, k=1.5):
    peak = max(np.max(np.abs(l)), np.max(np.abs(r))) + 1e-9
    l, r = drive(l / peak, k), drive(r / peak, k)
    peak = max(np.max(np.abs(l)), np.max(np.abs(r))) + 1e-9
    x = np.stack([l, r], 1) / peak * level
    path = os.path.join(OUT, 'title_%s.wav' % name)
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype('<i2').tobytes())
    rms = np.sqrt(np.mean(x ** 2))
    print('title_%s.wav %.2f s, rms %.1f dBFS' % (name, len(l) / SR, 20 * np.log10(rms + 1e-9)))


def draw():
    t = t_of(1.4)
    rasp = sosfilt(butter(2, [700, 3200], 'band', fs=SR, output='sos'), rng.normal(0, 1, len(t)))
    grit = np.clip(filt(rng.normal(0, 1, len(t)), 'low', 30) * 8, 0, None)   # the grinding comes in catches
    rasp *= (0.4 + grit) * np.clip(t / 0.03, 0, 1) * np.exp(-np.clip(t - 0.16, 0, None) * 40) * (t < 0.3)
    steel = ring(t, ((1870, 3.2, 0.5), (2830, 4.0, 0.42), (4210, 5.2, 0.3), (5650, 6.5, 0.2), (7310, 8, 0.12)), 0.17, 1.6)
    slide = np.sin(2 * np.pi * np.cumsum(2400 + 900 * np.clip((t - 0.1) / 0.08, 0, 1)) / SR) * np.exp(-np.clip(t - 0.1, 0, None) * 30) * (t > 0.1) * 0.25
    s = rasp * 0.9 + steel + slide
    l, r = pan(s, 0.15)
    l, r = reverb(l, r, 2.2, 0.28)
    write('draw', l, r)


def breath():
    t = t_of(0.75)
    up = np.clip(t / 0.6, 0, 1) ** 2 * (1 - np.clip((t - 0.62) / 0.08, 0, 1))
    wind = sweep_lp(rng.normal(0, 1, len(t)), 500 + 2200 * up) * up
    wind2 = sweep_lp(rng.normal(0, 1, len(t)), 500 + 2200 * up) * up
    drone = np.sin(2 * np.pi * np.cumsum(55 + 20 * up) / SR) * up * 0.5
    drone += np.sin(2 * np.pi * np.cumsum(110 + 40 * up) / SR) * up * 0.45
    drone += np.sin(2 * np.pi * np.cumsum(165 + 60 * up) / SR) * up * 0.25
    rise = np.sin(2 * np.pi * np.cumsum(380 + 260 * up) / SR) * up ** 2 * 0.08
    l = wind * 2.2 + drive(drone, 3.0) * 0.6 + rise * 2.0
    r = wind2 * 2.2 + drive(drone, 3.0) * 0.6 + rise * 2.0
    write('breath', l, r, 0.9)


def slash():
    t = t_of(2.4)
    hit = 0.07
    # the air torn along the blade, from the upper right to the lower left, high to low
    sw = np.clip(t / hit, 0, 1)
    fc = 7500 * (1 - sw) + 1300 * sw
    tear = sweep_bp(rng.normal(0, 1, len(t)), fc, 1.2)
    tear *= np.clip(t / hit, 0, 1) ** 1.5 * np.exp(-np.clip(t - hit, 0, None) * 14)
    tl, tr = pan(tear * 1.4, 0.9 - 1.8 * np.clip(t / (hit + 0.08), 0, 1))
    # where it lands: a hard crack and a short heavy body
    tt = np.clip(t - hit, 0, None)
    on = (t >= hit).astype(float)
    click = filt(rng.normal(0, 1, len(t)), 'high', 1800) * np.exp(-tt * 260) * on * 1.3
    body = np.sin(2 * np.pi * np.cumsum((95 * np.exp(-tt * 9) + 46) * on) / SR) * np.exp(-tt * 9) * on * 1.6
    body = drive(body, 2.5)
    # and the blade left singing through the held second
    sing = ring(t, ((3120, 1.3, 0.32), (4680, 1.8, 0.2), (2480, 1.1, 0.16), (6230, 2.6, 0.1)), hit + 0.01, 3.5)
    air = filt(rng.normal(0, 1, len(t)), 'low', 2200) * np.exp(-tt * 6) * on * 0.3
    cl, cr = pan(click + body + air, -0.2)
    sl, sr = pan(sing, -0.35)
    l, r = tl + cl + sl, tr + cr + sr
    l, r = reverb(l, r, 2.6, 0.3)
    write('slash', l, r, 0.97, 1.8)


def split():
    t = t_of(5.0)
    # the crack as it gives
    crack = filt(rng.normal(0, 1, len(t)), 'high', 900) * np.exp(-t * 90) * 1.4
    # the blow: a deep fall in pitch, driven so its overtones carry
    boom = np.sin(2 * np.pi * np.cumsum(34 + 60 * np.exp(-t * 3.5)) / SR) * np.exp(-t * 1.6) * 0.65
    boom = drive(boom, 4.0)
    thump = np.sin(2 * np.pi * np.cumsum(170 * np.exp(-t * 9) + 92) / SR) * np.exp(-t * 2.6) * 1.5
    thump = drive(thump, 2.5)
    chest = filt(rng.normal(0, 1, len(t)), 'band', [90, 320]) * np.exp(-t * 2.0) * (1 - np.exp(-t * 60)) * 2.4
    # thunder rolling on after it: cracks coming thinner and further apart, low and dark
    roll = np.zeros_like(t)
    tk = 0.05
    while tk < 2.2:
        i = int(tk * SR)
        m = int(rng.uniform(0.04, 0.16) * SR)
        if i + m < len(t):
            roll[i:i + m] += rng.normal(0, 1, m) * np.exp(-np.arange(m) / m * 5) * np.exp(-tk * 1.4) * rng.uniform(0.5, 1.2)
        tk += rng.uniform(0.03, 0.12) * (1 + tk * 1.5)
    roll = filt(roll, 'low', 2200) * 2.2
    rumble = filt(filt(rng.normal(0, 1, len(t)), 'low', 260), 'high', 70) * (1 - np.exp(-t * 12)) * np.exp(-t * 0.75) * 2.4
    rumble *= 0.7 + 0.3 * np.sin(2 * np.pi * 1.7 * t + 0.4)
    # the roar of air: it opens fast and spreads out to both sides as the cloud is driven apart
    fc = 350 + 5200 * np.exp(-((t - 0.22) / 0.32) ** 2) + 900 * np.exp(-t * 0.8)
    env = (1 - np.exp(-t * 18)) * np.exp(-t * 0.7)
    n_l = sweep_lp(rng.normal(0, 1, len(t)), fc) * env * 3.6
    n_r = sweep_lp(rng.normal(0, 1, len(t)), fc) * env * 3.6
    mid = (n_l + n_r) * 0.5
    wide = np.clip(t / 0.6, 0, 1)   # one roar in the middle, then two going apart
    a_l = mid * (1 - wide) + n_l * wide
    a_r = mid * (1 - wide) + n_r * wide
    low = boom + thump + chest + rumble * 0.6
    l = low + crack + roll * 0.9 + a_l
    r = low + crack + roll * 0.8 + a_r
    l, r = reverb(l, r, 3.4, 0.32, 1800)
    l, r = filt(l, 'high', 38), filt(r, 'high', 38)   # (below this nothing is heard, it only takes headroom)
    write('split', l, r, 0.98, 2.0)


def dive():
    t = t_of(3.0)
    up = np.clip(t / 2.2, 0, 1)
    env = up ** 1.5 * (1 - np.clip((t - 2.5) / 0.5, 0, 1))
    fc = 400 + 1500 * up
    l = sweep_bp(rng.normal(0, 1, len(t)), fc, 0.9) * env
    r = sweep_bp(rng.normal(0, 1, len(t)), fc, 0.9) * env
    flutter = 1 + 0.25 * np.sin(2 * np.pi * np.cumsum(5 + 9 * up) / SR)
    low = filt(rng.normal(0, 1, len(t)), 'low', 140) * env * 1.4
    write('dive', l * flutter + low, r * flutter + low, 0.9)


if __name__ == '__main__':
    draw()
    breath()
    slash()
    split()
    dive()
