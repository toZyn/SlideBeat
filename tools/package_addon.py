from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json
root = Path(__file__).resolve().parents[1]
source = root / 'slidebeat'
assert isinstance(json.loads((source / 'meta.json').read_text()), dict)
assert (source / 'global.lua').is_file()
output = root / 'dist' / 'SlideBeat-addon.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=9) as archive:
    for file in sorted(source.rglob('*')):
        if file.is_file():
            archive.write(file, file.relative_to(root))
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'slidebeat/meta.json' in archive.namelist()
    assert all(name.startswith('slidebeat/') for name in archive.namelist())
print(output.name, output.stat().st_size, 'bytes')
