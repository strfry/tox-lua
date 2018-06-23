
local pautil = require "audio.portaudioutil"
local filteraudio = require "audio.filteraudio"

local sampleRate = 48000
local framesPerBuffer = 960
local numChannels = 1

local filter = filteraudio.new_filter_audio(sampleRate)

filteraudio.enable_disable_filters(filter, 1, 0, 0, 0)

ffi = require "ffi"

local function audiofun(inp, out, size, nchans)
  buffer = ffi.new("short[?]", size * nchans)
  
  for i = 0, size*nchans-1 do
    buffer[i] = inp[i] * 2^15
  end

  if filteraudio.filter_audio(filter, buffer, size) == -1 then
    error "filtering failed"
  end
  
  filteraudio.pass_audio_output(filter, buffer, size)
  
  for i = 0, size*nchans-1 do
    out[i] = buffer[i] / 2^15
  end
  
end

local function waitfun()
  print("Press Enter to stop")
  io.read()
end


pautil.callback(sampleRate, framesPerBuffer, numChannels, audiofun, waitfun)
filteraudio.kill_filter_audio(filter)
