import argparse
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import subprocess
import json
import math
import struct
import wave

parser = argparse.ArgumentParser()
parser.add_argument('--engine', type=Path, required=True)
parser.add_argument('--love', default='love')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
engine = args.engine.resolve()
with TemporaryDirectory(prefix='slidebeat-native-') as directory:
    host = Path(directory)
    for folder in ['loxel', 'lib', 'funkin']:
        shutil.copytree(engine / folder, host / folder)
    shutil.copyfile(engine / 'project.lua', host / 'project.lua')
    folders = ['assets/images/fonts', 'assets/images/menus/mainmenu', 'assets/data']
    for folder in folders:
        shutil.copytree(engine / folder, host / folder)
    files = ['assets/fonts/vcr.ttf', 'assets/fonts/phantommuff.ttf', 'assets/music/freakyMenu.ogg']
    files += [f'assets/images/menus/{name}.png' for name in ['menuBG', 'menuDesat', 'menuBGMagenta']]
    files += [f'assets/images/skins/default/{name}.png' for name in ['NOTE_assets', 'sick', 'good', 'bad', 'shit', 'ready', 'set', 'go']]
    files += ['assets/images/skins/default/NOTE_assets.xml', 'assets/images/icons/bf.png']
    files += [f'assets/sounds/{name}.ogg' for name in ['scrollMenu', 'confirmMenu', 'cancelMenu', 'hitsound']]
    for name in files:
        destination = host / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(engine / name, destination)
    shutil.copytree(root / 'slidebeat', host / 'addons/slidebeat')
    shutil.copyfile(root / 'tests/native.lua', host / 'main.lua')
    (host / 'conf.lua').write_text("function love.conf(t) t.identity='slidebeat-addon-tests';t.window.width=1000;t.window.height=760 end\n")
    song = host / 'assets/songs/sb-fixture'
    (song / 'charts').mkdir(parents=True)
    chart = {'song': {'song': 'sb-fixture', 'bpm': 120, 'speed': 1, 'player1': 'bf', 'player2': 'dad', 'notes': [{'mustHitSection': True, 'lengthInSteps': 16, 'sectionNotes': [[1000, 0, 500], [2000, 1, 0], [2500, 2, 0], [3000, 3, 0]]}]}}
    (song / 'charts/normal.json').write_text(json.dumps(chart))
    (song / 'meta.json').write_text(json.dumps({'song': 'sb-fixture', 'displayName': 'SlideBeat Fixture', 'icon': 'bf', 'difficulties': ['Normal'], 'bpm': 120, 'color': [0.3, 0.7, 1]}))
    (host / 'assets/data/freeplayList.txt').write_text('sb-fixture\n')
    with wave.open(str(song / 'Inst.wav'), 'wb') as audio:
        audio.setparams((1, 2, 22050, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(struct.pack('<h', int(math.sin(i / 22050 * math.pi * 2 * 440) * 1000)) for i in range(22050 * 5)))
    subprocess.run([args.love, str(host)], check=True, timeout=80)
