require "pl"

class.Floor()

function Floor:_init(args)

    local compiled_floor_vertex = lovr.graphics.compileShader("vertex", [[
    vec4 lovrmain() {
      return DefaultPosition;
    }
    ]])

    local compiled_floor_fragment = lovr.graphics.compileShader('fragment', [[
    const float gridSize = 25.;
    const float cellSize = .5;

    vec4 lovrmain() {

      vec4 gcolor = Color;
      vec2 uv = UV;

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
  ]])

    self.shader = lovr.graphics.newShader(compiled_floor_vertex,compiled_floor_fragment, {flags = {highp = true}})
end

function Floor:draw(pass)
    pass:setShader(self.shader)
    pass:plane(0, 0, 0, 25, 25, -math.pi / 2)

end

return Floor
