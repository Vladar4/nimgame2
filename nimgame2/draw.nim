# nimgame2/draw.nim
# Copyright (c) 2016-2018 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl, sdl2/sdl_gfx_primitives, sdl2/sdl_gfx_primitives_font,
  settings, types


type
  DrawMode* {.pure.} = enum
    default,
    aa,
    filled


proc pixel*(pos: Coord, color: Color): bool {.inline.} =
  ##  Draw a single pixel.
  ##
  pixelRGBA(renderer,
            pos.x.int16, pos.y.int16,
            color.r, color.g, color.b, color.a) == 0


proc hline*(pos: Coord, length: float, color: Color): bool {.inline.} =
  ##  Draw a horizontal line from ``pos`` to the right.
  ##
  hlineRGBA(renderer,
            pos.x.int16, pos.x.int16 + length.int16, pos.y.int16,
            color.r, color.g, color.b, color.a) == 0


proc vline*(pos: Coord, height: float, color: Color): bool {.inline.} =
  ##  Draw a vertical line from ``pos`` down.
  ##
  vlineRGBA(renderer,
            pos.x.int16, pos.y.int16, pos.y.int16 + height.int16,
            color.r, color.g, color.b, color.a) == 0


proc rect*(pos1, pos2: Coord, color: Color): bool {.inline.} =
  ##  Draw a rectangle.
  ##
  rectangleRGBA(renderer,
                pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                color.r, color.g, color.b, color.a) == 0


proc roundedRect*(pos1, pos2: Coord, rad: float,
                  color: Color): bool {.inline.} =
  ##  Draw a rounded rectangle.
  ##
  roundedRectangleRGBA(renderer,
                       pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                       rad.int16, color.r, color.g, color.b, color.a) == 0


proc box*(pos1, pos2: Coord, color: Color): bool {.inline.} =
  ##  Draw a filled rectangle (box).
  ##
  boxRGBA(renderer,
          pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
          color.r, color.g, color.b, color.a) == 0


proc roundedBox*(pos1, pos2: Coord, rad: float,
                 color: Color): bool {.inline.} =
  ##  Draw a rounded filled rectangle (box).
  ##
  roundedBoxRGBA(renderer,
                 pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                 rad.int16, color.r, color.g, color.b, color.a) == 0


proc line*(pos1, pos2: Coord, color: Color): bool {.inline.} =
  ##  Draw a line.
  ##
  lineRGBA(renderer,
           pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
           color.r, color.g, color.b, color.a) == 0


proc aaLine*(pos1, pos2: Coord, color: Color): bool {.inline.} =
  ##  Draw an anti-aliased line.
  ##
  aalineRGBA(renderer,
             pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
             color.r, color.g, color.b, color.a) == 0


proc thickLine*(pos1, pos2: Coord, width: float,
                color: Color): bool {.inline.} =
  ##  Draw a ``width`` pixels wide line.
  ##
  thickLineRGBA(renderer,
                pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                width.uint8, color.r, color.g, color.b, color.a) == 0


proc circle*(pos: Coord, rad: float, color: Color,
             mode: DrawMode = DrawMode.default): bool =
  ## Draw a circle.
  ##
  case mode:
  of DrawMode.default:
    circleRGBA(renderer,
               pos.x.int16, pos.y.int16, rad.int16,
               color.r, color.g, color.b, color.a) == 0
  of DrawMode.aa:
    aacircleRGBA(renderer,
                 pos.x.int16, pos.y.int16, rad.int16,
                 color.r, color.g, color.b, color.a) == 0
  of DrawMode.filled:
    filledCircleRGBA(renderer,
                     pos.x.int16, pos.y.int16, rad.int16,
                     color.r, color.g, color.b, color.a) == 0


proc arc*(pos: Coord, rad, start, finish: Angle,
          color: Color): bool {.inline.} =
  ##  Draw an arc.
  ##
  arcRGBA(renderer,
          pos.x.int16, pos.y.int16, rad.int16, start.int16, finish.int16,
          color.r, color.g, color.b, color.a) == 0


proc ellipse*(pos, rad: Coord, color: Color,
              mode: DrawMode = DrawMode.default): bool =
  ##  Draw an ellipse.
  ##
  case mode:
  of DrawMode.default:
    ellipseRGBA(renderer,
                pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                color.r, color.g, color.b, color.a) == 0
  of DrawMode.aa:
    aaEllipseRGBA(renderer,
                  pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                  color.r, color.g, color.b, color.a) == 0
  of DrawMode.filled:
    filledEllipseRGBA(renderer,
                      pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                      color.r, color.g, color.b, color.a) == 0


proc pie*(pos: Coord, rad, start, finish: Angle, color: Color,
          mode: DrawMode = DrawMode.default): bool =
  ##  Draw a circular sector (pie).
  ##
  case mode:
  of DrawMode.default, DrawMode.aa:
    pieRGBA(renderer,
            pos.x.int16, pos.y.int16, rad.int16,
            start.int16, finish.int16,
            color.r, color.g, color.b, color.a) == 0
  of DrawMode.filled:
    filledPieRGBA(renderer,
                  pos.x.int16, pos.y.int16, rad.int16,
                  start.int16, finish.int16,
                  color.r, color.g, color.b, color.a) == 0


proc trigon*(pos1, pos2, pos3: Coord, color: Color,
             mode: DrawMode = DrawMode.default): bool =
  ##  Draw a trigon.
  ##
  case mode:
  of DrawMode.default:
    trigonRGBA(renderer,
               pos1.x.int16, pos1.y.int16,
               pos2.x.int16, pos2.y.int16,
               pos3.x.int16, pos3.y.int16,
               color.r, color.g, color.b, color.a) == 0
  of DrawMode.aa:
    aaTrigonRGBA(renderer,
                 pos1.x.int16, pos1.y.int16,
                 pos2.x.int16, pos2.y.int16,
                 pos3.x.int16, pos3.y.int16,
                 color.r, color.g, color.b, color.a) == 0
  of DrawMode.filled:
    filledTrigonRGBA(renderer,
                     pos1.x.int16, pos1.y.int16,
                     pos2.x.int16, pos2.y.int16,
                     pos3.x.int16, pos3.y.int16,
                     color.r, color.g, color.b, color.a) == 0


template `+`[T](p: ptr T, off: int): ptr T =
  cast[ptr T](cast[ByteAddress](p) +% off * sizeof(T))


template `[]=`[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val


proc polygon*(pos: openarray[Coord], color: Color,
              mode: DrawMode = DrawMode.default,
              surface: sdl.Surface = nil, surfaceD: Coord = (0, 0)): bool =
  ##  Draw a polygon.
  ##
  var vx, vy: ptr int16
  vx = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  vy = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  for i in 0..pos.high:
    vx[i] = pos[i].x.int16
    vy[i] = pos[i].y.int16
  if surface == nil:
    result = case mode:
    of DrawMode.default:
      polygonRGBA(renderer,
                  vx, vy, pos.len,
                  color.r, color.g, color.b, color.a) == 0
    of DrawMode.aa:
      aaPolygonRGBA(renderer,
                    vx, vy, pos.len,
                    color.r, color.g, color.b, color.a) == 0
    of DrawMode.filled:
      filledPolygonRGBA(renderer,
                        vx, vy, pos.len,
                        color.r, color.g, color.b, color.a) == 0
  else: # textured
    result = texturedPolygon(renderer,
                             vx, vy, pos.len,
                             surface, surfaceD.x.int, surfaceD.y.int) == 0
  # dealloc
  dealloc(vx)
  dealloc(vy)


proc bezier*(pos: openarray[Coord], s: float, color: Color): bool =
  ##  Draw a bezier curve.
  ##
  var vx, vy: ptr int16
  vx = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  vy = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  for i in 0..pos.high:
    vx[i] = pos[i].x.int16
    vy[i] = pos[i].y.int16
  result = bezierRGBA(renderer,
                      vx, vy, pos.len, s.int,
                      color.r, color.g, color.b, color.a) == 0
  # dealloc
  dealloc(vx)
  dealloc(vy)


proc setFont*(fontdata: pointer, dim: Dim) =
  ##  Set sdl_gfx_primitives font.
  ##
  gfxPrimitivesSetFont(fontdata, dim.w.uint32, dim.h.uint32)


template setFont*() =
  ##  Set default sdl_gfx_primitives font.
  ##
  gfxPrimitivesSetFont(addr(gfxPrimitivesFontData), 8, 8)


template setFontRotation*(rotation: uint32) =
  ##  Set sdl_gfx_primitives font rotation.
  ##
  gfxPrimitivesSetFontRotation(rotation)


proc character*(pos: Coord, c: char, color: Color): bool {.inline.} =
  ##  Draw a single character.
  ##
  characterRGBA(renderer,
                pos.x.int16, pos.y.int16, c,
                color.r, color.g, color.b, color.a) == 0


proc string*(pos: Coord, s: string, color: Color): bool {.inline.} =
  ##  Draw a string of text.
  ##
  stringRGBA(renderer,
             pos.x.int16, pos.y.int16, s,
             color.r, color.g, color.b, color.a) == 0

