
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

  shoot: (world) =>
    sfx\play "player_shoot"
    world.entities\add PlayerBullet @dir, @tip!

  draw: (gx, gy, alpha=255) =>
    g.push!
    g.translate gx, gy

    g.rotate @dir\radians!
    g.translate -@ox, -@oy

    g.setColor 120,120,120, alpha
    g.rectangle "fill", 0, 0, 20, 10
    g.pop!

  update: (dt) =>

class Player extends Entity
  watch_class @
  lazy_value @, "sprite", -> Spriter "img/player.png", 64, 64

  mover = make_mover "w", "s", "a", "d"

  life: 100
  score: 0
  display_score: 0

  w: 15
  h: 50

  alpha: 255
  scale: 1

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
    @effects = DrawList!

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
    g.setColor 255,255,255, @alpha
    g.push!
    @sprite\draw "150,107,23,10", @fx, @fy, 0, 2, 2, 11, 5
    g.pop!

    { :sx, :sy } = @offsets[@last_direction or "left"]

    g.push!
    g.translate @fx - sx, @fy - 40 - @z - sy
    g.scale 2 * @scale, 2 * @scale

    g.setColor 255,255,255, @alpha
    @anim\draw -32, -32
    g.pop!

    -- gun
    @gun\draw @gx, @gy, @alpha

    -- show bounding box and feed
    if false
      g.setColor 100, 255, 100
      @box\outline!
      g.point @fx , @fy

  update: (dt, world) =>
    unless @locked
      dir = mover(@speed) * dt
      cx, cy = @fit_move dir[1], dir[2], world, @pos
      @anim\set_state @direction_name "left", Vec2d dir[1], 0

      max_jump_time = 0.2
      if keyboard.isDown " "
        if not @jump_time or @jump_time < max_jump_time
          @jump_time or= 0

          if @jump_time == 0
            @is_jumping = true
            sfx\play "jump"

          @jump_time += dt
          pp = @jump_time / max_jump_time
          @zv = sqrt(pp) * 400
      else
        if @z == 0
          if @is_jumping
            sfx\play "land"
            @is_jumping = false

          @jump_time = nil
        else
          @jump_time = max_jump_time

      if @in_control_zone and cy
        world.platform\move dir[2]

      mx, my = mouse.getPosition!
      @gun.dir = (Vec2d(mx, my) - Vec2d(@gx, @gy))\normalized!


    @anim\update dt
    @effects\update dt

    @display_score = approach @display_score, @score,
      dt * ((@score - @display_score) * 1.5 + 14)

    @zv += dt * @za
    @z += @zv * dt
    if @z < 0
      @zv = 0
      @z = 0

    @update_box world
    @gun\update dt, world

  p_life: =>
    @life / @@life

  take_hit: (thing, world) =>
    return if @locked

    if thing.is_enemy_bullet
      sfx\play "player_hit"
      @life -= 10
      spray_dir = thing.vel\normalized!\flip!
      thing.life = 0
      world.particles\add BloodSquirt spray_dir, world, thing\center!
      world.game.viewport\shake 5

    if thing.is_barrier
      sfx\play "player_hit"
      @life -= 33

    @life = math.max 0, @life
    -- death
    if @life == 0 and not @locked
      @locked = true
      sfx\play "player_die"

      @effects\add Sequence ->
        x,y = @box\center!
        world.particles\add Sparks Vec2d(0, -1), world, x,y, 1, 100
        tween @, 1.0, alpha: 0, scale: 10
        world.game\goto_gameover!

  shoot: (world) =>
    return if @locked
    @gun\shoot world


