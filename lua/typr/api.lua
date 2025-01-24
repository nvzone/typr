local M = {}
local volt = require("volt")
local state = require("typr.state")
local utils = require("typr.utils")

M.toggle_symbols = function()
	state.config.symbols = not state.config.symbols
	volt.redraw(state.buf, "headerbtns")
	utils.gen_default_lines()
	volt.redraw(state.buf, "words")
end

M.toggle_numbers = function()
	state.config.numbers = not state.config.numbers
	volt.redraw(state.buf, "headerbtns")
	utils.gen_default_lines()
	volt.redraw(state.buf, "words")
end

M.toggle_random = function()
	state.config.random = not state.config.random
	volt.redraw(state.buf, "headerbtns")
	utils.gen_default_lines()
	volt.redraw(state.buf, "words")
end

M.toggle_language = function()
	state.config.language = state.config.language == "en" and "pt-br" or "en"
	volt.redraw(state.buf, "headerbtns")
	utils.gen_default_lines()
	volt.redraw(state.buf, "words")
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
	if state.stats.wpm == 0 then
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
