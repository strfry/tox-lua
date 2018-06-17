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

load_header "headers/tox.h"

local lib = ffi.load("toxcore")

-- Create a simple wrapper class for struct Tox
toxmt = {}
toxmt.__new = function(options) 
        return lib.tox_new(nil, nil)
end
toxmt.__index = function(self, name)
        return lib["tox_" .. name]
end

local Tox = ffi.metatype("struct Tox", toxmt)

return Tox
