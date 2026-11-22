"""Nova serija (10 ilustracija) iz uvecanih izvora.

Izvori su u Install/Alati/izvor/nova-serija; uvecajte ih 4x programom
Uvecaj-pozadine.py, pa:

    python Install/Alati/Napravi-nova-serija.py <fascikla-sa-uvecanim-png>

Pravi Nova-serija/*.jpg, web/assets/nova/*.webp i dist/StudentiPobedili-Nova-serija.zip.
"""
import os
import sys
import zipfile

from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
UP = sys.argv[1]
OUT = os.path.join(ROOT, 'Nova-serija')
WEB = os.path.join(ROOT, 'web', 'assets', 'nova')
ZIP = os.path.join(ROOT, 'dist', 'StudentiPobedili-Nova-serija.zip')

# izvor -> (ime, sirina, visina)
SERIJA = [
    ('01_Podignuta_grancica_mir_i_nada_portrait.png', '01-Grancica-mir-i-nada', 2160, 2880),
    ('02_Veliki_transparent_studenti_pobedili.png', '02-Veliki-transparent', 3840, 2160),
    ('03_Strip_ilustracija_studenti_pobedili.png', '03-Strip-ilustracija', 3840, 2160),
    ('04_Studentska_solidarnost_grad.png', '04-Studentska-solidarnost', 3840, 2160),
    ('05_Retro_risograf_studentski_trijumf.png', '05-Retro-risograf', 3840, 2160),
    ('06_Kolaz_knjige_studenti_buducnost.png', '06-Kolaz-knjige-buducnost', 3840, 2160),
    ('07_Baner_studenti_su_pobedili.png', '07-Baner-studenti-su-pobedili', 3840, 2160),
    ('08_Studentska_lista_amfiteatar_wide.png', '08-Amfiteatar-wide', 4532, 2160),
    ('09_Pobeda_studenata_dokumentarno.png', '09-Pobeda-studenata', 2880, 2160),
    ('10_Slagalica_studenti_telefon.png', '10-Slagalica-telefon', 2160, 3840),
]


def cover(im, w, h):
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def main():
    for d in (OUT, WEB):
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(d):
            os.remove(os.path.join(d, f))
    names = []
    for src, name, w, h in SERIJA:
        im = cover(Image.open(os.path.join(UP, src)).convert('RGB'), w, h)
        im = im.filter(ImageFilter.UnsharpMask(radius=1.2, percent=35, threshold=2))
        path = os.path.join(OUT, f'{name}-{w}x{h}.jpg')
        im.save(path, quality=92, optimize=True, progressive=True, subsampling=0)
        names.append(path)
        long = 1280
        s = long / max(w, h)
        im.resize((round(w * s), round(h * s)), Image.LANCZOS).save(os.path.join(WEB, name[:2] + '.webp'), quality=84, method=6)
        print(os.path.basename(path), os.path.getsize(path) // 1024, 'KB')
    os.makedirs(os.path.dirname(ZIP), exist_ok=True)
    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_STORED) as z:
        for p in names:
            z.write(p, 'StudentiPobedili-Nova-serija/' + os.path.basename(p))
    print('paket:', ZIP, round(os.path.getsize(ZIP) / 1048576, 1), 'MB')


if __name__ == '__main__':
    main()
