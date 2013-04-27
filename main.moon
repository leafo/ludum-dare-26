

reloader = require "lovekit.reloader"
require "lovekit.all"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

local *

p = (str, ...) -> g.print str\lower!, ...

require "system"
require "particles"
require "enemies"

system = TrapSystem 0.002

bump = (t) -> sin(t*2) * cos(t*8)

shadow = (box) ->
  {:w, :h, :x, :y} = box

  g.setColor 0,0,0, 80
  sw = w * 1.5
  sh = 7

  g.rectangle "fill", x + (w - sw) / 2,  y  + h - sh/2, sw, sh

class World
  new: (@game, @player) =>
    @entities = DrawList! -- things that collide
    @particles = DrawList! -- things that don't collide

    @collide = UniformGrid!

    @platform = Platform!
    @ground = Ground!

    @particles\add EnemySpawner @

    @box = Box 0, 0, g.getWidth!, g.getHeight!

  draw: =>
    @ground\draw!

    @platform\draw_body!
    @player\draw!
    @platform\draw_wheels!

    @entities\draw!
    @particles\draw!
    g.setColor 255,255,255

  collides: (thing) =>
    @platform\collides thing

  update: (dt) =>
    @platform\update dt, @
    @player\update dt, @
    @particles\update dt, @
    @entities\update dt, @
    @ground\update dt, @

    -- collision
    @collide\clear!
    @collide\add @player.box, @player
    for e in *@entities
      if e.alive != false
        @collide\add e

    for e in *@entities
      continue unless e.is_enemy
      for thing in *@collide\get_touching e
        e\take_hit thing, @

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
  height: 150

  inner_height: 40
  inner_width: 580

  new: =>
    @ox, @oy = g.getWidth! / 2, g.getHeight! * (2/3)
    @elapsed = 0

    @box = Box -@width/2, -@height/2, @width, @height
    @inner_box = Box -@inner_width/2, -@inner_height/2, @inner_width, @inner_height
    @recalc!

    @wheels = {
      Wheel 50, 5, -10
      Wheel 50, -5, -10
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

  draw_body: =>
    @transformed ->
      g.setColor 200,200,200

      -- top wall
      g.rectangle "fill", @floor[1], @floor[2] - @wall_height,
        @floor[3] - @floor[1], @wall_height

      @inner_floor\draw 106, 109, 111
      @floor\draw 141, 142, 143, 83, 85, 86

      -- bottom wall
      g.setColor 60,60,60
      g.rectangle "fill", @floor[7], @floor[8],
        @floor[5] - @floor[7], @wall_height

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


  draw: =>
    { :elapsed } = @

    g.push!
    g.translate @ox, @oy

    g.rotate sin(elapsed * 10) * 0.02

    g.translate cos(elapsed * 6) * 5,
      cos(elapsed * 12) * 3

    g.setColor 200,200,200

    -- top wall
    g.rectangle "fill", @floor[1], @floor[2] - @wall_height,
      @floor[3] - @floor[1], @wall_height

    @inner_floor\draw 106, 109, 111
    @floor\draw 141, 142, 143, 83, 85, 86

    -- bottom wall
    g.setColor 60,60,60
    g.rectangle "fill", @floor[7], @floor[8],
      @floor[5] - @floor[7], @wall_height

    g.setColor 255,255,255

    wheel_inset = 60
    -- wheel 1
    wx, wy = system\project @box.x, @box.y + @box.h
    @wheels[1]\draw wx + wheel_inset, wy + 30 + bump(elapsed*2) * 10

    -- wheel 2
    wx, wy = system\project @box.x + @box.w, @box.y + @box.h
    @wheels[2]\draw wx - wheel_inset, wy + 30 + bump(elapsed*2 + 0.8) * 10

    g.pop!

  move: (dy) =>
    @oy += dy / 5

  update: (dt, world) =>
    @elapsed += dt

    for w in *@wheels
      w\update dt

    -- vec = movement_vector! * 100 * dt
    -- @ox += vec[1]
    -- @oy += vec[2]

class Bullet extends Box
  size: 8
  speed: 500
  is_bullet: true

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

class Wheel
  segments: 6
  speed: 6
  num_lines: 15

  new: (@radius, @ox, @oy)=>
    @elapsed = 0

  update: (dt) =>
    @elapsed += dt * @speed

  draw: (cx, cy) =>
    -- back
    g.setColor 80,80,80
    g.push!
    g.translate cx + @ox, cy + @oy
    g.rotate @elapsed
    g.circle "fill", 0,0, @radius, @segments
    g.pop!

    -- lines
    g.setColor 180,180,180

    line_dir = Vec2d(@radius, 0)\rotate @elapsed
    for rad= 0, 2*math.pi, 2*math.pi / @num_lines
      l = line_dir\rotate rad
      lx, ly = cx + l[1], cy + l[2]
      g.line lx, ly, lx + @ox, ly + @oy

    -- front
    g.setColor 200,200,200
    g.push!
    g.translate cx, cy
    g.rotate @elapsed
    g.circle "fill", 0,0, @radius, @segments
    g.pop!


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

  w: 20
  h: 40

  ox: 10
  oy: 40

  speed: 200

  -- box holds world coordinates
  -- pos is position in system coordintes
  new: (x=0, y=0) =>
    @pos = { :x, :y }
    @gun = Gun @
    @box = Box 0,0, @w, @h

  update_box: (world) =>
    x, y = system\project @pos.x, @pos.y
    @box.x = x + world.platform.ox - @ox
    @box.y = y + world.platform.oy - @oy

  draw: =>
    return unless @box
    if @in_control_zone
      g.setColor 100, 200, 100

    -- shadow
    shadow @box

    g.setColor 255,255,255
    @box\draw!
    g.setColor 255,100,100
    @gun\draw @box\center!
    g.setColor 255,255,255

  update: (dt, world) =>
    dir = mover(@speed) * dt
    cx, cy = @fit_move dir[1], dir[2], world, @pos

    if @in_control_zone and cy
      world.platform\move dir[2]

    @update_box world

    mx, my = mouse.getPosition!
    @gun.dir = (Vec2d(mx, my) - Vec2d(@box\center!))\normalized!

    @gun\update dt, world


class Game
  show_fps: true

  new: =>
    @player = Player 0,0
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
    @thing\update dt


love.load = ->
  g.setBackgroundColor 10, 6, 9
  g.setPointSize 12

  dispatch = Dispatcher Game!
  dispatch\bind love

  if reloader
    old = love.update
    love.update = (...) ->
      reloader\update ...
      old ...

