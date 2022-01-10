local lovr = {
    thread = require 'lovr.thread',
}

local log_channel = lovr.thread.getChannel('logs')
while true do
    local message = log_channel:pop(true)
    print(message)
end
