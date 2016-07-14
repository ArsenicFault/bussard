local systems = require("data.systems")

local subnet_client = love.filesystem.read("os/orb/resources/subnet")

local subnet_user = { username="subnet",
                      password="reindeerflotilla",
                      files={["/home/subnet/_smashrc"]=subnet_client,
                         ["/home/subnet/bin/subnet"]=subnet_client} }

local data = {}

for _,sys in pairs(systems) do
   for _,body in pairs(sys.bodies) do
      if(body.subnet) then data[body.name] = {subnet = subnet_user} end
   end
end

return data