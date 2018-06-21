v4l2 = require "camera.v4l2"
video = require "video.init"
scanner = require "barcode.scanner"

jit.off() -- Required because of bug in v4l2 wrapper

local width, height = 640, 480

local camera = v4l2.open(width, height)
-- V4L2 might choose a different resolution than requested
local width, height = camera.width, camera.height
print ("Camera Resolution: ", width, "x", height)

local window = video.create_window(width, height)

scanner.init(width, height)

while video.update_window(window) do
    y, u, v = camera:read_frame()
    if y ~= nil then
        video.update_texture(window, y, u, v)
	for code in scanner.process(y) do
		print(code)
	end
    end
end

camera:close()
