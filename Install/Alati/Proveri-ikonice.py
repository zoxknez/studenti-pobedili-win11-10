"""Provera ICO formata, citljivosti, web okvira i lokalnih resursa.

    python -I Install/Alati/Proveri-ikonice.py
    python -I Install/Alati/Proveri-ikonice.py --porcelan-dir PUTANJA --skip-web
"""
import argparse
from html.parser import HTMLParser
from pathlib import Path
import struct

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SIZES = {16, 20, 24, 32, 40, 48, 64, 96, 128, 256}
NAV = ('Home', 'Gallery', 'Desktop', 'Folder-Downloads', 'Folder-Documents',
       'Folder-Pictures', 'Folder-Music', 'Folder-Video', 'Folder-3', 'ThisPC', 'Drive')


def validate_ico(path):
    data = path.read_bytes()
    assert struct.unpack_from('<HHH', data) == (0, 1, len(SIZES)), f'{path}: ICO header'
    previous_end = 6+16*len(SIZES)
    for i in range(len(SIZES)):
        w, h, _, _, planes, bits, length, offset = struct.unpack_from('<BBBBHHII', data, 6+16*i)
        size = w or 256
        assert (h or 256) == size and planes == 1 and bits == 32, f'{path}: entry {i}'
        assert offset == previous_end and offset+length <= len(data), f'{path}: payload bounds'
        blob = data[offset:offset+length]
        if size <= 64:
            assert struct.unpack_from('<IiiHH', blob) == (40, size, size*2, 1, 32), f'{path}: DIB'
            assert length == 40+size*size*4+((size+31)//32)*4*size, f'{path}: DIB length'
        else:
            assert blob.startswith(b'\x89PNG\r\n\x1a\n'), f'{path}: PNG'
        previous_end = offset+length
    assert previous_end == len(data), f'{path}: trailing data'
    with Image.open(path) as ico:
        assert ico.ico.sizes() == {(s, s) for s in SIZES}, f'{path}: sizes'
        for size in SIZES:
            image = ico.ico.getimage((size, size)).convert('RGBA')
            lo, hi = image.getchannel('A').getextrema()
            assert lo < 255 and hi == 255, f'{path}: alpha {size}'


class Resources(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            assert attrs['id'] not in self.ids, f'Duplicate id: {attrs["id"]}'
            self.ids.add(attrs['id'])
        for key in ('src', 'href', 'poster'):
            if key in attrs:
                self.urls.append(attrs[key])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--porcelan-dir', type=Path, default=ROOT/'Icons'/'Porcelan'/'ICO')
    parser.add_argument('--skip-web', action='store_true')
    args = parser.parse_args()
    expected = {p.stem for p in (ROOT/'Icons'/'PNG').glob('*.png')}
    assert len(expected) == 31, f'Expected 31 master images, got {len(expected)}'
    for directory in (ROOT/'Icons'/'ICO', args.porcelan_dir):
        assert {p.stem for p in directory.glob('*.ico')} == expected, f'{directory}: icon names'
        for path in directory.glob('*.ico'):
            validate_ico(path)
    for name in expected:
        with Image.open(args.porcelan_dir/(name+'.ico')) as ico:
            image = ico.ico.getimage((16, 16)).convert('RGBA')
            box = image.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox()
            w, h = box[2]-box[0], box[3]-box[1]
            assert max(w, h) >= 15, f'{name}: drawing too small at 16px: {w}x{h}'
            if name == 'Folder-Documents':
                assert w >= 11 and h >= 15, f'Documents: drawing too small: {w}x{h}'
    if not args.skip_web:
        for directory, assets in [(ROOT/'Icons'/'ICO', 'nav'), (args.porcelan_dir, 'nav-porcelan')]:
            for name in NAV:
                with Image.open(directory/(name+'.ico')) as ico:
                    for size in (16, 20, 24, 32, 40, 48):
                        web = ROOT/'web'/'assets'/assets/f'{name}-{size}.png'
                        with Image.open(web) as image:
                            assert image.convert('RGBA').tobytes() == ico.ico.getimage((size, size)).convert('RGBA').tobytes(), f'{web}: differs from ICO'
        resources = Resources()
        resources.feed((ROOT/'web'/'index.html').read_text(encoding='utf-8-sig'))
        for url in resources.urls:
            if url.startswith('#'):
                assert url[1:] in resources.ids or url == '#', f'Broken anchor: {url}'
            elif not url.startswith(('https:', 'http:', 'data:')):
                assert (ROOT/'web'/url.split('?')[0].split('#')[0]).is_file(), f'Missing resource: {url}'
    print('OK: 62 ICO fajla, 620 okvira, citljivost Porcelan ikonica' +
          (', 132 web okvira i lokalni resursi.' if not args.skip_web else '.'))


if __name__ == '__main__':
    main()
