# Peng-Pong for GFOS and AmigaOS 3.x

The AmiCradle port of Peng-Pong 0.3, Pong for two at one keyboard or
against the computer, by Adam Weiss and David Tansey (GPL-2.0-or-later).
It runs on ACGame through acsdl12, our SDL 1.2: an 800 x 600 screen in
256 colours on RTG or AGA, on a 68040 with an FPU.

Upstream is never kept here: `package/build-amiga.sh` fetches the release
tarball `package/pengpong.lock` names, checks its sha256 and applies
`amiga/patches`.

| Path | What |
| --- | --- |
| `amiga/patches/` | the patch to upstream: an 8-bit screen in the pictures' palette, PNGs from `PROGDIR:Data/`, settings in `PROGDIR:User/`, standard C++ streams, two buffer fixes |
| `amiga/data/` | upstream's pictures in one 256-colour palette, made by `tools/pengpong8.py` |
| `amiga/amiga_start.c` | stack, `$VER`, makes `PROGDIR:User` |
| `amiga/Makefile.amigaos` | the build on the os32-gcc16-open6 stove |
| `amiga/icons/`, `amiga/Install-PengPong` | GlowIcons and the Installer script (amicradle `scripts/ports`) |
| `package/build-amiga.sh` | Cradle's `stove_build` (target `package`): the LHA archive and the GFOpenUp part `Parts/PengPong` |
| `tests/host/test_all.sh` | host tests: tarball checksum, patches, pictures, and the game built on acsdl12 and played from a script |

Player notes: [AMIGA_PORT.md](AMIGA_PORT.md). Licences:
[amiga/Licences.txt](amiga/Licences.txt).

Designed, tested and delivered by The AmiCradle Team.
