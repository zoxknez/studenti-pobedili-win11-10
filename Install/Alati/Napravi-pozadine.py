"""Pravi sve pozadine iz redizajniranih izvora (10 slika, srpske zastave).

Izvori (1672x941 i sl.) su u Install/Alati/izvor/pozadine. Prvo ih uvecajte
4x programom Uvecaj-pozadine.py (Real-ESRGAN), pa ovom skriptom napravite:

  Wallpapers/       7 pozadina: 4 x 3840x2160, ultrawide 5120x2160, 2 tablet 2880x2160
  LockScreen/       zakljucani ekran za PC (3840x2160) i 2 za telefon (2160x3840)
  Mobilni/Pozadine/ 4 pozadine za telefon (2160x3840)
  web/assets/       pregledi za sajt (wall/, mob/, hero.webp)

Pokretanje:  python Install/Alati/Napravi-pozadine.py <fascikla-sa-uvecanim-png>
"""
import os
import shutil
import sys

from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
UP = sys.argv[1]
WALL = os.path.join(ROOT, 'Wallpapers')
LOCK = os.path.join(ROOT, 'LockScreen')
MOB = os.path.join(ROOT, 'Mobilni', 'Pozadine')
WEB = os.path.join(ROOT, 'web', 'assets')


def src(n):
    return Image.open(os.path.join(UP, n)).convert('RGB')


def cover(im, w, h, ax=0.5, ay=0.5):
    """Uvecaj/umanji da pokrije w x h, pa iseci (ax/ay = gde se sece, 0 levo/gore)."""
    s = max(w / im.width, h / im.height)
    nw, nh = round(im.width * s), round(im.height * s)
    im = im.resize((nw, nh), Image.LANCZOS)
    x, y = round((nw - w) * ax), round((nh - h) * ay)
    return im.crop((x, y, x + w, y + h))


def finish(im):
    # blago izostravanje posle umanjenja (Real-ESRGAN ume da omeksa detalje)
    return im.filter(ImageFilter.UnsharpMask(radius=1.2, percent=35, threshold=2))


def save(im, path, q=92):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if path.endswith('.webp'):
        im.save(path, quality=84, method=6)
    else:
        im.save(path, quality=q, optimize=True, progressive=True, subsampling=0)
    print(os.path.relpath(path, ROOT), im.size, os.path.getsize(path) // 1024, 'KB')


def main():
    for d in (WALL, MOB):
        for f in os.listdir(d):
            if f.lower().endswith('.jpg'):
                os.remove(os.path.join(d, f))

    beograd = src('04_Ultrawide_21x9_Belgrade.png')
    desk = {
        '01-Pobeda-Cinematic-4K.jpg': cover(src('01_Desktop_16x9_Cinematic.png'), 3840, 2160),
        '02-Pobeda-Minimal-Light-4K.jpg': cover(src('02_Desktop_16x9_Minimal_Light.png'), 3840, 2160),
        '03-Pobeda-Bordo-Talasi-4K.jpg': cover(src('03_Desktop_16x9_Bordo_Waves.png'), 3840, 2160),
        # 16:9 isecak ultrawide slike: levo ostaju naslov i Skupstina
        '04-Beograd-4K.jpg': cover(beograd, 3840, 2160, ax=0.0),
        '05-Beograd-Ultrawide-5120x2160.jpg': cover(beograd, 5120, 2160),
        '06-Univerzitet-Tablet-2880x2160.jpg': cover(src('05_Tablet_4x3_Cinematic.png'), 2880, 2160),
        '07-Minimal-Light-Tablet-2880x2160.jpg': cover(src('06_Tablet_4x3_Minimal_Light.png'), 2880, 2160),
    }
    for name, im in desk.items():
        desk[name] = finish(im)
        save(desk[name], os.path.join(WALL, name))

    mob = {
        '1-Bordo-Skupstina.jpg': '07_Mobile_9x16_Cinematic.png',
        '2-Bordo-Talasi.jpg': '08_Mobile_9x16_Bordo_Waves.png',
        '3-Svetla.jpg': '09_Mobile_9x16_Minimal_Light.png',
        '4-Nocna.jpg': '10_Mobile_9x16_Night.png',
    }
    mobim = {}
    for name, s in mob.items():
        mobim[name] = finish(cover(src(s), 2160, 3840))
        save(mobim[name], os.path.join(MOB, name))

    # zakljucani ekran
    save(desk['04-Beograd-4K.jpg'], os.path.join(LOCK, '03-Zakljucani-ekran-PC-3840x2160.jpg'))
    save(mobim['1-Bordo-Skupstina.jpg'], os.path.join(LOCK, '01-Zakljucani-ekran-2160x3840.jpg'))
    save(mobim['4-Nocna.jpg'], os.path.join(LOCK, '02-Zakljucani-ekran-alternativa-2160x3840.jpg'))

    # sajt
    wall = os.path.join(WEB, 'wall')
    for f in os.listdir(wall):
        os.remove(os.path.join(wall, f))
    for name, im in desk.items():
        n = name[:2]
        w = 1280
        save(im.resize((w, round(w * im.height / im.width)), Image.LANCZOS), os.path.join(wall, n + '.webp'))
    save(desk['01-Pobeda-Cinematic-4K.jpg'].resize((2048, 1152), Image.LANCZOS), os.path.join(WEB, 'hero.webp'))
    mweb = os.path.join(WEB, 'mob')
    for f in os.listdir(mweb):
        os.remove(os.path.join(mweb, f))
    for name, im in mobim.items():
        base = name[:-4]
        save(im.resize((600, 1067), Image.LANCZOS), os.path.join(mweb, base + '.webp'))
        save(im.resize((1440, 2560), Image.LANCZOS), os.path.join(mweb, base + '.jpg'), q=90)


if __name__ == '__main__':
    main()
