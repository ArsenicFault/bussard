local lume = require("lume")

--- Essentially a port of Emacs to Lua/Love.
-- missing features (a very limited list)
-- * search/replace
-- * syntax highlighting
-- * minibuffer

local kill_ring = {}

local make_buffer = function(fs, path, lines)
   return { fs=fs, path=path, mode = "edit",
            lines = lines or lume.split((fs and fs:find(path)) or "", "\n"),
            point = 0, point_line = 1, mark = nil, mark_line = nil,
            last_yank = nil, mark_ring = {},
            history = {}, undo_at = 0, dirty = false, needs_save = false,
            modeline = function(b)
               return string.format(" %s  %s  (%s/%s)  %s", b.needs_save and "*" or "-",
                                    b.path, b.point_line, #b.lines, b.mode)
            end
   }
end

-- how many lines do pageup/pagedown scroll?
local scroll_size = 20
-- How many pixels of padding are on either side
local PADDING = 20
-- how far down do you go before it starts to scroll?
local SCROLL_POINT = 0.8
-- How many pixels are required to display a row
local ROW_HEIGHT
-- Maximum amount of rows that can be displayed on the screen
local DISPLAY_ROWS
-- width of an m
local em
-- pattern for word breaks
local word_break = "[%s%p]+"

local kill_ring_max = 32
local mark_ring_max = 32
local history_max = 128

local console = make_buffer(nil, "*console*", {"This is the console.", "> "})
console.prevent_close, console.point, console.point_line = true, 2, 2
console.mode, console.prompt = "console", "> "

local mb
local last_buffer -- for returning too after leaving minibuffer
local buffers = {console}
local b = nil -- default back to flight mode

local inhibit_read_only

local last_line = "Press ctrl-enter to open the console, " ..
   "and run man() for more help. Zoom with = and -."

local invisible = {}             -- sentinel "do not print" value

local state = function()
   return {lines = lume.clone(b.lines), point = b.point, point_line = b.point_line}
end

local undo = function()
   local prev = b.history[#b.history-b.undo_at]
   if(b.undo_at < #b.history) then b.undo_at = b.undo_at + 1 end
   if(prev) then
      b.lines, b.point, b.point_line = prev.lines, prev.point, prev.point_line
   end
end

local wrap = function(fn, ...)
   b.dirty = false
   local last_state = state()
   if(fn ~= undo) then b.undo_at = 0 end
   fn(...)
   if(b and b.dirty) then
      table.insert(b.history, last_state)
   end
   if(b and #b.history > history_max) then
      table.remove(b.history, 1)
   end
end

local with_current_buffer = function(nb, f)
   local old_b = b
   b = nb
   local val = f()
   b = old_b
   return val
end

local region = function()
   b.mark = math.min(string.len(b.lines[b.mark_line]), b.mark)

   if(b.point_line == b.mark_line) then
      local start, finish = math.min(b.point, b.mark), math.max(b.point, b.mark)
      return {b.lines[b.point_line]:sub(start+1, finish)}, b.point_line, start, b.point_line, finish
   elseif(b.mark == nil or b.mark_line == nil) then
      return {}, b.point_line, b.point, b.point_line, b.point
   else
      local start_line, start, finish_line, finish
      if(b.point_line < b.mark_line) then
         start_line, start, finish_line,finish = b.point_line,b.point,b.mark_line,b.mark
      else
         start_line, start, finish_line,finish = b.mark_line,b.mark,b.point_line,b.point
      end
      local r = {b.lines[start_line]:sub(start+1, -1)}
      for i = start_line+1, finish_line-1 do
         table.insert(r, b.lines[i])
      end
      table.insert(r, b.lines[finish_line]:sub(0, finish))
      return r, start_line, start, finish_line, finish
   end
end

-- would be nice to have a more general read-only property
local in_prompt = function(line, point, line2, _point2)
   if(not b.prompt) then return false end
   if(not line2 and line ~= #b.lines) then return false end
   if(line == #b.lines and point >= b.prompt:len()) then return false end
   print("in prompt!", line, point, b.prompt, b.prompt:len(), line2, #b.lines)
   return false -- TODO/blocker: this should return true, but it breaks ssh commands
   -- not sure if this covers all the cases
end

local edit_disallowed = function(line, point, line2, _point2)
   if(inhibit_read_only) then return false end
   return b.read_only or in_prompt(line, point, line2, _point2)
end

local insert = function(text, point_to_end)
   if(edit_disallowed(b.point_line, b.point + 1)) then return end
   b.dirty, b.needs_save = true, true
   text = lume.map(text, function(s) return s:gsub("\t", "  ") end)
   if(not text or #text == 0) then return end
   local this_line = b.lines[b.point_line]
   local before, after = this_line:sub(0, b.point), this_line:sub(b.point + 1)
   local first_line = text[1]

   if(#text == 1) then
      b.lines[b.point_line] = (before or "") .. (first_line or "") .. (after or "")
      if(point_to_end) then
         b.point = before:len() + first_line:len()
      end
   else
      b.lines[b.point_line] = (before or "") .. (first_line or "")
      for i,l in ipairs(text) do
         if(i > 1 and i < #text) then
            table.insert(b.lines, i+b.point_line-1, l)
         end
      end
      table.insert(b.lines, b.point_line+#text-1, text[#text] .. (after or ""))
      if(point_to_end) then
         b.point = #text[#text]
         b.point_line = b.point_line+#text-1
      end
   end
end

local delete = function(start_line, start, finish_line, finish)
   start_line, finish_line = math.min(start_line, finish_line), math.max(start_line, finish_line)
   start, finish = math.min(start, finish), math.max(start, finish)
   if(edit_disallowed(start_line, start, finish_line, finish)) then return end

   b.dirty, b.needs_save = true, true
   if(start_line == finish_line) then
      local line = b.lines[b.point_line]
      b.lines[b.point_line] = line:sub(0, start) .. line:sub(finish + 1)
   else
      local after = b.lines[finish_line]:sub(finish+1, -1)
      for i = finish_line, start_line + 1, -1 do
         table.remove(b.lines, i)
      end
      b.lines[start_line] = b.lines[start_line]:sub(0, start) .. after
   end
   b.point, b.point_line, b.mark, b.mark_line = start, start_line, start, start_line
end

local push = function(ring, item, max)
   table.insert(ring, item)
   if(#ring > max) then table.remove(ring, 1) end
end

local yank = function()
   local text = kill_ring[#kill_ring]
   if(text) then
      b.last_yank = {b.point_line, b.point,
                     b.point_line + #text - 1, string.len(text[#text])}
      insert(text, true)
   end
end

local beginning_of_buffer = function()
   return b.point == 0 and b.point_line == 1
end

local end_of_buffer = function()
   return b.point == #b.lines[b.point_line] and b.point_line == #b.lines
end

local forward_word = function()
   if(end_of_buffer()) then return end
   local remainder = b.lines[b.point_line]:sub(b.point + 1, -1)
   if(not remainder:find("%S")) then
      b.point, b.point_line = 0, b.point_line+1
   end
   local _, match = b.lines[b.point_line]:find(word_break, b.point + 2)
   b.point = match and match - 1 or #b.lines[b.point_line]
end

local backward_word = function()
   if(beginning_of_buffer()) then return end
   local before = b.lines[b.point_line]:sub(0, b.point)
   if(not before:find("%S")) then
      b.point_line = b.point_line - 1
      b.point = #b.lines[b.point_line]
   end
   local back_line = b.lines[b.point_line]:sub(0, math.max(b.point - 1, 0)):reverse()
   if(back_line and back_line:find(word_break)) then
      local _, match = back_line:find(word_break)
      b.point = string.len(back_line) - match + 1
   else
      b.point = 0
   end
end

local forward_char = function(n) -- lameness: n must be 1 or -1
   n = n or 1
   if((end_of_buffer() and n > 0) or
      beginning_of_buffer() and n < 0) then return
   elseif(b.point == #b.lines[b.point_line] and n > 0) then
      b.point, b.point_line = 0, b.point_line+1
   elseif(b.point == 0 and n < 0) then
      b.point = #b.lines[b.point_line-1]
      b.point_line = b.point_line-1
   else
      b.point = b.point + n
   end
end

local save = function(this_fs, this_path)
   local target = this_fs or b.fs
   if(target) then
      local parts = lume.split(this_path or b.path, ".")
      local filename = table.remove(parts, #parts)
      for _,part in ipairs(parts) do
         target = target[part]
      end
      target[filename] = table.concat(b.lines, "\n")
      b.needs_save = false
   end
end

local newline = function(n)
   for _ = 1, (n or 1) do insert({"", ""}, true) end
end

local get_buffer = function(path)
   return lume.match(buffers, function(bu) return bu.path == path end)
end

local save_excursion = function(f) -- TODO: discards multiple values from f
   local old_b, p, pl, m, ml = b, b and b.point, b and b.point_line, b and b.mark, b and b.mark_line
   local val, err = pcall(f)
   b = old_b
   if(b) then
      b.point, b.point_line, b.mark, b.mark_line = p, pl, m, ml
   end
   if(not val) then error(err) end
   return val
end

-- write to the current point in the current buffer
local write = function(...)
   local lines = lume.split(table.concat({...}, " "), "\n")
   local read_only = inhibit_read_only
   inhibit_read_only = true
   insert(lines, true)
   inhibit_read_only = read_only
   return lume.last(lines), #lines
end

-- write to the end of the console buffer right before the prompt
local io_write = function(...)
   local prev_b = b
   b = console
   local line_count = nil
   local old_point, old_point_line = b.point, b.point_line
   b.point, b.point_line = #b.lines[#b.lines - 1], #b.lines - 1
   last_line, line_count = write(...)
   b, b.point, b.point_line = prev_b, old_point + last_line:len(), old_point_line + line_count - 1
end

return {
   initialize = function()
      ROW_HEIGHT = love.graphics.getFont():getHeight()
      em = love.graphics.getFont():getWidth('a')
   end,

   open = function(fs, path)
      b = get_buffer(path)
      if(not b) then
         b = make_buffer(fs, path)
         table.insert(buffers, b)
      end
   end,

   close = function(confirm)
      if(b.prevent_close) then return end
      if(b.needs_save and not confirm) then
         print("Save or call close(true) to confirm closing without saving.")
      else
         lume.remove(buffers, b)
         b = buffers[1]
      end
   end,

   revert = function()
      b.lines = lume.split(b.fs:find(b.path), "\n")
   end,

   save = save,

   -- edit commands
   delete_backwards = function()
      if(beginning_of_buffer()) then return end
      local line, point = b.point_line, b.point
      local line2, point2
      save_excursion(function()
            forward_char(-1)
            line2, point2 = b.point_line, b.point
      end)
      delete(line2, point2, line, point)
   end,

   delete_forwards = function()
      if(end_of_buffer()) then return end
      local line, point = b.point_line, b.point
      local line2, point2
      save_excursion(function()
            forward_char()
            line2, point2 = b.point_line, b.point
      end)
      delete(line, point, line2, point2)
   end,

   kill_line = function()
      delete(b.point_line, b.point, b.point_line, #b.lines[b.point_line])
   end,

   beginning_of_line = function()
      b.point = 0
   end,

   end_of_line = function()
      b.point = #b.lines[b.point_line]
   end,

   prev_line = function()
      if(b.point_line > 1) then b.point_line = b.point_line - 1 end
   end,

   next_line = function()
      if(b.point_line < #b.lines) then b.point_line = b.point_line + 1 end
   end,

   scroll_up = function()
      b.point_line = math.max(0, b.point_line - scroll_size)
   end,

   scroll_down = function()
      b.point_line = math.min(#b.lines, b.point_line + scroll_size)
   end,

   forward_char = forward_char,
   backward_char = lume.fn(forward_char, -1),
   forward_word = forward_word,
   backward_word = backward_word,

   backward_kill_word = function()
      local original_point_line, original_point = b.point_line, b.point
      backward_word()
      delete(b.point_line, b.point, original_point_line, original_point)
   end,

   forward_kill_word = function()
      local original_point_line, original_point = b.point_line, b.point
      forward_word()
      delete(original_point_line, original_point, b.point_line, b.point)
   end,

   beginning_of_buffer = function()
      b.point, b.point_line = 0, 1
      return b.point, b.point_line
   end,

   end_of_buffer = function()
      b.point, b.point_line = #b.lines[#b.lines], #b.lines
      return b.point, b.point_line
   end,

   newline = newline,

   newline_and_indent = function()
      local indentation = (b.lines[b.point_line]:match("^ +") or ""):len()
      newline()
      local existing_indentation = (b.lines[b.point_line]:match("^ +") or ""):len()
      insert({string.rep(" ", indentation - existing_indentation)})
      b.point = b.point + indentation
   end,

   mark = function()
      push(b.mark_ring, {b.point, b.point_line}, mark_ring_max)
      b.mark, b.mark_line = b.point, b.point_line
   end,

   jump_to_mark = function()
      b.point, b.point_line = b.mark or b.point, b.mark_line or b.point_line
      if(#b.mark_ring > 0) then
         table.insert(b.mark_ring, 1, table.remove(b.mark_ring))
         b.mark, b.mark_line = unpack(b.mark_ring[1])
      end
   end,

   no_mark = function()
      b.mark, b.mark_line = nil, nil
   end,

   kill_ring_save = function()
      if(b.mark == nil or b.mark_line == nil) then return end
      push(kill_ring, region(), kill_ring_max)
   end,

   kill_region = function()
      if(b.mark == nil or b.mark_line == nil) then return end
      local _, start_line, start, finish_line, finish = region()
      push(kill_ring, region(), kill_ring_max)
      delete(start_line, start, finish_line, finish)
   end,

   yank = yank,

   yank_pop = function()
      table.insert(kill_ring, 1, table.remove(kill_ring))
      local ly_line1, ly_point1, ly_line2, ly_point2 = unpack(b.last_yank)
      delete(ly_line1, ly_point1, ly_line2, ly_point2)
      yank()
   end,

   print_kill_ring = function()
      print("Ring:")
      for i,l in ipairs(kill_ring) do
         print(i, lume.serialize(l))
      end
   end,

   eval_buffer = function()
      assert(b.fs and b.fs.load, "No loading context available.")
      b.fs:load(b.path)
   end,

   undo = undo,

   -- internal functions
   draw = function()
      if(not b) then
         if(console.lines[#console.lines] == console.prompt) then
            love.graphics.print(last_line, PADDING,
                                love.graphics:getHeight() - ROW_HEIGHT * 2)
         else
            love.graphics.print(console.lines[#console.lines], PADDING,
                                love.graphics:getHeight() - ROW_HEIGHT * 2)
         end
         return
      end

      local width, height = love.graphics:getWidth(), love.graphics:getHeight()
      DISPLAY_ROWS = math.floor((height - (ROW_HEIGHT * 2)) / ROW_HEIGHT)

      -- enforce consistency
      if(b.point_line < 1) then b.point_line = 1 end
      if(b.point_line > #b.lines) then b.point_line = #b.lines end
      if(b.point < 0) then b.point = 0 end
      if(b.point > string.len(b.lines[b.point_line])) then
         b.point = string.len(b.lines[b.point_line]) end

      -- Draw background
      love.graphics.setColor(0, 0, 0, 170)
      love.graphics.rectangle("fill", 0, 0, width, height)

      -- maximum characters in a rendered line of text
      local render_line = function(ln2, y)
         if(ln2 == "\f\n" or ln2 == "\f") then
            love.graphics.line(PADDING, y + 0.5 * ROW_HEIGHT,
                               width - PADDING, y + 0.5 * ROW_HEIGHT)
         else
            love.graphics.print(ln2, PADDING, y)
         end
      end

      local edge = math.ceil(DISPLAY_ROWS * SCROLL_POINT)

      if(b.minibuffer) then
         mb, b = b, buffers[1]
      end

      local offset = (b.point_line < edge and 0) or (b.point_line - edge)
      for i,line in ipairs(b.lines) do
         if(i >= offset) then
            local y = ROW_HEIGHT * (i - offset)
            if(y >= height - ROW_HEIGHT) then break end
            -- elseif(y > height) then break end
            -- mark
            if(i == b.mark_line) then
               love.graphics.setColor(0, 125, 0)
               love.graphics.rectangle("line", PADDING+b.mark*em, y,
                                       em, ROW_HEIGHT)
            end
            if(i == b.point_line) then
               -- point_line line
               love.graphics.setColor(0, 50, 0, 150)
               love.graphics.rectangle("fill", 0, y, width, ROW_HEIGHT)
               -- point
               if(not mb) then
                  love.graphics.setColor(0, 125, 0)
                  love.graphics.rectangle("fill", PADDING+b.point*em, y,
                                          em, ROW_HEIGHT)
               end
            end
            love.graphics.setColor(0, 200, 0)
            render_line(line, y)
         end
      end

      love.graphics.setColor(0, 200, 0, 150)
      love.graphics.rectangle("fill", 0, height - ROW_HEIGHT, width, ROW_HEIGHT)
      love.graphics.setColor(0, 0, 0)
      if(mb) then
         love.graphics.print(mb.lines[1], PADDING, height - ROW_HEIGHT)
         love.graphics.setColor(0, 225, 0)
         love.graphics.rectangle("fill", PADDING+mb.point*em,
                                 height - ROW_HEIGHT, em, ROW_HEIGHT)
      else
         love.graphics.print(b:modeline(), PADDING, height - ROW_HEIGHT)
      end

      -- draw scroll bar

      -- this only gives you an estimate since it uses the amount of
      -- lines entered rather than the lines drawn, but close enough

      -- height is percentage of the possible lines
      local bar_height = math.min(100, (DISPLAY_ROWS * 100) / #b.lines)
      -- convert to pixels (percentage of screen height, minus 10px padding)
      local bar_height_pixels = (bar_height * (height - 10)) / 100

      local sx = width - 5
      -- Handle the case where there are less actual lines than display rows
      if bar_height_pixels >= height - 10 then
         love.graphics.line(sx, 5, sx, height - 5)
      else
         -- now determine location on the screen by taking the offset in
         -- history and converting it first to a percentage of total
         -- lines and then a pixel offset on the screen
         local bar_end = (b.point_line * 100) / #b.lines
         bar_end = ((height - 10) * bar_end) / 100

         local bar_begin = bar_end - bar_height_pixels
         -- Handle overflows
         if bar_begin < 5 then
            love.graphics.line(sx, 5, sx, bar_height_pixels)
         elseif bar_end > height - 5 then
            love.graphics.line(sx, height - 5 - bar_height_pixels, sx, height - 5)
         else
            love.graphics.line(sx, bar_begin, sx, bar_end)
         end
      end
      if(mb) then b, mb = mb, nil end
   end,

   textinput = function(t)
      wrap(function() insert({t}, true) end)
   end,

   activate_minibuffer = function(prompt, callback, exit_callback)
      -- TODO/blocker: prevent "o" from being inserted here
      last_buffer, b = b, make_buffer(nil, nil, {prompt})
      b.mode = "minibuffer"
      b.minibuffer, b.prompt = true, prompt
      b.callback, b.exit_callback = callback, exit_callback
      b.point = #prompt
   end,

   exit_minibuffer = function(cancel)
      local minibuffer = b
      b, mb = last_buffer, nil
      if(not cancel) then
         minibuffer.callback(string.sub(minibuffer.lines[1],
                                        #minibuffer.prompt + 1))
      end
   end,

   next_buffer = function(n)
      local current = lume.find(buffers, b) - 1
      if(current + (n or 1) < 0) then current = current + #buffers end
      b = buffers[math.mod(current + (n or 1), #buffers) + 1]
   end,

   change_buffer = function(path)
      b = get_buffer(path)
   end,

   insert = insert,
   region = region,
   delete = delete,

   wrap = wrap,
   end_hook = save,
   name = "edit",

   current_mode_name = function() return b and b.mode end,

   -- normally you would use ship.api.activate_mode; this is lower-level
   set_mode = function(mode_name) b.mode = mode_name end,

   current_buffer = function() return b end,

   print = function(...)
      local texts, read_only = {...}, inhibit_read_only
      inhibit_read_only = true
      if(texts[1] == invisible) then return end
      texts[1] = "\n" .. texts[1]
      io_write(unpack(lume.map(texts, tostring)))
      inhibit_read_only = read_only
   end,

   raw_write = write,
   write = io_write,

   get_line = function(n)
      if(not b) then return end
      if(n < 1) then n = #b.lines - n end
      return b.lines[n]
   end,

   get_line_number = function() return b.point_line end,

   get_max_lines = function() return b and #b.lines end,

   point = function() return b.point, b.point_line end,

   is_dirty = function() return b and b.dirty end,

   invisible = invisible,

   suppress_read_only = function(f, ...)
      local read_only = inhibit_read_only
      inhibit_read_only = true
      local val = f(...)
      inhibit_read_only = read_only
      return val
   end,

   set_read_only = function(s) b.read_only = s end,

   save_excursion = save_excursion,

   prompt = function() return (b and b.prompt) or "> " end,
   set_prompt = function(p)
      local line = b.lines[#b.lines]
      b.lines[#b.lines] = p .. line:gsub(b.prompt, "", 1)
      if(b.point_line == #b.lines) then b.point = p:len() end
      b.prompt = p
   end,
   print_prompt = function()
      local read_only = inhibit_read_only
      inhibit_read_only = true
      with_current_buffer(console, function()
                             write(b.prompt)
                             b.point, b.point_line = #b.lines[#b.lines], #b.lines
      end)
      inhibit_read_only = read_only
   end,

   debug = function()
      print("---------------", b.point_line, b.point)
      for _,line in ipairs(b.lines) do
         print(line)
      end
      print("---------------")
   end,
}