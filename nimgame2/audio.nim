# nimgame2/audio.nim
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
  sdl2/sdl_mixer as mix,
  types


type
  Channel* = int
  Distance* = range[0..255]
  Panning* = range[0..255]
  Volume* = range[0..mix.MaxVolume]

  Sound* = ref object of RootObj
    fChunk: mix.Chunk
    fChannel: Channel

  Music* = ref object of RootObj
    fMusic: mix.Music


#########
# SOUND #
#########

proc free*(sound: Sound) =
  if not (sound.fChunk == nil):
    # check if playing
    if sound.fChannel > -1:
      if sound.fChannel.playing() > 0:
        # halt the channel
        discard sound.fChannel.haltChannel()
    # free
    sound.fChunk.freeChunk()
    sound.fChunk = nil
  sound.fChannel = -1


proc init*(sound: Sound, file: string) =
  sound.free()
  sound.fChunk = loadWAV(file)
  if sound.fChunk == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load sound file %s: %s",
                    file, mix.getError())
  sound.fChannel = -1


proc newSound*(file: string): Sound =
  new result, free
  result.init(file)


proc available*(sound: Sound): bool =
  if sound.fChunk == nil:
    return false
  return not (sound.fChannel < 0)


proc playing*(sound: Sound): bool =
  ##  ``Return`` `true` if ``sound`` is playing, or `false` otherwise.
  ##
  if not sound.available:
    return false
  return sound.fChannel.playing() > 0


proc stop*(sound: Sound) =
  ##  Stop ``sound``.
  ##
  if sound.playing:
    discard sound.fChannel.haltChannel()


proc play*(sound: Sound, loops: int = 0): Channel =
  ##  Play ``sound`` ``loops`` + `1` times.
  ##
  ##  ``Return`` the channel the ``sound`` is played on.
  ##
  if sound.playing:
    sound.stop()
  sound.fChannel = playChannel(-1, sound.fChunk, loops)
  if sound.fChannel < 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't play sound chunk: %s",
                    mix.getError())
  return sound.fChannel


proc channel*(sound: Sound): Channel =
  ##  ``Return`` the channel the ``sound`` is played on.
  ##
  if sound.playing:
    return sound.fChannel
  else:
    return -1


proc paused*(sound: Sound): bool =
  ##  ``Return`` `true` if ``sound`` is paused, or `false` otherwise.
  ##
  if not sound.available:
    return false
  return sound.fChannel.paused() > 0


proc pause*(sound: Sound) =
  ##  Pause ``sound``.
  ##
  if not sound.available:
    return
  if not sound.paused:
    sound.fChannel.pause()


proc resume*(sound: Sound) =
  ##  Resume ``sound`` if it is paused.
  ##
  if not sound.available:
    return
  if sound.paused:
    sound.fChannel.resume()


proc volume*(sound: Sound): Volume {.inline.} =
  ##  ``Return`` the volume of ``sound``.
  ##
  return sound.fChunk.volumeChunk(-1)


proc normalizeVolume*(val: int): Volume =
  if val > Volume.high:
    return Volume.high
  if val < 0:
    return 0
  return val


proc `volume=`*(sound: Sound, val: Volume) {.inline.} =
  ##  Set ``sound`` volume.
  ##
  discard sound.fChunk.volumeChunk(val)


template volumeInc*(sound: Sound, val: int) =
  ##  Increase ``sound`` volume by ``val``.
  ##
  sound.volume = normalizeVolume(sound.volume + val)


template volumeDec*(sound: Sound, val: int) =
  ##  Decrease ``sound`` volume by ``val``.
  ##
  sound.volume = normalizeVolume(sound.volume - val)


#################
# SOUND CHANNEL #
#################

proc setDistance*(channel: Channel,
                  distance: Distance) {.inline.} =
  ##  Set the distance on a ``channel``.
  ##
  ##  ``distance``:
  ##    `0` - near (loud)
  ##    `255` - far (quiet)
  ##
  if mix.setDistance(channel, distance) == 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set the distance on the channel %s: %s",
                    channel, mix.getError())


proc setPanning*(channel: Channel,
                 left: Panning = Panning.high,
                 right: Panning = Panning.high) {.inline.} =
  ##  Set the panning on a ``channel``.
  ##
  ##  Setting both ``left`` and ``right`` to `255` (``Panning.high``)
  ##  will unregister the effect from ``channel``.
  ##
  if mix.setPanning(channel, left, right) == 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set the panning on the channel %s: %s",
                    channel, mix.getError())

proc setPosition*(channel: Channel,
                  angle: Angle,
                  distance: Distance) {.inline.} =
  ##  Set the position on a ``channel``.
  ##
  ##  ``angle``:
  ##    `0` - front
  ##    `90` - right
  ##    `180` - behind
  ##    `270` - left
  ##
  ##  ``distance``:
  ##    `0` - near (loud)
  ##    `255` - far (quiet)
  if mix.setPosition(channel, angle.int16, distance) == 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set the position on the channel %s: %s",
                    channel, mix.getError())


################
# SOUND GLOBAL #
################

proc soundStop*() {.inline.} =
  ##  Stop all sound channels.
  ##
  discard mix.haltChannel(-1)


proc soundPlayingNum*(): int {.inline.} =
  ##  ``Return`` the number of currently playing channels.
  ##
  return mix.playing(-1)


proc soundPausedNum*(): int {.inline.} =
  ##  ``Return`` the number of currently paused channels.
  ##
  return mix.paused(-1)


proc soundPause*() {.inline.} =
  ##  Pause all sound channels.
  ##
  mix.pause(-1)


proc soundResume*() {.inline.} =
  ##  Resume all sound channels.
  ##
  mix.resume(-1)


proc soundVolume*(): Volume {.inline.} =
  ##  ``Return`` average sound volume.
  ##
  return mix.volume(-1, -1)


proc `soundVolume=`*(val: Volume) {.inline.} =
  ##  Set new volume for all sound channels.
  ##
  discard mix.volume(-1, val)


template soundVolumeInc*(val: int) =
  ##  Increase global sound volume by ``val``.
  ##
  soundVolume = normalizeVolume(soundVolume + val)


template soundVolumeDec*(val: int) =
  ##  Decrease global sound volume by ``val``.
  ##
  soundVolume = normalizeVolume(soundVolume - val)


#########
# MUSIC #
#########

proc free*(music: Music) =
  if not (music.fMusic == nil):
    music.fMusic.freeMusic()
    music.fMusic = nil


proc init*(music: Music, file: string) =
  music.free()
  music.fMusic = mix.loadMUS(file)
  if music.fMusic == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load music file %s: %s",
                    file, mix.getError())


proc newMusic*(file: string): Music =
  new result, free
  result.init(file)


proc available*(music: Music): bool {.inline.} =
  return not (music.fMusic == nil)


proc play*(music: Music, loops: int = 0) =
  if music.fMusic.playMusic(loops) < 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't play music: %s",
                    mix.getError())

################
# MUSIC GLOBAL #
################


proc musicPaused*(): bool {.inline.} =
  ##  ``Return`` `true` if music is paused, or `false` otherwise.
  ##
  return mix.pausedMusic() != 0


proc musicPause*() {.inline.} =
  ##  Pause music.
  ##
  mix.pauseMusic()


proc musicResume*() {.inline.} =
  ##  Resume music.
  ##
  mix.resumeMusic()


proc musicRewind*() {.inline.} =
  ##  Rewind music.
  ##
  mix.rewindMusic()


proc musicPlaying*(): bool {.inline.} =
  ##  ``Return`` `true` if music is playing, or `false` otherwise.
  ##
  return mix.playingMusic() != 0


proc musicStop*() {.inline.} =
  ##  Stop music.
  ##
  discard mix.haltMusic()


proc `musicPosition=`*(val: float) {.inline.} =
  ##  Set the current position in the music stream.
  ##
  ##  Works only on MOD, OGG, and MP3 music:
  ##
  ##  MOD ``val`` is a pattern number.
  ##
  ##  OGG ``val`` is seconds from from the beginning.
  ##
  ##  MP3 ``val`` is seconds from the current position.
  ##
  discard mix.setMusicPosition(val)


proc musicVolume*(): Volume {.inline.} =
  ##  ``Return`` the current music volume.
  ##
  return mix.volumeMusic(-1)


proc `musicVolume=`*(val: Volume) =
  ##  Set the music volume.
  ##
  discard mix.volumeMusic(val)


template musicVolumeInc*(val: int) =
  ##  Increase music volume by ``val``.
  ##
  musicVolume = normalizeVolume(musicVolume + val)


template soundVolumeDec*(val: int) =
  ##  Decrease music volume by ``val``.
  ##
  musicVolume = normalizeVolume(musicVolume - val)

