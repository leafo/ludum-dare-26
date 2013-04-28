
{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

export *

class Bullet extends Box
  size: 8
  speed: 500
  is_bullet: true

  color: { 255, 246, 119 }

  new: (@vel, x, y) =>
    half = @size / 2

    super f(x - half), f(y - half), @size, @size

    @rads = @vel\normalized!\radians!
    @life = 3

  draw: =>
    -- hitbox
    g.rectangle "line", @x, @y, @w, @h

    -- trail
    g.setColor unpack @color
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
    @life > 0 and world.expanded_box\touches_box @

class EnemyBullet extends Bullet
  is_enemy_bullet: true

  color: { 226, 102, 207 }

nil
