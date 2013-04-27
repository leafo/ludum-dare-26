
{graphics: g, :timer, :mouse, :keyboard} = love

local *

class TrapSystem
  new: (@skew=0) =>

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

{ :TrapSystem, :SystemTest }
