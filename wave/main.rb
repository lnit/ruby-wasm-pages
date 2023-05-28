SAMPLE_RATE = 44100

puts "Hello, world!"

require "js"
window = JS.global[:window]
document = JS.global[:document]

def ctx
  return @ctx if defined?(@ctx)

  @ctx = JS.eval('return new AudioContext')
  @ctx[:sampleRate] = SAMPLE_RATE

  @ctx
end



SECONDS_TO_GENERATE = 1
TWO_PI = 2 * Math::PI
RANDOM_GENERATOR = Random.new


def generate_sample_data(num_samples, frequency, max_amplitude)
  position_in_period = 0.0
  position_in_period_delta = frequency / SAMPLE_RATE

  # Initialize an array of samples set to 0.0. Each sample will be replaced with
  # an actual value below.
  samples = [].fill(0.0, 0, num_samples)

  num_samples.times do |i|
    # Add next sample to sample list. The sample value is determined by
    # plugging the period offset into the appropriate wave function.

    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude

    samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.6
    samples[i] += Math::sin(position_in_period * TWO_PI * 2) * max_amplitude * 0.1
    samples[i] += Math::sin(position_in_period * TWO_PI * 3) * max_amplitude * 0.1
    #samples[i] += Math::sin(position_in_period * TWO_PI * 4) * max_amplitude * 0.1
    #samples[i] += Math::sin(position_in_period * TWO_PI * 5) * max_amplitude * 0.1
    samples[i] += Math::sin(position_in_period * TWO_PI * 0.5) * max_amplitude * 0.1
    samples[i] += Math::sin(position_in_period * TWO_PI * 0.25) * max_amplitude * 0.1

    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.3
    # samples[i] += Math::sin(position_in_period * TWO_PI) * max_amplitude * 0.3

    position_in_period += position_in_period_delta

    # Constrain the period between 0.0 and 1.0
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

  puts svg.render
  document ||= JS.global[:document]
  document.getElementById("plot-wave")[:innerHTML] = svg.render
end


button = document.getElementById "gen"
button.addEventListener "click" do |e|
  num_samples = SAMPLE_RATE * SECONDS_TO_GENERATE
  buf = ctx.createBuffer(1, SAMPLE_RATE, num_samples);
  data = buf.getChannelData(0);
  samples = generate_sample_data(num_samples, 442.0, 0.8)

  data[:length].to_i.times do |i|
    data[i] = samples[i]
  end

  puts ctx
  draw_wave(samples)

  src = ctx.createBufferSource()
  src[:buffer] = buf
  src.connect(ctx[:destination])

  src.start(0)
end
