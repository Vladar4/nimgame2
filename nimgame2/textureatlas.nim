# nimgame2/textureatlas.nim
# Copyright (c) 2016-2017 Vladar
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
# Vladar vladar4@gmail.com

import
  math, tables,
  sdl2/sdl,
  sdl2/sdl_image as img,
  settings, texturegraphic, types, utils


export
  tables


type
  TextureAtlas* = OrderedTableRef[string, TextureGraphic]


proc free*(atlas: TextureAtlas) =
  for graphic in atlas.values:
    if not (graphic == nil):
      graphic.free()


proc generate(source: Surface, rect: Rect): TextureGraphic =
  var
    srcRect = rect
    surface: Surface = createRGBSurfaceWithFormat(
      0, rect.w, rect.h, source.format.BitsPerPixel.cint, source.format.format)
  if surface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create a surface: %s",
                    sdl.getError())
    return nil
  # blit
  if not (source.blitSurface(addr(srcRect), surface, nil) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't blit a surface: %s",
                    sdl.getError())
    surface.freeSurface()
    return nil
  # return and free
  result = newTextureGraphic()
  discard result.assignTexture(renderer.createTextureFromSurface(surface))
  surface.freeSurface()


proc load(atlas: TextureAtlas, imagefile, mapfile: string) =
  var source = load(imagefile)
  if source == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load texture atlas image %s: %s",
                    imagefile, img.getError())
    return
  for mapping in mapfile.atlasValues:
    atlas.add(mapping.name, source.generate(mapping.rect))


proc newTextureAtlas*(imagefile, mapfile: string,
                      count: int = 64): TextureAtlas =
  ##  Create a new ``TextureAtlas``.
  ##
  ##  ``imagefile`` file containging the image atlas.
  ##
  ##  ``mapfile`` CSV file containing atlas mapping in a format of:
  ##
  ##  .. code-block
  ##    name, x, y, w, h
  ##    ...
  ##
  ##  ``count`` expected mappings count.
  ##
  new result, free
  result[] = initOrderedTable[string, TextureGraphic](nextPowerOfTwo(count))
  result.load(imagefile, mapfile)

