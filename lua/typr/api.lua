local M = {}
local volt = require "volt"
local state = require "typr.state"
local utils = require "typr.utils"
local CONSTANTS = require "typr.constants.consts"

local function redraw_all()
  local previous_line_count = state.line_count
  utils.gen_lines()
  local line_count_diff = state.line_count - previous_line_count
  state.h = state.h + line_count_diff
  utils.set_emptylines()
  vim.api.nvim_win_set_height(state.win, state.h)

  require("typr").initialize_volt()

  volt.redraw(state.buf, "all")
end

M.toggle_symbols = function()
  local config = state.config.mode_config.words
  config.symbols = not config.symbols
  volt.redraw(state.buf, "headerbtns")
  utils.gen_lines()
  volt.redraw(state.buf, "words")
end

M.toggle_numbers = function()
  local config = state.config.mode_config.words
  config.numbers = not config.numbers
  volt.redraw(state.buf, "headerbtns")
  utils.gen_lines()
  volt.redraw(state.buf, "words")
end

M.toggle_random = function()
  local config = state.config.mode_config.words
  config.random = not config.random
  volt.redraw(state.buf, "headerbtns")
  utils.gen_lines()
  volt.redraw(state.buf, "words")
end

M.set_linecount = function(new_line_count)
  local config = state.config.mode_config.words
  config.line_count = new_line_count
  redraw_all()
end

M.refresh = function()
  redraw_all()
end

M.reset = function()
  -- This is to remove the added
  -- height added by the results,
  -- if it has appeared
  if state.stats.wpm ~= 0 then
    state.h = state.h - 2
  end

  state.reset_vars()
  redraw_all()
end

M.restart = function()
  if state.stats.wpm == 0 then
    return
  end

  M.reset()
end

M.change_mode = function(new_mode)
  local current_mode = state.config.mode

  local function callback(mode)
    if mode == current_mode then
      return
    end

    state.config.mode = mode

    M.reset()

    require "typr.mappings"()
  end

  callback(new_mode)
end

M.cycle_mode = function()
  local current_mode = state.config.mode
  local index = 0
  local mode_index = index
  for _, mode in ipairs(CONSTANTS.MODES) do
    if mode == current_mode then
      mode_index = index
      break
    end

    index = index + 1
  end

  local new_mode_index = math.fmod(mode_index + 1, #CONSTANTS.MODES) + 1
  local new_mode = CONSTANTS.MODES[new_mode_index]

  M.change_mode(new_mode)
end

return M
