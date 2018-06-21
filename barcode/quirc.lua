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
        
        ffi.cdef(content)
end

load_header "barcode/quirc.h"

local lib = ffi.load("quirc")

local M = {}
M.__new = function(_, options)
        local obj = lib.quirc_new()
        ffi.gc(obj, lib.quirc_destroy)
        return obj
        -- TODO: Check error return and throw exception
end
M.__index = function(self, name)
        if name == "_end" then -- workaround because 'end' is a Lua keyword
                return lib.quirc_end
        end
        return lib["quirc_" .. name]
end

return ffi.metatype("struct quirc", M)
