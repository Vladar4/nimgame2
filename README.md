Nimgame 2
=========

A simple 2D game engine for Nim language.


Status: v0.4 alpha
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

* [home page](https://vladar4.github.io/nimgame2/)
* [demos](demos)
* [tutorials](https://vladar4.github.io/nimgame2/tutorials)
* [documentation](https://vladar4.github.io/nimgame2/docs.html)
* [ng2planetoids](https://github.com/Vladar4/ng2planetoids) - first demo game.
* [ng2gggrotto](https://github.com/Vladar4/ng2gggrotto) - Linux Game Jam 2017 entry.


Changelog:
----------

### v0.4 alpha
* GUI:
  * RadioGroup
  * RadioButton
* IndexedImage
* PerspectiveImage
* TextureAtlas
* joysticks support
* window management procedures
* 4 new demos
* [first tutorial](https://vladar4.github.io/nimgame2/tut101_bounce.html)


### v0.3 alpha
* camera property (Scene)
* new collision procedures
* reworked input
* Mosaic
* parallax property (Entity)
* TextField
* GUI:
  * Widget
  * Button
  * TextInput
* 3 new demos
* home page, snippets, and documentation

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

