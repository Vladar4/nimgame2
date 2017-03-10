# nimgame2/textinput.nim
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
  sdl2/sdl,
  ../collider,
  ../entity,
  ../font,
  ../graphic,
  ../input,
  ../textfield,
  ../textgraphic,
  ../types,
  widget


type
  GuiTextInput* = ref object of GuiWidget
    text*: TextField
    textPos*: Coord     ##  Relative text position
    keysBackspace*, keysDelete*, keysLeft*, keysRight*,
      keysToFirst*, keysToLast*, keysDone*: seq[Keycode]


proc init*(input: GuiTextInput,
           graphic: Graphic,
           font: Font) =
  ##  GuiTextInput initialization.
  ##
  ##  ``grapic`` 2x2 input field graphic:
  ##  default, focused, pressed (active), disabled.
  ##
  ##  ``font`` Font object for text rendering.
  ##
  GuiWidget(input).init()
  input.toggle = true
  input.keysBackspace = @[K_Backspace]
  input.keysDelete = @[K_Delete]
  input.keysLeft = @[K_Left]
  input.keysRight = @[K_Right]
  input.keysToFirst = @[K_Home]
  input.keysToLast = @[K_End]
  input.keysDone = @[K_Return, K_Escape]
  input.graphic = graphic
  input.initSprite((graphic.dim.w / 2, graphic.dim.h / 3))
  # Collider
  input.collider = input.newBoxCollider(input.sprite.dim / 2, input.sprite.dim)
  # Text
  input.text = newTextField(font)
  input.textPos = (
    (input.sprite.dim.h - font.charH) / 2,
    (input.sprite.dim.h - font.charH) / 2)


proc newGuiTextInput*(graphic: Graphic, font: Font): GuiTextInput =
  ##  Create a new GuiTextInput.
  ##
  ##  ``grapic`` 2x2 input field graphic:
  ##  default, focused, pressed (active), disabled.
  ##
  ##  ``font`` Font object for text rendering.
  ##
  result = new GuiTextInput
  result.init(graphic, font)


proc eventGuiTextInput*(input: GuiTextInput, e: Event) =
  if input.state.isEnabled:
    case e.kind:
    of KeyDown:
      if input.toggled:
        let key = e.key.keysym.sym
        if key in input.keysBackspace:
            input.text.bs()

        elif key in input.keysDelete:
          input.text.del()

        elif key in input.keysLeft:
          input.text.left()

        elif key in input.keysRight:
          input.text.right()

        elif key in input.keysToFirst:
          input.text.toFirst()

        elif key in input.keysToLast:
          input.text.toLast()

        elif key in input.keysDone:
          input.text.deactivate()
          stopTextInput()
          input.release()

    of TextInput:
      if input.toggled:
        input.text.add($e.text.text)

    of TextEditing:
      if input.toggled:
        discard

    else:
      discard


method event*(input: GuiTextInput, e: Event) =
  input.eventGuiWidget(e)
  input.eventGuiTextInput(e)


method `state=`*(input: GuiTextInput, val: GuiState) =
  input.setState(val)
  input.sprite.currentFrame = val.int


proc enter*(input: GuiTextInput) =
  input.text.activate()
  startTextInput()


proc click*(input: GuiTextInput, mb: MouseButton) {.inline.} =
  input.enter()


method onClick*(input: GuiTextInput, mb: MouseButton) =
  input.click(mb)


proc renderGuiTextInput*(input: GuiTextInput) =
  ##  Default text input render procedure.
  ##
  ##  Call it from your text input render method.
  ##
  input.renderEntity()
  input.text.draw(input.pos + input.textPos)


method render*(input: GuiTextInput) =
  input.renderGuiTextInput()

