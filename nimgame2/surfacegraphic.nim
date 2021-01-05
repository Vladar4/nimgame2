# nimgame2/surfacegraphic.nim
# Copyright (c) 2016-2021 Vladimir Arabadzhi (Vladar)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# vladar4@gmail.com
# https://github.com/Vladar4

import
  sdl2/sdl,
  texturegraphic, palette, settings, types, utils


type
  SurfaceGraphic* = ref object of TextureGraphic ## \
    ##  Same as TextureGraphic but keeps the Surface object,
    ##  allowing easy per-pixel operations.
    # Private
    fSurface: sdl.Surface


#================#
# SurfaceGraphic #
#================#

proc freeSurface*(graphic: SurfaceGraphic) =
  if not (graphic.fSurface == nil):
    graphic.fSurface.freeSurface()
    graphic.fSurface = nil


proc free*(graphic: SurfaceGraphic) =
  TextureGraphic(graphic).free()
  graphic.freeSurface()


proc initSurfaceGraphic*(graphic: SurfaceGraphic) =
  graphic.initTextureGraphic()
  graphic.fSurface = nil


proc updateSurface*(
    graphic: SurfaceGraphic, freeCurrent: bool = true): bool =
  ##  Update surface and create a new texture from it.
  ##
  ##  ``Note:`` if the surface is `nil`, will free the texture as well.
  ##
  ##  ``assignSurface()``
  ##  or any other proc that changes the surface, calls this on its own.
  ##
  ##  ``Return`` `true` on success (or if the surface is absent),
  ##  or `false` otherwise.
  ##
  if graphic.fSurface == nil:
    graphic.freeTexture()
    return graphic.updateTexture()
  # if surface is not nil
  result = graphic.assignTexture(
    renderer.createTextureFromSurface(graphic.fSurface), freeCurrent)
  if graphic.texture == nil: # check if createTextureFromSurface was successful
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create texture from surface: %s",
                    sdl.getError)
    return false
  # otherwise return result


proc load*(
    graphic: SurfaceGraphic, file: string): bool =
  ##  Load surface from ``file``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  graphic.free()
  # load surface
  graphic.fSurface = loadSurface(file)
  return not(graphic.fSurface == nil) and graphic.updateSurface()


proc load*(
    graphic: SurfaceGraphic, rw: ptr RWops, freeSrc: bool = true): bool =
  ##  Load surface from ``src`` ``RWops``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  graphic.free()
  # load surface
  graphic.fSurface = loadSurface(rw, freeSrc)
  return not(graphic.fSurface == nil) and graphic.updateSurface()


proc assignSurface*(
    graphic: SurfaceGraphic, surface: Surface, freeCurrent: bool = true): bool =
  ##  Assign already created ``surface`` and run ``updateSurface()`` afterwards.
  ##
  ##  ``freeCurrent`` Free the currently assigned surface ``AND`` texture
  ##  (as it updates the texture from the new surface).
  ##  Set to `false` if either is used by other objects.
  ##
  ##  ``ATTENTION!`` The ``surface`` will be destroyed on ``free()``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  if not(graphic.fSurface == nil) and freeCurrent:
    graphic.freeSurface()
  graphic.fSurface = surface
  return graphic.updateSurface()


proc surface*(graphic: SurfaceGraphic): sdl.Surface {.inline.} =
  ##  Direct access to the ``graphic``'s surface. Be careful.
  ##
  graphic.fSurface


proc newSurfaceGraphic*(): SurfaceGraphic =
  new result, free
  result.initSurfaceGraphic()


proc newSurfaceGraphic*(file: string): SurfaceGraphic =
  result = newSurfaceGraphic()
  discard result.load(file)


proc newSurfaceGraphic*(src: ptr RWops, freeSrc: bool = true): SurfaceGraphic =
  result = newSurfaceGraphic()
  discard result.load(src, freeSrc)


proc newSurfaceGraphic*(surface: Surface): SurfaceGraphic =
  result = newSurfaceGraphic()
  discard result.assignSurface(surface)


method draw*(graphic: SurfaceGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  drawTextureGraphic(graphic, pos, angle, scale, center, flip, region)


# Palette

proc palette*(graphic: SurfaceGraphic): PalettePtr {.inline.} =
  graphic.fSurface.format.palette


proc assignPalette*(graphic: SurfaceGraphic, palette: PalettePtr): bool =
  if not(graphic.fSurface.setSurfacePalette(palette) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set the new palette: %s",
                    sdl.getError())
    return false
  return graphic.updateSurface()

