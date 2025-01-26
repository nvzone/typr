local state = require "typr.state"
local map = vim.keymap.set
local api = vim.api
local myapi = require "typr.api"

return function()
  map("n", "i", function()
    api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })
    vim.cmd.startinsert()
  end, { buffer = state.buf })

  map("n", "<C-r>", function()
    api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })
    myapi.restart()
  end, { buffer = state.buf })

  map("n", "s", myapi.toggle_symbols, { buffer = state.buf })
  map("n", "n", myapi.toggle_numbers, { buffer = state.buf })
  map("n", "r", myapi.toggle_random, { buffer = state.buf })
  map("n", "p", myapi.toggle_phrases, { buffer = state.buf })

  for _, v in ipairs { 3, 6, 9 } do
    map("n", tostring(v), function()
      myapi.set_linecount(v)
    end, { buffer = state.buf })
  end

  map("n", "o", "", { buffer = state.buf })
  map("i", "<cr>", "", { buffer = state.buf })

  if state.config.mappings then
    state.config.mappings(state.buf)
  end
end
