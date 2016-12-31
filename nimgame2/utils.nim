# nimgame2/utils.nim
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
  math,
  types


template rad*(a: Angle): Angle =
  ##  Convert degrees to radians.
  ##
  (a * Pi / 180)


template deg*(a: Angle): Angle =
  ##  Convert radians to degrees.
  ##
  (a * 180 / Pi)


proc distance*(a, b: Coord): float {.inline.} =
  ##  ``Return`` distance between two coordinates.
  ##
  return sqrt( pow(b.x - a.x, 2) + pow(b.y - a.y, 2) )


proc distanceToLine*(a, d1, d2: Coord): float =
  ##  ``Return`` distance between point ``a`` and line ``d1``-``d2``.
  ##
  let d = d2 - d1
  return abs( d.y * a.x - d.x * a.y + d2.x * d1.y - d2.y * d1.x ) /
         sqrt( pow(d.y, 2) + pow(d.x, 2) )


proc direction*(a, b: Coord): Angle =
  ##  ``Return`` angle direction from coordinate ``a`` to ``b``.
  ##
  let
    dx = a.x - b.x
    dy = a.y - b.y
  return -(arctan2(dy, dx) / Pi) * 180 + 90


proc rotate*(a: Coord, angle: Angle): Coord =
  ##  Rotate point ``a`` by the given ``angle`` (in degrees).
  ##
  let
    rot = rad(angle)
    c = cos(rot)
    s = sin(rot)
  result.x = a.x * c - a.y * s
  result.y = a.x * s + a.y * c


proc rotate*(point, center, offset: Coord, angle: Angle): Coord =
  ##  Rotate ``point`` by the given ``angle`` around ``center``
  ##  and with given ``offset``.
  ##
  ##  ``offset``  Offset coordinate (parent position)
  ##  ``point``   Point to rotate
  ##  ``center``  Center of rotation
  ##  ``angle``   Angle of rotation (in degrees)
  ##
  result = offset - center + point
  if angle != 0:
    result = rotate(point - center, angle) + offset

