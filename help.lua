local utils = require("utils")

return {
   -- need to have a string message so just `help' works vs help()
   message = "Type `man()` to view your ship's operating manual.",
   man = function()
      return utils.read_file("manual.md")
   end
}
