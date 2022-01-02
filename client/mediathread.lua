local lovr = {
    thread = require 'lovr.thread',
    data = require 'lovr.data',
    timer = require 'lovr.timer'
}
local in_channel = lovr.thread.getChannel('media_in')
local out_channel = lovr.thread.getChannel('media_out')
local funny = require 'funny'

print('welcome to chillis')
local image = in_channel:pop(true)

print('initial image ref', out_image)

out_channel:push('waiting')
local stream = funny.open('rtsp://localhost:8554/live.sdp')
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
