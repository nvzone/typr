local dashboard = require "typr.stats.dashboard"
local keystrokes = require "typr.stats.keystrokes"
local voltui = require "volt.ui"
local state = require "typr.state"
local history = require "typr.stats.history"

local empty_line = {
  lines = function()
    return { {} }
  end,
  name = "emptyline",
}

local components = {
  ["  Dashboard"] = dashboard,
  Keystrokes = keystrokes,
  ["  History"] = history,
}

return {
  {
    lines = function()
      local data = { "  Dashboard", "Keystrokes", "_pad_", "  History" }
      return voltui.tabs(data, state.w_with_pad, { active = state.tab })
    end,
    name = "tabs",
  },

  empty_line,

  {
    lines = function()
      return components[state.tab]()
    end,
    name = "typrStats",
  },
}
