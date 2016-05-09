local mail = require("mail")
local utils = require("utils")
local mission = require("mission")

return {
   name="passenger2",
   description="Passenger run from Tana Prime to Apkabar Station",
   id="d6069254-4182-4f96-a145-df309a992798",
   destinations={"Tana Prime", "Newton Station"},
   credits=250,
   success_events={"passenger2"},

   prereq=function(ship)
      if(require("lume").find(ship.upgrade_names, "life_support")) then
         return true
      else
         return false, "Cannot take passengers without onboard life support sytem."
      end
   end,

   on_login = function(ship, target)
      local m = ship.active_missions["d6069254-4182-4f96-a145-df309a992798"]
      if(not m.pickup and target == "Tana Prime") then
         m.pickup = 0
      elseif(target == "Interportal: Sol" and not ship.events.try_interportal) then
         mail.deliver_msg(ship, "nari07.msg")
         mission.record_event(ship, "try_interportal")
      elseif(target == "Apkabar Station" and ship.events.try_interportal
             and not ship.events.background_check) then
         mail.deliver_msg(ship, "nari08.msg")
         mission.record_event(ship, "background_check")
      end
   end,

   accept_function = function(ship)
      mail.deliver_msg(ship, "nari01.msg")
   end,

   update = function(ship, dt)
      local m = ship.active_missions["d6069254-4182-4f96-a145-df309a992798"]
      if(not m or not m.pickup) then return end
      m.pickup = m.pickup + dt
      if(m.pickup > 12 and not ship.mail_delivered["nari02"]) then
         mail.deliver_msg(ship, "nari02.msg")
      elseif(m.pickup > 32 and not ship.mail_delivered["nari03"]) then
         mail.deliver_msg(ship, "nari03.msg")
      end
   end,

   -- TODO/blocker: this never runs
   success_function = function(ship)
      mail.deliver(ship, "nari09.msg")
   end,
}

-- messages:
-- 01: on accept
-- 02: timed after accept
-- 03: timed after accept
-- 04: on ack 03
-- 05: on ack 04
-- 06: on ack 05
-- 07: on attempt to interportal
-- 08: on login to apkabar
-- 09: on completion