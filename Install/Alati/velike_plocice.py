"""Velike (512 px) ikonice Home i Gallery u istom stilu kao postojece plocice (User, Pictures...).

Koristi plocicu iz User.png (bordo pozadina, roze okvir, luk, senka), brise njen glif i crta
novi krem glif sa 4x nadsemplovanjem. Rezultat ide u Icons/PNG kao master.
"""
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

BG = (104, 5, 31, 255)
GLYPH = (255, 250, 247, 255)
OUTLINE = (214, 190, 192, 255)
X = 4  # nadsemplovanje


def blank_tile(png_dir):
    tile = Image.open(os.path.join(png_dir, 'User.png')).convert('RGBA')
    ImageDraw.Draw(tile).rectangle((140, 128, 372, 362), fill=BG)
    return tile


def _paint(tile, mask_big):
    """mask_big: L maska glifa u 4x velicini."""
    m = mask_big.resize(tile.size, Image.LANCZOS)
    edge = mask_big.filter(ImageFilter.MaxFilter(9)).resize(tile.size, Image.LANCZOS)
    o = Image.new('RGBA', tile.size, OUTLINE); o.putalpha(edge); tile.alpha_composite(o)
    g = Image.new('RGBA', tile.size, GLYPH); g.putalpha(m); tile.alpha_composite(g)
    return tile


def S(v):
    return v * X


def home(png_dir):
    tile = blank_tile(png_dir)
    m = Image.new('L', (512 * X, 512 * X), 0)
    d = ImageDraw.Draw(m)
    d.polygon([(S(256), S(132)), (S(384), S(246)), (S(350), S(246)), (S(350), S(372)), (S(162), S(372)), (S(162), S(246)), (S(128), S(246))], fill=255)
    d.rectangle((S(318), S(150), S(344), S(214)), fill=255)                    # dimnjak
    door = Image.new('L', m.size, 0)
    ImageDraw.Draw(door).rounded_rectangle((S(228), S(286), S(284), S(380)), radius=S(24), fill=255)
    m = ImageChops.subtract(m, door)
    return _paint(tile, m)


def gallery(png_dir):
    tile = blank_tile(png_dir)
    big = (512 * X, 512 * X)
    stroke = S(20)
    front_box = (S(140), S(196), S(332), S(352))
    back_box = (S(186), S(150), S(378), S(306))
    front = Image.new('L', big, 0)
    ImageDraw.Draw(front).rounded_rectangle(front_box, radius=S(22), outline=255, width=stroke)
    inner = Image.new('L', big, 0)
    d = ImageDraw.Draw(inner)
    d.polygon([(S(166), S(328)), (S(214), S(262)), (S(246), S(300)), (S(270), S(276)), (S(308), S(328))], fill=255)
    d.ellipse((S(262), S(222), S(296), S(256)), fill=255)
    back = Image.new('L', big, 0)
    ImageDraw.Draw(back).rounded_rectangle(back_box, radius=S(22), outline=255, width=stroke)
    cut = Image.new('L', big, 0)
    ImageDraw.Draw(cut).rounded_rectangle((front_box[0] - S(16), front_box[1] - S(16), front_box[2] + S(16), front_box[3] + S(16)), radius=S(30), fill=255)
    back = ImageChops.subtract(back, cut)
    m = ImageChops.lighter(ImageChops.lighter(front, inner), back)
    return _paint(tile, m)


def build(png_dir):
    home(png_dir).save(os.path.join(png_dir, 'Home.png'))
    gallery(png_dir).save(os.path.join(png_dir, 'Gallery.png'))
