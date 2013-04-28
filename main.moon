-- TODO: remove all the reloader stuff

require "lovekit.all"
reloader = require "lovekit.reloader"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math

import unpack from _G

p = (str, ...) -> g.print str\lower!, ...

require "system"
require "bullets"
require "particles"
require "enemies"
require "hud"
require "levels"
require "player"

system = TrapSystem 0.002

bump = (t) -> sin(t*2) * cos(t*8)

export ^

class Ground
  width: 0.7 -- of screen

  new: =>
    @elapsed = 0
    @img = imgfy "img/ground.png"
    @img\set_wrap "repeat", "repeat"

    @effect = g.newPixelEffect [[
      extern number time;
      extern bool persp;

      vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
        float x = 1 - st.x - 0.5;
        float y = st.y;
        if (persp) {
          x /= y * 1.5 + 1.5;
        }

        return texture2D(tex, vec2(x - time, y));
      }
    ]]

  draw: =>
    g.push!
    g.translate 0, g.getHeight! * (1 - @width)
    g.scale g.getWidth! / @img\width!, g.getHeight! / @img\height! * @width

    @effect\send "persp", 1
    g.setPixelEffect @effect

    @img\draw 0, 0
    g.pop!

    g.setPixelEffect!

  update: (dt) =>
    @elapsed += dt / 5
    @effect\send "time", @elapsed

class Platform
  wall_height: 20
  width: 500
  height: 120

  min_oy: 197
  max_oy: 402

  inner_height: 40
  inner_width: 580

  new: =>
    @ox, @oy = g.getWidth! / 2, g.getHeight! * .54
    @elapsed = 0

    @hitbox = Box 0,0,450,120

    @box = Box -@width/2, -@height/2, @width, @height
    @inner_box = Box -@inner_width/2, -@inner_height/2, @inner_width, @inner_height
    @recalc!

    @wheels = {
      Wheel 50, 5, -10
      Wheel 50, -5, -10

      with Wheel 40, 5, -10
        .front_color = { 120,120,120 }
        .back_color = { 50,50,50 }
        .line_color = { 80, 80, 80 }

      with Wheel 40, -5, -10
        .front_color = { 120,120,120 }
        .back_color = { 50,50,50 }
        .line_color = { 80, 80, 80 }
    }

  recalc: =>
    @floor = system\project_box @box
    @inner_floor = system\project_box @inner_box

  collides: (thing) =>
    if pt = thing.pos
      thing.in_control_zone = false

      return false if @box\touches_pt pt.x, pt.y
      if @inner_box\touches_pt pt.x, pt.y
        thing.in_control_zone = true
        return false

    true

  transformed: (fn) =>
    elapsed = @elapsed

    g.push!
    g.translate @ox, @oy

    g.rotate sin(elapsed * 10) * 0.02

    g.translate cos(elapsed * 6) * 5,
      cos(elapsed * 12) * 3

    fn elapsed

    g.pop!

  draw: (fn) =>
    @draw_body!
    fn! if fn
    @draw_wheels!

  draw_body: =>
    @transformed (elapsed) ->
      g.setColor 200,200,200
      { :floor, :inner_floor, :wall_height } = @

      -- back wheels
      wheel_inset = 60

      -- wheel 1
      wx, wy = system\project @box.x + wheel_inset, @box.y
      @wheels[3]\draw wx, wy - 10 + bump(elapsed*2) * 10

      -- wheel 2
      wx, wy = system\project @box.x + @box.w - wheel_inset, @box.y
      @wheels[4]\draw wx, wy - 10 + bump(elapsed*2 + 0.8) * 10


      -- bottom wall
      g.setColor 60,60,60
      g.rectangle "fill", floor[7], floor[8],
        floor[5] - floor[7], wall_height

      g.rectangle "fill", inner_floor[7], inner_floor[8],
        inner_floor[5] - inner_floor[7], wall_height

      g.setColor 200,200,200

      -- top wall
      g.rectangle "fill", floor[1], floor[2] - wall_height,
        floor[3] - floor[1], wall_height

      inner_floor\draw 106, 109, 111
      floor\draw 141, 142, 143, 83, 85, 86

      g.setColor 255,255,255


  draw_wheels: =>
    @transformed (elapsed) ->
      wheel_inset = 60
      -- wheel 1
      wx, wy = system\project @box.x, @box.y + @box.h
      @wheels[1]\draw wx + wheel_inset, wy + 30 + bump(elapsed*2) * 10

      -- wheel 2
      wx, wy = system\project @box.x + @box.w, @box.y + @box.h
      @wheels[2]\draw wx - wheel_inset, wy + 30 + bump(elapsed*2 + 0.8) * 10

  move: (dy) =>
    @oy += dy / 5

    if @oy > @max_oy
      @oy = @max_oy

    if @oy < @min_oy
      @oy = @min_oy

  position: =>
    (@oy - @min_oy) / (@max_oy - @min_oy)

  row: =>
    f(_min(@position! * 3, 2)) + 1

  update: (dt, world) =>
    @elapsed += dt

    @hitbox\move_center @ox, @oy

    for w in *@wheels
      w\update dt

  take_hit: (barrier, world) =>
    s = Sequence ->
      with world.particles
        for i = 1,8
          \add Explosion world, @hitbox\random_point!
          wait rand 0.05, 0.1

    s.draw = -> -- lol
    world.particles\add s
    world.game.viewport\shake 20

class Wheel
  segments: 6
  speed: 6
  num_lines: 15

  back_color: { 100,100,100 }
  front_color: { 190,190,190 }
  line_color: { 180, 180, 180 }

  new: (@radius, @ox, @oy)=>
    @elapsed = 0

  update: (dt) =>
    @elapsed += dt * @speed

  draw: (cx, cy) =>
    -- back
    g.setColor unpack @back_color
    g.push!
    g.translate cx + @ox, cy + @oy
    g.rotate @elapsed
    g.circle "fill", 0,0, @radius, @segments
    g.pop!

    -- lines
    g.setColor unpack @line_color

    line_dir = Vec2d(@radius, 0)\rotate @elapsed
    for rad= 0, 2*math.pi, 2*math.pi / @num_lines
      l = line_dir\rotate rad
      lx, ly = cx + l[1], cy + l[2]
      g.line lx, ly, lx + @ox, ly + @oy

    -- front
    g.setColor unpack @front_color
    g.push!
    g.translate cx, cy
    g.rotate @elapsed
    g.circle "fill", 0,0, @radius, @segments
    g.pop!


class Game
  show_fps: false
  shroud: 0

  new: =>
    @updated = false
    @player = Player 0,0
    @world = World @, @player
    @hud = Hud @world
    @viewport = with EffectViewport scale: 1
      import effects from lovekit
      .shake = (amount=20) =>
        @effects\add effects.ViewportShake 0.8, 5, amount

    @shroud = 255
    @seq = Sequence ->
      tween @, 1.0, shroud: 0
      @seq = nil

  goto_gameover: =>
    @seq = Sequence ->
      tween @, 1.0, shroud: 255
      dispatch\push GameOver!

  on_key: (key, code) =>
    if key == "return"
      @world.started = true

    -- TODO: remove me
    if key == "f2"
      @player.life = 0
      @player\take_hit {}, @world
      return

    if key == "p"
      @paused = not @paused

    if key == "f1"
      @show_fps = not @show_fps

    if key == "x"
      print "Entities"
      for i, e in ipairs @world.entities
        print i, e.__class.__name, e.alive

      print "> Dead List"
      for i in *@world.entities.dead_list
        print ">", i

      print!
      print "Particles"
      for i, e in ipairs @world.particles
        print i, e.__class.__name, e.alive

      print "> Dead List"
      for i in *@world.particles.dead_list
        print ">", i

  mousepressed: (x,y) =>
    @player\shoot @world

  draw: =>
    return unless @updated

    @viewport\apply!

    @world\draw!
    @hud\draw!

    @viewport\pop!

    if @shroud > 0
      @viewport\draw {0,0,0, @shroud}

    if @show_fps
      g.setColor 255,255,255
      g.scale 2
      g.translate 10, 100
      p tostring(timer.getFPS!), 0,0
      p tostring("b: #{@world\block_i!}, bp: #{@world\block_progress!}"), 0,10
      p tostring("ne: #{@world.active_e}-#{#@world.entities}, np: #{@world.active_p}-#{#@world.particles}"), 0,20
      p tostring("de: #{#@world.entities.dead_list}, dp: #{#@world.particles.dead_list}"), 0,30

  update: (dt) =>
    @updated = true
    return if @paused

    @seq\update dt if @seq
    @viewport\update dt
    @world\update dt
    @hud\update dt, @world

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 10, 6, 9
  g.setPointSize 12

  font = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont font

  export sfx = lovekit.audio.Audio "sounds"
  sfx\preload { }
  -- TODO: bring music back
  sfx.play_music = ->

  -- TODO: title screen
  export dispatch = Dispatcher Game!
  dispatch\bind love

  if reloader
    old = love.update
    love.update = (...) ->
      reloader\update ...
      old ...

