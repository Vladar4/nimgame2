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
    pos*, vel*, acc*, drg*: Coord ##  position, velocity, acceleration, drag
    # RenderEx
    renderEx*: bool               ##  render with rotation and flip status
    rot*: Angle                   ##  rotation angle
    rotVel*, rotAcc*, rotDrg*: float  ##  rotation velocity, acceleration, drag
    rotCentered*: bool            ##  `true` if rotation anchor is in center
    rotAnchor*: Coord             ##  rotation anchor position
    flip*: Flip                   ##  texture flip status

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


proc updatePhysics*(physics: Physics, entity: Entity, elapsed: float) =
  ##  Default physics procedure. Disabled by default.
  ##
  ##  Call it from your entity physics update method.
  ##

  # acceleration -> velocity
  entity.vel.x += entity.acc.x * elapsed
  entity.vel.y += entity.acc.y * elapsed

  # drag -> velocity
  let absx = entity.vel.x.abs
  if absx > 0.0:
    var dx = entity.drg.x * elapsed
    if dx > absx:
      entity.vel.x = 0.0
    else:
      entity.vel.x += (if entity.vel.x > 0.0: -dx else: dx)

  let absy = entity.vel.y.abs
  if absy > 0.0:
    var dy = entity.drg.y * elapsed
    if dy > absy:
      entity.vel.y = 0.0
    else:
      entity.vel.y += (if entity.vel.y > 0.0: -dy else: dy)

  # velocity -> position
  entity.pos.x += entity.vel.x * elapsed
  entity.pos.y += entity.vel.y * elapsed

  # rotation acceleration -> rotation velocity
  entity.rotVel += entity.rotAcc * elapsed

  # rotation drag -> rotation velocity
  let absr = entity.rotVel.abs
  if absr > 0.0:
    var dr = entity.rotDrg * elapsed
    if dr > absr:
      entity.rotVel = 0.0
    else:
      entity.rotVel += (if entity.rotVel > 0.0: -dr else: dr)

  # rotatiton velocity -> rotation
  entity.rot += entity.rotVel * elapsed


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
  entity.drg = (0.0, 0.0)
  entity.renderEx = false
  entity.rot = 0.0
  entity.rotVel = 0.0
  entity.rotAcc = 0.0
  entity.rotDrg = 0.0
  entity.rotCentered = true
  entity.rotAnchor = (0.0, 0.0)
  entity.flip = Flip.none


proc renderEntity*(entity: Entity, renderer: sdl.Renderer) =
  ##  Default entity render procedure.
  ##
  ##  Call it from your entity render method.
  ##
  if not (entity.graphic == nil):
    if not entity.renderEx:
      entity.graphic.draw(renderer, entity.pos)
    else:
      entity.graphic.drawEx(renderer, entity.pos, entity.rot,
                            entity.rotCentered, entity.rotAnchor,
                            entity.flip)


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
