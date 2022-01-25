--local socket = require("socket")
local lovr = require('lovr')
local loglib = require('log')


local Window = require 'window'
local Floor = require 'floor'

ctx = {
    last_controller_position = {
        left = nil,
        right = nil,
    },

    active_controller = {
        left = true,
        right = true,
    }
}

ctx.windows = {
    screen_1 = Window({
        position = {0, 1.5, -3},
        size = {3.55, 2},
        rotation = {math.pi, 1, 0, 0},
    })
}

ctx.floor = Floor()

function lovr.load()
    local log_thread = loglib.startLogThread()
    if log_thread == nil then
        print('logs were unable to be loaded')
        lovr.event.quit(1)
    end

    ctx.models = {}
    if lovr.headset.getDriver() ~= "desktop" then
        src_path = lovr.filesystem.getSource()
        print('src path:', src_path)
        ctx.models.left = lovr.graphics.newModel('quest2_left_hand.glb')
        ctx.models.right = lovr.graphics.newModel('quest2_right_hand.glb')
    end

    ctx.image_1 = lovr.data.newImage(1366, 768, 'rgb', nil)
    ctx.texture_1 = lovr.graphics.newTexture(ctx.image_1, {type='2d', msaa=8, mipmaps=false})
    ctx.material_1 = lovr.graphics.newMaterial(ctx.texture_1)

    --ctx.image_2 = lovr.data.newImage(1080, 1920, 'rgb', nil)
    --ctx.texture_2 = lovr.graphics.newTexture(ctx.image_2, {type='2d', msaa=8, mipmaps=false})
    --ctx.material_2 = lovr.graphics.newMaterial(ctx.texture_2)

    ctx.screen_1_in = lovr.thread.getChannel('screen_1_in')
    ctx.screen_2_in = lovr.thread.getChannel('screen_2_in')
    ctx.coordinator_channel = lovr.thread.getChannel('coordinator')

    local ret = lovr.filesystem.read('mediathread.lua')
    if ret == nil then
        print('failed to load mediathread.lua')
    end
    local media_thread_code, media_thread_bytes = ret
    print(media_thread_bytes, 'bytes for media thread code')
    ctx.thread_1 = lovr.thread.newThread(media_thread_code)
    ctx.coordinator_channel:push("screen_1")
    ctx.thread_1:start()
    ctx.thread_2 = lovr.thread.newThread(media_thread_code)
    ctx.coordinator_channel:push("screen_2")
    --ctx.thread_2:start()

    ctx.screen_1_in:push('rtsp://192.168.0.237:8554/screen_1.sdp')
    ctx.screen_1_in:push(ctx.image_1)
    --ctx.screen_2_in:push('rtsp://192.168.0.237:8554/screen_2.sdp')
    --ctx.screen_2_in:push(ctx.image_2)
end

function lovr.update()

    for hand, model in pairs(ctx.models) do
        if lovr.headset.isTracked(hand) then
            local pose = {lovr.headset.getPose(hand)}
            local current_position = vec3(pose[1], pose[2], pose[3])
            local last_position = ctx.last_controller_position[hand]
            if last_position == nil then
                print('new position!', current_position:unpack())
                ctx.last_controller_position[hand] = {
                    lovr.timer.getTime(),
                    {current_position:unpack()},
                }
            elseif last_position ~= nil then
                local delta_vec = current_position:sub(vec3(unpack(last_position[2])))
                local dx, dy, dz = delta_vec:unpack()
                local average_delta = (dx+dy+dz / 3)

                -- movement detected
                if average_delta > 0.1 then
                    print('new position!', current_position:unpack())
                    ctx.last_controller_position[hand] = {
                        lovr.timer.getTime(),
                        {current_position:unpack()},
                    }
                    if not ctx.active_controller[hand] then
                        ctx.active_controller[hand] = true
                    end
                else
                    local last_timestamp = last_position[1]
                    local current_timestamp = lovr.timer.getTime()

                    local delta = current_timestamp - last_timestamp

                    if delta > 3 and ctx.active_controller[hand] then
                        ctx.active_controller[hand] = false
                    end
                end
            end
        end
    end
end

function lovr.draw()
    ctx.floor:draw()

    -- for each screen, we need to replacePixels
    ctx.texture_1:replacePixels(ctx.image_1)
    ctx.windows.screen_1:draw(ctx.material_1)

    --lovr.graphics.plane(ctx.material_2, 1.56, 1.4, -2, 1.125, 2, math.pi, 1, 0, 0)

    for hand, model in pairs(ctx.models) do
        if ctx.active_controller[hand] and lovr.headset.isTracked(hand) then
            model:draw(mat4(lovr.headset.getPose(hand)))
        end
    end
end

--[[

scenes = {
    connection_start = 0,
    connection_loading = 1,
    wait_screen = 2,
    connection_error = 3,
    main = 4
}

OpCode = {
    HELLO = 1
}

ctx = {
    scene = nil,
    state = {}
}

local function receive_message(sock)
    print(sock)
    local opcode = sock:receive(4)
    if opcode == nil then return nil end
    print('recv raw op', opcode)
    local actual_opcode = tonumber(opcode)
    print('recv op', actual_opcode)
    return {op = actual_opcode}
end

function lovr.load()
    ctx.state.tcp = socket.tcp()
end

function lovr.update()
    if ctx.scene == nil then
        ctx.scene = scenes.connection_loading
        print('attempting to connect')
        local ok, err = ctx.state.tcp:connect("192.168.0.237", 9696)
        ctx.state.sock = ok
        ctx.state.sock_error = err
        ctx.scene = scenes.connection_loading
    elseif ctx.scene == scenes.connection_loading then
        if ctx.state.sock == 1 then
            -- we have a socket, receive a message!
            local message = receive_message(ctx.state.tcp)
            print('msg', message.op)
            if message.op == OpCode.HELLO then
                ctx.scene = scenes.wait_screen
            end
        else
            -- no socket, what to do?
        end
    elseif ctx.scene == scenes.wait_screen then
        -- local message = receive_message(ctx.state.tcp)
        -- print('msg', message)
        -- if message and message.op == OpCode.SCREEN then
        --     ctx.scene = scenes.main
        -- else
        --     ctx.scene = scenes.connection_error
        -- end
    end
end

function lovr.draw()
    if ctx.scene == nil then
        lovr.graphics.print("connecting", 0, 1.4, -2, 0.5)
    elseif ctx.scene == scenes.connection_loading then
        lovr.graphics.print("ok? " .. tostring(ctx.state.sock), 0, 1.4, -4, 0.5)
        lovr.graphics.print("err? " .. tostring(ctx.state.sock_error), 0, 0.5, -4, 0.5)
    elseif ctx.scene == scenes.wait_screen then
        lovr.graphics.print("waiting for screen data", 0, 0.5, -4, 0.5)
    end
end

]]
