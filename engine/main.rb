
require "js"

CANVAS_WIDTH=480
CANVAS_HEIGHT=320

class MainScene
  def initialize
    Input.add_input_events

    entities << Player.new do |e|
      e.pos_x = CANVAS_WIDTH / 3
      e.pos_y = 40
      e.scale_x = 40.0
      e.scale_y = 40.0

      e.vel_x = 0
      e.vel_y = 0

      e.acc_x = 0
      e.acc_y = 400

      e.color = "#FF3311"
    end

  end

  def main(deltaTime)
    Input.main

    fps[:innerText] = "FPS: #{(1 / deltaTime).to_s}"
    ctx.clearRect(0, 0, canvas[:width], canvas[:height]);

    entities.each do |e|
      e.update(deltaTime)
    end

    entities.each do |e|
      e.draw
    end

    ctx.beginPath
    ctx.rect(0, 0, canvas[:width], canvas[:height])
    ctx[:fillStyle] = "#111111"
    ctx.stroke
    ctx.closePath
  end

  private
  def entities
    @entities ||= []
  end

  def document
    @document = JS.global[:document]
  end

  def fps
    @fps = document.getElementById("main")
  end

  def canvas
    @canvas = document.getElementById("main_canvas")
  end


  def ctx
    @ctx = canvas.getContext("2d")
  end

end

class Entity
  attr_accessor :pos_x, :pos_y
  attr_accessor :vel_x, :vel_y
  attr_accessor :acc_x, :acc_y

  def initialize
    yield(self) if block_given?

    self.pos_x ||= 0
    self.pos_y ||= 0
    self.vel_x ||= 0
    self.vel_y ||= 0
    self.acc_x ||= 0
    self.acc_y ||= 0
  end

  def update(deltaTime)
    raise NotImplementedError
  end

  def draw
    raise NotImplementedError
  end

  private
  def document
    @@document = JS.global[:document]
  end


  def canvas
    @@canvas = document.getElementById("main_canvas")
  end

  def ctx
    @@ctx = canvas.getContext("2d")
  end
end

class Player < Entity
  attr_accessor :scale_x, :scale_y
  attr_accessor :color

  def update(deltaTime)
    self.vel_x += self.acc_x * deltaTime
    self.vel_y += self.acc_y * deltaTime


    if pos_x < 20 ||  460 < pos_x
      self.vel_x = - self.vel_x
    end

    if Input.mousedown?
      self.vel_y = -250
    end

    self.pos_x += self.vel_x * deltaTime
    self.pos_y += self.vel_y * deltaTime
  end

  def draw
    ctx.beginPath
    ctx.rect((pos_x - scale_x / 2).to_i, (pos_y - scale_y / 2).to_i, scale_x.to_i, scale_y.to_i)
    ctx[:fillStyle] = color
    ctx.fill
    ctx.closePath
  end

  def color
    @color || "#000000"
  end
end

class Input
  @mouse_state = false
  @mouse_prev_state = false

  @mousedown= false

  def self.add_input_events
    document = JS.global[:document]
    ev_canvas = document.getElementById("main_canvas")
    ev_canvas.addEventListener("mousedown") do |e|
      print "down"
      @mouse_state = true
    end
    ev_canvas.addEventListener("mouseup") do |e|
      print "up"
      @mouse_state = false
    end
    ev_canvas.addEventListener("mouseleave") do |e|
      if @mouse
        print "leave"
        @mouse_state = false
      end
    end
    ev_canvas.addEventListener("touchstart") do |e|
      print "down"
      @mouse_state = true
    end
    ev_canvas.addEventListener("touchend") do |e|
      print "up"
      @mouse_state = false
    end
    ev_canvas.addEventListener("touchcancel") do |e|
      print "up"
      @mouse_state = false
    end
  end

  def self.main
    if (@mouse_state && !@mouse_prev_state)
      @mousedown = true
    else
      @mousedown = false
    end

    @mouse_prev_state = @mouse_state
  end

  def self.mouse?
    @mouse_state
  end

  def self.mousedown?
    @mousedown
  end
end
