local lovr = {thread = require "lovr.thread"}
-- necessary to start thread
local loglib = require "log"
local log = loglib.Logger:new("media")
local coordinator = lovr.thread.getChannel("coordinator")
log:info("thread get")
local thread_id = coordinator:pop(true)
log = loglib.Logger:new(thread_id)
log:info("thread start")
coordinator:push(true)

local lovr = {
    thread = require "lovr.thread",
    data = require "lovr.data",
    timer = require "lovr.timer",
    filesystem = require "lovr.filesystem",
}

local rtsp = require "rtsp2"

local in_channel = lovr.thread.getChannel(thread_id .. "_in")
local out_channel = lovr.thread.getChannel(thread_id .. "_out")

local stream = rtsp.create()

log:info("created stream %s", tostring(stream))
local rtsp_url = in_channel:pop(true)
log:info("rtsp url: %s", rtsp_url)
rtsp.open_v2(stream, rtsp_url)

local slice_configuration = in_channel:pop(true)

local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

-- instead of creating two threads, do it in a single thread that
-- slices the main incoming frame into two screens that are fed
-- to each image sequentially.
for _, slice_description in ipairs(mysplit(slice_configuration, ";")) do
    if slice_description == "ALL" then
        local debug_image = in_channel:pop(true)
        rtsp.addDebugFrame(stream, debug_image:getBlob():getPointer())
    else

        local splitted = mysplit(slice_description, ",")
        local offset_x, offset_y, size_x, size_y = tonumber(splitted[1]),
                                                   tonumber(splitted[2]),
                                                   tonumber(splitted[3]),
                                                   tonumber(splitted[4])

        local slice_image = in_channel:pop(true)

        log:info("recv %d %d %d %d", offset_x, offset_y, size_x, size_y)
        rtsp.addSlice(stream, offset_x, offset_y, size_x, size_y,
                      slice_image:getBlob():getPointer())
        log:info("slice ok")

    end
end

log:info("starting main loop")
local result = rtsp.runMainLoop(stream)
out_channel:push(result)
