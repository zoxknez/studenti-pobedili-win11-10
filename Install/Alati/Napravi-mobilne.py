"""Pozadine za telefon (iPhone i Android), 1440x3120 (9:19.5).

Gornja trecina ostaje mirna zbog sata na zakljucanom ekranu, a naslov
i "3" su u sredini. Fotografije se ne uvecavaju: isecak 1440 px sirine
iz 4K pozadine ide u donji deo, a gornji deo je bordo prelaz.

Pokretanje:  python Install/Alati/Napravi-mobilne.py [izlazna-fascikla]
             python Install/Alati/Napravi-mobilne.py --paket   (pravi i dist/StudentiPobedili-Mobilni.zip)
"""
import math
import os
import sys
import zipfile

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
WALL = os.path.join(ROOT, 'Wallpapers')
ARGS = [a for a in sys.argv[1:] if not a.startswith('--')]
OUT = ARGS[0] if ARGS else os.path.join(ROOT, 'Mobilni', 'Pozadine')
W, H = 1440, 3120
FONT = 'C:/Windows/Fonts/NotoSans-VariableFont_wdth,wght.ttf'

TOP = (41, 5, 19)        # 04: vrh
BOTTOM = (86, 13, 43)    # 04: dno
PINK = (240, 188, 204)
CREAM = (246, 242, 233)
CREAM_LINE = (226, 216, 204)
BORDO = (153, 31, 52)
INK = (38, 14, 20)


def font(size, weight=800):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_axes([weight, 100])
    return f


def gradient(c1, c2, w=W, h=H):
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / (h - 1)
        g.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(c1, c2)))
    return g.resize((w, h))


def centered(d, y, text, f, fill, spacing=0):
    if spacing:
        widths = [d.textlength(ch, font=f) for ch in text]
        total = sum(widths) + spacing * (len(text) - 1)
        x = (W - total) / 2
        for ch, cw in zip(text, widths):
            d.text((x, y), ch, font=f, fill=fill)
            x += cw + spacing
        return
    d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)


def ring_with_three(img, cx, cy, r, ring, three, width=10, size=None):
    """Krug i "3" na posebnom sloju 3x vecem, pa umanjeno (glatke ivice)."""
    s = 3
    layer = Image.new('RGBA', (img.width * s, img.height * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s],
              outline=ring, width=width * s)
    f = font((size or int(r * 1.15)) * s, 850)
    bbox = d.textbbox((0, 0), '3', font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((cx * s - tw / 2 - bbox[0], cy * s - th / 2 - bbox[1]), '3', font=f, fill=three)
    layer = layer.resize(img.size, Image.LANCZOS)
    img.paste(layer, (0, 0), layer)


def waves(img, color, alpha, y0, y1, count=14):
    """Tanke talasaste linije kao na pozadini 04."""
    s = 2
    layer = Image.new('RGBA', (W * s, H * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(count):
        base = y0 + (y1 - y0) * i / (count - 1)
        pts = []
        for x in range(0, W + 1, 8):
            y = base + 38 * math.sin(x / 260 + i * 0.35) + 18 * math.sin(x / 97 + i)
            pts.append((x * s, y * s))
        a = int(alpha * (1 - abs(i - count / 2) / (count / 2) * 0.6))
        d.line(pts, fill=color + (a,), width=2 * s)
    layer = layer.resize((W, H), Image.LANCZOS)
    img.paste(layer, (0, 0), layer)


def title(d, y, light=False):
    first = INK if light else (255, 255, 255)
    second = BORDO if light else PINK
    centered(d, y, 'СТУДЕНТИ', font(150), first)
    centered(d, y + 178, 'ПОБЕДИЛИ.', font(150), second)


def photo(src, x0, out, darken_top=0.0):
    """Fotografija u donjem delu, gornji deo bordo prelaz."""
    im = Image.open(os.path.join(WALL, src)).convert('RGB').crop((x0, 0, x0 + W, 2160))
    canvas = gradient(TOP, tuple(int(v) for v in im.crop((0, 0, W, 40)).resize((1, 1), Image.BOX).getpixel((0, 0))))
    top = H - 2160
    mask = Image.new('L', (W, 2160), 255)
    md = ImageDraw.Draw(mask)
    ramp = 700
    for y in range(ramp):
        md.line([(0, y), (W, y)], fill=int(255 * (y / ramp) ** 1.6))
    canvas.paste(im, (0, top), mask)

    # tamni sloj odozgo do sredine, da sat i naslov budu citljivi
    shade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    end = top + 900
    for y in range(end):
        t = 1 - y / end
        sd.line([(0, y), (W, y)], fill=TOP + (int(255 * (0.25 + 0.75 * t) * (t ** 0.6) * (1 + darken_top)) if t > 0 else 0,))
    canvas.paste(shade, (0, 0), shade)

    # meka tamna senka iza naslova, da se cita i preko svetlog neba
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sdr = ImageDraw.Draw(sh)
    sdr.ellipse([W / 2 - 330, 925, W / 2 + 330, 1135], fill=(30, 3, 12, 120))
    sdr.text(((W - sdr.textlength('СТУДЕНТИ', font=font(150))) / 2, 1230), 'СТУДЕНТИ', font=font(150), fill=(30, 3, 12, 200))
    sdr.text(((W - sdr.textlength('ПОБЕДИЛИ.', font=font(150))) / 2, 1408), 'ПОБЕДИЛИ.', font=font(150), fill=(30, 3, 12, 220))
    sdr.rectangle([W / 2 - 380, 1660, W / 2 + 380, 1730], fill=(30, 3, 12, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(sh, (0, 0), sh)
    d = ImageDraw.Draw(canvas)
    ring_with_three(canvas, W // 2, 1030, 120, (255, 255, 255), (255, 255, 255), width=7)
    title(d, 1230)
    d.line([(W / 2 - 150, 1640), (W / 2 + 150, 1640)], fill=PINK, width=4)
    centered(d, 1672, 'ЗАЈЕДНО СМО ИСПИСАЛИ ИСТОРИЈУ', font(34, 700), (255, 255, 255), spacing=3)
    canvas.save(os.path.join(OUT, out), quality=93, optimize=True)


def bordo_three(out):
    img = gradient(TOP, BOTTOM)
    waves(img, (255, 210, 225), 34, 1050, 2350)
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([W / 2 - 560, 1100, W / 2 + 560, 2220], fill=(170, 40, 80, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    img.paste(glow, (0, 0), glow)
    ring_with_three(img, W // 2, 1660, 430, (240, 200, 212), (255, 255, 255), width=12, size=560)
    d = ImageDraw.Draw(img)
    title(d, 2230)
    d.line([(W / 2 - 330, 2660), (W / 2 + 330, 2660)], fill=(150, 70, 100), width=3)
    centered(d, 2700, 'СТУДЕНТСКА ЛИСТА  ·  2026', font(36, 700), PINK, spacing=3)
    img.save(os.path.join(OUT, out), quality=93, optimize=True)


def svetla(out):
    img = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(img)
    m = 56
    d.rectangle([m, m, W - m, H - m], outline=CREAM_LINE, width=3)
    # tanka mreza kao na 02
    for x in range(m + 120, W - m, 120):
        d.line([(x, m), (x, H - m)], fill=(241, 236, 226), width=1)
    for y in range(m + 120, H - m, 120):
        d.line([(m, y), (W - m, y)], fill=(241, 236, 226), width=1)
    d.rectangle([m, m, W - m, H - m], outline=CREAM_LINE, width=3)
    ring_with_three(img, W // 2, 1560, 400, BORDO, BORDO, width=12, size=520)
    d = ImageDraw.Draw(img)
    centered(d, 1040, 'СТУДЕНТСКА ЛИСТА', font(40, 800), BORDO, spacing=4)
    title(d, 2080, light=True)
    centered(d, 2500, '25. ОКТОБАР 2026.', font(48, 800), INK)
    centered(d, 2582, 'ПОБЕДА ЗНАЊА, СОЛИДАРНОСТИ И УПОРНОСТИ.', font(30, 500), (120, 100, 104), spacing=2)
    d.rectangle([m, H - m - 120, W - m, H - m], fill=BORDO)
    centered(d, H - m - 84, 'СТУДЕНТИ ПОБЕДИЛИ', font(38, 800), CREAM, spacing=4)
    img.save(os.path.join(OUT, out), quality=93, optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    photo('03-Pobeda-Desktop-4K.jpg', 2080, '1-Bordo-Skupstina.jpg')
    photo('06-Desktop-bez-teksta-4K.jpg', 2200, '2-Bordo-Univerzitet.jpg')
    bordo_three('3-Bordo-Trojka.jpg')
    svetla('4-Svetla.jpg')
    print('Gotovo:', OUT)
    if '--paket' in sys.argv:
        paket()


def paket():
    src = os.path.join(ROOT, 'Mobilni')
    os.makedirs(os.path.join(ROOT, 'dist'), exist_ok=True)
    dst = os.path.join(ROOT, 'dist', 'StudentiPobedili-Mobilni.zip')
    with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as z:
        for base, _, files in os.walk(src):
            for name in sorted(files):
                full = os.path.join(base, name)
                z.write(full, os.path.join('StudentiPobedili-Mobilni', os.path.relpath(full, src)))
    print('Paket:', dst, os.path.getsize(dst) // 1024, 'KB')


if __name__ == '__main__':
    main()
