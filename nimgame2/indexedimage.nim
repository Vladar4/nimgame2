# nimgame2/indexedimage.nim
# Copyright (c) 2016-2019 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl_image as img,
  palette, settings, types


type
  IndexedImage* {.deprecated: "Use SurfaceGraphic instead".} =
      ref object of RootObj
    # Private
    fSurface: Surface   ##  Source surface


#==============#
# IndexedImage #
#==============#

proc free*(image: IndexedImage) =
  if not (image.fSurface == nil):
    image.fSurface.freeSurface()


proc initIndexedImage*(image: IndexedImage) =
  image.free()
  image.fSurface = nil


template init*(image: IndexedImage) {.deprecated: "Use initIndexedImage() insteadl".} =
  initIndexedImage(image)


proc load*(image: IndexedImage,
           file: string): bool =
  ##  Load ``image``graphic source from a ``file``.
  ##
  result = true
  image.free()
  # load image
  image.fSurface = img.load(file)
  if image.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load indexed image %s: %s",
                    file, img.getError())
    return false

  if image.fSurface.format.palette == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "No palette found in image %s",
                    file)
    image.fSurface.freeSurface()
    return false


proc load*(image: IndexedImage,
           src: ptr RWops, freeSrc: bool = true): bool =
  ##  Load ``image``graphic source from a ``src`` ``RWops``.
  ##
  result = true
  image.free()
  # load image
  image.fSurface = img.loadRW(src, freeSrc)
  if image.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load indexed image RW: %s",
                    img.getError())
    return false

  if image.fSurface.format.palette == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "No palette found in image RW")
    image.fSurface.freeSurface()
    return false


proc newIndexedImage*(): IndexedImage =
  new result, free
  result.initIndexedImage()


proc newIndexedImage*(file: string): IndexedImage =
  ##  Create a new IndexedImage and load it from a ``file``.
  ##
  result = newIndexedImage()
  discard result.load(file)


proc newIndexedImage*(src: ptr RWops, freeSrc: bool = true): IndexedImage =
  ##  Create a new IndexedImage and load it from a ``src`` ``RWops``.
  ##
  result = newIndexedImage()
  discard result.load(src, freeSrc)


proc palette*(image: IndexedImage): PalettePtr {.inline.} =
  ##  Get the current palette of the ``image``.
  ##
  image.fSurface.format.palette


proc `palette=`*(image: IndexedImage, palette: PalettePtr) {.inline.} =
  ##  Assign a new palette to the ``image``.
  ##
  if image.fSurface.setSurfacePalette(palette) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set the new palette: %s",
                    sdl.getError())


proc render*(image: IndexedImage): Texture {.inline.} =
  ##  ``Return`` a new ``Texture`` created from indexed ``image``.
  ##
  renderer.createTextureFromSurface(image.fSurface)

