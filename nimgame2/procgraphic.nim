# nimgame2/procgraphic.nim
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
  sdl2/sdl,
  graphic, types


type
  ProcGraphic* = ref object of Graphic
    procedure*: proc(graphic: ProcGraphic,
                     pos: Coord,
                     angle: Angle,
                     scale: Scale,
                     center: Coord,
                     flip: Flip,
                     region: Rect) {.locks:0.}  ##  Drawing procedure.
    dimProcedure*: proc(): Dim {.locks:0.}  ##  Dimensions procedure.


#=============#
# ProcGraphic #
#=============#

proc newProcGraphic*(): ProcGraphic =
  new result
  result.procedure = nil


method w*(graphic: ProcGraphic): int =
  ##  ``Return`` the width of the ``graphic`` if available, or `nil` otherwise.
  ##
  if graphic.dimProcedure == nil:
    return 0
  else:
    return graphic.dimProcedure().w


method h*(graphic: ProcGraphic): int =
  ##  ``Return`` the height of the ``graphic`` if available, or `nil` otherwise.
  ##
  if graphic.dimProcedure == nil:
    return 0
  else:
    return graphic.dimProcedure().h


method dim*(graphic: ProcGraphic): Dim =
  ##  ``Return`` the ``graphic``'s dimensions if available, or `nil` otherwise.
  ##
  if graphic.dimProcedure == nil:
    return (0, 0)
  else:
    return graphic.dimProcedure()


method draw*(graphic: ProcGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  if graphic.procedure == nil:
    return
  graphic.procedure(graphic, pos, angle, scale, center, flip, region)

