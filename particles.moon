
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


class Shrapnel extends Spark
  min_mod: 0
  max_mod: 2

  cell: 2


class Smoke extends Spark
  speed: 200
  gravity: -400

  life: 2.0

  min_mod: 1
  max_mod: 3

  cell: 3

class Flare extends Spark
  speed: 200
  gravity: -400

  life: 0.8

  min_mod: 1
  max_mod: 3

  cell: 4

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

class Explosion extends Emitter
  make_particle: (x,y) =>
    with @world.particles
      \add Smoke x,y, Vec2d(0,1)\rotate(rand 0, math.pi*2) * Smoke.speed
      \add Spark x,y, Vec2d(0,1)\rotate(rand 0, math.pi*2) * Spark.speed
      \add Flare x,y, Vec2d(0,1)\rotate(rand 0, math.pi*2) * Flare.speed

    Shrapnel x,y, Vec2d(0,1)\rotate(rand 0, math.pi*2) * Shrapnel.speed

nil
