"""Pravi dist/StudentiPobedili-macOS.zip (install.command sa dozvolom izvrsavanja, ikonice, pozadine).

Pokretanje:  py -I Install/Alati/Napravi-mac.py
ZIP cuva Unix dozvole (0755 za install.command), pa ih macOS Archive Utility zadrzava.
"""
import os
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
MAC = os.path.join(ROOT, 'macOS')
TOP = 'StudentiPobedili-macOS'
ICONS = ['Folder-3', 'Folder-Documents', 'Folder-Downloads', 'Folder-Pictures', 'Folder-Music', 'Folder-Video',
         'Folder-Projects', 'Folder-Education', 'Folder-Team', 'Folder-Favorites', 'Desktop']


def add(z, src, arc, mode):
    info = zipfile.ZipInfo.from_file(src, arc)
    info.external_attr = (0o100000 | mode) << 16   # regularan fajl + Unix dozvole
    info.create_system = 3                         # Unix
    info.compress_type = zipfile.ZIP_DEFLATED
    with open(src, 'rb') as f:
        z.writestr(info, f.read(), compresslevel=9)


def main():
    dist = os.path.join(ROOT, 'dist'); os.makedirs(dist, exist_ok=True)
    out = os.path.join(dist, 'StudentiPobedili-macOS.zip')
    with zipfile.ZipFile(out, 'w') as z:
        add(z, os.path.join(MAC, 'install.command'), f'{TOP}/install.command', 0o755)
        add(z, os.path.join(MAC, 'PROCITAJ-ME.txt'), f'{TOP}/PROCITAJ-ME.txt', 0o644)
        for n in ICONS:
            add(z, os.path.join(ROOT, 'Icons', 'PNG', n + '.png'), f'{TOP}/icons/{n}.png', 0o644)
            add(z, os.path.join(ROOT, 'Icons', 'Porcelan', 'PNG', n + '.png'), f'{TOP}/icons-porcelan/{n}.png', 0o644)
        walls = os.path.join(ROOT, 'Wallpapers')
        for f in sorted(os.listdir(walls)):
            add(z, os.path.join(walls, f), f'{TOP}/wallpapers/{f}', 0o644)
    print('paket:', out, round(os.path.getsize(out) / 1048576, 1), 'MB')


if __name__ == '__main__':
    main()
