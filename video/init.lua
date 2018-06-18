local bit = require "bit"

local eglwin = require "video.eglwindow"
local gltex = require "video.gltexture"

local M = {}

function M.generate_test_pattern(width, height, y, u, v, frame)
    for j=0,height/2 - 1 do
        local py = y + 2 * j * width
        local pu = u + j * width / 2
        local pv = v + j * width / 2
        for i=0, width / 2 - 1 do
            --local z = bit.xor((i + frame) / 16), (j + frame) / 16)
            local z = bit.band(15, (bit.bxor((i + frame) / 16, (j + frame) / 16)))

            local yval = 0x80 + z * 0x8

            py[0] = yval
            py[1] = yval
            py[width] = yval
            py[width+1] = yval

            pu[0] = 0x00 + z * 0x10;
            pv[0] = 0x80 + z * 0x30;
            py = py + 2
            pu = pu + 1
            pv = pv + 1
        end
    end
end

function M.create_window(width, height)
    local win = eglwin.create(width, height)
    win.width = width
    win.height = height
    
    win:bind_context()

    win.phandle = gltex.init_shaders()

    return win
end

function M.update_window(self)
    gltex.draw_blit(self.phandle)
    return self:update()
end

function M.update_texture(self, y, u, v)
    gltex.upload_yuv(self.phandle,
        self.height,
        y, u, v,
        self.width, self.width / 2, self.width / 2)
end


return M
