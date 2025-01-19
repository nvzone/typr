local M = {}
local state = require "typr.state"
local config = state.config
local voltui = require "volt.ui"
local stats = require "typr.stats.state"
local kblayouts = require "typr.constants.kblayouts"

local tmp_stats = {
  times = 5,
  total_secs = 3001,

  wpm = {
    avg = 70,
    max = 120,
  },

  accuracy = 60,
}

local function secsTodhm(secs)
  local days = math.floor(secs / 86400)
  local hours = math.floor((secs % 86400) / 3600)
  local minutes = math.floor((secs % 3600) / 60)
  return string.format("%02d:%02d:%02d", days, hours, minutes)
end

local function get_lvlstats(my_secs, wpm_ratio)
  local level = math.floor(my_secs / 1000)
  local next_lvl = (level + 1) * 1000
  local next_perc = math.floor(((my_secs + wpm_ratio) / next_lvl) * 100)

  return {
    val = level,
    next_perc = 100 - next_perc,
  }
end

M.tabs = function()
  local data = { "  Dashboard", "Keystrokes", "_pad_", "  History" }
  return voltui.tabs(data, state.w_with_pad, { active = state.tab})
end

M.progress = function()
  local barlen = state.w_with_pad / 3 - 1
  local wpm_progress = (tmp_stats.wpm.avg / config.wpm_goal) * 100

  local wpm_stats = {
    { { "", "exgreen" }, { "  WPM ~ " }, { tostring(tmp_stats.wpm.avg) .. " / " .. tostring(config.wpm_goal) } },
    {},
    voltui.progressbar {
      w = barlen,
      val = wpm_progress > 100 and 100 or wpm_progress,
      icon = { on = "┃", off = "┃" },
      hl = { on = "exgreen", off = "linenr" },
    },
  }

  local accuracy_stats = {
    { { "", "exred" }, { "  Accuracy ~ " }, { tostring(tmp_stats.accuracy) .. " %" } },
    {},
    voltui.progressbar {
      w = barlen,
      val = tmp_stats.accuracy,
      icon = { on = "┃", off = "┃" },
    },
  }

  local lvl_stats = get_lvlstats(tmp_stats.total_secs, tmp_stats.accuracy)

  local lvl_stats_ui = {
    { { "", "exyellow" }, { "  Level ~ " }, { tostring(lvl_stats.val) } },
    {},
    voltui.progressbar {
      w = barlen,
      val = lvl_stats.next_perc,
      hl = { on = "exyellow" },
      icon = { on = "┃", off = "┃" },
    },
  }

  return voltui.grid_col {
    { lines = wpm_stats, w = barlen, pad = 2 },
    { lines = accuracy_stats, w = barlen, pad = 2 },
    { lines = lvl_stats_ui, w = barlen },
  }
end

M.tabular_stats = function()
  local tb = {
    {
      "  Total time",
      "  Tests",
      "  Lowest",
      "  Highest",
      " RAW WPM",
    },

    {
      secsTodhm(tmp_stats.total_secs),
      "2100",
      "60 WPM",
      "120 WPM",
      "150 WPM",
    },
  }

  return voltui.table(tb, state.w_with_pad)
end

M.graph = function()
  local wpm_graph_data = {
    val = { 60, 20, 80, 70, 30, 10, 30, 50, 20, 40 },
    footer_label = { " Last 10 WPM stats" },

    format_labels = function(x)
      return tostring((x / 100) * 150)
    end,

    baropts = {
      w = 2,
      gap = 1,
      hl = "exgreen",
      dual_hl = { "exlightgrey", "commentfg" },
      -- format_hl = function(x)
      --   return x > 50 and "exred" or "normal"
      -- end,
    },
    w = state.w_with_pad / 2,
  }

  local accuracy_graph_data = {
    val = { 60, 20, 80, 70, 30, 10, 30, 50, 20, 40 },
    w = state.w_with_pad / 2,
    footer_label = { "Last 10 Accuracy stats" },
  }

  return voltui.grid_col {
    { lines = voltui.graphs.bar(wpm_graph_data), w = (state.w_with_pad - 1) / 2, pad = 0 },
    { lines = voltui.graphs.dot(accuracy_graph_data), w = (state.w_with_pad - 1) / 2, pad = 0 },
  }
end

M.rawpm = function()
  local m = { 60, 20, 80, 70, 30, 20, 80, 70, 30, 80, 70, 30, 50 }
  local n = { 60, 20, 80, 70, 30, 20, 80, 70, 30, 80, 70, unpack(m) }

  local wpm_graph_data = {
    val = { 60, 20, 80, 70, 30, 10, 30, 50, 20, 40, unpack(n) },
    footer_label = { " Last 20 RAW WPM stats" },

    format_labels = function(x)
      return tostring((x / 100) * 150)
    end,

    baropts = {
      w = 1,
      gap = 1,
      format_hl = function(x)
        return x > 30 and "exred" or "normal"
      end,
    },
    w = state.w_with_pad / 2,
  }

  return voltui.graphs.bar(wpm_graph_data)
end

local border_chars = {
  mid = { top = "┬", bot = "┴", none = "┼" },
  corners_left = { top = "┌", bot = "└", none = "├" },
  corners_right = { top = "┐", bot = "┘", none = "┤" },
  vline = "│",
}

M.keys_accuracy = function()
  local x = stats.val.char_accuracy
  local lines = {}
  local line = string.rep("─", (10 * 4) + 1)

  for i, v in ipairs(kblayouts[config.kblayout]) do
    local row = {}

    for _, letter in ipairs(v) do
      local score = x[letter] or 100
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

  local indicators = {
    { { "󱓻 ", "commentfg" }, { "100% accuracy!" } },
    { { "󱓻 ", "exyellow" }, { "Less than 90%" } },
    { { "󱓻 ", "exred" }, { "Less than 80%" } },
    { { "" } },
    { { "Inaccurate keys: ", "exred" }, { "a z i", "exlightgrey" } },
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

  local kek = start > stop and -1 or 1

  for i = start, stop, kek do
    table.insert(result, tb[i])
  end

  return result
end

M.emptychad = function(w)
  local words = stats.val.word_stats
  local keys = stats.val.char_stats
  local wordavg = ((words.all - words.wrong) / words.all) * 100
  local charavg = ((keys.all - keys.wrong) / keys.all) * 100

  local tb = {
    {
      "Total",
      { "  Correct", "exgreen" },
      { "  Wrong", "exred" },
      "Avg",
    },

    -- { words.all, words.all - words.wrong, words.wrong, math.floor(wordavg) },
    { 8210, 7130, 1100, 82 },
  }

  local wordStats = voltui.table(tb, w, "normal", { "   Overall word stats" })

  local tb2 = {
    {
      "Total",
      { "  Correct", "exgreen" },
      { "  Wrong", "exred" },
      "Avg",
    },

    { 8210, 7130, 1100, 82 },
    -- { keys.all, keys.all - keys.wrong, keys.wrong, math.floor(charavg) },
  }

  local keyStats = voltui.table(tb2, w, "normal")

  local progressTxt = "  Keystrokes "

  local progressbar = voltui.progressbar {
    w = w - 2 - #progressTxt,
    val = tmp_stats.accuracy,
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

M.char_times = function()
  local char_times = stats.val.char_times
  --
  -- if #char_times == 0 then
  --   char_times = {
  --     a = 0.360408,
  --     b = 0.194506,
  --     c = 0.108318,
  --     d = 0.186247,
  --     e = 0.61095,
  --     g = 0.281173,
  --     h = 0.563126,
  --     i = 0.531408,
  --     k = 0.236884,
  --     l = 0.321144,
  --     m = 0.253785,
  --     n = 0.586682,
  --     o = 0.888713,
  --     r = 0.128862,
  --     s = 0.506386,
  --     t = 0.721127,
  --     u = 0.47689,
  --     v = 0.154953,
  --     w = 0.36646,
  --   }
  -- end

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
    return { { x[1], "exred" }, x[2] }
  end, tb1)

  local tb2 = slice_tb(list, #list, #list - 4)
  table.insert(tb2, 1, { "Key", "Avg" })

  tb2 = vim.tbl_map(function(x)
    return { { x[1], "exblue" }, x[2] }
  end, tb2)

  local slowest_keys_ui = voltui.table(tb1, "fit", "normal", { "Slowest keys" })
  local fastest_keys_ui = voltui.table(tb2, "fit", "normal", { "Fastest keys" })

  local w1 = voltui.line_w(slowest_keys_ui[1])
  local w2 = voltui.line_w(fastest_keys_ui[1])
  local w3 = state.w_with_pad - w1 - w2 - 4

  return voltui.grid_col {
    { lines = slowest_keys_ui, pad = 2, w = w1 },
    { lines = fastest_keys_ui, pad = 2, w = w2 },
    { lines = M.emptychad(w3), pad = 2, w = w3 },
  }
end

M.activity_heatmap = function()
  local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
  local days = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }
  local hlgroups = { "linenr", "typrgreen3", "typrgreen2", "typrgreen1", "typrgreen0" }

  local months_i = state.months_toggled and 6 or 1
  local months_end = (months_i + 6)
  local months_to_show = 7
  local squares_len = months_to_show * 4

  local lines = {
    { { "   ", "exgreen" }, { "  " } },
    {},
  }

  for i = months_i, months_end do
    table.insert(lines[1], { "  " .. months[i] .. "  ", "Visual" })
    table.insert(lines[1], { i == months_end and "" or "  " })
  end

  local hrline = voltui.separator("─", squares_len * 2 + (months_to_show - 1 + 5), "exgreen")
  table.insert(lines[2], hrline[1])

  for day = 1, 7 do -- 7 weakdays
    local line = { { days[day], "exlightgrey" }, { " │ ", "linenr" } }

    for i = 1, squares_len do -- 12 months * 4 weeks
      local hl = hlgroups[math.random(1, #hlgroups)]
      local space = i == squares_len and "" or " "
      table.insert(line, { "󱓻" .. space, hl })

      if i % 4 == 0 then
        table.insert(line, { space })
      end
    end

    table.insert(lines, line)
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

  for _, v in ipairs(hlgroups) do
    table.insert(header, { "󱓻 ", v })
  end

  table.insert(header, { " More" })
  table.insert(lines, 1, voltui.hpad(header, 80))


  return lines
end

return M
