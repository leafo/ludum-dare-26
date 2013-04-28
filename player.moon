
import watch_class from require "lovekit.reloader"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math
import unpack from _G

system = TrapSystem 0.002

export ^

class Gun extends Box
  watch_class @

  ox: 2
  oy: 5

  length: 20

  new: (@entity) =>
    @dir = Vec2d 1,0

  tip: =>
    unpack Vec2d(@length, 0)\rotate(@dir\radians!)\adjust @entity.gx, @entity.gy

  draw: (gx, gy) =>
    g.push!
    g.translate gx, gy

    g.rotate @dir\radians!
    g.translate -@ox, -@oy
    g.rectangle "fill", 0, 0, 20, 10
    g.pop!

  update: (dt) =>

class Player extends Entity
  watch_class @
  lazy_value @, "sprite", -> Spriter "img/player.png", 64, 64

  mover = make_mover "w", "s", "a", "d"

  w: 15
  h: 50

  -- cool
  offsets: {
    left: {
      ox: 7
      oy: 60

      sx: 6
      sy: 0

      gox: 5
      goy: 28
    }

    right: {
      ox: 7
      oy: 60

      sx: -5
      sy: 0

      gox: -5
      goy: 28
    }

  }

  za: -1400

  speed: 200

  -- box holds world coordinates
  -- pos is position in system coordintes
  new: (x=0, y=0) =>
    @pos = { :x, :y }
    @gun = Gun @
    @box = Box 0,0, @w, @h

    with @sprite
      @anim = StateAnim "stand_left", {
        stand_left: \seq { 0 }, 0, true
        stand_right: \seq { 0 }

        walk_left: \seq { 1, 2, 0 }, 0.12, true
        walk_right: \seq { 1, 2, 0 }, 0.12
      }

    -- z velocity, accel
    @zv = 0
    @z = 0

  update_box: (world) =>
    x, y = system\project @pos.x, @pos.y

    -- feet position
    fx = x + world.platform.ox
    fy = y + world.platform.oy

    {:ox, :oy, :gox, :goy} = @offsets[@last_direction or "left"]

    -- gun position
    @gx = fx - gox
    @gy = fy - goy - @z

    @box.x = fx - ox
    @box.y = fy - oy - @z

    @fx, @fy = fx, fy

  draw: =>
    return unless @box
    -- if @in_control_zone
    --   g.setColor 100, 200, 100

    -- shadow
    g.setColor 255,255,255
    g.push!
    @sprite\draw "150,107,23,10", @fx, @fy, 0, 2, 2, 11, 5
    g.pop!

    { :sx, :sy } = @offsets[@last_direction or "left"]

    g.push!
    g.translate @fx - sx, @fy - 40 - @z - sy
    g.scale 2, 2

    g.setColor 255,255,255
    @anim\draw -32, -32
    g.pop!

    -- gun
    g.setColor 255,100,100
    @gun\draw @gx, @gy
    g.setColor 255,255,255

    -- show bounding box and feed
    if false
      g.setColor 100, 255, 100
      @box\outline!
      g.point @fx , @fy

  update: (dt, world) =>
    dir = mover(@speed) * dt
    cx, cy = @fit_move dir[1], dir[2], world, @pos

    @anim\set_state @direction_name "left", Vec2d dir[1], 0
    @anim\update dt

    max_jump_time = 0.2
    if keyboard.isDown " "
      if not @jump_time or @jump_time < max_jump_time
        @jump_time or= 0
        @jump_time += dt
        pp = @jump_time / max_jump_time
        @zv = sqrt(pp) * 400
    else
      if @z == 0
        @jump_time = nil
      else
        @jump_time = max_jump_time

    @zv += dt * @za
    @z += @zv * dt
    if @z < 0
      @zv = 0
      @z = 0

    if @in_control_zone and cy
      world.platform\move dir[2]

    @update_box world

    mx, my = mouse.getPosition!
    @gun.dir = (Vec2d(mx, my) - Vec2d(@gx, @gy))\normalized!

    @gun\update dt, world

  take_hit: (thing, world) =>
    if thing.is_enemy_bullet
      spray_dir = thing.vel\normalized!\flip!
      thing.life = 0
      world.particles\add BloodSquirt spray_dir, world, thing\center!

