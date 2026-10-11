"""Generate compact, original PCM effects and a quiet 8-second music loop."""

from math import pi, sin
from pathlib import Path
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parent


def write(name, duration, tones, noise=0.0, decay=3.0):
    frames = []
    count = int(RATE * duration)
    for i in range(count):
        t = i / RATE
        u = i / count
        envelope = min(1.0, u * 60.0) * (1.0 - u) ** decay
        value = sum(sin(2 * pi * frequency * t) * amplitude for frequency, amplitude in tones)
        # Deterministic high-frequency grit gives impacts a soft percussion edge.
        grit = sin(2 * pi * 1811 * t) * sin(2 * pi * 2333 * t) * noise
        frames.append(struct.pack("<h", int(max(-1.0, min(1.0, (value + grit) * envelope)) * 16000)))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(b"".join(frames))


write("discover", 0.12, [(740, 0.25), (1110, 0.12)], 0.06)
write("splash", 0.18, [(280, 0.12), (420, 0.1)], 0.26)
write("ship_found", 0.24, [(523, 0.22), (784, 0.14)], 0.03)
write("cannon", 0.3, [(83, 0.24), (126, 0.13)], 0.32, 5.0)
write("impact", 0.17, [(180, 0.16), (310, 0.09)], 0.30)
write("treasure", 0.28, [(659, 0.20), (988, 0.13)], 0.04)
write("coin", 0.11, [(988, 0.17), (1318, 0.10)], 0.02)
write("purchase", 0.23, [(440, 0.16), (660, 0.14), (880, 0.06)], 0.02)
write("sink", 0.55, [(92, 0.19), (138, 0.09)], 0.19, 2.0)
write("victory", 0.6, [(523, 0.18), (659, 0.17), (784, 0.16)], 0.02, 1.5)
write("defeat", 0.55, [(220, 0.16), (196, 0.13)], 0.08, 1.8)


def music():
    notes = [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]
    count = RATE * 8
    frames = []
    for i in range(count):
        t = i / RATE
        beat = int(t * 2) % len(notes)
        local = (t * 2) % 1.0
        fade = min(1.0, local * 8) * min(1.0, (1.0 - local) * 5)
        tone = sin(2 * pi * notes[beat] * t) * 0.085
        bass = sin(2 * pi * notes[beat] / 4 * t) * 0.04
        frames.append(struct.pack("<h", int((tone + bass) * fade * 16000)))
    with wave.open(str(OUT / "music.wav"), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(b"".join(frames))


music()
