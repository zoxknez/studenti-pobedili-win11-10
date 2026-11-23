"""Pravi dist/StudentiPobedili-Windows-v2.zip (kompletan Windows paket).

Pre ovoga: Napravi-themepack.ps1 (Teme/*.deskthemepack).
.cmd, .ps1 i .txt idu sa CRLF krajevima redova (cmd.exe ne podnosi LF).

Pokretanje:  python Install/Alati/Napravi-windows-paket.py
"""
import os
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'dist', 'StudentiPobedili-Windows-v2.zip')
TOP = 'StudentiPobedili-Windows'
CRLF = ('.cmd', '.ps1', '.txt')


def files():
    yield 'INSTALIRAJ.cmd'
    yield 'PROCITAJ-ME.txt'
    for sub in ('Icons/ICO', 'Icons/PNG', 'Icons/Porcelan/ICO', 'Icons/Porcelan/PNG', 'LockScreen', 'Sounds', 'Teme', 'Wallpapers', 'Preview/X'):
        for f in sorted(os.listdir(os.path.join(ROOT, sub))):
            if os.path.isfile(os.path.join(ROOT, sub, f)):
                yield f'{sub}/{f}'
    for f in ('Brand.png', 'Linux-Dolphin.png', 'Pregled-Ikonica.png', 'Pregled-Porcelan.png', 'Pregled-Pozadina.png', 'Telefon.jpg'):
        yield f'Preview/{f}'
    for f in sorted(os.listdir(os.path.join(ROOT, 'Install'))):
        if f.endswith('.ps1'):
            yield f'Install/{f}'
    for f in sorted(os.listdir(os.path.join(ROOT, 'Install', 'Alati'))):
        if f.endswith(('.py', '.ps1')):
            yield f'Install/Alati/{f}'
    yield 'Install/Alati/izvor/Folder-bez-broja-512.png'


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    n = 0
    with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for rel in files():
            path = os.path.join(ROOT, *rel.split('/'))
            data = open(path, 'rb').read()
            if rel.endswith(CRLF):
                data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
            info = zipfile.ZipInfo(f'{TOP}/{rel}', date_time=(2026, 11, 22, 12, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, data)
            n += 1
    print('paket:', OUT, n, 'fajlova', round(os.path.getsize(OUT) / 1048576, 1), 'MB')


if __name__ == '__main__':
    main()
