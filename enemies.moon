
export *

-- stores enemies in the entity list in the world
class EnemySpawner extends Sequence
  new: (@world) =>
    super ->
      @world.entities\add Enemy 0, 100, Vec2d(100, 0)
      wait 1.0
      again!

  draw: =>

class Enemy extends Box
  is_enemy: true
  w: 30
  h: 30

  life: 100

  color: { 209, 100, 121 }

  new: (@x, @y, @vel=Vec2d(0,0), @accel=Vec2d(0,0))=>

  take_hit: (thing, world) =>
    if thing.is_bullet
      thing.alive = false
      @life -= 50

      spray_dir = thing.vel\normalized!
      world.particles\add Sparks spray_dir, world, thing\center!

  update: (dt, world) =>
    @vel\adjust unpack @accel * dt
    @move unpack @vel * dt

    @life > 0

  draw: =>
    super @color

nil
