local ffi = require "ffi"

-- Load Header file and strip preprocessor #macros
local function load_header(hdr)
        --print ("-- LOAD HEADER --", hdr)
        local f = io.open(hdr, "rb")
        local content = f:read("*all")
        f:close()
        content = content:gsub("#ifdef.-#endif", "\n")
        content = content:gsub("\\\n", "")
        content = content:gsub("#[^\n]-\n", "\n")
        --content = content:gsub("\n[^\n]-inline.-{.-({[^}]+})?.-}", "\n")
        
        ffi.cdef(content)
end

load_header "tox/headers/toxav.h"

local lib = ffi.load("toxcore")

-- Create a simple wrapper class for struct Tox
local toxavmt = {}
toxavmt.__new = function(_, tox)
        return lib.toxav_new(tox, nil)
        -- TODO: Check error return and throw exception
end
toxavmt.__index = function(self, name)
        return lib["toxav_" .. name]
end

return ffi.metatype("struct ToxAV", toxavmt)
