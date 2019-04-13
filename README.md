Nimgame 2
=========

A simple 2D game engine for Nim language.

For more information check [home page](https://vladar4.github.io/nimgame2/).

[Coding style guide](STYLE.md) for the contributors.

All pull requests should be done into the **devel** branch.

Status: v0.6.1 alpha
--------------------


Requires:
---------

* [sdl2_nim](https://github.com/Vladar4/sdl2_nim) package (v2.0.7.1 or newer).
* Runtime libraries for:
  * SDL 2.0.7 or newer
  * SDL_gfx 1.0.1
  * SDL_image 2.0.2
  * SDL_mixer 2.0.2
  * SDL_ttf 2.0.14
(see [SDL2 links](https://github.com/Vladar4/sdl2_nim/blob/master/LINKS.md))


Optional dependencies:
----------------------

* For plugin/mpeggraphic
  * mpg123 runtime library (dll is distributed within SDL_)
* For plugin/tar:
  * [zip](https://github.com/nim-lang/zip)
  * zlib runtime library (dll is distributed within SDL2_image builds)
* For plugin/zzip:
  * [zip](https://github.com/nim-lang/zip)
  * zlib runtime library (dll is distributed within SDL2_image builds)
  * zzip runtime library


Installation through [Nimble](https://github.com/nim-lang/nimble):
------------------------------------------------------------------

* For the Nim 0.17: `nimble install nimgame2@#head`
* For the Nim 0.18 and newer: `nimble install nimgame2@#devel`


Recommended compilation flags:
------------------------------
`--multimethods:on -d:release --opt:speed`


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

### v0.6.1 alpha (2019-06-15)
* Nim v0.20.0 transition

### v0.6 alpha (2019-01-21)
* new modules: typewriter
* new plugins: mpeggraphic (+demo22), tar, zzip
* new utils procedures: textureFormat, textureFormats, toSeq, neg, new rand procedures
* color constants
* audio: playing template
* emitter: emission areas, procedure argument for emit
* entity: animation callback, blinking, scale parameters, dim template (by [CodeDoes](https://github.com/CodeDoes))
* input: mouse wheel events (by [CodeDoes](https://github.com/CodeDoes))
* icon surface init option
* RW loading procedures
* simplified time counters
* demo23 (transform) (by [CodeDoes](https://github.com/CodeDoes))
* various minor changes and upgrades, code refactoring
* Nim v0.19.0 transition


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

