"""Uporedi objavljive Windows i Linux pakete sa trenutnim izvorima."""
import importlib.util
from pathlib import Path
import sys
import tarfile
import zipfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))


def main():
    spec = importlib.util.spec_from_file_location('linux_builder', HERE/'Napravi-linux.py')
    linux = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(linux)
    with zipfile.ZipFile(ROOT/'dist'/'StudentiPobedili-Windows-v2.zip') as archive:
        assert archive.testzip() is None, 'Windows ZIP CRC'
        for folder in ('Icons/ICO', 'Icons/Porcelan/ICO'):
            for path in (ROOT/folder).glob('*.ico'):
                rel = path.relative_to(ROOT).as_posix()
                assert archive.read('StudentiPobedili-Windows/'+rel) == path.read_bytes(), f'Stale ZIP icon: {rel}'
        for path in (ROOT/'Install').glob('*.ps1'):
            data = path.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
            assert archive.read('StudentiPobedili-Windows/Install/'+path.name) == data, f'Stale script: {path.name}'
        for name in ('Navigacija-Bordo.png', 'Navigacija-Porcelan.png'):
            assert archive.read('StudentiPobedili-Windows/Preview/'+name) == (ROOT/'Preview'/name).read_bytes()
        for name in archive.namelist():
            assert not name.startswith('/') and '..' not in Path(name).parts, f'Unsafe ZIP path: {name}'
    count = 0
    with tarfile.open(ROOT/'dist'/'StudentiPobedili-Linux.tar.gz') as archive:
        for name, (context, master) in linux.ICONS.items():
            for size in linux.SIZES:
                rel = f'icons/StudentiPobedili-Porcelan/{size}x{size}/{context}/{name}.png'
                data = archive.extractfile('StudentiPobedili-Linux/'+rel).read()
                assert data == (ROOT/'Linux'/rel).read_bytes(), f'Stale Linux icon: {rel}'
                with Image.open(ROOT/'Linux'/rel) as image:
                    assert image.convert('RGBA').tobytes() == linux.porcelan_frame(master, size).tobytes(), f'Linux/ICO mismatch: {rel}'
                count += 1
    print(f'OK: Windows ZIP CRC, 62 ikonice, instalacione skripte, pregledi; {count} Linux Porcelan PNG fajlova.')


if __name__ == '__main__':
    main()
