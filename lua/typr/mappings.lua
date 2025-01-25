local state = require "typr.state"
local map = vim.keymap.set
local api = vim.api
local typr_api = require "typr.api"
local CONSTANTS = require "typr.constants.consts"

local mode_mappings = {

  [CONSTANTS.MODES.Words] = function()
    map("n", "s", typr_api.toggle_symbols, { buffer = state.buf })
    map("n", "n", typr_api.toggle_numbers, { buffer = state.buf })
    map("n", "r", typr_api.toggle_random, { buffer = state.buf })

    for _, v in ipairs { 3, 6, 9 } do
      map("n", tostring(v), function()
        typr_api.set_linecount(v)
      end, { buffer = state.buf })
    end
  end,

  [CONSTANTS.MODES.Sentences] = function()
    map("n", "r", typr_api.refresh, { buffer = state.buf })
  end,
}

return function()
  local disabled_keys = {
    n = { "o", "a", "d", "x", "I", "A" },
    i = { "<Enter>", "<Del>" },
  }

  for mode, keys in pairs(disabled_keys) do
    for _, key in ipairs(keys) do
      map(mode, key, "", { buffer = state.buf })
    end
  end

  map("n", "i", function()
    api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })
    vim.cmd.startinsert()
  end, { buffer = state.buf })

  map("n", "<Enter>", function()
    api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })
    typr_api.cycle_mode()
  end, { buffer = state.buf })

  map("n", "<C-r>", function()
    api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })
    typr_api.restart()
  end, { buffer = state.buf })

  map("i", "<BS>", function()
    if state.config.no_backspace then
      return
    end

    local _, column = unpack(vim.api.nvim_win_get_cursor(state.win))
    if column <= state.xpad then
      return
    end

    local backspace = vim.api.nvim_replace_termcodes("<BS>", true, false, true)
    vim.api.nvim_feedkeys(backspace, "n", false)
  end, { buffer = state.buf })

  local mode_mapping_func = mode_mappings[state.config.mode]
  mode_mapping_func()

  if state.config.mappings then
    state.config.mappings(state.buf)
  end
end
