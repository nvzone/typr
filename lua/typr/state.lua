local M = {
  ns = vim.api.nvim_create_namespace "Typr",
  xpad = 2,
  w = 80,
  h = 20,
  linecount = 1,
  default_lines = {},
  ui_lines = {},
  lastchar = nil,
  words_row = 4,
  timer = vim.uv.new_timer(),
  secs = 0,
  months_toggled = false,
  tab = "  Dashboard",

  config = {
    kblayout = "qwerty",
    wpm_goal = 200,
    numbers = false,
    punctuation = false,
    random = false,
    insert_on_start = false,
    stats_filepath = vim.fn.stdpath "config" .. "/typrstats",
  },

  -- stats = {} -- data stored here after test finishes
  -- then saved to disk and this table is reset
}

M.reset_vars = function()
  M.lastchar = nil
  M.secs = 0

  M.stats = {
    accuracy = 0,
    wpm = 0,
    rawpm = 0,
    correct_word_ratio = "?",
    total_char_count = 0,
    typed_char_count = 0,
    char_times = {},
    char_stats = { all = 0, wrong = 0 },
    word_stats = { all = 0, wrong = 0 },
  }

  M.timer:stop()
end

M.reset_vars()

M.w_with_pad = M.w - (2 * M.xpad)

return M
