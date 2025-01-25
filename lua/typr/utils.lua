local M = {}
local state = require "typr.state"
local volt = require "volt"
local CONSTANTS = require "typr.constants.consts"

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
  local config = state.config.mode_config.words
  local words = require("typr.dictionaries." .. state.config.mode)

  if frequency == 4 and state.config.numbers then
    word = tostring(math.random(1, 1000))
  else
    word = config.random and gen_random_word() or words[math.random(1, #words)]
  end

  if config.symbols then
    local tmp_i = math.random(0, punct_symbolslen)
    local symbol = tmp_i > 0 and symbols[tmp_i] or ""
    word = word .. symbol
  end

  return word
end

M.words_to_lines = function()
  local lines = {}
  local line_count = state.config.mode_config.words.line_count
  local maxw = state.w_with_pad

  state.line_count = line_count

  for _ = 1, line_count do
    local line_words = {}
    local line_length = 0

    while line_length < maxw do
      local word = M.gen_word()
      if line_length + #word + 1 > maxw then
        break
      end
      table.insert(line_words, word)
      line_length = line_length + #word + 1 -- +1 for the space
    end

    table.insert(lines, table.concat(line_words, " ") .. " ")
  end

  return lines
end

M.gen_sentence = function()
  local mode = state.config.mode
  local sentences = require("typr.dictionaries." .. mode)
  local sentence = sentences[math.random(1, #sentences)]
  return sentence
end

M.sentence_to_lines = function()
  local lines = {}
  local maxw = state.w_with_pad

  local sentence = M.gen_sentence()
  local line_words = {}
  local line_length = 0

  for _, word in ipairs(vim.split(sentence, "%s", { trimempty = true })) do
    if line_length + #word + 1 >= maxw then
      table.insert(lines, table.concat(line_words, " ") .. " ")
      line_words = {}
      line_length = 0
    end

    table.insert(line_words, word)
    line_length = line_length + #word + 1 -- +1 for the space
  end

  if #line_words > 0 then
    table.insert(lines, table.concat(line_words, " "))
  end

  state.line_count = #lines

  return lines
end

M.gen_lines = function()
  local line_gen_mapping = {
    [CONSTANTS.MODES.Words] = M.words_to_lines,
    [CONSTANTS.MODES.Sentences] = M.sentence_to_lines,
  }

  local line_generator = line_gen_mapping[state.config.mode]
  local lines = line_generator()
  local last_line = lines[#lines]
  lines[#lines] = vim.trim(last_line)
  state.lines = lines

  local ui_lines = {}

  for _, v in ipairs(state.lines) do
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

  for _, line in ipairs(state.lines) do
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
  local default_words = #table.concat(state.lines):gsub("%s+", "")
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
  end, state.lines)

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
  local maxline = (state.line_count + state.words_row)
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

  state.h = state.h + 2
  vim.api.nvim_win_set_height(state.win, state.h)

  vim.schedule(function()
    M.get_accuracy()
    M.count_correct_words()
    M.char_accuracy()
    M.char_times_calc()

    M.set_emptylines()
    require("typr").initialize_volt()
    volt.redraw(state.buf, "all")

    require("typr.stats.utils").save()
  end)
end

M.handle_test_end = function()
  local pos = vim.api.nvim_win_get_cursor(state.win)
  local curline_endcol = #state.lines[pos[1] - state.words_row]
  local cur_col = pos[2] - 1

  if cur_col == curline_endcol then
    if state.words_row_end == pos[1] then
      M.on_finish()
      return
    end

    vim.schedule(function()
      vim.api.nvim_win_set_cursor(state.win, { pos[1] + 1, state.xpad })
    end)
  end
end

return M
