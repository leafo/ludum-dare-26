
{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs, :sqrt} = math

export *

class Hud extends Box
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

    do
      import w2, h2, stepx, h from @sizing
      @quads = {
        @system\project_box Box -w2, -h2, stepx, h
        @system\project_box Box -w2 + stepx, -h2, stepx, h
        @system\project_box Box -w2 + stepx*2, -h2, stepx, h
      }

  update: (dt, world) =>
    @position = world.platform\position!
    @segment = world.platform\segment!
    @progress = world\progress!

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

  draw_progress: =>
    w = @progress_w
    h = @h * @progress
    x = @x - @margin - w

    g.setColor 255,255,255, 120
    g.rectangle "fill", x, @y + @h - h, w, h

    g.setColor 200,200,200
    g.rectangle "line", x, @y, w, @h

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
    q\draw 80,80,80

    g.setColor 255,255,255

    for y=-h2, h2, stepy
      for x=-w2, w2 + stepx/2, stepx
        g.point system\project x, (y + time * speed + h2) % h - h2

    g.pop!
    g.setScissor!

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


    g.setColor 200,200,200
    g.rectangle "line", @unpack!
    g.setColor 255,255,255

    g.setPointSize pt_size

    @draw_progress!

