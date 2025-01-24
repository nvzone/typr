local state = require "typr.state"
local map = vim.keymap.set
local api = vim.api
local myapi = require "typr.api"
local utils = require "typr.utils"

return function()
  map("i", "<Space>", function()
    local pos = vim.api.nvim_win_get_cursor(state.win)
    local curline_end = #state.default_lines[pos[1] - state.words_row]

    if pos[2] > curline_end then
      if state.words_row_end == pos[1] then
        utils.on_finish()
        return
      end

      api.nvim_win_set_cursor(state.win, { pos[1] + 1, state.xpad })
    else
      api.nvim_feedkeys(" ", "n", true)
    end
  end, { buffer = state.buf })

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

  map("n", "l", function()
    myapi.toggle_language()
  end, { buffer = state.buf })

  for _, v in ipairs { 3, 6, 9 } do
    map("n", tostring(v), function()
      myapi.set_linecount(v)
    end, { buffer = state.buf })
  end
end
