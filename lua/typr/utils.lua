local M = {}
local state = require "typr.state"
local words = require "typr.constants.words"
local volt = require "volt"

local symbols = {
  "!",
  '"',
  "#",
  "$",
  "%",
  "&",
  "'",
  "(",
  ")",
  "*",
  "+",
  ",",
  "-",
  ".",
  "/",
  ":",
  ";",
  "<",
  "=",
  ">",
  "?",
  "@",
  "[",
  "\\",
  "]",
  "^",
  "_",
  "`",
  "{",
  "|",
  "}",
  "~",
}

local punct_symbolslen = #symbols

local gen_random_word = function()
  local word = ""
  local length = math.random(1, 7)

  for _ = 1, length do
    local randomChar = string.char(math.random(97, 122))
    word = word .. randomChar
  end

  return word
end

M.gen_word = function()
  local word
  local frequency = math.random(1, 4)
  local config = state.config

  if frequency == 4 and state.config.numbers then
    word = tostring(math.random(1, 1000))
  else
    word = config.random and gen_random_word() or words[math.random(1, #words)]
  end

  if state.config.symbols then
    local tmp_i = math.random(0, punct_symbolslen)
    local symbol = tmp_i > 0 and symbols[tmp_i] or ""
    word = word .. symbol
  end

  return word
end

M.words_to_lines = function()
  local lines = {}
  local maxw = state.w_with_pad

  for _ = 1, state.linecount do
    local lineWords = {}
    local lineLength = 0

    while lineLength < maxw do
      local word = M.gen_word()
      if lineLength + #word + 1 > maxw then
        break
      end
      table.insert(lineWords, word)
      lineLength = lineLength + #word + 1 -- +1 for the space
    end

    table.insert(lines, table.concat(lineWords, " "))
  end

  return lines
end

M.gen_default_lines = function()
  state.default_lines = M.words_to_lines()
  local ui_lines = {}

  for _, v in ipairs(state.default_lines) do
    local line = {}
    for word in string.gmatch(v, "%S+") do
      table.insert(line, { word .. " ", "commentfg" })
    end

    table.insert(ui_lines, line)
  end

  state.ui_lines = ui_lines
end

M.gen_lines_diff = function(line, userline)
  local result = {}
  local userlinelen = #userline
  local croppedline = line:sub(1, userlinelen)

  for i = 1, #croppedline do
    local char = line:sub(i, i)
    local expected = userline:sub(i, i)

    local status = char == expected and "Added" or "Removed"

    local resultlen = #result

    if expected ~= char and expected == " " then
      expected = "x"
    end

    if resultlen > 0 and result[resultlen][2] == status then
      result[resultlen][1] = result[resultlen][1] .. expected
    else
      table.insert(result, { expected, status })
    end
  end

  table.insert(result, { line:sub(#userline + 1), "commentfg" })

  return result
end

M.count_correct_words = function()
  local count = 0
  local userlines = {}
  local default_lines = {}
  local unmatched_count = 0

  for _, line in ipairs(state.ui_lines) do
    local strs = ""

    for _, v in ipairs(line) do
      strs = strs .. v[1]
    end

    table.insert(userlines, vim.split(strs, " "))
  end

  for _, line in ipairs(state.default_lines) do
    table.insert(default_lines, vim.split(line, " "))
  end

  for i, line in ipairs(userlines) do
    for j, word in ipairs(line) do
      if default_lines[i][j] == word then
        count = count + 1
      else
        unmatched_count = unmatched_count + 1
      end
    end
  end

  local total_words = count + unmatched_count
  state.stats.correct_word_ratio = count .. " / " .. total_words
  state.stats.word_stats = { all = total_words, wrong = unmatched_count }
  state.stats.wpm = math.floor((count / state.secs) * 60)
  state.stats.rawpm = math.floor((total_words / state.secs) * 60)
end

M.get_accuracy = function()
  local lines = state.ui_lines
  local mystr = ""

  for _, line in ipairs(lines) do
    for _, val in ipairs(line) do
      if val[2] == "Added" then
        mystr = mystr .. val[1]
      end
    end
  end

  local mystrlen = #mystr:gsub("%s+", "")
  local default_words = #table.concat(state.default_lines):gsub("%s+", "")
  local accuracy = (mystrlen / default_words) * 100

  state.stats.accuracy = math.floor(accuracy)
  state.stats.total_char_count = default_words
  state.stats.typed_char_count = mystrlen
end

M.char_accuracy = function()
  local userlines = vim.tbl_map(function(line)
    local userwords = vim.tbl_map(function(v)
      return v[1]
    end, line)

    local userstrs = table.concat(userwords, "")

    return vim.split(userstrs, "")
  end, state.ui_lines)

  local default_lines = vim.tbl_map(function(line)
    return vim.split(line, "")
  end, state.default_lines)

  local wrongchars = {}
  local wrongchars_count = 0
  local totalchars_count = 0
  local rightchars = {}
  local result = {}

  for i, line in ipairs(default_lines) do
    for j, char in ipairs(line) do
      totalchars_count = totalchars_count + 1
      if userlines[i][j] == char then
        rightchars[char] = (rightchars[char] or 0) + 1
      else
        wrongchars[char] = (wrongchars[char] or 0) + 1
        wrongchars_count = wrongchars_count + 1
      end
    end
  end

  state.stats.char_stats = { all = totalchars_count, wrong = wrongchars_count }

  for key, val in pairs(rightchars) do
    local sum = (wrongchars[key] or 0) + val
    result[key] = math.floor((val / sum) * 100)
  end

  state.stats.char_accuracy = result
end

M.char_times_calc = function()
  local t = state.stats.char_times

  local chars = {}
  local pressed = {}

  for _, v in ipairs(t) do
    if v[1] ~= "" and v[1] ~= " " then
      chars[v[1]] = (chars[v[1]] or 0) + v[2]
      pressed[v[1]] = (pressed[v[1]] or 0) + 1
    end
  end

  for k, v in pairs(chars) do
    chars[k] = v / pressed[k]
  end

  state.stats.char_times = chars
end

M.start_timer = function()
  state.timer:start(
    0,
    1000,
    vim.schedule_wrap(function()
      state.secs = state.secs + 1
      volt.redraw(state.buf, "stats")
    end)
  )
end

M.set_emptylines = function()
  local maxline = (state.linecount + state.words_row)
  state.words_row_end = maxline

  local lines = {}

  for i = 1, state.h do
    local str = (i > state.words_row and i <= maxline) and "" or string.rep(" ", state.w_with_pad)
    table.insert(lines, str)
  end

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
end

M.on_finish = function()
  state.timer:stop()
  vim.cmd.stopinsert()

  M.get_accuracy()
  M.count_correct_words()
  M.char_accuracy()

  state.h = state.h + 2
  vim.api.nvim_win_set_height(state.win, state.h)
  M.set_emptylines()

  require("typr").initialize_volt()
  volt.redraw(state.buf, "all")

  M.char_times_calc()

  require("typr.stats.utils").save()
end

return M
