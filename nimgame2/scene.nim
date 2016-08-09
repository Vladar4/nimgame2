# nimgame2/scene.nim
# Copyright (c) 2016 Vladar
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
  entity, types


type
  Scene* = ref object of RootObj
    list*: seq[Entity]


#########
# Scene #
#########


proc init*(scene: Scene) =
  scene.list = @[]


method event*(scene: Scene, e: sdl.Event) {.base.} = discard


proc renderScene*(scene: Scene, renderer: sdl.Renderer) =
  ##  Default scene render procedure.
  ##
  ##  Call it from your scene render method.
  ##
  for entity in scene.list:
    entity.render(renderer)


method render*(scene: Scene, renderer: sdl.Renderer) {.base.} =
  scene.renderScene(renderer)


proc updateScene*(scene: Scene, elapsed: float) =
  ##  Default scene update procedure.
  ##
  ##  Call it from your scene update method.
  ##
  for entity in scene.list:
    entity.update(elapsed)


method update*(scene: Scene, elapsed: float) {.base.} =
  scene.updateScene(elapsed)

