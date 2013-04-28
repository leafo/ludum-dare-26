
import watch_class from require"lovekit.reloader"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math

export ^

Levels = {
  {
    "....X.........X.....X........"
    ".........................X..."
    ".........X.....X......X......"
    "............................."
  }
}

-- 1
-- 2
-- 3
class Barrier
  watch_class @

  w: 300
  h: 150

  row_dist: 130

  new: (@row) =>
    @position!

  position: =>
    h = g.getHeight!
    @y = h * ((Ground.width * 0.6) + (1 - Ground.width))

    if @row == 1
      @y -= @row_dist
      @h = @@h - 50

    if @row == 3
      @y += @row_dist
      @h = @@h + 50

  draw_origin: =>
    @x - @w / 2, @y - @h

  draw_shadow: =>
    g.push!
    g.translate @draw_origin!

    sw = 40
    sh = 30

    g.setColor 0,0,0, 140
    g.rectangle "fill", -sw, @h - sh/2, @w + sw*2, sh

    g.pop!

  draw: =>
    ox = (@progress - 0.5) * 2 * 30
    oy = -10

    g.push!

    g.translate @draw_origin!

    g.setColor 50,50,50
    g.rectangle "fill", ox, oy, @w, @h

    g.setColor 80,80,80
    g.rectangle "fill", 0, 0, @w, @h

    g.pop!

  update: (dt, world) =>
    b = world.box
    grow = 1.5 + @row/4

    hw = b.w / 2
    cx = b.x + hw

    left = cx - hw * grow
    right = cx + hw * grow
    @progress = world\block_progress!
    @x = (1 - @progress) * (right - left) + left

class World
  watch_class @

  speed: 77
  block_size: 300

  new: (@game, @player, @level=Levels[1]) =>
    @entities = DrawList! -- things that collide
    @particles = DrawList! -- things that don't collide

    @collide = UniformGrid!

    @platform = Platform!
    @ground = Ground!

    @particles\add EnemySpawner @

    @box = Box 0, 0, g.getWidth!, g.getHeight!
    @expanded_box = @box\pad -20

    @num_blocks = #@level[1]
    @traversed = 0
    @length = @num_blocks * @block_size

    @barriers = {
      Barrier 1
      Barrier 2
      Barrier 3
    }

  block_i: =>
    f @progress! * @num_blocks

  block_progress: =>
    @traversed % @block_size / @block_size

  progress: =>
    @traversed / @length

  draw: =>
    @ground\draw!

    player_row = @platform\row!
    for i = 1,3
      @barriers[i]\draw_shadow! unless player_row == i

    for i = 1,3
      if player_row == i
        @platform\draw -> @player\draw!
      else
        @barriers[i]\draw!


    @entities\draw!
    @particles\draw!
    g.setColor 255,255,255

  collides: (thing) =>
    @platform\collides thing

  update: (dt) =>
    @traversed += dt * @speed

    for b in *@barriers
      b\update dt, @

    @platform\update dt, @
    @player\update dt, @
    _, @active_p = @particles\update dt, @
    _, @active_e = @entities\update dt, @
    @ground\update dt, @

    -- collision
    @collide\clear!
    @collide\add @player.box, @player
    for e in *@entities
      if e.alive != false
        @collide\add e

    for e in *@entities
      continue unless e.is_enemy and e.alive
      for thing in *@collide\get_touching e
        e\take_hit thing, @

    for thing in *@collide\get_touching @player.box
      @player\take_hit thing, @


