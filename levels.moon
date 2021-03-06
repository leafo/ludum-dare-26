
-- import watch_class from require"lovekit.reloader"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math

export ^

Levels = {
  {
    "....x..x....."
    "..x.......x.."
    "....x..x....."
    "a..a.ba.a.ab."
  }

  {
    "..x.xx.xxx..."
    "..x...x..x.x."
    "....x..x...xx"
    "..b.b.a.a.bb."
  }

  {
    "x.x.x.x."
    ".x.x.x.x"
    "x.x.x.x."
    "...a.a.."
  }

  {
    "x.x.xx.xxx..."
    ".xx...x..x.x."
    "x...x..x..xxx"
    ".dc.c.b..d..."
  }
}


class Barrier extends Box
  -- watch_class @

  w: 300
  h: 150

  row_dist: 130
  has_collided: false
  is_barrier: true

  new: (@row) =>
    h = g.getHeight!
    @y = h * ((Ground.width * 0.6) + (1 - Ground.width))

    if @row == 1
      @y -= @row_dist
      @h = @@h - 50

    if @row == 3
      @y += @row_dist
      @h = @@h + 50

    @y -= @h

  draw_shadow: =>
    g.push!
    g.translate @x, @y

    sw = 40
    sh = 30

    g.setColor 0,0,0, 140
    g.rectangle "fill", -sw, @h - sh/2, @w + sw*2, sh

    g.pop!

  draw: =>
    ox = (@progress - 0.5) * 2 * 30
    oy = -10

    g.push!

    g.translate @x, @y

    g.setColor 50,50,50
    g.rectangle "fill", ox, oy, @w, @h

    g.setColor 80,80,80
    g.rectangle "fill", 0, 0, @w, @h

    g.pop!

    g.setColor 255,255,255, 128
    @outline!

  update: (dt, world) =>
    b = world.box
    grow = 1.5 + @row/4

    hw = b.w / 2
    cx = b.x + hw

    left = cx - hw * grow
    right = cx + hw * grow
    @progress = world\block_progress!

    x = (1 - @progress) * (right - left) + left
    @x = x - @w / 2

class World
  -- watch_class @

  speed: 77
  block_size: 300
  started: false

  shroud: 0

  lazy_value @, "tutorial", -> imgfy "img/tutorial.png"

  new: (@game, @player, level=Levels[1]) =>
    @entities = DrawList! -- things that collide
    @particles = DrawList! -- things that don't collide

    @collide = UniformGrid!

    @platform = Platform!
    @ground = Ground!

    @box = Box 0, 0, g.getWidth!, g.getHeight!
    @expanded_box = @box\pad -20

    @traversed = 0
    @level = {}
    @active_block = { }

    @barriers = {
      Barrier 1
      Barrier 2
      Barrier 3
    }

  start: =>
    return if @started
    @started = true
    lid = @game.current_level + 1
    @game.current_level += 1
    @load_level lid

  load_level: (lid) =>
    level = Levels[lid]
    unless level
      level = Levels[#Levels]

    @game.hud\show_stage lid

    @traversed = 0
    @level = @parse_level level

    @num_blocks = #@level
    @length = @num_blocks * @block_size

  parse_level: (level) =>
    {row1, row2, row3, enemies} = level
    return for i = 1, #row1
      {
        row1\sub(i,i) != "."
        row2\sub(i,i) != "."
        row3\sub(i,i) != "."
        enemy: enemies\sub(i,i)
      }

  goto_next_level: =>
    @transition = Sequence ->
      @player.locked = true
      @show_continue_message = true
      tween @, 1.0, shroud: 255
      wait_for_key "return"

      lid = @game.current_level + 1
      @game.current_level += 1
      @load_level lid

      tween @, 1.0, shroud: 0
      @show_continue_message = false
      @player.locked = false
      @transition = false

  block_i: =>
    return -1 unless @started and @num_blocks
    _min f(@progress! * @num_blocks) + 1, @num_blocks

  block_progress: =>
    @traversed % @block_size / @block_size

  progress: =>
    return 0 unless @length and @length != 0

    p = @traversed / @length
    p = 1 if p > 1
    p

  draw: =>
    @ground\draw!

    player_row = @platform\row!
    for i = 1,3
      @barriers[i]\draw_shadow! if @active_block[i]

    for i = 1,3
      if player_row == i
        @platform\draw -> @player\draw!
        @particles\draw!
        @entities\draw!

      @barriers[i]\draw! if @active_block[i]

    g.setColor 255,255,255

    unless @started
      @tutorial\draw 0,0, 0, 2,2

    if @shroud > 0
      @game.viewport\draw {0,0,0, @shroud}

    if @show_continue_message
      g.push!
      g.translate @game.viewport.w / 2, @game.viewport.h / 2
      g.scale 2,2
      tcolor = {0,0,0, @shroud}
      g.setColor 255,255,255, @shroud
      box_text "Stage Complete", 0, 0, true, tcolor
      g.setColor 255,255,255, @shroud
      box_text "Press Enter To Continue", 0, 10, true, tcolor
      g.pop!

  collides: (thing) =>
    @platform\collides thing

  setup_block: (bid) =>
    @active_block = @level[bid] or {}
    for i=1,3
      @barriers[i].has_collided = false

    if etype = @active_block.enemy
      switch etype
        when "a"
          @particles\add EnemySpawner @, 1
        when "b"
          @particles\add EnemySpawner @, 2
        when "c"
          @particles\add EnemySpawner @, 3
        when "d"
          @particles\add EnemySpawner @, 2
          @particles\add EnemySpawner @, 2
        when "e"
          @particles\add EnemySpawner @, 3
          @particles\add EnemySpawner @, 3

  update: (dt) =>
    @transition\update dt if @transition
    progress = @progress!

    if @started
      if progress < 1.0
        @player.score += dt * 6 * math.min(@game.current_level, 5)

      @traversed += dt * @speed

    if progress == 1 and not @transition
      @goto_next_level!

    bid = @block_i!
    if bid != @_current_block
      @_current_block = bid
      @setup_block bid

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

    -- barriers colliding
    row = @platform\row!
    if @active_block[row]
      b = @barriers[row]
      if not b.has_collided and b\touches_box @platform.hitbox
        sfx\play "barrier_collide"
        @platform\take_hit b, @
        @player\take_hit b, @
        b.has_collided = true

