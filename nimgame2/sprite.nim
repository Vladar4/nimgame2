# nimgame2/sprite.nim
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
  sdl2/sdl_image as img,
  entity, graphic, types


type
  Animation* = object
    frames*: seq[int]
    frameRate*: float
    looped*: bool
    flip*: Flip



  Sprite* = ref object of Graphic
    fAnimationKeys: seq[string]
    fAnimations: seq[Animation]
    fCurrentAnimation: int
    fFrameSize: Dim
    fOffset: Dim
    fFrames: seq[Rect]
    fCurrent: int
    fTime: float
    playing*: bool


proc free*(sprite: Sprite) =
  Graphic(sprite).free()


proc init*(sprite: Sprite, frameSize: Dim, offset: Dim = (0, 0)) =
  sprite.fAnimationKeys = @[]
  sprite.fAnimations = @[]
  sprite.fCurrentAnimation = -1
  sprite.fFrameSize = frameSize
  sprite.fOffset = offset
  sprite.fFrames = @[]
  sprite.fCurrent = 0
  sprite.fTime = 0.0
  sprite.playing = false


proc newSprite*(frameSize: Dim, offset: Dim = (0, 0)): Sprite =
  new result, free
  result.init(frameSize, offset)


proc load*(sprite: Sprite, renderer: Renderer, file: string): bool =
  ##  Load texture from ``file``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = Graphic(sprite).load(renderer, file)

  var cols = (sprite.w - sprite.fOffset.w) div sprite.fFrameSize.w
  var rows = (sprite.h - sprite.fOffset.h) div sprite.fFrameSize.h

  sprite.fFrames = @[]
  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      sprite.fFrames.add(Rect(x: sprite.fOffset.w + sprite.fFrameSize.w * c,
                              y: sprite.fOffset.h + sprite.fFrameSize.h * r,
                              w: sprite.fFrameSize.w,
                              h: sprite.fFrameSize.h))


proc frameCount*(sprite: Sprite): int {.inline.} =
  sprite.fFrames.len


proc addAnimation*(sprite: Sprite,
                   name: string,
                   frames: openarray[int],
                   frameRate: float = 0.1,
                   looped: bool = false,
                   flip: Flip = Flip.none): bool =
  result = true

  if frames.len < 1:
    return false

  for frame in frames:
    if frame < 0 or frame > sprite.frameCount:
      return false

  sprite.fAnimationKeys.add(name)
  sprite.fAnimations.add(Animation(
    frames: @frames, frameRate: frameRate, looped: looped, flip: flip))



template getIdx(sprite: Sprite, name: string): int =
  sprite.fAnimationKeys.find(name)


proc animation*(sprite: Sprite, name: string): var Animation {.inline.} =
  let idx = sprite.getIdx(name)
  if idx < 0:
    return
  sprite.fAnimations[idx]


proc currentAnimation*(sprite: Sprite): var Animation {.inline.} =
  if sprite.fCurrentAnimation < 0:
    return
  sprite.fAnimations[sprite.fCurrentAnimation]


proc play*(sprite: Sprite, anim: string) =
  let idx = sprite.getIdx(anim)
  if idx < 0:
    return
  sprite.fCurrentAnimation = idx
  sprite.fCurrent = 0
  sprite.fTime = 0.0
  sprite.playing = true


proc updateSprite*(sprite: Sprite, entity: Entity, elapsed: float) =
  if sprite.fCurrentAnimation < 0:
    return

  if not sprite.playing:
    return

  sprite.fTime += elapsed
  while sprite.fTime >= sprite.currentAnimation.frameRate:
    sprite.fTime -= sprite.currentAnimation.frameRate
    inc sprite.fCurrent
    if sprite.fCurrent >= sprite.currentAnimation.frames.len:
      if not sprite.currentAnimation.looped:
        sprite.playing = false
      sprite.fCurrent = 0


method update*(sprite: Sprite, entity: Entity, elapsed: float) =
  sprite.updateSprite(entity, elapsed)


########
# DRAW #
########

method draw*(sprite: Sprite,
             renderer: Renderer,
             pos: Coord) =
  ##  Default draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  var frameSize = sprite.fFrameSize

  Graphic(sprite).draw(renderer,
                       pos,
                       frameSize,
                       sprite.fFrames[
                        sprite.currentAnimation.frames[sprite.fCurrent]])


method draw*(sprite: Sprite,
             renderer: Renderer,
             pos: Coord,
             size: Dim) =
  ##  Default draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions. Leave (0, 0) for default sprite size.
  ##
  var frameSize = size
  if size == (0, 0):
    frameSize = sprite.fFrameSize

  Graphic(sprite).draw(renderer,
                       pos,
                       frameSize,
                       sprite.fFrames[
                        sprite.currentAnimation.frames[sprite.fCurrent]])


method drawEx*(sprite: Sprite,
               renderer: Renderer,
               pos: Coord,
               angle: Angle = 0.0,
               centered: bool = true,
               anchor: Coord = (0.0, 0.0),
               flip: Flip = Flip.none) =
  ##  Advanced draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``angle`` Rotation angle in degrees.
  ##
  ##  ``centered`` Set to `true` to set the rotation `anchor`
  ##  in the center of the sprite.
  ##
  ##  ``anchor`` Rotation anchor position.
  ##
  ##  ``flip``  ``RenderFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  var frameSize = sprite.fFrameSize

  Graphic(sprite).drawEx(renderer,
                         pos,
                         frameSize,
                         sprite.fFrames[
                          sprite.currentAnimation.frames[sprite.fCurrent]],
                         angle,
                         centered,
                         anchor,
                         flip)


method drawEx*(sprite: Sprite,
               renderer: Renderer,
               pos: Coord,
               size: Dim = (0, 0),
               angle: Angle = 0.0,
               centered: bool = true,
               anchor: Coord = (0.0, 0.0),
               flip: Flip = Flip.none) =
  ##  Advanced draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions. Leave (0, 0) for default sprite size.
  ##
  ##  ``angle`` Rotation angle in degrees.
  ##
  ##  ``centered`` Set to `true` to set the rotation `anchor`
  ##  in the center of the sprite.
  ##
  ##  ``anchor`` Rotation anchor position.
  ##
  ##  ``flip``  ``RenderFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  var frameSize = size
  if size == (0, 0):
    frameSize = sprite.fFrameSize

  Graphic(sprite).drawEx(renderer,
                         pos,
                         frameSize,
                         sprite.fFrames[
                          sprite.currentAnimation.frames[sprite.fCurrent]],
                         angle,
                         centered,
                         anchor,
                         flip)

