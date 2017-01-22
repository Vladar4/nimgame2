# nimgame2/tween.nim
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
  math


type
  Tween*[T,V] = ref object of RootObj
    target: T                   ##  Target object
    get: proc(e: T): V          ##  A value getter procedure
    set: proc(e: T, v: V)       ##  A value setter procedure
    fStart, fFinish: V          ##  Starting and finishing values
    fDistance: V                ##  Total distance (finish - start)
    fElapsed, fDuration: float  ##  Elapsed and total duration (in seconds)
    loop*, loopLimit*: int      ##  Loop counter and loop limit
    running*: bool              ##  Running status flag
    procedure*: proc(start, distance: V, elapsed, duration: float): V ##  \
      ##  Value changing procedure, called from the ``update()``
    ender*: proc (tween: Tween[T,V]) ## \
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
  tween.running = result


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
  tween.running = true
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
  tween.loopLimit = loops


proc update*(tween: Tween, elapsed: float) =
  ##  Tween update procedure. Call it from the scene update method.
  ##
  if tween.running:
    tween.fElapsed += elapsed
    tween.value = tween.procedure(
      tween.start, tween.distance, tween.elapsed, tween.duration)
    tween.ender(tween)


#============#
# Procedures #
#============#

# LINEAR #

proc linear*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Linear tween procedure.
  ##
  return start + distance * progress(elapsed, duration)


# QUAD #

proc inQuad*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In Quadratic tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 2)


proc outQuad*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out Quadratic tween procedure.
  ##
  let progress = progress(elapsed, duration)
  return start - distance * progress * (progress - 2.0)


proc inOutQuad*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In/Out Quadratic tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2.0
  return
    if x2progress < 1.0:
      start + distance / 2.0 * pow(x2progress, 2)
    else:
      start - distance / 2.0 *
        ((x2progress - 1.0) * (x2progress - 3.0) - 1.0)


# CUBIC #

proc inCubic*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In Cubic tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 3)


proc outCubic*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out Cubic tween procedure.
  ##
  return start + distance * (pow(progress(elapsed, duration) - 1.0, 3) + 1.0)


proc inOutCubic*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In/Out Cubic tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2.0
  return
    if x2progress < 1.0:
      start + distance / 2.0 * pow(x2progress, 3)
    else:
      start + distance / 2.0 * (pow(x2progress - 2.0, 3) + 2.0)


proc outInCubic*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out/In Cubic tween procedure.
  ##
  let distance2 = distance / 2.0
  return
    if elapsed < duration / 2.0:
      outCubic(start, distance / 2.0, elapsed * 2, duration)
    else:
      inCubic(start + distance2, distance2, elapsed * 2 - duration, duration)


# QUART #

proc inQuart*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In Quart tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 4)


proc outQuart*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out Quart tween procedure.
  ##
  return start - distance * (pow(progress(elapsed, duration) - 1.0, 4) - 1.0)


proc inOutQuart*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In/Out Quart tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1.0:
      start + distance / 2.0 * pow(x2progress, 4)
    else:
      start - distance / 2.0 * (pow(x2progress - 2.0, 4) - 2.0)


proc outInQuart*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##   Ease Out/In Quart tween procedure
  ##
  let distance2 = distance / 2.0
  return
    if elapsed < duration / 2.0:
      outQuart(start, distance2, elapsed * 2, duration)
    else:
      inQuart(start + distance2, distance2, elapsed * 2 - duration, duration)


# QUINT #

proc inQuint*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In Quint tween procedure.
  ##
  return start + distance * pow(progress(elapsed, duration), 5)


proc outQuint*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out Quint tween procedure.
  ##
  return start + distance * (pow(progress(elapsed, duration) - 1.0, 5) + 1.0)


proc inOutQuint*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease In/Out Quint tween procedure.
  ##
  let x2progress = progress(elapsed, duration) * 2
  return
    if x2progress < 1.0:
      start + distance / 2.0 * pow(x2progress, 5)
    else:
      start + distance / 2.0 * (pow(x2progress - 2.0, 5) + 2.0)


proc outInQuint*[V](start, distance: V, elapsed, duration: float): V {.procvar.} =
  ##  Ease Out/In Quint tween procedure.
  ##
  let distance2 = distance / 2.0
  return
    if elapsed < duration / 2.0:
      outQuint(start, distance2, elapsed * 2, duration)
    else:
      inQuint(start + distance2, distance2, elapsed * 2 - duration, duration)


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

proc init*[T,V](tween: Tween[T,V],
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
  tween.running = false
  tween.procedure = linear
  tween.ender = reversing


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
  result.init(target, get, set)

