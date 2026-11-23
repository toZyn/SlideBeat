from pathlib import Path
import math
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
TRACKS = [
    ('01-first-steps', 'First Steps', 80, 64, [130.81, 110, 87.31, 98], 'bf', '107 204 255', 'Wide, steady beats. Learn the return to center.'),
    ('02-neon-circuit', 'Neon Circuit', 120, 160, [146.83, 116.54, 130.81, 98], 'pico', '185 132 255', 'Bright synths, alternating strokes and syncopation.'),
    ('03-moonlit', 'Moonlit', 98, 144, [110, 87.31, 130.81, 98], 'bf', '104 232 191', 'A slower groove with rests and flowing phrases.'),
    ('04-redline', 'Redline', 160, 192, [164.81, 130.81, 146.83, 123.47], 'dad', '255 127 118', 'Fast runs, short bursts and sudden direction changes.'),
]
PATTERNS = [[1, 4, 2, 3, 1, 3, 2, 4], [3, 1, 4, 2, 4, 1, 3, 2], [1, 3, 2, 4, 2, 3, 1, 4], [3, 4, 1, 2, 4, 3, 2, 1]]

def add_tone(audio, start, duration, frequency, gain, kind=0):
    offset = int(start * RATE)
    length = min(int(duration * RATE), len(audio) - offset)
    if length <= 0:
        return
    t = np.arange(length) / RATE
    envelope = (1 - np.exp(-t * 180)) * np.exp(-t * 6 / duration)
    wave_data = np.sin(2 * np.pi * frequency * t)
    if kind:
        wave_data += 0.25 * np.sin(4 * np.pi * frequency * t) + 0.12 * np.sin(6 * np.pi * frequency * t)
    audio[offset:offset + length] += wave_data * envelope * gain

for track_index, (song_id, title, bpm, beats, chords, icon, color, description) in enumerate(TRACKS):
    beat_length = 60 / bpm
    duration = beats * beat_length
    folder = ROOT / 'songs' / song_id
    folder.mkdir(parents=True, exist_ok=True)
    audio = np.zeros(int((duration + 0.02) * RATE), dtype=np.float64)
    rng = np.random.default_rng(2013 + track_index)
    for beat in range(beats):
        start = beat * beat_length
        root = chords[(beat // 16) % 4]
        phase = np.arange(int(beat_length * RATE)) / RATE
        offset = int(start * RATE)
        count = min(len(phase), len(audio) - offset)
        if beat % 2 == 0:
            kick = np.sin(2 * np.pi * (45 * phase + 3 * (1 - np.exp(-phase * 35)))) * np.exp(-phase * 25)
            audio[offset:offset + count] += kick[:count] * 0.38
        else:
            noise = rng.uniform(-1, 1, count) * np.exp(-phase[:count] * 32)
            audio[offset:offset + count] += noise * 0.13
        add_tone(audio, start, beat_length * 0.9, root / 2, 0.20, 1)
        for sub in [0, 0.5]:
            pos = int((start + sub * beat_length) * RATE)
            n = min(int(0.045 * RATE), len(audio) - pos)
            audio[pos:pos + n] += rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / RATE * 130) * 0.07
        if beat % 4 == 0:
            for multiplier in [1, 1.189207, 1.498307]:
                add_tone(audio, start, beat_length * 3.8, root * multiplier, 0.045)
        if 4 <= beat < beats - 8 and beat % 16 < 14:
            scale = [1, 1.189207, 1.33484, 1.498307, 1.781797, 2, 1.498307, 1.189207]
            frequency = root * 2 * scale[(beat + track_index * 2) % len(scale)]
            add_tone(audio, start, beat_length * 0.85, frequency, 0.10, 1)
            if track_index in [1, 3] and beat % 8 in [3, 7]:
                add_tone(audio, start + beat_length * 0.5, beat_length * 0.4, frequency * 1.189207, 0.07)
    envelope = np.minimum(1, np.arange(len(audio)) / RATE / 0.05) * np.minimum(1, (len(audio) - np.arange(len(audio))) / RATE / 1.7)
    audio *= envelope * 0.88 / max(0.88, float(np.max(np.abs(audio))))
    temp = folder / 'music.wav'
    with wave.open(str(temp), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes((audio * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-i', str(temp), '-c:a', 'libvorbis', '-q:a', '1', str(folder / 'music.ogg')], check=True)
    temp.unlink()
    metadata = {'title': title, 'artist': 'SlideBeat Originals', 'bpm': bpm, 'duration': f'{duration:.4f}', 'icon': icon, 'color': color, 'description': description, 'order': track_index + 1, 'preview': beat_length * 16}
    (folder / 'meta.txt').write_text(''.join(f'{key}={value}\n' for key, value in metadata.items()))
    for difficulty_index, difficulty in enumerate(['easy', 'normal', 'hard']):
        rows = []
        tick = 16
        count = 0
        while tick < (beats - 8) * 4:
            beat = tick / 4
            phrase = int(beat // 16)
            pattern = PATTERNS[(track_index + phrase) % 4]
            rest = int(beat) % 16 in [14, 15]
            if not rest:
                direction = pattern[(count + phrase * 3) % len(pattern)]
                rows.append(f'{beat * beat_length:.6f} {direction}\n')
                count += 1
            step = 4 if difficulty_index == 0 else 2
            if track_index == 0 and difficulty_index == 1 and beat < 32:
                step = 4
            if difficulty_index == 2 and track_index > 0 and int(beat) % 16 in [8, 9, 10, 11]:
                step = 1
            tick += step
        (folder / (difficulty + '.txt')).write_text(''.join(rows))
    print(title, f'{duration:.1f}s', (folder / 'music.ogg').stat().st_size)
