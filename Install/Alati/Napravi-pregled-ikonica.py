"""Web navigacija i pregled stvarnih ICO okvira u obe teme.

    python -I Install/Alati/Napravi-pregled-ikonica.py

PNG navigacija koristi tacne okvire 16/20/24 px i njihove 2x verzije.
Pregled prikazuje stvarnu velicinu u svetlom i tamnom rezimu, bez uvecavanja.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
NAV_NAMES = ('Home', 'Gallery', 'Desktop', 'Folder-Downloads', 'Folder-Documents',
             'Folder-Pictures', 'Folder-Music', 'Folder-Video', 'Folder-3', 'ThisPC', 'Drive')
LABELS = ('Home', 'Gallery', 'Desktop', 'Downloads', 'Documents', 'Pictures', 'Music',
          'Videos', 'Projekti', 'This PC', 'System (C:)')


def frame(path, size):
    with Image.open(path) as ico:
        return ico.ico.getimage((size, size)).convert('RGBA')


def font(size):
    try:
        return ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', size)
    except OSError:
        return ImageFont.load_default(size=size)


def main():
    for style, folder, assets in [('Bordo', ROOT/'Icons'/'ICO', 'nav'),
                                   ('Porcelan', ROOT/'Icons'/'Porcelan'/'ICO', 'nav-porcelan')]:
        out = ROOT/'web'/'assets'/assets
        out.mkdir(parents=True, exist_ok=True)
        for name in NAV_NAMES:
            for size in (16, 20, 24, 32, 40, 48):
                filename = f'{name}.png' if size == 20 else f'{name}-{size}.png'
                image = frame(folder/(name+'.ico'), size)
                image.save(out/filename, optimize=True)
                if size == 20:
                    image.save(out/f'{name}-20.png', optimize=True)
        sheet = Image.new('RGB', (1100, 760), '#211b20')
        d = ImageDraw.Draw(sheet)
        d.text((30, 20), f'{style} · jasne ikonice od 16 piksela', font=font(28), fill='white')
        d.text((30, 62), 'Stvarni ICO okviri. 100%, 125% i 150% · svetla i tamna podloga.',
               font=font(16), fill='#d2c5cb')
        for row, dark in enumerate((True, False)):
            for col, size in enumerate((16, 20, 24)):
                x, y = 30+col*356, 106+row*316
                bg, fg = ('#191919', '#f8f4f6') if dark else ('#f6f3f0', '#292229')
                d.rounded_rectangle((x, y, x+328, y+300), radius=12, fill=bg)
                d.text((x+16, y+10), f'{round(size/16*100)}% · {size} px', font=font(14), fill=fg)
                for i, name in enumerate(NAV_NAMES):
                    yy = y+40+i*23
                    icon = frame(folder/(name+'.ico'), size)
                    sheet.paste(icon, (x+18, yy+(24-size)//2), icon)
                    d.text((x+56, yy+2), LABELS[i], font=font(13), fill=fg)
        sheet.save(ROOT/'Preview'/f'Navigacija-{style}.png', optimize=True)
        print(style, ': web navigacija i pregled osvezeni')


if __name__ == '__main__':
    main()
