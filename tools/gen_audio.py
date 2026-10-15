"""Synthesize music loops and sound effects for the prologue (numpy only).

Instruments: Karplus-Strong plucked string (đàn tranh-like, with a small pitch bend),
breathy bamboo flute (sáo), soft pads, frame drums. Writes 16-bit mono WAV files.
"""
import os
import wave
import numpy as np

SR = 32000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(1)


def write(path, x, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) + 1e-9
    if peak > 0.98:
        x = x / peak * 0.98
    data = (x * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env_adsr(n, a=0.005, d=0.1, s=0.6, r=0.2):
    t = np.arange(n) / SR
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    e[:na] = np.linspace(0, 1, max(na, 1))[:na]
    e[na:na + nd] = np.linspace(1, s, max(nd, 1))[:len(e[na:na + nd])]
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def pluck(freq, dur, bright=0.5, bend=0.0, decay=0.996):
    """Karplus-Strong with optional upward pitch bend at the attack (đàn tranh nhấn)."""
    n = int(dur * SR)
    L = max(2, int(SR / freq))
    exc = (rng.random(L + 1) * 2 - 1) * (0.5 + bright * 0.5)
    for _ in range(int((1 - bright) * 3)):
        exc = (exc + np.roll(exc, 1)) * 0.5
    out = np.zeros(n + L + 1)
    out[:L + 1] = exc
    for start in range(L + 1, len(out), L):
        end = min(start + L, len(out))
        out[start:end] = decay * 0.5 * (out[start - L:end - L] + out[start - L - 1:end - L - 1])
    out = out[:n]
    if bend:
        # resample to create a short bend toward the target pitch
        t = np.arange(n)
        warp = 1.0 + bend * np.exp(-t / (SR * 0.08))
        pos = np.cumsum(1.0 / warp)
        pos = pos / pos[-1] * (n - 1)
        out = np.interp(t, pos, out)
    out *= env_adsr(n, 0.001, 0.05, 1.0, min(0.15, dur * 0.3))
    return out


def flute(freq, dur, vib=0.006, breath=0.08):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vibrato = 1 + vib * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.25, 0, 1)
    phase = 2 * np.pi * np.cumsum(freq * vibrato) / SR
    tone = np.sin(phase) + 0.25 * np.sin(2 * phase) + 0.08 * np.sin(3 * phase)
    noise = rng.normal(0, 1, n)
    noise = np.convolve(noise, np.ones(8) / 8, mode='same')
    sig = tone * 0.8 + noise * breath
    return sig * env_adsr(n, 0.06, 0.1, 0.85, min(0.25, dur * 0.35))


def pad(freqs, dur, amp=0.15):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for f in freqs:
        for det in (-0.6, 0.6):
            s += np.sin(2 * np.pi * (f + det) * t) + 0.3 * np.sin(2 * np.pi * (f * 2 + det) * t)
    return s * amp / len(freqs) * env_adsr(n, dur * 0.3, 0.1, 0.9, dur * 0.35)


def drum(kind, dur=0.4):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if kind == 'low':
        f = 70 * np.exp(-t * 8) + 48
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)
        s += rng.normal(0, 0.15, n) * np.exp(-t * 40)
    elif kind == 'mid':
        f = 160 * np.exp(-t * 10) + 110
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11)
        s += rng.normal(0, 0.2, n) * np.exp(-t * 30)
    else:  # rim / wood click
        s = rng.normal(0, 1, n) * np.exp(-t * 90)
        s += np.sin(2 * np.pi * 900 * t) * np.exp(-t * 60) * 0.6
    return s


def reverb(x, wet=0.25, room=0.82):
    """Small Schroeder reverb."""
    out = np.copy(x)
    acc = np.zeros(len(x) + SR)
    xs = np.concatenate([x, np.zeros(SR)])
    for d, g in ((1557, room), (1617, room), (1491, room), (1422, room)):
        acc += _comb(xs, d, g)
    acc /= 4
    for d, g in ((225, 0.5), (556, 0.5)):
        acc = _allpass(acc, d, g)
    full = np.concatenate([out, np.zeros(SR)])
    return full * (1 - wet) + acc * wet


def _comb(x, d, g):
    y = np.copy(x)
    # process in chunks of d: y[n] = x[n] + g*y[n-d]
    for start in range(d, len(x), d):
        end = min(start + d, len(x))
        y[start:end] += g * y[start - d:end - d]
    return y


def _allpass(x, d, g):
    y = np.zeros_like(x)
    buf = np.zeros_like(x)
    for start in range(0, len(x), d):
        end = min(start + d, len(x))
        delayed = buf[start - d:end - d] if start >= d else np.zeros(end - start)
        v = x[start:end] + g * delayed
        y[start:end] = -g * v + delayed
        buf[start:end] = v
    return y


def place(track, sig, at):
    i = int(at * SR)
    end = min(len(track), i + len(sig))
    if i < len(track):
        track[i:end] += sig[:end - i]


def loopify(x, length, tail):
    """Fold the reverb tail back into the start so the loop is seamless."""
    n = int(length * SR)
    y = x[:n].copy()
    rest = x[n:n + int(tail * SR)]
    y[:len(rest)] += rest
    return y


# --------------------------------------------------------------- scales / melodies
# A-based Northern pentatonic (do re fa sol la) shifted: notes in MIDI around D minor pentatonic feel
PENTA = [62, 64, 67, 69, 71, 74, 76, 79, 81]  # D E G A B D E G A


def music_village():
    bpm = 72
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    tr = np.zeros(int((L + 3) * SR))
    # original lullaby-like melody (scale degrees into PENTA), (index, beats)
    mel = [(4, 1), (3, 1), (2, 2), (1, 1), (2, 1), (3, 2),
           (4, 1), (5, 1), (4, 1), (3, 1), (2, 4),
           (2, 1), (1, 1), (0, 2), (1, 1), (2, 1), (3, 2),
           (2, 1), (1, 1), (0, 1), (1, 1), (0, 4)]
    t = 0.0
    for rep in range(2):
        for (deg, b) in mel:
            f = midi(PENTA[deg])
            s = pluck(f, b * beat + 0.6, bright=0.45, bend=0.03 if b >= 2 else 0.0)
            place(tr, s * 0.55, t)
            t += b * beat
    # flute answers in the second half, an octave up, sparse
    for (deg, at, b) in ((6, 32, 2), (5, 34, 2), (4, 36, 4), (5, 40, 2), (4, 42, 2), (3, 44, 4),
                         (4, 48, 2), (3, 50, 2), (2, 52, 4), (3, 56, 2), (2, 58, 2), (1, 60, 4)):
        place(tr, flute(midi(PENTA[deg]) * 1.0, b * beat) * 0.18, at * beat)
    # bass plucks on bar starts
    roots = [50, 55, 50, 57] * 4
    for i, r in enumerate(roots):
        place(tr, pluck(midi(r), 4 * beat, bright=0.2) * 0.35, i * 4 * beat)
    # soft pad bed
    for i in range(bars // 2):
        chord = [midi(62), midi(69), midi(74)] if i % 2 == 0 else [midi(67), midi(71), midi(74)]
        place(tr, pad(chord, 8 * beat + 1.0, 0.12), i * 8 * beat)
    out = reverb(tr, wet=0.3)
    return loopify(out, L, 2.5)


def music_night():
    bpm = 60
    beat = 60 / bpm
    L = 16 * 4 * beat
    tr = np.zeros(int((L + 3) * SR))
    mel = [(4, 2), (3, 2), (2, 4), (1, 2), (2, 2), (0, 4), (2, 2), (3, 2), (4, 4), (3, 2), (2, 2), (1, 4)]
    t = 4 * beat
    for (deg, b) in mel:
        place(tr, pluck(midi(PENTA[deg]), b * beat + 1.0, bright=0.25, bend=0.02) * 0.45, t)
        t += b * beat * 1.6
    for i in range(8):
        place(tr, pad([midi(50), midi(57), midi(62)], 8 * beat + 1, 0.1), i * 8 * beat)
    # crickets
    n = len(tr)
    tt = np.arange(n) / SR
    chirp = np.sin(2 * np.pi * 4300 * tt) * (np.sin(2 * np.pi * 28 * tt) > 0.6) * (np.sin(2 * np.pi * 0.7 * tt) > 0.2)
    tr += chirp * 0.025
    out = reverb(tr, wet=0.35)
    return loopify(out, L, 2.5)


def music_battle():
    bpm = 132
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    tr = np.zeros(int((L + 2) * SR))
    for b in range(bars):
        for k in range(8):  # eighth notes
            at = (b * 4 + k * 0.5) * beat
            if k in (0, 3, 6):
                place(tr, drum('low') * 0.8, at)
            if k in (2, 6):
                place(tr, drum('mid') * 0.5, at)
            if k % 2 == 1:
                place(tr, drum('rim') * 0.18, at)
    # ostinato in D minor-ish pentatonic
    ost = [62, 65, 67, 69, 67, 65, 62, 60]
    for b in range(bars):
        shift = (0, 0, -2, 3)[b % 4]
        for k, nn in enumerate(ost):
            place(tr, pluck(midi(nn + shift), beat * 0.6, bright=0.7) * 0.32, (b * 4 + k * 0.5) * beat)
    # flute stabs
    for b in range(0, bars, 2):
        place(tr, flute(midi(74 + (0, 3, -2, 5)[(b // 2) % 4]), beat * 1.5, vib=0.01) * 0.2, (b * 4 + 2) * beat)
    out = reverb(tr, wet=0.18, room=0.7)
    return loopify(out, L, 1.5)


def music_tension():
    L = 24.0
    n = int((L + 3) * SR)
    t = np.arange(n) / SR
    drone = np.sin(2 * np.pi * 55 * t) * 0.3 + np.sin(2 * np.pi * 55.7 * t) * 0.3 + np.sin(2 * np.pi * 82.4 * t) * 0.15
    drone *= 0.6 + 0.4 * np.sin(2 * np.pi * 0.08 * t)
    tr = drone * 0.5
    for i in range(10):  # glassy porcelain tones
        f = midi(rng.choice([86, 88, 91, 93, 98]))
        at = rng.uniform(0, L - 2)
        m = int(2.5 * SR)
        tt = np.arange(m) / SR
        s = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt * 2.2)
        place(tr, s * 0.12, at)
    out = reverb(tr, wet=0.4)
    return loopify(out, L, 2.5)


def music_title():
    return music_village()


# --------------------------------------------------------------- SFX
def sfx_chop():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    thunk = np.sin(2 * np.pi * (180 * np.exp(-t * 18) + 90) * t) * np.exp(-t * 14)
    crack = rng.normal(0, 1, n) * np.exp(-t * 35)
    crack = np.convolve(crack, [1, -0.6], mode='same')
    return thunk * 0.8 + crack * 0.5


def sfx_chop_bad():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * (120 * np.exp(-t * 10) + 70) * t) * np.exp(-t * 16) * 0.8 + rng.normal(0, 0.2, n) * np.exp(-t * 20)


def sfx_sweep():
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n)
    s = np.convolve(s, np.ones(6) / 6, mode='same')
    return s * np.sin(np.pi * t / t[-1]) ** 2 * 0.6


def sfx_water():
    n = int(0.7 * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for k in range(9):
        f = rng.uniform(500, 1400)
        at = rng.uniform(0, 0.4)
        i = int(at * SR)
        m = n - i
        tt = np.arange(m) / SR
        s[i:] += np.sin(2 * np.pi * (f + 900 * tt) * tt) * np.exp(-tt * 30) * 0.3
    s += np.convolve(rng.normal(0, 0.2, n), np.ones(20) / 20, mode='same') * np.exp(-t * 4)
    return s


def sfx_hit():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * (300 * np.exp(-t * 30) + 80) * t) * np.exp(-t * 18) + rng.normal(0, 0.6, n) * np.exp(-t * 40)) * 0.8


def sfx_shatter():
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n) * np.exp(-t * 7)
    s = s - np.convolve(s, np.ones(4) / 4, mode='same')
    for k in range(14):
        f = rng.uniform(2500, 6500)
        i = int(rng.uniform(0, 0.3) * SR)
        tt = np.arange(n - i) / SR
        s[i:] += np.sin(2 * np.pi * f * tt) * np.exp(-tt * rng.uniform(10, 25)) * 0.25
    return s * 0.7


def sfx_parry():
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((1240, 6), (1870, 8), (2650, 10)))
    return s * 0.35 + rng.normal(0, 0.5, n) * np.exp(-t * 60)


def sfx_ui(f=880, dur=0.07):
    n = int(dur * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t) * np.exp(-t * 40) * 0.5


def sfx_text():
    n = int(0.03 * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * 620 * t) * np.exp(-t * 120) * 0.25


def sfx_heal():
    out = np.zeros(int(0.9 * SR))
    for i, nn in enumerate((74, 79, 83, 86)):
        place(out, pluck(midi(nn), 0.6, bright=0.6) * 0.4, i * 0.09)
    return out


def sfx_roar():
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n)
    s = np.convolve(s, np.ones(60) / 60, mode='same')
    s *= np.sin(np.pi * np.clip(t / 1.6, 0, 1))
    drone = np.sin(2 * np.pi * (60 + 20 * np.sin(2 * np.pi * 3 * t)) * t) * 0.5
    glass = np.sin(2 * np.pi * 2200 * t) * 0.05 * np.sin(np.pi * t / 1.6)
    return (s * 3 + drone + glass) * 0.7


def sfx_vision():
    n = int(2.0 * SR)
    t = np.arange(n) / SR
    sweep = np.sin(2 * np.pi * np.cumsum(200 + 1600 * (t / 2) ** 2) / SR) * np.sin(np.pi * t / 2) * 0.3
    bell = np.sin(2 * np.pi * 523 * t) * np.exp(-t * 1.5) * 0.3 + np.sin(2 * np.pi * 1047 * t) * np.exp(-t * 2.5) * 0.15
    return reverb(sweep + bell, wet=0.5)[:n]


def sfx_whoosh():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n)
    s = np.convolve(s, np.ones(10) / 10, mode='same')
    return s * np.sin(np.pi * t / t[-1]) * 0.7


def sfx_step():
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n) * np.exp(-t * 60)
    return np.convolve(s, np.ones(12) / 12, mode='same') * 0.5


def sfx_bell():
    n = int(2.5 * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) * a for f, d, a in ((220, 1.2, 1), (440 * 1.19, 1.8, 0.5), (660 * 1.33, 2.5, 0.3)))
    return s * 0.4


def sfx_wall():
    """The Nghiệt hitting the invisible boundary: a deep thud plus a ringing shimmer."""
    n = int(1.8 * SR)
    t = np.arange(n) / SR
    thud = np.sin(2 * np.pi * (60 * np.exp(-t * 6) + 35) * t) * np.exp(-t * 4)
    shimmer = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * 2) for f in (660, 990, 1320)) * 0.08
    return reverb(thud + shimmer, wet=0.4)[:n]


def sfx_glint():
    """Telegraph before a Nghiệt strikes: a cold porcelain 'shing'."""
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) * a for f, d, a in ((2350, 7, 0.5), (3530, 9, 0.35), (4710, 12, 0.2)))
    s += np.sin(2 * np.pi * (1200 + 2600 * t) * t) * np.exp(-t * 14) * 0.2
    return reverb(s * 0.6, wet=0.35)[:n]


def sfx_crack():
    """Porcelain hands breaking up through the ground."""
    n = int(0.75 * SR)
    t = np.arange(n) / SR
    rumble = np.convolve(rng.normal(0, 1, n), np.ones(60) / 60, mode='same') * np.exp(-t * 5) * 2.2
    s = rumble + np.sin(2 * np.pi * (70 * np.exp(-t * 3) + 30) * t) * np.exp(-t * 6) * 0.6
    for k in range(10):
        i = int(rng.uniform(0, 0.35) * SR)
        m = int(0.03 * SR)
        if i + m < n:
            s[i:i + m] += rng.normal(0, 0.8, m) * np.exp(-np.arange(m) / m * 6)
    return s * 0.6


def sfx_impact():
    """A heavy hit landing on the hero."""
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * (140 * np.exp(-t * 22) + 55) * t) * np.exp(-t * 10)
    crunch = rng.normal(0, 1, n) * np.exp(-t * 28)
    crunch = crunch - np.convolve(crunch, np.ones(6) / 6, mode='same')
    return (thump * 1.0 + crunch * 0.7) * 0.85


def sfx_tick():
    """Bịt Mắt count-in: a dry tap on porcelain, short and high, unlike anything else in the fight."""
    n = int(0.16 * SR)
    t = np.arange(n) / SR
    click = rng.normal(0, 1, n) * np.exp(-t * 400)
    ring = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) * a for f, d, a in ((1760, 38, 0.6), (2640, 46, 0.35), (3960, 60, 0.2)))
    return (click * 0.5 + ring) * 0.7


def sfx_reveal():
    """Trắng Tay comes out of the mist: a long breath drawn in, then porcelain, many small bells struck at once
    over a low thud, ringing out cold."""
    n = int(3.2 * SR)
    t = np.arange(n) / SR
    hit = 1.1
    breath = np.convolve(rng.normal(0, 1, n), np.ones(40) / 40, mode='same')
    breath *= np.clip(t / hit, 0, 1) ** 3 * (t < hit) * 1.6
    tt = np.clip(t - hit, 0, None)
    on = (t >= hit).astype(float)
    bells = np.zeros(n)
    for f, d, a in ((1318, 1.6, 0.5), (1567, 1.9, 0.45), (2093, 2.4, 0.4), (2489, 2.8, 0.3), (3135, 3.5, 0.25),
                    (3729, 4.2, 0.2), (4698, 5.0, 0.15)):
        f2 = f * (1 + rng.uniform(-0.004, 0.004))
        bells += (np.sin(2 * np.pi * f * tt) + np.sin(2 * np.pi * f2 * tt)) * np.exp(-tt * d) * a
    thud = np.sin(2 * np.pi * (50 * np.exp(-tt * 4) + 32) * tt) * np.exp(-tt * 2.2) * 1.4
    return reverb((breath + (bells * 0.5 + thud) * on) * 0.6, wet=0.45)[:n]


def main():
    mus = os.path.join(ROOT, 'assets', 'audio', 'music')
    sfx = os.path.join(ROOT, 'assets', 'audio', 'sfx')
    jobs = {
        os.path.join(mus, 'village.wav'): music_village,
        os.path.join(mus, 'night.wav'): music_night,
        os.path.join(mus, 'battle.wav'): music_battle,
        os.path.join(mus, 'tension.wav'): music_tension,
        os.path.join(sfx, 'chop.wav'): sfx_chop,
        os.path.join(sfx, 'chop_bad.wav'): sfx_chop_bad,
        os.path.join(sfx, 'sweep.wav'): sfx_sweep,
        os.path.join(sfx, 'water.wav'): sfx_water,
        os.path.join(sfx, 'hit.wav'): sfx_hit,
        os.path.join(sfx, 'shatter.wav'): sfx_shatter,
        os.path.join(sfx, 'parry.wav'): sfx_parry,
        os.path.join(sfx, 'ui_move.wav'): lambda: sfx_ui(700, 0.05),
        os.path.join(sfx, 'ui_ok.wav'): lambda: sfx_ui(1100, 0.09),
        os.path.join(sfx, 'ui_back.wav'): lambda: sfx_ui(440, 0.08),
        os.path.join(sfx, 'text.wav'): sfx_text,
        os.path.join(sfx, 'heal.wav'): sfx_heal,
        os.path.join(sfx, 'roar.wav'): sfx_roar,
        os.path.join(sfx, 'vision.wav'): sfx_vision,
        os.path.join(sfx, 'whoosh.wav'): sfx_whoosh,
        os.path.join(sfx, 'step.wav'): sfx_step,
        os.path.join(sfx, 'bell.wav'): sfx_bell,
        os.path.join(sfx, 'wall.wav'): sfx_wall,
        os.path.join(sfx, 'glint.wav'): sfx_glint,
        os.path.join(sfx, 'reveal.wav'): sfx_reveal,
        os.path.join(sfx, 'crack.wav'): sfx_crack,
        os.path.join(sfx, 'impact.wav'): sfx_impact,
        os.path.join(sfx, 'tick.wav'): sfx_tick,
    }
    for path, fn in jobs.items():
        x = fn()
        write(path, x)
        print(os.path.basename(path), round(len(x) / SR, 2), 's')


if __name__ == '__main__':
    main()
