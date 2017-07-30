# nimgame2/scene.nim
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
  sdl2/sdl,
  entity, settings, types


type
  Scene* = ref object of RootObj
    camera*, cameraBond*: Entity  ##  Camera and its bond Entity
    cameraBondOffset*: Coord
    fList, fAddList: seq[Entity]


#=======#
# Scene #
#=======#

proc init*(scene: Scene) =
  scene.camera = nil
  scene.cameraBond = nil
  scene.cameraBondOffset = (0.0, 0.0)
  scene.fList = @[]
  scene.fAddList = @[]


proc eventScene*(scene: Scene, e: sdl.Event) =
  for entity in scene.fList:
    entity.event(e)


method event*(scene: Scene, e: sdl.Event) {.base.} =
  scene.eventScene(e)


method show*(scene: Scene) {.base.} =
  ##  Called when ``scene`` is set in ``Game``.
  ##
  discard


method hide*(scene: Scene) {.base.} =
  ##  Called when ``scene`` is replaced by other one in ``Game``.
  ##
  discard


proc renderScene*(scene: Scene) =
  ##  Default scene render procedure.
  ##
  ##  Call it from your scene render method.
  ##
  for entity in scene.fList:
    entity.render()
  # Should be in the scene level to be drawn on top of all entities
  if colliderOutline:
    for entity in scene.fList:
      if entity.collider != nil:
        entity.collider.render()


method render*(scene: Scene) {.base.} =
  scene.renderScene()


proc addEntity(scene: Scene, entity: Entity) =
  if scene.fList.len < 1:
    scene.fList.add(entity)
    return

  if scene.fList[scene.fList.high].layer <= entity.layer:
    scene.fList.add(entity)
    return

  var i = scene.fList.high-1
  while i >= 0:
    if scene.fList[i].layer <= entity.layer:
      scene.fList.insert(entity, i+1)
      return
    dec i

  scene.fList.insert(entity, 0)


proc delEntity(scene: Scene, index: int) =
  scene.fList.delete(index)


proc add*(scene: Scene, entity: Entity) =
  ##  Add a new ``entity`` to the ``scene``.
  ##
  scene.fAddList.add(entity)


template bindCameraTo*(scene: Scene, bond: Entity, offset: Coord) =
  ##  Bind the camera to the movement of the specific ``entity``.
  ##
  scene.cameraBond = bond
  scene.cameraBondOffset = offset


proc clear*(scene: Scene) =
  ##  Remove all entities from the scene.
  ##
  while scene.fList.len > 0:
    discard scene.fList.pop()


proc contains*(scene: Scene, entity: Entity): bool {.inline.} =
  ##  ``Return`` `true` if the ``scene`` has the ``entity``,
  ##  or `false` otherwise.
  ##
  return entity in scene.fList


proc contains*(scene: Scene, tag: string): bool =
  ##  ``Return`` `true` if the ``scene`` has an entity with ``tag``,
  ##  or `false` otherwise.
  ##
  for entity in scene.fList:
    if tag in entity.tags:
      return true
  return false


proc count*(scene: Scene): int {.inline.} =
  ##  ``Return`` the number of entities in the ``scene``.
  ##
  return scene.fList.len


proc count*(scene: Scene, tag: string): int =
  ##  ``Return`` the number of entities with ``tag`` in the ``scene``.
  ##
  result = 0
  for entity in scene.fList:
    if tag in entity.tags:
      inc result


proc del*(scene: Scene, entity: Entity): bool =
  ##  Delete ``entity`` from the ``scene``.
  ##
  ##  ``Return`` `true` if ``entity`` was deleted,
  ##  or `false` if there is no such ``entity`` in the scene.
  ##
  let idx = scene.fList.find(entity)
  if idx < 0:
    return false
  scene.delEntity(idx)
  return true


proc del*(scene: Scene, tag: string) =
  ##  Delete all entities with ``tag`` from the ``scene``.
  ##
  var idx = 0
  while idx < scene.fList.len:
    if tag in scene.fList[idx].tags:
      scene.delEntity(idx)
      continue
    inc idx


proc find*(scene: Scene, tag: string): Entity =
  ##  ``Return`` the first entity with ``tag`` in the ``scene``,
  ##  or `nil` otherwise.
  ##
  for entity in scene.fList:
    if tag in entity.tags:
      return entity
  return nil


proc findAll*(scene: Scene, tag: string): seq[Entity] =
  ##  ``Return`` a sequence of all entities with ``tag`` in the ``scene``,
  ##  or an empty sequence if no such entities are found.
  ##
  result = @[]
  for entity in scene.fList:
    if tag in entity.tags:
      result.add(entity)


proc pop*(scene: Scene): Entity {.inline.} =
  ##  ``Return`` the top entity and remove it from the ``scene``.
  ##
  return scene.fList.pop()


iterator entities*(scene: Scene): Entity {.inline.} =
  ##  Iterate through all entities in the ``scene``.
  ##
  for entity in scene.fList:
    yield entity


iterator entities*(scene: Scene, tag: string): Entity {.inline.} =
  ##  Iterate throught entities with ``tag`` in the ``scene``.
  ##
  for entity in scene.fList:
    if tag in entity.tags:
      yield entity


proc updateScene*(scene: Scene, elapsed: float) =
  ##  Default scene update procedure.
  ##
  ##  Call it from your scene update method.
  ##

  # delete
  var
    i = 0
    len = scene.fList.len
  while i < len:
    # marked as dead
    if scene.fList[i].dead:
      scene.delEntity(i)
      dec len
      continue
    # marked as changed layer
    if scene.fList[i].updLayer:
      scene.fList[i].updLayer = false
      scene.fAddList.add(scene.fList[i])
      scene.delEntity(i)
      dec len
      continue
    inc i

  # add
  while scene.fAddList.len > 0:
    let entity = scene.fAddList.pop()
    entity.updLayer = false
    scene.addEntity(entity)

  # camera
  if not (scene.cameraBond == nil):
    scene.camera.pos = -scene.cameraBond.pos + scene.cameraBondOffset

  # update
  for entity in scene.fList:
    entity.update(elapsed)
    if entity.collider != nil:
      entity.colliding = @[]

  # collisions
  for entity in scene.fList:
    if entity.collider != nil:
      entity.checkCollisions(scene.fList)


method update*(scene: Scene, elapsed: float) {.base.} =
  scene.updateScene(elapsed)

