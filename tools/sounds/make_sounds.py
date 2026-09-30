#!/usr/bin/env python3
"""Synthesises the game's sound effects into sounds/*.ogg (and .wav).

Every sound is made from scratch here (oscillators, filtered noise, a small room
reverb), so the pack is original and free to use: upload the .ogg files to Roblox and
paste the ids into src/shared/Config/SoundConfig.lua (docs/SOUNDS.md).

Usage: python3 tools/sounds/make_sounds.py        (needs numpy + soundfile)
"""
import os

import numpy as np
import soundfile as sf

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "sounds")
RNG = np.random.default_rng(1234)


# ------------------------------------------------------------------ building blocks

def t_(dur):
    return np.arange(int(SR * dur)) / SR


def silence(dur):
    return np.zeros(int(SR * dur))


def glide(f0, f1, dur, curve=1.0):
    """Instantaneous frequency from f0 to f1 (exponential by default)."""
    x = np.linspace(0, 1, int(SR * dur)) ** curve
    return f0 * (f1 / f0) ** x


def phase(freq):
    return 2 * np.pi * np.cumsum(freq) / SR


def sine(freq, dur=None):
    if np.isscalar(freq):
        return np.sin(2 * np.pi * freq * t_(dur))
    return np.sin(phase(freq))


def tri(freq, dur=None):
    ph = (freq * t_(dur)) if np.isscalar(freq) else np.cumsum(freq) / SR
    return 2 * np.abs(2 * (ph % 1) - 1) - 1


def soft_square(freq, dur=None, harmonics=7):
    """Band-limited square (odd harmonics) - warm, not harsh."""
    ph = (2 * np.pi * freq * t_(dur)) if np.isscalar(freq) else phase(freq)
    out = np.zeros_like(ph)
    for k in range(1, harmonics * 2, 2):
        out += np.sin(k * ph) / k
    return out * 0.8


def noise(dur):
    return RNG.uniform(-1, 1, int(SR * dur))


def env_exp(n_or_dur, decay, attack=0.002):
    n = n_or_dur if isinstance(n_or_dur, int) else int(SR * n_or_dur)
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-5), 0, 1)
    return a * np.exp(-t / decay)


def env_adsr(dur, a=0.01, d=0.05, s=0.7, r=0.1):
    n = int(SR * dur)
    t = np.arange(n) / SR
    e = np.ones(n) * s
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / d
    rel = t > dur - r
    e[rel] *= np.clip((dur - t[rel]) / r, 0, 1)
    return e


def onepole_lp(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def hp(x, cutoff):
    return x - onepole_lp(x, cutoff)


def bandpass(x, f, q=2.0):
    """RBJ biquad band-pass; f may be an array (swept)."""
    f = np.broadcast_to(np.asarray(f, dtype=float), x.shape)
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        w = 2 * np.pi * f[i] / SR
        alpha = np.sin(w) / (2 * q)
        cw = np.cos(w)
        b0, b2 = alpha, -alpha
        a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
        out = (b0 * v + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, v
        y2, y1 = y1, out
        y[i] = out
    return y


def taper(sig, ms=12):
    """Fade the last few ms so a layer never ends with a click."""
    sig = np.array(sig, dtype=float)
    k = min(len(sig), int(SR * ms / 1000))
    if k > 1:
        sig[-k:] *= np.linspace(1, 0, k) ** 2
    return sig


def at(buf, sig, start, gain=1.0):
    i = int(start * SR)
    end = min(len(buf), i + len(sig))
    buf[i:end] += taper(sig[: end - i], 25) * gain
    return buf


def reverb(x, room=0.35, mix=0.18, tail=0.6):
    """Small bright room: convolution with decaying filtered noise."""
    n = int(SR * tail)
    ir = RNG.normal(0, 1, n) * np.exp(-np.arange(n) / (SR * room * 0.35))
    ir = onepole_lp(ir, 6000)
    ir[: int(SR * 0.008)] = 0  # pre-delay
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    size = len(x) + n
    nfft = 1 << (size - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, nfft) * np.fft.rfft(ir, nfft), nfft)[:size]
    dry = np.concatenate([x, np.zeros(n)])
    return dry * (1 - mix) + wet * mix * 1.4


def bell(freq, dur, decay=0.6, bright=1.0):
    """Glassy bell: slightly inharmonic partials."""
    t = t_(dur)
    out = np.zeros_like(t)
    for ratio, amp, dk in ((1.0, 1.0, 1.0), (2.01, 0.5 * bright, 0.6), (3.02, 0.28 * bright, 0.4), (4.17, 0.18 * bright, 0.3), (5.43, 0.1 * bright, 0.2)):
        out += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / (decay * dk))
    return taper(out * np.clip(t / 0.002, 0, 1), 60)


def coin(freq=988.0, gain=1.0):
    """The classic two-step coin: a short note then a higher, longer one."""
    a = soft_square(freq, 0.07, 4) * env_exp(0.07, 0.05, 0.001)
    b = soft_square(freq * 4 / 3, 0.32, 4) * env_exp(0.32, 0.12, 0.001)
    out = np.concatenate([a, b])
    return onepole_lp(out, 7000) * gain


def pluck(freq, dur=0.4, decay=0.12):
    """Marimba-ish pluck."""
    t = t_(dur)
    out = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t / 0.03)
    return out * env_exp(len(t), decay, 0.001)


def note(name):
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12) / 12)


def finish(x, peak=0.89, fade_out=0.01):
    x = np.asarray(x, dtype=float)
    x = x - np.mean(x)
    f = int(SR * fade_out)
    if f and len(x) > f:
        x[-f:] *= np.linspace(1, 0, f)
    x[: 32] *= np.linspace(0, 1, 32)
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


# ------------------------------------------------------------------ the sounds

def s_pop():
    out = silence(1.2)
    crack = hp(noise(0.05), 1500) * env_exp(0.05, 0.008, 0.0005)
    snap = bandpass(noise(0.09), 1100, 1.4) * env_exp(0.09, 0.025, 0.0005)
    thump = sine(glide(150, 48, 0.18)) * env_exp(0.18, 0.06, 0.001)
    at(out, crack, 0, 1.0)
    at(out, snap, 0.001, 1.6)
    at(out, thump, 0, 0.9)
    # confetti sparkle: little bright pings scattering after the pop
    for _ in range(14):
        f = RNG.uniform(2600, 6200)
        at(out, sine(f, 0.12) * env_exp(0.12, 0.03, 0.001), 0.03 + RNG.uniform(0, 0.4), RNG.uniform(0.04, 0.12))
    out = np.tanh(out * 2.2) / np.tanh(2.2)  # saturate: more body, same peak
    return finish(reverb(out, 0.3, 0.22, 0.5))


def s_launch():
    dur = 0.75
    sweep = glide(350, 2600, dur, 0.8)
    whoosh = bandpass(noise(dur), sweep, 1.6) * env_adsr(dur, 0.12, 0.2, 0.6, 0.35)
    stretch_f = glide(260, 640, 0.42) * (1 + 0.03 * np.sin(2 * np.pi * 18 * t_(0.42)))
    stretch = tri(stretch_f) * env_adsr(0.42, 0.02, 0.1, 0.6, 0.12)
    out = silence(1.0)
    at(out, whoosh, 0, 1.0)
    at(out, onepole_lp(stretch, 3000), 0.02, 0.35)
    return finish(reverb(out, 0.25, 0.12))


def s_tick():
    out = sine(1760, 0.09) + 0.4 * sine(2640, 0.09)
    return finish(out * env_exp(0.09, 0.022, 0.0008), 0.7)


def s_letout():
    dur = 2.0
    n = noise(dur + 0.2)
    hiss = bandpass(n, 4200, 0.9) + 0.5 * bandpass(n, 1700, 1.2)
    flutter = 1 + 0.18 * np.sin(2 * np.pi * 11 * t_(dur + 0.2)) + 0.08 * np.sin(2 * np.pi * 3.1 * t_(dur + 0.2))
    x = hiss * flutter
    # seamless loop: crossfade the extra tail into the start
    k = int(0.2 * SR)
    body = x[: int(dur * SR)].copy()
    ramp = np.linspace(0, 1, k)
    body[:k] = body[:k] * ramp + x[int(dur * SR):int(dur * SR) + k] * (1 - ramp)
    body = body - np.mean(body)
    return body / (np.max(np.abs(body)) + 1e-9) * 0.8


def s_landstart():
    out = silence(0.8)
    at(out, pluck(note("G5")), 0)
    at(out, pluck(note("C6")), 0.09)
    at(out, pluck(note("E6"), 0.5, 0.2), 0.18, 0.7)
    return finish(reverb(out, 0.3, 0.2))


def s_bank():
    out = silence(2.2)
    base = 988.0
    for i in range(11):
        f = base * 2 ** (i / 24)
        at(out, coin(f, 0.55), i * 0.065 + RNG.uniform(0, 0.015))
    for j, n in enumerate(("C6", "E6", "G6", "C7")):
        at(out, bell(note(n), 1.0, 0.5, 0.8), 0.8 + j * 0.05, 0.35)
    for _ in range(10):
        at(out, sine(RNG.uniform(3000, 7000), 0.1) * env_exp(0.1, 0.03), 0.85 + RNG.uniform(0, 0.6), 0.06)
    return finish(reverb(out, 0.4, 0.2))


def s_coinin():
    return finish(coin(1175.0), 0.75, 0.02)


def s_max():
    out = silence(2.2)
    at(out, bell(note("A5"), 2.0, 0.9), 0)
    at(out, bell(note("E6"), 1.8, 0.8, 0.7), 0.08, 0.6)
    at(out, bell(note("A6"), 1.6, 0.7, 0.5), 0.16, 0.45)
    for _ in range(12):
        at(out, sine(RNG.uniform(4000, 8000), 0.08) * env_exp(0.08, 0.02), RNG.uniform(0.1, 1.0), 0.05)
    return finish(reverb(out, 0.5, 0.25, 0.9))


def s_hit():
    out = silence(0.5)
    thud = sine(glide(170, 70, 0.14)) * env_exp(0.14, 0.05, 0.001)
    squeak_f = glide(950, 480, 0.16) * (1 + 0.05 * np.sin(2 * np.pi * 30 * t_(0.16)))
    squeak = tri(squeak_f) * env_adsr(0.16, 0.005, 0.04, 0.6, 0.06)
    smack = bandpass(noise(0.05), 2200, 1.5) * env_exp(0.05, 0.01, 0.0005)
    at(out, thud, 0, 1.0)
    at(out, onepole_lp(squeak, 4000), 0.01, 0.5)
    at(out, smack, 0, 0.8)
    out = np.tanh(out * 1.8) / np.tanh(1.8)
    return finish(reverb(out, 0.2, 0.1))


def s_fall():
    dur = 1.6
    f = glide(1900, 380, dur, 0.9) * (1 + 0.012 * np.sin(2 * np.pi * 6 * t_(dur)))
    x = sine(f) + 0.2 * sine(f * 2)
    return finish(onepole_lp(x, 5000) * env_adsr(dur, 0.05, 0.1, 0.8, 0.4), 0.7)


def s_click():
    body = sine(glide(1500, 900, 0.045)) * env_exp(0.045, 0.012, 0.0005)
    tick = hp(noise(0.01), 3000) * env_exp(0.01, 0.002, 0.0002)
    out = silence(0.06)
    at(out, body, 0)
    at(out, tick, 0, 0.5)
    return finish(out, 0.8, 0.005)


def s_open():
    out = silence(0.35)
    at(out, sine(glide(480, 900, 0.07)) * env_exp(0.07, 0.04, 0.002), 0)
    at(out, sine(glide(720, 1350, 0.08)) * env_exp(0.08, 0.05, 0.002), 0.06, 0.8)
    return finish(reverb(out, 0.2, 0.12), 0.75)


def s_close():
    out = silence(0.3)
    at(out, sine(glide(1100, 620, 0.07)) * env_exp(0.07, 0.04, 0.002), 0)
    at(out, sine(glide(800, 440, 0.08)) * env_exp(0.08, 0.05, 0.002), 0.055, 0.8)
    return finish(reverb(out, 0.2, 0.1), 0.7)


def s_buy():
    out = silence(1.5)
    clack = bandpass(noise(0.03), 3200, 2.0) * env_exp(0.03, 0.006, 0.0003)
    at(out, clack, 0, 1.0)
    at(out, clack, 0.07, 0.7)
    for j, n in enumerate(("E6", "G#6", "B6", "E7")):
        at(out, bell(note(n), 1.2, 0.55, 0.9), 0.12 + j * 0.025, 0.5)
    at(out, coin(1319.0, 0.6), 0.12)
    return finish(reverb(out, 0.35, 0.2))


def s_upgrade():
    out = silence(1.5)
    seq = ("C5", "E5", "G5", "C6", "E6", "G6")
    for i, n in enumerate(seq):
        tone = soft_square(note(n), 0.16, 5) * env_exp(0.16, 0.07, 0.002)
        at(out, onepole_lp(tone, 6000), i * 0.055, 0.5)
    at(out, bell(note("C7"), 1.0, 0.6), 0.36, 0.5)
    for _ in range(10):
        at(out, sine(RNG.uniform(3500, 8000), 0.09) * env_exp(0.09, 0.025), 0.36 + RNG.uniform(0, 0.5), 0.06)
    return finish(reverb(out, 0.4, 0.22))


def s_equip():
    dur = 0.3
    f = np.concatenate([glide(300, 470, 0.12), glide(470, 390, dur - 0.12)])
    f = f * (1 + 0.02 * np.sin(2 * np.pi * 22 * t_(dur)))
    x = tri(f) * env_adsr(dur, 0.005, 0.08, 0.5, 0.12)
    out = silence(0.45)
    at(out, onepole_lp(x, 3500), 0)
    at(out, pluck(note("C6"), 0.3, 0.08), 0.1, 0.4)
    return finish(reverb(out, 0.2, 0.12), 0.8)


def s_error():
    out = silence(0.4)
    for i, f in enumerate((233.1, 196.0)):
        tone = soft_square(f, 0.12, 5) * env_adsr(0.12, 0.004, 0.03, 0.7, 0.04)
        at(out, onepole_lp(tone, 2200), i * 0.12)
    return finish(out, 0.7)


def s_teleport():
    dur = 0.7
    swoosh = bandpass(noise(dur), glide(600, 5000, dur, 0.7), 2.0) * env_adsr(dur, 0.05, 0.1, 0.5, 0.4)
    out = silence(1.1)
    at(out, swoosh, 0, 0.9)
    for i in range(8):
        at(out, sine(1200 * 2 ** (i / 6), 0.12) * env_exp(0.12, 0.04), 0.1 + i * 0.045, 0.25)
    return finish(reverb(out, 0.35, 0.22))


def s_restock():
    out = silence(2.0)
    at(out, bell(note("C6"), 1.3, 0.7), 0)
    at(out, bell(note("G5"), 1.5, 0.8), 0.28)
    return finish(reverb(out, 0.45, 0.2, 0.8))


def brass(freq, dur):
    t = t_(dur)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.25, 0, 1)
    ph = phase(freq * vib)
    x = np.zeros_like(t)
    for k in range(1, 9):
        x += np.sin(k * ph) / k ** 1.1
    x = onepole_lp(x, 2800)
    return x * env_adsr(dur, 0.035, 0.08, 0.75, 0.12)


def s_fanfare():
    out = silence(2.4)
    for i, n in enumerate(("G4", "C5", "E5")):
        at(out, brass(note(n), 0.14), i * 0.12, 0.6)
    for n in ("C5", "E5", "G5", "C6"):
        at(out, brass(note(n), 0.95), 0.4, 0.35)
    at(out, bell(note("C7"), 1.3, 0.6), 0.42, 0.35)
    for _ in range(14):
        at(out, sine(RNG.uniform(3500, 8000), 0.09) * env_exp(0.09, 0.025), 0.45 + RNG.uniform(0, 0.8), 0.05)
    return finish(reverb(out, 0.5, 0.25, 0.9))


SOUNDS = {
    "Pop": s_pop,
    "Launch": s_launch,
    "Tick": s_tick,
    "LetOut": s_letout,
    "LandStart": s_landstart,
    "Bank": s_bank,
    "CoinIn": s_coinin,
    "Max": s_max,
    "Hit": s_hit,
    "Fall": s_fall,
    "Click": s_click,
    "Open": s_open,
    "Close": s_close,
    "Buy": s_buy,
    "Upgrade": s_upgrade,
    "Equip": s_equip,
    "Error": s_error,
    "Teleport": s_teleport,
    "Restock": s_restock,
    "Fanfare": s_fanfare,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = fn().astype(np.float32)
        stereo = np.stack([x, x], axis=1)
        sf.write(os.path.join(OUT, f"{name}.ogg"), stereo, SR, format="OGG", subtype="VORBIS")
        print(f"{name:10s} {len(x) / SR:5.2f}s")
    print("wrote", len(SOUNDS), "sounds to", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
