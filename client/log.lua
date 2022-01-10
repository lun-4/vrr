-- simple logging system that handles multithreading
local lovr = {
    thread = require 'lovr.thread',
    filesystem = require 'lovr.filesystem',
}

log_channel = lovr.thread.getChannel('logs')
mod = {}

mod.Logger = {name=nil}

function mod.Logger:new(name)
    local ret = {name=name}
    setmetatable(ret, self)
    self.__index = self
    return ret
end

function mod.Logger:any(tag, msg, ...)
    local arg = {...}
    local line = string.format('[%s %s] '..msg, tag, self.name, unpack(arg or {}))
    log_channel:push(line)
end

function mod.Logger:info(msg, ...)
    return self:any('info', msg, ...)
end
function mod.Logger:error(msg, ...)
    return self:any('error', msg, ...)
end
function mod.Logger:warn(msg, ...)
    return self:any('warn', msg, ...)
end
function mod.Logger:debug(msg, ...)
    return self:any('debug', msg, ...)
end

-- calling this function twice is undefined behavior
function mod.startLogThread()
    local ret = lovr.filesystem.read('log_thread.lua')
    if ret == nil then
        print('failed to load log_thread.lua')
        return nil
    end
    local log_thread = lovr.thread.newThread(ret)
    log_thread:start()
    return log_thread
end

return mod
