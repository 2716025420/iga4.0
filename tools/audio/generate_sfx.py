"""Generate warm tactile procedural WAV sound effects for IGA into assets/audio/sfx."""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SR = 44100
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def _write_wav(name: str, samples: list[float]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    peak = max((abs(s) for s in samples), default=1.0)
    scale = 0.88 / max(peak, 1e-6) if peak > 0.88 else 1.0
    pcm = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s * scale))
        pcm += struct.pack("<h", int(v * 32767.0))
    path = OUT_DIR / f"{name}.wav"
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(bytes(pcm))


def _env(t: float, attack: float, decay: float, dur: float) -> float:
    if t < 0.0 or t > dur:
        return 0.0
    a = min(1.0, t / attack) if attack > 0.0 else 1.0
    rel = max(0.0, 1.0 - max(0.0, (t - (dur - decay)) / max(decay, 1e-5))) if decay > 0.0 else 1.0
    return a * math.exp(-3.5 * (t / max(dur, 1e-5))) * min(1.0, rel * 2.5)


def _bp_noise(n: int, center_hz: float, q: float, seed: int = 1) -> list[float]:
    rng = random.Random(seed)
    w0 = 2.0 * math.pi * center_hz / SR
    alpha = math.sin(w0) / (2.0 * max(q, 0.2))
    b0, b1, b2 = alpha, 0.0, -alpha
    a0 = 1.0 + alpha
    a1 = -2.0 * math.cos(w0)
    a2 = 1.0 - alpha
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for _ in range(n):
        x0 = rng.uniform(-1.0, 1.0)
        y0 = (b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, x0
        y2, y1 = y1, y0
        out.append(y0)
    return out


def gen_all() -> int:
    # 1. sfx_ui_click
    dur = 0.06
    ns = _bp_noise(int(SR * dur), 1800, 1.4, 10)
    s = [(_env(i / SR, 0.002, 0.03, dur) * (0.38 * math.sin(2 * math.pi * (420 - 180 * (i / SR / dur)) * (i / SR)) + 0.14 * ns[i])) for i in range(int(SR * dur))]
    _write_wav("sfx_ui_click", s)

    # 2. sfx_ui_hover
    dur = 0.035
    s = [_env(i / SR, 0.003, 0.02, dur) * 0.16 * math.sin(2 * math.pi * 880 * (i / SR)) for i in range(int(SR * dur))]
    _write_wav("sfx_ui_hover", s)

    # 3. sfx_page_flip
    dur = 0.16
    ns = _bp_noise(int(SR * dur), 2400, 0.9, 20)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        swish = math.sin(math.pi * t / dur) ** 1.4 * (0.7 + 0.3 * math.sin(2 * math.pi * 14 * t))
        s.append(0.32 * ns[i] * swish)
    _write_wav("sfx_page_flip", s)

    # 4. sfx_modal_open
    dur = 0.20
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        v = 0.28 * _env(t, 0.004, 0.12, 0.14) * math.sin(2 * math.pi * 523.25 * t)
        v += 0.28 * _env(t - 0.055, 0.004, 0.14, 0.145) * math.sin(2 * math.pi * 659.25 * max(0.0, t - 0.055))
        s.append(v)
    _write_wav("sfx_modal_open", s)

    # 5. sfx_save_chime
    dur = 0.42
    notes = [(0.0, 523.25), (0.075, 659.25), (0.15, 783.99)]
    s = [0.0] * int(SR * dur)
    for start, freq in notes:
        for i in range(int(SR * dur)):
            t = i / SR - start
            if t >= 0.0:
                s[i] += 0.25 * math.exp(-8.5 * t) * (math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t))
    _write_wav("sfx_save_chime", s)

    # 6. sfx_card_play
    dur = 0.14
    ns = _bp_noise(int(SR * dur), 2800, 1.2, 30)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        f = 540 + 260 * (t / dur)
        s.append(_env(t, 0.003, 0.07, dur) * (0.34 * math.sin(2 * math.pi * f * t) + 0.20 * ns[i]))
    _write_wav("sfx_card_play", s)

    # 7. sfx_shield_up
    dur = 0.30
    ns = _bp_noise(int(SR * dur), 3200, 2.2, 40)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        lift = 1.0 + 0.35 * (t / dur)
        tone = math.sin(2 * math.pi * 330 * lift * t) + 0.5 * math.sin(2 * math.pi * 660 * lift * t) + 0.25 * math.sin(2 * math.pi * 990 * lift * t)
        s.append(_env(t, 0.015, 0.16, dur) * (0.22 * tone + 0.14 * ns[i]))
    _write_wav("sfx_shield_up", s)

    # 8. sfx_heal
    dur = 0.38
    s = [0.0] * int(SR * dur)
    for idx, (st, freq) in enumerate([(0.0, 523.25), (0.06, 659.25), (0.12, 783.99), (0.19, 1046.5)]):
        for i in range(int(SR * dur)):
            t = i / SR - st
            if t >= 0.0:
                s[i] += 0.20 * math.exp(-7.5 * t) * math.sin(2 * math.pi * freq * (1.0 + 0.06 * math.exp(-30 * t)) * t)
    _write_wav("sfx_heal", s)

    # 9. sfx_debuff_glitch
    dur = 0.26
    ns = _bp_noise(int(SR * dur), 1900, 1.5, 50)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        fm = math.sin(2 * math.pi * 38 * t) * 90.0
        carr = math.sin(2 * math.pi * ((320 - 160 * (t / dur)) + fm) * t)
        s.append(_env(t, 0.004, 0.12, dur) * (0.30 * carr + 0.26 * ns[i]))
    _write_wav("sfx_debuff_glitch", s)

    # 10. sfx_counter_reflect
    dur = 0.24
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        bell = math.sin(2 * math.pi * 1046.5 * t) + 0.65 * math.sin(2 * math.pi * 1567.98 * t)
        s.append(0.28 * math.exp(-12.0 * t) * bell)
    _write_wav("sfx_counter_reflect", s)

    # 11. sfx_hit_normal
    dur = 0.18
    ns = _bp_noise(int(SR * dur), 1400, 0.9, 60)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        f = 210 * math.exp(-14.0 * t) + 55
        s.append((0.46 * math.exp(-18.0 * t) * math.sin(2 * math.pi * f * t)) + (0.28 * _env(t, 0.001, 0.07, 0.09) * ns[i]))
    _write_wav("sfx_hit_normal", s)

    # 12. sfx_hit_overclock
    dur = 0.30
    ns = _bp_noise(int(SR * dur), 2200, 0.8, 70)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        f = 165 * math.exp(-11.0 * t) + 42
        punch = math.tanh(1.8 * math.sin(2 * math.pi * f * t)) * math.exp(-11.0 * t)
        spark = 0.30 * math.exp(-15.0 * t) * ns[i] + 0.16 * math.exp(-9.0 * t) * math.sin(2 * math.pi * 740 * t)
        s.append(0.50 * punch + spark)
    _write_wav("sfx_hit_overclock", s)

    # 13. sfx_cutin_slash
    dur = 0.34
    ns = _bp_noise(int(SR * dur), 3100, 1.3, 80)
    s = []
    for i in range(int(SR * dur)):
        t = i / SR
        whoosh = 0.34 * math.sin(math.pi * min(1.0, t / 0.18)) * ns[i]
        sting = 0.25 * math.exp(-7.0 * max(0.0, t - 0.05)) * (
            math.sin(2 * math.pi * 440 * t) + 0.7 * math.sin(2 * math.pi * 659.25 * t) + 0.5 * math.sin(2 * math.pi * 880 * t)
        ) if t >= 0.05 else 0.0
        s.append(whoosh + sting)
    _write_wav("sfx_cutin_slash", s)

    # 14. sfx_pack_tear
    dur = 0.44
    ns = _bp_noise(int(SR * dur), 3400, 1.0, 90)
    s = [0.0] * int(SR * dur)
    for i in range(int(SR * 0.15)):
        t = i / SR
        s[i] += 0.35 * math.sin(math.pi * t / 0.15) * ns[i]
    for st, freq in [(0.11, 783.99), (0.16, 987.77), (0.21, 1174.66), (0.26, 1567.98)]:
        for i in range(int(SR * dur)):
            t = i / SR - st
            if t >= 0.0:
                s[i] += 0.18 * math.exp(-9.5 * t) * math.sin(2 * math.pi * freq * t)
    _write_wav("sfx_pack_tear", s)

    # 15. sfx_zodiac_resonate
    dur = 0.72
    chord = [261.63, 392.00, 587.33, 659.25]
    s = [0.0] * int(SR * dur)
    for i in range(int(SR * dur)):
        t = i / SR
        env = min(1.0, t / 0.06) * math.exp(-3.4 * t)
        val = sum(math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * (f * 1.003) * t) for f in chord) / len(chord)
        s[i] = 0.38 * env * val
    _write_wav("sfx_zodiac_resonate", s)

    # 16. sfx_victory
    dur = 0.58
    arp = [(0.0, 523.25), (0.09, 659.25), (0.18, 783.99), (0.27, 1046.50)]
    s = [0.0] * int(SR * dur)
    for st, freq in arp:
        for i in range(int(SR * dur)):
            t = i / SR - st
            if t >= 0.0:
                s[i] += 0.22 * math.exp(-5.0 * t) * (math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(4 * math.pi * freq * t))
    _write_wav("sfx_victory", s)
    return 16


if __name__ == "__main__":
    count = gen_all()
    print(f"Synthesized {count} procedural WAV SFX files into {OUT_DIR}")
