local socket = require("socket")

ctx = {}

function lovr.load()
    ctx.image = lovr.data.newImage(1366, 768, 'rgb', nil)
    ctx.texture = lovr.graphics.newTexture(ctx.image, {type='2d', msaa=0, mipmaps=false})
    ctx.material = lovr.graphics.newMaterial(ctx.texture)

    ctx.media_in_channel = lovr.thread.getChannel('media_in')
    ctx.media_out_channel = lovr.thread.getChannel('media_out')
    local media_thread_code = lovr.filesystem.read('./mediathread.lua')
    ctx.thread = lovr.thread.newThread(media_thread_code)
    ctx.media_in_channel:push(ctx.image)
    ctx.thread:start()
  floor_shader = lovr.graphics.newShader([[
    vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
      return projection * transform * vertex;
    }
  ]], [[
    const float gridSize = 25.;
    const float cellSize = .5;

    vec4 color(vec4 gcolor, sampler2D image, vec2 uv) {

      // Distance-based alpha (1. at the middle, 0. at edges)
      float alpha = 1. - smoothstep(.15, .50, distance(uv, vec2(.5)));

      // Grid coordinate
      uv *= gridSize;
      uv /= cellSize;
      vec2 c = abs(fract(uv - .5) - .5) / fwidth(uv);
      float line = clamp(1. - min(c.x, c.y), 0., 1.);
      vec3 value = mix(vec3(.01, .01, .011), (vec3(.04)), line);

      return vec4(vec3(value), alpha);
    }
  ]], { flags = { highp = true } })
end

function lovr.update()
    local blob = ctx.image:getBlob()
    local blob_ptr = blob:getPointer()

    local message = ctx.media_out_channel:pop()
    if message ~= nil then
        local mtype, mdata = message
        print('message', mtype, mdata)
        if mtype == 'frame' then
            ctx.image:paste(mdata)
        end
    end
end

function lovr.draw()
    lovr.graphics.setShader(floor_shader)
    lovr.graphics.plane('fill', 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
    lovr.graphics.setShader()
    -- for i=0,700,1 do
    --     ctx.image:setPixel(30 + i, 30 + i, 1, 1, 1)
    -- end
    -- for i=0,50 do
    --     ctx.image:setPixel(30, 30 + i, 1, 1, 1)
    -- end
    ctx.texture:replacePixels(ctx.image)
    lovr.graphics.plane(ctx.material, 0, 1.4, -2, 1.77, 1)
    --lovr.graphics.print("connecting", 0, 1.4, -2, 0.5)
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
