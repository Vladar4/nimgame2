# nimgame2/texturegraphic.nim
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
  graphic, types


type
  TextureGraphic* = ref object of Graphic
    texture*: sdl.Texture
    fSize: Dim


########
# LOAD #
########


proc free*(graphic: TextureGraphic) =
  if not(graphic.texture == nil):
    graphic.texture.destroyTexture()
    graphic.texture = nil


proc newTextureGraphic*(): TextureGraphic =
  new result, free


method w*(graphic: TextureGraphic): int {.inline.} =
  graphic.fSize.w


method h*(graphic: TextureGraphic): int {.inline.} =
  graphic.fSize.h


method dim*(graphic: TextureGraphic): Dim {.inline.} =
  graphic.fSize


proc load*(
    graphic: TextureGraphic, renderer: sdl.Renderer, file: string): bool =
  ##  Load texture from ``file``.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  # load texture
  graphic.texture = renderer.loadTexture(file)
  if graphic.texture == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load image %s: %s",
                    file, img.getError())
    return false
  # get dimensions
  var w, h: cint
  if graphic.texture.queryTexture(nil, nil, addr(w), addr(h)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture attributes: %s",
                    sdl.getError)
    sdl.destroyTexture(graphic.texture)
    return false
  graphic.fSize.w = w
  graphic.fSize.h = h


########
# DRAW #
########


method draw*(graphic: TextureGraphic,
             renderer: Renderer,
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
  if graphic.texture == nil:
    return
  if scale == 0.0:
    return

  let
    empty = Rect(x: 0, y: 0, w: 0, h: 0)
  var
    size: Dim = if region == empty: graphic.dim
                else: (region.w.int, region.h.int)
    cntr = center

  if scale != 1.0:
    size.w = int(size.w.float * scale)
    size.h = int(size.h.float * scale)
    cntr *= scale

  var
    position = pos - cntr
    dstRect = sdl.Rect(
      x: position.x.cint, y: position.y.cint, w: size.w.cint, h: size.h.cint)

  if (angle == 0.0) and flip == Flip.none:

    if region == empty:
      discard renderer.renderCopy(graphic.texture, nil, addr(dstRect))
    else:
      var srcRect = region
      discard renderer.renderCopy(graphic.texture, addr(srcRect), addr(dstRect))

  else: # renderCopyEx procedure

    var
      anchor: sdl.Point
    anchor.x = cntr.x.cint
    anchor.y = cntr.y.cint

    if region == empty:
      discard renderer.renderCopyEx(graphic.texture,
                                    nil,
                                    addr(dstRect),
                                    angle,
                                    addr(anchor),
                                    flip.RendererFlip)
    else:
      var srcRect = region
      discard renderer.renderCopyEx(graphic.texture,
                                    addr(srcRect),
                                    addr(dstRect),
                                    angle,
                                    addr(anchor),
                                    flip.RendererFlip)


########
# MODS #
########

proc colorMod*(graphic: TextureGraphic): Color =
  ##  TODO
  ##
  var r, g, b: uint8
  result = Color(r: 0, g: 0, b: 0, a: 0)

  if graphic.texture.getTextureColorMod(addr(r), addr(g), addr(b)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture color mod: %s",
                    sdl.getError())
    return

  return Color(r: r, g: g, b: b, a: 0xFF)


proc `colorMod=`*(graphic: TextureGraphic, color: Color) =
  ##  TODO
  ##
  if graphic.texture.setTextureColorMod(color.r, color.g, color.b) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture color mod: %s",
                    sdl.getError())


proc alphaMod*(graphic: TextureGraphic): uint8 =
  ##  TODO
  ##
  var a: uint8
  if graphic.texture.getTextureAlphaMod(addr(a)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture alpha mod: %s",
                    sdl.getError())
    return 0xFF
  return a


proc `alphaMod=`*(graphic: TextureGraphic, alpha: uint8) =
  ##  TODO
  ##
  if graphic.texture.setTextureAlphaMod(alpha) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture alpha mod: %s",
                    sdl.getError())


proc blendMod*(graphic: TextureGraphic): Blend =
  ##  TODO
  ##
  var blend: sdl.BlendMode

  if graphic.texture.getTextureBlendMode(addr(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture blend mode: %s",
                    sdl.getError())
    return Blend.none
  return Blend(blend)


proc `blendMod=`*(graphic: TextureGraphic, blend: Blend) =
  ##  TODO
  ##
  if graphic.texture.setTextureBlendMode(sdl.BlendMode(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture blend mode: %s",
                    sdl.getError())

