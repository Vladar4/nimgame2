# nimgame2/mpeggraphic.nim
# Copyright (c) 2016-2019 Vladimir Arabadzhi (Vladar)
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
  sdl2/smpeg,
  ../graphic, ../texturegraphic, ../settings, ../types

##  ``Note:`` mpg123 dynamic library should be available in the system.

type
  MpegVolume* = range[0..100]
  MpegGraphic* = ref object of TextureGraphic ##  \
    ##  See sdl2/mpeg documentation for the details of implementation.
    # Private
    fInfo: smpeg.Info
    fSmpeg: smpeg.Smpeg
    fFrame: smpeg.Frame
    fMutex: sdl.Mutex
    fRect: sdl.Rect
    fVideo, fAudio, fLoop: bool
    fVolume: MpegVolume
    fUpdated: bool


#=============#
# MpegGraphic #
#=============#

method w*(graphic: MpegGraphic): int =
  graphic.fRect.w


method h*(graphic: MpegGraphic): int =
  graphic.fRect.h


method dim*(graphic: MpegGraphic): Dim =
  (graphic.fRect.w.int, graphic.fRect.h.int)


proc free*(graphic: MpegGraphic) =
  TextureGraphic(graphic).free()
  if graphic.fSmpeg != nil:
    graphic.fSmpeg.delete()
    graphic.fSmpeg = nil
  if graphic.fMutex != nil:
    graphic.fMutex.destroyMutex()
    graphic.fMutex = nil


proc update(data: pointer, frame: Frame) {.cdecl.} =
  var graphic = cast[MpegGraphic](data)
  graphic.fFrame = frame
  graphic.fUpdated = true


template afterLoad(graphic: MpegGraphic) =
  graphic.fMutex = sdl.createMutex()
  discard graphic.assignTexture(renderer.createTexture(
    sdl.PixelFormat_YV12, sdl.TextureAccessStreaming,
    graphic.fInfo.width, graphic.fInfo.height))
  graphic.fRect = sdl.Rect(
    x: 0, y: 0, w: graphic.fInfo.width, h: graphic.fInfo.height)
  graphic.fSmpeg.setDisplay(update, cast[pointer](graphic), graphic.fMutex)
  graphic.fSmpeg.renderFrame(1)
  graphic.fVideo = (graphic.fInfo.hasVideo != 0)
  graphic.fAudio = (graphic.fInfo.hasAudio != 0)
  graphic.fLoop = false
  graphic.fVolume = MpegVolume.high


proc load*(graphic: MpegGraphic, filename: string): bool =
  ##  Load MPEG movie file.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  graphic.free()
  # load smpeg
  graphic.fSmpeg = smpeg.new(filename, addr(graphic.fInfo), true)
  let error = graphic.fSmpeg.error()
  if error != nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "SMPEG error: %s",
                    error)
    graphic.fSmpeg = nil
    return false
  # after-load
  afterLoad(graphic)


proc load*(graphic: MpegGraphic, src: ptr RWops, freeSrc: bool = true): bool =
  ##  Load MPEG movie file.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  result = true
  graphic.free()
  # load smpeg
  graphic.fSmpeg = smpeg.newRWops(src, addr(graphic.fInfo), freeSrc, true)
  let error = graphic.fSmpeg.error()
  if error != nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "SMPEG error: %s",
                    error)
    graphic.fSmpeg = nil
    return false
  # after-load
  afterLoad(graphic)


proc newMpegGraphic*(filename: string): MpegGraphic =
  new result, free
  if not result.load(filename):
    result.free()
    return nil


proc newMpegGraphic*(src: ptr RWops, freeSrc: bool): MpegGraphic =
  new result, free
  if not result.load(src, freeSrc):
    result.free()
    return nil


proc drawMpegGraphic*(graphic: MpegGraphic,
                      pos: Coord = (0.0, 0.0),
                      angle: Angle = 0.0,
                      scale: Scale = 1.0,
                      center: Coord = (0.0, 0.0),
                      flip: Flip = Flip.none,
                      region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  if graphic.fUpdated:
    discard graphic.fMutex.mutexP() # lock
    discard sdl.updateTexture(graphic.texture, nil, graphic.fFrame.image,
                              graphic.fFrame.imageWidth.cint)
    graphic.fSmpeg.getInfo(addr(graphic.fInfo))
    graphic.fUpdated = false
    discard graphic.fMutex.mutexV() # unlock
  drawTextureGraphic(graphic, pos, angle, scale, center, flip, region)


method draw*(graphic: MpegGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  drawMpegGraphic(graphic, pos, angle, scale, center, flip, region)


proc video*(graphic: MpegGraphic): bool {.inline.} =
  graphic.fVideo


proc `video=`*(graphic: MpegGraphic, on: bool) =
  if graphic.fInfo.hasVideo != 0:
    graphic.fSmpeg.enableVideo(on)
    graphic.fVideo = on


proc audio*(graphic: MpegGraphic): bool {.inline.} =
  graphic.fAudio


proc `audio=`*(graphic: MpegGraphic, on: bool) =
  if graphic.fInfo.hasAudio != 0:
    graphic.fSmpeg.enableAudio(on)
    graphic.fAudio = on


proc playing*(graphic: MpegGraphic): bool =
  let status = graphic.fSmpeg.status()
  return status == PLAYING


proc volume*(graphic: MpegGraphic): MpegVolume {.inline.} =
  graphic.fVolume


proc `volume=`*(graphic: MpegGraphic, volume: MpegVolume) =
  graphic.fSmpeg.setVolume(volume)
  graphic.fVolume = volume


proc loop*(graphic: MpegGraphic): bool {.inline.} =
  graphic.fLoop


proc `loop=`*(graphic: MpegGraphic, on: bool) {.inline.} =
  graphic.fSmpeg.loop(on)
  graphic.fLoop = on


proc play*(graphic: MpegGraphic) {.inline.} =
  graphic.fSmpeg.play()


proc pause*(graphic: MpegGraphic) {.inline.} =
  graphic.fSmpeg.pause()


proc stop*(graphic: MpegGraphic) {.inline.} =
  graphic.fSmpeg.stop()


proc rewind*(graphic: MpegGraphic) {.inline.} =
  graphic.fSmpeg.rewind()


proc seek*(graphic: MpegGraphic, bytes: int) =
  graphic.fSmpeg.seek(bytes)


proc skip*(graphic: MpegGraphic, seconds: float) =
  if (graphic.fInfo.currentTime + seconds) <= graphic.fInfo.totalTime:
    graphic.fSmpeg.skip(seconds)


proc currentFrame*(graphic: MpegGraphic): int {.inline.} =
  graphic.fInfo.currentFrame


proc currentTime*(graphic: MpegGraphic): float {.inline.} =
  graphic.fInfo.currentTime


proc totalTime*(graphic: MpegGraphic): float {.inline.} =
  graphic.fInfo.totalTime


proc renderFrame*(graphic: MpegGraphic, frame: int) =
  if frame < 0:
    graphic.fSmpeg.renderFinal()
  else:
    graphic.fSmpeg.renderFrame(frame)

