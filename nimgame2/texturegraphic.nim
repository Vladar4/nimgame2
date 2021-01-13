# nimgame2/texturegraphic.nim
# Copyright (c) 2016-2021 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl,
  sdl2/sdl_image as img,
  graphic, settings, types


type
  TextureGraphic* = ref object of Graphic
    # Private
    fTexture: sdl.Texture
    fFormat: uint32
    fSize: Dim


#================#
# TextureGraphic #
#================#

proc freeTexture*(graphic: TextureGraphic) =
  if not (graphic.fTexture == nil):
    graphic.fTexture.destroyTexture()
    graphic.fTexture = nil


proc free*(graphic: TextureGraphic) =
  graphic.freeTexture()
  graphic.fFormat = 0
  graphic.fSize = (0, 0)


proc initTextureGraphic*(graphic: TextureGraphic) =
  graphic.fTexture = nil
  graphic.fFormat = 0
  graphic.fSize = (0, 0)


template init*(graphic: TextureGraphic) {.deprecated: "use initTextureGraphic() instead".} =
  initTextureGraphic(graphic)


proc updateTexture*(graphic: TextureGraphic): bool =
  ##  Update format and dimensions of the texture.
  ##
  ##  ``load()``, ``assignTexture()``
  ##  or any other proc that changes the texture, calls this on its own.
  ##
  ##  ``Return`` `true` on success (or if the texture is absent),
  ##  or `false` otherwise.
  ##
  if graphic.fTexture == nil: # nothing to update
    graphic.fFormat = 0
    graphic.fSize = (0, 0)
    return true
  result = true
  var w, h: cint
  if graphic.fTexture.queryTexture(
      addr(graphic.fFormat), nil, addr(w), addr(h)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture attributes: %s",
                    sdl.getError)
    sdl.destroyTexture(graphic.fTexture)
    return false
  graphic.fSize.w = w
  graphic.fSize.h = h


proc format*(graphic: TextureGraphic): uint32 {.inline.} =
  graphic.fFormat


proc load*(
    graphic: TextureGraphic, file: string): bool =
  ##  Load texture from ``file``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  graphic.free()
  # load texture
  graphic.fTexture = renderer.loadTexture(file)
  if graphic.fTexture == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load image %s: %s",
                    file, img.getError())
    return false
  result = graphic.updateTexture()


proc load*(
    graphic: TextureGraphic, rw: ptr RWops, freeSrc: bool = true): bool =
  ##  Load texture from ``src`` ``RWops``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  graphic.free()
  # load texture
  graphic.fTexture = renderer.loadTextureRW(rw, freeSrc)
  if graphic.fTexture == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load image RW: %s",
                    img.getError())
    return false
  result = graphic.updateTexture()


proc assignTexture*(
  graphic: TextureGraphic, texture: Texture, freeCurrent: bool = true): bool =
  ##  Assign already created ``texture`` and run ``updateTexture()`` afterwards.
  ##
  ##  ``freeCurrent`` Free the currently assigned texture.
  ##  Set to `false` if it used by other objects.
  ##
  ##  ``ATTENTION!`` The ``texture`` will be destroyed on ``free()``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  if not(graphic.fTexture == nil) and freeCurrent:
    graphic.freeTexture()
  graphic.fTexture = texture
  result = graphic.updateTexture()


proc texture*(graphic: TextureGraphic): sdl.Texture {.inline.} =
  ##  Direct access to the ``graphic``'s texture. Be careful.
  ##
  graphic.fTexture


proc newTextureGraphic*(): TextureGraphic =
  new result, free
  result.initTextureGraphic()


proc newTextureGraphic*(file: string): TextureGraphic =
  result = newTextureGraphic()
  discard result.load(file)


proc newTextureGraphic*(src: ptr RWops, freeSrc: bool = true): TextureGraphic =
  result = newTextureGraphic()
  discard result.load(src, freeSrc)


proc newTextureGraphic*(texture: Texture): TextureGraphic =
  result = newTextureGraphic()
  discard result.assignTexture(texture)


method w*(graphic: TextureGraphic): int {.inline.} =
  graphic.fSize.w


method h*(graphic: TextureGraphic): int {.inline.} =
  graphic.fSize.h


method dim*(graphic: TextureGraphic): Dim {.inline.} =
  graphic.fSize


proc drawTextureGraphic*(graphic: TextureGraphic,
                         pos: Coord = (0.0, 0.0),
                         angle: Angle = 0.0,
                         scale: Scale = 1.0,
                         center: Coord = (0.0, 0.0),
                         flip: Flip = Flip.none,
                         region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  ##  Draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``angle`` Rotation angle in degrees.
  ##
  ##  ``scale`` Draw scale. `1.0` for original size.
  ##
  ##  ``center`` Center of rendering, rotation, and scaling.
  ##
  ##  ``flip`` ``RendererFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  ##
  ##  ``region`` Source texture region to draw.
  ##
  if graphic.fTexture == nil:
    return
  if scale == 0.0:
    return

  let
    empty = Rect(x: 0, y: 0, w: 0, h: 0)
  var
    size: Dim = if region == empty: graphic.dim
                else: (region.w.int, region.h.int)
    cntr =  if region == empty:
              center - graphic.offset
            else:
              center

  if scale != 1.0:
    size.w = int(size.w.float * scale)
    size.h = int(size.h.float * scale)
    cntr *= scale

  var
    position = pos - cntr
    dstRect = sdl.Rect(
      x: position.x.cint, y: position.y.cint, w: size.w.cint, h: size.h.cint)
    srcRect = region

  if not (srcRect == empty):
    srcRect.x -= graphic.offset.x.cint
    srcRect.y -= graphic.offset.y.cint


  if (angle == 0.0) and flip == Flip.none:

    if region == empty:
      discard renderer.renderCopy(graphic.fTexture,
                                  nil,
                                  addr(dstRect))
    else:
      discard renderer.renderCopy(graphic.fTexture,
                                  addr(srcRect),
                                  addr(dstRect))

  else: # renderCopyEx procedure

    var
      anchor: sdl.Point
    anchor.x = cntr.x.cint
    anchor.y = cntr.y.cint

    if region == empty:
      discard renderer.renderCopyEx(graphic.fTexture,
                                    nil,
                                    addr(dstRect),
                                    angle,
                                    addr(anchor),
                                    flip.RendererFlip)
    else:
      discard renderer.renderCopyEx(graphic.fTexture,
                                    addr(srcRect),
                                    addr(dstRect),
                                    angle,
                                    addr(anchor),
                                    flip.RendererFlip)


method draw*(graphic: TextureGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  drawTextureGraphic(graphic, pos, angle, scale, center, flip, region)


proc drawTiled*(graphic: TextureGraphic,
                rect: Rect,
                region: Rect = Rect(x: 0, y: 0, w: 0, h: 0),
                reverseX = false, reverseY = false) =
  ##  Repeatedly draw the ``graphic`` to fill the ``rect``.
  ##
  ##  ``region`` Source texture region to draw.
  ##
  ##  ``reverseX``, ``reverseY`` Drawing progression order.
  ##

  proc drawTile(graphic: TextureGraphic, src, dst: var Rect) =
    discard renderer.renderCopy(graphic.fTexture, addr(src), addr(dst))

  proc drawLine(graphic: TextureGraphic,
                src, dst: var Rect, deltaX, endX: int) =
    let
      startX = dst.x
      lastX = endX - deltaX

    if reverseX: dst.x += deltaX
    while dst.x < lastX:
      graphic.drawTile(src, dst)
      dst.x += dst.w

    if deltaX > 0:
      var
        partSrc = Rect(x: src.x, y: src.y, w: deltaX, h: src.h)
        partDst = dst
      if reverseX:
        partSrc.x = src.w - deltaX
        partSrc.y = src.y
        partDst.x = startX
      partDst.w = deltaX
      graphic.drawTile(partSrc, partDst)

  var srcRect, dstRect: Rect

  srcRect = if region == Rect(x: 0, y: 0, w: 0, h: 0):
              Rect(x: 0, y: 0, w: graphic.dim.w, h: graphic.dim.h)
            else:
              region
  dstRect = Rect(x: rect.x, y: rect.y, w: graphic.w, h: graphic.h)

  let
    endX = rect.x + rect.w
    endY = rect.y + rect.h
    deltaX = rect.w mod srcRect.w
    deltaY = rect.h mod srcRect.h
    startY = dstRect.y
    lastY = endY - deltaY

  if reverseY: dstRect.y += deltaY
  while dstRect.y < lastY:
    graphic.drawLine(srcRect, dstRect, deltaX, endX)
    dstRect.x = rect.x
    dstRect.y += dstRect.h

  if deltaY > 0:
    srcRect.x = 0
    srcRect.y = 0
    if reverseY:
      srcRect.y = srcRect.h - deltaY
      dstRect.y = startY
    srcRect.h = deltaY
    dstRect.h = deltaY
    graphic.drawLine(srcRect, dstRect, deltaX, endX)


proc colorMod*(graphic: TextureGraphic): Color =
  ##  ``Return`` current color modifier.
  ##
  var r, g, b: uint8
  result = Color(r: 0, g: 0, b: 0, a: 0)

  if graphic.fTexture.getTextureColorMod(addr(r), addr(g), addr(b)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture color mod: %s",
                    sdl.getError())
    return

  return Color(r: r, g: g, b: b, a: 0xFF)


proc `colorMod=`*(graphic: TextureGraphic, color: Color) =
  ##  Set a new color modifier.
  ##
  if graphic.fTexture.setTextureColorMod(color.r, color.g, color.b) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture color mod: %s",
                    sdl.getError())


proc alphaMod*(graphic: TextureGraphic): uint8 =
  ##  ``Return`` current alpha (transparency) modifier.
  ##
  var a: uint8
  if graphic.fTexture.getTextureAlphaMod(addr(a)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture alpha mod: %s",
                    sdl.getError())
    return 0xFF
  return a


proc `alphaMod=`*(graphic: TextureGraphic, alpha: uint8) =
  ##  Set a new alpha (transparency) modifier.
  ##
  if graphic.fTexture.setTextureAlphaMod(alpha) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture alpha mod: %s",
                    sdl.getError())


proc blendMod*(graphic: TextureGraphic): Blend =
  ##  ``Return`` current blending mode.
  ##
  var blend: sdl.BlendMode

  if graphic.fTexture.getTextureBlendMode(addr(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture blend mode: %s",
                    sdl.getError())
    return Blend.none
  return Blend(blend)


proc `blendMod=`*(graphic: TextureGraphic, blend: Blend) =
  ##  Set a new blending mode.
  ##
  if graphic.fTexture.setTextureBlendMode(sdl.BlendMode(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture blend mode: %s",
                    sdl.getError())

