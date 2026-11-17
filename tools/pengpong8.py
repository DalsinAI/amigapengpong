#!/usr/bin/env python3
"""Peng-Pong 0.3's pictures as the Amiga port's PNGs, in one 256-colour
palette (the screen's).

    python3 tools/pengpong8.py UPSTREAM OUT

UPSTREAM is the unpacked pengpong-0.3; OUT gets data/*.png: the two
SFont fonts (24P_Copperplate_Blue.png, red.png), logo.png (logo.jpg),
ball.png and paddle.png (the TGAs).

The palette: 0 black; 1 magenta (255,0,255), SFont's character marks, exact;
2 red (255,0,0), the menu's box; then every colour of the fonts (their
alpha laid over black, as upstream draws them on its black screen), the
ball and the paddle, exactly; the rest is the logo's, by median cut, the
logo dithered onto the whole palette. 255 is black again, for the fonts'
see-through pixels: SFont keys the colour of each font's bottom-left pixel,
and a key of its own leaves the dark edges of the letters drawn.
The same input makes the same bytes.

Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like Peng-Pong.
"""
import os
import sys

from PIL import Image

FONTS = ("24P_Copperplate_Blue.png", "red.png")
SPRITES = (("ball.tga", "ball.png"), ("paddle.tga", "paddle.png"))
KEY = 255


def over_black(px):
    r, g, b, a = px
    return (r * a + 127) // 255, (g * a + 127) // 255, (b * a + 127) // 255


def rgba(im):
    raw = im.convert("RGBA").tobytes()
    return [tuple(raw[k:k + 4]) for k in range(0, len(raw), 4)]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    up, out = sys.argv[1], os.path.join(sys.argv[2], "data")
    os.makedirs(out, exist_ok=True)
    fixed = [(0, 0, 0), (255, 0, 255), (255, 0, 0)]
    seen = set(fixed)

    def add(c):
        if c not in seen:
            seen.add(c)
            fixed.append(c)

    fonts = {}
    for f in FONTS:
        im = Image.open(os.path.join(up, f))
        px = rgba(im)
        fonts[f] = (im.size, px)
        for p in px:
            if p[3] and p[:3] != (255, 0, 255):
                add(over_black(p))
    sprites = {}
    for src, dst in SPRITES:
        im = Image.open(os.path.join(up, src))
        px = rgba(im)
        sprites[dst] = (im.size, px)
        for p in px:
            add(p[:3])
    room = 255 - len(fixed)
    if room < 16:
        raise SystemExit("only %d colours left for the logo" % room)
    logo = Image.open(os.path.join(up, "logo.jpg")).convert("RGB")
    q = logo.quantize(colors=room, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    lp = q.getpalette()[:room * 3]
    palette = fixed + [tuple(lp[i:i + 3]) for i in range(0, len(lp), 3)]
    palette += [(0, 0, 0)] * (256 - len(palette))   # 255: the fonts' key
    flat = [v for c in palette for v in c]
    index = {}
    for i, c in enumerate(palette[:255]):
        index.setdefault(c, i)

    def save(name, size, idx):
        im = Image.new("P", size)
        im.putpalette(flat)
        im.putdata(idx)
        im.save(os.path.join(out, name), optimize=False, bits=8)
        print("data/" + name)

    for f in FONTS:
        size, px = fonts[f]
        idx = []
        for p in px:
            if p[3] == 0:
                idx.append(KEY)
            elif p[:3] == (255, 0, 255):
                idx.append(1)
            else:
                idx.append(index[over_black(p)])
        save(f, size, idx)
    for dst, (size, px) in sorted(sprites.items()):
        save(dst, size, [index[p[:3]] for p in px])
    pal = Image.new("P", (1, 1))
    pal.putpalette(flat[:255 * 3] + [0, 0, 0])
    l8 = logo.quantize(palette=pal, dither=Image.Dither.FLOYDSTEINBERG)
    save("logo.png", logo.size, list(l8.tobytes()))


if __name__ == "__main__":
    main()
