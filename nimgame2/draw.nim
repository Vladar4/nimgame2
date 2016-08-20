# nimgame2/draw.nim
# Copyright (c) 2016 Vladar
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
  sdl2/sdl, sdl2/sdl_gfx_primitives, sdl2/sdl_gfx_primitives_font,
  types


type
  DrawMode* {.pure.} = enum
    default,
    aa,
    filled


proc pixel*(renderer: Renderer,
            pos: Coord, color: Color): bool {.inline.} =
  pixelRGBA(renderer,
            pos.x.int16, pos.y.int16,
            color.r, color.g, color.b, color.a) == 0


proc hline*(renderer: Renderer,
            pos: Coord, length: float, color: Color): bool {.inline.} =
  hlineRGBA(renderer,
            pos.x.int16, pos.x.int16 + length.int16, pos.y.int16,
            color.r, color.g, color.b, color.a) == 0


proc vline*(renderer: Renderer,
            pos: Coord, height: float, color: Color): bool {.inline.} =
  vlineRGBA(renderer,
            pos.x.int16, pos.y.int16, pos.y.int16 + height.int16,
            color.r, color.g, color.b, color.a) == 0


proc rect*(renderer: Renderer,
           pos1, pos2: Coord, color: Color): bool {.inline.} =
  rectangleRGBA(renderer,
                pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                color.r, color.g, color.b, color.a) == 0


proc roundedRect*(renderer: Renderer,
                  pos1, pos2: Coord, rad: float,
                  color: Color): bool {.inline.} =
  roundedRectangleRGBA(renderer,
                       pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                       rad.int16, color.r, color.g, color.b, color.a) == 0


proc box*(renderer: Renderer,
          pos1, pos2: Coord, color: Color): bool {.inline.} =
    boxRGBA(renderer,
            pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
            color.r, color.g, color.b, color.a) == 0


proc roundedBox*(renderer: Renderer,
                 pos1, pos2: Coord, rad: float,
                 color: Color): bool {.inline.} =
  roundedBoxRGBA(renderer,
                 pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                 rad.int16, color.r, color.g, color.b, color.a) == 0


proc line*(renderer: Renderer,
           pos1, pos2: Coord, color: Color): bool {.inline.} =
  lineRGBA(renderer,
           pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
           color.r, color.g, color.b, color.a) == 0


proc aaLine*(renderer: Renderer,
             pos1, pos2: Coord, color: Color): bool {.inline.} =
  aalineRGBA(renderer,
             pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
             color.r, color.g, color.b, color.a) == 0


proc thickLine*(renderer: Renderer,
                pos1, pos2: Coord, width: float,
                color: Color): bool {.inline.} =
  thickLineRGBA(renderer,
                pos1.x.int16, pos1.y.int16, pos2.x.int16, pos2.y.int16,
                width.uint8, color.r, color.g, color.b, color.a) == 0


proc circle*(renderer: Renderer,
             pos: Coord, rad: float, color: Color,
             mode: DrawMode = DrawMode.default): bool =
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


proc arc*(renderer: Renderer,
          pos: Coord, rad, start, finish: float,
          color: Color): bool {.inline.} =
  arcRGBA(renderer,
          pos.x.int16, pos.y.int16, rad.int16, start.int16, finish.int16,
          color.r, color.g, color.b, color.a) == 0


proc ellipse*(renderer: Renderer,
              pos, rad: Coord, color: Color,
              mode: DrawMode = DrawMode.default): bool =
  case mode:
  of DrawMode.default:
    ellipseRGBA(renderer,
                pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                color.r, color.g, color.b, color.a) == 0
  of DrawMode.aa:
    aaellipseRGBA(renderer,
                  pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                  color.r, color.g, color.b, color.a) == 0
  of DrawMode.filled:
    filledEllipseRGBA(renderer,
                      pos.x.int16, pos.y.int16, rad.x.int16, rad.y.int16,
                      color.r, color.g, color.b, color.a) == 0


proc pie*(renderer: Renderer,
          pos: Coord, rad, start, finish: float, color: Color,
          mode: DrawMode = DrawMode.default): bool =
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


proc trigon*(renderer: Renderer,
             pos1, pos2, pos3: Coord, color: Color,
             mode: DrawMode = DrawMode.default): bool =
  case mode:
  of DrawMode.default:
    trigonRGBA(renderer,
              pos1.x.int16, pos1.y.int16,
              pos2.x.int16, pos2.y.int16,
              pos3.x.int16, pos3.y.int16,
              color.r, color.g, color.b, color.a) == 0
  of DrawMode.aa:
    aatrigonRGBA(renderer,
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


proc polygon*(renderer: Renderer,
              pos: openarray[Coord], color: Color,
              mode: DrawMode = DrawMode.default,
              texture: sdl.Surface = nil, textureD: Coord = (0, 0)): bool =
  var vx, vy: ptr int16
  vx = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  vy = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  for i in 0..pos.high:
    vx[i] = pos[i].x.int16
    vx[i] = pos[i].y.int16
  if texture == nil:
    case mode:
    of DrawMode.default:
      polygonRGBA(renderer,
                  vx, vy, pos.len,
                  color.r, color.g, color.b, color.a) == 0
    of DrawMode.aa:
      aapolygonRGBA(renderer,
                    vx, vy, pos.len,
                    color.r, color.g, color.b, color.a) == 0
    of DrawMode.filled:
      filledPolygonRGBA(renderer,
                        vx, vy, pos.len,
                        color.r, color.g, color.b, color.a) == 0
  else: # textured
    texturedPolygon(renderer,
                    vx, vy, pos.len,
                    texture, textureD.x.int, textureD.y.int) == 0


proc bezier*(renderer: Renderer,
             pos: openarray[Coord], s: float, color: Color): bool =
  var vx, vy: ptr int16
  vx = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  vy = cast[ptr int16](alloc(pos.len * sizeof(int16)))
  for i in 0..pos.high:
    vx[i] = pos[i].x.int16
    vx[i] = pos[i].y.int16
  bezierRGBA(renderer,
             vx, vy, pos.len, s.int,
             color.r, color.g, color.b, color.a) == 0



proc setFont*(fontdata: pointer, dim: Dim) =
  gfxPrimitivesSetFont(fontdata, dim.w.uint32, dim.h.uint32)


template setFont*() =
  gfxPrimitivesSetFont(addr(gfxPrimitivesFontData), 8, 8)


template setFontRotation*(rotation: uint32) =
  gfxPrimitivesSetFontRotation(rotation)


proc character*(renderer: Renderer,
                pos: Coord, c: char, color: Color): bool {.inline.} =
  characterRGBA(renderer,
                pos.x.int16, pos.y.int16, c,
                color.r, color.g, color.b, color.a) == 0


proc string*(renderer: Renderer,
             pos: Coord, s: string, color: Color): bool {.inline.} =
  stringRGBA(renderer,
             pos.x.int16, pos.y.int16, s,
             color.r, color.g, color.b, color.a) == 0

