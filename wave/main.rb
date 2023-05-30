SAMPLE_RATE = 44100

require "js"
window = JS.global[:window]
document = JS.global[:document]

def ctx
  return @ctx if defined?(@ctx)

  @ctx = JS.eval('return new AudioContext')
  @ctx[:sampleRate] = SAMPLE_RATE

  @ctx
end

SECONDS_TO_GENERATE = 2
TWO_PI = 2 * Math::PI
RANDOM_GENERATOR = Random.new

def generate_sample_data(num_samples, frequency, max_amplitude)
  position_in_period = 0.0
  position_in_period_delta = frequency / SAMPLE_RATE

  samples = [].fill(0.0, 0, num_samples)

  num_samples.times do |i|

    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude

    samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.6
    samples[i] += Math::sin(position_in_period * TWO_PI * 2) * max_amplitude * 0.2
    #samples[i] += Math::sin(position_in_period * TWO_PI * 3) * max_amplitude * 0.1
    #samples[i] += Math::sin(position_in_period * TWO_PI * 4) * max_amplitude * 0.1
    #samples[i] += Math::sin(position_in_period * TWO_PI * 5) * max_amplitude * 0.1
    samples[i] += Math::sin(position_in_period * TWO_PI * 0.5) * max_amplitude * 0.2
    #samples[i] += Math::sin(position_in_period * TWO_PI * 0.25) * max_amplitude * 0.1

    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.3
    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.3

    position_in_period += position_in_period_delta

    # 0.0 → 1.0 の周期を繰り返す
    if position_in_period >= 1.0
      position_in_period -= 1.0
    end
  end

  samples
end

def draw_wave(samples)
  width = 441
  height = 320
  svg = Victor::SVG.new
  svg.setup width: width, height: height
  svg.rect x: 0, y: 0, width: width, height: height, stroke: "black", fill: "transparent"


  points = samples.first(width).map.with_index do |n, i|
    "#{i},#{n * 150 * -1 + height / 2 }"
  end.join(" ")

  svg.element :polyline,
    stroke: "green",
    fill: "transparent",
    stroke_width: 1,
    stroke_linejoin: :round,
    stroke_linecap: :round,
    points: points

  document ||= JS.global[:document]
  document.getElementById("plot-wave")[:innerHTML] = svg.render
end

# 基準波形の生成(A=442Hz)
gen_btn = document.getElementById "gen"
gen_btn.addEventListener "click" do |e|
  textarea = document.getElementById "script-wave"
  eval(textarea[:value].to_s)

  num_samples = SAMPLE_RATE * SECONDS_TO_GENERATE
  @buf = ctx.createBuffer(1, num_samples, SAMPLE_RATE);
  data = @buf.getChannelData(0);
  samples = generate_sample_data(num_samples, 442.0, 0.5)

  data[:length].to_i.times do |i|
    data[i] = samples[i]
  end

  draw_wave(samples)
end

# テスト再生
play_btn = document.getElementById "play"
play_btn.addEventListener "click" do |e|
  src = ctx.createBufferSource()
  src[:buffer] = @buf
  src.connect(ctx[:destination])

  src.start(0)
end


#
KEYS = %w(
  z s x d c v g b h n j m
  e 4 r 5 t y 7 u 8 i 9 o p
)

KEYS_HASH = KEYS.zip(-9..KEYS.length).to_h
# 押したキーに対応した音階を得るための倍率
def key_to_pitch_mag(key)
  n = KEYS_HASH[key]
  2 ** Rational(n / 12.0)
end

# キーボードから再生
@keydown_state = {}
@keydown_gain = {}
document.addEventListener "keydown" do |e|
  key = e[:key].to_s

  if KEYS.include?(key) && !@keydown_state[key]
    @keydown_state[key] = true
    src = ctx.createBufferSource()
    src[:buffer] = @buf
    # src[:playbackRate][:value] = key_to_pitch_mag(key)
    src[:detune][:value] = KEYS_HASH[key] * 100
    src[:loop] = true

    gain_node = ctx.createGain()
    gain_node[:gain][:value] = 1.0
    gain_node[:gain].linearRampToValueAtTime(1, ctx[:currentTime].to_i)
    @keydown_gain[key] = gain_node

    src.connect(gain_node).connect(ctx[:destination])

    src.start(0)
  end
end

document.addEventListener "keyup" do |e|
  key = e[:key].to_s

  if KEYS.include?(key)
    @keydown_state[key] = false
    gain_node = @keydown_gain.delete(key)
    gain_node[:gain].linearRampToValueAtTime(0, ctx[:currentTime].to_i + 1.5)
  end
end


puts "Hello, world!"
