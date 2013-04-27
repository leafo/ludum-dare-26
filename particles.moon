
{ graphics: g } = love
{ :cos, :sin, :pi } = math

export *

lazy_value Particle, "sprite", ->
  Spriter "img/sprite.png", 32, 32

class Spark extends Particle
  life: 2.0
  speed: 300
  gravity: 300
  cell: 0

  min_mod: -1.0
  max_mod: 1.0

  new: (...) =>
    super ...
    @time = 0
    @mod = rand @min_mod, @max_mod
    @accel[2] = @gravity

  draw: =>
    g.push!
    g.translate @x, @y
    g.rotate @time * @mod

    s = @mod + 1.5
    g.scale s,s

    g.setColor @r, @g, @b, 255 * (1 - @p!)
    @sprite\draw @cell, -16, -16
    g.pop!

  update: (dt, ...) =>
    @time += dt
    super dt, ...
    
class Blood extends Spark
  gravity: 700
  life: 1.0
  min_mod: 0
  cell: 1


class DirectionalEmitter extends Emitter
  type: nil
  width: 1

  new: (@dir, ...) =>
    super ...

  make_particle: (x,y) =>
    particle_cls = @type
    particle_cls x,y, @dir\rotate(rand -@width, @width) * particle_cls.speed

class Sparks extends DirectionalEmitter
  type: Spark

class BloodSquirt extends DirectionalEmitter
  type: Blood

nil
