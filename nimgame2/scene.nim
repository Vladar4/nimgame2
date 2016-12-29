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
  collider, entity, settings, types


type
  Scene* = ref object of RootObj
    when defined(faststack):
      list*: FastStack[Entity]
    else:
      list*: seq[Entity]


#########
# Scene #
#########


proc init*(scene: Scene) =
  when defined(faststack):
    scene.list = newFastStack[Entity](1_000)
  else:
    scene.list = @[]


method event*(scene: Scene, e: sdl.Event) {.base.} = discard


proc renderScene*(scene: Scene, renderer: sdl.Renderer) =
  ##  Default scene render procedure.
  ##
  ##  Call it from your scene render method.
  ##
  for entity in scene.list:
    entity.render(renderer)
  # Should be in the scene level to be drawn on top of all entities
  if colliderOutline:
    for entity in scene.list:
      if entity.collider != nil:
        entity.collider.render(renderer)


method render*(scene: Scene, renderer: sdl.Renderer) {.base.} =
  scene.renderScene(renderer)


proc checkCollisions*(scene: Scene, entity: Entity) =
  for target in scene.list:
    if target.collider == nil: continue # no collider on target
    if entity == target: continue # entity is target
    if target in entity.colliding: continue # already collided with target
    if collide(entity.collider, target.collider):
      target.colliding.add(entity) # mark target as already collided with entity
      entity.onCollide(target)
      target.onCollide(entity)


proc updateScene*(scene: Scene, elapsed: float) =
  ##  Default scene update procedure.
  ##
  ##  Call it from your scene update method.
  ##
  for entity in scene.list:
    entity.update(elapsed)
    if entity.collider != nil:
      entity.colliding = @[]

  for entity in scene.list:
    if entity.collider != nil:
      scene.checkCollisions(entity)


method update*(scene: Scene, elapsed: float) {.base.} =
  scene.updateScene(elapsed)


