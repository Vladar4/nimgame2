Nimgame 2
=========

A simple 2D game engine for Nim language.


Status: v0.2 alpha
------------------


Requires:
---------

* [sdl2_nim](https://github.com/Vladar4/sdl2_nim) package.
* Runtime libraries for:
  * SDL 2.0.5
  * SDL_gfx 1.0.1
  * SDL_image 2.0.1
  * SDL_mixer 2.0.1
  * SDL_ttf 2.0.14


Installation through [Nimble](https://github.com/nim-lang/nimble):
------------------------------------------------------------------
`nimble install nimgame2@#head`


Recommended compilation flags:
------------------------------
`-d:release --opt:speed`


Links:
------

* [demos](demos)
* [ng2planetoids](https://github.com/Vladar4/ng2planetoids) - first demo game.


Changelog:
----------

### v0.2 alpha
* collider optimizations
* music playlists
* random procedures
* tilemaps
* tweens
* emitters
* various fixes
* 4 new demos

### v0.1 alpha
* base scene/entity system
* assets manager
* basic sound and music
* colliders (point, box, circle, line, and polygon)
* fonts (bitmap and TrueType) and text output
* keyboard and mouse input
* vector drawing procedures

