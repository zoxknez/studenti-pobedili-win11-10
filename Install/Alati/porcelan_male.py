"""Opticki podesene Porcelan ikonice za male okvire (16-48 px).

Isti jezik oblika kao veliki masteri: porcelan, grafit i bordo akcenat.
Crtezi koriste celu mrezu 16 x 16; bez mekih senki i minijaturnih znacki.
Vece ICO velicine i PNG masteri ostaju izvor za ilustrativni prikaz.
"""
import math

from PIL import Image, ImageDraw

WHITE = '#faf7f4'
EDGE = '#61545b'
INK = '#342b32'
RED = '#b12e4d'
PALE = '#e4dadb'


class Canvas:
    def __init__(self, size):
        self.size = size
        self.k = size * 12 / 16
        self.image = Image.new('RGBA', (size * 12, size * 12))
        self.draw = ImageDraw.Draw(self.image)

    def points(self, points):
        return [(round(x * self.k), round(y * self.k)) for x, y in points]

    def box(self, box):
        return tuple(round(v * self.k) for v in box)

    def line(self, points, fill=INK, width=1.3):
        p = self.points(points)
        w = max(1, round(width * self.k))
        self.draw.line(p, fill=fill, width=w, joint='curve')
        r = w / 2
        for x, y in (p[0], p[-1]):
            self.draw.ellipse((round(x-r), round(y-r), round(x+r), round(y+r)), fill=fill)

    def rect(self, box, fill=WHITE, radius=1, outline=EDGE, width=.8):
        self.draw.rounded_rectangle(self.box(box), radius=round(radius*self.k),
                                    fill=fill, outline=outline, width=max(1, round(width*self.k)))

    def ellipse(self, box, fill=WHITE, outline=EDGE, width=.8):
        self.draw.ellipse(self.box(box), fill=fill, outline=outline, width=max(1, round(width*self.k)))

    def poly(self, points, fill=WHITE, outline=EDGE, width=.8):
        self.draw.polygon(self.points(points), fill=fill)
        if outline:
            self.line(points + [points[0]], outline, width)

    def done(self):
        return self.image.resize((self.size, self.size), Image.Resampling.LANCZOS)


def folder(c, symbol='3'):
    c.rect((.5, 1.7, 7.7, 6.3), PALE, radius=.9)
    c.rect((.5, 4, 15.5, 14.7), WHITE, radius=1.2)
    if symbol == '3':
        c.line([(5.2, 6.5), (8.9, 6.5), (10, 7.4), (10, 8.2), (8.2, 9.2),
                (10, 10.2), (10, 11.5), (8.9, 12.4), (5.2, 12.4)], RED, 1.7)
    elif symbol == 'code':
        c.line([(6, 7), (3.6, 9.4), (6, 11.8)], RED, 1.5)
        c.line([(10, 7), (12.4, 9.4), (10, 11.8)], INK, 1.5)


def photo(c, gallery=False):
    if gallery:
        c.rect((3.8, .6, 15.4, 11.6), RED, radius=1.1)
        box = (.5, 4, 12.7, 15.2)
        c.rect(box, radius=1.1)
        c.poly([(2, 13.5), (5.1, 8.7), (7.4, 11.5), (9, 10), (11.1, 13.5)], INK, None)
        c.ellipse((8.1, 5.8, 10.8, 8.5), RED, None)
    else:
        c.rect((.5, 1.5, 15.5, 14.5), radius=1.1)
        c.poly([(2, 12.8), (6.3, 6.5), (9.5, 10.1), (11.2, 8.6), (14, 12.8)], INK, None)
        c.ellipse((10.1, 3.3, 13.3, 6.5), RED, None)


def monitor(c, tower=False):
    right = 11.3 if tower else 15.5
    c.rect((.5, 1, right, 11.6), radius=1.1)
    c.rect((2, 2.5, right-1.5, 8.9), PALE, radius=.3, outline=None)
    c.line([(2, 9.8), (right-1.5, 9.8)], RED, 1)
    center = (right+.5)/2
    c.line([(center, 11.8), (center, 14.7)], INK, 1.5)
    c.line([(center-3, 14.7), (center+3, 14.7)], WHITE, 1.5)
    if tower:
        c.rect((12.4, 4.8, 15.5, 14.9), WHITE, radius=.5)
        c.line([(13.4, 6.4), (14.5, 6.4)], INK, .7)
        c.ellipse((13.4, 11.8, 14.6, 13), RED, None)


def document(c):
    c.poly([(2, .5), (10.1, .5), (14, 4.4), (14, 15.5), (2, 15.5)])
    c.poly([(10.1, .9), (10.1, 4.4), (13.7, 4.4)], RED, None)
    for y, end in [(6.9, 11.6), (9.6, 11.6), (12.3, 9.4)]:
        c.line([(4.4, y), (end, y)], INK, 1.3)


def download(c):
    c.poly([(.5, 9.5), (3.1, 9.5), (3.1, 12.8), (12.9, 12.8),
            (12.9, 9.5), (15.5, 9.5), (15.5, 15.3), (.5, 15.3)])
    c.line([(8, 1), (8, 9.9)], WHITE, 3.6)
    c.line([(8, .8), (8, 8.6)], RED, 2.1)
    c.poly([(2.8, 6.9), (13.2, 6.9), (8, 12)], RED, None)


def music(c):
    c.poly([(5.2, 3.3), (14.7, .7), (14.7, 11.3), (12.3, 11.3),
            (12.3, 5.4), (7.4, 6.8), (7.4, 13.3), (5.2, 13.3)])
    c.ellipse((.4, 10, 7.4, 15.4))
    c.ellipse((8, 8.1, 15, 13.5))
    c.line([(6.5, 4.3), (13.4, 2.5)], RED, 1.5)


def video(c):
    c.rect((.5, 2.5, 11, 13.5), radius=1.6)
    c.poly([(10.8, 6), (15.5, 3.3), (15.5, 12.7), (10.8, 10)])
    c.ellipse((2.4, 4.4, 5.3, 7.3), RED, None)
    c.line([(3, 11), (7, 11)], INK, 1)


def people(c, team=False):
    if team:
        c.ellipse((.7, 1.8, 6, 7.1), PALE)
        c.ellipse((10, 1.8, 15.3, 7.1), PALE)
        c.rect((.5, 8, 6.3, 14.8), PALE, radius=2.5)
        c.rect((9.7, 8, 15.5, 14.8), PALE, radius=2.5)
    c.ellipse((4.3, .5 if not team else 3, 11.7, 7.9 if not team else 10.4))
    c.rect((2 if not team else 3.3, 9 if not team else 10.7,
            14 if not team else 12.7, 15.5), WHITE, radius=2.7)
    c.line([(6.1, 11.4 if not team else 12.3), (9.9, 11.4 if not team else 12.3)], RED, 1.6)


def render(name, size):
    c = Canvas(size)
    kind = {'Explorer': 'Folder-3', 'Documents': 'Folder-Documents',
            'Downloads': 'Folder-Downloads', 'Pictures': 'Folder-Pictures',
            'Music': 'Folder-Music', 'Video': 'Folder-Video', 'Monitor': 'Desktop'}.get(name, name)
    if kind == 'Home':
        c.poly([(2.3, 7), (8, 2), (13.7, 7), (13.7, 15.4), (2.3, 15.4)])
        c.line([(.8, 7.1), (8, .8), (15.2, 7.1)], RED, 1.5)
        c.rect((6.1, 9.4, 9.9, 15.4), INK, radius=.5, outline=None)
    elif kind == 'Gallery':
        photo(c, True)
    elif kind == 'Desktop':
        monitor(c)
    elif kind == 'ThisPC':
        monitor(c, True)
    elif kind == 'Folder-Documents':
        document(c)
    elif kind == 'Folder-Downloads':
        download(c)
    elif kind == 'Folder-Pictures':
        photo(c)
    elif kind == 'Folder-Music':
        music(c)
    elif kind == 'Folder-Video':
        video(c)
    elif kind in ('Folder-3', 'Folder-Projects'):
        folder(c, 'code' if kind == 'Folder-Projects' else '3')
    elif kind == 'Folder-Education':
        c.poly([(3.2, 8), (12.8, 8), (12.8, 12.2), (8, 14.2), (3.2, 12.2)])
        c.poly([(.6, 5.1), (8, 1.1), (15.4, 5.1), (8, 9.1)])
        c.line([(14.3, 6.3), (14.3, 13.9)], RED, 1.5)
    elif kind == 'Folder-Favorites':
        c.poly([(8, .5), (10.2, 5.4), (15.5, 6), (11.5, 9.8),
                (12.5, 15.1), (8, 12.5), (3.5, 15.1), (4.5, 9.8), (.5, 6), (5.8, 5.4)])
        c.ellipse((6.3, 6.5, 9.7, 9.9), RED, None)
    elif kind in ('Folder-Team', 'User'):
        people(c, kind == 'Folder-Team')
    elif kind == 'Drive':
        c.poly([(2.6, 1.3), (13.4, 1.3), (15.5, 10), (.5, 10)], PALE)
        c.rect((.5, 9.1, 15.5, 14.7), radius=1)
        c.line([(2.8, 11.8), (9.4, 11.8)], INK, 1.1)
        c.ellipse((12, 10.7, 14.1, 12.8), RED, None)
    elif kind == 'Network':
        c.line([(8, 5.2), (8, 9.4), (3.2, 9.4), (3.2, 12)], RED, 1.7)
        c.line([(8, 9.4), (12.8, 9.4), (12.8, 12)], RED, 1.7)
        for box in [(4.8, .6, 11.2, 6.4), (.5, 10.8, 6.7, 15.4), (9.3, 10.8, 15.5, 15.4)]:
            c.rect(box, radius=.5)
    elif kind.startswith('RecycleBin-'):
        if kind.endswith('Full'):
            c.poly([(3.2, 3.9), (2.8, .8), (7.1, 1.5), (7.8, 5)], PALE)
            c.poly([(8, 4), (9.3, .6), (13, 2.2), (12, 5)], WHITE)
        c.poly([(2.6, 4.1), (13.4, 4.1), (12.5, 15.4), (3.5, 15.4)])
        c.line([(1.2, 3.8), (14.8, 3.8)], WHITE, 1.9)
        if kind.endswith('Empty'):
            c.line([(5.6, 1.3), (10.4, 1.3)], RED, 1.5)
        for x in (6, 10):
            c.line([(x, 7), (x, 12.4)], RED, 1.3)
    elif kind == 'Printer':
        c.rect((3, .6, 13, 7), radius=.4)
        c.line([(5, 3), (11, 3)], INK, 1)
        c.rect((.5, 5.7, 15.5, 12.6), radius=1.1)
        c.ellipse((12, 7.2, 13.7, 8.9), RED, None)
        c.rect((3, 10.2, 13, 15.4), radius=.3)
        c.line([(5.2, 12.5), (10.8, 12.5)], INK, 1)
    elif kind == 'Security':
        c.poly([(8, .5), (14.9, 3.2), (13.9, 10.3), (11.5, 13.5), (8, 15.5),
                (4.5, 13.5), (2.1, 10.3), (1.1, 3.2)])
        c.line([(4.8, 7.9), (7.1, 10.5), (11.4, 5.9)], RED, 1.9)
    elif kind == 'Settings':
        points = []
        for i in range(32):
            a = math.pi*i/16
            r = 7.4 if i % 4 in (0, 3) else 5.7
            points.append((8+r*math.cos(a), 8+r*math.sin(a)))
        c.poly(points)
        c.ellipse((4.8, 4.8, 11.2, 11.2), RED, None)
        c.ellipse((6.4, 6.4, 9.6, 9.6), WHITE, None)
    elif kind == 'Browser':
        c.ellipse((.5, .5, 15.5, 15.5))
        c.line([(.9, 8), (15.1, 8)], RED, 1.3)
        c.line([(8, .9), (5.2, 4), (4.4, 8), (5.2, 12), (8, 15.1)], INK, 1.1)
        c.line([(8, .9), (10.8, 4), (11.6, 8), (10.8, 12), (8, 15.1)], INK, 1.1)
    elif kind == 'Inbox':
        c.poly([(2, 6.4), (14, 6.4), (15.5, 14.8), (.5, 14.8)])
        c.line([(2.2, 10.3), (5.2, 10.3), (6.1, 12.2), (9.9, 12.2), (10.8, 10.3), (13.8, 10.3)], INK, 1.1)
        c.line([(8, .8), (8, 7.3)], RED, 1.8)
        c.poly([(4.6, 5.1), (11.4, 5.1), (8, 8.5)], RED, None)
    else:
        raise ValueError(f'Nedostaje mala Porcelan ikonica: {name}')
    return c.done()
