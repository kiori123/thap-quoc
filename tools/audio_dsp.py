"""Small DSP kit for the game's synthesized sound (tools/gen_game_audio.py, tools/gen_title_audio.py): filters, moving
filters, a convolution reverb in stereo, soft saturation, panning, ringing partials, Karplus-Strong strings, and a
writer that masters to a target loudness and keeps the low end where laptop speakers can play it."""
import os
import wave

import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
rng = np.random.default_rng(11)


def t_of(dur):
    return np.arange(int(dur * SR)) / SR


def noise(n):
    return rng.normal(0, 1, n)


def filt(x, kind, fc, order=2):
    return sosfilt(butter(order, fc, kind, fs=SR, output='sos'), x)


def band(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, min(hi, SR / 2 - 200)], 'band', fs=SR, output='sos'), x)


def sweep_lp(x, fc):
    """x low-passed with a cutoff that moves (one value per sample), from a bank of fixed filters crossfaded."""
    bank = [150, 300, 600, 1200, 2400, 4800, 9600, 16000]
    ys = np.stack([filt(x, 'low', f) for f in bank])
    fb = np.array(bank, float)
    pos = np.interp(np.log(np.clip(fc, fb[0], fb[-1])), np.log(fb), np.arange(len(fb)))
    pos = np.clip(pos, 0, len(bank) - 1.001)
    i = pos.astype(int)
    w = pos - i
    n = np.arange(len(x))
    return ys[i, n] * (1 - w) + ys[i + 1, n] * w


def sweep_bp(x, fc, q=1.5):
    """x band-passed round a centre that moves."""
    bank = [200, 300, 450, 700, 1000, 1500, 2200, 3300, 5000, 7500, 11000]
    ys = np.stack([band(x, f / (1 + 0.5 / q), f * (1 + 0.5 / q)) for f in bank])
    fb = np.array(bank, float)
    pos = np.interp(np.log(np.clip(fc, fb[0], fb[-1])), np.log(fb), np.arange(len(fb)))
    pos = np.clip(pos, 0, len(bank) - 1.001)
    i = pos.astype(int)
    w = pos - i
    n = np.arange(len(x))
    return ys[i, n] * (1 - w) + ys[i + 1, n] * w


def reverb(l, r, secs=1.8, wet=0.25, dark=3000, pre=0.012):
    """A room: an exponentially decaying noise impulse per side (so the two sides differ), darker as it dies."""
    t = t_of(secs)
    env = np.exp(-6.9 * t / secs)
    out = []
    for x in (l, r):
        ir = noise(len(t)) * env
        ir = filt(ir, 'low', dark) * 0.65 + ir * 0.35 * np.exp(-t * 4)
        k = int(pre * SR)
        ir[:k] *= np.linspace(0, 1, k)
        ir /= np.sqrt(np.sum(ir ** 2))
        y = fftconvolve(x, ir)[:len(x)]
        out.append(x * (1 - wet) + y * wet * 2.0)
    return out


def drive(x, k):
    """Soft saturation: a deep tone grows the overtones small speakers can play."""
    return np.tanh(x * k) / np.tanh(k)


def pan(x, p):
    """p -1 (left) .. 1 (right), one value or one per sample; equal power."""
    a = (np.asarray(p) + 1) * np.pi / 4
    return x * np.cos(a), x * np.sin(a)


def ring(t, parts, t0=0.0, beat=0.0):
    """Partials (f, decay per s, amplitude) from t0, each doubled a hair off so it shimmers."""
    tt = np.clip(t - t0, 0, None)
    on = (t >= t0).astype(float)
    s = np.zeros_like(t)
    for f, d, a in parts:
        s += (np.sin(2 * np.pi * f * tt) + np.sin(2 * np.pi * (f + beat) * tt + 1.3)) * 0.5 * np.exp(-tt * d) * a
    return s * on * np.minimum(tt / 0.002, 1)


def adsr(n, a=0.005, d=0.1, s=0.6, r=0.2):
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    e[:na] = np.linspace(0, 1, max(na, 1))[:na]
    e[na:na + nd] = np.linspace(1, s, max(nd, 1))[:len(e[na:na + nd])]
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def pluck(freq, dur, bright=0.5, bend=0.0, decay=0.997, body=True):
    """Karplus-Strong string (đàn tranh), a small upward bend at the attack (nhấn) if asked, a wooden body resonance."""
    n = int(dur * SR)
    L = max(2, int(SR / freq))
    exc = noise(L + 1) * (0.5 + bright * 0.5)
    for _ in range(int((1 - bright) * 3)):
        exc = (exc + np.roll(exc, 1)) * 0.5
    out = np.zeros(n + L + 1)
    out[:L + 1] = exc
    for start in range(L + 1, len(out), L):
        end = min(start + L, len(out))
        out[start:end] = decay * 0.5 * (out[start - L:end - L] + out[start - L - 1:end - L - 1])
    out = out[:n]
    if bend:
        tt = np.arange(n)
        warp = 1.0 + bend * np.exp(-tt / (SR * 0.09))
        pos = np.cumsum(1.0 / warp)
        pos = pos / pos[-1] * (n - 1)
        out = np.interp(tt, pos, out)
    if body:
        out = out + band(out, 180, 420) * 0.6
    return out * adsr(n, 0.001, 0.05, 1.0, min(0.15, dur * 0.3))


def flute(freq, dur, vib=0.006, breath=0.1):
    """Bamboo flute (sáo): a soft tone with breath, vibrato that comes in late."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vibrato = 1 + vib * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.15) / 0.3, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vibrato) / SR
    tone = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.07 * np.sin(3 * ph)
    br = band(noise(n), freq * 0.8, freq * 3.5) * breath * 3
    chiff = band(noise(n), 2000, 6000) * np.exp(-t * 40) * 0.3
    return (tone * 0.8 + br + chiff) * adsr(n, 0.05, 0.1, 0.85, min(0.25, dur * 0.35))


def bowed(freq, dur, amp=1.0):
    """A bowed string (đàn nhị-like): a sawtooth through a body filter, bow noise, slow vibrato."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.2) / 0.4, 0, 1)
    ph = np.cumsum(freq * vib) / SR
    saw = 2 * (ph % 1.0) - 1
    s = band(saw, freq * 0.9, freq * 6) + band(noise(n), freq, freq * 4) * 0.08
    s = s + band(s, 600, 1400) * 0.5   # the nasal body
    return s * adsr(n, 0.12, 0.2, 0.8, min(0.3, dur * 0.3)) * amp


def place(track, sig, at):
    i = int(at * SR)
    end = min(len(track), i + len(sig))
    if 0 <= i < len(track):
        track[i:end] += sig[:end - i]


def loopify(l, r, length, tail):
    """Fold the tail back into the start, so the loop is seamless."""
    n = int(length * SR)
    out = []
    for x in (l, r):
        y = x[:n].copy()
        rest = x[n:n + int(tail * SR)]
        y[:len(rest)] += rest
        out.append(y)
    return out


def master(l, r, rms_db, hp=40.0, k=1.4, ceiling=0.97):
    """High-pass below what is heard (it only takes headroom), soft saturation, to a target loudness, under a peak."""
    l, r = filt(l, 'high', hp), filt(r, 'high', hp)
    pk = max(np.abs(l).max(), np.abs(r).max()) + 1e-9
    l, r = drive(l / pk, k), drive(r / pk, k)
    rms = np.sqrt((np.mean(l ** 2) + np.mean(r ** 2)) / 2) + 1e-9
    g = 10 ** (rms_db / 20) / rms
    l, r = l * g, r * g
    pk = max(np.abs(l).max(), np.abs(r).max())
    if pk > ceiling:   # (a softer gain than asked, rather than clipping)
        l, r = l / pk * ceiling, r / pk * ceiling
    return l, r


def write(path, l, r):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.stack([l, r], 1)
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())


def bands_of(l, r):
    """Share of energy in 20-120, 120-500, 500-2k, 2k-6k, 6k+ Hz (for checking a mix)."""
    m = (l + r) * 0.5
    F = np.abs(np.fft.rfft(m)) ** 2
    fr = np.fft.rfftfreq(len(m), 1 / SR)
    e = [F[(fr >= a) & (fr < b)].sum() for a, b in ((20, 120), (120, 500), (500, 2000), (2000, 6000), (6000, 22050))]
    s = sum(e) + 1e-12
    return [round(100 * x / s) for x in e]
