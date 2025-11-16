local M = {}
local api = vim.api
local state = require "typr.state"
local volt = require "volt"
local voltstate = require "volt.state"
local utils = require "typr.stats.utils"

M.open = function()
  if state.statsbuf then
    return
  end

  state.statsbuf = api.nvim_create_buf(false, true)

  if state.config.winlayout == "responsive" then
    state.winlayout = vim.o.columns > ((2 * state.w) + 10) and "horizontal" or "vertical"
  else
    state.winlayout = state.config.winlayout
  end

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

  if state.config.transparent_background then
    vim.wo[dim_win].winblend = 100
  else
    vim.wo[dim_win].winblend = 20
  end

  require("typr.stats.utils").init_volt()
  state.h = voltstate[state.statsbuf].h

  local winconf = utils.make_winconf()
  state.win = api.nvim_open_win(state.statsbuf, true, winconf)

  api.nvim_win_set_hl_ns(state.win, state.ns)
  api.nvim_set_hl(state.ns, "FloatBorder", { link = "typrborder" })
  api.nvim_set_hl(state.ns, "Normal", { link = "typrnormal" })

  volt.run(state.statsbuf, { h = state.h + 1, w = state.w_with_pad })

  require "typr.ui.hl"(state.ns, "stats")

  volt.mappings {
    bufs = { state.statsbuf, dim_buf },
    winclosed_event = true,
    after_close = function()
      state.statsbuf = nil
      -- vim.api.nvim_del_augroup_by_name "TyprResize"
    end,
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

  vim.keymap.set("n", "<C-t>", function()
    state.horiz_i = state.horiz_i == 3 and 1 or state.horiz_i + 1
    volt.redraw(state.statsbuf, "all")
  end, { buffer = state.statsbuf })

  vim.bo[state.statsbuf].filetype = "typrstats"

  -- vim.api.nvim_create_autocmd("VimResized", {
  --   group = vim.api.nvim_create_augroup("TyprResize", {}),
  --   callback = function()
  --     if state.config.winlayout == "responsive" then
  --       state.winlayout = vim.o.columns > ((2 * state.w) + 10) and "horizontal" or "vertical"
  --       state.h = state.h == 40 and 36 or 40
  --
  --       vim.bo[state.statsbuf].modifiable = true
  --       require("volt").set_empty_lines(state.statsbuf, state.h, 1)
  --       vim.bo[state.statsbuf].modifiable = false
  --
  --       utils.init_volt()
  --       volt.redraw(state.statsbuf, "all")
  --     end
  --
  --     local conf = utils.make_winconf()
  --     api.nvim_win_set_config(state.win, conf)
  --     api.nvim_win_set_hl_ns(state.win, state.ns)
  --   end,
  -- })
end

return M
