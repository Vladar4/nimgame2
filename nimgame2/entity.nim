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
  math,
  sdl2/sdl,
  draw, graphic, settings, types, utils


type
  Animation* = object
    frames*: seq[int] ##  List of animation's frame indexes
    frameRate*: float ##  Frame rate (in seconds per frame)
    flip*: Flip       ##  Flip flag


  Sprite* = ref object
    animationKeys*: seq[string] ##  List of animation names
    animations*: seq[Animation] ##  List of animations
    currentAnimation*: int      ##  Index of currently playing animation
    currentFrame*: int          ##  Incex of current frame
    cycles*: int                ##  Animation cycles counter (`-1` for looping)
    kill*: bool                 ##  Kill when animation is finished
    time*: float                ##  Animation timer
    playing*: bool              ##  Animation playing flag
    dim*: Dim                   ##  Sprite frame dimensions
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

  Scene = ref object of RootObj
  Entity* = ref object of RootObj
    parent*: Entity               ##  Parent entity reference
    tags*: seq[string]            ##  List of entity tags
    dead*: bool                   ##  `true` if marked for removal
    fLayer: int                   ##  Rendering layer
    updLayer*: bool               ##  `true` if entity's layer was changed
    graphic*: Graphic
    sprite*: Sprite
    logic*: LogicProc
    physics*: PhysicsProc
    collisionEnvironment*: seq[Entity]  ## List of collidable entites
                                        ## used in some physics procedures
    collider*: Collider
    colliding*: seq[Entity]       ##  List of Entities currently colliding with
    pos*, vel*, acc*, drg*: Coord ##  Position, velocity, acceleration, drag
    rot*: Angle                   ##  Rotation angle in degrees
    rotVel*, rotAcc*, rotDrg*: Angle  ##  Rotation velocity, acceleration, drag
    parallax*, scale*: Scale      ##  Parallax and scale ratio
    center*: Coord                ##  Center for drawing and rotating
    flip*: Flip                   ##  Texture flip status
    visible*: bool                ##  Visibility status

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
  entity.sprite.currentAnimation = -1
  entity.sprite.currentFrame = 0
  entity.sprite.cycles = 0
  entity.sprite.kill = false
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
  target.currentAnimation = source.currentAnimation
  target.currentFrame     = source.currentFrame
  target.cycles           = source.cycles
  target.kill             = source.kill
  target.time             = source.time
  target.playing          = source.playing
  target.dim              = source.dim
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


proc changeFramerate*(entity: Entity, frameRate: float = 0.1) =
  ##  Change framerate for all created animations.
  ##
  for i in 0..entity.sprite.animations.high:
    entity.sprite.animations[i].frameRate = frameRate


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
  entity.sprite.currentFrame = 0
  if cycles != 0:
    entity.sprite.playing = true


proc update(sprite: Sprite, entity: Entity, elapsed: float) =
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
  entity.rot += entity.rotVel * elapsed


proc willCollide*(entity: Entity, pos: Coord, rot: Angle, scale: Scale): bool
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
  let
    diffX = entity.vel.x * elapsed
    diffY = entity.vel.y * elapsed
  # x
  if entity.willCollide(entity.pos + (diffX, 0.0), entity.rot, entity.scale):
    entity.vel.x = 0.0
  else:
    entity.pos.x = entity.pos.x + diffX
  # y
  if entity.willCollide(entity.pos + (0.0, diffY), entity.rot, entity.scale):
    entity.vel.y = 0.0
  else:
    entity.pos.y = entity.pos.y + diffY


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

  let
    dim = if entity.sprite == nil:
              entity.graphic.dim
            else:
              entity.sprite.dim
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
    entity.logic(entity, elapsed)
  if not(entity.physics == nil):
    entity.physics(entity, elapsed)


method update*(entity: Entity, elapsed: float) {.base.} =
  entity.updateEntity(elapsed)


method onCollide*(entity, target: Entity) {.base.} =
  ##  Called when ``entity`` collides with ``target``.
  ##
  discard
from fenv import epsilon
let Eps = epsilon(float)


#==================#
# Collider Private #
#==================#

template position(a: Collider): Coord =
  if a.parent.absRot == 0:
    (a.parent.absPos + a.pos * a.parent.absScale)
  else:
    rotate(a.pos * a.parent.absScale, a.parent.absPos, a.parent.absRot)


template scaled(n: float, a: Collider): float =
  (n * a.parent.absScale)


template scaled(n: int, a: Collider): int =
  int(n.float * a.parent.absScale)


template scaled(n: Coord, a: Collider): Coord =
  (n.x * a.parent.absScale, n.y * a.parent.absScale)


template left(b: BoxCollider): float =
  (b.position.x - b.dim.w.scaled(b) / 2)


template right(b: BoxCollider): float =
  (b.position.x + b.dim.w.scaled(b) / 2)


template top(b: BoxCollider): float =
  (b.position.y - b.dim.h.scaled(b) / 2)


template bottom(b: BoxCollider): float =
  (b.position.y + b.dim.h.scaled(b) / 2)


template pointInBox(p: Coord, b: BoxCollider): bool =
  ##  ``Return`` `true` if ``p`` is contained in ``b``, or `false` otherwise.
  ##
  ( ((p.x >= b.left) and (p.x <= b.right)) and
    ((p.y >= b.top) and (p.y <= b.bottom)) )


proc linesIntersect(p1, p2, p3, p4: Coord): bool =
  ##  ``Return`` `true` if line segment `p1`-`p2` intersects with `p3`-`p4`,
  ##  or `false` otherwise.
  ##
  let
    a = ( (p4.x - p3.x) * (p1.y - p3.y) -
          (p4.y - p3.y) * (p1.x - p3.x) ) /
        ( (p4.y - p3.y) * (p2.x - p1.x) -
          (p4.x - p3.x) * (p2.y - p1.y) )
    b = ( (p2.x - p1.x) * (p1.y - p3.y) -
          (p2.y - p1.y) * (p1.x - p3.x) ) /
        ( (p4.y - p3.y) * (p2.x - p1.x) -
          (p4.x - p3.x) * (p2.y - p1.y) )
  return ( a >= 0 and a <= 1 ) and (b >= 0 and b <= 1)


#==================#
# Coord collisions #
#==================#

# Coord - Coord
template collide*(pos1, pos2: Coord): bool =
  pos1 == pos2


# Coord - Point
method collide*(pos: Coord, a: Collider): bool {.base, inline.} =
  pos == a.position


# Coord - Box
method collide*(pos: Coord, b: BoxCollider): bool {.inline.} =
  pointInBox(pos, b)


# Coord - Circle
method collide*(pos: Coord, c: CircleCollider): bool {.inline.} =
  distance(pos, c.position) <= c.radius.scaled(c)


# Coord - Line
method collide*(pos: Coord, d: LineCollider): bool =
  let
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    pos1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    pos2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
  if distanceToLine(pos, pos1, pos2) >= 0.5:
    return false
  if distance(pos, pos1) + distance(pos, pos2) >= distance(pos1, pos2) + 0.5:
    return false
  else:
    return true


# Coord - Poly
method collide*(pos: Coord, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(pos, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(pos, LineCollider(parent: p.parent,
                                     pos: p.points[0],
                                     pos2: p.points[1]))
  else:
    let
      ppPosition = p.parent.absPos
      ppRotation = p.parent.absRot
    var
      i = 0
      j = p.points.high
      c = 0
    while i < p.points.len:
      let
        pi = rotate(p.points[i].scaled(p), ppPosition, ppRotation)
        pj = rotate(p.points[j].scaled(p), ppPosition, ppRotation)
      if ( ((pi.y <= pos.y) and (pos.y < pj.y)) or
          ((pj.y <= pos.y) and (pos.y < pi.y)) ) and
        ( pos.x < (pj.x - pi.x) * (pos.y - pi.y) / (pj.y - pi.y) + pi.x ):
        c = if c == 0: 1 else: 0
      # increment
      j = i
      inc i
    return c > 0


#==================#
# Collider (Point) #
#==================#

proc init*(a: Collider, parent: Entity, pos: Coord = (0, 0)) =
  a.parent = parent
  a.pos = pos
  a.tags = @[]


proc newCollider*(parent: Entity, pos: Coord = (0, 0)): Collider =
  result = new Collider
  result.init(parent, pos)


proc renderCollider*(a: Collider) =
  let
    pos = a.position
    rad = 4.0
  discard hline(pos - (rad, 0.0), 8, colliderOutlineColor)
  discard vline(pos - (0.0, rad), 8, colliderOutlineColor)
  discard circle(pos, rad, colliderOutlineColor)


method render*(a: Collider) {.base.} =
  a.renderCollider()


# Point - Coord
method collide*(a: Collider, pos: Coord): bool {.base, inline.} =
  return collide(pos, a)


# Point - Point
method collide*(a1, a2: Collider): bool {.base, inline.} =
  return collide(a1.position, a2.position)


# Point - Box
method collide*(a: Collider, b: BoxCollider): bool {.inline.} =
  return collide(a.position, b)


# Point - Circle
method collide*(a: Collider, c: CircleCollider): bool {.inline.} =
  return collide(a.position, c)


# Point - Line
method collide*(a: Collider, d: LineCollider): bool =
  return collide(a.position, d)


# Point - Poly
method collide*(a: Collider, p: PolyCollider): bool =
  return collide(a.position, p)


#=============#
# BoxCollider #
#=============#

proc init*(b: BoxCollider, parent: Entity, pos: Coord = (0, 0),
           dim: Dim = (0, 0)) =
  Collider(b).init(parent, pos)
  b.dim = dim


proc newBoxCollider*(parent: Entity, pos: Coord = (0, 0),
                     dim: Dim = (0, 0)): BoxCollider =
  result = new BoxCollider
  result.init(parent, pos, dim)


method render*(b: BoxCollider) =
  discard rect((b.left, b.top), (b.right, b.bottom), colliderOutlineColor)
  b.renderCollider()


# Box - Coord
method collide*(b: BoxCollider, pos: Coord): bool {.inline.} =
  return collide(pos, b)


# Box - Point
method collide*(b: BoxCollider, a: Collider): bool {.inline.} =
  return collide(a, b)


# Box - Box
method collide*(b1, b2: BoxCollider): bool =
  if b1.left > b2.right: return false
  if b1.right < b2.left: return false
  if b1.top > b2.bottom: return false
  if b1.bottom < b2.top: return false
  return true


# Box - Circle
method collide*(b: BoxCollider, c: CircleCollider): bool =
  let
    left = b.left
    right = b.right
    top = b.top
    bottom = b.bottom
    cpos = c.position
  var
    closest: Coord
  closest.x = if left > cpos.x: left
              elif right < cpos.x: right
              else: cpos.x
  closest.y = if top > cpos.y: top
              elif bottom < cpos.y: bottom
              else: cpos.y
  return distance(cpos, closest) < c.radius.scaled(c)


# Box - Line
method collide*(b: BoxCollider, d: LineCollider): bool =
  let
    b1 = (x: b.left, y: b.top)
    b2 = (b.right, b1.y)
    b3 = (b.right, b.bottom)
    b4 = (b1.x, b.bottom)
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    d1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    d2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
  if pointInBox(d1, b):
    return true
  elif pointInBox(d2, b):
    return true
  elif linesIntersect(b1, b2, d1, d2):
    return true
  elif linesIntersect(b2, b3, d1, d2):
    return true
  elif linesIntersect(b3, b4, d1, d2):
    return true
  else:
    return false


# Box - Poly
method collide*(b: BoxCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(b, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(b, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  else:
    var
      i = 0
      j = p.points.high
    while i < p.points.len:
      if collide(b, LineCollider(parent: p.parent,
                                pos: p.points[i],
                                pos2: p.points[j])):
        return true
      # increment
      j = i
      inc i
    return false


#================#
# CircleCollider #
#================#

proc init*(c: CircleCollider, parent: Entity, pos: Coord = (0, 0),
           radius: float = 0) =
  Collider(c).init(parent, pos)
  c.radius = radius


proc newCircleCollider*(parent: Entity, pos: Coord = (0, 0),
                        radius: float = 0): CircleCollider =
  result = new CircleCollider
  result.init(parent, pos, radius)


method render*(c: CircleCollider) =
  discard circle(c.position, c.radius.scaled(c), colliderOutlineColor)
  c.renderCollider()


# Circle - Coord
method collide*(c: CircleCollider, pos: Coord): bool {.inline.} =
  return collide(pos, c)


# Circle - Point
method collide*(c: CircleCollider, a: Collider): bool {.inline.} =
  return collide(a, c)


# Circle - Box
method collide*(c: CircleCollider, b: BoxCollider): bool {.inline.} =
  return collide(b, c)


# Circle - Circle
method collide*(c1, c2: CircleCollider): bool {.inline.} =
  return distance(c1.position, c2.position) <
         (c1.radius.scaled(c1) + c2.radius.scaled(c2))


# Circle - Line
method collide*(c: CircleCollider, d: LineCollider): bool =
  let
    cc = c.position
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    d1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    d2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
    dd = d2 - d1
    a = pow(dd.x, 2) + pow(dd.y, 2)
    b = 2 * (dd.x * (d1.x - cc.x) + dd.y * (d1.y - cc.y))
    c = pow(cc.x, 2) + pow(cc.y, 2) +
        pow(d1.x, 2) + pow(d1.y, 2) -
        2 * (cc.x * d1.x + cc.y * d1.y) -
        pow(c.radius.scaled(c), 2)
    i = b * b - 4 * a * c;
  if i < 0:
    return false
  elif abs(a) < Eps:
    return false
  else:
    let
      a2 = 2 * a
      ri = sqrt(i)
      n1 = (-b + ri) / a2
      n2 = (-b - ri) / a2
    if ((n1 < 0) and (n2 < 0)) or ((n1 > 1) and (n2 > 1)):
      return false
    else:
      return true

# Circle - Poly
method collide*(c: CircleCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(c, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(c, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  else:
    var
      i = 0
      j = p.points.high
    while i < p.points.len:
      if collide(c, LineCollider(parent: p.parent,
                                pos: p.points[i],
                                pos2: p.points[j])):
        return true
      # increment
      j = i
      inc i
    return false


#===============#
# Line Collider #
#===============#

proc init*(d: LineCollider, parent: Entity, pos: Coord = (0, 0),
           pos2: Coord = (0, 0)) =
  Collider(d).init(parent, pos)
  d.pos2 = pos2


proc newLineCollider*(parent: Entity, pos: Coord = (0, 0),
                      pos2: Coord = (0, 0)): LineCollider =
  result = new LineCollider
  result.init(parent, pos, pos2)


method render*(d: LineCollider) =
  let
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    pos1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    pos2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
  discard line(pos1, pos2, colliderOutlineColor)
  d.renderCollider()


# Line - Coord
method collide*(d: LineCollider, pos: Coord): bool {.inline.} =
  collide(pos, d)


# Line - Point
method collide*(d: LineCollider, a: Collider): bool {.inline.} =
  collide(a, d)


# Line - Box
method collide*(d: LineCollider, b: BoxCollider): bool {.inline.} =
  collide(b, d)


# Line - Circle
method collide*(d: LineCollider, c: CircleCollider): bool {.inline.} =
  collide(c, d)


# Line - Line
method collide*(d1, d2: LineCollider): bool =
  let
    d1pPosition = d1.parent.absPos
    d1pRotation = d1.parent.absRot
    d2pPosition = d2.parent.absPos
    d2pRotation = d2.parent.absRot
    p1 = rotate(d1.pos.scaled(d1), d1pPosition, d1pRotation)
    p2 = rotate(d1.pos2.scaled(d1), d1pPosition, d1pRotation)
    p3 = rotate(d2.pos.scaled(d2), d2pPosition, d2pRotation)
    p4 = rotate(d2.pos2.scaled(d2), d2pPosition, d2pRotation)
  return linesIntersect(p1, p2, p3, p4)


# Line - Poly
method collide*(d: LineCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(d, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(d, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  else:
    if collide(Collider(parent: d.parent, pos: d.pos), p):
      return true
    if collide(Collider(parent: d.parent, pos: d.pos2), p):
      return true
    var
      i = 0
      j = p.points.high
    while i < p.points.len:
      if collide(d, LineCollider(parent: p.parent,
                                pos: p.points[i],
                                pos2: p.points[j])):
        return true
      # increment
      j = i
      inc i
    return false


#==============#
# PolyCollider #
#==============#

proc init*(p: PolyCollider, parent: Entity, pos: Coord = (0, 0),
           points: openarray[Coord]) =
  Collider(p).init(parent, pos)
  p.points = @points


proc newPolyCollider*(parent: Entity, pos: Coord = (0, 0),
                      points: openarray[Coord]): PolyCollider =
  result = new PolyCollider
  result.init(parent, pos, points)


method render*(p: PolyCollider) =
  if p.points.len < 1:    # No points
    return
  elif p.points.len < 2:  # One point
    render(Collider(parent: p.parent, pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    render(LineCollider(parent: p.parent, pos: p.points[0], pos2: p.points[1]))
  else:
    let
      ppPosition = p.parent.absPos
      ppRotation = p.parent.absRot
    var points: seq[Coord] = @[]
    for point in p.points:
      points.add(rotate(point.scaled(p), ppPosition, ppRotation))
    discard polygon(points, colliderOutlineColor)
    p.renderCollider()


# Poly - Coord
method collide*(p: PolyCollider, pos: Coord): bool {.inline.} =
  collide(pos, p)


# Poly - Point
method collide*(p: PolyCollider, a: Collider): bool {.inline.} =
  collide(a, p)


# Poly - Box
method collide*(p: PolyCollider, b: BoxCollider): bool {.inline.} =
  collide(b, p)


# Poly - Circle
method collide*(p: PolyCollider, c: CircleCollider): bool {.inline.} =
  collide(c, p)


# Poly - Line
method collide*(p: PolyCollider, d: LineCollider): bool {.inline.} =
  collide(d, p)


# Poly - Poly
method collide*(p1, p2: PolyCollider): bool =
  if p1.points.len < 1 or p2.points.len < 1:   # P1 or P2 no points
    return false
  elif p1.points.len < 2: # P1 one point
    return collide(Collider(parent: p1.parent,
                            pos: p1.points[0]),
                   p2)
  elif p2.points.len < 2: # P2 one point
    return collide(Collider(parent: p2.parent,
                            pos: p2.points[0]),
                   p1)
  elif p1.points.len < 3: # P1 two points
    return collide(LineCollider(parent: p1.parent,
                                pos: p1.points[0],
                                pos2: p1.points[1]),
                   p2)
  elif p2.points.len < 3: # P2 two points
    return collide(LineCOllider(parent: p2.parent,
                                pos: p2.points[0],
                                pos2: p2.points[1]),
                   p1)
  else:
    # check if polygons are close enough
    var
      max1 = 0.0
      max2 = 0.0
    for p in p1.points:
      let dp = distance(p1.pos, p)
      if dp > max1:
        max1 = dp
    for p in p2.points:
      let dp = distance(p2.pos, p)
      if dp > max2:
        max2 = dp
    if (max1 + max2) < distance(p1.pos, p2.pos):
      return false # not close enough

    # check for collision
    var
      i = 0
      j = p1.points.high
    while i < p1.points.len:
      if collide(LineCollider(parent: p1.parent,
                              pos: p1.points[i],
                              pos2: p1.points[j]),
                p2):
        return true
      # increment
      j = i
      inc i
    return false


#================#
# Collider Utils #
#================#

proc intersect(a, b: seq[string]): bool =
  for item in a:
    if item in b:
      return true
  return false


iterator collisions(entity: Entity, list: seq[Entity]): Entity =
  for target in list:
    if target.collider == nil: continue # no collider on target
    if entity == target: continue # entity is target
    if target in entity.colliding: continue # already collided with target
    if entity.collider.tags.len == 0 or # no tags given
       entity.collider.tags.intersect(target.tags): # check for needed tags
      if collide(entity.collider, target.collider): # check for collision
        yield target


proc checkCollisions*(entity: Entity, list: seq[Entity]) =
  for target in entity.collisions(list):
    target.colliding.add(entity) # mark target as already collided with entity
    entity.onCollide(target)
    target.onCollide(entity)


proc isColliding*(entity: Entity, list: seq[Entity]): bool =
  for target in entity.collisions(list):
    return true
  return false


proc willCollide*(entity: Entity, pos: Coord, rot: Angle, scale: Scale): bool =
  let
    originalPos = entity.pos
    originalRot = entity.rot
    originalScale = entity.scale

  entity.pos = pos
  entity.rot = rot
  entity.scale = scale

  defer:
    entity.pos = originalPos
    entity.rot = originalRot
    entity.scale = scale

  result = isColliding(entity, entity.collisionEnvironment)


