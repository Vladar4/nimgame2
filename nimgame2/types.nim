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
