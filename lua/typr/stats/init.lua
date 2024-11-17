local M = {}
local api = vim.api
local state = require "typr.state"
local volt = require "volt"
local voltstate = require "volt.state"
local layout = require "typr.stats.layout"
local typrutils = require "typr.stats.utils"

M.open = function()
  require "typr.ui.hl"
  typrutils.restore_stats()

  state.statsbuf = api.nvim_create_buf(false, true)

  volt.gen_data {
    { buf = state.statsbuf, layout = layout, xpad = state.xpad, ns = state.ns },
  }

  local dim_buf = api.nvim_create_buf(false, true)

  local dim_win = api.nvim_open_win(dim_buf, false, {
    focusable = false,
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - 2,
    relative = "editor",
    style = "minimal",
    border = "none",
  })

  vim.wo[dim_win].winblend = 20

  state.h = voltstate[state.statsbuf].h

  state.win = api.nvim_open_win(state.statsbuf, true, {
    row = (vim.o.lines / 2) - (state.h / 2),
    col = (vim.o.columns / 2) - (state.w / 2),
    width = state.w,
    height = state.h,
    relative = "editor",
    style = "minimal",
    border = "single",
    zindex = 100,
    title = { { " Typing Stats ", "pmenusel" } },
    title_pos = "center",
  })

  api.nvim_win_set_hl_ns(state.win, state.ns)

  api.nvim_set_hl(state.ns, "FloatBorder", { link = "typrborder" })
  api.nvim_set_hl(state.ns, "Normal", { link = "typrnormal" })

  volt.run(state.statsbuf, {
    h = state.h,
    w = state.w_with_pad,
  })

  volt.mappings {
    bufs = { state.statsbuf, dim_buf },
  }

  require("volt.events").add(state.statsbuf)
end

return M