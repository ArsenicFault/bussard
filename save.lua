local lume = require "lume"
local body = require "body"

local ship_fields = {
   "x", "y", "dx", "dy", "heading",
   "battery", "fuel", "credits", "system_name",
   "upgrade_names", "cargo", "target_number",
}

local system_fields = {
   "x", "y", "dx", "dy", "cargo"
}

local ship_filename = "ship_data.lua"
local system_filename = "system_data.lua"

local fs_filename = function(b)
   return b.name .. "_fs.lua"
end

local get_system_data = function(bodies)
   local data = {}
   for _,b in ipairs(bodies) do
      data[b.name] = lume.pick(b, unpack(system_fields))
   end
   return data
end

return {
   save = function(ship)
      local ship_data = lume.pick(ship, unpack(ship_fields))
      ship_data.api = lume.pick(ship.api, unpack(ship.api.persist))
      love.filesystem.write(ship_filename, lume.serialize(ship_data))
      love.filesystem.write(system_filename,
                            lume.serialize(get_system_data(ship.bodies)))
      for _,s in pairs(ship.systems) do
         for _,b in pairs(s.bodies) do
            local fs = body.filesystems[b.name]
            if(fs) then
               orb.fs.strip_special(fs)
               local fs_data = lume.serialize(fs)
               love.filesystem.write(fs_filename(b), fs_data)
            end
         end
      end
   end,

   load_into = function(ship)
      if(love.filesystem.isFile(ship_filename)) then
         local ship_data_string = love.filesystem.read(ship_filename)
         local ship_data = lume.deserialize(ship_data_string)
         local api_data = ship_data.api

         lume.extend(ship.api, api_data)
         ship_data.api = nil

         lume.extend(ship, ship_data)
         ship:enter(ship.system_name)
         ship.api.repl.last_result = nil
      end
      if(love.filesystem.isFile(system_filename)) then
         local system_data_string = love.filesystem.read(system_filename)
         local system_data = lume.deserialize(system_data_string)
         for _,b in ipairs(ship.bodies) do
            lume.extend(b, system_data[b.name])
         end
      end
      for _,s in pairs(ship.systems) do
         for _,b in pairs(s.bodies) do
            if(love.filesystem.isFile(fs_filename(b))) then
               local fs_data = love.filesystem.read(fs_filename(b))
               body.filesystems[b.name] = lume.deserialize(fs_data)
            end
         end
      end
   end,

   abort = function(ship)
      love.filesystem.remove(ship_filename)
      love.filesystem.remove(system_filename)
      for _,s in pairs(ship.systems) do
         for _,b in pairs(s.bodies) do
            love.filesystem.remove(fs_filename(b))
         end
      end
   end,
}
