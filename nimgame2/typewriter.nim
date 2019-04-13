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
  entity, textgraphic, types


type
  Typewriter* = ref object of Entity
    # Private
    fText: seq[char]  ##  typewriter's queue
    fRemainder: float ##  internal timer (in seconds)
    # Public
    rate*: float  ##  typewriter's rate (in seconds)
    width*: int   ##  line width limit, no limit if `0` (default)


#============#
# Typewriter #
#============#

proc newTypewriter*(text: TextGraphic, rate: float): Typewriter =
  new result
  result.initEntity()
  result.graphic = text
  let tg = TextGraphic(result.graphic)
  if tg.lines.len < 1:
    tg.lines = [""]
  result.fText = @[]
  result.fRemainder = 0.0
  result.rate = rate
  result.width = -1


proc add*(tw: Typewriter, text: string) {.inline.} =
  ##  Add new ``text`` to the typewriter's queue.
  ##
  tw.fText = reversed(text) & tw.fText


proc dump*(tw: Typewriter): string {.inline.} =
  ##  ``Return`` the text awaiting in the typewriter's queue.
  ##
  $tw.fText


proc text*(tw: Typewriter): string {.inline.} =
  ##  ``Return`` the printed text.
  ##
  TextGraphic(tw.graphic).text


proc clear*(tw: Typewriter, empty: bool = false) {.inline.} =
  ##  Delete the text awaiting in the typewriter's queue.
  ##
  ##  ``empty`` Set to `true` if you want to clear the printed text as well.
  tw.fText = @[]
  if empty:
    TextGraphic(tw.graphic).setText("")


proc force*(tw: Typewriter, text: string = "") =
  ##  Add new ``text`` to the typewriter's queue
  ##  and then output it all immediately.
  ##
  if text.len > 0:
    tw.add(text)
  tw.fRemainder = 0.0
  let tg = TextGraphic(tw.graphic)
  tg.setText(tg.text & reversed(tw.fText).join())
  tw.clear()


proc updateTypewriter*(tw: Typewriter, elapsed: float) =
  var str = ""
  tw.fRemainder += elapsed
  while tw.fRemainder >= tw.rate:
    if tw.fText.len < 1: # no text to print left
      tw.fRemainder = 0.0
      break
    tw.fRemainder -= tw.rate
    str.add(tw.fText.pop())

  # update textgraphic
  if str.len > 0:
    let tg = TextGraphic(tw.graphic)
    tg.setText(tg.text & str, tw.width)


method update*(tw: Typewriter, elapsed: float) =
  updateTypewriter(tw, elapsed)

