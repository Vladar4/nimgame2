# nimgame2/types.nim
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
  math,
  sdl2/sdl


export
  sdl.Color, sdl.Event, sdl.EventKind, sdl.Keycode, sdl.Rect, sdl.Renderer,
  sdl.Surface, sdl.Texture


# csize is deprecated in Nim v1.1
# See Nim commit 99078d80d7abb1c47612bc70f7affbde8735066a
when not declared(csize_t):
  type csize_t* {.importc: "size_t", nodecl.} = uint


type
  Coord* = tuple[x: float, y: float]  ##  Coordinates type
  Coord2* = tuple[abs, rel: Coord]    ##  Abs + Rel coordinates type
  CoordInt* = tuple[x: int, y: int]   ##  Integer coordinates
  Dim* = tuple[w: int, h: int]        ##  Dimensions type
  Angle* = float                      ##  Angle type
  Scale* = float                      ##  Scale type
  Transform* = tuple[pos: Coord, angle: Angle, scale: Scale] # Experimental
  Blend* {.size: sizeof(cint), pure.} = enum
    none  = sdl.BlendModeNone
    blend = sdl.BlendModeBlend
    bAdd = sdl.BlendModeAdd
    bMod = sdl.BlendModeMod
    bMul = sdl.BlendModeMul

  Flip* {.size: sizeof(cint), pure.} = enum
    none        = sdl.FlipNone,
    horizontal  = sdl.FlipHorizontal,
    vertical    = sdl.FlipVertical,
    both        = sdl.FlipBoth

  TextAlign* {.pure.} = enum left, center, right
  Direction* {.pure.} = enum leftRight, rightLeft, topBottom, bottomTop
  HAlign* {.pure.} = enum left, center, right
  VAlign* {.pure.} = enum top, center, bottom


converter toSeq*[T](s: Slice[T]): seq[T] =
  result = @[]
  if s.a <= s.b:
    for i in s:
      result.add(i)
  else:
    for i in countdown(s.a, s.b):
      result.add(i)


#=======#
# Color #
#=======#

converter toUint32*(c: Color): uint32 =
  ##  Color(r, g, b, a) to 0xRRGGBBAA
  ##
  uint32((c.r shl 24) or (c.g shl 16) or (c.b shl 8) or (c.a))


converter toColor*(u: uint32): Color =
  ##  0xRRGGBBAA to Color(r, g, b, a)
  ##
  Color(r: cast[uint8](u shr 24),
        g: cast[uint8](u shr 16),
        b: cast[uint8](u shr 8),
        a: cast[uint8](u))


template neg*(c: Color): Color =  ##  \
  ##  ``Return`` negative to color ``c``.
  Color(r: 0xFF-c.r, g: 0xFF-c.g, b: 0xFF-c.b, a: c.a)


template colorConst(name, value) =  ##  \
  ##  Declare ColorName and ColourName constants from hex RGB values.
  const
    `Color name`* {.inject.} = (value.uint32 shl 8) + 0xFF
    `Colour name`* {.inject.} = `Color name`

colorConst(Black, 0x000000)
colorConst(Navy, 0x000080)
colorConst(DarkBlue, 0x00008B)
colorConst(MediumBlue, 0x0000CD)
colorConst(Blue, 0x0000FF)
colorConst(DarkGreen, 0x006400)
colorConst(Green, 0x008000)
colorConst(Teal, 0x008080)
colorConst(DarkCyan, 0x008B8B)
colorConst(DeepSkyBlue, 0x00BFFF)
colorConst(DarkTurquoise, 0x00CED1)
colorConst(MediumSpringGreen, 0x00FA9A)
colorConst(Lime, 0x00FF00)
colorConst(SpringGreen, 0x00FF7F)
colorConst(Aqua, 0x00FFFF)
colorConst(Cyan, 0x00FFFF)
colorConst(MidnightBlue, 0x191970)
colorConst(DodgerBlue, 0x1E90FF)
colorConst(LightSeaGreen, 0x20B2AA)
colorConst(ForestGreen, 0x228B22)
colorConst(SeaGreen, 0x2E8B57)
colorConst(DarkSlateGray, 0x2F4F4F)
colorConst(DarkSlateGrey, 0x2F4F4F)
colorConst(LimeGreen, 0x32CD32)
colorConst(MediumSeaGreen, 0x3CB371)
colorConst(Turquoise, 0x40E0D0)
colorConst(RoyalBlue, 0x4169E1)
colorConst(SteelBlue, 0x4682B4)
colorConst(DarkSlateBlue, 0x483D8B)
colorConst(MediumTurquoise, 0x48D1CC)
colorConst(Indigo, 0x4B0082)
colorConst(DarkOliveGreen, 0x556B2F)
colorConst(CadetBlue, 0x5F9EA0)
colorConst(CornflowerBlue, 0x6495ED)
colorConst(RebeccaPurple, 0x663399)
colorConst(MediumAquaMarine, 0x66CDAA)
colorConst(DimGray, 0x696969)
colorConst(DimGrey, 0x696969)
colorConst(SlateBlue, 0x6A5ACD)
colorConst(OliveDrab, 0x6B8E23)
colorConst(SlateGray, 0x708090)
colorConst(SlateGrey, 0x708090)
colorConst(LightSlateGray, 0x778899)
colorConst(LightSlateGrey, 0x778899)
colorConst(MediumSlateBlue, 0x7B68EE)
colorConst(LawnGreen, 0x7CFC00)
colorConst(Chartreuse, 0x7FFF00)
colorConst(Aquamarine, 0x7FFFD4)
colorConst(Maroon, 0x800000)
colorConst(Purple, 0x800080)
colorConst(Olive, 0x808000)
colorConst(Gray, 0x808080)
colorConst(Grey, 0x808080)
colorConst(SkyBlue, 0x87CEEB)
colorConst(LightSkyBlue, 0x87CEFA)
colorConst(BlueViolet, 0x8A2BE2)
colorConst(DarkRed, 0x8B0000)
colorConst(DarkMagenta, 0x8B008B)
colorConst(SaddleBrown, 0x8B4513)
colorConst(DarkSeaGreen, 0x8FBC8F)
colorConst(LightGreen, 0x90EE90)
colorConst(MediumPurple, 0x9370DB)
colorConst(DarkViolet, 0x9400D3)
colorConst(PaleGreen, 0x98FB98)
colorConst(DarkOrchid, 0x9932CC)
colorConst(YellowGreen, 0x9ACD32)
colorConst(Sienna, 0xA0522D)
colorConst(Brown, 0xA52A2A)
colorConst(DarkGray, 0xA9A9A9)
colorConst(DarkGrey, 0xA9A9A9)
colorConst(LightBlue, 0xADD8E6)
colorConst(GreenYellow, 0xADFF2F)
colorConst(PaleTurquoise, 0xAFEEEE)
colorConst(LightSteelBlue, 0xB0C4DE)
colorConst(PowderBlue, 0xB0E0E6)
colorConst(FireBrick, 0xB22222)
colorConst(DarkGoldenRod, 0xB8860B)
colorConst(MediumOrchid, 0xBA55D3)
colorConst(RosyBrown, 0xBC8F8F)
colorConst(DarkKhaki, 0xBDB76B)
colorConst(Silver, 0xC0C0C0)
colorConst(MediumVioletRed, 0xC71585)
colorConst(IndianRed, 0xCD5C5C)
colorConst(Peru, 0xCD853F)
colorConst(Chocolate, 0xD2691E)
colorConst(Tan, 0xD2B48C)
colorConst(LightGray, 0xD3D3D3)
colorConst(LightGrey, 0xD3D3D3)
colorConst(Thistle, 0xD8BFD8)
colorConst(Orchid, 0xDA70D6)
colorConst(GoldenRod, 0xDAA520)
colorConst(PaleVioletRed, 0xDB7093)
colorConst(Crimson, 0xDC143C)
colorConst(Gainsboro, 0xDCDCDC)
colorConst(Plum, 0xDDA0DD)
colorConst(BurlyWood, 0xDEB887)
colorConst(LightCyan, 0xE0FFFF)
colorConst(Lavender, 0xE6E6FA)
colorConst(DarkSalmon, 0xE9967A)
colorConst(Violet, 0xEE82EE)
colorConst(PaleGoldenRod, 0xEEE8AA)
colorConst(LightCoral, 0xF08080)
colorConst(Khaki, 0xF0E68C)
colorConst(AliceBlue, 0xF0F8FF)
colorConst(HoneyDew, 0xF0FFF0)
colorConst(Azure, 0xF0FFFF)
colorConst(SandyBrown, 0xF4A460)
colorConst(Wheat, 0xF5DEB3)
colorConst(Beige, 0xF5F5DC)
colorConst(WhiteSmoke, 0xF5F5F5)
colorConst(MintCream, 0xF5FFFA)
colorConst(GhostWhite, 0xF8F8FF)
colorConst(Salmon, 0xFA8072)
colorConst(AntiqueWhite, 0xFAEBD7)
colorConst(Linen, 0xFAF0E6)
colorConst(LightGoldenRodYellow, 0xFAFAD2)
colorConst(OldLace, 0xFDF5E6)
colorConst(Red, 0xFF0000)
colorConst(Fuchsia, 0xFF00FF)
colorConst(Magenta, 0xFF00FF)
colorConst(DeepPink, 0xFF1493)
colorConst(OrangeRed, 0xFF4500)
colorConst(Tomato, 0xFF6347)
colorConst(HotPink, 0xFF69B4)
colorConst(Coral, 0xFF7F50)
colorConst(DarkOrange, 0xFF8C00)
colorConst(LightSalmon, 0xFFA07A)
colorConst(Orange, 0xFFA500)
colorConst(LightPink, 0xFFB6C1)
colorConst(Pink, 0xFFC0CB)
colorConst(Gold, 0xFFD700)
colorConst(PeachPuff, 0xFFDAB9)
colorConst(NavajoWhite, 0xFFDEAD)
colorConst(Moccasin, 0xFFE4B5)
colorConst(Bisque, 0xFFE4C4)
colorConst(MistyRose, 0xFFE4E1)
colorConst(BlanchedAlmond, 0xFFEBCD)
colorConst(PapayaWhip, 0xFFEFD5)
colorConst(LavenderBlush, 0xFFF0F5)
colorConst(SeaShell, 0xFFF5EE)
colorConst(Cornsilk, 0xFFF8DC)
colorConst(LemonChiffon, 0xFFFACD)
colorConst(FloralWhite, 0xFFFAF0)
colorConst(Snow, 0xFFFAFA)
colorConst(Yellow, 0xFFFF00)
colorConst(LightYellow, 0xFFFFE0)
colorConst(Ivory, 0xFFFFF0)
colorConst(White, 0xFFFFFF)


#=======#
# Coord #
#=======#

proc `==`*(c1, c2: Coord): bool {.inline.} =
  return (c1.x == c2.x) and (c1.y == c2.y)


proc `==`*(c: Coord, v: float): bool {.inline.} =
  return (c.x == v) and (c.y == v)


template `==`*(v: float, c: Coord): bool =
  (c == v)


proc `-`*(c: Coord): Coord {.inline.} =
  return (-c.x, -c.y)


proc `+`*(c1, c2: Coord): Coord {.inline.} =
  result.x = c1.x + c2.x
  result.y = c1.y + c2.y


proc `+=`*(c1: var Coord, c2: Coord) {.inline.} =
  c1.x += c2.x
  c1.y += c2.y


proc `-`*(c1, c2: Coord): Coord {.inline.} =
  result.x = c1.x - c2.x
  result.y = c1.y - c2.y


proc `-=`*(c1: var Coord, c2: Coord) {.inline.} =
  c1.x -= c2.x
  c1.x -= c2.y


proc `*`*(c1, c2: Coord): Coord {.inline.} =
  result.x = c1.x * c2.x
  result.y = c1.y * c2.y


proc `*=`*(c1: var Coord, c2: Coord) {.inline.} =
  c1.x *= c2.x
  c1.y *= c2.y


proc `/`*(c1, c2: Coord): Coord {.inline.} =
  result.x = c1.x / c2.x
  result.y = c1.y / c2.y


proc `/=`*(c1: var Coord, c2: Coord) {.inline.} =
  c1.x /= c2.x
  c1.y /= c2.y


proc `+`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x + v
  result.y = c.y + v


template `+`*(v: float, c: Coord): Coord =
  (c + v)


proc `+=`*(c: var Coord, v: float) {.inline.} =
  c.x += v
  c.y += v


proc `-`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x - v
  result.y = c.y - v


template `-`*(v: float, c: Coord): Coord =
  (-c + v)


proc `-=`*(c: var Coord, v: float) {.inline.} =
  c.x -= v
  c.y -= v


proc `*`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x * v
  result.y = c.y * v


template `*`*(v: float, c: Coord): Coord =
  (c * v)


proc `*=`*(c: var Coord, v: float) {.inline.} =
  c.x *= v
  c.y *= v


proc `/`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x / v
  result.y = c.y / v


proc `/=`*(c: var Coord, v: float) {.inline.} =
  c.x /= v
  c.y /= v


proc abs*(c: Coord): Coord {.inline.} =
  result.x = abs(c.x)
  result.y = abs(c.y)


proc sin*(c: Coord): Coord {.inline.} =
  result.x = sin(c.x)
  result.y = sin(c.y)


proc arcsin*(c: Coord): Coord {.inline.} =
  result.x = arcsin(c.x)
  result.y = arcsin(c.y)


converter toDim*(c: Coord): Dim =
  result.w = c.x.int
  result.h = c.y.int


#==========#
# CoordInt #
#==========#

proc `==`*(c1, c2: CoordInt): bool {.inline.} =
  return (c1.x == c2.x) and (c1.y == c2.y)


proc `-`*(c: CoordInt): CoordInt {.inline.} =
  return (-c.x, -c.y)


proc `+`*(c1, c2: CoordInt): CoordInt {.inline.} =
  result.x = c1.x + c2.x
  result.y = c1.y + c2.y


proc `+=`*(c1: var CoordInt, c2: CoordInt) {.inline.} =
  c1.x += c2.x
  c1.y += c2.y


proc `-`*(c1, c2: CoordInt): CoordInt {.inline.} =
  result.x = c1.x - c2.x
  result.y = c1.y - c2.y


proc `-=`*(c1: var CoordInt, c2: CoordInt) {.inline.} =
  c1.x -= c2.x
  c1.x -= c2.y


proc `*`*(c1, c2: CoordInt): CoordInt {.inline.} =
  result.x = c1.x * c2.x
  result.y = c1.y * c2.y


proc `*=`*(c1: var CoordInt, c2: CoordInt) {.inline.} =
  c1.x *= c2.x
  c1.y *= c2.y


proc `div`*(c1, c2: CoordInt): CoordInt {.inline.} =
  result.x = c1.x div c2.x
  result.y = c1.y div c2.y


proc `div=`*(c1: var CoordInt, c2: CoordInt) {.inline.} =
  c1.x = c1.x div c2.x
  c1.y = c1.y div c2.y


proc `+`*(c: CoordInt, v: int): CoordInt {.inline.} =
  result.x = c.x + v
  result.y = c.y + v


template `+`*(v: int, c: CoordInt): CoordInt =
  (c + v)


proc `+=`*(c: var CoordInt, v: int) {.inline.} =
  c.x += v
  c.y += v


proc `-`*(c: CoordInt, v: int): CoordInt {.inline.} =
  result.x = c.x - v
  result.y = c.y - v


template `-`*(v: int, c: CoordInt): CoordInt =
  (-c + v)


proc `-=`*(c: var CoordInt, v: int) {.inline.} =
  c.x -= v
  c.y -= v


proc `*`*(c: CoordInt, v: int): CoordInt {.inline.} =
  result.x = c.x * v
  result.y = c.y * v


template `*`*(v: int, c: CoordInt): CoordInt =
  (c * v)


proc `*=`*(c: var CoordInt, v: int) {.inline.} =
  c.x *= v
  c.y *= v


proc `div`*(c: CoordInt, v: int): CoordInt {.inline.} =
  result.x = c.x div v
  result.y = c.y div v


proc `div=`*(c: var CoordInt, v: int) {.inline.} =
  c.x = c.x div v
  c.y = c.y div v


proc abs*(c: CoordInt): CoordInt {.inline.} =
  result.x = abs(c.x)
  result.y = abs(c.y)


converter toDim*(c: CoordInt): Dim =
  result.w = c.x
  result.h = c.y


#=====#
# Dim #
#=====#

proc `==`*(d1, d2: Dim): bool {.inline.} =
  return (d1.w == d2.w) and (d1.h == d2.h)


proc `+`*(d1, d2: Dim): Dim {.inline.} =
  result.w = d1.w + d2.w
  result.h = d1.h + d2.h


proc `+=`*(d1: var Dim, d2: Dim) {.inline.} =
  d1.w += d2.w
  d1.h += d2.h


proc `-`*(d1, d2: Dim): Dim {.inline.} =
  result.w = d1.w - d2.w
  result.h = d1.h - d2.h


proc `-=`*(d1: var Dim, d2: Dim) {.inline.} =
  d1.w -= d2.w
  d1.h -= d2.h


proc `*`*(d1, d2: Dim): Dim {.inline.} =
  result.w = d1.w * d2.w
  result.h = d1.h * d2.h


proc `*=`*(d1: var Dim, d2: Dim) {.inline.} =
  d1.w *= d2.w
  d1.h *= d2.h


proc `/`*(d1, d2: Dim): Dim {.inline.} =
  result.w = d1.w div d2.w
  result.h= d1.h div d2.h


proc `/=`*(d1: var Dim, d2: Dim) {.inline.} =
  d1.w = d1.w div d2.w
  d1.h = d1.h div d2.h


proc `+`*(d: Dim, v: int): Dim {.inline.} =
  result.w = d.w + v
  result.h = d.h + v


proc `+=`*(d: var Dim, v: int) {.inline.} =
  d.w += v
  d.h += v


proc `-`*(d: Dim, v: int): Dim {.inline.} =
  result.w = d.w - v
  result.h = d.h - v


proc `-=`*(d: var Dim, v: int) {.inline.} =
  d.w -= v
  d.h -= v


proc `*`*(d: Dim, v: int): Dim {.inline.} =
  result.w = d.w * v
  result.h = d.h * v


proc `*=`*(d: var Dim, v: int) {.inline.} =
  d.w *= v
  d.h *= v


proc `/`*(d: Dim, v: int): Dim {.inline.} =
  result.w = d.w div v
  result.h= d.h div v


proc `/=`*(d: var Dim, v: int): Dim {.inline.} =
  d.w = d.w div v
  d.h = d.h div v


converter toCoord*(d: Dim): Coord =
  result.x = d.w.float
  result.y = d.h.float


#=============#
#  Transform  #
#=============#

from utils import rotate

template `*`*(transform: Transform, point: Coord): Coord =
  transform.pos + rotate(point * transform.scale, transform.angle)

#[
# experimental
template `*`*(transform: Transform, other: Transform)=
  Transform(
    pos = transform * other.pos,
    angle = transform.angle + other.angle,
    scale = transform.scale * other.scale)
]#

template local*(transform: Transform): Transform =
  ( pos: (0.0, 0.0),
    angle: (-transform.angle) mod 360.0,
    scale: 1.0 / transform.scale
  ).Transform

