v4l2 = require "camera.v4l2"
video = require "video.init"

jit.off()

local width = 640
local height = 480

local win = video.create_window(width, height)

local frame = 0

camera = v4l2.open(width, height)

while video.update_window(win) do
    y, u, v = camera:read_frame()
    if y ~= nil then
        video.update_texture(win, y, u, v)
    end
    
    frame = frame + 1
end




camera:close()
