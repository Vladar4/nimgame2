Nimgame 2
=========

A simple 2D game engine for Nim language.


Status: v0.5 alpha
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

### v0.5 alpha (2017-08-01)
* changed physics and logic systems
* platformer physics
* CoordInt type
* now collider module is autmatically included into the entity module
* group collider
* huge Tilemap optimizations
* various utility Tilemap procedures
* TextureGraphic.drawTiled
* GUI:
  * GUIProgressBar
  * widget actions
* various minor changes and upgrades
* Nim v0.17.0 transition
* documentation, snippets, and demos update
* [second tutorial](https://vladar4.github.io/nimgame2/tut102_platformer.html)

### v0.4 alpha (2017-05-04)
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


### v0.3 alpha (2017-03-10)
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

### v0.2 alpha (2017-01-31)
* collider optimizations
* music playlists
* random procedures
* tilemaps
* tweens
* emitters
* various fixes
* 4 new demos

### v0.1 alpha (2017-01-16)
* base scene/entity system
* assets manager
* basic sound and music
* colliders (point, box, circle, line, and polygon)
* fonts (bitmap and TrueType) and text output
* keyboard and mouse input
* vector drawing procedures

