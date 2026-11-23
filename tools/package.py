from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parents[1]
destination = root / 'dist' / 'SlideBeat.love'
destination.parent.mkdir(exist_ok=True)
files = [root / 'main.lua', root / 'conf.lua', root / 'README.md']
for folder in ['core', 'screens', 'assets', 'songs', 'tests', 'docs']:
    files.extend(sorted((root / folder).rglob('*')))
with ZipFile(destination, 'w', ZIP_DEFLATED) as package:
    for path in files:
        if path.is_file():
            package.write(path, path.relative_to(root))
print(destination.name, destination.stat().st_size, 'bytes')
