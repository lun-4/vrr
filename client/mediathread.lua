local lovr = { thread = require 'lovr.thread', data = require 'lovr.data' }
local in_channel = lovr.thread.getChannel('media_in')
local out_channel = lovr.thread.getChannel('media_out')
local funny = require 'funny'

print('welcome to chillis')
local image = in_channel:pop(true)

print('initial image ref', out_image)

out_channel:push('waiting')
local stream = funny.open('rtsp://localhost:8554/live.sdp')
out_channel:push('ok')

while true do
    print('frame time!', stream, image)
    local frame_data = funny.fetchFrame(stream, image:getBlob():getPointer())
    print('frame is REAL')
    --out_channel:push('frame')
end
