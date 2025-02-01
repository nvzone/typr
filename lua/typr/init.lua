local M = {}
local api = vim.api
local state = require "typr.state"
local layout = require "typr.ui.layout"
local volt = require "volt"
local utils = require "typr.utils"
local voltstate = require "volt.state"

M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})
  require("typr.stats.utils").restore_stats()
end

M.initialize_volt = function()
  volt.gen_data {
    { buf = state.buf, layout = layout, xpad = state.xpad, ns = state.ns },
  }
end

M.open = function()
  require "typr.ui.hl"(0)

  state.buf = api.nvim_create_buf(false, true)

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

  utils.gen_default_lines()

  M.initialize_volt()

  state.h = voltstate[state.buf].h

  state.win = api.nvim_open_win(state.buf, true, {
    row = (vim.o.lines / 2) - (state.h / 2),
    col = (vim.o.columns / 2) - (state.w / 2),
    width = state.w,
    height = state.h,
    relative = "editor",
    style = "minimal",
    border = "single",
    zindex = 100,
  })

  api.nvim_win_set_hl_ns(state.win, state.ns)

  api.nvim_set_hl(state.ns, "FloatBorder", { link = "typrborder" })
  api.nvim_set_hl(state.ns, "Normal", { link = "typrnormal" })

  api.nvim_set_current_win(state.win)

  volt.run(state.buf, {
    h = 10,
    w = state.w_with_pad,
    custom_empty_lines = utils.set_emptylines,
  })

  if state.config.insert_on_start then
    vim.api.nvim_command "startinsert"
  end

  ----------------- keymaps --------------------------
  volt.mappings {
    bufs = { state.buf, dim_buf },
    winclosed_event = true,
    after_close = function()
      state.reset_vars()
    end,
  }

  vim.bo[state.buf].filetype = "typr"
  vim.bo[state.buf].ma = true
  vim.wo[state.win].wrap = true
  vim.wo[state.win].sidescrolloff = 0
  vim.wo[state.win].virtualedit = "all"

  api.nvim_win_set_cursor(state.win, { state.words_row + 1, state.xpad })

  local lasttime = 0

  api.nvim_buf_attach(state.buf, false, {
    on_lines = function(_, _, _, line)
      if not state.lastchar and api.nvim_get_mode().mode == "i" then
        utils.start_timer()
      end

      local curline = api.nvim_get_current_line():sub(3)
      local words_row = line - state.words_row + 1
      local default_line = state.default_lines[words_row]

      state.ui_lines[words_row] = utils.gen_lines_diff(default_line, curline)

      api.nvim_buf_set_extmark(state.buf, state.ns, line, 0, {
        virt_text = state.ui_lines[words_row],
        virt_text_win_col = state.xpad,
        id = line + 1,
      })

      state.lastchar = curline:sub(-1)

      local cur = vim.uv.hrtime()
      table.insert(state.stats.char_times, { state.lastchar, (cur - lasttime) / 1e6 })
      lasttime = cur

      utils.handle_test_end()
    end,
  })

  require "typr.mappings"()

  pcall(function()
    require("cmp").setup.buffer { enabled = false }
  end)

  if type(state.config.on_attach) == "function" then
    state.config.on_attach(state.buf)
  end
end

return M
