local ffi = require "ffi"
local quirc = require "barcode.quirc"

local M = {}

function M.init(width, height)
	M.decoder = quirc()

	if M.decoder:resize(width, height) ~= 0 then
		error("quirc: resize failed")
	end
end

function M.process(y)
	pw = ffi.new("int[1]")
	ph = ffi.new("int[1]")

	local image = M.decoder:begin(pw, ph)
	local len = pw[0] * ph[0]
	ffi.copy(image, y, len)
	M.decoder:_end()

	ret = {}

	local code = ffi.new("struct quirc_code[1]")
	local data = ffi.new("struct quirc_data[1]")

	local i = 0

	-- TODO: is there a nicer way to implement the iterator function?
	return function()
		i = i + 1

		if i <= M.decoder:count() then
			M.decoder:extract(i-1, code)
			local result = M.decoder.decode(code, data)
			-- TODO: do something with the result???

			return ffi.string(data[0].payload, data[0].payload_len)
		end
	end
end

return M
