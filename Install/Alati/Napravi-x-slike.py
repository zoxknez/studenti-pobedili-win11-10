"""Slike za X thread: naslovna (svi sistemi), Linux, macOS. 1600x900."""
import os
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = r'D:\ProjektiApp\StudentiPobedili_Windows11-10'
OUT = os.path.join(ROOT, 'Preview', 'X-Objava')
os.makedirs(OUT, exist_ok=True)
W, H = 1600, 900
FONT = 'C:/Windows/Fonts/NotoSans-VariableFont_wdth,wght.ttf'
TOP, BOT = (30, 5, 13), (78, 12, 38)
PINK = (240, 188, 204)
CREAM = (248, 236, 238)
MUTED = (205, 175, 183)
ROSE = (226, 84, 108)


def font(sz, w=800):
    f = ImageFont.truetype(FONT, sz)
    f.set_variation_by_axes([w, 100])
    return f


def gradient(w=W, h=H, c1=TOP, c2=BOT):
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / (h - 1)
        g.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(c1, c2)))
    return g.resize((w, h))


def glow(img, box, color=(170, 40, 80, 70), blur=180):
    g = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse(box, fill=color)
    g = g.filter(ImageFilter.GaussianBlur(blur))
    img.paste(g, (0, 0), g)


def shadow(img, box, radius, blur=28, alpha=170, off=(0, 24)):
    s = Image.new('RGBA', img.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    ImageDraw.Draw(s).rounded_rectangle([x0 + off[0], y0 + off[1], x1 + off[0], y1 + off[1]], radius, fill=(0, 0, 0, alpha))
    s = s.filter(ImageFilter.GaussianBlur(blur))
    img.paste(s, (0, 0), s)


def rounded_paste(img, src, xy, radius):
    S = 3
    w, h = src.size
    m = Image.new('L', (w * S, h * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, fill=255)
    img.paste(src, xy, m.resize((w, h), Image.LANCZOS))


def pill(d, x, y, text, f, fill=(255, 236, 240, 30), color=CREAM, pad=(18, 9), outline=(255, 214, 222)):
    tw = d.textlength(text, font=f)
    bb = f.getbbox('Ag')
    h = bb[3] - bb[1] + pad[1] * 2
    d.rounded_rectangle([x, y, x + tw + pad[0] * 2, y + h], h // 2, fill=(70, 18, 34), outline=(120, 50, 70), width=2)
    d.text((x + pad[0], y + pad[1] - bb[1]), text, font=f, fill=color)
    return x + tw + pad[0] * 2


def cover(im, w, h):
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def phone(img, path, x, y, w, radius=38):
    """Telefon 9:19.5; pozadina 9:16 se iseca sa strana, kao na pravom telefonu."""
    h = int(w * 19.5 / 9)
    shadow(img, (x, y, x + w, y + h), radius + 2, blur=30, alpha=190)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x - 8, y - 8, x + w + 8, y + h + 8], radius + 8, fill=(29, 17, 20), outline=(95, 62, 72), width=2)
    rounded_paste(img, cover(Image.open(path).convert('RGB'), w, h), (x, y), radius)
    d.rounded_rectangle([x + w / 2 - w * 0.15, y + h * 0.018, x + w / 2 + w * 0.15, y + h * 0.045], 999, fill=(0, 0, 0))


def title(d, x, y, size=118):
    d.text((x, y), 'Студенти', font=font(size, 850), fill=(255, 255, 255))
    f = font(size, 850)
    d.text((x, y + size * 1.08), 'победили', font=f, fill=(255, 255, 255))
    d.text((x + d.textlength('победили', font=f) + 4, y + size * 1.08), '.', font=f, fill=ROSE)


# 1) Naslovna: svi sistemi
def naslovna():
    bg = gradient()
    glow(bg, (760, 60, 1700, 960), color=(180, 40, 80, 80))
    d = ImageDraw.Draw(bg)
    x = pill(d, 70, 64, 'Nova verzija 2.4', font(24, 700)) + 12
    pill(d, x, 64, 'Nove pozadine · srpske zastave', font(24, 700), color=PINK)
    title(d, 66, 120)
    d.text((72, 405), 'Jedna tema za sve vaše uređaje', font=font(36, 700), fill=CREAM)
    x = 72
    for name in ['Windows', 'Linux', 'macOS', 'Android', 'iPhone']:
        x = pill(d, x, 480, name, font(26, 750)) + 12
    d.text((72, 560), 'Pozadine u 4K · 31 ikonica · zaključani ekran · zvuk', font=font(26, 600), fill=MUTED)
    d.text((72, 600), 'Besplatno · bez admin prava · potpuna deinstalacija', font=font(26, 600), fill=MUTED)
    d.text((72, 790), 'studenti-tema.vercel.app', font=font(34, 800), fill=(255, 255, 255))

    # desktop prozor + telefon
    desk = Image.open(os.path.join(ROOT, 'Preview', 'X', '1-Bordo-desktop.jpg')).convert('RGB').resize((704, 396), Image.LANCZOS)
    bx, by = 800, 230
    shadow(bg, (bx, by, bx + 704, by + 396), 18, blur=30, alpha=200)
    d.rounded_rectangle([bx - 10, by - 10, bx + 714, by + 406], 22, fill=(29, 17, 20), outline=(110, 70, 82), width=2)
    rounded_paste(bg, desk, (bx, by), 14)
    phone(bg, os.path.join(ROOT, 'Mobilni', 'Pozadine', '1-Bordo-Skupstina.jpg'), 1330, 370, 200)
    bg.save(os.path.join(OUT, '1-Svi-sistemi.jpg'), quality=92, optimize=True)


# Preview/Telefon.jpg: sve cetiri pozadine za telefon
def telefon():
    img = gradient(2000, 1125, (30, 5, 13), (70, 11, 34))
    glow(img, (300, 150, 1700, 1100), color=(170, 40, 80, 60), blur=200)
    names = ['1-Bordo-Skupstina', '2-Bordo-Talasi', '3-Svetla', '4-Nocna']
    pw, gap = 380, 60
    x0 = (2000 - (4 * pw + 3 * gap)) // 2
    for i, n in enumerate(names):
        phone(img, os.path.join(ROOT, 'Mobilni', 'Pozadine', n + '.jpg'), x0 + i * (pw + gap), 110 + (0 if i % 2 == 0 else 40), pw, radius=56)
    d = ImageDraw.Draw(img)
    t = 'Студенти победили  ·  Android и iPhone'
    f = font(40, 800)
    d.text(((2000 - d.textlength(t, font=f)) / 2, 1030), t, font=f, fill=(248, 232, 236))
    img.save(os.path.join(ROOT, 'Preview', 'Telefon.jpg'), quality=90, optimize=True)


# 3) Linux
def linux():
    img = gradient()
    glow(img, (700, 100, 1700, 950))
    d = ImageDraw.Draw(img)
    pill(d, 70, 70, 'Linux', font(24, 750))
    d.text((66, 120), 'GNOME', font=font(84, 850), fill=(255, 255, 255))
    d.text((66, 215), 'i KDE Plasma', font=font(84, 850), fill=PINK)
    y = 390
    for line in ['Pozadine prate tamni i svetli režim', 'Bordo šeme boja i naslovne trake (KDE)',
                 'Tema ikonica, i u Dolphin-u i Files-u', 'Bez sudo, potpuno vraćanje podešavanja']:
        d.ellipse([72, y + 13, 84, y + 25], fill=ROSE)
        d.text((102, y), line, font=font(27, 600), fill=CREAM)
        y += 54
    pill(d, 70, 650, 'Ubuntu Unity iz zajednice · @UrosUbuntu', font(22, 700))
    d.text((72, 790), 'studenti-tema.vercel.app/#linux', font=font(32, 800), fill=(255, 255, 255))
    shot = Image.open(os.path.join(ROOT, 'Preview', 'Linux-Dolphin.png')).convert('RGB')
    shot = shot.resize((790, 540), Image.LANCZOS)
    sx, sy = 750, 180
    shadow(img, (sx, sy, sx + 790, sy + 540), 18, blur=30, alpha=210)
    d.rounded_rectangle([sx - 8, sy - 8, sx + 798, sy + 548], 22, fill=(29, 17, 20), outline=(110, 70, 82), width=2)
    rounded_paste(img, shot, (sx, sy), 14)
    d.text((sx, sy + 566), 'Pravi snimak: KDE Plasma 6, Dolphin', font=font(22, 600), fill=MUTED)
    img.save(os.path.join(OUT, '3-Linux.jpg'), quality=92, optimize=True)


# 4) macOS
def mac():
    img = gradient()
    glow(img, (760, 80, 1650, 900))
    d = ImageDraw.Draw(img)
    x = pill(d, 70, 70, 'macOS', font(24, 750)) + 12
    pill(d, x, 70, 'Beta · tražimo testere', font(24, 750), color=PINK)
    d.text((66, 120), 'I za Mac.', font=font(110, 850), fill=(255, 255, 255))
    y = 300
    for line in ['Bordo ili Svetla pozadina', 'Tamni ili svetli režim, crveni akcenat',
                 'Nove ikonice fascikli u Finder-u', 'Crvena „3“ za bilo koju fasciklu',
                 'Bez admin lozinke, potpuno vraćanje']:
        d.ellipse([72, y + 13, 84, y + 25], fill=ROSE)
        d.text((102, y), line, font=font(30, 600), fill=CREAM)
        y += 56
    d.text((72, 640), 'Imate Mac? Isprobajte i javite nam', font=font(30, 700), fill=PINK)
    d.text((72, 680), 'kako radi, svaka povratna informacija pomaže.', font=font(30, 600), fill=MUTED)
    d.text((72, 790), 'studenti-tema.vercel.app/#macos', font=font(32, 800), fill=(255, 255, 255))
    icons = [('Folder-Documents', 'Documents'), ('Folder-Downloads', 'Downloads'), ('Folder-Pictures', 'Pictures'),
             ('Folder-Music', 'Music'), ('Folder-Video', 'Movies'), ('Folder-3', 'Po izboru')]
    cx0, cy0, step_x, step_y, sz = 845, 170, 230, 290, 200
    panel = (820, 130, 1530, 770)
    p = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(p).rounded_rectangle(panel, 28, fill=(255, 236, 240, 14), outline=(255, 214, 222, 40), width=2)
    img.paste(p, (0, 0), p)
    d = ImageDraw.Draw(img)
    for i, (n, label) in enumerate(icons):
        ix = cx0 + (i % 3) * step_x
        iy = cy0 + (i // 3) * step_y
        ic = Image.open(os.path.join(ROOT, 'Icons', 'PNG', n + '.png')).convert('RGBA').resize((sz, sz), Image.LANCZOS)
        sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
        sh.paste((0, 0, 0, 150), (ix, iy + 18), ic.split()[3])
        sh = sh.filter(ImageFilter.GaussianBlur(14))
        img.paste(sh, (0, 0), sh)
        img.paste(ic, (ix, iy), ic)
        f = font(24, 700)
        d.text((ix + (sz - d.textlength(label, font=f)) / 2, iy + sz + 6), label, font=f, fill=MUTED)
    img.save(os.path.join(OUT, '4-macOS.jpg'), quality=92, optimize=True)


# Preview/Pregled-Pozadina.png: sve pozadine na jednoj slici
def pregled_pozadina():
    W2 = 1200
    img = gradient(W2, 1640, (22, 4, 10), (48, 8, 24))
    d = ImageDraw.Draw(img)
    d.text((40, 30), 'Pozadine', font=font(44, 850), fill=(255, 255, 255))
    d.text((40, 90), 'Računar (4K), ultrawide, tablet i telefon', font=font(24, 600), fill=MUTED)
    wall = os.path.join(ROOT, 'Wallpapers')
    f = font(18, 700)

    def tile(name, box, label):
        x0, y0, x1, y1 = box
        im = cover(Image.open(os.path.join(wall, name)).convert('RGB'), x1 - x0, y1 - y0)
        rounded_paste(img, im, (x0, y0), 12)
        d.text((x0 + 4, y1 + 8), label, font=f, fill=MUTED)

    g, m = 20, 40
    w2 = (W2 - 2 * m - g) // 2
    h2 = w2 * 9 // 16
    y = 140
    walls = [('01-Pobeda-Cinematic-4K.jpg', '01 · Cinematic'), ('02-Pobeda-Minimal-Light-4K.jpg', '02 · Minimal Light'),
             ('03-Pobeda-Bordo-Talasi-4K.jpg', '03 · Bordo talasi'), ('04-Beograd-4K.jpg', '04 · Beograd')]
    for i, (n, label) in enumerate(walls):
        x = m + (i % 2) * (w2 + g)
        yy = y + (i // 2) * (h2 + 44)
        tile(n, (x, yy, x + w2, yy + h2), label)
    y += 2 * (h2 + 44)
    uw = W2 - 2 * m
    tile('05-Beograd-Ultrawide-5120x2160.jpg', (m, y, m + uw, y + uw * 2160 // 5120), '05 · Ultrawide 21:9')
    y += uw * 2160 // 5120 + 44
    tw = (W2 - 2 * m - 3 * g) // 4
    th = tw * 3 // 4
    tile('06-Univerzitet-Tablet-2880x2160.jpg', (m, y, m + tw, y + th), '06 · Tablet')
    tile('07-Minimal-Light-Tablet-2880x2160.jpg', (m + tw + g, y, m + 2 * tw + g, y + th), '07 · Tablet svetla')
    # telefoni desno od tableta
    pw = (2 * tw + g - 3 * 12) // 4
    ph = pw * 16 // 9
    for i, n in enumerate(['1-Bordo-Skupstina', '2-Bordo-Talasi', '3-Svetla', '4-Nocna']):
        x = m + 2 * (tw + g) + i * (pw + 12)
        im = cover(Image.open(os.path.join(ROOT, 'Mobilni', 'Pozadine', n + '.jpg')).convert('RGB'), pw, ph)
        rounded_paste(img, im, (x, y), 14)
    d.text((m + 2 * (tw + g) + 4, y + ph + 8), 'Telefon (Android i iPhone)', font=f, fill=MUTED)
    img = img.crop((0, 0, W2, y + ph + 60))
    img.save(os.path.join(ROOT, 'Preview', 'Pregled-Pozadina.png'), optimize=True)


telefon()
naslovna()
linux()
mac()
pregled_pozadina()
for src, dst in [('X/1-Bordo-desktop.jpg', '2a-Windows-Bordo.jpg'), ('X/2-File-Explorer.jpg', '2b-Windows-Explorer.jpg'),
                 ('X/3-Svetla.jpg', '2c-Windows-Svetla.jpg'), ('X/4-Ikonice.jpg', '2d-Windows-Ikonice.jpg'),
                 ('Telefon.jpg', '5-Android-iPhone.jpg')]:
    shutil.copy(os.path.join(ROOT, 'Preview', src), os.path.join(OUT, dst))
print('ok')
