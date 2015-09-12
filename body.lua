local utils = require "utils"

local seed = function(os)
   local raw = os.fs.new_raw()
   os.fs.seed(os.fs.proxy(raw, "root", raw), {guest = ""})
   return raw
end

local filesystems = {}

local g = 1000

return {
   draw = function(body, x, y)
      local bx = body.x - body.image:getWidth() / 2
      local by = body.y - body.image:getHeight() / 2
      love.graphics.draw(body.image, bx - x, by - y)
   end,

   gravitate = function(body, x, y)
      local dx = (x - body.x)
      local dy = (y - body.y)

      local distance = utils.distance(dx, dy)
      local theta = math.atan2(dx, dy) + math.pi

      local f = (body.mass * g) / (distance * distance)
      return (f * math.sin(theta)), (f * math.cos(theta))
   end,

   escape_velocity = function(body, escapee)
      local distance = utils.distance(body.x - escapee.x,
                                      body.y - escapee.y)
      return math.sqrt(2*g*body.mass / distance)
   end,

   -- currently you can log into any body that's not a star
   login = function(body, username, password)
      if((not body) or body.star) then return false end
      filesystems[body.name] = filesystems[body.name] or seed(body.os)
      return body.os.shell.auth(filesystems[body.name], username, password) and
         filesystems[body.name]
   end,

   schedule = function(bodies)
      for _,b in pairs(bodies) do
         local fs = filesystems[b.name]
         if b.os and fs then b.os.process.scheduler(fs) end
      end
   end,

   seed_cargo = function(b)
      if(not b.prices) then return end
      b.cargo = {}
      for name,info in pairs(b.prices) do
         b.cargo[name] = math.random(info.stock)
      end
   end,

   seed_pos = function(b, star)
      if(b.star or b.asteroid) then return end
      assert(star.star, star.name .. " is not a star.")

      local theta = math.random(math.pi * 2)
      local v = math.sqrt((g*star.mass)/b.r) / 8

      b.x, b.y = math.sin(theta) * b.r, math.cos(theta) * b.r
      -- the velocity calculations here are not quite right, but close
      b.dx = math.sin(theta + math.pi / 2) * v
      b.dy = math.cos(theta + math.pi / 2) * v
   end,

   find = function(bodies,name)
      for _,b in pairs(bodies) do if(b.name == name) then return b end end
   end,
}
