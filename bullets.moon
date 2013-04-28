
{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

export *

class Bullet extends Box
  lazy_value @, "sprite", -> Player.sprite

  size: 8
  speed: 500
  is_bullet: true

  color: { 255, 246, 119 }

  new: (@vel, x, y) =>
    half = @size / 2

    super f(x - half), f(y - half), @size, @size

    @rads = @vel\normalized!\radians! + math.pi / 2
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
    g.rectangle "fill", -1, -1, 2, 6
    g.pop!
    g.setColor 255, 255, 255

  update: (dt, world) =>
    @move unpack @vel * @speed * dt

    @life -= dt
    @life > 0 and world.expanded_box\touches_box @

class PlayerBullet extends Bullet

  draw: =>
    x,y = @center!
    g.setColor 255,255,255
    @sprite\draw "214,70,19,26", x, y, @rads, 2,2, 9, 8

    -- g.setColor 255,0,0
    -- g.rectangle "line", @unpack!

class EnemyBullet extends Bullet
  elapsed: 0
  is_enemy_bullet: true

  update: (dt, ...) =>
    @elapsed += dt
    super dt, ...

  draw: =>
    x,y = @center!
    g.setColor 255,255,255
    @sprite\draw "251,68,17,18", x, y, @elapsed*10, 3,3, 9, 10

nil
