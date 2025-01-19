local ui = require "typr.stats.ui"
local volt_ui = require "volt.ui"
local state = require "typr.state"

local empty_line = {
  lines = function()
    return { {} }
  end,
  name = "emptyline",
}

local dashboard = function()
  return volt_ui.grid_row {
    ui.progress(),
    { {} },
    ui.tabular_stats(),
    { {} },
    ui.graph(),
    { {} },
    ui.rawpm(),
    { {} },
  }
end

local keystrokes = function()
  return volt_ui.grid_row {
    ui.keys_accuracy(),
    { {} },
    ui.char_times(),
    { {} },
    ui.activity_heatmap(),
  }
end

local components = {
  ["  Dashboard"] = dashboard,
  Keystrokes = keystrokes,
  ["  History"] = keystrokes,
}

return {
  { lines = ui.tabs, name = "tabs" },

  empty_line,

  {
    lines = function()
      return components[state.tab]()
    end,
    name = "typrStats",
  },
}
