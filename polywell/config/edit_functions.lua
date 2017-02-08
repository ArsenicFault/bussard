-- -*- lua -*-
local editor = require("polywell")
local utils = require("polywell.utils")
local lume = require("polywell.lume")
local utf8 = require("polywell.utf8")

editor.find_file = function()
   -- this is more complicated because it offers live feedback as you type.
   local callback = function(input, cancel)
      -- open the file is given, but we don't support opening tables yet
      if(not cancel and type(editor.fs[input]) == "string") then
         editor.open(editor.fs, input)
      end
   end
   -- show completions as you go
   local completer = function(input)
      local separator = getmetatable(editor.fs) and
         getmetatable(editor.fs).__separator
      local completions = utils.completions_for(input, editor.fs, separator)
      -- different types should display differently
      local decorate_type = function(path)
         local x = editor.fs[path]
         if(type(x) == "table") then
            return path .. separator
         elseif(type(x) == "string") then
            return path
         else
            return false
         end
      end
      -- filter out non-table, non-string entries
      return lume.sort(lume.filter(lume.map(completions, decorate_type)),
                       function(s1, s2) return #s1 < #s2 end)
   end
   -- read_line takes a callback function that is called with input.
   editor.read_line("Open: ", callback, {completer=completer})
end

editor.search = function(original_direction)
   local lines, point, point_line = editor.get_lines(), editor.point()
   local continue_from, path = point_line, editor.current_buffer_path()
   local on_change = function(find_next, new_direction)
      local input = editor.get_input()
      local direction = new_direction or original_direction or 1
      local to = (direction < 1) and 1 or #lines
      if(input == "") then return end
      local line = find_next and continue_from or point_line
      for i=line, to, direction do
         local match_point = lines[i]:find(input)
         if(match_point) then
            continue_from = i + direction
            return editor.go_to(i, match_point-1, path)
         end
      end
      -- wrap around to beginning if not found
      if(find_next) then continue_from = 1 end
   end
   local callback = function(_, cancel)
      if(cancel) then editor.go_to(point_line, point) end
   end
   editor.read_line("Search: ", callback,
                    {on_change=on_change,
                     bind={["ctrl-g"]=function() editor.exit_minibuffer(true) end,
                        ["ctrl-n"]=function()
                           editor.exit_minibuffer()
                           editor.next_line()
                        end,
                        ["ctrl-p"]=function()
                           editor.exit_minibuffer()
                           editor.prev_line()
                        end,
                        ["ctrl-f"]=lume.fn(on_change, true),
                        ["ctrl-s"]=lume.fn(on_change, true, 1),
                        ["ctrl-r"]=lume.fn(on_change, true, -1),}})
end

editor.replace = function()
   local lines, point, point_line = editor.get_lines(), editor.point()
   local path = editor.current_buffer_path()
   local function replacer(replace, with, cancel, continue_from)
      for i=continue_from or point_line, #lines do
         if(cancel) then editor.go_to(point_line, point) return end
         local match_point = lines[i]:find(replace)
         if(match_point) then
            editor.go_to(i, match_point-1, path)
            editor.read_line("Replace? [Y/n] ", function(y, inner_cancel)
                           if(not inner_cancel and y == "" or
                              y:lower() == "y" or y:lower() == "yes") then
                              local new_line = lines[i]:gsub(replace, with)
                              editor.set_line(new_line, i, path)
                              replacer(replace, with, false, i+1)
                           end
            end)
            return
         end
      end
   end
   editor.read_line("Replace: ", function(replace_text, cancel)
                       if(cancel) then return end
                       editor.read_line("Replace " .. replace_text .. " with: ",
                                        lume.fn(replacer, replace_text))
   end)
end

editor.switch_buffer = function()
   local last_buffer = editor.last_buffer()
   last_buffer = last_buffer or "*console*"
   local callback = function(b, cancel)
      if(not cancel) then
         editor.change_buffer(b ~= "" and b or last_buffer)
      end
   end
   local completer = function(input)
      return utils.completions_for(input, editor.buffer_names())
   end
   editor.read_line("Switch to buffer (default: " .. last_buffer ..
                            "): ", callback, {completer=completer})
end

editor.reload = function()
   for _,b in pairs(editor.buffer_names()) do
      editor.save(nil, b)
   end
   local chunk = assert(love.filesystem.load("polywell/config/init.lua"))
   chunk()
   print("Successfully reloaded config.")
end

editor.complete = function()
   local _, point_line = editor.point()
   local line = editor.get_line(point_line)
   -- what's the expression being completed?
   local entered = lume.last(lume.array((line):gmatch("[._%a0-9]+"))) or ""
   -- only complete if something is entered
   if(#entered < 1) then return end
   local completions = utils.completions_for(entered, _G, ".")

   -- if there's only one completion candidate, insert it. otherwise insert the
   -- longest unambiguous substring and display a list of candidates.
   if(#completions == 1) then
      editor.textinput(utf8.sub(completions[1], #entered + 1), true)
   elseif(#completions > 0) then
      local common = utils.longest_common_prefix(completions)
      if(common == entered) then
         editor.echo(table.concat(completions, " "))
      else
         editor.textinput(utf8.sub(common, #entered + 1), true)
      end
   end
end