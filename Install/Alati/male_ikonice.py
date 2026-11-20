"""Male ikonice (16-32 px) za levu navigaciju i prikaz detalja u Explorer-u.

Na 16 px fascikla sa znackom izgleda isto za sve stavke, pa male velicine koriste razlicite
siluete (kao sto to radi i Windows): kucica, slike, ekran, strelica, list, pejzaz, nota, kamera.
Stil: bordo gradijent, tanka tamna ivica, suptilan odsjaj, krem detalji. Crta se na mrezi
16 x 16 jedinica sa 16x nadsemplovanjem i smanjuje box filterom, pa su ivice ciste.
"""
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SS = 16
TOP = (212, 62, 88)        # svetliji bordo (gore) - dovoljno svetao za tamni rezim
BOTTOM = (142, 20, 50)     # dubok bordo (dole) - ton brenda
EDGE = (104, 10, 36, 175)  # tanka ivica za kontrast na svetloj pozadini
CREAM = (255, 244, 241, 255)
ROSE = (240, 156, 170)     # zadnja kartica u galeriji


class Canvas:
    def __init__(self, size):
        self.size = size
        self.n = size * SS
        self.k = self.n / 16.0
        self.img = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))

    def p(self, pts):
        return [(x * self.k, y * self.k) for x, y in pts]

    def r(self, box):
        x0, y0, x1, y1 = box
        return (x0 * self.k, y0 * self.k, x1 * self.k, y1 * self.k)

    def mask(self):
        return Image.new('L', (self.n, self.n), 0)

    def gradient(self, top=TOP, bottom=BOTTOM):
        g = Image.new('RGBA', (1, 256))
        for y in range(256):
            t = y / 255
            g.putpixel((0, y), tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,))
        return g.resize((self.n, self.n), Image.BILINEAR)

    def fill(self, m, color=None, edge=True, gloss=True, top=TOP, bottom=BOTTOM):
        """Popuni masku gradijentom (ili bojom), sa ivicom i odsjajem."""
        if edge:
            # Uvek 1 piksel u konacnoj velicini (MaxFilter radi sa neparnim velicinama).
            grown = m.filter(ImageFilter.MaxFilter(SS * 2 + 1))
            ring = ImageChops.subtract(grown, m)
            layer = Image.new('RGBA', (self.n, self.n), EDGE)
            layer.putalpha(ImageChops.multiply(ring, Image.new('L', ring.size, EDGE[3])))
            self.img.alpha_composite(layer)
        layer = Image.new('RGBA', (self.n, self.n), color) if color else self.gradient(top, bottom)
        layer.putalpha(m)
        self.img.alpha_composite(layer)
        if gloss:
            # Mek odsjaj: jaci gore, nestaje do sredine visine (bez ostre linije).
            col = Image.new('L', (1, 256))
            for y in range(256):
                col.putpixel((0, y), max(0, round(46 * (1 - y / 128)))) if y < 128 else col.putpixel((0, y), 0)
            g = col.resize((self.n, self.n), Image.BILINEAR)
            gl = Image.new('RGBA', (self.n, self.n), (255, 255, 255, 255))
            gl.putalpha(ImageChops.multiply(g, m))
            self.img.alpha_composite(gl)

    def cream(self, m):
        layer = Image.new('RGBA', (self.n, self.n), CREAM)
        layer.putalpha(m)
        self.img.alpha_composite(layer)

    def done(self):
        return self.img.reduce(SS)


def rr(c, box, radius):
    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.r(box), radius=radius * c.k, fill=255)
    return m


def poly(c, pts):
    m = c.mask()
    ImageDraw.Draw(m).polygon(c.p(pts), fill=255)
    return m


def ellipse(c, box):
    m = c.mask()
    ImageDraw.Draw(m).ellipse(c.r(box), fill=255)
    return m


def union(*ms):
    out = ms[0]
    for m in ms[1:]:
        out = ImageChops.lighter(out, m)
    return out


def minus(a, b):
    return ImageChops.subtract(a, b)


# ---------------------------------------------------------------- ikonice
def home(size):
    c = Canvas(size)
    body = union(poly(c, [(8, 1.0), (15.4, 7.8), (13.2, 7.8), (13.2, 15), (2.8, 15), (2.8, 7.8), (0.6, 7.8)]))
    door = rr(c, (6.4, 9.6, 9.6, 15.2), 1.4)
    c.fill(minus(body, door))
    c.cream(minus(rr(c, (6.4, 9.6, 9.6, 15), 1.4), c.mask()))
    return c.done()


def gallery(size):
    c = Canvas(size)
    back = rr(c, (4.2, 1.2, 15.2, 10.6), 1.6)
    front = rr(c, (0.8, 4.6, 12.2, 14.8), 1.6)
    c.fill(minus(back, front.filter(ImageFilter.MaxFilter(SS * 2 + 1))), top=ROSE, bottom=(214, 96, 118), gloss=False)
    c.fill(front)
    c.cream(union(poly(c, [(2.4, 13.2), (5.6, 8.8), (7.7, 11.2), (9.0, 9.8), (10.8, 13.2)]), ellipse(c, (8.0, 6.0, 10.4, 8.4))))
    return c.done()


def desktop(size):
    c = Canvas(size)
    screen = rr(c, (0.8, 1.6, 15.2, 11.8), 1.6)
    stand = union(poly(c, [(6.4, 11.4), (9.6, 11.4), (10.0, 13.6), (6.0, 13.6)]), rr(c, (4.0, 13.4, 12.0, 15.0), 0.8))
    c.fill(union(screen, stand))
    dots = union(rr(c, (2.6, 3.4, 5.0, 5.8), 0.6), rr(c, (2.6, 7.0, 5.0, 9.4), 0.6), rr(c, (6.2, 3.4, 8.6, 5.8), 0.6))
    c.cream(dots)
    return c.done()


def downloads(size):
    c = Canvas(size)
    arrow = union(rr(c, (6.3, 0.8, 9.7, 6.6), 0.8), poly(c, [(2.8, 5.8), (13.2, 5.8), (8.0, 11.0)]))
    tray = poly(c, [(0.8, 9.6), (3.4, 9.6), (3.4, 12.6), (12.6, 12.6), (12.6, 9.6), (15.2, 9.6), (15.2, 15.2), (0.8, 15.2)])
    c.fill(union(arrow, tray))
    return c.done()


def documents(size):
    c = Canvas(size)
    page = poly(c, [(2.6, 0.8), (10.0, 0.8), (13.6, 4.4), (13.6, 15.2), (2.6, 15.2)])
    c.fill(page, color=CREAM, gloss=False)
    fold = poly(c, [(10.0, 0.8), (10.0, 4.4), (13.6, 4.4)])
    lines = union(rr(c, (4.8, 6.6, 11.6, 8.0), 0.5), rr(c, (4.8, 9.2, 11.6, 10.6), 0.5), rr(c, (4.8, 11.8, 9.4, 13.2), 0.5))
    c.fill(union(fold, lines), edge=False, gloss=False)
    return c.done()


def pictures(size):
    c = Canvas(size)
    frame = rr(c, (0.8, 2.2, 15.2, 13.8), 1.8)
    c.fill(frame)
    c.cream(union(poly(c, [(2.4, 12.2), (6.6, 6.8), (9.6, 10.4), (11.2, 8.8), (13.6, 12.2)]), ellipse(c, (10.2, 4.0, 12.8, 6.6))))
    return c.done()


def music(size):
    c = Canvas(size)
    heads = union(ellipse(c, (0.8, 10.0, 6.4, 14.6)), ellipse(c, (8.6, 8.4, 14.2, 13.0)))
    stems = union(poly(c, [(4.8, 3.6), (6.4, 3.2), (6.4, 12.4), (4.8, 12.4)]), poly(c, [(12.6, 1.6), (14.2, 1.2), (14.2, 10.8), (12.6, 10.8)]))
    beam = poly(c, [(4.8, 3.6), (14.2, 1.0), (14.2, 3.9), (4.8, 6.5)])
    c.fill(union(heads, stems, beam))
    return c.done()


def videos(size):
    c = Canvas(size)
    body = rr(c, (0.8, 3.6, 11.0, 12.6), 1.8)
    lens = poly(c, [(10.4, 6.8), (15.2, 3.8), (15.2, 12.4), (10.4, 9.4)])
    c.fill(union(body, lens))
    c.cream(ellipse(c, (2.8, 5.4, 4.8, 7.4)))
    return c.done()


GLYPHS = {
    'Home': home, 'Gallery': gallery, 'Desktop': desktop,
    'Folder-Downloads': downloads, 'Folder-Documents': documents, 'Folder-Pictures': pictures,
    'Folder-Music': music, 'Folder-Video': videos,
}
GLYPH_MAX = 32   # do ove velicine koristi siluete
