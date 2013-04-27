
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
    @entities = {}

    @thing = Quad 100, 100,
      200, 120,
      220, 220,
      80, 210

  draw: =>
    @player\draw!

    @thing\draw!

  update: (dt) =>
    @player\update dt, @

class Player extends Entity
  mover = make_mover "w", "s", "a", "d"
  speed: 100

  new: (x=0, y=0) =>
    super nil, x, y

  draw: =>
    @box\draw!

  update: (dt, world) =>
    dir = mover(@speed) * dt
    @box\move unpack dir

class Game
  show_fps: true

  new: =>
    @player = Player 400, 400
    @world = World @, @player

  mousepressed: (x,y) =>
    print @world.thing\contains_pt x,y

  draw: =>
    @world\draw!

    if @show_fps
      g.scale 2
      p tostring(timer.getFPS!), 0,0

  update: (dt) =>
    @world\update dt

love.load = ->
  g.setBackgroundColor 52/2, 57/2, 61/2
  g.setPointSize 12

  dispatch = Dispatcher Game!
  dispatch\bind love

