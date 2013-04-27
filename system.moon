
{graphics: g, :timer, :mouse, :keyboard} = love

local *

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

  draw: (top_r, top_g, top_b, bot_r=top_r, bot_g=top_g, bot_b=top_b) =>
    g.setColor top_r, top_g, top_b
    g.triangle "fill",
      @[1], @[2],
      @[3], @[4],
      @[5], @[6]

    g.setColor bot_r, bot_g, bot_b
    g.triangle "fill",
      @[1], @[2],
      @[5], @[6],
      @[7], @[8]

    -- g.setColor 255,100,100
    -- g.point @[1], @[2]
    -- g.setColor 100,255,100
    -- g.point @[3], @[4]
    -- g.setColor 100,100,255
    -- g.point @[5], @[6]
    -- g.setColor 100,255,255
    -- g.point @[7], @[8]
    -- g.setColor 255,255,255

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

class TrapSystem
  new: (@skew=0) =>

  -- project to Quad
  project_box: (box) =>
    ax, ay, bx, by = box\unpack2!

    x1, y1 = @project ax, ay
    x2, y2 = @project bx, ay

    x3, y3 = @project bx, by
    x4, y4 = @project ax, by

    Quad x1, y1, x2, y2, x3, y3, x4, y4

  -- form system to euclidean
  project: (x, y) =>
    x * (@skew * y + 1), y * (1 - @skew^0.3)

  -- euclidean to system
  unproject: (x, y) =>
    sy = y / (1 - @skew^0.3)
    x / (@skew * sy + 1), sy

class SystemTest
  skew: 0.003

  draw: =>
    system = TrapSystem @skew

    g.push!
    g.translate g.getWidth!/2, g.getHeight!/2
    g.scale 3, 3

    for y=-100, 100, 10
      for x=-100, 100, 10
        g.point system\project x,y

    g.pop!


if ... == "test"
  system = TrapSystem 0.003
  x, y = system\project 100, 100
  print x, y
  print system\unproject x, y

{ :TrapSystem, :SystemTest, :Quad }
