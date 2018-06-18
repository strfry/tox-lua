local toxcore = require "toxcore"
local toxav = require "toxav"
--local sodium = require "ffi".load("sodium")

local ffi = require "ffi"

--local video = require "video"

jit.off() -- TODO: Find out which functions to disable specifically

TEST_TRANSFER_V = true

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


function iterate_tox()
    alice:iterate(nil)
    bob:iterate(nil)
    bootstrap:iterate(nil)
end

local off = true
local besties = false


-- Start friend request from Bob to Alice
alice_address = ffi.new("unsigned char[?]", toxcore.address_size())
alice:self_get_address(alice_address)

alice:callback_friend_request(function(tox, public_key, data, len, _)
    print "Accepting friend request..."
    local friend_num = tox:friend_add_norequest(public_key, nil)
    print (string.format("Bob is now Alice's friend #%d", friend_num))
end)

bob:callback_friend_status(function(tox, friend_num, status, _)
    print "Alice and Bob are now best friends forever"
    besties = true
end)

local request_msg = "This is a friend request"
local request = ffi.new("char[32]")
ffi.copy(request, request_msg)

local alice_on_bobs_friendlist = bob:friend_add(alice_address, request, request_msg:len(), nil)

if not alice_on_bobs_friendlist then
    error("Friend request from Bob to Alice failed!")
else
    print(string.format("Alice is Bob's friend #%d", alice_on_bobs_friendlist))
end

while off or not besties do
    iterate_tox()

    if bootstrap:self_get_connection_status() ~= 0 and
        alice:self_get_connection_status() ~= 0 and
        bob:self_get_connection_status() ~= 0 and
        off then
        off = false
        
        print ("Toxes are online")
    end
end


aliceav = toxav(alice)
bobav = toxav(bob)

    -- toxav_callback_call(*AliceAV, t_toxav_call_cb, AliceCC);
    -- toxav_callback_call_state(*AliceAV, t_toxav_call_state_cb, AliceCC);
    -- toxav_callback_bit_rate_status(*AliceAV, t_toxav_bit_rate_status_cb, AliceCC);
    -- toxav_callback_video_receive_frame(*AliceAV, t_toxav_receive_video_frame_cb, AliceCC);
    -- toxav_callback_audio_receive_frame(*AliceAV, t_toxav_receive_audio_frame_cb, AliceCC);
aliceav:callback_call(function (toxav, friend_number, audio_enabled, video_enabled, _)
    print (_, "Alice received call")
end, nil)

bobav:callback_call(function (toxav, friend_number, audio_enabled, video_enabled, _)
    print ("Bob received call from friend #", friend_number)
    local rc = ffi.new("TOXAV_ERR_ANSWER[1]")
    if not bobav:answer(friend_number, 0, 5000, rc) then
        print ("Answering call failed:", rc[0])
    end
end, nil)

local send_video_frames = false

bobav:callback_call_state(function(toxav, friend_number, state, _)
    print ("bobs callstate now is", state)
    send_video_frames = true
end, nil)--"Alice->Bob")


aliceav:callback_video_receive_frame(function (av, friend_number, width, height, y, u, v, ystride, ustride, vstride, _)
    print "Alice received Frame"
end, nil)

bobav:callback_video_receive_frame(function (av, friend_number, width, height, y, u, v, ystride, ustride, vstride, _)
    print ("Bob received frame", width, height)
end, nil)


if TEST_TRANSFER_V then
    print "Trying video enc/dec..."
    local rc = ffi.new("TOXAV_ERR_CALL[1]")
    
    if not aliceav:call(0, 0, 2000, rc) then
        print ("Alice: Call to Bob failed!", rc[0])
    end
end

while true do
    iterate_tox()

    if send_video_frames then
        local rc = ffi.new("TOXAV_ERR_SEND_FRAME[1]")
        local result = bobav:video_send_frame(alice_on_bobs_friendlist,
            32, 32, nil, nil, nil, rc)

        if not result then
            --print ("send video frame failed", rc[0])
        end
    end
end
