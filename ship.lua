local calculate_distance = function(x, y) return math.sqrt(x*x+y*y) end
local default_config_file = io.open("default_config.lua", "r")
local default_config = default_config_file:read("*all")
default_config_file:close()

local repl = require("love-repl")

local sandbox = {
   pairs = pairs,
   ipairs = ipairs,
   unpack = unpack,
   print = repl.print,
   realprint = print,
   coroutine = { yield = coroutine.yield,
                 status = coroutine.status },
   io = { write = write, read = read },
   tonumber = tonumber,
   tostring = tostring,
   math = math,
   type = type,
   table = { concat = table.concat,
             remove = table.remove,
             insert = table.insert,
   },
}

local ship = {
   x = -200, y = 0,
   dx = 0, dy = 0,
   heading = math.pi,

   engine = 10,
   engine_on = false,
   turning_speed = 3,
   turning_right = false,
   turning_left = false,

   fuel = 100,
   recharge_rate = 1,
   burn_rate = 5,
   mass = 10,

   comm_connected = false,
   comm_range = 450,
   target_number = 0,
   target = nil,

   config = default_config,

   configure = function(ship, bodies, game_api)
      local font = love.graphics.newFont("mensch.ttf", 20)
      repl.initialize()
      repl.screenshot = false
      repl.font = font
      repl.sandbox = sandbox
      ship.api.sensors.bodies = function() return bodies end
      local chunk = assert(loadstring(ship.config))
      sandbox.ship = ship.api
      sandbox.game = game_api
      setfenv(chunk, sandbox)
      chunk()
   end,

   update = function(ship, dt)
      ship.api.dt = dt
      -- calculate movement
      ship.x = ship.x + (ship.dx * dt * 100)
      ship.y = ship.y + (ship.dy * dt * 100)

      -- activate controls
      for k,f in pairs(ship.api.controls) do
         f(love.keyboard.isDown(k))
      end

      if(ship.engine_on and ship.fuel > 0) then
         ship.dx = ship.dx + (math.sin(ship.heading) * dt * ship.engine)
         ship.dy = ship.dy + (math.cos(ship.heading) * dt * ship.engine)
         ship.fuel = ship.fuel - (ship.burn_rate * dt)
      elseif(ship.fuel < 100) then
         ship.fuel = ship.fuel + (ship.recharge_rate * dt)
      end

      if(ship.turning_left) then
         ship.heading = ship.heading + (dt * ship.turning_speed)
      elseif(ship.turning_right) then
         ship.heading = ship.heading - (dt * ship.turning_speed)
      end
   end,

   in_range = function(ship, body)
      return calculate_distance(ship.x - body.x, ship.y - body.y) <
         ship.comm_range
   end,
}

ship.api = {
   repl = repl,
   sensors = {
      x = function() return ship.x end,
      y = function() return ship.y end,
      dx = function() return ship.dx end,
      dy = function() return ship.dy end,
      heading = function() return ship.heading end,
      fuel = function() return ship.fuel end,
   },
   actions = {
      forward = function(down) ship.engine_on = down end,
      left = function(down) ship.turning_left = down end,
      right = function(down) ship.turning_right = down end,
      next_target = function()
         local bodies = ship.api.sensors.bodies()
         ship.target_number = (ship.target_number + 1) % (#bodies + 1)
         ship.target = bodies[ship.target_number]
      end,
      connect = function()
         if(ship.target and ship:in_range(ship.target)) then
            repl.print("Connecting to " .. ship.target.name .. "... TODO")
         else
            repl.print("Could not connect.")
         end
      end,
   },
   -- added by loading config
   controls = {},
   commands = {},
}

return ship
