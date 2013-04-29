
-- import watch_class from require"lovekit.reloader"

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math

black = { 0,0,0 }
white = { 255,255,255 }
outline_color = { 200, 200, 200}
health_color = { 100, 200, 100 }

export *

p = (str, ...) -> g.print str\lower!, ...
box_text = (msg, x, y, center=true, inner_color=black) ->
  msg = msg\lower!
  font = g.getFont!

  w, h = font\getWidth(msg), font\getHeight!
  g.push!

  if center
    center = 0.5 if center == true
    g.translate x - w*center, y - h/2
  else
    g.translate x, y - h/2

  g.rectangle "fill", 0,0, w,h
  g.setColor unpack inner_color
  g.print msg, 0,0
  g.pop!


class Hud extends Box
  -- watch_class @

  system: TrapSystem 0.008
  speed: 130

  margin: 10
  w: 200
  h: 80

  progress_w: 20

  new: (world) =>
    @x = g.getWidth! - @margin - @w
    @y = @margin
    @time = 0

    div_x = 3
    div_y = 5

    @sizing = with {}
      .stepx = @w/div_x
      .stepy = @h/div_y

      .w2 = @w/2
      .h = @h * 2
      .h2 = .h/2

    @blinker = Sequence ->
      @_blink_on = not @_blink_on
      wait 0.5
      again!

    do
      import w2, h2, stepx, h from @sizing
      @quads = {
        @system\project_box Box -w2, -h2, stepx, h
        @system\project_box Box -w2 + stepx, -h2, stepx, h
        @system\project_box Box -w2 + stepx*2, -h2, stepx, h
      }

  update: (dt, world) =>
    @position = world.platform\position!
    @segment = world.platform\row!
    @progress = world\progress!
    @player_life = world.player\p_life!
    @player_score = world.player.display_score

    @current_block = world.active_block
    @next_block = world.level[world\block_i! + 1] or {}

    @block_progress = world\block_progress!
    @in_danger = @current_block[@segment] and @block_progress < 0.6

    @blinker\update dt

    if @stage_timeout
      @stage_timeout -= dt
      if @stage_timeout < 0
        @stage_timeout = nil

    @time += dt

  -- this is dumb
  position_to_indicator: (p) =>
    if p <= .33
      -- 0 -> 0.25
      (p / .33) * 0.25
    elseif p <= 0.66
      -- 0.25 -> .75
      0.25 + (p - 0.33) / 0.33 * 0.5
    else
      -- 0.75 -> 1.0
      0.75 + (p - 0.66) / 0.33 * 0.25

  show_stage: (label) =>
    @stage_label = label
    @stage_timeout = 3

  draw: =>
    pt_size = g.getPointSize!
    g.setPointSize 4

    g.setScissor @unpack!

    g.push!
    g.translate @center!

    import w2, h2, stepx, stepy, h from @sizing
    import system, time, speed from @

    q = @quads[@segment]
    q.a = ((math.sin(time*8) + 1) / 4 + 0.5) * 255

    if @in_danger
      q\draw 200,80,80
    else
      q\draw 80,80,80

    g.setColor 255,255,255

    for y=-h2, h2, stepy
      for x=-w2, w2 + stepx/2, stepx
        g.point system\project x, (y + time * speed + h2) % h - h2

    g.pop!
    g.setScissor!

    -- indicator
    g.push!
    g.translate @x, @y + @h + @margin * 1.2
    g.scale @w, @h

    g.translate @position_to_indicator(@position), 0

    g.scale 0.1, 0.1
    g.triangle "fill",
      0, -1,
      0.5, 0.5,
      -0.5,0.5
    g.pop!

    -- outline
    g.setColor unpack outline_color
    g.rectangle "line", @unpack!

    -- next block warnings
    @draw_warning_rect 1
    @draw_warning_rect 2
    @draw_warning_rect 3

    if @stage_timeout and @stage_timeout > 0 and @_blink_on
      g.setColor unpack white
      g.push!
      g.translate g.getWidth!/2, 40
      g.scale 4, 4
      box_text "stage #{@stage_label}", 0,0, true
      g.pop!

    -- danger text
    if @in_danger and @_blink_on
      g.setColor 255,100,100
      g.push!
      g.translate g.getWidth!/2, 40
      g.scale 4, 4
      box_text "warning", 0,0, true, white
      g.pop!

    g.setColor 255,255,255
    g.setPointSize pt_size

    @draw_progress!
    @draw_player_health!
    @draw_score!

  draw_warning_rect: (row, on=false) =>
    w = 20
    h = 10

    blink = true
    on = @next_block[row]
    if @current_block[row] and @block_progress < 0.6
      on = true
      blink = false

    ox = if row == 1
      -40
    elseif row == 3
      40
    else
      0

    if on and (not blink or @_blink_on)
      g.setColor 255,100,100
    else
      g.setColor 80,80,80

    g.rectangle "fill", @x + (@w - w) / 2 + ox, @y - 3, w, h

  draw_progress: =>
    w = @progress_w
    h = @h * @progress
    x = @x - @margin - w

    g.setColor 255,255,255, 120
    g.rectangle "fill", x, @y + @h - h, w, h

    g.setColor unpack outline_color
    g.rectangle "line", x, @y, w, @h

    g.setColor 255,255,255
    g.push!
    g.translate @x - 90, 16
    g.scale 2
    box_text "goal", 0, 0, false
    g.pop!

  draw_player_health: =>
    padding = 4

    w = 183
    h = @progress_w

    g.setColor unpack health_color

    g.rectangle "fill",
      @margin + padding, 30 + padding,
      (w - padding * 2) * @player_life, h - padding * 2

    g.setColor unpack outline_color
    g.rectangle "line", @margin, 30, w, h

    g.setColor 255,255,255
    g.push!
    g.translate @margin, 16
    g.scale 2
    box_text "health", 0, 0, false
    g.pop!

  draw_score: =>
    g.setColor 255,255,255
    g.push!
    g.translate 100, 16
    g.scale 2
    box_text "score: #{f @player_score}", 0, 0, false
    g.pop!

class TitleScreen
  -- watch_class @
  shroud: 0

  new: =>
    @viewport = EffectViewport scale: 3
    @title = imgfy "img/title.png"
    sfx\play_music "moondar_title"

  on_key: (key) =>
    return if @seq
    if key == "return"
      sfx\play "start_game"
      @seq = Sequence ->
        tween @, 1.0, shroud: 255
        @shroud = 0
        @seq = nil
        dispatch\push Game!

  draw: =>
    @viewport\apply!
    g.setColor 255,255,255
    @title\draw 0,0

    if f(timer.getTime! * 2) % 2 == 0
      box_text "Press Enter To Begin", 230, 110

    g.setColor 255,255,255, 128
    p "leafo 2013", 0, @viewport.h - 8

    if @shroud > 0
      @viewport\draw {0,0,0, @shroud}

    @viewport\pop!

  update: (dt) =>
    @seq\update dt if @seq

class GameOver
  -- watch_class @

  new: (@game) =>
    @viewport = EffectViewport scale: 3

  on_key: (key) =>
    if key == "return"
      dispatch\reset TitleScreen!

  update: (dt) =>

  draw: =>
    @viewport\apply!
    g.setColor 255,255,255

    p "Moondar is lost...", 10, 10

    g.push!
    g.translate 0, 10
    p "Game Over", 60, 40
    p "Level Reached: #{@game.current_level}", 60, 60
    p "Score: #{f @game.player.score}", 60, 70

    p "Press enter to return to title", 60, 100
    p "Thanks for playing! &", 60, 110
    g.pop!

    @viewport\pop!

