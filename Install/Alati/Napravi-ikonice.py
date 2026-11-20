"""Pravi Windows .ico fajlove iz 512 px PNG mastera (Icons/PNG -> Icons/ICO).

Pokretanje (potreban Python 3 + Pillow):
    py -I Install/Alati/Napravi-ikonice.py

Sta radi:
- Velicine 16, 20, 24, 32, 40, 48, 64 kao 32-bitni BMP (DIB) i 96, 128, 256 kao PNG,
  kako Microsoft preporucuje (male PNG ikonice neki delovi Windows-a ne prikazuju dobro).
  20 i 40 px su za 125% i 250% skaliranja ekrana.
- Home, Gallery, Desktop, Dokumenti, Preuzimanja, Slike, Muzika, Video do 32 px koriste
  razlicite siluete (male_ikonice.py), da bi se razlikovale u levoj navigaciji Explorer-a.
- Ostale male velicine (<= 48 px) se crtaju posebno umesto da se samo smanji velika slika:
  * fascikle sa znackom: znacka (dokument, preuzimanje, slika...) se uvecava da bi se
    fascikle razlikovale i na 16 px u navigacionom oknu Explorer-a;
  * zaobljene plocice: uklanja se meka senka koja na malim velicinama pravi mrlju;
  * sve se secu na stvarne ivice slike da bi popunile okvir kao Windows ikonice.
"""
import io
import os
import struct
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # py -I ne dodaje fasciklu skripte
import male_ikonice      # noqa: E402  siluete za 16-32 px
import velike_plocice    # noqa: E402  Home/Gallery 512 px masteri

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PNG_DIR = os.path.join(ROOT, 'Icons', 'PNG')
ICO_DIR = os.path.join(ROOT, 'Icons', 'ICO')

BMP_SIZES = [16, 20, 24, 32, 40, 48, 64]
PNG_SIZES = [96, 128, 256]
SMALL = 48                       # do ove velicine vazi posebno crtanje
BADGE_C, BADGE_R = (399.5, 399.5), 73.5   # znacka u 512 px masteru
BADGE_RATIO = {16: 0.70, 20: 0.66, 24: 0.62, 32: 0.56, 40: 0.52, 48: 0.48}

FOLDER_BADGE = ['Folder-Documents', 'Folder-Downloads', 'Folder-Pictures', 'Folder-Music', 'Folder-Video',
                'Folder-Projects', 'Folder-Education', 'Folder-Team', 'Folder-Favorites']
TILES = ['Browser', 'Drive', 'Music', 'Network', 'Pictures', 'Printer', 'Security', 'User', 'Video', 'Home', 'Gallery']


def load(name):
    return Image.open(os.path.join(PNG_DIR, name + '.png')).convert('RGBA')


def alpha_bbox(im, threshold=24):
    return im.getchannel('A').point(lambda v: 255 if v > threshold else 0).getbbox()


def fit(im, size, sharpen):
    """Smanji sliku tako da stane u size x size uz ocuvan odnos stranica, centrirano."""
    w, h = im.size
    k = size / max(w, h)
    nw, nh = max(1, round(w * k)), max(1, round(h * k))
    # Smanjivanje u koracima daje cistije ivice nego jedan veliki skok.
    cur = im
    while cur.width > nw * 2:
        cur = cur.resize((cur.width // 2, cur.height // 2), Image.LANCZOS)
    cur = cur.resize((nw, nh), Image.LANCZOS)
    if sharpen:
        cur = unsharp_rgba(cur, size)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.alpha_composite(cur, ((size - nw) // 2, (size - nh) // 2))
    return out


def unsharp_rgba(im, size):
    pct = 70 if size <= 24 else 45
    rgb = im.convert('RGB').filter(ImageFilter.UnsharpMask(radius=0.8, percent=pct, threshold=1))
    out = rgb.convert('RGBA')
    out.putalpha(im.getchannel('A'))
    return out


def remove_soft_shadow(im):
    """Plocice imaju sivu meku senku dole desno; za male velicine je uklanjamo."""
    px = im.load()
    out = im.copy()
    po = out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if 0 < a < 250 and max(r, g, b) - min(r, g, b) < 28:
                po[x, y] = (r, g, b, 0)
    return out


def badge_from(master):
    cx, cy = BADGE_C
    r = BADGE_R
    box = (round(cx - r), round(cy - r), round(cx + r), round(cy + r))
    crop = master.crop(box)
    s = crop.width
    mask = Image.new('L', (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, s * 4 - 1, s * 4 - 1), fill=255)
    mask = mask.resize((s, s), Image.LANCZOS)
    crop.putalpha(ImageChops.multiply(crop.getchannel('A'), mask))
    return crop


def small_badged_folder(name, size, base_master):
    master = load(name)
    base = base_master.crop(alpha_bbox(base_master))
    canvas = fit(base, size, sharpen=True)
    d = max(7, round(size * BADGE_RATIO[size]))
    badge = badge_from(master)
    b = badge
    while b.width > d * 2:
        b = b.resize((b.width // 2, b.height // 2), Image.LANCZOS)
    b = unsharp_rgba(b.resize((d, d), Image.LANCZOS), size)
    canvas.alpha_composite(b, (size - d, size - d))
    return canvas


def render(name, size, base_master):
    if name in male_ikonice.GLYPHS and size <= male_ikonice.GLYPH_MAX:
        return male_ikonice.GLYPHS[name](size)
    master = load(name)
    if size > SMALL:
        return fit(master, size, sharpen=False) if size != 256 else master.resize((256, 256), Image.LANCZOS)
    if name in FOLDER_BADGE:
        return small_badged_folder(name, size, base_master)
    src = remove_soft_shadow(master) if name in TILES else master
    return fit(src.crop(alpha_bbox(src)), size, sharpen=True)


def bmp_entry(im):
    s = im.width
    header = struct.pack('<IiiHHIIiiII', 40, s, s * 2, 1, 32, 0, 0, 0, 0, 0, 0)
    px = im.load()
    rows = bytearray()
    for y in range(s - 1, -1, -1):
        for x in range(s):
            r, g, b, a = px[x, y]
            rows += bytes((b, g, r, a))
    stride = ((s + 31) // 32) * 4
    mask = bytearray()
    for y in range(s - 1, -1, -1):
        row = bytearray(stride)
        for x in range(s):
            if px[x, y][3] == 0:
                row[x // 8] |= 0x80 >> (x % 8)
        mask += row
    return header + bytes(rows) + bytes(mask)


def png_entry(im):
    buf = io.BytesIO()
    im.save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def write_ico(path, images):
    entries = [(im.width, bmp_entry(im) if im.width in BMP_SIZES else png_entry(im)) for im in images]
    offset = 6 + 16 * len(entries)
    out = bytearray(struct.pack('<HHH', 0, 1, len(entries)))
    data = bytearray()
    for size, blob in entries:
        dim = 0 if size >= 256 else size
        out += struct.pack('<BBBBHHII', dim, dim, 0, 0, 1, 32, len(blob), offset + len(data))
        data += blob
    with open(path, 'wb') as f:
        f.write(out + data)


def main():
    # Novi masteri: Home i Gallery (plocice), Desktop (isti crtez kao Monitor, druga mala silueta)
    velike_plocice.build(PNG_DIR)
    load('Monitor').save(os.path.join(PNG_DIR, 'Desktop.png'))
    names = sorted(os.path.splitext(f)[0] for f in os.listdir(PNG_DIR) if f.lower().endswith('.png'))
    out_dir = sys.argv[1] if len(sys.argv) > 1 else ICO_DIR   # opciono: druga izlazna fascikla
    os.makedirs(out_dir, exist_ok=True)
    # Fascikla bez broja "3" (broj je uklonjen iz Folder-3.png): na malim velicinama znacka bi
    # prekrila pola broja i ostao bi besmislen beli komadic.
    base_master = Image.open(os.path.join(os.path.dirname(__file__), 'izvor', 'Folder-bez-broja-512.png')).convert('RGBA')
    for name in names:
        images = [render(name, s, base_master) for s in BMP_SIZES + PNG_SIZES]
        write_ico(os.path.join(out_dir, name + '.ico'), images)
        print('ok', name)


if __name__ == '__main__':
    sys.exit(main())
