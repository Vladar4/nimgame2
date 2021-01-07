# nimgame2/outline.nim
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
  settings, surfacegraphic, types


const
  DefaultOutlineColor* = 0xFFFFFFFF'u32
  DefaultOutlineThickness* = 1
  DefaultOutlineThreshold* = 200


type
  Outline* = ref object of SurfaceGraphic
    color*: Color         ##  outline color
    thickness*: Positive  ##  outline thickness (in pixels)
    threshold*: uint8     ##  alpha threshold for edge detection
    shadow*: bool         ##  if true - solid pixels are filled as well


#=========#
# Outline #
#=========#

proc free*(outline: Outline) =
  SurfaceGraphic(outline).free()
  outline.color = DefaultOutlineColor
  outline.thickness = DefaultOutlineThickness
  outline.threshold = DefaultOutlineThreshold
  outline.shadow = false


proc initOutline*(
    outline: Outline,
    color: Color = DefaultOutlineColor,
    thickness: Positive = DefaultOutlineThickness,
    threshold: uint8 = DefaultOutlineThreshold,
    shadow: bool = false) =
  outline.initSurfaceGraphic()
  outline.color = color
  outline.thickness = thickness
  outline.threshold = threshold
  outline.shadow = shadow


proc newOutline*(
    color: Color = DefaultOutlineColor,
    thickness: Positive = DefaultOutlineThickness,
    threshold: uint8 = DefaultOutlineThreshold,
    shadow: bool = false): Outline =
  new result, free
  result.initOutline(color, thickness, threshold, shadow)


#TODO support for pixel formats other than 4-byte ones
proc updateOutline*(outline: Outline, source: Surface): bool =
  let
    fmt = source.format
    pitch = source.pitch div fmt.BytesPerPixel
    color = fmt.mapRGBA(outline.color)
    t = outline.thickness.int32 # width
    t2 = t * 2 # double width
    tt = t * t # thickness squared
    dstW = source.w + t2
    dstH = source.h + t2

  if not(outline.surface == nil):
    outline.freeSurface()

  # create a new surface
  if not outline.assignSurface(createRGBSurfaceWithFormat(
      0, dstW, dstH, fmt.BitsPerPixel.cint, fmt.format)) or
      outline.surface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create a surface for outline proc",
                    sdl.getError())
    return false

  # lock
  discard lockSurface(source)
  discard lockSurface(outline.surface)

  var
    x, y: int
    srcPixels = cast[ptr uint32](source.pixels)
    dstPixels = cast[ptr uint32](outline.surface.pixels)

  ptrMath:
    if t == 1: # simpler algorithm for 1-pixel thickness
      for y in -t2..<dstH:
        for x in -t2..<dstW:
          var px = if (y in 0..<source.h) and (x in 0..<source.w):
            srcPixels[x + y * source.w].getRGBA(fmt)
          else:
            0'u32 # transparent pixels outside of the source surface
          if px.a < outline.threshold: # transparent pixel
            let scan = [(x:x, y:y-1), (x, y+1), (x-1, y), (x+1, y)]
            for n in scan:
              # check if out of bounds
              if n.x < 0 or n.x >= source.w or n.y < 0 or n.y >= source.h:
                continue
              if  srcPixels[n.x + n.y * source.w].
                  getRGBA(fmt).a >= outline.threshold: # non-transparent pixel
                dstPixels[t + x + (t + y) * outline.surface.w] = color
          elif outline.shadow:
            dstPixels[t + x + (t + y) * outline.surface.w] = color

    else: # advanced algorithm for thickness > 1
      while y < source.h:
        while x < source.w:
          # check for transparency
          if srcPixels[x + y * source.w].getRGBA(fmt).a >= outline.threshold:
            # draw circle
            for yy in -t..t:
              let
                yy2 = yy * yy
                y0 = (y + t + yy) * outline.surface.w
                yyy = y + yy
                yyy0 = yyy * outline.surface.w
              for xx in -t..t:
                if (yy2 + xx * xx <= tt): # inside the circle
                  # check for transparency
                  let
                    xxx = x + xx
                    px =
                      if (yyy in 0..<source.h) and (xxx in 0..<source.w):
                        srcPixels[xxx + yyy * source.w].getRGBA(fmt)
                      else:
                        0'u32 # transparent pixels outside of the source surface
                  if outline.shadow or (px.a < outline.threshold):
                    dstPixels[y0 + xxx + t] = color
          inc x
        # while x < source.w
        x = 0
        inc y
      # while y < source.h
  # ptrMath

  # unlock
  unlockSurface(source)
  unlockSurface(outline.surface)

  return outline.updateSurface()

