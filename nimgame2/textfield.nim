# nimgame2/gui/textfield.nim
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
  unicode,
  font, graphic, textgraphic, types


const
  DefaultTextFieldCursor = "|"
  DefaultTextFieldLimit = 8


type
  TextField* = ref object of TextGraphic
    fActive: bool
    fCursorIndex: int
    cursor*: string
    limit*: int


# PRIVATE #

template cursorLen(tf: TextField): int =
  tf.cursor.runeLen


# PUBLIC #

proc init*(tf: TextField, font: Font) =
  TextGraphic(tf).init(font)
  tf.fActive = false
  tf.fCursorIndex = 0
  tf.cursor = DefaultTextFieldCursor
  tf.limit = DefaultTextFieldLimit
  tf.lines = [""]


proc newTextField*(font: Font): TextField =
  result = new TextField
  result.init(font)


proc text*(tf: TextField): string =
  tf.lines[0]


proc `text=`*(tf: TextField, val: string) =
  tf.lines = [val]


template isActive*(tf: TextField): bool =
  tf.fActive


template len*(tf: TextField): int =
  tf.text.runeLen


proc bs*(tf: TextField, index = -1) =
  ##  Backspace text action.
  ##
  if not tf.fActive:
    return
  let
    runes = tf.text.toRunes
    idx = if index >= 0: index else: (tf.fCursorIndex - 1)
  if idx >= 0 and idx < tf.len:
    tf.text = $runes[0..(idx-1)] & $runes[(idx+1)..^1]
    dec tf.fCursorIndex


proc del*(tf: TextField, index = -1) =
  ##  Delete text action.
  ##
  if not tf.fActive:
    return
  let
    runes = tf.text.toRunes
    idx = if index >= 0: index else: (tf.fCursorIndex + 1)
  if (idx >= 0) and (idx < tf.len):
    tf.text = $runes[0..(idx-1)] & $runes[(idx+1)..^1]


proc add*(tf: TextField, str: string, index = -1) =
  ##  Add text action.
  ##
  if not tf.fActive:
    return
  if (index >= tf.len) or (tf.len - tf.cursorLen + str.runeLen > tf.limit):
    return
  let
    runes = tf.text.toRunes
    idx = if index >= 0: index else: tf.fCursorIndex
  tf.text = $runes[0..(idx-1)] & str & $runes[idx..^1]
  inc tf.fCursorIndex


proc left*(tf: TextField) =
  ##  Move cursor to the left.
  ##
  if tf.fActive and tf.fCursorIndex > 0:
    let
      runes = tf.text.toRunes
      idx = tf.fCursorIndex
    tf.text = $runes[0..(idx-2)] &
              tf.cursor &
              $runes[idx-1] &
              $runes[(idx+1)..^1]
    dec tf.fCursorIndex


proc right*(tf: TextField) =
  ##  Move cursor to the right.
  ##
  if tf.fActive and tf.fCursorIndex < (tf.len - 1):
    let
      runes = tf.text.toRunes
      idx = tf.fCursorIndex
    tf.text = $runes[0..(idx-1)] &
              $runes[idx+1] &
              tf.cursor &
              $runes[(idx+2)..^1]
    inc tf.fCursorIndex


proc toFirst*(tf: TextField) =
  ##  Move cursor to the beginning.
  ##
  if tf.fActive:
    while tf.fCursorIndex > 0:
      tf.left()


proc toLast*(tf: TextField) =
  ##  Move cursor to the end.
  ##
  if tf.fActive:
    while tf.fCursorIndex < (tf.len - 1):
      tf.right()


proc activate*(tf: TextField) =
  ##  Activate text field.
  ##
  if not tf.fActive:
    tf.fCursorIndex = tf.len
    tf.text = tf.text & tf.cursor
    tf.fActive = true


proc deactivate*(tf: TextField) =
  ##  Deactivate text field.
  ##
  if tf.fActive:
    let
      runes = tf.text.toRunes
      idx = tf.fCursorIndex
    tf.text = $runes[0..(idx-1)] & $runes[(idx+1)..^1]
    tf.fCursorIndex = tf.len - 1
    tf.fActive = false


proc draw*(tf: TextField, pos: Coord) =
  Graphic(tf).draw(pos)

