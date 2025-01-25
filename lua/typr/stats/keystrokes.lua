local state = require "typr.state"
local config = state.config
local voltui = require "volt.ui"
local kblayouts = require "typr.constants.kblayouts"

local border_chars = {
  mid = { top = "┬", bot = "┴", none = "┼" },
  corners_left = { top = "┌", bot = "└", none = "├" },
  corners_right = { top = "┐", bot = "┘", none = "┤" },
  vline = "│",
}

local keys_accuracy = function()
  local data = state.data.char_accuracy
  local lines = {}
  local line = string.rep("─", (10 * 4) + 1)

  local keys = {}
  for k, v in pairs(data) do
    table.insert(keys, { k, v })
  end

  table.sort(keys, function(a, b)
    return a[2] < b[2]
  end)

  local kblayout = type(config.kblayout) == "table" and config.kblayout or kblayouts[config.kblayout]

  for i, v in ipairs(kblayout) do
    local row = {}

    for _, letter in ipairs(v) do
      local score = data[letter] or 100
      local hl = score == 100 and "TyprGrey" or "TyprRed"

      if score > 90 and score < 100 then
        hl = "TyprYellow"
      end

      table.insert(row, { " " .. letter:upper() .. " ", hl })
      table.insert(row, { " " })
    end

    table.remove(row)

    if i ~= 1 then
      table.insert(lines, { { border_chars.corners_left.none .. line .. border_chars.corners_right.none, "linenr" } })
    end

    table.insert(row, 1, { border_chars.vline .. " ", "linenr" })
    table.insert(row, { " " .. border_chars.vline, "linenr" })
    table.insert(lines, row)

    if i == 1 then
      table.insert(lines, 1, { { border_chars.corners_left.top .. line .. border_chars.corners_right.top, "linenr" } })
    elseif i == 3 then
      table.insert(lines, { { border_chars.corners_left.bot .. line .. border_chars.corners_right.bot, "linenr" } })
    end
  end

  table.insert(lines, 1, { { "   Average of Key Accuracies" } })

  if state.winlayout == "horizontal" then
    table.insert(lines[1], { "  " })

    local virts =
      { { " Ctrl ", "visual" }, { " + ", "comment" }, { " t ", "visual" }, { " Cycle panes ", "commentfg" } }

    for _, v in ipairs(virts) do
      table.insert(lines[1], v)
    end
  end

  local worst_keys = ""
  if #keys >= 3 then
    worst_keys = keys[1][1] .. " " .. keys[2][1] .. " " .. keys[3][1]
  else
    worst_keys = "No Data"
  end

  local indicators = {
    { { "󱓻 ", "commentfg" }, { "100% accuracy!" } },
    { { "󱓻 ", "exyellow" }, { "Less than 90%" } },
    { { "󱓻 ", "exred" }, { "Less than 80%" } },
    { { "" } },
    { { "Top worst keys: ", "exred" }, { worst_keys, "exlightgrey" } },
  }

  voltui.border(indicators, "exred")
  table.insert(indicators, 1, {})

  return voltui.grid_col {
    { lines = lines, w = state.w_with_pad - 32, pad = 1 },
    { lines = indicators, w = 20 },
  }
end

local slice_tb = function(tb, start, stop)
  local result = {}
  local start_i = start > stop and -1 or 1

  for i = start, stop, start_i do
    table.insert(result, tb[i])
  end

  return result
end

local key_word_stats = function(w)
  local words = state.data.word_stats
  local keys = state.data.char_stats
  local wordavg = ((words.all - words.wrong) / words.all) * 100
  local charavg = ((keys.all - keys.wrong) / keys.all) * 100

  local tb = {
    {
      "Total",
      { { "  Correct", "exgreen" } },
      { { "  Wrong", "exred" } },
      "Avg",
    },

    { words.all, words.all - words.wrong, words.wrong, math.floor(wordavg) },
  }

  local wordStats = voltui.table(tb, w, "normal", { "   Overall word stats" })

  local tb2 = {
    {
      "Total",
      { { "  Correct", "exgreen" } },
      { { "  Wrong", "exred" } },
      "Avg",
    },

    { keys.all, keys.all - keys.wrong, keys.wrong, math.floor(charavg) },
  }

  local keyStats = voltui.table(tb2, w, "normal")

  local progressTxt = "  Keystrokes "

  local progressbar = voltui.progressbar {
    w = w - 2 - #progressTxt,
    val = state.data.accuracy,
    hl = { on = "exblue" },
    icon = { on = "|", off = "|" },
  }

  table.insert(progressbar, 1, { progressTxt })

  progressbar = { progressbar }

  voltui.border(progressbar)

  return voltui.grid_row {
    wordStats,
    progressbar,
    keyStats,
  }
end

local char_times = function()
  local char_times = state.data.char_times

  local list = {}

  for k, v in pairs(char_times) do
    v = math.floor(v)
    table.insert(list, { k, v })
  end

  table.sort(list, function(a, b)
    return a[2] > b[2]
  end)

  local tb1 = slice_tb(list, 1, 5)
  table.insert(tb1, 1, { "Key", "Avg" })

  tb1 = vim.tbl_map(function(x)
    return { { { x[1], "exred" } }, x[2] }
  end, tb1)

  local tb2 = slice_tb(list, #list, #list - 4)
  table.insert(tb2, 1, { "Key", "Avg" })

  tb2 = vim.tbl_map(function(x)
    return { { { x[1], "exblue" } }, x[2] }
  end, tb2)

  local slowest_keys_ui = voltui.table(tb1, "fit", "normal", { "Slowest keys" })
  local fastest_keys_ui = voltui.table(tb2, "fit", "normal", { "Fastest keys" })

  local w1 = voltui.line_w(slowest_keys_ui[1])
  local w2 = voltui.line_w(fastest_keys_ui[1])
  local w3 = state.w_with_pad - w1 - w2 - 4

  return voltui.grid_col {
    { lines = slowest_keys_ui, pad = 2, w = w1 },
    { lines = fastest_keys_ui, pad = 2, w = w2 },
    { lines = key_word_stats(w3), w = w3 },
  }
end

local year = os.date "%Y"

local getday_i = function(day, month)
  return tonumber(os.date("%w", os.time { year = tostring(year), month = month, day = day })) + 1
end

local double_digits = function(day)
  return day > 10 and day or "0" .. day
end

local get_activity_hl = function(n)
  if n > 20 then
    return "0"
  elseif n > 10 then
    return "1"
  elseif n > 0 then
    return "2"
  else
    return "3"
  end
end

local activity_heatmap = function()
  local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
  local days_in_months = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  local days = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }

  local four_colors = { "red", "green", "blue", "yellow" }
  local monthshl = vim.list_extend(vim.list_extend(four_colors, four_colors), four_colors)

  local months_i = state.months_toggled and 6 or 1
  local months_end = (months_i + 6)
  local months_to_show = 7
  local squares_len = months_to_show * 4

  local lines = {
    { { "   ", "exgreen" }, { "  " } },
    {},
  }

  for i = months_i, months_end do
    local hl = "ex" .. monthshl[i]
    table.insert(lines[1], { "  " .. months[i] .. "  ", hl })
    table.insert(lines[1], { i == months_end and "" or "  " })
  end

  local hrline = voltui.separator("─", squares_len * 2 + (months_to_show - 1 + 5), "exlightgrey")
  table.insert(lines[2], hrline[1])

  for day = 1, 7 do -- 7 weakdays
    local line = { { days[day], "exlightgrey" }, { " │ ", "linenr" } }
    table.insert(lines, line)
  end

  for i = months_i, months_end do
    local month_i = i

    local start_day = getday_i(1, month_i)
    if start_day ~= 1 and month_i == 1 then
      for n = 1, start_day - 1 do
        table.insert(lines[n + 2], { "  " })
      end
    end

    for n = 1, days_in_months[month_i] do
      local day = getday_i(n, month_i)
      local key = double_digits(n) .. double_digits(month_i) .. year

      local activity = state.data.activity[key] or 0
      local hl = "Typr" .. monthshl[month_i] .. get_activity_hl(activity)
      hl = activity == 0 and "Linenr" or hl

      table.insert(lines[day + 2], { "󱓻" .. " ", hl })
    end
  end

  voltui.border(lines)

  local header = {
    { "   Activity" },
    { "  " },
    { " TAB ", "lazyh1" },
    { " " },
    { "Toggle Months", "commentfg" },
    { "_pad_" },
    { "  Less " },
  }

  local hlgroups = { "linenr", "typrgreen3", "typrgreen2", "typrgreen1", "typrgreen0" }

  for _, v in ipairs(hlgroups) do
    table.insert(header, { "󱓻 ", v })
  end

  table.insert(header, { " More" })
  table.insert(lines, 1, voltui.hpad(header, 80))

  return lines
end

return function()
  return require("volt.ui").grid_row {
    keys_accuracy(),
    { {} },
    char_times(),
    { {} },
    activity_heatmap(),
  }
end
