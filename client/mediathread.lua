local lovr = {
    thread = require "lovr.thread",
    data = require "lovr.data",
    timer = require "lovr.timer",
    filesystem = require "lovr.filesystem",
}

local rtsp = require "rtsp"
local loglib = require "log"

local log = loglib.Logger:new("media")

local coordinator = lovr.thread.getChannel("coordinator")
log:info("media thread start")
local thread_id = coordinator:pop(true)
log:info("received thread id: %s", thread_id)

log = loglib.Logger:new(thread_id)

local in_channel = lovr.thread.getChannel(thread_id .. "_in")
local out_channel = lovr.thread.getChannel(thread_id .. "_out")

local rtsp_url = in_channel:pop(true)
log:info("rtsp url %s", rtsp_url)

local image = in_channel:pop(true)
log:info("image ref %s", image)

out_channel:push("waiting")
local stream = rtsp.open(rtsp_url)
out_channel:push("ok")

local blob = image:getBlob()
log:info("blob size %d", blob:getSize())
rtsp.frameLoop(stream, blob:getPointer(), blob:getSize())
