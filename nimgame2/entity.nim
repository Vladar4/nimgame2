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
  Animation = object
    frames*: seq[int]
    frameRate*: float
    looped*: bool
    flip*: Flip


  Sprite = ref object
    animationKeys*: seq[string]
    animations*: seq[Animation]
    currentAnimation*: int
    currentFrame*: int
    time*: float
    playing*: bool
    frameSize*: Dim
    offset*: Dim
    frames*: seq[Rect]


  Entity* = ref object of RootObj
    tags*: seq[string]
    graphic*: Graphic
    sprite*: Sprite
    logic*: Logic
    physics*: Physics
    pos*, vel*, acc*, drg*: Coord ##  velocity, acceleration, drag
    center*: Coord                ##  Center for drawing and rotating
    # RenderEx
    renderEx*: bool               ##  render with rotation and flip status
    rot*: Angle                   ##  rotation angle
    rotVel*, rotAcc*, rotDrg*: float  ##  rotation velocity, acceleration, drag
    rotCentered*: bool            ##  `true` if rotation anchor is in center
    flip*: Flip                   ##  texture flip status

  Logic* = ref object of RootObj

  Physics* = ref object of RootObj


##########
# Sprite #
##########

proc initSprite*(entity: Entity,
                 frameSize: Dim,
                 offset: Dim = (0, 0)) =
  ##  Creeate a sprite for a given ``entity`` with attached Graphic.
  ##
  ##  ``frameSize`` Dimensions of one frame.
  ##
  ##  ``offset``  Offset from the edge of the texture.
  ##
  entity.sprite = new Sprite
  entity.sprite.animationKeys = @[]
  entity.sprite.animations = @[]
  entity.sprite.currentAnimation = -1
  entity.sprite.currentFrame = 0
  entity.sprite.time = 0
  entity.sprite.playing = false
  entity.sprite.frameSize = frameSize
  entity.sprite.offset = offset
  entity.sprite.frames = @[]

  var cols = (entity.graphic.w - entity.sprite.offset.w) div
              entity.sprite.frameSize.w
  var rows = (entity.graphic.h - entity.sprite.offset.h) div
              entity.sprite.frameSize.h

  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      entity.sprite.frames.add(Rect(
        x: entity.sprite.offset.w + entity.sprite.frameSize.w * c,
        y: entity.sprite.offset.h + entity.sprite.frameSize.h * r,
        w: entity.sprite.frameSize.w,
        h: entity.sprite.frameSize.h))


proc animationIndex*(entity: Entity, name: string): int {.inline.} =
  if entity.sprite == nil:
    return -1
  entity.sprite.animationKeys.find(name)


proc animation*(entity: Entity, name: string): var Animation =
  let index = entity.animationIndex(name)
  if index < 0:
    return
  entity.sprite.animations[index]


proc animation*(entity: Entity, index: int): var Animation =
  if index < 0 or index >= entity.sprite.animations.len:
    return
  entity.sprite.animations[index]


template animation*(entity: Entity): var Animation =
  entity.animation(entity.sprite.currentAnimation)


proc addAnimation*(entity: Entity,
                   name: string,
                   frames: openarray[int],
                   frameRate: float = 0.1,
                   looped: bool = false,
                   flip: Flip = Flip.none): bool =
  result = true

  if entity.sprite == nil:
    return false

  if frames.len < 1:
    return false

  if entity.animationIndex(name) >= 0:
    return false

  for frame in frames:
    if frame < 0 or frame >= entity.sprite.frames.len:
      return false

  entity.sprite.animationKeys.add(name)
  entity.sprite.animations.add(Animation(
    frames: @frames, frameRate: frameRate, looped: looped, flip: flip))



proc play*(entity: Entity, anim: string) =
  if entity.sprite == nil:
    return
  if entity.animationIndex(anim) < 0:
    return
  entity.sprite.currentAnimation = entity.animationIndex(anim)
  entity.sprite.time = 0.0
  entity.sprite.playing = true


method update*(sprite: Sprite, entity: Entity, elapsed: float) {.base.} =
  if entity.sprite == nil:
    return
  if (entity.sprite.currentAnimation < 0) or (not entity.sprite.playing):
    return
  let frameRate = entity.animation.frameRate
  entity.sprite.time += elapsed
  while entity.sprite.time >= frameRate:
    entity.sprite.time -= frameRate
    inc entity.sprite.currentFrame
    if entity.sprite.currentFrame >= entity.animation.frames.len:
      if not entity.animation.looped:
        entity.sprite.playing = false
      entity.sprite.currentFrame = 0


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
  entity.pos = entity.pos + entity.vel * elapsed

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
  entity.tags = @[]
  entity.graphic = nil
  entity.sprite = nil
  entity.logic = nil
  entity.physics = nil
  entity.pos = (0.0, 0.0)
  entity.vel = (0.0, 0.0)
  entity.acc = (0.0, 0.0)
  entity.drg = (0.0, 0.0)
  entity.center = (0.0, 0.0)
  entity.renderEx = false
  entity.rot = 0.0
  entity.rotVel = 0.0
  entity.rotAcc = 0.0
  entity.rotDrg = 0.0
  entity.rotCentered = true
  entity.flip = Flip.none


proc renderEntity*(entity: Entity, renderer: sdl.Renderer) =
  ##  Default entity render procedure.
  ##
  ##  Call it from your entity render method.
  ##
  if not (entity.graphic == nil):
    if not (entity.sprite == nil):
      if entity.sprite.currentAnimation < 0:
        entity.graphic.drawEx(renderer, entity.pos - entity.center,
                              entity.sprite.frameSize,
                              entity.sprite.frames[0],
                              entity.rot, entity.rotCentered, entity.center,
                              entity.flip)
      else:
        let anim = entity.animation
        entity.graphic.drawEx(renderer, entity.pos - entity.center,
                              entity.sprite.frameSize,
                              entity.sprite.frames[
                                anim.frames[entity.sprite.currentFrame]],
                              entity.rot, entity.rotCentered, entity.center,
                              anim.flip)
    elif not entity.renderEx:
      entity.graphic.draw(renderer, entity.pos - entity.center)
    else:
      entity.graphic.drawEx(renderer, entity.pos - entity.center,
                            entity.rot, entity.rotCentered, entity.center,
                            entity.flip)


method render*(entity: Entity, renderer: sdl.Renderer) {.base.} =
  entity.renderEntity(renderer)


proc updateEntity*(entity: Entity, elapsed: float) =
  ##  Default entity update procedure.
  ##
  ##  Call it from your entity update method.
  ##
  if not(entity.sprite == nil):
    entity.sprite.update(entity, elapsed)
  if not(entity.logic == nil):
    entity.logic.update(entity, elapsed)
  if not(entity.physics == nil):
    entity.physics.update(entity, elapsed)


method update*(entity: Entity, elapsed: float) {.base.} =
  entity.updateEntity(elapsed)

