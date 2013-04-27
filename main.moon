
require "lovekit.all"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

class Game

love.load = ->
  g.setBackgroundColor 52/2, 57/2, 61/2
  g.setPointSize 12

  dispatch = Dispatcher Game!
  dispatch\bind love

