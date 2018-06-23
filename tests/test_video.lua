ffi = require "ffi"
video = require "video.init"

--jit.off()

local width = 640
local height = 480

local y = ffi.new("uint8_t[?]", width * height + 32)
local u = ffi.new("uint8_t[?]", width * height / 4 + 32)
local v = ffi.new("uint8_t[?]", width * height / 4 + 32)

local win = video.create_window(width, height)

local frame = 0

while video.update_window(win) do
    video.generate_test_pattern(width, height, y, u, v, frame)
    video.update_texture(win, y, u, v)
    
    frame = frame + 1
end
