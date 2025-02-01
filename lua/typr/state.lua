local M = {
  ns = vim.api.nvim_create_namespace "Typr",
  xpad = 2,
  w = 80,
  h = 20,
  linecount = 2,
  default_lines = {},
  ui_lines = {},
  lastchar = nil,
  words_row = 4,
  timer = vim.uv.new_timer(),
  secs = 0,
  months_toggled = false,
  tab = "  Dashboard",
  winlayout = "horizontal",
  horiz_i = 1,

  -- temporary!
  -- stats = {} -- data stored here after test finishes
  -- then saved to disk and this table is reset

  ----------------------- user config -----------------------
  config = {
    mode = "words", -- words, phrases
    winlayout = "responsive",
    kblayout = "qwerty",
    wpm_goal = 130,
    numbers = false,
    symbols = false,
    random = false,
    phrases = nil, -- can be a table of strings
    insert_on_start = false,
    stats_filepath = vim.fn.stdpath "data" .. "/typrstats",
    mappings = nil,
    -- or function(buf) end
    -- mappings = function(buf)
    --  vim.keymap.set("n", "a, anything, { buffer = buf })
    -- end,
    on_attach = nil,
    -- or function(buf) end
    -- on_attach = function(buf)
    --  vim.b[buf].minipairs_disable = true
    -- end,
  },

  -- for stats
  data = {},
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
