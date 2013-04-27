
{ graphics: g } = love
{ :cos, :sin, :pi } = math

export *

class Sparks extends Emitter
  new: (@dir, ...) =>
    super ...

  make_particle: (x,y) =>
    Spark x,y, @dir\rotate(rand -1, 1) * Spark.speed

class Spark extends Particle
  life: 2.0
  speed: 300

  lazy_value @, "sprite", ->
    Spriter "img/sprite.png", 32, 32

  new: (...) =>
    super ...
    @time = 0
    @mod = rand -1.0, 1.0
    @accel[2] = 300

  draw: =>
    g.push!
    g.translate @x, @y
    g.rotate @time * @mod

    s = @mod + 1.5
    g.scale s,s

    g.setColor 255,255,255, 255 * (1 - @p!)
    @sprite\draw 0, -16, -16
    g.pop!

  update: (dt, ...) =>
    @time += dt
    super dt, ...
    
nil
