local state = require "typr.state"
local map = vim.keymap.set
local api = vim.api
local typr_api = require "typr.api"
local utils = require "typr.utils"
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
    map("n", "m", function()
      typr_api.change_dictionary(CONSTANTS.DICTIONARIES.Monkeytype)
    end, { buffer = state.buf })

    map("n", "t", function()
      typr_api.change_dictionary(CONSTANTS.DICTIONARIES.TypeRacer)
    end, { buffer = state.buf })
  end,
}

local function get_data()
  local pos = vim.api.nvim_win_get_cursor(state.win)
  local curline_end = #state.lines[pos[1] - state.words_row]
  return pos, curline_end
end

return function()
  map("i", "<Space>", function()
    local pos, curline_end = get_data()

    if pos[2] >= curline_end then
      if state.words_row_end == pos[1] then
        utils.on_finish()
        return
      end

      api.nvim_win_set_cursor(state.win, { pos[1] + 1, state.xpad })
    else
      api.nvim_feedkeys(" ", "n", true)
    end
  end, { buffer = state.buf })

  map("i", "<Enter>", function()
    local pos, curline_end = get_data()

    if pos[2] >= curline_end and state.words_row_end == pos[1] then
      utils.on_finish()
    end
  end, { buffer = state.buf })

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

  local mode_mapping_func = mode_mappings[state.config.mode]
  mode_mapping_func()

  for _, key in ipairs { "o", "a", "I", "A" } do
    map("n", key, "", { buffer = state.buf })
  end

  if state.config.mappings then
    state.config.mappings(state.buf)
  end
end
