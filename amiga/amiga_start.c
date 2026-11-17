/* The Amiga port's start: the stack, the version string and PROGDIR:User,
 * where Peng-Pong keeps its settings (config_file: the players' names, the
 * computer player, its difficulty), made before main(). Install-PengPong
 * and GFOpenUp keep User when they update the game.
 * Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like Peng-Pong. */
#include <sys/stat.h>

/* A Shell gives 4 KB of stack; the game and acsdl12 want more. libnix's
 * startup sets this much up. */
unsigned long __stack = 64 * 1024;
static const char version[] __attribute__((used)) =
    "$VER: PengPong 0.3 (17.11.2026)";

static void __attribute__((constructor)) amiga_user_drawer(void)
{
	struct stat st;

	if (stat("PROGDIR:User", &st) != 0)
		mkdir("PROGDIR:User", 0755);
}
