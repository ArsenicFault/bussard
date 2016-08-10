-- for a new game
return function(ship)
   ship.system_name = "L 668-21"
   ship.flag = "Katilay"
   ship.name = "Adahn"
   ship.api.docs = ship.api.docs or {}
   ship.api.docs.backup = { ["msg1_rot13"] =
         love.filesystem.read("data/docs/traxus-1.rot13")}
   ship.api.docs.mail = ship.api.docs.mail or
      { inbox = { _unread = {} },
        jobs = { _unread = {} },
        archive = { _unread = {} },
      }
   for _,v in pairs(love.filesystem.getDirectoryItems("data/src")) do
      ship.api.src[v] = ship.api.src[v] or love.filesystem.read("data/src/"..v)
   end
   ship.api.editor.print("This is the console. Enter any code for your " ..
                         "ship's computer to run it; run man() for help.")
end
