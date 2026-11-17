#!/usr/bin/env python3
"""amiga/data against upstream's pictures: one 256-colour palette in every
PNG; the fonts' marks magenta (255,0,255) exactly, their see-through pixels
at 255 (their bottom-left pixel, SFont's key), their letters exactly
upstream's laid over black; the ball and the paddle exactly upstream's;
the logo within a mean error of 12 a channel of logo.jpg.

    python3 tests/host/check_pictures.py UPSTREAM amiga/data

Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like Peng-Pong.
"""
import os
import sys

from PIL import Image


def px(im, mode):
    raw = im.convert(mode).tobytes()
    n = len(mode)
    return [tuple(raw[k:k + n]) for k in range(0, len(raw), n)]


def main():
    up, data = sys.argv[1], sys.argv[2]
    pal = None
    for f in ("24P_Copperplate_Blue.png", "red.png", "ball.png", "paddle.png", "logo.png"):
        im = Image.open(os.path.join(data, f))
        if im.mode != "P":
            raise SystemExit("FAIL: %s is not paletted" % f)
        if pal is None:
            pal = im.getpalette()
        elif im.getpalette() != pal:
            raise SystemExit("FAIL: %s has another palette" % f)
    for f in ("24P_Copperplate_Blue.png", "red.png"):
        a = px(Image.open(os.path.join(up, f)), "RGBA")
        im = Image.open(os.path.join(data, f))
        idx = list(im.tobytes())
        rgb = px(im, "RGB")
        if idx[(im.size[1] - 1) * im.size[0]] != 255:
            raise SystemExit("FAIL: %s: bottom-left pixel is not the key" % f)
        for p, i, c in zip(a, idx, rgb):
            if p[3] == 0:
                ok = i == 255
            elif p[:3] == (255, 0, 255):
                ok = c == (255, 0, 255)
            else:
                ok = c == tuple((v * p[3] + 127) // 255 for v in p[:3]) and i != 255
            if not ok:
                raise SystemExit("FAIL: %s: pixel %r became %d %r" % (f, p, i, c))
    for src, dst in (("ball.tga", "ball.png"), ("paddle.tga", "paddle.png")):
        if px(Image.open(os.path.join(up, src)), "RGB") != px(Image.open(os.path.join(data, dst)), "RGB"):
            raise SystemExit("FAIL: %s differs from %s" % (dst, src))
    a = Image.open(os.path.join(up, "logo.jpg")).convert("RGB").tobytes()
    b = Image.open(os.path.join(data, "logo.png")).convert("RGB").tobytes()
    err = sum(abs(x - y) for x, y in zip(a, b)) / len(a)
    if err > 12:
        raise SystemExit("FAIL: logo.png mean error %.2f" % err)
    print("ok: amiga/data: one palette; fonts, ball and paddle exact; logo mean error %.2f" % err)


if __name__ == "__main__":
    main()
