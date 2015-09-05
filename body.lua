local new = function(x, y, dx, dy, mass, image, name, description, star)
   return {x = x, y = y, dx = dx, dy = dy,
           mass = mass, image = image, name = name, description = description,
           star = star
   }
end

return {
   load = function()
      return {new(3500, 0, 0, 5, 1000,
                  love.graphics.newImage('assets/planet-1.png'), "Earth",
                 "This is a pretty great planet."),
              new(0, 0, 0, 0, 20000,
                  love.graphics.newImage('assets/sun.png'), "Sol", nil, true)}
   end,

   draw = function(body, x, y)
      local bx = body.x - body.image:getWidth() / 2
      local by = body.y - body.image:getHeight() / 2
      love.graphics.draw(body.image, bx - x, by - y)
   end,

   gravitate = function(body, x, y)
      local dx = (x - body.x)
      local dy = (y - body.x)
      local distance = math.sqrt(dx*dx + dy*dy)

      local theta = math.atan2(dx, dy) + math.pi
      local g = 5000

      local f = (body.mass * g) / (distance * distance)
      return (f * math.sin(theta)), (f * math.cos(theta)), f
   end,
}
