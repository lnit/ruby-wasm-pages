
require "js"

CANVAS_WIDTH=480
CANVAS_HEIGHT=320

class MainScene
  attr_accessor :reset_flag

  def initialize
    Input.add_input_events

    player = Player.new do |e|
      e.scene = self
      e.pos_x = CANVAS_WIDTH / 3
      e.pos_y = CANVAS_HEIGHT / 2
      e.scale_x = 40.0
      e.scale_y = 40.0

      e.vel_x = 0
      e.vel_y = 0

      e.acc_x = 0
      e.acc_y = 450
    end
    entities << player

    entities << EnemySpawner.new do |e|
      e.scene = self
      e.player = player
    end

    entities << Enemy.new do |e|
      e.player = player
      e.pos_x = CANVAS_WIDTH / 3
      e.pos_y = CANVAS_HEIGHT + 150
    end
    entities << Enemy.new do |e|
      e.player = player
      e.pos_x = CANVAS_WIDTH / 3
      e.pos_y = -150
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

  def entities
    @entities ||= []
  end

  private

  def document
    @document ||= JS.global[:document]
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
  attr_accessor :scene
  attr_accessor :scale_x, :scale_y
  attr_accessor :color
  attr_accessor :in_game, :dead

  def initialize
    super

    self.in_game = false
    self.dead = false

    @jump_se = JumpSE.new
    @damage_se = DamageSE.new
  end

  def update(deltaTime)
    if self.in_game
      self.vel_x += self.acc_x * deltaTime
      self.vel_y += self.acc_y * deltaTime


      if Input.mousedown?
        jump
      end

      self.pos_x += self.vel_x * deltaTime
      self.pos_y += self.vel_y * deltaTime
    elsif self.dead
      if Input.mousedown?
        scene.reset_flag = true
      end
    else
      if Input.mousedown?
        self.in_game = true
        jump
      end
    end
  end

  def draw
    ctx.beginPath
    ctx.rect((pos_x - scale_x / 2).to_i, (pos_y - scale_y / 2).to_i, scale_x.to_i, scale_y.to_i)
    ctx[:fillStyle] = color
    ctx.fill
    ctx.closePath
  end

  def damage
    self.in_game = false
    self.dead = true
    @damage_se.play
  end

  private

  def color
    @color || "#000000"
  end

  def jump
    self.vel_y = -300
    @jump_se.play
  end
end

class Enemy < Entity
  SIZE = 60
  attr_accessor :player

  def update(deltaTime)
    return nil if pos_x < - SIZE / 2

    if player.in_game
      self.pos_x += self.vel_x * deltaTime
      self.pos_y += self.vel_y * deltaTime

      collision_player
    end
  end

  def draw
    return nil if pos_x < - 30

    ctx.beginPath
    ctx.rect((pos_x - SIZE / 2).to_i, (pos_y - SIZE / 2).to_i, SIZE, SIZE)
    ctx[:fillStyle] = color
    ctx.fill
    ctx.closePath
  end

  private

  def collision_player
    if (self.pos_x - player.pos_x).abs < (SIZE / 2 + 20) &&
       (self.pos_y - player.pos_y).abs < (SIZE / 2 + 20)
      player.damage
      @failed = true
    end
  end

  def color
    return "#22DD33" if self.pos_x < 90
    return "#FF2222" if @failed
    "#AAAAAA"
  end
end

class EnemySpawner < Entity
  attr_accessor :scene, :player

  attr_accessor :spawn_wait
  SPAWN_PER_SECOND = 4

  def initialize
    super

    self.spawn_wait = 0
  end

  def update(deltaTime)
    if player.in_game
      spawn if self.spawn_wait <= 0
      self.spawn_wait -= deltaTime
    end
  end

  def draw
    nil
  end

  private
  def spawn
    self.spawn_wait = SPAWN_PER_SECOND

    rand = Random.rand(-20..20)
    spawn_enemy(CANVAS_WIDTH + 30, CANVAS_HEIGHT / 2 - 100 + rand)
    spawn_enemy(CANVAS_WIDTH + 30, CANVAS_HEIGHT / 2 + 100 + rand)
  end

  def spawn_enemy(x, y)
    scene.entities << Enemy.new do |e|
      e.player = player
      e.pos_x = x
      e.pos_y = y

      e.vel_x = -100
      e.vel_y = 0
    end
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
      @mouse_state = true
    end
    ev_canvas.addEventListener("mouseup") do |e|
      @mouse_state = false
    end
    ev_canvas.addEventListener("mouseleave") do |e|
      if @mouse
        @mouse_state = false
      end
    end
    ev_canvas.addEventListener("touchstart") do |e|
      @mouse_state = true
    end
    ev_canvas.addEventListener("touchend") do |e|
      @mouse_state = false
    end
    ev_canvas.addEventListener("touchcancel") do |e|
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

class SoundEffect
  def initialize
    array_buffer = JS.global.fetch(path).await.arrayBuffer.await
    @audio_buffer = ctx.decodeAudioData(array_buffer).await

    puts path
  end

  def play
    src = ctx.createBufferSource()
    src[:buffer] = @audio_buffer

    src.connect(gain_node).connect(ctx[:destination])
    src.start(0)
  end

  private

  def ctx
    @@ctx ||= JS.global[:AudioContext].new
  end

  def gain_node
    gain_node = ctx.createGain()
    gain_node[:gain][:value] = 0.3
    gain_node
  end
end

class JumpSE < SoundEffect
  def path
    "se/Motion-Pop20-1.mp3"
  end
end


class DamageSE < SoundEffect
  def path
    "se/Motion-Pop13-2.mp3"
  end
end
