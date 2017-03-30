local utils = require("utils")

local hostname = function(body_name)
   return body_name:lower():gsub(" ", "-")
end

local g = 4196

-- Without capping gravity accel, you run into a weird bug caused by
-- the fact that we calculate gravitation discretely instead of
-- continuously. If the point of calculation is one at which you are very close
-- to a star, you'll be given a very high velocity, and the next point of
-- calculation won't happen till you're further away, so gravity won't get
-- a chance to slow you back down. This is only noticeable when you pass over
-- what is essentially the heart of a star, but it's very annoying when you do.

local max_accel = 100

-- return the acceleration felt at (x,y) due to body
local gravitate = function(body, x, y)
   if(body.mass == 0) then return 0, 0 end
   -- a vector that points from (x,y) to the body
   local dx = (body.x - x)
   local dy = (body.y - y)
   local distance = utils.distance(dx, dy)

   -- the same vector but with unit length
   local nx = dx / distance
   local ny = dy / distance

   local accel = math.min((body.mass * g) / (distance * distance), max_accel)
   return (accel * nx), (accel * ny)
end

local is_gravitated_by = function(from, to)
   if(from == to) then return false
   elseif(to.star) then return false
   elseif((to.world or to.portal) and not from.star) then return false
   else return true end
end

local kinds = {"ship", "rover", "asteroid", "world", "star"}
local kind = function(b)
   for _,k in ipairs(kinds) do if b[k] then return b[k] end end
end

return {
   draw = function(body, x, y)
      if(body.draw) then return body:draw(x, y) end
      body.image = body.image or love.graphics.newImage("assets/" ..
                                                           body.image_name .. ".png")
      local scale = body.scale or 1
      body.ox = body.ox or body.image:getWidth() * scale / 2
      body.oy = body.oy or body.image:getHeight() * scale / 2
      love.graphics.draw(body.image, body.x - x, body.y - y,
                         body.rotation, scale, scale, body.ox, body.oy)
   end,

   gravitate = gravitate,

   gravitate_all = function(bodies, ship, dt)
      ship.x = ship.x + (ship.dx * dt)
      ship.y = ship.y + (ship.dy * dt)
      for _, b in ipairs(bodies) do
         b.x = b.x + (b.dx * dt)
         b.y = b.y + (b.dy * dt)

         local ddx, ddy = gravitate(b, ship.x, ship.y)
         ship.dx = ship.dx + dt * ddx
         ship.dy = ship.dy + dt * ddy

         -- apply b's gravity to other bodies
         for _, b2 in ipairs(bodies) do
            if(is_gravitated_by(b, b2)) then
               local ddx2, ddy2 = gravitate(b, b2.x, b2.y)
               b2.dx = b2.dx + (dt * ddx2)
               b2.dy = b2.dy + (dt * ddy2)
            end
         end
      end
   end,

   update = function(bodies, dt)
      for _,b in pairs(bodies) do
         if(b.update) then -- currently only used by AI ships
            b:update(dt)
         end
      end
   end,

   seed_pos = function(b, star)
      if(b.star) then
         b.x, b.y = 0, 0
      elseif(b.r or (b.x and b.y)) then
         assert(star.star, star.name .. " is not a star.")

         b.r = b.r or utils.distance(b.x, b.y)
         local v = math.sqrt((g*star.mass)/b.r)
         local theta = love.math.random() * math.pi * 2

         b.x, b.y = math.sin(theta) * b.r, math.cos(theta) * b.r
         b.dx = math.sin(theta + math.pi / 2) * v
         b.dy = math.cos(theta + math.pi / 2) * v
      end
   end,

   find = function(bodies,name)
      for _,b in pairs(bodies) do if(b.name == name) then return b end end
   end,

   kind = kind,
   hostname = hostname,

   stop = function(b)
      if(b.thread) then
         love.thread.getChannel(b.thread):push({command = "kill"})
         b.thread = nil
      end
   end,

   start = function(b)
      if(b.world and not b.thread) then
         b.input, b.output = love.thread.newChannel(), love.thread.newChannel()
         b.thread = love.thread.newThread("os/server.lua")
         b.thread:start(b.input, b.output, b.os, hostname(b.name))
      end
   end,

   g = g,
   max_accel = max_accel,
}
