local M = {}
local volt = require "volt"
local state = require "typr.state"
local utils = require "typr.utils"

M.redraw_words_header = function(mode)
  state.config.mode = mode or "words"
  volt.redraw(state.buf, "headerbtns")
  utils.gen_default_lines()
  volt.redraw(state.buf, "words")
end

M.toggle_symbols = function()
  state.config.symbols = not state.config.symbols
  M.redraw_words_header()
end

M.toggle_numbers = function()
  state.config.numbers = not state.config.numbers
  M.redraw_words_header()
end

M.toggle_random = function()
  state.config.random = not state.config.random
  M.redraw_words_header()
end

M.toggle_phrases = function()
  state.config.mode = state.config.mode == "phrases" and "words" or "phrases"

  if state.config.mode == "phrases" then
    state.config.numbers = false
    state.config.symbols = false
    state.config.random = false
  end

  M.redraw_words_header(state.config.mode)
end

M.set_linecount = function(x)
  local diff = x - state.linecount
  state.linecount = x
  state.h = state.h + diff
  utils.gen_default_lines()
  utils.set_emptylines()
  vim.api.nvim_win_set_height(state.win, state.h)

  require("typr").initialize_volt()

  volt.redraw(state.buf, "all")
end

M.restart = function()
  if state.stats.rawpm == 0 then
    return
  end

  state.reset_vars()

  state.h = state.h - 2
  vim.api.nvim_win_set_height(state.win, state.h)
  utils.set_emptylines()
  utils.gen_default_lines()
  require("typr").initialize_volt()
  volt.redraw(state.buf, "all")
end

return M
