import argparse
from pathlib import Path, PurePosixPath
import shutil
import stat
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ABIS = {'armeabi-v7a', 'arm64-v8a'}


def prepare(runtime, version, code):
    if not version or not version.replace('.', '').isdigit() or not 1 <= code <= 2100000000:
        raise ValueError('Invalid Android version')
    archive = ROOT / 'dist/SlideBeat.love'
    with zipfile.ZipFile(archive) as game:
        entries = game.infolist()
        names = set()
        for entry in entries:
            path = PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or '\\' in entry.filename or path.as_posix() != entry.filename or stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError('Unsafe asset path: ' + entry.filename)
            if entry.filename in names:
                raise ValueError('Duplicate asset: ' + entry.filename)
            names.add(entry.filename)
        if not {'main.lua', 'conf.lua', 'core/app.lua', 'screens/play.lua'}.issubset(names):
            raise ValueError('Game archive is incomplete')
        target = runtime / 'app/src/embed/assets'
        if target.exists():
            shutil.rmtree(target)
        target.mkdir(parents=True)
        game.extractall(target)
    properties = (ROOT / 'android/gradle.properties').read_text()
    properties = properties.replace('app.version_code=2000001', f'app.version_code={code}')
    properties = properties.replace('app.version_name=2.0.1', f'app.version_name={version}')
    (runtime / 'gradle.properties').write_text(properties)
    shutil.copyfile(ROOT / 'android/AndroidManifest.xml', runtime / 'app/src/main/AndroidManifest.xml')
    gradle = runtime / 'app/build.gradle'
    gradle.write_text(gradle.read_text() + '\n' + (ROOT / 'android/app.gradle').read_text())
    print(f'Prepared {len(names)} direct APK assets for SlideBeat {version}')


def validate(directory):
    produced = set()
    for apk in sorted(directory.glob('*.apk')):
        with zipfile.ZipFile(apk) as package:
            names = set(package.namelist())
            abis = {name.split('/')[1] for name in names if name.startswith('lib/') and name.count('/') > 1}
            if not abis or not abis.issubset(ABIS):
                raise ValueError(f'Unexpected native architectures: {apk}: {abis}')
            for abi in abis:
                if f'lib/{abi}/liblove.so' not in names:
                    raise ValueError('Missing native LOVE runtime: ' + abi)
            required = {'assets/main.lua', 'assets/conf.lua', 'assets/core/app.lua', 'assets/screens/play.lua', 'assets/assets/light/images/notes.png'}
            if not required.issubset(names) or 'assets/game.love' in names:
                raise ValueError('Incorrect direct asset layout: ' + str(apk))
            if not any(name.startswith('assets/songs/') and name.endswith('/music.ogg') for name in names):
                raise ValueError('Song audio is missing')
            with zipfile.ZipFile(ROOT / 'dist/SlideBeat.love') as game:
                for entry in game.infolist():
                    if not entry.is_dir() and package.read('assets/' + entry.filename) != game.read(entry):
                        raise ValueError('APK asset differs from the packaged game: ' + entry.filename)
        suffix = '' if abis == ABIS else '-' + next(iter(abis))
        output = directory / ('SlideBeat-android' + suffix + '.apk')
        apk.rename(output)
        produced.add(frozenset(abis))
        print(output.name, ', '.join(sorted(abis)))
    expected = {frozenset(ABIS), frozenset({'arm64-v8a'}), frozenset({'armeabi-v7a'})}
    if produced != expected:
        raise ValueError('Universal, ARM64 and ARMv7 APKs must all be present')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    config = sub.add_parser('prepare')
    config.add_argument('runtime', type=Path)
    config.add_argument('--version', required=True)
    config.add_argument('--code', required=True, type=int)
    verify = sub.add_parser('validate')
    verify.add_argument('directory', type=Path)
    args = parser.parse_args()
    if args.command == 'prepare':
        prepare(args.runtime, args.version, args.code)
    else:
        validate(args.directory)
