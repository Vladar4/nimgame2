# nimgame2/tween.nim
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
  math


const
  Pi2 = Pi / 2
  X2Pi = Pi * 2
  BounceTime = [1 / 2.75, 2 / 2.75,   2.5 / 2.75]
  BounceSub =  [0.0,      1.5 / 2.75, 2.25 / 2.75,  2.625 / 2.75]
  BounceAdd =  [0.0,      0.75,       0.9375,       0.984375]
  BounceMul = 7.5625
  DefaultPeriodMul = 0.3
  DefaultBack = 1.70158


type
  TweenProcedure*[V] = proc(
    start, distance: V,
    elapsed, duration: float,
    amplitude, period: V, back: float): V

  TweenEnder*[T,V] = proc(tween: Tween[T,V])

  Tween*[T,V] = ref object of RootObj
    # Private
    target: T                   ##  Target object
    get: proc(e: T): V          ##  A value getter procedure
    set: proc(e: T, v: V)       ##  A value setter procedure
    fStart, fFinish: V          ##  Starting and finishing values
    fDistance: V                ##  Total distance (finish - start)
    fElapsed, fDuration: float  ##  Elapsed and total duration (in seconds)
    # Public
    amplitude*, period*: V      ##  Ease elastic amplitude and period
    back*: float                ##  Ease Back coefficient
    loop*, loopLimit*: int      ##  Loop counter and loop limit
    playing*: bool              ##  Playing status flag
    procedure*: TweenProcedure[V] ##  \
      ##  Value changing procedure, called from the ``update()``
    ender*: TweenEnder[T,V] ## \
      ##  Loop ending procedure, called from the ``update()``


#=========#
# Private #
#=========#

template progress(elapsed, duration: float): float =
  (elapsed / duration)


proc nextLoop(tween: Tween): bool =
  inc tween.loop
  if tween.loopLimit >= 0:
    result = tween.loop < tween.loopLimit
  else:
    result = true
  tween.playing = result


#========#
# Public #
#========#

proc value*[T,V](tween: Tween[T,V]): V {.inline.} =
  ##  ``Return`` the target value of ``tween``.
  ##
  if not (tween.get == nil):
    return tween.get(tween.target)


proc `value=`*[T,V](tween: Tween[T,V], val: V) {.inline.} =
  ##  Set the target value of ``tween`` to ``val``.
  ##
  if not (tween.set == nil):
    tween.set(tween.target, val)


proc start*[T,V](tween: Tween[T,V]): V {.inline.} =
  ##  ``Return`` starting value.
  ##
  return tween.fStart


proc finish*[T,V](tween: Tween[T,V]): V {.inline.} =
  ##  ``Return`` final value.
  ##
  return tween.fFinish


proc distance*[T,V](tween: Tween[T,V]): V {.inline.} =
  ##  ``Return`` the total distance.
  ##
  return tween.fDistance


proc duration*(tween: Tween): float {.inline.} =
  ##  ``Return`` ``tween``'s total duration.
  ##
  return tween.fDuration


proc elapsed*(tween: Tween): float {.inline.} =
  ##  ``Return`` ``tween``'s elapsed duration.
  ##
  return tween.fElapsed


proc progress*(tween: Tween): float =
  ##  ``Return`` ``tween`` progress in `0.0`..`1.0` range.
  ##
  return tween.fElapsed / tween.fDuration


proc play*(tween: Tween) =
  ##  Start playing ``tween`` with previously set params.
  ##
  tween.value = tween.fStart
  tween.fElapsed = 0.0
  tween.playing = true
  tween.loop = 0


proc stop*(tween: Tween) =
  ##  Stop playing ``tween`` immediately.
  ##
  tween.value = tween.fFinish
  tween.fElapsed = 0.0
  tween.playing = false
  tween.loop = 0


proc setup*[T,V](tween: Tween[T,V],
    start, finish: V, duration: float, loops = 0) =
  ##  Set up ``tween`` params.
  ##
  ##  ``start``, ``finish`` Limiting values for the target variable.
  ##
  ##  ``duration`` Duration (in seconds).
  ##
  ##  ``loops`` Loop limit. `0` for one loop, `-1` for looping forever.
  ##
  tween.fStart = start
  tween.fFinish = finish
  tween.fDuration = duration
  tween.fDistance = finish - start
  tween.amplitude = start - start
  tween.period = start / start * DefaultPeriodMul * duration
  tween.back = DefaultBack
  tween.loopLimit = loops


proc update*(tween: Tween, elapsed: float) =
  ##  Tween update procedure. Call it from the scene update method.
  ##
  if tween.playing:
    tween.fElapsed += elapsed
    tween.value = tween.procedure(
      tween.start, tween.distance, tween.elapsed, tween.duration,
      tween.amplitude, tween.period, tween.back)
    tween.ender(tween)


#============#
# Procedures #
#============#

# LINEAR #

proc linear*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Linear tween procedure.
  ##
  return start + distance * progress(elapsed, duration)


# QUAD #

proc inQuad*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Quadratic tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 2)


proc outQuad*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Quadratic tween procedure.
  ##
  let progress = progress(elapsed, duration)
  return start - distance * progress * (progress - 2)


proc inOutQuad*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Quadratic tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1:
      start + distance / 2.0 * pow(x2progress, 2)
    else:
      start - distance / 2.0 *
        ((x2progress - 1) * (x2progress - 3) - 1)


# CUBIC #

proc inCubic*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Cubic tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 3)


proc outCubic*[V](start, distance: V, elapsed, duration: float,
                  amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Cubic tween procedure.
  ##
  return start + distance * (pow(progress(elapsed, duration) - 1, 3) + 1)


proc inOutCubic*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Cubic tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1:
      start + distance / 2.0 * pow(x2progress, 3)
    else:
      start + distance / 2.0 * (pow(x2progress - 2, 3) + 2)


proc outInCubic*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Cubic tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outCubic(start, distance2, x2elapsed, duration,
               amplitude, period, back)
    else:
      inCubic(start + distance2, distance2, x2elapsed - duration, duration,
               amplitude, period, back)


# QUART #

proc inQuart*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Quart tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 4)


proc outQuart*[V](start, distance: V, elapsed, duration: float,
                  amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Quart tween procedure.
  ##
  return start - distance * (pow(progress(elapsed, duration) - 1, 4) - 1)


proc inOutQuart*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Quart tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1:
      start + distance / 2.0 * pow(x2progress, 4)
    else:
      start - distance / 2.0 * (pow(x2progress - 2, 4) - 2)


proc outInQuart*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##   Ease Out/In Quart tween procedure
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outQuart(start, distance2, x2elapsed, duration,
               amplitude, period, back)
    else:
      inQuart(start + distance2, distance2, x2elapsed - duration, duration,
              amplitude, period, back)


# QUINT #

proc inQuint*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Quint tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 5)


proc outQuint*[V](start, distance: V, elapsed, duration: float,
                  amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Quint tween procedure.
  ##
  return start + distance * (pow(progress(elapsed, duration) - 1, 5) + 1)


proc inOutQuint*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Quint tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1:
      start + distance / 2.0 * pow(x2progress, 5)
    else:
      start + distance / 2.0 * (pow(x2progress - 2, 5) + 2)


proc outInQuint*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Quint tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outQuint(start, distance2, x2elapsed, duration,
               amplitude, period, back)
    else:
      inQuint(start + distance2, distance2, x2elapsed - duration, duration,
              amplitude, period, back)


# SINE #

proc inSine*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Sine tween procedure.
  ##
  return start + distance - distance * cos(progress(elapsed, duration) * Pi2)


proc outSine*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Sine tween procedure.
  ##
  return start + distance * sin(progress(elapsed, duration) * Pi2)


proc inOutSine*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Sine tween procedure.
  ##
  return start - distance / 2.0 * (cos(progress(elapsed, duration) * Pi) - 1)


proc outInSine*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Sine tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outSine(start, distance2, x2elapsed, duration,
              amplitude, period, back)
    else:
      inSine(start + distance2, distance2, x2elapsed - duration, duration,
             amplitude, period, back)


# EXPO #

proc inExpo*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Expo tween procedure.
  ##
  return
    if elapsed == 0.0:
      start
    else:
      start - distance * 0.001 + distance *
        pow(2, 10 * (progress(elapsed, duration) - 1))


proc outExpo*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Expo tween procedure.
  ##
  return
    if elapsed == duration:
      start + distance
    else:
      start + distance * 1.001 * (-pow(2, -10 * progress(elapsed, duration)) + 1)


proc inOutExpo*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Expo tween procedure.
  ##
  if elapsed == 0.0:
    return start
  elif elapsed == duration:
    return start + distance
  else:
    let x2progress = progress(elapsed, duration) * 2
    return
      if x2progress < 1:
        start - distance * 0.0005 + distance / 2.0 *
          pow(2, 10 * (x2progress - 1))
      else:
        start + distance / 2.0 * 1.0005 *
          (-pow(2, -10 * (x2progress - 1)) + 2)


proc outInExpo*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Expo tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outExpo(start, distance2, x2elapsed, duration,
              amplitude, period, back)
    else:
      inExpo(start + distance2, distance2, x2elapsed - duration, duration,
             amplitude, period, back)


# CIRC #

proc inCirc*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Circ tween procedure.
  ##
  return start - distance *
    (sqrt(1 - pow(progress(elapsed, duration), 2)) - 1)


proc outCirc*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Circ tween procedure.
  ##
  return start + distance *
    sqrt(1 - pow(progress(elapsed, duration) - 1, 2))


proc inOutCirc*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Circ tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1:
      start - distance / 2.0 * (sqrt(1 - pow(x2progress, 2)) - 1)
    else:
      start + distance / 2.0 * (sqrt(1 - pow(x2progress - 2, 2)) + 1)


proc outInCirc*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Circ tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outCirc(start, distance2, x2elapsed, duration,
              amplitude, period, back)
    else:
      inCirc(start + distance2, distance2, x2elapsed - duration, duration,
             amplitude, period, back)


# BOUNCE #

proc outBounce*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Bounce tween procedure.
  ##
  let progress = progress(elapsed, duration)
  return
    if progress < BounceTime[0]:
      start + distance *
        (BounceMul * pow(progress - BounceSub[0], 2) + BounceAdd[0])
    elif progress < BounceTime[1]:
      start + distance *
        (BounceMul * pow(progress - BounceSub[1], 2) + BounceAdd[1])
    elif progress < BounceTime[2]:
      start + distance *
        (BounceMul * pow(progress - BounceSub[2], 2) + BounceAdd[2])
    else:
      start + distance *
        (BounceMul * pow(progress - BounceSub[3], 2) + BounceAdd[3])


proc inBounce*[V](start, distance: V, elapsed, duration: float,
                  amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Bounce tween procedure.
  ##
  return
    start + distance -
      outBounce(start - start, distance, duration - elapsed, duration,
                amplitude, period, back)


proc inOutBounce*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Bounce tween procedure.
  ##
  let x2elapsed = elapsed * 2
  return
    if x2elapsed < duration:
      start +
        inBounce(start - start, distance, x2elapsed, duration,
                 amplitude, period, back) * 0.5
    else:
      start + distance / 2.0 +
        outBounce(start - start, distance, x2elapsed - duration, duration,
                  amplitude, period, back) * 0.5


proc outInBounce*[V](start, distance: V, elapsed, duration: float,
                     amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Bounce tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outBounce(start, distance2, x2elapsed, duration,
                amplitude, period, back)
    else:
      inBounce(start + distance2, distance2, x2elapsed - duration, duration,
               amplitude, period, back)


# ELASTIC #

proc inElastic*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Elastic tween procedure.
  ##
  if elapsed == 0:
    return start
  if elapsed == duration:
    return start + distance

  var amp, s: V
  if amplitude < abs(distance):
    amp = distance
    s = period / 4.0
  else:
    amp = amplitude
    s = period / X2Pi * arcsin(distance / amp)

  let progress1 = progress(elapsed, duration) - 1

  return
    start -
      amp * pow(2, 10 * progress1) *
      sin((progress1 * duration - s) * X2Pi / period)


proc outElastic*[V](start, distance: V, elapsed, duration: float,
                    amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Elastic tween procedure.
  ##
  if elapsed == 0:
    return start
  if elapsed == duration:
    return start + distance

  var amp, s: V
  if amplitude < abs(distance):
    amp = distance
    s = period / 4.0
  else:
    amp = amplitude
    s = period / X2Pi * arcsin(distance / amp)

  let progress = progress(elapsed, duration)

  return
    start + distance +
      amp * pow(2, -10 * progress) *
      sin((progress * duration - s) * X2Pi / period)


proc inOutElastic*[V](start, distance: V, elapsed, duration: float,
                      amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Elastic tween procedure.
  ##
  if elapsed == 0:
    return start
  if elapsed == duration:
    return start + distance

  var amp, s: V
  if amplitude < abs(distance):
    amp = distance
    s = period / 4.0
  else:
    amp = amplitude
    s = period / X2Pi * arcsin(distance / amp)

  let
    x2progress1 = progress(elapsed, duration) * 2 - 1
  return
    if x2progress1 < 0:
      start -
        amp * pow(2, 10 * x2progress1) *
        sin((x2progress1 * duration - s) * X2Pi / period) * 0.5
    else:
      start + distance +
        amp * pow(2, -10 * x2progress1) *
        sin((x2progress1 * duration - s) * X2Pi / period) * 0.5


proc outInElastic*[V](start, distance: V, elapsed, duration: float,
                      amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Elastic tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outElastic(start, distance2, x2elapsed, duration,
                 amplitude, period, back)
    else:
      inElastic(start + distance2, distance2, x2elapsed - duration, duration,
                amplitude, period, back)


# BACK #

proc inBack*[V](start, distance: V, elapsed, duration: float,
                amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In Back tween procedure.
  ##
  let progress = progress(elapsed, duration)
  return
    start + distance *
      pow(progress, 2) * ((back + 1) * progress - back)


proc outBack*[V](start, distance: V, elapsed, duration: float,
                 amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out Back tween procedure.
  ##
  let progress1 = progress(elapsed, duration) - 1
  return
    start + distance *
      (pow(progress1, 2) * ((back + 1) * progress1 + back) + 1)


proc inOutBack*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease In/Out Back tween procedure.
  ##
  let
    backN = back * 1.525
    x2progress = progress(elapsed, duration) * 2
  if x2progress < 1:
    return
      start + distance / 2.0 *
        (pow(x2progress, 2) * ((backN + 1) * x2progress - backN))
  else:
    let x2progress2 = x2progress - 2
    return
      start + distance / 2.0 *
        (pow(x2progress2, 2) * ((backN + 1) * x2progress2 + backN) + 2)


proc outInBack*[V](start, distance: V, elapsed, duration: float,
                   amplitude, period: V, back: float): V {.procvar.} =
  ##  Ease Out/In Back tween procedure.
  ##
  let
    x2elapsed = elapsed * 2
    distance2 = distance / 2.0
  return
    if x2elapsed < duration:
      outBack(start, distance2, x2elapsed, duration,
              amplitude, period, back)
    else:
      inBack(start + distance2, distance2, x2elapsed - duration, duration,
             amplitude, period, back)


#========#
# Enders #
#========#

proc reversing*(tween: Tween) {.procvar.} =
  ##  Tween ender.
  ##
  ##  Reverses the direction on each loop.
  ##
  ##  Default option.
  ##
  ##  ``Note:`` each reversal counts as one loop.
  ##
  if tween.progress >= 1.0:
    if tween.nextLoop():
      swap(tween.fStart, tween.fFinish)
      tween.fDistance = -tween.fDistance
      tween.fElapsed = 0.0


proc repeating*(tween: Tween) {.procvar.} =
  ##  Tween ender.
  ##
  ##  Repeats from ``start`` to ``finish`` on each loop.
  ##
  if tween.progress >= 1.0:
    if tween.nextLoop():
      tween.value = tween.fStart
      tween.fElapsed = 0.0


#=======#
# Tween #
#=======#

proc initTween*[T,V](tween: Tween[T,V],
                     target: T,
                     get: proc(e: T): V,
                     set: proc(e: T, v: V)) =
  ##  Set new bindings for the ``tween``.
  ##
  ##  ``target`` The target object of this tween.
  ##
  ##  ``get`` A value getter procedure.
  ##
  ##  ``set`` A value setter procedure.
  ##
  tween.target = target
  tween.get = get
  tween.set = set
  tween.playing = false
  tween.procedure = linear
  tween.ender = reversing


template init*[T,V](tween: Tween[T,V],
                    target: T,
                    get: proc(e: T): V,
                    set: proc(e: T, v: V)) {.
                    deprecated: "Use initTween() instead".} =
  initTween(tween, target, get, set)


proc newTween*[T,V](target: T,
                    get: proc(e: T): V,
                    set: proc(e: T, v: V)): Tween[T,V] =
  ##  Create a new ``Tween``.
  ##
  ##  ``target`` The target object of this tween.
  ##
  ##  ``get`` A value getter procedure.
  ##
  ##  ``set`` A value setter procedure.
  ##
  new result
  result.initTween(target, get, set)

