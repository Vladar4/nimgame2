# nimgame2/emitter.nim
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
  entity, random, scene, types, utils


type
  Particle* = ref object of Entity
    ttl*: float ##  Time to live (in seconds)

  EmissionAreaKind* = enum
    eaPoint,
    eaLine,
    eaCircle,
    eaBox

  EmissionArea* = object
    case kind*: EmissionAreaKind
    of eaPoint:   discard
    of eaLine:    length*: float  ## line length
    of eaCircle:  radius*: float  ## circle radius
    of eaBox:     dim*: Dim       ## box dimensions

  Emitter* = ref object of Entity
    # Public
    randomVel*, randomAcc*: Coord     ##  Ranges of vel and acc deviation
    randomRot*, randomRotVel*: Angle  ##  Ranges of rot and rotVel deviation
    randomScale*: Scale               ##  Range of scale deviation
    randomTTL*: float                 ##  Range of TTL deviation
    scene*: Scene                     ##  Target scene
    area*: EmissionArea  ##  Area of particle emission
    particle*: Particle  ##  A stencil particle, its properties will be \\
                         ##  assigned to any created particles.


#==========#
# Particle #
#==========#

proc initParticle*(particle: Particle) =
  particle.initEntity()
  particle.physics = defaultPhysics
  particle.ttl = 1.0


proc newParticle*(): Particle =
  result = new Particle
  result.initParticle()


template copy*(target, source: Particle) =
  ##  Copy ``source`` properties to the ``target``.
  ##
  Entity(target).copy(Entity(source))
  target.ttl = source.ttl


proc updateParticle*(particle: Particle, elapsed: float) =
  particle.updateEntity(elapsed)
  particle.ttl -= elapsed
  if particle.ttl < 0:
    particle.dead = true


method update*(particle: Particle, elapsed: float) =
  updateParticle(particle, elapsed)


#=========#
# Emitter #
#=========#

proc initEmitter*(emitter: Emitter, scene: Scene) =
  ##  Create a new ``Emitter`` for the ``scene``.
  ##
  emitter.initEntity()
  emitter.scene = scene
  emitter.area = EmissionArea(kind: eaPoint)
  emitter.particle = nil


proc newEmitter*(scene: Scene): Emitter =
  ##  Create a new Emitter in the ``scene``.
  ##
  result = new Emitter
  result.initEmitter(scene)


proc emit*(emitter: Emitter, amount: int = 1,
           procedure: proc(p: Particle) = nil) =
  ##  Emit an ``amount`` of particles,
  ##  apply the ``procedure`` for each emitted particle.
  ##
  if emitter.particle == nil:
    return
  for i in 1..amount:
    let particle = newParticle()
    particle.copy(emitter.particle)
    particle.pos = emitter.pos
    particle.rot = emitter.rot
    # set random deviations
    # position
    case emitter.area.kind:
    of eaPoint: discard
    of eaLine:
      let point: Coord = (rand(emitter.area.length), 0.0)
      particle.pos = rotate(point * emitter.absScale,
                            emitter.absPos * emitter.parallax, emitter.absRot)
    of eaCircle:
      let
        angle = rand(360.0)
        point: Coord = (rand(emitter.area.radius), 0.0)
      particle.pos = rotate(point * emitter.absScale,
                            emitter.absPos * emitter.parallax, angle)
    of eaBox:
      let
        half = emitter.area.dim / 2
        point: Coord = (rand(-half.w..half.w), rand(-half.h..half.h))
      particle.pos = rotate(point * emitter.absScale,
                            emitter.absPos * emitter.parallax, emitter.absRot)
    # end of case emitter.area.kind
    # velocity
    particle.vel.x += rand(-emitter.randomVel.x..emitter.randomVel.x)
    particle.vel.y += rand(-emitter.randomVel.y..emitter.randomVel.y)
    # acceleration
    particle.acc.x += rand(-emitter.randomAcc.x..emitter.randomAcc.x)
    particle.acc.y += rand(-emitter.randomAcc.y..emitter.randomAcc.y)
    # rotation
    particle.rot += rand(-emitter.randomRot..emitter.randomRot)
    particle.rotVel += rand(-emitter.randomRotVel..emitter.randomRotVel)
    # scale
    particle.scale += rand(-emitter.randomScale..emitter.randomScale)
    # time to live
    particle.ttl += rand(-emitter.randomTTL..emitter.randomTTL)
    # perform the procedure
    if not (procedure == nil):
      procedure(particle)
    # add to the scene
    emitter.scene.add(particle)

