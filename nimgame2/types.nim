# nimgame2/types.nim
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
  sdl2/sdl


export
  sdl.Color, sdl.Event, sdl.EventKind, sdl.Keycode, sdl.Rect, sdl.Renderer


when defined(faststack):
  include faststack


type
  Coord* = tuple[x: float, y: float]  ##  Coordinates type
  Coord2* = tuple[abs: Coord, rel: Coord] ## Abs + Rel coordinates type
  Dim* = tuple[w: int, h: int]        ##  Dimensions type
  Angle* = float                      ##  Angle type

  Blend* {.size: sizeof(cint), pure.} = enum
    none  = sdl.BlendModeNone
    blend = sdl.BlendModeBlend
    bAdd = sdl.BlendModeAdd
    bMod = sdl.BlendModeMod

  Flip* {.size: sizeof(cint), pure.} = enum
    none        = sdl.FlipNone,
    horizontal  = sdl.FlipHorizontal,
    vertical    = sdl.FlipVertical,
    both        = sdl.FlipBoth


#########
# COORD #
#########

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


proc `+=`*(c: var Coord, v: float) {.inline.} =
  c.x += v
  c.y += v


proc `-`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x - v
  result.y = c.y - v


proc `-=`*(c: var Coord, v: float) {.inline.} =
  c.x -= v
  c.y -= v


proc `*`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x * v
  result.y = c.y * v


proc `*=`*(c: var Coord, v: float) {.inline.} =
  c.x *= v
  c.y *= v


proc `/`*(c: Coord, v: float): Coord {.inline.} =
  result.x = c.x / v
  result.y = c.y / v


proc `/=`*(c: var Coord, v: float) {.inline.} =
  c.x /= v
  c.y /= v


#######
# DIM #
#######

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

