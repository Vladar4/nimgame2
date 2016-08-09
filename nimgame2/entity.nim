# nimgame2/entity.nim
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
  sdl2/sdl,
  graphic, scene, types

type
  Entity* = ref object of RootObj
    graphic*: Graphic
    logic*: Logic
    physics*: Physics
    pos*, vel*, acc*: Coord     ##  position, velocity, acceleration
    rot*: Angle                 ##  rotation angle
    rotVel*, rotAcc: float      ##  rotation velocity, rotation acceleration
    rotCentered*: bool          ##  `true` if rotation anchor is in center
    rotAnchor*: Coord           ##  rotation anchor position
    flip*: Flip                 ##  texture flip status

  Logic* = ref object of RootObj

  Physics* = ref object of RootObj


#########
# Logic #
#########

method update*(logic: Logic, entity: Entity, elapsed: float) {.base.} =
  discard


###########
# Physics #
###########

method update*(physics: Physics, entity: Entity, elapsed: float) {.base.} =
  discard


##########
# Entity #
##########


proc initEntity*(entity: Entity) =
  ##  Default entity initialization procedure.
  ##
  ##  Call it after creating a new entity.
  ##
  entity.graphic = nil
  entity.logic = nil
  entity.physics = nil
  entity.pos = (0.0, 0.0)
  entity.vel = (0.0, 0.0)
  entity.acc = (0.0, 0.0)
  entity.rot = 0.0
  entity.rotVel = 0.0
  entity.rotAcc = 0.0
  entity.rotCentered = true
  entity.rotAnchor = (0.0, 0.0)
  entity.flip = Flip.none


proc renderEntity*(entity: Entity, renderer: sdl.Renderer) =
  ##  Default entity render procedure.
  ##
  ##  Call it from your entity render method.
  ##
  if not (entity.graphic == nil):
    entity.graphic.draw(renderer, entity.pos)


method render*(entity: Entity, renderer: sdl.Renderer) {.base.} =
  entity.renderEntity(renderer)


proc updateEntity*(entity: Entity, elapsed: float) =
  ##  Default entity update procedure.
  ##
  ##  Call it from your entity update method.
  ##
  if not(entity.logic == nil):
    entity.logic.update(entity, elapsed)
  if not(entity.physics == nil):
    entity.physics.update(entity, elapsed)


method update*(entity: Entity, elapsed: float) {.base.} =
  entity.updateEntity(elapsed)
