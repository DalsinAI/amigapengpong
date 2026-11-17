#!/bin/sh
# Host tests (Linux, gcc/g++, zlib's headers, Pillow):
#  1. upstream's tarball matches the lock's sha256; amiga/patches apply;
#  2. amiga/data: check_pictures.py (one palette, fonts, ball and paddle
#     exact, the logo close), and tools/pengpong8.py makes the same files
#     again, byte for byte;
#  3. the game built with the host's compiler (-Wall -Werror) on acsdl12
#     and ACGame at the locked commits (all of acsdl12's own code, as on the
#     Amiga) with tests/host/acgame_host.c for ACGame's screen and keyboard,
#     and played from a script: the logo, a key, the game on an 800 x 600
#     screen with both paddles and the scores, Q moves the left paddle up,
#     Right Amiga + Q ends it and the settings land in PROGDIR:User.
# ACSDL (a gameports/acsdl12) and ACGAME (DalsinAI/acgame) override the
# fetches. Frames: $T/shot-*.ppm.
# Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like Peng-Pong.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
. "$ROOT/package/pengpong.lock"
T=${WORK:-"${TMPDIR:-/tmp}/amigapengpong-test"}
mkdir -p "$T"
T=$(CDPATH= cd -- "$T" && pwd)
cd "$ROOT"
ok() { echo "ok: $*"; }
fetch() {   # fetch DIR URL COMMIT
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "$1"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
    fi
    git -C "$1" checkout -q -- . && git -C "$1" clean -qfdx
}

# 1. upstream + patches
TAR="$T/pengpong-$PENGPONG_VERSION.tar.gz"
[ "$(sha256sum "$TAR" 2>/dev/null | cut -d' ' -f1)" = "$PENGPONG_SHA256" ] ||
    curl -fsSL --retry 3 -o "$TAR" "$PENGPONG_URL"
[ "$(sha256sum "$TAR" | cut -d' ' -f1)" = "$PENGPONG_SHA256" ] || { echo "FAIL: upstream tarball sha256"; exit 1; }
rm -rf "$T/up" "$T/orig"; mkdir -p "$T/up" "$T/orig"; tar xzf "$TAR" -C "$T/up"; tar xzf "$TAR" -C "$T/orig"
UP="$T/up"
for p in amiga/patches/*.patch; do patch -s -p1 -d "$UP" < "$p"; done
ok "upstream tarball checks out; patches apply"

# 2. the pictures
python3 tests/host/check_pictures.py "$T/orig" amiga/data
rm -rf "$T/data8"; python3 tools/pengpong8.py "$T/orig" "$T/data8" > /dev/null
diff -r amiga/data "$T/data8/data" > /dev/null || { echo "FAIL: tools/pengpong8.py makes other pictures than amiga/data"; exit 1; }
ok "tools/pengpong8.py makes amiga/data again, byte for byte"

# 3. built on acsdl12 and played
if [ -z "${ACSDL:-}" ]; then
    G="$T/guest"
    if [ "$(git -C "$G" rev-parse HEAD 2>/dev/null)" != "$GUEST_REF" ]; then
        rm -rf "$G"; git init -q "$G"
        git -C "$G" sparse-checkout set gameports/acsdl12
        git -C "$G" fetch -q --depth 1 --filter=blob:none https://github.com/DalsinAI/amicradle-guest "$GUEST_REF"
        git -C "$G" checkout -q FETCH_HEAD
    fi
    ACSDL="$G/gameports/acsdl12"
fi
if [ -z "${ACGAME:-}" ]; then
    fetch "$T/acgame" https://github.com/DalsinAI/acgame "$ACGAME_REF"
    ACGAME="$T/acgame"
fi
B="$T/build"; rm -rf "$B"; mkdir -p "$B"
FL="-std=gnu++98 -O1 -Wall -Werror -Wno-write-strings -Wno-unused-variable -Wno-unused-but-set-variable \
    -Wno-misleading-indentation -Wno-format-overflow -Wno-parentheses -Wno-sign-compare -D__amigaos__ \
    -I$ACSDL/include/SDL -I$ACGAME/include"
for f in pengpong link2; do g++ $FL -c "$UP/$f.cpp" -o "$B/$f.o"; done
g++ -x c++ $FL -c "$UP/SFont.c" -o "$B/SFont.o"
gcc -O1 -Wall -Wextra -Werror -c amiga/amiga_start.c -o "$B/amiga_start.o"
for f in "$ACSDL"/src/*.c; do
    gcc -std=gnu99 -O1 -w -I"$ACSDL/include/SDL" -I"$ACSDL/src" -I"$ACGAME/include" -c "$f" -o "$B/acsdl_$(basename "$f" .c).o"
done
gcc -O1 -Wall -Wextra -Werror -I"$ACGAME/include" -c tests/host/acgame_host.c -o "$B/acgame_host.o"
g++ -o "$B/pengpong" "$B"/*.o -lz -lpthread -lm
ok "game builds on the host (-Wall -Werror) on acsdl12 $GUEST_REF and ACGame $ACGAME_REF"

# On the host, -D__amigaos__ makes PROGDIR:Data and PROGDIR:User drawers of
# those names in the current one.
P="$T/play"; rm -rf "$P"; mkdir -p "$P/PROGDIR:Data"; cp amiga/data/*.png "$P/PROGDIR:Data/"
cat > "$T/play.txt" <<EOS
2000 tap 40
2600 shot $T/shot-0.ppm
2700 down 10
3100 up 10
3200 shot $T/shot-up.ppm
3300 quit
EOS
(cd "$P" && ACG_SCRIPT="$T/play.txt" ACG_LOG="$T/play.frames" timeout -s KILL 30 "$B/pengpong") > "$T/play.out" 2>&1 ||
    { echo "FAIL: the game did not end on Right Amiga + Q"; tail "$T/play.out"; exit 1; }
for s in 0 up; do
    [ "$(head -c 15 "$T/shot-$s.ppm" | tr '\n' ' ')" = "P6 800 600 255 " ] || { echo "FAIL: no 800 x 600 frame $s"; exit 1; }
done
grep -q '^have_ai:1$' "$P/PROGDIR:User/config_file" || { echo "FAIL: no settings in PROGDIR:User/config_file"; exit 1; }
python3 - "$T" <<'EOP'
import sys
t = sys.argv[1]
frames = [l.split() for l in open(t + "/play.frames")]
before = {h for n, ms, h in frames if int(ms) < 2000}
assert len(before) >= 2, "no logo before the key: %r" % before
def load(n):
    d = open("%s/shot-%s.ppm" % (t, n), "rb").read()
    return d[len(b"P6 800 600 255\n"):]
def paddle_y(px, x0):
    rows = [y for y in range(600) if px[(y * 800 + x0 + 8) * 3] > 150]
    return (min(rows) + max(rows)) // 2 if rows else None
s0, su = load("0"), load("up")
top = [s0[(y * 800 + x) * 3 + 2] for y in range(4, 26) for x in range(0, 300)]
assert max(top) > 200, "no blue score line at the top"
y0, yu = paddle_y(s0, 16), paddle_y(su, 16)
assert None not in (y0, yu), "no left paddle"
assert yu < y0 - 50, "Q did not move the left paddle up (%d -> %d)" % (y0, yu)
print("ok: played: logo, scores, left paddle %d -> %d on Q; %d frames" % (y0, yu, len(frames)))
EOP
ok "settings written to PROGDIR:User/config_file"
echo "all host tests passed"
