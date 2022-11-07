require "pl"
local util = require "util"

class.Window()

function Window:_init(args)
    self.hover = false
    self.active = false

    self.position = lovr.math.vec3(unpack(args.position))
    self.size = lovr.math.vec3(unpack(args.size))
    self.rotation = lovr.math.newQuat(unpack(args.rotation))

    self:_compute_draw_args()
end

function Window:_compute_draw_args()
    self._draw_args = lovr.math.newMat4(self.position, self.size, self.rotation)
end

function Window:draw(pass)
    pass:setColor(1, 1, 1, 1)
    pass:plane(self._draw_args)
end

return Window
