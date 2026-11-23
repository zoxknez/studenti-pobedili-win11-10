"""Obnovi Porcelan ICO i web navigaciju iz kodom crtanih malih ikonica.

    python -I Install/Alati/Napravi-porcelan.py

16-48 px: posebno nacrtane siluete; 64-256 px: originalni PNG masteri.
ICO kodiranje deli sa Napravi-ikonice.py (DIB za 16-64, PNG za 96-256).
"""
import importlib.util
from pathlib import Path
import sys

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import porcelan_male  # noqa: E402

spec = importlib.util.spec_from_file_location('napravi_ikonice', HERE / 'Napravi-ikonice.py')
NI = importlib.util.module_from_spec(spec)
spec.loader.exec_module(NI)

NAV_NAMES = ('Home', 'Gallery', 'Desktop', 'Folder-Documents', 'Folder-Downloads',
             'Folder-Pictures', 'Folder-Music', 'Folder-Video', 'Folder-3', 'ThisPC', 'Drive')


def main():
    png_dir = ROOT / 'Icons' / 'Porcelan' / 'PNG'
    ico_dir = png_dir.parent / 'ICO'
    nav_dir = ROOT / 'web' / 'assets' / 'nav-porcelan'
    ico_dir.mkdir(parents=True, exist_ok=True)
    nav_dir.mkdir(parents=True, exist_ok=True)
    for path in sorted(png_dir.glob('*.png')):
        with Image.open(path) as source:
            master = source.convert('RGBA')
        images = [porcelan_male.render(path.stem, s) if s <= 48
                  else master.resize((s, s), Image.Resampling.LANCZOS)
                  for s in NI.BMP_SIZES + NI.PNG_SIZES]
        NI.write_ico(ico_dir / (path.stem + '.ico'), images)
        if path.stem in NAV_NAMES:
            for size in (16, 20, 24, 32, 40, 48):
                filename = f'{path.stem}.png' if size == 20 else f'{path.stem}-{size}.png'
                porcelan_male.render(path.stem, size).save(nav_dir / filename, optimize=True)
        print('Porcelan:', path.stem)


if __name__ == '__main__':
    main()
