"""The game's sound, remade (2026-10-14; the author: "làm âm thanh"): every effect and the four music loops, stereo at
44.1 kHz, built so they carry on small speakers (the weight in 100 Hz to 4 kHz, not under 80 Hz where a laptop plays
nothing), each effect at about the loudness of the one it replaces so the game's own levels still hold (a few that were
too weak, a little louder). Same file names, so no code changes: assets/audio/sfx/*.wav, assets/audio/music/*.wav.
The old generator (tools/gen_audio.py) is kept; this one replaces its output.

Run: python tools/gen_game_audio.py [name ...]   (no names: all)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from audio_dsp import (SR, t_of, noise, filt, band, sweep_bp, sweep_lp, reverb, drive, pan, ring, pluck, flute, bowed,
                       place, loopify, master, write, bands_of, rng)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, 'assets', 'audio', 'sfx')
MUS = os.path.join(ROOT, 'assets', 'audio', 'music')


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def mono(x, p=0.0, rev=None):
    l, r = pan(x, p)
    if rev:
        l, r = reverb(l, r, *rev)
    return l, r


def env(t, a, d):
    return np.minimum(t / max(a, 1e-4), 1) * np.exp(-np.clip(t - a, 0, None) * d)


# ------------------------------------------------------------------ the world
def step():
    """A footstep on packed earth and stone: a soft heel, the grit under it."""
    t = t_of(0.16)
    heel = np.sin(2 * np.pi * np.cumsum(150 * np.exp(-t * 30) + 90) / SR) * env(t, 0.002, 45) * 0.8
    grit = band(noise(len(t)), 1500, 6000) * env(t, 0.004, 55) * 0.35
    scuff = band(noise(len(t)), 300, 1500) * env(t, 0.01, 30) * 0.4
    return mono(heel + grit + scuff, 0.0, (0.5, 0.12, 2500))


def water():
    """Water dipped and poured: a splash, bubbles rising, the trickle after."""
    t = t_of(0.9)
    s = band(noise(len(t)), 500, 5000) * env(t, 0.005, 9) * 0.5
    for k in range(22):   # bubbles: short rising sines
        at = rng.uniform(0.0, 0.55)
        f0 = rng.uniform(500, 1600)
        tt = np.clip(t - at, 0, None)
        s += np.sin(2 * np.pi * (f0 * tt + f0 * 2.5 * tt * tt)) * np.exp(-tt * rng.uniform(30, 60)) * (t >= at) * rng.uniform(0.08, 0.2)
    trickle = band(noise(len(t)), 1500, 7000) * (0.15 + 0.1 * np.sin(2 * np.pi * 13 * t)) * np.exp(-t * 3)
    return mono(s + trickle * 0.4, 0.0, (0.8, 0.18, 4000))


def chop():
    """The axe into a log: the bite (a sharp crack), the wood's knock, the halves falling apart."""
    t = t_of(0.7)
    bite = band(noise(len(t)), 2500, 9000) * env(t, 0.0005, 120) * 1.2
    knock = np.sin(2 * np.pi * np.cumsum(420 * np.exp(-t * 20) + 260) / SR) * env(t, 0.001, 18)
    knock += band(noise(len(t)), 250, 900) * env(t, 0.002, 25) * 0.8
    tt = np.clip(t - 0.09, 0, None)
    split = band(noise(len(t)), 800, 3500) * np.exp(-tt * 40) * (t > 0.09) * 0.5
    fall = np.sin(2 * np.pi * np.cumsum(180 * np.exp(-tt * 15) + 110) / SR) * np.exp(-tt * 14) * (t > 0.16) * 0.5
    return mono(drive(bite + knock + split + fall, 1.6), 0.0, (0.7, 0.15, 3500))


def chop_bad():
    """The axe glancing off: a dull knock, the handle buzzing in the hands."""
    t = t_of(0.5)
    knock = np.sin(2 * np.pi * np.cumsum(240 * np.exp(-t * 12) + 150) / SR) * env(t, 0.002, 20)
    buzz = band(noise(len(t)), 300, 1200) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 38 * t))) * env(t, 0.01, 9) * 0.35
    return mono(knock + buzz + band(noise(len(t)), 2000, 6000) * env(t, 0.001, 80) * 0.4, 0.0, (0.6, 0.12, 3000))


def sweep():
    """A stroke of the broom over earth: bristles dragging, rising and falling."""
    t = t_of(0.55)
    e = np.sin(np.pi * np.clip(t / 0.5, 0, 1)) ** 1.5
    s = sweep_bp(noise(len(t)), 1500 + 2500 * e, 1.3) * e
    grain = band(noise(len(t)), 4000, 10000) * e * (rng.random(len(t)) > 0.97) * 3
    l, r = pan(s + grain * 0.3, 0.4 - 0.8 * np.clip(t / 0.55, 0, 1))
    return reverb(l, r, 0.6, 0.12)


def bell():
    """The village bell: a struck bronze bowl, its partials beating, ringing out."""
    t = t_of(3.5)
    s = ring(t, ((220, 1.0, 1.0), (220 * 2.01, 1.5, 0.55), (220 * 2.76, 2.0, 0.45), (220 * 4.07, 2.8, 0.25),
                 (220 * 5.4, 3.5, 0.12)), 0.0, 0.7)
    s += band(noise(len(t)), 800, 3000) * env(t, 0.001, 60) * 0.3
    return mono(drive(s * 0.8, 1.2), 0.0, (3.0, 0.3, 3000))


def text():
    """A line of speech typing out: a soft dry tick of a brush on paper."""
    t = t_of(0.05)
    s = band(noise(len(t)), 1800, 5000) * env(t, 0.0005, 160) * 0.6 + np.sin(2 * np.pi * 900 * t) * env(t, 0.001, 140) * 0.3
    return mono(s)


def ui(kind):
    """The lacquer board: a soft wooden tap to move, a tap and a small bell to choose, a lower tap to go back."""
    t = t_of(0.35)
    tap_f = {'move': 1100, 'ok': 900, 'back': 600}[kind]
    tap = np.sin(2 * np.pi * np.cumsum(tap_f * 1.6 * np.exp(-t * 60) + tap_f) / SR) * env(t, 0.0008, 70)
    tap += band(noise(len(t)), 2500, 7000) * env(t, 0.0005, 200) * 0.3
    if kind == 'ok':
        tap += ring(t, ((1760, 9, 0.35), (2640, 12, 0.18)), 0.012, 2.0)
    if kind == 'back':
        tap = filt(tap, 'low', 2500)
    return mono(tap, 0.0, (0.4, 0.1))


def heal():
    """Medicine taken: a few soft strings going up, warm."""
    t = t_of(1.2)
    out = np.zeros(len(t))
    for i, nn in enumerate((74, 78, 81, 86)):
        place(out, pluck(midi(nn), 0.8, bright=0.5) * 0.45, i * 0.08)
    out += band(noise(len(t)), 300, 2000) * np.exp(-t * 3) * 0.05
    return mono(out, 0.1, (1.4, 0.3, 4000))


def vision():
    """The Duyên glimpse: the world drawn in like a breath, a high cold tone, a hollow."""
    t = t_of(2.2)
    up = np.clip(t / 1.2, 0, 1) ** 2 * (1 - np.clip((t - 1.6) / 0.6, 0, 1))
    air = sweep_bp(noise(len(t)), 400 + 3000 * up, 1.0) * up
    tone = (np.sin(2 * np.pi * 880 * t) + 0.5 * np.sin(2 * np.pi * 1320.5 * t) + 0.3 * np.sin(2 * np.pi * 1767 * t)) * up * 0.25
    l1, r1 = pan(air * 0.8, -0.3)
    l2, r2 = pan(tone, 0.3)
    return reverb(l1 + l2, r1 + r2, 2.6, 0.4)


# ------------------------------------------------------------------ the fight
def whoosh():
    """A blade through the air: a fast rising and falling rush, across."""
    t = t_of(0.35)
    e = np.sin(np.pi * np.clip(t / 0.3, 0, 1)) ** 2
    s = sweep_bp(noise(len(t)), 900 + 4500 * e, 1.4) * e
    l, r = pan(s, 0.6 - 1.2 * np.clip(t / 0.3, 0, 1))
    return reverb(l, r, 0.6, 0.12)


def hit():
    """The blade biting porcelain: a hard click, a short ring, the crack under it."""
    t = t_of(0.4)
    click = band(noise(len(t)), 3000, 10000) * env(t, 0.0003, 180)
    body = np.sin(2 * np.pi * np.cumsum(500 * np.exp(-t * 35) + 220) / SR) * env(t, 0.001, 28) * 0.9
    tink = ring(t, ((2900, 22, 0.3), (4300, 28, 0.2)), 0.002, 4)
    return mono(drive(click + body + tink, 1.5), 0.0, (0.6, 0.14, 4000))


def impact():
    """A heavy blow landing on the protagonist: a thump in the chest, a crunch, the air knocked out."""
    t = t_of(0.6)
    thump = np.sin(2 * np.pi * np.cumsum(200 * np.exp(-t * 22) + 95) / SR) * env(t, 0.001, 12) * 1.2
    crunch = band(noise(len(t)), 600, 4000) * env(t, 0.001, 30) * 0.8
    air = band(noise(len(t)), 200, 900) * env(t, 0.01, 8) * 0.4
    return mono(drive(thump + crunch + air, 2.2), 0.0, (0.8, 0.14, 2500))


def parry():
    """Steel meeting porcelain and holding: a bright clang, a scrape, the ring."""
    t = t_of(0.9)
    clang = ring(t, ((1180, 5.5, 0.6), (1793, 7, 0.45), (2652, 9, 0.35), (3790, 12, 0.22), (5030, 16, 0.12)), 0.0, 3.0)
    hitn = band(noise(len(t)), 2500, 9000) * env(t, 0.0003, 120)
    scrape = band(noise(len(t)), 2000, 6000) * env(t, 0.03, 18) * 0.25 * (t > 0.02)
    l, r = pan(clang + hitn + scrape, 0.15)
    return reverb(l, r, 1.4, 0.22)


def shatter():
    """A Mảnh Sành breaking: the face cracks, pieces of porcelain falling and skittering across both sides."""
    t = t_of(1.2)
    l = np.zeros(len(t))
    r = np.zeros(len(t))
    crack = band(noise(len(t)), 1500, 9000) * env(t, 0.0005, 35) * 0.9
    l += crack
    r += crack
    for k in range(34):   # shards: short high rings, scattered in time and across
        at = rng.uniform(0.0, 0.45) * (1 + k / 34)
        f = rng.uniform(2400, 7000)
        tt = np.clip(t - at, 0, None)
        s = (np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 1.51 * tt)) * np.exp(-tt * rng.uniform(25, 60)) * (t >= at)
        s += band(noise(len(t)), 3000, 9000) * np.exp(-tt * 200) * (t >= at) * 0.5
        a, b = pan(s * rng.uniform(0.08, 0.2), rng.uniform(-0.9, 0.9))
        l += a
        r += b
    thud = np.sin(2 * np.pi * np.cumsum(160 * np.exp(-t * 20) + 110) / SR) * env(t, 0.001, 18) * 0.5
    return reverb(l + thud, r + thud, 1.2, 0.2, 5000)


def crack():
    """Porcelain hands breaking up out of the ground: the earth heaving, ceramic cracking in runs."""
    t = t_of(1.0)
    heave = band(noise(len(t)), 90, 400) * env(t, 0.03, 4) * 1.2
    heave += np.sin(2 * np.pi * np.cumsum(110 + 30 * np.exp(-t * 3)) / SR) * env(t, 0.02, 5) * 0.6
    cracks = np.zeros(len(t))
    tk = 0.0
    while tk < 0.55:
        i = int(tk * SR)
        m = int(rng.uniform(0.01, 0.04) * SR)
        if i + m < len(t):
            cracks[i:i + m] += band(noise(m), 1200, 7000) * np.exp(-np.arange(m) / m * 6) * rng.uniform(0.5, 1.0)
        tk += rng.uniform(0.015, 0.07)
    l, r = pan(drive(heave, 1.8) + cracks, 0.0)
    return reverb(l, r, 1.1, 0.2, 3000)


def glint():
    """Before a Nghiệt strikes: a cold porcelain shing."""
    t = t_of(0.7)
    s = ring(t, ((2350, 7, 0.5), (3530, 9, 0.35), (4710, 12, 0.2), (1570, 6, 0.25)), 0.0, 5.0)
    s += sweep_bp(noise(len(t)), 2000 + 4000 * np.clip(t / 0.15, 0, 1), 2.0) * env(t, 0.03, 18) * 0.3
    l, r = pan(s, 0.2)
    return reverb(l, r, 1.4, 0.3)


def tick():
    """Bịt Mắt's count-in: a dry tap on porcelain."""
    t = t_of(0.2)
    s = band(noise(len(t)), 3000, 9000) * env(t, 0.0003, 350) * 0.6
    s += ring(t, ((1760, 38, 0.6), (2640, 46, 0.35), (3960, 60, 0.2)), 0.0, 2.0)
    return mono(s, 0.0, (0.5, 0.15))


def wall():
    """A Nghiệt hitting the boundary at the pass: a heavy blow on nothing, the air ringing like glass."""
    t = t_of(2.0)
    thud = np.sin(2 * np.pi * np.cumsum(160 * np.exp(-t * 7) + 85) / SR) * env(t, 0.002, 5) * 1.2
    thud = drive(thud, 2.5) + band(noise(len(t)), 120, 600) * env(t, 0.003, 9) * 0.6
    shim = ring(t, ((660, 2.0, 0.25), (990, 2.4, 0.2), (1320, 3.0, 0.15), (1980, 3.6, 0.1)), 0.02, 2.5)
    l, r = pan(thud + shim, 0.0)
    return reverb(l, r, 2.2, 0.3, 2500)


def gate():
    """The city gate swinging on its posts (Bạch Sơn, scripts/world/bach_son.gd set_gate): the iron hinges groaning
    as the leaves turn, the white bars rattling in their frames, and the leaves meeting the stops with a heavy wooden
    knock at the end of the swing (1.2 s, the gate's own time)."""
    t = t_of(2.2)
    n = len(t)
    # the hinge: stick and slip, a train of tiny catches whose rate wanders as the weight turns, through the iron
    rate = 70 + 45 * np.sin(2 * np.pi * 0.9 * t) + 25 * np.sin(2 * np.pi * 2.3 * t + 1.0)
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0.0) > 0).astype(float)
    creak = band(pulses, 380, 2400) * 6 + band(pulses, 850, 1250) * 5
    creak *= np.clip(t / 0.08, 0, 1) * np.clip((1.15 - t) / 0.25, 0, 1) * (0.55 + 0.45 * np.sin(2 * np.pi * 1.6 * t) ** 2)
    # the bars knocking in their frames as it moves
    rat = np.zeros(n)
    for _ in range(10):
        at = rng.uniform(0.05, 1.12)
        rat += ring(t, ((rng.uniform(1200, 2400), 38, 0.22), (rng.uniform(2600, 3800), 55, 0.1)), at)
    # the leaves meeting the stops: a deep wooden knock, and the rattle of the bars it shakes
    t0 = 1.2
    tk = np.clip(t - t0, 0, None)
    on = (t >= t0).astype(float)
    knock = np.sin(2 * np.pi * np.cumsum(120 * np.exp(-tk * 10) + 72) / SR) * env(tk, 0.002, 7) * on * 1.3
    knock = drive(knock, 2.2) + band(noise(n), 150, 900) * env(tk, 0.002, 14) * on * 0.7
    for _ in range(5):
        rat += ring(t, ((rng.uniform(1400, 2600), 30, 0.18),), t0 + rng.uniform(0.01, 0.12))
    knock = band(knock, 90, 3000)   # (the knock's weight where a laptop plays it, the boom under 90 Hz gone)
    l, r = pan(creak * 1.6 + rat * 1.4, -0.15)
    kl, kr = pan(knock * 0.8, 0.05)
    return reverb(l + kl, r + kr, 1.8, 0.28, 2600)


def roar():
    """Trắng Tay: many porcelain throats at once, grinding, hollow, cold over it."""
    t = t_of(1.8)
    e = np.sin(np.pi * np.clip(t / 1.7, 0, 1)) ** 0.8
    l = np.zeros(len(t))
    r = np.zeros(len(t))
    for k in range(5):
        f0 = rng.uniform(85, 140)
        vib = 1 + 0.03 * np.sin(2 * np.pi * rng.uniform(4, 7) * t + k)
        ph = np.cumsum(f0 * vib) / SR
        saw = 2 * (ph % 1.0) - 1
        voice = band(saw, 300, 900) * 0.7 + band(saw, 1200, 2600) * 0.35   # (formants: a throat, not a hum)
        a, b = pan(voice * e * 0.4, rng.uniform(-0.7, 0.7))
        l += a
        r += b
    grind = band(noise(len(t)), 800, 3500) * (0.5 + 0.5 * np.sin(2 * np.pi * 23 * t)) * e * 0.3
    cold = ring(t, ((2200, 1.0, 0.05), (3310, 1.4, 0.03)), 0.2)
    l, r = l + grind + cold, r + grind + cold
    l, r = drive(l, 1.8), drive(r, 1.8)
    return reverb(l, r, 1.8, 0.3, 3000)


def reveal():
    """Trắng Tay coming out of the mist: a long breath drawn in, then porcelain, many small bells over a blow."""
    t = t_of(3.4)
    hit = 1.1
    breath = sweep_bp(noise(len(t)), 300 + 2200 * np.clip(t / hit, 0, 1) ** 2, 1.0) * np.clip(t / hit, 0, 1) ** 3 * (t < hit) * 1.4
    tt = np.clip(t - hit, 0, None)
    on = (t >= hit).astype(float)
    bells = np.zeros(len(t))
    for f, d, a in ((1318, 1.6, 0.5), (1567, 1.9, 0.45), (2093, 2.4, 0.4), (2489, 2.8, 0.3), (3135, 3.5, 0.25), (3729, 4.2, 0.2)):
        bells += (np.sin(2 * np.pi * f * tt) + np.sin(2 * np.pi * f * 1.004 * tt)) * np.exp(-tt * d) * a
    blow = np.sin(2 * np.pi * np.cumsum(220 * np.exp(-tt * 5) + 105) / SR) * np.exp(-tt * 2.0) * 1.2
    blow = drive(blow, 2.5) + band(noise(len(t)), 100, 500) * np.exp(-tt * 2.5) * 0.6
    l1, r1 = pan(breath, 0.0)
    l2, r2 = pan(bells * 0.35 * on, -0.3)
    l3, r3 = pan(bells * 0.35 * on, 0.3)
    l = l1 + l2 + l3 * 0.7 + blow * on
    r = r1 + r2 * 0.7 + r3 + blow * on
    return reverb(l, r, 3.0, 0.4, 3000)


SFX_JOBS = {   # name: (maker, target rms dBFS: about what it replaced, a little more for the ones that were too weak)
    'step': (step, -25.0), 'water': (water, -19.5), 'chop': (chop, -19.0), 'chop_bad': (chop_bad, -18.0),
    'sweep': (sweep, -17.5), 'bell': (bell, -18.0), 'text': (text, -24.0), 'ui_move': (lambda: ui('move'), -18.0),
    'ui_ok': (lambda: ui('ok'), -18.0), 'ui_back': (lambda: ui('back'), -18.5), 'heal': (heal, -22.0),
    'vision': (vision, -18.0), 'whoosh': (whoosh, -16.5), 'hit': (hit, -17.0), 'impact': (impact, -17.5),
    'parry': (parry, -18.0), 'shatter': (shatter, -19.0), 'crack': (crack, -18.0), 'glint': (glint, -20.0),
    'tick': (tick, -19.0), 'wall': (wall, -16.0), 'roar': (roar, -13.5), 'reveal': (reveal, -17.0),
    'gate': (gate, -19.0),
}


# ------------------------------------------------------------------ music
def _stereo_track(L):
    n = int((L + 4) * SR)
    return np.zeros(n), np.zeros(n)


def _put(tr, sig, at, p):
    l, r = pan(sig, p)
    place(tr[0], l, at)
    place(tr[1], r, at)


PENTA = [62, 64, 67, 69, 71, 74, 76, 79, 81]


def village():
    """Morning in the valley: đàn tranh carrying the tune, sáo answering, a bass string on each bar, a soft bed."""
    bpm = 72
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    tr = _stereo_track(L)
    mel = [(4, 1), (3, 1), (2, 2), (1, 1), (2, 1), (3, 2), (4, 1), (5, 1), (4, 1), (3, 1), (2, 4),
           (2, 1), (1, 1), (0, 2), (1, 1), (2, 1), (3, 2), (2, 1), (1, 1), (0, 1), (1, 1), (0, 4)]
    t = 0.0
    for rep in range(2):
        for deg, b in mel:
            _put(tr, pluck(midi(PENTA[deg]), b * beat + 0.8, bright=0.5, bend=0.035 if b >= 2 else 0.0) * 0.5, t, -0.25)
            t += b * beat
    for deg, at, b in ((6, 32, 2), (5, 34, 2), (4, 36, 4), (5, 40, 2), (4, 42, 2), (3, 44, 4),
                       (4, 48, 2), (3, 50, 2), (2, 52, 4), (3, 56, 2), (2, 58, 2), (1, 60, 4)):
        _put(tr, flute(midi(PENTA[deg]), b * beat) * 0.22, at * beat, 0.35)
    for i, rt in enumerate([50, 55, 50, 57] * 4):
        _put(tr, pluck(midi(rt), 4 * beat, bright=0.25) * 0.4, i * 4 * beat, 0.0)
        _put(tr, pluck(midi(rt + 12), 2 * beat, bright=0.35) * 0.15, (i * 4 + 2) * beat, 0.1)   # (the octave, audible on small speakers)
    for i in range(bars // 2):
        ch = [62, 69, 74] if i % 2 == 0 else [67, 71, 74]
        for k, nn in enumerate(ch):
            _put(tr, bowed(midi(nn), 8 * beat + 1.0, 0.035), i * 8 * beat, (-0.6, 0.0, 0.6)[k])
    l, r = reverb(tr[0], tr[1], 2.2, 0.28)
    return loopify(l, r, L, 3.0)


def night():
    """Night at the house: slow strings, a low bed, crickets left and right."""
    bpm = 60
    beat = 60 / bpm
    L = 16 * 4 * beat
    tr = _stereo_track(L)
    mel = [(4, 2), (3, 2), (2, 4), (1, 2), (2, 2), (0, 4), (2, 2), (3, 2), (4, 4), (3, 2), (2, 2), (1, 4)]
    t = 4 * beat
    for deg, b in mel:
        _put(tr, pluck(midi(PENTA[deg]), b * beat + 1.2, bright=0.3, bend=0.025) * 0.45, t, -0.2)
        t += b * beat * 1.6
    for i in range(8):
        for k, nn in enumerate((50, 57, 62)):
            _put(tr, bowed(midi(nn + 12 * (k == 0)), 8 * beat + 1, 0.04), i * 8 * beat, (-0.5, 0.5, 0.0)[k])
    n = len(tr[0])
    tt = np.arange(n) / SR
    for p, f, rate in ((-0.8, 4300, 28), (0.75, 4650, 31)):
        chirp = np.sin(2 * np.pi * f * tt) * (np.sin(2 * np.pi * rate * tt) > 0.6) * (np.sin(2 * np.pi * 0.7 * tt + p) > 0.2)
        a, b = pan(chirp * 0.02, p)
        tr[0][:] += a
        tr[1][:] += b
    l, r = reverb(tr[0], tr[1], 2.6, 0.32)
    return loopify(l, r, L, 3.0)


def drum(kind, dur=0.5):
    """Frame drums and a taiko-like low drum, with their skin and body where small speakers hear them."""
    t = t_of(dur)
    if kind == 'low':
        s = np.sin(2 * np.pi * np.cumsum(170 * np.exp(-t * 10) + 88) / SR) * env(t, 0.001, 8)
        s = drive(s * 1.3, 2.5) + band(noise(len(t)), 200, 900) * env(t, 0.002, 25) * 0.5
    elif kind == 'mid':
        s = np.sin(2 * np.pi * np.cumsum(260 * np.exp(-t * 14) + 170) / SR) * env(t, 0.001, 14)
        s += band(noise(len(t)), 500, 2500) * env(t, 0.001, 30) * 0.5
    else:   # rim / wood
        s = band(noise(len(t)), 2000, 8000) * env(t, 0.0003, 90) + np.sin(2 * np.pi * 900 * t) * env(t, 0.0005, 60) * 0.5
    return s


def battle():
    """A fight: low drums on the strong beats, frame drums, wood ticks, a running string figure, sáo stabs, a bowed line."""
    bpm = 132
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    tr = _stereo_track(L)
    for b in range(bars):
        for k in range(8):
            at = (b * 4 + k * 0.5) * beat
            if k in (0, 3, 6):
                _put(tr, drum('low') * 0.75, at, 0.0)
            if k in (2, 6):
                _put(tr, drum('mid') * 0.5, at, -0.3)
            if k % 2 == 1:
                _put(tr, drum('rim') * 0.2, at, 0.4)
    ost = [62, 65, 67, 69, 67, 65, 62, 60]
    for b in range(bars):
        sh = (0, 0, -2, 3)[b % 4]
        for k, nn in enumerate(ost):
            _put(tr, pluck(midi(nn + sh), beat * 0.6, bright=0.75) * 0.3, (b * 4 + k * 0.5) * beat, -0.35)
    for b in range(0, bars, 2):
        _put(tr, flute(midi(74 + (0, 3, -2, 5)[(b // 2) % 4]), beat * 1.5, vib=0.01) * 0.22, (b * 4 + 2) * beat, 0.4)
    for b in range(0, bars, 4):   # a bowed line under it, the tension held
        _put(tr, bowed(midi(57 + (0, -2, 3, 0)[(b // 4) % 4]), 4 * 4 * beat, 0.08), b * 4 * beat, 0.25)
    l, r = reverb(tr[0], tr[1], 1.4, 0.16)
    return loopify(l, r, L, 2.0)


def tension():
    """Dread (Trắng Tay near): a held bowed drone in the low middle, slow beating, porcelain tones dropping in, a breath."""
    L = 24.0
    tr = _stereo_track(L)
    n = len(tr[0])
    t = np.arange(n) / SR
    for f, p, a in ((110, -0.4, 0.07), (110.6, 0.4, 0.07), (164.8, 0.0, 0.04), (220.4, -0.2, 0.02)):
        d = bowed(f, L + 3.5, a)
        d *= 0.6 + 0.4 * np.sin(2 * np.pi * 0.06 * t[:len(d)] + p * 3)
        _put(tr, d, 0.0, p)
    breath = sweep_bp(noise(n), 500 + 400 * np.sin(2 * np.pi * 0.05 * t), 1.0) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t)) * 0.05
    _put(tr, breath, 0.0, 0.0)
    for i in range(12):
        f = midi(rng.choice([86, 88, 91, 93, 98]))
        tt = t_of(2.8)
        s = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt * 2.0) * 0.1
        _put(tr, s, rng.uniform(0, L - 2.5), rng.uniform(-0.8, 0.8))
    l, r = reverb(tr[0], tr[1], 3.2, 0.4, 2500)
    return loopify(l, r, L, 3.0)


MUSIC_JOBS = {'village': (village, -20.0), 'night': (night, -21.0), 'battle': (battle, -19.0), 'tension': (tension, -21.0)}


def main():
    want = set(sys.argv[1:])
    for name, (fn, rms) in SFX_JOBS.items():
        if want and name not in want:
            continue
        l, r = fn()
        l, r = master(l, r, rms, hp=60.0)
        write(os.path.join(SFX, name + '.wav'), l, r)
        print('sfx  %-9s %4.2fs  %s' % (name, len(l) / SR, bands_of(l, r)))
    for name, (fn, rms) in MUSIC_JOBS.items():
        if want and name not in want:
            continue
        l, r = fn()
        l, r = master(l, r, rms, hp=45.0, k=1.2)
        write(os.path.join(MUS, name + '.wav'), l, r)
        print('mus  %-9s %5.1fs  %s' % (name, len(l) / SR, bands_of(l, r)))


if __name__ == '__main__':
    main()
