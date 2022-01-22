local lovr = {
    thread = require 'lovr.thread',
    data = require 'lovr.data',
    timer = require 'lovr.timer',
    filesystem = require 'lovr.filesystem'
}

local funny = require 'rtsp'
local loglib = require 'log'

local log = loglib.Logger:new('media')

local coordinator = lovr.thread.getChannel('coordinator')
log:info('media thread start')
local thread_id = coordinator:pop(true)
log:info('received thread id: %s', thread_id)

log = loglib.Logger:new(thread_id)

local in_channel = lovr.thread.getChannel(thread_id..'_in')
local out_channel = lovr.thread.getChannel(thread_id..'_out')

local rtsp_url = in_channel:pop(true)
log:info('rtsp url %s', rtsp_url)

local image = in_channel:pop(true)
log:info('image ref %s', image)

out_channel:push('waiting')
local stream = funny.open(rtsp_url)
out_channel:push('ok')

local FPS_TARGET = 45
local fps_budget = (1 / FPS_TARGET)

while true do
    log:info('frame time!', stream, image)
    local frame_time = funny.fetchFrame(stream, image:getBlob():getPointer())

    local delta = fps_budget - frame_time

    log:info('timings %f %f %f',fps_budget, frame_time, delta)

    if delta > 0 then
        -- good case: we decoded fast
        -- we can sleep the rest of the ms knowing we're on 60fps target
        lovr.timer.sleep(delta)
    elseif delta < 0 then
        -- bad case, we decoded slow
        log:info('timings are shit!')
    end
end
