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

type
  Tween*[T,V] = ref object of RootObj
    target: T                   ##  Target object
    get: proc(e: T): V          ##  A value getter procedure
    set: proc(e: T, v: V)       ##  A value setter procedure
    fStart, fFinish, fSpeed: V  ##  Starting, finishing values, \
                                ##  and speed of change (per second)
    fDuration: float            ##  Duration (in seconds)
    loop*, loopLimit*: int      ##  Loop counter and loop limit
    running*: bool              ##  Running status flag
    procedure*: proc(tween: Tween[T,V], elapsed: float) ##  \
      ##  Value changing procedure, called from the ``update()``
    ender*: proc (tween: Tween[T,V]) ## \
      ##  Loop ending procedure, called from the ``update()``


#=========#
# Private #
#=========#

proc between[V](val, start, finish: V): bool =
  let
    lo = min(start, finish)
    hi = max(start, finish)
  return (val > lo) and (val < hi)


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


proc duration*(tween: Tween): float {.inline.} =
  ##  ``Return`` ``tween``'s duration.
  ##
  return tween.fDuration


proc speed*[T,V](tween: Tween[T,V]): V {.inline.} =
  ##  ``Return`` the speed of ``tween`` target variable change (per second).
  ##
  return tween.fSpeed


proc play*(tween: Tween) =
  ##  Start playing ``tween`` with previously set params.
  ##
  tween.value = tween.fStart
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
  tween.fSpeed = (finish - start) / duration
  tween.loopLimit = loops


proc update*(tween: Tween, elapsed: float) =
  ##  Tween update procedure. Call it from the scene update method.
  ##
  if tween.running:
    tween.procedure(tween, elapsed)
    tween.ender(tween)


#============#
# Procedures #
#============#

proc linear*(tween: Tween, elapsed: float) {.procvar.} =
  ##  Tween procedure.
  ##
  ##  Changes ``tween`` value lineary from ``start`` to ``finish``.
  ##
  tween.value = tween.value + tween.fSpeed * elapsed


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
  if not tween.value.between(tween.fStart, tween.fFinish):
    if tween.nextLoop():
      tween.fSpeed = -tween.fSpeed


proc repeating*(tween: Tween) {.procvar.} =
  ##  Tween ender.
  ##
  ##  Repeats from ``start`` to ``finish`` on each loop.
  ##
  if not tween.value.between(tween.fStart, tween.fFinish):
    if tween.nextLoop():
      tween.value = tween.fStart


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

