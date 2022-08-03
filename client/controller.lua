require "pl"

class.Controller()

function Controller:_init(hand)
    self.hand = hand
    self.last_position = nil
    self.active = true
    self.model = nil
end

function Controller:onLoad()
    if lovr.headset ~= nil then
        self.model = lovr.graphics.newModel(
            "quest2_" .. self.hand .. "_hand.glb")
    end
end

function Controller:newPosition(new_vec3_table)
    print(self.hand, "new position!", unpack(new_vec3_table))
    self.last_position = {
        timestamp = lovr.timer.getTime(),
        vector = new_vec3_table,
    }

    -- new positions always mean active
    self.active = true
end

function Controller:onUpdate(dt)
    -- do not apply controller calculations when the mouse's position
    -- will always stay the same (weird stuff on the desktop simulator)
    if lovr.headset == nil then
        self.active = true
        return
    end

    if not lovr.headset.isTracked(self.hand) then
        self.active = false
        return
    end

    local pose = {lovr.headset.getPose(hand)}
    local pose_position_table = {pose[1], pose[2], pose[3]}
    local current_position = vec3(unpack(pose_position_table))
    if self.last_position == nil then
        self:newPosition(pose_position_table)
    else
        -- compare current and last by subtracting them up
        -- and checking the average delta change between them
        --
        -- this is done because two controller positions will never
        -- be exact because
        --
        -- 1) float shenanigans
        -- 2) the world exists and is never exact
        local last_position_vec = vec3(unpack(self.last_position.vector))
        local delta_vec = current_position:sub(last_position_vec)
        local dx, dy, dz = delta_vec:unpack()
        local average_delta = (dx + dy + dz / 3)
        print(self.hand, "avg", average_delta)

        -- movement detected
        if average_delta >= 0 then
            self:newPosition(pose_position_table)
        else
            local current_timestamp = lovr.timer.getTime()
            local delta = current_timestamp - self.last_position.timestamp

            -- no movement for 3 seconds, set inactive
            if delta > 3 then
                self.active = false
            end
        end
    end
end

function Controller:draw()
    if not self.active then
        return
    end

    -- draw the true position given by headset, instead of last_position
    -- (which could be updated by the time we want to draw the frame!)
    if self.model then
        lovr.graphics.setColor(1, 1, 1, 1)
        self.model:draw(mat4(lovr.headset.getPose(self.hand)))
    else
        local position = vec3(lovr.headset.getPosition(self.hand))
        local direction =
            quat(lovr.headset.getOrientation(self.hand)):direction()

        lovr.graphics.setColor(1, 1, 1)
        lovr.graphics.sphere(position, .01)

        lovr.graphics.setColor(1, 0, 0)
        lovr.graphics.line(position, position + direction * 50)
    end
end

return Controller
