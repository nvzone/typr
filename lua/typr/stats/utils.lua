local M = {}
local state = require "typr.state"
local layout = require "typr.stats.layout"

M.gen_default_stats = function()
  local default_stats = {
    times = 0,
    total_secs = 0,
    wpm = { avg = 0, max = 0, min = 0 },
    rawpm = { avg = 0, max = 0, min = 0 },
    accuracy = 0,
    rawpm_hist = {},
    wpm_hist = {},
    accuracy_hist = {},
    char_accuracy = {},
    char_times = {},
    char_stats = { all = 0, wrong = 0 },
    word_stats = { all = 0, wrong = 0 },
    test_history = {},
    activity = {},
  }

  for i = 1, 32 do
    if i <= 10 then
      table.insert(default_stats.wpm_hist, 0)
      table.insert(default_stats.accuracy_hist, 0)
    end

    table.insert(default_stats.rawpm_hist, 0)
  end

  for _ = 1, 8 do
    table.insert(default_stats.test_history, { wpm = 0, rawpm = 0, accuracy = 0, time = 0 })
  end

  return default_stats
end

M.save_str_tofile = function(tb)
  local str = "'" .. vim.json.encode(tb) .. "'"

  local data = "return string.dump(function()return" .. str .. "end, true)"
  local path = state.config.stats_filepath
  local file = io.open(path, "wb")
  file:write(loadstring(data)())
  file:close()
end

M.restore_stats = function()
  local path = state.config.stats_filepath
  local ok, stats = pcall(dofile, path)

  if ok and stats then
    state.data = vim.json.decode(stats)
  else
    local oldfile = vim.fn.stdpath "config" .. "/typrstats"
    local ok2, oldata = pcall(dofile, oldfile)
    state.data = ok2 and oldata and vim.json.decode(oldata) or M.gen_default_stats()
    M.save_str_tofile(state.data)
  end
end

M.save = function()
  local stats = state.stats
  local tmp = state.data

  tmp.times = tmp.times + 1
  local oldtimes = tmp.times - 1
  local times = tmp.times

  -- calc wpm
  tmp.wpm.avg = ((tmp.wpm.avg * oldtimes) + stats.wpm) / times
  tmp.wpm.avg = math.floor(tmp.wpm.avg)
  tmp.wpm.max = (stats.wpm > tmp.wpm.max and stats.wpm) or tmp.wpm.max

  if tmp.wpm.min == 0 then
    tmp.wpm.min = stats.wpm
  else
    tmp.wpm.min = (stats.wpm < tmp.wpm.min and stats.wpm) or tmp.wpm.min
  end

  table.insert(tmp.wpm_hist, stats.wpm)
  table.remove(tmp.wpm_hist, 1)

  -- calc rawpm
  tmp.rawpm.avg = ((tmp.rawpm.avg * oldtimes) + stats.rawpm) / times
  tmp.rawpm.avg = math.floor(tmp.rawpm.avg)
  tmp.rawpm.max = (stats.rawpm > tmp.rawpm.max and stats.rawpm) or tmp.rawpm.max

  table.insert(tmp.rawpm_hist, stats.rawpm)
  table.remove(tmp.rawpm_hist, 1)

  -- calc accuracy
  table.insert(tmp.accuracy_hist, stats.accuracy)
  table.remove(tmp.accuracy_hist, 1)

  -- accuracy average
  tmp.accuracy = ((tmp.accuracy * oldtimes) + stats.accuracy) / times
  tmp.accuracy = math.floor(tmp.accuracy)

  tmp.total_secs = tmp.total_secs + state.secs

  -- calc wrong chars
  for k, v in pairs(stats.char_accuracy) do
    local char_avg = tmp.char_accuracy[k] or 100

    tmp.char_accuracy[k] = ((char_avg * oldtimes) + v) / times
    tmp.char_accuracy[k] = math.floor(tmp.char_accuracy[k])
  end

  -- calc char times
  for k, v in pairs(stats.char_times) do
    tmp.char_times[k] = ((tmp.char_times[k] or 0) + v) / times
  end

  tmp.char_stats = {
    all = tmp.char_stats.all + stats.char_stats.all,
    wrong = tmp.char_stats.wrong + stats.char_stats.wrong,
  }

  tmp.word_stats = {
    all = tmp.word_stats.all + stats.word_stats.all,
    wrong = tmp.word_stats.wrong + stats.word_stats.wrong,
  }

  table.insert(tmp.test_history, {
    wpm = stats.wpm,
    rawpm = stats.rawpm,
    accuracy = stats.accuracy,
    time = state.secs,
  })

  table.remove(tmp.test_history, 1)

  local date = os.date "%d%m%Y"
  tmp.activity[date] = (tmp.activity[date] or 0) + 1

  state.data = tmp
  state.stats.char_times = {}

  M.save_str_tofile(tmp)
end

M.init_volt = function()
  require("volt").gen_data {
    { buf = state.statsbuf, layout = layout[state.winlayout], xpad = state.xpad, ns = state.ns },
  }
end

M.make_winconf = function()
  local large_screen = state.h + 10 < vim.o.lines
  local h = large_screen and state.h or vim.o.lines - 7
  local winw = state.w

  if state.winlayout == "horizontal" then
    winw = winw * 2
  end

  return {
    row = large_screen and ((vim.o.lines / 2) - (state.h / 2)) or 2,
    col = (vim.o.columns / 2) - (winw / 2),
    width = winw,
    height = h,
    relative = "editor",
    style = "minimal",
    border = "single",
    zindex = 100,
  }
end

return M
