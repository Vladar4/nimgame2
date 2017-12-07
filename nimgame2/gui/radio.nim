# nimgame2/radiogroup.nim
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
  ../entity,
  ../graphic,
  button,
  widget


type
  GuiRadioGroup* = ref object of Entity
    # Public
    list*: seq[GuiWidget]

  GuiRadioButton* = ref object of GuiButton
    # Public
    group*: GuiRadioGroup


#===============#
# GuiRadioGroup #
#===============#

proc init*(radiogroup: GuiRadioGroup) =
  radiogroup.initEntity()
  radiogroup.list = @[]


proc newGuiRadioGroup*(): GuiRadioGroup =
  result = new GuiRadioGroup
  result.init()


proc toggle*(radiogroup: GuiRadioGroup, target: GuiWidget) =
  ##  Toggle a ``target`` element of the ``radiogroup``.
  ##
  let idx = radiogroup.list.find(target)
  if idx >= 0:
    for i in 0..radiogroup.list.high:
      if i != idx:
        radiogroup.list[i].setToggled(false)


#================#
# GuiRadioButton #
#================#

proc init*(radiobutton: GuiRadioButton,
           group: GuiRadioGroup,
           graphic: Graphic,
           image: Graphic = nil,
           circle: bool = false) =
  ##  GuiRadioButton initialization.
  ##
  ##  ``group`` GuiRadioGroup the ``radiobutton`` belongs to.
  ##
  ##  ``graphic``, ``image``, ``circle``
  ##  See "gui/button.nim" initialization docs.
  ##
  GuiButton(radiobutton).init(graphic, image, circle)
  radiobutton.toggle = true
  radiobutton.parent = group
  radiobutton.group = group
  group.list.add(radiobutton)


proc newGuiRadioButton*(group: GuiRadioGroup,
                        graphic: Graphic,
                        image: Graphic = nil,
                        circle: bool = false): GuiRadioButton =
  ##  Create a new GuiRadioButton.
  ##
  ##  ``group`` GuiRadioGroup the ``radiobutton`` belongs to.
  ##
  ##  ``graphic``, ``image``, ``circle``
  ##  See "gui/button.nim" initialization docs.
  ##
  ##
  result = new GuiRadioButton
  result.init(group, graphic, image, circle)


proc setToggled*(radiobutton: GuiRadioButton, val: bool) =
  ##  Toggle ``radiobutton`` to a given state.
  ##
  if val:
    GuiWidget(radiobutton).setToggled(val)
    radiobutton.group.toggle(radiobutton)


method `toggled=`*(radiobutton: GuiRadioButton, val: bool) =
  radiobutton.setToggled(val)

