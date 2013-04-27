
{ graphics: g } = love
{ :cos, :sin, :pi } = math

export *

-- do
--   mt = getmetatable Emitter
--   cons = mt.__call
--   mt.__call = (...) ->
--     print "creating an emitter"
--     cons ...

class Sparks extends Emitter
  make_particle: (x,y) =>
    Spark x,y

class Spark extends Particle
  life: 2.0

  lazy_value @, "sprite", ->
    Spriter "img/sprite.png", 32, 32

  new: (...) =>
    super ...
    speed = rand 80, 300
    dir = rand 0, 2*pi

    @time = 0
    @mod = rand -1.0, 1.0

    @vel[1] = speed * cos dir
    @vel[2] = speed * sin dir

    @accel[2] = 300

  draw: =>
    g.push!
    g.translate @x, @y
    g.rotate @time * @mod

    @sprite\draw 0, 0, 0
    g.pop!

  update: (dt, ...) =>
    @time += dt
    super dt, ...
    
nil
