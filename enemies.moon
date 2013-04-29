
{ graphics: g } = love

import insert from table

export *

-- 3 point bezier
bez3 = (x1, y1, x2, y2, x3, y3, t) ->
  tt = 1 - t

  x = tt * (tt * x1 + t * x2) + t * (tt * x2 + t * x3)
  y = tt * (tt * y1 + t * y2) + t * (tt * y2 + t * y3)

  x,y

-- derivative of 3 point bez
bez3_prime = (x1, y1, x2, y2, x3, y3, t) ->
  tt = 1 - t

  x = 2 * tt * (x2 - x1) + 2 * t * (x3 - x2)
  y = 2 * tt * (y2 - y1) + 2 * t * (y3 - y2)

  x,y

reverse = (t) ->
  return for i=#t,1,-1 do t[i]

class Thing
  speed: 200

  new: (@x, @y) =>
    @flip = false

  update: (dt) =>
    {:fx, :fy, :tx, :ty, :cx, :cy} = @

    if tx and fx
      before = @time
      @time += dt * @tscale
      if @time > 1
        @x, @y = @tx, @ty
        @tx, @ty = nil, nil
      else
        -- wow this is lame
        ax, ay = bez3 fx, fy, cx, cy, tx, ty, before
        bx, by = bez3 fx, fy, cx, cy, tx, ty, @time

        dx = bx - ax
        dy = by - ay

        @x += dx
        @y += dy

  draw: =>
    g.point @x ,@y

  move_to: (@tx, @ty) =>
    @time = 0
    @fx, @fy = @x, @y

    move = Vec2d(@tx - @fx, @ty - @fy)
    move_len = move\len!
    control_len = 1 + move_len / 4

    dir = move\normalized!\cross!
    dir = dir\flip! if @flip
    @flip = not @flip

    @cx = (@tx + @fx) / 2 + dir[1] * control_len
    @cy = (@ty + @fy) / 2 + dir[2] * control_len

    @tscale = 1 / move_len * @speed


-- stores enemies in the entity list in the world
class EnemySpawner extends Sequence
  new: (@world, num_enemies=3) =>
    super ->
      for i=1, num_enemies
        targets = PathEnemy\gen_targets @world, 2

        if math.random! < 0.5
          targets = reverse targets

        {ix, iy} = table.remove targets, 1

        -- @world.entities\add Enemy 0, 100, Vec2d(100, 0)
        @world.entities\add PathEnemy ix, iy, targets
        wait 2.0

  draw: =>

class Enemy extends Box
  is_enemy: true
  w: 30
  h: 30

  life: 100

  color: { 209, 100, 121 }

  new: (@x, @y, @vel=Vec2d(0,0), @accel=Vec2d(0,0))=>

  shoot: (world, dir) =>
    sfx\play "enemy_shoot"

    dir = (Vec2d(world.player.box\center!) - Vec2d(@center!))\normalized!
    world.entities\add EnemyBullet dir, @x, @y

  take_hit: (thing, world) =>
    if thing.is_bullet and not thing.is_enemy_bullet
      thing.life = 0
      @life -= 34

      spray_dir = thing.vel\normalized!
      world.particles\add Sparks spray_dir, world, thing\center!

      if @life > 0
        sfx\play "enemy_hit"
      else
        sfx\play "enemy_die"

  update: (dt, world) =>
    @vel\adjust unpack @accel * dt
    @move unpack @vel * dt

    @life > 0

  draw: =>
    super @color

Sequence.default_scope.bezier_move_to = (thing, tx, ty, speed) ->
  speed or= thing.speed

  fx = thing.x
  fy = thing.y

  move = Vec2d tx - fx, ty - fy
  move_len = move\len!
  control_len = 1 + move_len / 4

  dir = move\normalized!\cross!
  dir = dir\flip! if math.random! > 0.5

  cx = (tx + fx) / 2 + dir[1] * control_len
  cy = (ty + fy) / 2 + dir[2] * control_len

  tscale = 1 / move_len * speed

  time = 0
  remaining = 0

  before_x, before_y = fx, fy

  while time < 1
    dt = coroutine.yield!
    time += dt * tscale

    if time > 1
      remaining = (1 - time) / tscale
      time = 1

    -- wow this is lame
    nx, ny = bez3 fx, fy, cx, cy, tx, ty, smoothstep 0, 1, time

    dx = nx - before_x
    dy = ny - before_y

    before_x = nx
    before_y = ny

    thing.x += dx
    thing.y += dy

  if remaining > 0
    coroutine.yield "more", remaining

class PathEnemy extends Enemy
  @gen_targets: (world, num_targets=2) =>
    max_height = world.box.h * 0.4
    chunk = world.box.w / num_targets

    min_x = 0

    targets = {
      { world.box.x - 100, rand(-200, max_height) }
    }

    for i=1,num_targets
      table.insert targets, {
        rand min_x, min_x + chunk
        rand 0, max_height
      }
      min_x += chunk

    targets[#targets + 1] = {
      world.box.w + 200, rand(-200, max_height)
    }

    targets

  speed: 200

  new: (@x, @y, @targets) =>
    @speed = rand 150, 250

    @seq = Sequence ->
      for i, {x,y} in ipairs @targets
        bezier_move_to @, x, y
        unless i == #@targets
          @shoot @world
          wait rand 0.3, 0.7

  update: (dt, world) =>
    @world = world
    @seq\update(dt) and @life > 0

nil
