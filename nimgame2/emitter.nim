# nimgame2/emitter.nim
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
  entity, random, scene, types, utils


type
  Particle* = ref object of Entity
    ttl*: float ##  Time to live (in seconds)


  Emitter* = ref object of Entity
    randomVel*, randomAcc*: Coord     ##  Ranges of vel and acc deviation
    randomRot*, randomRotVel*: Angle  ##  Ranges of rot and rotVel deviation
    randomScale*: Scale               ##  Range of scale deviation
    randomTTL*: float                 ##  Range of TTL deviation
    scene*: Scene                     ##  Target scene
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


proc copy*(target, source: Particle) =
  ##  Copy ``source`` properties to the ``target``.
  ##
  Entity(target).copy(Entity(source))
  target.ttl = source.ttl


method update*(particle: Particle, elapsed: float) =
  particle.updateEntity(elapsed)
  particle.ttl -= elapsed
  if particle.ttl < 0:
    particle.dead = true


#=========#
# Emitter #
#=========#

proc initEmitter*(emitter: Emitter, scene: Scene) =
  ##  Create a new ``Emitter`` for the ``scene``.
  ##
  emitter.initEntity()
  emitter.scene = scene
  emitter.particle = nil


proc newEmitter*(scene: Scene): Emitter =
  ##  Create a new Emitter in the ``scene``.
  ##
  result = new Emitter
  result.initEmitter(scene)


proc emit*(emitter: Emitter, amount: int = 1) =
  ##  Emit an ``amount`` of particles.
  ##
  if emitter.particle == nil:
    return
  for i in 1..amount:
    let particle = newParticle()
    particle.copy(emitter.particle)
    particle.pos = emitter.pos
    particle.rot = emitter.rot
    # set random deviations
    particle.vel.x += random(-emitter.randomVel.x..emitter.randomVel.x)
    particle.vel.y += random(-emitter.randomVel.y..emitter.randomVel.y)
    particle.acc.x += random(-emitter.randomAcc.x..emitter.randomAcc.x)
    particle.acc.y += random(-emitter.randomAcc.y..emitter.randomAcc.y)
    particle.rot += random(-emitter.randomRot..emitter.randomRot)
    particle.rotVel += random(-emitter.randomRotVel..emitter.randomRotVel)
    particle.scale += random(-emitter.randomScale..emitter.randomScale)
    particle.ttl += random(-emitter.randomTTL..emitter.randomTTL)
    # add to the scene
    emitter.scene.add(particle)

