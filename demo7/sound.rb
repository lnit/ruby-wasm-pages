require "js"

def document
  @document ||= JS.global[:document]
end

def ctx
  @ctx ||= JS.global[:AudioContext].new
end

def play
  src = ctx.createBufferSource()
  src[:buffer] = @audio_buffer

  src.connect(ctx[:destination])
  src.start(0)
end

path = "sound.mp3"
response = JS.global.fetch(path).await
array_buffer = response.arrayBuffer.await
@audio_buffer = ctx.decodeAudioData(array_buffer).await


button = document.getElementById("play")
button.addEventListener "click" do |e|
  play
end
button.removeAttribute("disabled")
