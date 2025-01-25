local M = {}
local state = require "typr.state"
local voltui = require "volt.ui"
local CONSTANTS = require "typr.constants.consts"

M.words = function()
  return state.ui_lines
end

M.headerbtns = function()
  local mode = state.config.mode
  local mode_config = state.config.mode_config

  local header_line_map = {

    [CONSTANTS.MODES.Words] = {
      { "  Symbols ", mode_config.words.symbols and "exgreen" or "normal" },
      { "   Numbers ", mode_config.words.numbers and "exgreen" or "normal" },
      { "   Random ", mode_config.words.random and "exgreen" or "normal" },
      { "_pad_" },
      { "  Lines ", "exred" },
      { " 3 *", mode_config.words.line_count == 3 and "" or "commentfg" },
      { " 6 *", mode_config.words.line_count == 6 and "" or "commentfg" },
      { " 9", mode_config.words.line_count == 9 and "" or "commentfg" },
    },

    [CONSTANTS.MODES.Sentences] = {
      { "  Refresh Sentence", "normal" },
      { "_pad_" },
    },
  }

  local line = header_line_map[mode]

  local lines = { voltui.hpad(line, state.w + 1) }
  voltui.border(lines)

  return lines
end

M.stats = function()
  local stats = state.stats

  if state.secs == 0 then
    return { {}, {} }
  end

  if stats.wpm == 0 then
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

      { "  " },
      { " ENTER ", "visual" },
      { " - Mode", "commentfg" },

      { "  " },

      { " CTRL ", "visual" },
      { " " },
      { " r ", "visual" },
      { " - Restart ", "commentfg" },
    },
  }
end

return M
