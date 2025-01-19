local M = {}
local api = vim.api
local state = require "typr.state"
local volt = require "volt"
local voltstate = require "volt.state"
local layout = require "typr.stats.layout"

M.open = function()
  state.statsbuf = api.nvim_create_buf(false, true)

  volt.gen_data {
    { buf = state.statsbuf, layout = layout, xpad = state.xpad, ns = state.ns },
  }

  -- local dim_buf = api.nvim_create_buf(false, true)

  -- local dim_win = api.nvim_open_win(dim_buf, false, {
  --   focusable = false,
  --   row = 0,
  --   col = 0,
  --   width = vim.o.columns,
  --   height = vim.o.lines - 2,
  --   relative = "editor",
  --   style = "minimal",
  --   border = "none",
  -- })
  --
  -- vim.wo[dim_win].winblend = 20

  state.h = voltstate[state.statsbuf].h

  local  large_screen = state.h + 10 < vim.o.lines
  local h = large_screen and state.h or vim.o.lines - 7

  state.win = api.nvim_open_win(state.statsbuf, true, {
    row = large_screen and ((vim.o.lines / 2) - (state.h / 2)) or 2,
    col = (vim.o.columns / 2) - (state.w / 2),
    width = state.w,
    height = h,
    relative = "editor",
    style = "minimal",
    border = "single",
    zindex = 100,
  })

  api.nvim_win_set_hl_ns(state.win, state.ns)

  api.nvim_set_hl(state.ns, "FloatBorder", { link = "typrborder" })
  api.nvim_set_hl(state.ns, "Normal", { link = "typrnormal" })

  volt.run(state.statsbuf, {
    h = state.h+1,
    w = state.w_with_pad,
  })

  require "typr.ui.hl"(state.ns, "stats")

  volt.mappings {
    bufs = { state.statsbuf },
  }

  vim.keymap.set("n", "<tab>", function()
    state.months_toggled = not state.months_toggled
    volt.redraw(state.statsbuf, "typrStats")
  end, { buffer = state.statsbuf })

  vim.keymap.set("n", "D", function()
    state.tab = "  Dashboard"
    volt.redraw(state.statsbuf, "all")
  end, { buffer = state.statsbuf })

  vim.keymap.set("n", "K", function()
    state.tab = "Keystrokes"
    volt.redraw(state.statsbuf, "all")
  end, { buffer = state.statsbuf })

    vim.keymap.set("n", "H", function()
    state.tab = "  History"
    volt.redraw(state.statsbuf, "all")
  end, { buffer = state.statsbuf })

  vim.bo[state.statsbuf].filetype = "typrstats"
end

return M
