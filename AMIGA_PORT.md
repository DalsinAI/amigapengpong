Peng-Pong 0.3 for GFOS and AmigaOS 3.x
======================================

Peng-Pong is Pong with a penguin on its title by Adam Weiss and David
Tansey (2001): two players at one keyboard, or one against the computer,
with menus for the players' names and the computer's difficulty.

This port runs it on ACGame, the AmiCradle game layer, through acsdl12
(SDL 1.2 on ACGame): an 800 x 600 screen in 256 colours, RTG or AGA.

Needs
-----

- A 68040 or 68060 with an FPU.
- AmigaOS 3.x with an RTG card or an AGA chipset (GFOS on AmiCradle has
  both).
- Under 700 KB of disk.

Its own acgame.library is in the drawer's Libs/, so nothing else is
needed.

Install
-------

Double-click Install-PengPong (it asks where; Work:Games by default), or
drag the PengPong drawer anywhere. On GFOS: GFOpenUpTool INSTALL
Parts/PengPong.

Playing
-------

- Any key on the title: start.
- Q and A: the left player up and down; O and L: the right player, when
  the computer is not playing it (it is, at first).
- Esc: the menu (with the mouse): players' names, the computer player and
  its difficulty, back to the game, quit.
- Right Amiga + Q: quit; Right Amiga + P: pause; Right Amiga + M: grab the
  mouse (ACGame's own keys, as in every ACGame game).

The settings are kept in the drawer's User/config_file; updates keep it.

Port notes
----------

- All pictures share one 256-colour palette (tools/pengpong8.py): the
  fonts and sprites exactly, the title picture dithered.
- Two fixes to upstream: the window title buffer was one byte short, and
  typing a name copied a string onto itself.

Designed, tested and delivered by The AmiCradle Team.
