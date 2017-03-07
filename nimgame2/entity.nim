# nimgame2/entity.nim
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
  graphic, types, utils


type
  Animation = object
    frames*: seq[int] ##  List of animation's frame indexes
    frameRate*: float ##  Frame rate (in frames per second)
    flip*: Flip       ##  Flip flag


  Sprite = ref object
    animationKeys*: seq[string] ##  List of animation names
    animations*: seq[Animation] ##  List of animations
    currentAnimation*: int      ##  Index of currently playing animation
    currentFrame*: int          ##  Incex of current frame
    cycles*: int                ##  Animation cycles counter (`-1` for looping)
    kill*: bool                 ##  Kill when animation is finished
    time*: float                ##  Animation timer
    playing*: bool              ##  Animation playing flag
    dim*: Dim                   ##  Sprite frame dimensions
    offset*: Dim                ##  Sprite graphic offset
    frames*: seq[Rect]          ##  Frames' coordinates


  Collider* = ref object of RootObj
    parent*: Entity
    tags*: seq[string]  ##  only check collisios with entities with given tags
    pos*: Coord

  BoxCollider* = ref object of Collider
    dim*: Dim

  CircleCollider* = ref object of Collider
    radius*: float

  LineCollider* = ref object of Collider
    pos2*: Coord

  PolyCollider* = ref object of Collider
    points*: seq[Coord]


  Entity* = ref object of RootObj
    parent*: Entity               ##  Parent entity reference
    tags*: seq[string]            ##  List of entity tags
    dead*: bool                   ##  `true` if marked for removal
    fLayer: int                   ##  Rendering layer
    updLayer*: bool               ##  `true` if entity's layer was changed
    graphic*: Graphic
    sprite*: Sprite
    logic*: Logic
    physics*: Physics
    collider*: Collider
    colliding*: seq[Entity]       ##  List of Entities currently colliding with
    pos*, vel*, acc*, drg*: Coord ##  Position, velocity, acceleration, drag
    rot*: Angle                   ##  Rotation angle in degrees
    rotVel*, rotAcc*, rotDrg*: Angle  ##  Rotation velocity, acceleration, drag
    parallax*, scale*: Scale      ##  Parallax and scale ratio
    center*: Coord                ##  Center for drawing and rotating
    flip*: Flip                   ##  Texture flip status
    visible*: bool                ##  Visibility status

  Logic* = ref object of RootObj

  Physics* = ref object of RootObj


#========#
# Sprite #
#========#

proc initSprite*(entity: Entity,
                 dim: Dim,
                 offset: Dim = (0, 0)) =
  ##  Creeate a sprite for the given ``entity`` with the attached Graphic.
  ##
  ##  ``dim`` dimensions of one frame.
  ##
  ##  ``offset``  offset from the edge of the texture.
  ##
  entity.sprite = new Sprite
  entity.sprite.animationKeys = @[]
  entity.sprite.animations = @[]
  entity.sprite.currentAnimation = -1
  entity.sprite.currentFrame = 0
  entity.sprite.cycles = 0
  entity.sprite.kill = false
  entity.sprite.time = 0
  entity.sprite.playing = false
  entity.sprite.dim = dim
  entity.sprite.offset = offset
  entity.sprite.frames = @[]

  let
    cols = (entity.graphic.w - entity.sprite.offset.w) div
            entity.sprite.dim.w
    rows = (entity.graphic.h - entity.sprite.offset.h) div
            entity.sprite.dim.h

  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      entity.sprite.frames.add(Rect(
        x: entity.sprite.offset.w + entity.sprite.dim.w * c,
        y: entity.sprite.offset.h + entity.sprite.dim.h * r,
        w: entity.sprite.dim.w,
        h: entity.sprite.dim.h))


proc copy(target, source: Sprite) =
  ##  Copy ``source``'s properties and animations to the other sprite.
  ##
  ##  No new objects will be allocated.
  ##
  target.animationKeys = @[]
  for key in source.animationKeys:
    target.animationKeys.add(key)
  target.animations = @[]
  for anim in source.animations:
    target.animations.add(anim)
  target.currentAnimation = source.currentAnimation
  target.currentFrame     = source.currentFrame
  target.cycles           = source.cycles
  target.kill             = source.kill
  target.time             = source.time
  target.playing          = source.playing
  target.dim              = source.dim
  target.offset           = source.offset
  target.frames = @[]
  for frame in source.frames:
    target.frames.add(frame)



proc animationIndex*(entity: Entity, name: string): int {.inline.} =
  ##  ``Return`` the index of the animation named ``name``.
  ##
  if entity.sprite == nil:
    return -1
  entity.sprite.animationKeys.find(name)


proc animation*(entity: Entity, name: string): var Animation =
  ##  ``Return`` the animation named ``name``.
  ##
  let index = entity.animationIndex(name)
  if index < 0:
    return
  entity.sprite.animations[index]


proc animation*(entity: Entity, index: int): var Animation =
  ##  ``Return`` the animation under given ``index``.
  ##
  if index < 0 or index >= entity.sprite.animations.len:
    return
  entity.sprite.animations[index]


template currentAnimation*(entity: Entity): var Animation =
  ##  ``Return`` the current animation.
  ##
  entity.animation(entity.sprite.currentAnimation)


proc currentAnimationName*(entity: Entity): string =
  ##  ``Return`` the name of the current animation.
  ##
  if entity.sprite.currentAnimation < 0:
    return ""
  return entity.sprite.animationKeys[entity.sprite.currentAnimation]


proc addAnimation*(entity: Entity,
                   name: string,
                   frames: openarray[int],
                   frameRate: float = 0.1,
                   flip: Flip = Flip.none): bool =
  ##  Add animation to the ``entity``.
  ##
  ##  ``name`` name of the animation.
  ##
  ##  ``frames``  array of animation frames' indexes.
  ##
  ##  ``frameRate`` animation speed in seconds per frame.
  ##
  ##  ``flip``  animation flip flag.
  ##
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
    frames: @frames, frameRate: frameRate, flip: flip))



proc play*(entity: Entity, anim: string, cycles = -1, kill: bool = false) =
  ##  Start playing the animation.
  ##
  ##  ``anim``  name of the animation.
  ##
  ##  ``cycles``  number of times to repeat the animation, or `-1` for looping.
  ##
  ##  ``kill``  kill when finished.
  ##
  if entity.sprite == nil:
    return
  if entity.animationIndex(anim) < 0:
    return
  entity.visible = true
  entity.sprite.currentAnimation = entity.animationIndex(anim)
  entity.sprite.cycles = cycles
  entity.sprite.kill = kill
  entity.sprite.time = 0.0
  if cycles != 0:
    entity.sprite.playing = true


method update*(sprite: Sprite, entity: Entity, elapsed: float) {.base.} =
  if entity.sprite == nil:
    return
  if (entity.sprite.currentAnimation < 0) or (not entity.sprite.playing):
    return
  let frameRate = entity.currentAnimation.frameRate
  entity.sprite.time += elapsed
  while entity.sprite.time >= frameRate:
    entity.sprite.time -= frameRate
    inc entity.sprite.currentFrame  # next frame
    if entity.sprite.currentFrame >= entity.currentAnimation.frames.len:
      # Animation has ended
      if entity.sprite.cycles > 0:
        # Reduce cycles counter
        dec entity.sprite.cycles
        if entity.sprite.cycles == 0:
          # No more cycles left
          entity.sprite.playing = false
          # Check if entity need to be killed
          if entity.sprite.kill:
            entity.dead = true
            entity.visible = false
      # cycles <= 0 - animation either stopped or looped
      # Set current frame to first one of the current animation
      entity.sprite.currentFrame = 0


#=======#
# Logic #
#=======#

method update*(logic: Logic, entity: Entity, elapsed: float) {.base.} =
  discard


#=========#
# Physics #
#=========#


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


#========#
# Entity #
#========#


proc initEntity*(entity: Entity) =
  ##  Default entity initialization procedure.
  ##
  ##  Call it after creating a new entity.
  ##
  entity.parent = nil
  entity.tags = @[]
  entity.dead = false
  entity.fLayer = 0
  entity.updLayer = false
  entity.graphic = nil
  entity.sprite = nil
  entity.logic = nil
  entity.physics = nil
  entity.collider = nil
  entity.colliding = @[]
  entity.pos = (0.0, 0.0)
  entity.vel = (0.0, 0.0)
  entity.acc = (0.0, 0.0)
  entity.drg = (0.0, 0.0)
  entity.rot = 0.0
  entity.rotVel = 0.0
  entity.rotAcc = 0.0
  entity.rotDrg = 0.0
  entity.parallax = 1.0
  entity.scale = 1.0
  entity.center = (0.0, 0.0)
  entity.flip = Flip.none
  entity.visible = true


proc newEntity*(): Entity =
  result = new Entity
  result.initEntity()


proc layer*(entity: Entity): int {.inline.} =
  ##  ``Return`` current rendering layer of the ``entity``.
  ##
  return entity.fLayer


proc `layer=`*(entity: Entity, val: int) =
  ##  Change the rendering layer of the ``entity``.
  ##
  entity.fLayer = val
  entity.updLayer = true


proc copy*(target, source: Entity) =
  ##  Copy ``source``'s properties to the other entity.
  ##
  ##  No new objects will be allocated.
  ##
  target.parent   = source.parent
  target.tags     = @[]
  for tag in source.tags:
    target.tags.add(tag)
  target.dead     = source.dead
  target.fLayer   = source.layer
  target.updLayer = source.updLayer
  target.graphic  = source.graphic
  target.sprite   = new Sprite
  target.sprite.copy(source.sprite)
  target.logic    = source.logic
  target.physics  = source.physics
  target.collider = source.collider
  target.colliding = @[]
  for e in source.colliding:
    target.colliding.add(e)
  target.pos      = source.pos
  target.vel      = source.vel
  target.acc      = source.acc
  target.drg      = source.drg
  target.rot      = source.rot
  target.rotVel   = source.rotVel
  target.rotAcc   = source.rotAcc
  target.rotDrg   = source.rotDrg
  target.scale    = source.scale
  target.center   = source.center
  target.flip     = source.flip
  target.visible  = source.visible


proc absRot*(entity: Entity): Angle =
  ##  ``Return`` the absolute (counting the parent's) rotation angle
  ##  of the ``entity``.
  ##
  if entity.parent == nil:
    return entity.rot
  else:
    return entity.parent.absRot + entity.rot


proc absScale*(entity: Entity): Scale =
  ##  ``Return`` the absolute (counting the parent's) scale
  ##  of the ``entity``.
  ##
  if entity.parent == nil:
    return entity.scale
  else:
    return entity.parent.absScale * entity.scale


proc absPos*(entity: Entity): Coord =
  ##  ``Return`` the absolute (counting the parent's) scale
  ##  of the ``entity``.
  ##
  if entity.parent == nil:
    return entity.pos
  else:
    if entity.parent.absRot == 0:
      return
        entity.parent.absPos * entity.parallax + entity.pos * entity.absScale
    else:
      return
        rotate(entity.pos * entity.absScale,
               entity.parent.absPos * entity.parallax,
               entity.absRot)


proc centrify*(entity: Entity, hor = HAlign.center, ver = VAlign.center) =
  ##  Set ``entity``'s ``center``, according to the given align.
  ##
  ##  ``hor`` Horisontal align: left, center, or right
  ##
  ##  ``ver`` Vertical align: top, center, or bottom
  ##
  if entity.graphic == nil:
    return

  var dim = if entity.sprite == nil:
              entity.graphic.dim
            else:
              entity.sprite.dim

  # horisontal align
  entity.center.x = case hor:
  of HAlign.left:   0.0
  of HAlign.center: dim.w / 2
  of HAlign.right:  dim.w.float - 1

  # vertical align
  entity.center.y = case ver:
  of VAlign.top:    0.0
  of VAlign.center: dim.h / 2
  of VAlign.bottom: dim.h.float - 1


method event*(entity: Entity, e: sdl.Event) {.base.} = discard


proc renderEntity*(entity: Entity) =
  ##  Default entity render procedure.
  ##
  ##  Call it from your entity render method.
  ##
  if not (entity.graphic == nil) and entity.visible:
    if entity.sprite == nil:
      entity.graphic.draw(entity.absPos,
                          entity.absRot,
                          entity.absScale,
                          entity.center,
                          entity.flip)
    else: # entity.sprite != nil
      if entity.sprite.currentAnimation < 0:
        entity.graphic.draw(entity.absPos,
                            entity.absRot,
                            entity.absScale,
                            entity.center,
                            entity.flip,
                            entity.sprite.frames[entity.sprite.currentFrame])
      else:
        let anim = entity.currentAnimation
        entity.graphic.draw(entity.absPos,
                            entity.absRot,
                            entity.absScale,
                            entity.center,
                            Flip(entity.flip.cint xor anim.flip.cint),
                            entity.sprite.frames[
                              anim.frames[entity.sprite.currentFrame]])


method render*(entity: Entity) {.base.} =
  entity.renderEntity()


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


method onCollide*(entity, target: Entity) {.base.} =
  ##  Called when ``entity`` collides with ``target``.
  ##
  discard

