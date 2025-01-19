local state = require "typr.state"
local config = state.config
local voltui = require "volt.ui"

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

local progress = function()
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

local tabular_stats = function()
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

local graph = function()
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

local rawpm = function()
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

return function()
  return require("volt.ui").grid_row {
    progress(),
    { {} },
    tabular_stats(),
    { {} },
    graph(),
    { {} },
    rawpm(),
    { {} },
  }
end
