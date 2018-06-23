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

load_header "tox/headers/tox.h"

local lib = ffi.load("toxcore")

function make_options(overrides)
        if not overrides then return nil end

        local options = lib.tox_options_new(nil)
        
        for k,v in pairs(overrides) do
                options[k] = v
        end

        return options
end

make_options(nil)
make_options({})

-- Create a simple wrapper class for struct Tox
local toxmt = {}
toxmt.__new = function(_, options)
        return lib.tox_new(make_options(options), nil)
        -- TODO: Check error return and throw exception
end
toxmt.__index = function(self, name)
        return lib["tox_" .. name]
end

return ffi.metatype("struct Tox", toxmt)
