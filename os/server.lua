require("love.filesystem")
require("love.math")
require("love.thread")

local dbg = os.getenv("DEBUG") and print or function() end
local output, input, os_name, hostname = ...
local os_ok, os = pcall(require, "os." .. os_name .. ".init")
if(not os_ok) then print("Couldn't load OS:", os) return end

local sessions = {}

local new_session = function(username, password)
   if(not os.is_authorized(hostname, username, password)) then return false end
   local session_id = string.format("%x", love.math.random(4294967296))
   local stdin = love.thread.newChannel()
   sessions[session_id] = os.new_session(stdin, output, username, hostname)
   sessions[session_id].stdin = stdin
   output:push({op="status", ok=true, ["new-session"] = session_id})
   return true
end

while true do
   local msg = input:demand()
   -- TODO: range check
   dbg(">", require("lume").serialize(msg))
   if(msg.op == "kill") then return
   elseif(msg.op == "login") then
      local handle = function() print(debug.traceback()) end
      if(not xpcall(new_session, handle, msg.username, msg.password)) then
         output:push({op="status", out="Login failed."})
      end
   elseif(msg.op == "stdin") then
      local session = sessions[msg.session]
      if(session) then
         session.stdin:push(msg.stdin)
      else
         print("Warning: no session", msg.session)
      end
   elseif(msg.op == "debug") then
      pp(sessions)
   end
end