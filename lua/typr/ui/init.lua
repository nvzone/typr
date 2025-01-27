local M = {}
local state = require "typr.state"
local voltui = require "volt.ui"

M.words = function()
  return state.ui_lines
end

M.headerbtns = function()
  local config = state.config

  local line = {
    { "  Symbols ", config.symbols and "exgreen" or "normal" },
    { "   Numbers ", config.numbers and "exgreen" or "normal" },
    { "   Random ", config.random and "exgreen" or "normal" },
    { "   Phrases ", config.mode == 'phrases' and "exgreen" or "normal" },
    { "_pad_" },
    { "Lines ", "exred" },
    { " 3 *", state.linecount == 3 and "" or "commentfg" },
    { " 6 *", state.linecount == 6 and "" or "commentfg" },
    { " 9", state.linecount == 9 and "" or "commentfg" },
  }

  local lines = { voltui.hpad(line, state.w + 1) }
  voltui.border(lines)
  return lines
end

M.stats = function()
  local stats = state.stats

  if state.secs == 0 then
    return { {}, {} }
  end

  if stats.rawpm == 0 then
    return {
      { { string.rep(" ", (state.w_with_pad / 2) - 3) }, { "  " .. state.secs .. "s  " } },
    }
  end

  local txts = {
    { "Results:", "Added" },
    { "  Words : " .. stats.correct_word_ratio },
    { "    Accuracy: " .. stats.accuracy .. "%" },
    { "_pad_" },
    { "    " .. state.secs .. "s  " },
    { " WPM ", "pmenusel" },
    { " " .. stats.wpm .. " ", "visual" },
  }

  local totalstrlen = 0

  for _, v in ipairs(txts) do
    totalstrlen = totalstrlen + vim.api.nvim_strwidth(v[1])
  end

  local lines = { voltui.hpad(txts, state.w + 1) }
  voltui.border(lines)
  table.insert(lines, {})
  return lines
end

M.mappings = function()
  return {
    {
      { " ESC ", "visual" },
      { " or ", "commentfg" },
      { " q ", "visual" },
      { " - Quit ", "commentfg" },

      { "  " },

      { " i ", "visual" },
      { " - Start ", "commentfg" },

      { "                   " },

      { " CTRL ", "visual" },
      { " " },
      { " R ", "visual" },
      { " - Restart ", "commentfg" },
    },
  }
end

return M
