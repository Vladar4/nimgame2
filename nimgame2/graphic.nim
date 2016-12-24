# nimgame2/graphic.nim
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
  types


type
  Graphic* = ref object of RootObj
    texture*: sdl.Texture
    fSize: Dim


########
# LOAD #
########


proc free*(graphic: Graphic) =
  if not(graphic.texture == nil):
    graphic.texture.destroyTexture()
    graphic.texture = nil


proc newGraphic*(): Graphic =
  new result, free


proc load*(graphic: Graphic, renderer: sdl.Renderer, file: string): bool =
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


proc w*(graphic: Graphic): int {.inline.} =
  graphic.fSize.w


proc h*(graphic: Graphic): int {.inline.} =
  graphic.fSize.h


proc dim*(graphic: Graphic): Dim {.inline.} =
  graphic.fSize


########
# DRAW #
########


proc draw*(graphic: Graphic,
           renderer: sdl.Renderer,
           pos: Coord) =
  ##  Default draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  if graphic.texture == nil:
    return

  var dstRect = sdl.Rect(x: pos.x.int,
                         y: pos.y.int,
                         w: graphic.fSize.w,
                         h: graphic.fSize.h)
  discard renderer.renderCopy(graphic.texture, nil, addr(dstRect))


proc draw*(graphic: Graphic,
           renderer: sdl.Renderer,
           pos: Coord,
           size: Dim) =
  ##  Default draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions. Leave (0, 0) for default texture size.
  ##
  if graphic.texture == nil:
    return

  if size == (0, 0):
    draw(graphic, renderer, pos)
    return

  var dstRect = sdl.Rect(x: pos.x.int,
                         y: pos.y.int,
                         w: size.w,
                         h: size.h)
  discard renderer.renderCopy(graphic.texture, nil, addr(dstRect))


proc draw*(graphic: Graphic,
           renderer: sdl.Renderer,
           pos: Coord,
           size: Dim,
           region: sdl.Rect) =
  ##  Default draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions.
  ##
  ##  ``region``  Source texture region to draw.
  ##
  if graphic.texture == nil:
    return

  var srcRect = region
  var dstRect = sdl.Rect(x: pos.x.int,
                         y: pos.y.int,
                         w: size.w,
                         h: size.h)
  discard renderer.renderCopy(graphic.texture, addr(srcRect), addr(dstRect))


proc drawEx*(graphic: Graphic,
             renderer: sdl.Renderer,
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
  ##  in the center of the texture.
  ##
  ##  ``anchor``  Rotation anchor position.
  ##
  ##  ``flip``  ``RendererFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  ##
  if graphic.texture == nil:
    return

  var dstRect = sdl.Rect(x: pos.x.int,
                         y: pos.y.int,
                         w: graphic.fSize.w,
                         h: graphic.fSize.h)
  var anchorPoint: sdl.Point
  if not centered:
    anchorPoint.x = anchor.x.cint
    anchorPoint.y = anchor.y.cint
  discard renderer.renderCopyEx(graphic.texture, nil, addr(dstRect),
                                angle,
                                if centered: nil else: addr(anchorPoint),
                                sdl.RendererFlip(flip))


proc drawEx*(graphic: Graphic,
             renderer: sdl.Renderer,
             pos: Coord,
             size: Dim,
             angle: Angle = 0.0,
             centered: bool = true,
             anchor: Coord = (0.0, 0.0),
             flip: Flip = Flip.none) =
  ##  Advanced draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions. Leave (0, 0) for default texture size.
  ##
  ##  ``angle`` Rotation angle in degrees.
  ##
  ##  ``centered`` Set to `true` to set the rotation `anchor`
  ##  in the center of the texture.
  ##
  ##  ``anchor``  Rotation anchor position.
  ##
  ##  ``flip``  ``RendererFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  ##
  if graphic.texture == nil:
    return

  if size == (0, 0):
    drawEx(graphic, renderer, pos, angle, centered, anchor, flip)
    return

  var dstRect = sdl.Rect(x: pos.x.int,
                         y: pos.y.int,
                         w: size.w,
                         h: size.h)
  var anchorPoint: sdl.Point
  if not centered:
    anchorPoint.x = anchor.x.cint
    anchorPoint.y = anchor.y.cint
  discard renderer.renderCopyEx(graphic.texture, nil, addr(dstRect),
                                angle,
                                if centered: nil else: addr(anchorPoint),
                                sdl.RendererFlip(flip))


proc drawEx*(graphic: Graphic,
             renderer: Renderer,
             pos: Coord,
             size: Dim,
             region: Rect,
             angle: Angle = 0.0,
             centered: bool = true,
             anchor: Coord = (0.0, 0.0),
             flip: Flip = Flip.none) =
  ##  Advanced draw procedure.
  ##
  ##  ``pos`` Draw coordinates.
  ##
  ##  ``size`` Output dimensions. Leave (0, 0) for default texture size.
  ##
  ##  ``region`` Source texture region to draw.
  ##
  ##  ``angle`` Rotation angle in degrees.
  ##
  ##  ``centered`` Set to `true` to set the rotation `anchor`
  ##  in the center of the texture.
  ##
  ##  ``anchor``  Rotation anchor position.
  ##
  ##  ``flip``  ``RendererFlip`` value, could be set to:
  ##  ``FlipNone``, ``FlipHorizontal``, ``FlipVertical``.
  ##
  if graphic.texture == nil:
    return

  if size == (0, 0):
    drawEx(graphic, renderer, pos, angle, centered, anchor, flip)
    return

  var srcRect = region
  var dstRect = Rect(x: pos.x.int,
                     y: pos.y.int,
                     w: size.w,
                     h: size.h)
  var anchorPoint: sdl.Point
  if not centered:
    anchorPoint.x = anchor.x.cint
    anchorPoint.y = anchor.y.cint
  discard renderer.renderCopyEx(graphic.texture, addr(srcRect), addr(dstRect),
                                angle,
                                if centered: nil else: addr(anchorPoint),
                                sdl.RendererFlip(flip))


########
# MODS #
########

proc colorMod*(graphic: Graphic): Color =
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


proc `colorMod=`*(graphic: Graphic, color: Color) =
  ##  TODO
  ##
  if graphic.texture.setTextureColorMod(color.r, color.g, color.b) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture color mod: %s",
                    sdl.getError())


proc alphaMod*(graphic: Graphic): uint8 =
  ##  TODO
  ##
  var a: uint8
  if graphic.texture.getTextureAlphaMod(addr(a)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture alpha mod: %s",
                    sdl.getError())
    return 0xFF
  return a


proc `alphaMod=`*(graphic: Graphic, alpha: uint8) =
  ##  TODO
  ##
  if graphic.texture.setTextureAlphaMod(alpha) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture alpha mod: %s",
                    sdl.getError())


proc blendMod*(graphic: Graphic): Blend =
  ##  TODO
  ##
  var blend: sdl.BlendMode

  if graphic.texture.getTextureBlendMode(addr(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture blend mode: %s",
                    sdl.getError())
    return Blend.none
  return Blend(blend)


proc `blendMod=`*(graphic: Graphic, blend: Blend) =
  ##  TODO
  ##
  if graphic.texture.setTextureBlendMode(sdl.BlendMode(blend)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set texture blend mode: %s",
                    sdl.getError())

