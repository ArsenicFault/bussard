-- Emacs keys -*- lua -*-
local editor = require("polywell")
local lume = require("polywell.lume")

editor.bind("edit", "ctrl-h", editor.delete_backwards)
editor.bind("edit", "ctrl-d", editor.delete_forwards)
editor.bind("edit", "ctrl-k", editor.kill_line)
editor.bind("edit", "ctrl-a", editor.beginning_of_line)
editor.bind("edit", "ctrl-e", editor.end_of_line)
editor.bind("edit", "ctrl-b", editor.backward_char)
editor.bind("edit", "ctrl-f", editor.forward_char)
editor.bind("edit", "alt-f", editor.forward_word)
editor.bind("edit", "alt-b", editor.backward_word)
editor.bind("edit", "ctrl-p", editor.prev_line)
editor.bind("edit", "ctrl-n", editor.next_line)
editor.bind("edit", "alt-,", editor.beginning_of_buffer)
editor.bind("edit", "alt-.", editor.end_of_buffer)
editor.bind("edit", "alt-<", editor.beginning_of_buffer)
editor.bind("edit", "alt->", editor.end_of_buffer)
editor.bind("edit", "alt-v", editor.scroll_up)
editor.bind("edit", "ctrl-v", editor.scroll_down)

editor.bind("edit", "ctrl- ", editor.mark)
editor.bind("edit", "ctrl-space", editor.mark)
editor.bind("edit", "ctrl-g", editor.no_mark)
editor.bind("edit", "alt-w", editor.kill_ring_save)
editor.bind("edit", "ctrl-w", editor.kill_region)
editor.bind("edit", "ctrl-y", editor.yank)
editor.bind("edit", "alt-y", editor.yank_pop)

editor.bind("edit", "ctrl-backspace", editor.backward_kill_word)
editor.bind("edit", "alt-d", editor.forward_kill_word)
editor.bind("edit", "ctrl-alt-r", editor.reload)

editor.bind("edit", "ctrl-s", editor.search)
editor.bind("edit", "ctrl-r", lume.fn(editor.search, -1))
editor.bind("edit", "alt-5", editor.replace)

editor.bind("edit", "ctrl-x ctrl-f", editor.find_file)
editor.bind("edit", "ctrl-x b", editor.switch_buffer)
editor.bind("edit", "ctrl-x ctrl-s", editor.save)
editor.bind("edit", "ctrl-x k", editor.close)
editor.bind("edit", "ctrl-x ctrl-c", function() editor.save() os.exit() end)

editor.bind("edit", "ctrl-x 1", editor.split)
editor.bind("edit", "ctrl-x 2", lume.fn(editor.split, "vertical"))
editor.bind("edit", "ctrl-x 3", lume.fn(editor.split, "horizontal"))
editor.bind("edit", "ctrl-x 4", lume.fn(editor.split, "triple"))
editor.bind("edit", "ctrl-x o", editor.focus_next)
