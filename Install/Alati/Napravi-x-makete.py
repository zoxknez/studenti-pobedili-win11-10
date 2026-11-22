"""Makete Windows 11 sa temom za Preview/X (1920x1080, UI na 150%).

Pokretanje: python Install/Alati/Napravi-x-makete.py <koren projekta>
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

P = sys.argv[1]
OUT = os.path.join(P, 'Preview', 'X')
os.makedirs(OUT, exist_ok=True)
W, H = 1920, 1080
S = 1.5
F = 'C:/Windows/Fonts/'
def font(size, w='regular'):
    name = {'regular': 'segoeui.ttf', 'semi': 'seguisb.ttf', 'bold': 'segoeuib.ttf', 'black': 'seguibl.ttf', 'sym': 'seguisym.ttf'}[w]
    return ImageFont.truetype(F + name, round(size))

def ico(name, size):
    im = Image.open(os.path.join(P, 'Icons', 'ICO', name + '.ico'))
    sizes = sorted(im.info['sizes'])
    exact = [s for s in sizes if s[0] == size]
    im.size = exact[0] if exact else [s for s in sizes if s[0] >= size][0]
    im = im.convert('RGBA')
    return im if im.width == size else im.resize((size, size), Image.LANCZOS)

def wall(name):
    return Image.open(os.path.join(P, 'Wallpapers', name)).convert('RGB').resize((W, H), Image.LANCZOS).convert('RGBA')

def layer():
    return Image.new('RGBA', (W, H), (0, 0, 0, 0))

def shadow_text(img, xy, text, f, fill=(255, 255, 255)):
    l = layer(); d = ImageDraw.Draw(l)
    d.text((xy[0] + 1, xy[1] + 2), text, font=f, fill=(0, 0, 0, 200), anchor='ma')
    img.alpha_composite(l.filter(ImageFilter.GaussianBlur(2)))
    ImageDraw.Draw(img).text(xy, text, font=f, fill=fill, anchor='ma')

def taskbar(img, dark=True):
    h = round(48 * S)
    bar = img.crop((0, H - h, W, H)).filter(ImageFilter.GaussianBlur(30))
    img.paste(bar, (0, H - h))
    l = layer(); d = ImageDraw.Draw(l)
    tint = (78, 8, 26, 215) if dark else (243, 238, 238, 215)
    d.rectangle((0, H - h, W, H), fill=tint)
    d.line((0, H - h, W, H - h), fill=(255, 255, 255, 30 if dark else 120), width=1)
    img.alpha_composite(l)
    d = ImageDraw.Draw(img)
    fg = (255, 255, 255) if dark else (26, 26, 26)
    icons = ['__start', '__search', 'Explorer', 'Browser', 'Settings', 'Pictures', 'Music', 'Video']
    isz = round(24 * S); gap = round(44 * S)
    search_w = round(140 * S)
    total = gap * (len(icons) - 1) + search_w
    x = (W - total) // 2
    cy = H - h // 2
    for n in icons:
        if n == '__start':
            q = round(9 * S); g = round(1.5 * S)
            col = (255, 190, 200) if dark else (152, 31, 52)
            for dx in (0, 1):
                for dy in (0, 1):
                    x0 = x - q - g // 2 + dx * (q + g); y0 = cy - q - g // 2 + dy * (q + g)
                    d.rounded_rectangle((x0, y0, x0 + q, y0 + q), radius=2, fill=col)
            x += gap
            continue
        if n == '__search':
            pill = (x - round(14 * S), cy - round(16 * S), x - round(14 * S) + search_w, cy + round(16 * S))
            l = layer(); ImageDraw.Draw(l).rounded_rectangle(pill, radius=round(16 * S), fill=(255, 255, 255, 34 if dark else 200), outline=(255, 255, 255, 40 if dark else 0))
            img.alpha_composite(l); d = ImageDraw.Draw(img)
            d.text((pill[0] + round(36 * S), cy), 'Pretraga', font=font(13 * S), fill=fg, anchor='lm')
            d.ellipse((pill[0] + round(12 * S), cy - round(6 * S), pill[0] + round(24 * S), cy + round(6 * S)), outline=fg, width=2)
            x += search_w + round(10 * S)
            continue
        im = ico(n, isz)
        if n == 'Explorer':
            l = layer(); ImageDraw.Draw(l).rounded_rectangle((x - round(18 * S), cy - round(19 * S), x + round(18 * S), cy + round(19 * S)), radius=round(5 * S), fill=(255, 255, 255, 28 if dark else 150))
            img.alpha_composite(l); d = ImageDraw.Draw(img)
            d.rounded_rectangle((x - round(8 * S), H - round(5 * S), x + round(8 * S), H - round(2 * S)), radius=2, fill=(226, 84, 108))
        img.alpha_composite(im, (x - isz // 2, cy - isz // 2))
        x += gap
    rf = font(12 * S)
    d.text((W - round(18 * S), cy - round(9 * S)), '20:26', font=rf, fill=fg, anchor='rm')
    d.text((W - round(18 * S), cy + round(9 * S)), '25.10.2026.', font=rf, fill=fg, anchor='rm')

def desktop_icons(img, items):
    isz = round(48 * S); cell = round(76 * S)
    x = round(14 * S) + cell // 2; y = round(14 * S)
    for name, label in items:
        img.alpha_composite(ico(name, isz) if isz <= 64 else ico(name, 256).resize((isz, isz), Image.LANCZOS), (x - isz // 2, y))
        shadow_text(img, (x, y + isz + round(4 * S)), label, font(12 * S))
        y += round(90 * S)

def save(img, name):
    img.convert('RGB').save(os.path.join(OUT, name), quality=92)
    print('saved', name)

def explorer(img, box, dark=True, title='Fakultet', selected='Fakultet'):
    x0, y0, x1, y1 = box
    k = 1.25
    def r(v): return round(v * k)
    C = dict(
        bg=(32, 32, 32) if dark else (249, 249, 249), nav=(28, 28, 28) if dark else (243, 243, 243),
        text=(255, 255, 255) if dark else (26, 26, 26), dim=(170, 170, 170) if dark else (96, 96, 96),
        line=(58, 58, 58) if dark else (225, 225, 225), sel=(55, 55, 55) if dark else (229, 229, 229),
        title=(96, 14, 36) if dark else (152, 31, 52), pill=(45, 45, 45) if dark else (255, 255, 255))
    # senka prozora
    sh = layer(); ImageDraw.Draw(sh).rounded_rectangle((x0 + 6, y0 + 16, x1 + 6, y1 + 22), radius=r(10), fill=(0, 0, 0, 150))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(28)))
    mask = Image.new('L', (W, H), 0); ImageDraw.Draw(mask).rounded_rectangle(box, radius=r(8), fill=255)
    win = layer(); d = ImageDraw.Draw(win)
    d.rectangle(box, fill=C['bg'])
    tb = y0 + r(40)
    d.rectangle((x0, y0, x1, tb), fill=C['title'])                      # naslovna traka u akcentnoj boji
    tab = (x0 + r(8), y0 + r(7), x0 + r(240), tb)
    d.rounded_rectangle(tab, radius=r(8), fill=C['bg']); d.rectangle((tab[0], tb - r(8), tab[2], tb), fill=C['bg'])
    win.alpha_composite(ico('Folder-3', r(16)), (tab[0] + r(12), tab[1] + r(9)))
    d.text((tab[0] + r(38), tab[1] + r(17)), title, font=font(r(12)), fill=C['text'], anchor='lm')
    d.text((tab[2] - r(16), tab[1] + r(17)), '✕', font=font(r(10), 'sym'), fill=C['dim'], anchor='mm')
    d.text((tab[2] + r(22), tab[1] + r(16)), '+', font=font(r(16)), fill=(255, 255, 255), anchor='mm')
    for i, ch in enumerate(['✕', '▢', '—']):
        d.text((x1 - r(24) - i * r(46), y0 + r(20)), ch, font=font(r(12), 'sym'), fill=(255, 255, 255), anchor='mm')
    # adresna traka
    ab = tb + r(48)
    for i, ch in enumerate(['←', '→', '↑', '⟳']):
        d.text((x0 + r(22) + i * r(36), tb + r(24)), ch, font=font(r(15), 'sym'), fill=C['dim'] if i == 1 else C['text'], anchor='mm')
    d.rounded_rectangle((x0 + r(160), tb + r(9), x1 - r(260), ab - r(9)), radius=r(4), fill=C['pill'])
    win.alpha_composite(ico('ThisPC', r(16)), (x0 + r(170), tb + r(16)))
    d.text((x0 + r(196), tb + r(24)), '›   Ovaj računar   ›   Podaci (D:)   ›   ' + title, font=font(r(12)), fill=C['text'], anchor='lm')
    d.rounded_rectangle((x1 - r(248), tb + r(9), x1 - r(12), ab - r(9)), radius=r(4), fill=C['pill'])
    d.text((x1 - r(236), tb + r(24)), 'Pretraži: ' + title, font=font(r(12)), fill=C['dim'], anchor='lm')
    # komandna traka
    cb = ab + r(44)
    d.line((x0, ab, x1, ab), fill=C['line'])
    d.text((x0 + r(20), ab + r(22)), '⊕  Novo', font=font(r(12), 'sym'), fill=C['text'], anchor='lm')
    d.text((x0 + r(120), ab + r(22)), '✂     ⧉     ⎘     ✎     ⇪     🗑', font=font(r(12), 'sym'), fill=C['dim'], anchor='lm')
    d.text((x1 - r(250), ab + r(22)), '⇅  Sortiraj      ☰  Prikaz      ⋯', font=font(r(12), 'sym'), fill=C['text'], anchor='lm')
    d.line((x0, cb, x1, cb), fill=C['line'])
    # leva navigacija
    nw = r(230)
    d.rectangle((x0, cb + 1, x0 + nw, y1), fill=C['nav'])
    items = [('Home', 'Početna'), ('Gallery', 'Galerija'), None, ('Desktop', 'Radna površina'), ('Folder-Downloads', 'Preuzimanja'),
             ('Folder-Documents', 'Dokumenti'), ('Folder-Pictures', 'Slike'), ('Folder-Music', 'Muzika'), ('Folder-Video', 'Video'),
             None, ('ThisPC', 'Ovaj računar'), ('Drive', 'Lokalni disk (C:)'), ('Drive', 'Podaci (D:)')]
    y = cb + r(12)
    pins = {'Desktop', 'Folder-Downloads', 'Folder-Documents', 'Folder-Pictures', 'Folder-Music', 'Folder-Video'}
    for it in items:
        if it is None:
            d.line((x0 + r(16), y + r(8), x0 + nw - r(16), y + r(8)), fill=C['line']); y += r(16); continue
        n, label = it
        if label == 'Podaci (D:)':
            d.rounded_rectangle((x0 + r(6), y, x0 + nw - r(6), y + r(30)), radius=r(4), fill=C['sel'])
        win.alpha_composite(ico(n, r(16) if n in ('ThisPC', 'Drive') else 20), (x0 + r(20), y + r(7)))
        d.text((x0 + r(50), y + r(15)), label, font=font(r(12)), fill=C['text'], anchor='lm')
        if n in pins: d.text((x0 + nw - r(22), y + r(15)), '📌', font=font(r(9), 'sym'), fill=C['dim'], anchor='mm')
        y += r(32)
    # sadrzaj: velike ikonice
    folders = [('Folder-3', 'Fakultet'), ('Folder-Projects', 'Projekti'), ('Folder-Education', 'Ispiti'), ('Folder-Team', 'Tim'),
               ('Folder-Favorites', 'Omiljeno'), ('Folder-Pictures', 'Slike sa protesta'), ('Folder-Video', 'Snimci'),
               ('Folder-Music', 'Muzika'), ('Folder-Documents', 'Dokumenta'), ('Folder-3', 'Arhiva')]
    isz = r(80); cw = r(118); chh = r(126)
    cx0 = x0 + nw + r(24); cy0 = cb + r(20)
    cols = max(1, (x1 - cx0 - r(10)) // cw)
    for i, (n, label) in enumerate(folders):
        cx = cx0 + (i % cols) * cw; cy = cy0 + (i // cols) * chh
        if cy + chh > y1 - r(30): break
        if label == selected:
            d.rounded_rectangle((cx - r(4), cy - r(4), cx + cw - r(10), cy + chh - r(10)), radius=r(4),
                                fill=(70, 26, 37) if dark else (246, 225, 230), outline=(176, 58, 82) if dark else (214, 120, 140))
        big = ico(n, 256).resize((isz, isz), Image.LANCZOS)
        win.alpha_composite(big, (cx + (cw - r(10) - isz) // 2, cy + r(4)))
        d.text((cx + (cw - r(10)) // 2, cy + isz + r(12)), label, font=font(r(12)), fill=C['text'], anchor='ma')
    d.text((x0 + nw + r(16), y1 - r(16)), f'{len(folders)} stavki', font=font(r(11)), fill=C['dim'], anchor='lm')
    win.putalpha(Image.composite(win.getchannel('A'), Image.new('L', (W, H), 0), mask))
    img.alpha_composite(win)

def taskbar_scale(v):
    global S
    S = v

# 1) Bordo desktop
img = wall('01-Pobeda-Cinematic-4K.jpg')
desktop_icons(img, [('ThisPC', 'Ovaj računar'), ('RecycleBin-Full', 'Korpa'), ('User', 'Korisnik'), ('Folder-3', 'Fakultet')])
taskbar(img, dark=True)
save(img, '1-Bordo-desktop.jpg')

# 2) File Explorer (tamni rezim)
S = 1.25
img = wall('04-Beograd-4K.jpg')
explorer(img, (96, 70, 1290, 950), dark=True)
taskbar(img, dark=True)
save(img, '2-File-Explorer.jpg')

# 3) Svetla varijanta
img = wall('02-Pobeda-Minimal-Light-4K.jpg')
explorer(img, (1010, 170, 1880, 900), dark=False, title='Dokumenta', selected='Dokumenta')
taskbar(img, dark=False)
save(img, '3-Svetla.jpg')

# 4-Ikonice.jpg ne zavisi od pozadina i ne pravi se ponovo.
