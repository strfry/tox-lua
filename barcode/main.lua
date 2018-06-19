local ffi = require "ffi"
local quirc = require "quirc"

local decoder = quirc()

width, height = 1366, 768

local filename = '2018-06-19-193844_1366x768_scrot.data'
local file = io.open(filename, "r")

local data = file:read(width * height)

--print (data)

print ("width, height", width, height)

if decoder:resize(width, height) ~= 0 then
    error("resize failed")
end

local image = decoder:begin(nil, nil)
print ("image pointer: ", image)

ffi.copy(image, data, width*height)

decoder:_end()

print ("found", decoder:count(), "codes")

for i=1,decoder:count() do
    print ("decoding code #", i)

    local code = ffi.new("struct quirc_code[1]")
    decoder:extract(i-1, code)

    local data = ffi.new("struct quirc_data[1]")

    local result = decoder.decode(code, data)
    print ("decode result", result)

    print (ffi.string(data[0].payload, data[0].payload_len))
end
