local lovr = {
    thread = require 'lovr.thread',
    data = require 'lovr.data',
    timer = require 'lovr.timer'
}
local funny = require 'funny'

local coordinator = lovr.thread.getChannel('coordinator')
-- TODO logging thread everyone spits stuff to
--  TODO lovr channels do have a mutex on them, right?
print('welcome to chillis')
local thread_id = coordinator:pop(true)
print('thread id', thread_id)

local in_channel = lovr.thread.getChannel(thread_id..'_in')
local out_channel = lovr.thread.getChannel(thread_id..'_out')

local rtsp_url = in_channel:pop(true)
print('rtsp url', thread_id, rtsp_url)

local image = in_channel:pop(true)
print('image ref', thread_id, image)

out_channel:push('waiting')
local stream = funny.open(rtsp_url)
out_channel:push('ok')

local FPS_TARGET = 60
local fps_budget = (1 / FPS_TARGET)

while true do
    print('frame time!', stream, image)
    local frame_time = funny.fetchFrame(stream, image:getBlob():getPointer())

    local delta = fps_budget - frame_time

    print('timings', fps_budget, frame_time, delta)

    if delta > 0 then
        -- good case: we decoded fast
        -- we can sleep the rest of the ms knowing we're on 60fps target
        lovr.timer.sleep(delta)
    elseif delta < 0 then
        -- bad case, we decoded slow
        print('shit!')
    end
end
