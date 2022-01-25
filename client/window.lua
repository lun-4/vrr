require 'pl'
local util = require 'util'

class.Window()

function Window:_init(args)
    self.hover = false
    self.active = false

    self.position = args.position
    self.size = args.size
    self.rotation = args.rotation

    self:_compute_draw_args()
end

function Window:_compute_draw_args()
    self._draw_args = util.table_concat({self.position, self.size, self.rotation})
end

function Window:draw(material)
    lovr.graphics.setShader()
    lovr.graphics.setColor(1, 1, 1, 1)
    lovr.graphics.plane(
        material,
        unpack(self._draw_args)
    )
end

return Window
