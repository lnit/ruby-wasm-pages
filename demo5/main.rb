
require "js"

class MainScene
  def initialize
    entities << Rectangle.new do |e|
      e.pos_x = 40
      e.pos_y = 0
      e.scale_x = 40.0
      e.scale_y = 40.0

      e.vel_x = 2.0
      e.vel_y = 0

      e.acc_x = 0;
      e.acc_y = 0.2;

      e.color = "#FF3311"
    end

    entities << Rectangle.new do |e|
      e.pos_x = 40
      e.pos_y = 300
      e.scale_x = 150.0
      e.scale_y = 20.0

      e.vel_x = 2.0
      e.vel_y = 0

      e.acc_x = 0;
      e.acc_y = 0;

      e.color = "#1133FF"
    end


  end

  def main(deltaTime)
    fps[:innerText] = "FPS: #{(1000 / deltaTime).to_s}"
    ctx.clearRect(0, 0, canvas[:width], canvas[:height]);

    entities.each do |e|
      e.update
    end

    entities.each do |e|
      e.draw
    end


    #ctx.beginPath
    #ctx.rect(20, 40, 50, 50)
    #ctx[:fillStyle] = "#FF0000"
    #ctx.fill
    #ctx.closePath

    #ctx.beginPath
    #ctx.rect(120, 40, 50, 50)
    #ctx[:fillStyle] = "#00FF00"
    #ctx.fill
    #ctx.closePath

    #ctx.beginPath
    #ctx.rect(20, 140, 50, 50)
    #ctx[:fillStyle] = "#0000FF"
    #ctx.fill
    #ctx.closePath

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

  def update
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


class Rectangle < Entity
  attr_accessor :scale_x, :scale_y
  attr_accessor :color

  def update
    self.vel_x += self.acc_x
    self.vel_y += self.acc_y
    if self.vel_y > 9.5
      self.vel_y = 9.5
    end

    if (pos_y > 280)
      self.vel_y = - self.vel_y
    end

    if( pos_x < 20 ||  460 < pos_x)
      self.vel_x = - self.vel_x
    end


    self.pos_x += self.vel_x
    self.pos_y += self.vel_y
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
