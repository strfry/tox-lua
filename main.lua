local toxcore = require "toxcore"
--local sodium = require "ffi".load("sodium")
local bindechex = require "BinDecHex"

--local video = require "video"



opts = {
    end_port = 0,
    ipv6_enabled = false
}

opts.start_port = 33445
bootstrap = toxcore(opts)

opts.start_port = 33455
alice = toxcore(opts)

opts.start_port = 33465
bob = toxcore(opts)


function self_connection_status_cb(tox, status, _)
    print (_, "Connection Status changed to", status)
end

alice:callback_self_connection_status(self_connection_status_cb)
bob:callback_self_connection_status(self_connection_status_cb)
bootstrap:callback_self_connection_status(self_connection_status_cb)

jit.off()
--jit.off(self_connection_status_cb)
--jit.off(tox.iterate)

local off = true


while true do
    alice:iterate(nil)
    bob:iterate(nil)
    bootstrap:iterate(nil)

    if bootstrap:self_get_connection_status() ~= 0 and
        alice:self_get_connection_status() ~= 0 and
        bob:self_get_connection_status() ~= 0 and
        off then
        off = false
        
        print ("Toxes are online")
        
    end
        
            --printf("Toxes are online, took %llu seconds\n", time(NULL) - cur_time);
end
