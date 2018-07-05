# nimgame2/entity.nim
# Copyright (c) 2016-2018 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl,
  draw, graphic, settings, types, utils


type
  Animation* = object
    # Public
    frames*: seq[int] ##  List of animation's frame indexes
    frameRate*: float ##  Frame rate (in seconds per frame)
    flip*: Flip       ##  Flip flag

  AnimationCallback* = proc(entity: Entity, index: int) ##  \
    ##  Called after animation is finished (see ``play()`` procedure).
    ##
    ##  ``index`` The index of the finished animation.

  Sprite* = ref object
    # Public
    animationKeys*: seq[string] ##  List of animation names
    animations*: seq[Animation] ##  List of animations
    currentAnimationIndex*: int ##  Index of currently playing animation
    currentFrame*: int          ##  Index of current frame in currentAnimation \
      ## (or in ``frames``, if no currentAnimation is set)
    cycles*: int                ##  Animation cycles counter (`-1` for looping)
    kill*: bool                 ##  Kill when animation is finished
    callback*: AnimationCallback##  Call this when animation is finished
    time*: float                ##  Animation timer
    playing*: bool              ##  Animation playing flag
    dim*: Dim                   ##  Sprite frame dimensions
    frames*: seq[Rect]          ##  Frames' coordinates


  Collider* = ref object of RootObj
    # Public
    parent*: Entity
    tags*: seq[string]  ##  only check collisios with entities with given tags
    pos*: Coord

  BoxCollider* = ref object of Collider
    # Public
    dim*: Dim

  CircleCollider* = ref object of Collider
    # Public
    radius*: float

  LineCollider* = ref object of Collider
    # Public
    pos2*: Coord

  PolyCollider* = ref object of Collider
    # Private
    farthest: float
    # Public
    points*: seq[Coord]

  GroupCollider* = ref object of Collider
    # Public
    list*: seq[Collider]


  Entity* = ref object of RootObj
    # Private
    fLayer: int                   ##  Rendering layer
    fBlinkTimer: float            ##  Used internally for blinking
    # Public
    parent*: Entity               ##  Parent entity reference
    tags*: seq[string]            ##  List of entity tags
    dead*: bool                   ##  `true` if marked for removal
    updLayer*: bool               ##  `true` if entity's layer was changed
    graphic*: Graphic
    sprite*: Sprite
    logic*: LogicProc
    physics*: PhysicsProc
    fastPhysics*: bool            ##  rough and fast physics flag
    collisionEnvironment*: seq[Entity]  ## List of collidable entites
                                        ## used in some physics procedures
    collider*: Collider
    colliding*: seq[Entity]       ##  List of Entities currently colliding with
    pos*, vel*, acc*, drg*: Coord ##  Position, velocity, acceleration, drag
    rot*: Angle                   ##  Rotation angle in degrees
    rotVel*, rotAcc*, rotDrg*: Angle  ##  Rotation velocity, acceleration, drag
    parallax*, scale*: Scale      ##  Parallax and scale ratio
    scaleVel*, scaleAcc*, scaleDrg*: Scale ## Scale's velocity, accel., and drag
    center*: Coord                ##  Center for drawing and rotating
    flip*: Flip                   ##  Texture flip status
    visible*: bool                ##  Visibility status
    blinking*: bool               ##  Blinking status
    blinkOn*, blinkOff*: float    ##  Blinking rate (in seconds)

  LogicProc* = proc(entity: Entity, elapsed: float)

  PhysicsProc* = proc(entity: Entity, elapsed: float)


#========#
# Sprite #
#========#

proc initSprite*(entity: Entity,
                 dim: Dim,
                 offset: Dim = (0, 0),
                 border: Dim = (0, 0)) =
  ##  Creeate a sprite for the given ``entity`` with the attached Graphic.
  ##
  ##  ``dim`` dimensions of one frame.
  ##
  ##  ``offset``  offset from the edge of the texture.
  ##
  ##  ``border``  border around individual frames.
  ##
  entity.sprite = new Sprite
  entity.sprite.animationKeys = @[]
  entity.sprite.animations = @[]
  entity.sprite.currentAnimationIndex = -1
  entity.sprite.currentFrame = 0
  entity.sprite.cycles = 0
  entity.sprite.kill = false
  entity.sprite.callback = nil
  entity.sprite.time = 0
  entity.sprite.playing = false
  entity.sprite.dim = dim
  entity.sprite.frames = @[]

  let
    cols = (entity.graphic.w - offset.w) div
            (entity.sprite.dim.w + 2 * border.w)
    rows = (entity.graphic.h - offset.h) div
            (entity.sprite.dim.h + 2 * border.h)

  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      entity.sprite.frames.add(Rect(
        x: offset.w + entity.sprite.dim.w * c + border.w * (1 + c * 2),
        y: offset.h + entity.sprite.dim.h * r + border.h * (1 + r * 2),
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
  target.currentAnimationIndex = source.currentAnimationIndex
  target.currentFrame     = source.currentFrame
  target.cycles           = source.cycles
  target.kill             = source.kill
  target.callback         = source.callback
  target.time             = source.time
  target.playing          = source.playing
  target.dim              = source.dim
  target.frames = @[]
  for frame in source.frames:
    target.frames.add(frame)


proc animationIndex*(sprite: Sprite, name: string): int {.inline.} =
  ##  ``Return`` the index of the animation named ``name``.
  ##
  if sprite == nil:
    -1
  else:
    sprite.animationKeys.find(name)


template animationIndex*(entity: Entity, name: string): int =
  ##  ``Return`` the index of the animation named ``name``.
  ##
  entity.sprite.animationIndex(name)


proc animation*(sprite: Sprite, name: string): var Animation =
  ##  ``Return`` the animation named ``name``.
  ##
  if sprite == nil:
    return
  let index = sprite.animationIndex(name)
  if index < 0:
    return
  sprite.animations[index]


template animation*(entity: Entity, name: string): var Animation =
  ##  ``Return`` the animation named ``name``.
  ##
  entity.sprite.animation(name)


proc animation*(sprite: Sprite, index: int): var Animation =
  ##  ``Return`` the animation under given ``index``.
  ##
  if sprite == nil:
    return
  if index < 0 or index >= sprite.animations.len:
    return
  sprite.animations[index]


template animation*(entity: Entity, index: int): var Animation =
  ##  ``Return`` the animation under given ``index``.
  ##
  entity.sprite.animation(index)


template currentAnimationIndex*(entity: Entity): int =
  if entity.sprite == nil:
    -1
  else:
    entity.sprite.currentAnimationIndex


proc currentAnimation*(sprite: Sprite): var Animation =
  ##  ``Return`` the current animation.
  ##
  if sprite == nil:
    return
  sprite.animation(sprite.currentAnimationIndex)


template currentAnimation*(entity: Entity): var Animation =
  ##  ``Return`` the current animation.
  ##
  entity.sprite.currentAnimation()


proc currentAnimationName*(sprite: Sprite): string =
  ##  ``Return`` the name of the current animation, or empty string if none.
  ##
  if sprite == nil:
    return ""
  if sprite.currentAnimationIndex < 0:
    return ""
  return sprite.animationKeys[sprite.currentAnimationIndex]



template currentAnimationName*(entity: Entity): string =
  ##  ``Return`` the name of the current animation or empty string if none.
  ##
  entity.sprite.currentAnimationName()


proc changeFramerate*(sprite: Sprite, frameRate: float = 0.1) =
  ##  Change framerate for all created animations.
  ##
  if sprite == nil:
    return
  for i in 0..sprite.animations.high:
    sprite.animations[i].frameRate = frameRate


template changeFramerate*(entity: Entity, frameRate: float = 0.1) =
  ##  Change framerate for all created animations.
  ##
  entity.sprite.changeFramerate(frameRate)


proc addAnimation*(sprite: Sprite,
                   name: string,
                   frames: openarray[int],
                   frameRate: float = 0.1,
                   flip: Flip = Flip.none): bool =
  ##  Add a new animation to the ``sprite``.
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

  if (sprite == nil) or (frames.len < 1):
    return false

  if sprite.animationIndex(name) >= 0:
    return false

  for frame in frames:
    if frame < 0 or frame >= sprite.frames.len:
      return false

  sprite.animationKeys.add(name)
  sprite.animations.add(Animation(
    frames: @frames, frameRate: frameRate, flip: flip))


template addAnimation*(entity: Entity,
                       name: string,
                       frames: openarray[int],
                       frameRate: float = 0.1,
                       flip: Flip = Flip.none): bool =
  ##  Add a new animation to the ``entity``.
  ##
  ##  ``name`` name of the animation.
  ##
  ##  ``frames``  array of animation frames' indexes.
  ##
  ##  ``frameRate`` animation speed in seconds per frame.
  ##
  ##  ``flip``  animation flip flag.
  ##
  entity.sprite.addAnimation(name, frames, frameRate, flip)


proc play*(sprite: Sprite, anim: string, cycles = -1,
           kill: bool = false, callback: AnimationCallback = nil) =
  ##  Start playing the animation.
  ##
  ##  ``anim``  name of the animation.
  ##
  ##  ``cycles``  number of times to repeat the animation, or `-1` for looping.
  ##
  ##  ``kill``  kill when finished.
  ##
  ##  ``callback`` called when animation is finished.
  ##
  if sprite == nil:
    return
  if sprite.animationIndex(anim) < 0:
    return
  sprite.currentAnimationIndex = sprite.animationIndex(anim)
  sprite.cycles = cycles
  sprite.kill = kill
  sprite.callback = callback
  sprite.time = 0.0
  sprite.currentFrame = 0
  if cycles != 0:
    sprite.playing = true


template play*(entity: Entity, anim: string, cycles = -1,
               kill: bool = false, callback: AnimationCallback = nil) =
  ##  Start playing the animation.
  ##
  ##  ``anim``  name of the animation.
  ##
  ##  ``cycles``  number of times to repeat the animation, or `-1` for looping.
  ##
  ##  ``kill``  kill when finished.
  ##
  ##  ``callback`` called when animation is finished.
  ##
  entity.sprite.play(anim, cycles, kill, callback)


proc update(sprite: Sprite, entity: Entity, elapsed: float) =
  if (sprite.currentAnimationIndex < 0) or (not sprite.playing):
    return
  let frameRate = sprite.currentAnimation.frameRate
  sprite.time += elapsed
  while sprite.time >= frameRate:
    sprite.time -= frameRate
    inc sprite.currentFrame  # next frame
    if sprite.currentFrame >= sprite.currentAnimation.frames.len:
      # Animation has ended
      if sprite.cycles > 0:
        # Reduce cycles counter
        dec sprite.cycles
        if sprite.cycles == 0:
          # No more cycles left
          sprite.playing = false
          # Check if entity need to be killed
          if sprite.kill:
            entity.dead = true
            entity.visible = false
          # Check for the callback
          if not (sprite.callback == nil):
            sprite.callback(entity, entity.sprite.currentAnimationIndex)
      # cycles <= 0 - animation either stopped or looped
      # Set current frame to first one of the current animation
      sprite.currentFrame = 0


#=========#
# Physics #
#=========#

proc defaultPhysics*(entity: Entity, elapsed: float) =
  ##  Default physics procedure. Disabled by default.
  ##
  ##  Assign it as your entity's physics.
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
  entity.rot = (entity.rot + entity.rotVel * elapsed) mod 360.0

  # scale
  entity.scale += entity.scaleVel * elapsed
  entity.scaleVel += entity.scaleAcc * elapsed
  let abss = entity.scaleVel.abs
  if abss > 0.0:
    var dr = entity.scaleDrg * elapsed
    if dr > abss:
      entity.scaleVel = 0.0
    else:
      entity.scaleVel += (if entity.scaleVel > 0.0: -dr else: dr)


proc willCollide*(
  entity: Entity, pos: Coord, rot: Angle, scale: Scale, list: seq[Entity]): bool
proc platformerPhysics*(entity: Entity, elapsed: float) =
  ##  Platformer physics procedure.
  ##
  ##  Assign it as your entity's physics.
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
  var
    diffX = entity.vel.x * elapsed
    diffY = entity.vel.y * elapsed

  if entity.fastPhysics:

    # x
    if entity.willCollide(entity.pos + (diffX, 0.0), entity.rot, entity.scale,
        entity.collisionEnvironment):
      entity.vel.x = 0.0
    else:
      entity.pos.x += diffX

    # y
    if entity.willCollide(entity.pos + (0.0, diffY), entity.rot, entity.scale,
        entity.collisionEnvironment):
      entity.vel.y = 0.0
    else:
      entity.pos.y += diffY

  else:
    let
      stepX = diffX / abs(diffX)
      stepY = diffY / abs(diffY)

    # x
    while abs(diffX) >= 1.0:
      if entity.willCollide(entity.pos + (stepX, 0.0), entity.rot, entity.scale,
          entity.collisionEnvironment):
        entity.vel.x = 0.0
        break
      diffX -= stepX
      entity.pos.x += stepX

    # x remainder
    if entity.vel.x != 0.0:
      if entity.willCollide(entity.pos + (diffX, 0.0), entity.rot, entity.scale,
          entity.collisionEnvironment):
        entity.vel.x = 0.0
      else:
        entity.pos.x += diffX

    # y
    while abs(diffY) >= 1.0:
      if entity.willCollide(entity.pos + (0.0, stepY), entity.rot, entity.scale,
          entity.collisionEnvironment):
        entity.vel.y = 0.0
        break
      diffY -= stepY
      entity.pos.y += stepY

    # y remainder
    if entity.vel.y != 0.0:
      if entity.willCollide(entity.pos + (0.0, diffY), entity.rot, entity.scale,
          entity.collisionEnvironment):
        entity.vel.y = 0.0
      else:
        entity.pos.y += diffY


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
  entity.fBlinkTimer = 0.0
  entity.updLayer = false
  entity.graphic = nil
  entity.sprite = nil
  entity.logic = nil
  entity.physics = nil
  entity.collider = nil
  entity.colliding = @[]
  entity.fastPhysics = false
  entity.collisionEnvironment = @[]
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
  entity.scaleVel = 0.0
  entity.scaleAcc = 0.0
  entity.scaleDrg = 0.0
  entity.center = (0.0, 0.0)
  entity.flip = Flip.none
  entity.visible = true
  entity.blinking = false
  entity.blinkOn = 0.0
  entity.blinkOff = 0.0


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
  target.fBlinkTimer = source.fBlinkTimer
  target.updLayer = source.updLayer
  target.graphic  = source.graphic
  if source.sprite!=nil:
    target.sprite   = new Sprite
    target.sprite.copy(source.sprite)
  target.logic    = source.logic
  target.physics  = source.physics
  target.collider = source.collider
  target.colliding = @[]
  for e in source.colliding:
    target.colliding.add(e)
  target.fastPhysics = source.fastPhysics
  target.collisionEnvironment = source.collisionEnvironment
  target.pos      = source.pos
  target.vel      = source.vel
  target.acc      = source.acc
  target.drg      = source.drg
  target.rot      = source.rot
  target.rotVel   = source.rotVel
  target.rotAcc   = source.rotAcc
  target.rotDrg   = source.rotDrg
  target.scale    = source.scale
  target.scaleVel = source.scaleVel
  target.scaleAcc = source.scaleAcc
  target.scaleDrg = source.scaleDrg
  target.center   = source.center
  target.flip     = source.flip
  target.visible  = source.visible
  target.blinking = source.blinking
  target.blinkOn  = source.blinkOn
  target.blinkOff = source.blinkOff


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


template dim*(entity: Entity): Dim =
  ##  ``Return`` ``entity.sprite.dim`` if ``entity.sprite`` is not `nil`,
  ##  or ``entity.graphic.dim`` otherwise.
  (if entity.sprite == nil:
    entity.graphic.dim
  else:
    entity.sprite.dim)


proc centrify*(entity: Entity, hor = HAlign.center, ver = VAlign.center) =
  ##  Set ``entity``'s ``center``, according to the given align.
  ##
  ##  ``hor`` Horisontal align: left, center, or right
  ##
  ##  ``ver`` Vertical align: top, center, or bottom
  ##
  if entity.graphic == nil:
    return

  let
    dim = entity.dim
    oldCenter = entity.center

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

  # collider adjustment
  if entity.collider != nil:
    entity.collider.pos += oldCenter - entity.center


method event*(entity: Entity, e: sdl.Event) {.base.} = discard


proc renderEntity*(entity: Entity) =
  ##  Default entity render procedure.
  ##
  ##  Call it from your entity render method.
  ##
  if not (entity.graphic == nil) and entity.visible and
    ((entity.blinking and (entity.fBlinkTimer >= 0)) or (not entity.blinking)):
    if entity.sprite == nil:
      entity.graphic.draw(entity.absPos,
                          entity.absRot,
                          entity.absScale,
                          entity.center,
                          entity.flip)
    else: # entity.sprite != nil
      if entity.sprite.currentAnimationIndex < 0:
        entity.graphic.draw(entity.absPos,
                            entity.absRot,
                            entity.absScale,
                            entity.center,
                            entity.flip,
                            entity.sprite.frames[entity.sprite.currentFrame])
      else:
        let anim = entity.currentAnimation()
        entity.graphic.draw(entity.absPos,
                            entity.absRot,
                            entity.absScale,
                            entity.center,
                            Flip(entity.flip.cint xor anim.flip.cint),
                            entity.sprite.frames[
                              anim.frames[entity.sprite.currentFrame]])


method render*(entity: Entity) {.base.} =
  entity.renderEntity()


proc updateBlinking(entity: Entity, elapsed: float) =
  if entity.fBlinkTimer < 0:
    entity.fBlinkTimer += elapsed
    if entity.fBlinkTimer > 0:
      let remainder = entity.fBlinkTimer
      entity.fBlinkTimer = entity.blinkOn
      entity.updateBlinking(remainder)
  else:
    entity.fBlinkTimer -= elapsed
    if entity.fBlinkTimer < 0:
      let remainder = entity.fBlinkTimer
      entity.fBlinkTimer = -entity.blinkOff
      entity.updateBLinking(remainder)


proc updateEntity*(entity: Entity, elapsed: float) =
  ##  Default entity update procedure.
  ##
  ##  Call it from your entity update method.
  ##
  if not(entity.sprite == nil):
    entity.sprite.update(entity, elapsed)
  if not(entity.logic == nil):
    entity.logic(entity, elapsed)
  if not(entity.physics == nil):
    entity.physics(entity, elapsed)
  # blinking
  if entity.blinking and (entity.blinkOn > 0) and (entity.blinkOff > 0):
    entity.updateBlinking(elapsed)


method update*(entity: Entity, elapsed: float) {.base.} =
  entity.updateEntity(elapsed)


method onCollide*(entity, target: Entity) {.base.} =
  ##  Called when ``entity`` collides with ``target``.
  ##
  discard


#===========#
# Transform #
#===========#

template transform*(entity: Entity): Transform =
  ( pos: entity.absPos,
    angle: entity.absRot,
    scale: entity.absScale
  ).Transform


template `transform=`*(entity: Entity, transform: Transform) =
  entity.pos = transform.pos
  entity.rot = transform.angle
  entity.scale = transform.scale


template rect*(entity: Entity): Rect =
  entity.graphic.rect(entity.center * entity.scale)


template topleft*(entity: Entity): Coord =
  -entity.center


template topright*(entity: Entity): Coord =
  -entity.center + (entity.dim.w.toFloat, 0.0)


template bottomright*(entity: Entity): Coord =
  -entity.center + entity.dim.toCoord


template bottomleft*(entity: Entity): Coord =
  -entity.center + (0.0, entity.dim.h.toFloat)


template corners*(entity: Entity): untyped =
  [
    entity.topleft,
    entity.topright,
    entity.bottomright,
    entity.bottomleft,
  ]


template worldCorners*(entity: Entity): untyped =
  [
    entity.transform * entity.topleft,
    entity.transform * entity.topright,
    entity.transform * entity.bottomright,
    entity.transform * entity.bottomleft,
  ]


include private/collider

