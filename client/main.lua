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

new_method = false

function lovr.load()
    local log_thread = loglib.startLogThread()
    if log_thread == nil then
        print("logs were unable to be loaded")
        lovr.event.quit(1)
    end

    ctx.controllers.left:onLoad()
    ctx.controllers.right:onLoad()

    ctx.image_1 = lovr.data.newImage(1366, 768, "rgba8")
    ctx.texture_1 = lovr.graphics.newTexture(ctx.image_1, {
        type = '2d',
        stereo = false,
        mipmaps = true,
        label = 'screen 1 texture'
    })

    ctx.image_2 = lovr.data.newImage(1366, 768, "rgba8")
    ctx.texture_2 = lovr.graphics.newTexture(ctx.image_2, {
        type = '2d',
        stereo = false,
        mipmaps = true,
        label = 'screen 1 texture'
    })

    if new_method then
        local coordinator_channel = lovr.thread.getChannel("coordinator")

        local media_thread_code = assert(
            lovr.filesystem.read("new_mediathread.lua"),
            "failed to load mediathread.lua")
        local media_thread = lovr.thread.newThread(media_thread_code)
        coordinator_channel:push("media")
        media_thread:start()
        coordinator_channel:push("media")
        assert(coordinator_channel:pop(true), "failed to create thread")

        ctx.in_channel = lovr.thread.getChannel("media_in")
        ctx.out_channel = lovr.thread.getChannel("media_out")

        -- ctx.in_channel:push("rtsp://192.168.0.237:8554/screen.sdp")
        ctx.in_channel:push("/home/luna/woob_tokyo_run.mp4")
        -- ctx.in_channel:push("0,0,1366,768;1366,0,1080,1920;ALL")
        ctx.in_channel:push("0,0,800,300;800,800,1280,300;ALL")
        ctx.in_channel:push(ctx.image_1)
        ctx.in_channel:push(ctx.image_2)
        ctx.in_channel:push(ctx.image_3) -- holds it for debugging
    else
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

        ctx.screen_1_in:push("rtsp://127.0.0.1:8554/screen_1.sdp")
        ctx.screen_1_in:push(ctx.image_1)

        ctx.screen_2_in:push("rtsp://127.0.0.1:8554/screen_2.sdp")
        ctx.screen_2_in:push(ctx.image_2)
    end
end

function lovr.update()
    --for _, controller in pairs(ctx.controllers) do
    --    controller:onUpdate()
    --end
end

function lovr.draw(pass)
    print('draw',pass)
    ctx.floor:draw(pass)

    -- for each screen, we need to replacePixels
    pass:setShader()

    pass:setMaterial(ctx.image_1)
    ctx.windows.screen_1:draw(pass)

    pass:setMaterial(ctx.image_2)
    ctx.windows.screen_2:draw(pass)

    for _, controller in pairs(ctx.controllers) do
        controller:draw(pass)
    end
end

function lovr.log(message, level, tag)
    print("lovr.log", tag, level, message)
end
