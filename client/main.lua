-- local socket = require("socket")
local lovr = require("lovr")
local loglib = require("log")

local Window = require "window"
local Floor = require "floor"
local Controller = require "controller"

ctx = {controllers = {left = Controller("left"), right = Controller("right")}}

ctx.windows = {
    screen_1 = Window({
        position = {0, 1.5, -3},
        size = {3.55, 2},
        rotation = {math.pi, 1, 0, 0},
    }),
    screen_2 = Window({
        position = {3, 2, -3},
        size = {2.24, 4},
        rotation = {math.pi, 1, 0, 0},
    }),
}

ctx.floor = Floor()

function lovr.load()
    local log_thread = loglib.startLogThread()
    if log_thread == nil then
        print("logs were unable to be loaded")
        lovr.event.quit(1)
    end

    ctx.controllers.left:onLoad()
    ctx.controllers.right:onLoad()

    ctx.canvas_1 = lovr.graphics.newCanvas(1366, 768, {
        format = "rgb",
        stereo = false,
        mipmaps = true,
        msaa = 8,
    })
    ctx.image_1 = ctx.canvas_1:newImage()
    ctx.material_1 = lovr.graphics.newMaterial(ctx.canvas_1:getTexture(), 1, 1,
                                               1, 1)

    ctx.canvas_2 = lovr.graphics.newCanvas(1080, 1920, {
        format = "rgb",
        stereo = false,
        mipmaps = true,
        msaa = 8,
    })
    ctx.image_2 = ctx.canvas_2:newImage()
    ctx.material_2 = lovr.graphics.newMaterial(ctx.canvas_2:getTexture(), 1, 1,
                                               1, 1)

    ctx.screen_1_in = lovr.thread.getChannel("screen_1_in")
    ctx.screen_2_in = lovr.thread.getChannel("screen_2_in")
    ctx.coordinator_channel = lovr.thread.getChannel("coordinator")

    local ret = lovr.filesystem.read("mediathread.lua")
    if ret == nil then
        print("failed to load mediathread.lua")
    end
    local media_thread_code, media_thread_bytes = ret
    print(media_thread_bytes, "bytes for media thread code")
    ctx.thread_1 = lovr.thread.newThread(media_thread_code)
    ctx.coordinator_channel:push("screen_1")
    ctx.thread_1:start()
    ctx.thread_2 = lovr.thread.newThread(media_thread_code)
    ctx.coordinator_channel:push("screen_2")
    ctx.thread_2:start()

    ctx.screen_1_in:push("rtsp://192.168.0.237:8554/screen_1.sdp")
    ctx.screen_1_in:push(ctx.image_1)

    ctx.screen_2_in:push("rtsp://192.168.0.237:8554/screen_2.sdp")
    ctx.screen_2_in:push(ctx.image_2)
end

function lovr.update()
    for _, controller in pairs(ctx.controllers) do
        controller:onUpdate()
    end
end

function lovr.draw()
    ctx.floor:draw()

    -- for each screen, we need to replacePixels
    lovr.graphics.setShader()
    ctx.canvas_1:getTexture():replacePixels(ctx.image_1)
    ctx.windows.screen_1:draw(ctx.material_1)

    ctx.canvas_2:getTexture():replacePixels(ctx.image_2)
    ctx.windows.screen_2:draw(ctx.material_2)

    -- lovr.graphics.plane(ctx.material_2, 1.56, 1.4, -2, 1.125, 2, math.pi, 1, 0, 0)

    for _, controller in pairs(ctx.controllers) do
        controller:draw()
    end
end

function lovr.log(message, level, tag)
    print("lovr.log", tag, level, message)
end
