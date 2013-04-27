
require "lovekit.all"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

local *

p = (str, ...) -> g.print str\lower!, ...

barycentric_coords = (x1, y1, x2, y2, x3,y3, px, py) ->
  det = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)

  b1 = (y2 - y3) * (px - x3) + (x3 - x2) * (py - y3)
  b2 = (y3 - y1) * (px - x3) + (x1 - x3) * (py - y3)

  b1 = b1 / det
  b2 = b2 / det
  b3 = 1 - b1 - b2

  b1, b2, b3

pt_in_tri = (...) ->
  b1, b2, b3 = barycentric_coords ...
  return false if b1 < 0 or b2 < 0 or b3 < 0
  true

class Quad
  -- clockwise from top left
  new: (x1, y1, x2, y2, x3, y3, x4, y4) =>
    @[1] = x1
    @[2] = y1

    @[3] = x2
    @[4] = y2

    @[5] = x3
    @[6] = y3

    @[7] = x4
    @[8] = y4

  draw: =>
    g.setColor 255,255,255, 128
    g.triangle "fill",
      @[1], @[2],
      @[3], @[4],
      @[5], @[6]

    g.setColor 255,255,255, 64
    g.triangle "fill",
      @[1], @[2],
      @[5], @[6],
      @[7], @[8]

    g.setColor 255,100,100
    g.point @[1], @[2]
    g.setColor 100,255,100
    g.point @[3], @[4]
    g.setColor 100,100,255
    g.point @[5], @[6]
    g.setColor 100,255,255
    g.point @[7], @[8]
    g.setColor 255,255,255

  contains_pt: (x,y) =>
    return true if pt_in_tri @[1], @[2],
      @[3], @[4],
      @[5], @[6],
      x,y

    return true if pt_in_tri @[1], @[2],
      @[5], @[6],
      @[7], @[8],
      x,y

    false

  __tostring: =>
    "vec2d<(%f, %f), (%f, %f), (%f, %f), (%f, %f)>"\format unpack @

class World
  new: (@game, @player) =>
    @entities = DrawList!

    @floor = Quad 100, 100,
      200, 120,
      220, 220,
      80, 210

  draw: =>
    @floor\draw!
    @player\draw!
    @entities\draw!

  collides: (thing) =>
    box = thing.box or box
    cx, cy = box\center!
    not @floor\contains_pt cx, cy

  update: (dt) =>
    @player\update dt, @
    @entities\update dt, @

class Bullet extends Box
  size: 8
  speed: 300

  new: (@vel, x, y) =>
    half = @size / 2

    super f(x - half), f(y - half), @size, @size

    @rads = @vel\normalized!\radians!
    @life = 3

  draw: =>
    -- hitbox
    g.rectangle "line", @x, @y, @w, @h

    -- trail
    g.setColor 255, 246, 119
    g.push!
    g.translate @center!

    g.scale 3, 3
    g.rotate @rads
    g.rectangle "fill", -5, -1, 5, 2
    g.pop!
    g.setColor 255, 255, 255


  update: (dt, world) =>
    @move unpack @vel * @speed * dt

    @life -= dt
    @life > 0

class Gun extends Box
  ox: 2
  oy: 5

  length: 20

  new: (@entity) =>
    @dir = Vec2d 1,0

  tip: =>
    unpack Vec2d(@length, 0)\rotate(@dir\radians!)\adjust @entity.box\center!

  draw: (gx, gy) =>
    g.push!
    g.translate gx, gy

    g.rotate @dir\radians!
    g.translate -@ox, -@oy
    g.rectangle "fill", 0, 0, 20, 10
    g.pop!

  update: (dt) =>

class Player extends Entity
  mover = make_mover "w", "s", "a", "d"
  speed: 140

  new: (x=0, y=0) =>
    super nil, x, y
    @gun = Gun @

  draw: =>
    @box\draw!
    g.setColor 255,100,100
    @gun\draw @box\center!
    g.setColor 255,255,255

  update: (dt, world) =>
    dir = mover(@speed) * dt
    @fit_move dir[1], dir[2], world

    mx, my = mouse.getPosition!
    @gun.dir = (Vec2d(mx, my) - Vec2d(@box\center!))\normalized!

    @gun\update dt, world

class Game
  show_fps: true

  new: =>
    @player = Player 152, 162
    @world = World @, @player

  on_key: (key, code) =>
    if key == " "
      @paused = not @paused

  mousepressed: (x,y) =>
    @world.entities\add Bullet(@player.gun.dir, @player.gun\tip!)

  draw: =>
    @world\draw!

    if @show_fps
      g.scale 2
      p tostring(timer.getFPS!), 0,0

  update: (dt) =>
    return if @paused
    @world\update dt

love.load = ->
  g.setBackgroundColor 52/2, 57/2, 61/2
  g.setPointSize 12

  dispatch = Dispatcher Game!
  dispatch\bind love

