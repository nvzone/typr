local state = require "typr.state"
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

local tabular_stats = function()
  local dum = {
    "21 s",
    "60",
    "150",
    "99%",
  }

  local tb = {
    {
      "Time",
      "WPM",
      "RAW",
      "Accuracy",
    },
  }

  for i = 1, 16 do
  table.insert(tb, dum)
  end

  local w1 = state.w_with_pad - 30
  local w2 = 30

  local goalTb = {{ "  WPM GOAL ~ 150" }}

  local progressbar = voltui.progressbar {
    w = w2-4,
    val = 60,
    hl = { on = "exblue" },
    icon = { on = "|", off = "|" },
  }

  for _, _ in ipairs(tb) do
    table.insert(goalTb, {progressbar})
  end
  table.remove(goalTb)

  return voltui.grid_col {
    {
      lines = voltui.table(tb, w1),
      w = w1,
      pad = 1,
    },
    {
      lines = voltui.table(goalTb, w2),
      w = w2,
    },
  }
end

return function()
  return require("volt.ui").grid_row {
    { { { "History of last 20 tests" } } },

    tabular_stats(),
  }
end
