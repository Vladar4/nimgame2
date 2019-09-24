# nimgame2/typewriter.nim
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
  algorithm, strutils,
  entity, textgraphic


type
  Typewriter* = ref object of Entity
    # Private
    fQueue: seq[seq[char]]  ##  typewriter's queue
    fRemainder: float ##  internal timer (in seconds)
    # Public
    rate*: float  ##  typewriter's rate (in seconds)
    width*: int   ##  line width limit, no limit if `0` (default)


#============#
# Typewriter #
#============#


proc initTypewriter*(tw: Typewriter, text: TextGraphic, rate: float) =
  tw.initEntity()
  tw.graphic = text
  tw.fQueue = @[]
  tw.fRemainder = 0.0
  tw.rate = rate
  tw.width = -1


proc newTypewriter*(text: TextGraphic, rate: float): Typewriter =
  new result
  result.initTypewriter(text, rate)


proc add*(tw: Typewriter, line: string) {.inline.} =
  ##  Add new ``line`` to the typewriter's queue.
  ##
  tw.fQueue.insert(reversed(line), 0)


proc queue*(tw: Typewriter): seq[seq[char]] {.inline.} =
  ##  ``Return`` the text awaiting in the typewriter's queue (backwards).
  ##
  tw.fQueue


template dump*(tw: Typewriter): seq[seq[char]] {.
    deprecated: "Use queue() instead".} =
  queue(tw)


proc queueLen*(tw: Typewriter): int {.inline.} =
  ##  ``Return`` queue length (in lines).
  ##
  tw.fQueue.len


proc text*(tw: Typewriter): string {.inline.} =
  ##  ``Return`` already printed text.
  ##
  TextGraphic(tw.graphic).text


proc clear*(tw: Typewriter, empty: bool = false) {.inline.} =
  ##  Delete the text awaiting in the typewriter's queue.
  ##
  ##  ``empty`` Set to `true` if you want to clear the printed text as well.
  tw.fQueue = @[]
  if empty:
    TextGraphic(tw.graphic).setText("")


proc force*(tw: Typewriter, line: string = "") =
  ##  Add new ``line`` to the typewriter's queue
  ##  and then output it all immediately.
  ##
  if line.len > 0:
    tw.add(line)
  tw.fRemainder = 0.0
  let tg = TextGraphic(tw.graphic)
  if tw.fQueue.len > 0:
    if tw.fQueue[^1].len > 0:
      tg.append(tw.fQueue.pop().reversed.join)
    while tw.fQueue.len > 0:
      tg.add(tw.fQueue.pop().reversed.join)


proc updateTypewriter*(tw: Typewriter, elapsed: float) =
  updateEntity(tw, elapsed)

  let tg = TextGraphic(tw.graphic)
  tw.fRemainder += elapsed

  while tw.fRemainder >= tw.rate:
    if tw.fQueue.len < 1: # no text to print left
      tw.fRemainder = 0.0
      break

    var str = ""
    while tw.fQueue[^1].len > 0 and
          tw.fRemainder >= tw.rate:
      tw.fRemainder -= tw.rate
      str.add(tw.fQueue[^1].pop())
    tg.append(str)

    if tw.fQueue[^1].len < 1: # line has ended
      discard tw.fQueue.pop()
      tg.add("") # new line

    elif tw.width > 0 and
         tg.lines[^1].len >= tw.width: # check for text wrapping
      tg.add("")


method update*(tw: Typewriter, elapsed: float) =
  updateTypewriter(tw, elapsed)

