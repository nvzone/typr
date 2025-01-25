local lighten = require("volt.color").change_hex_lightness
local mix = require("volt.color").mix
local api = vim.api

local hexadecimal_to_hex = function(hex)
  return "#" .. ("%06x"):format(hex == nil and 0 or hex)
end

local function get_hl(name)
  local hl = api.nvim_get_hl(0, { name = name })
  local result = {}

  if hl.fg ~= nil then
    result.fg = hexadecimal_to_hex(hl.fg)
  end

  if hl.bg ~= nil then
    result.bg = hexadecimal_to_hex(hl.bg)
  end

  return result
end

return function(ns, winType)
  local bg

  if vim.g.base46_cache then
    local colors = dofile(vim.g.base46_cache .. "colors")
    bg = colors.black
  else
    bg = get_hl("Normal").bg
  end

  local transparent = not bg

  if not transparent then
    bg = lighten(bg, 2)
    api.nvim_set_hl(ns, "TyprBorder", { fg = bg, bg = bg })
    api.nvim_set_hl(ns, "TyprNormal", { bg = bg })
  else
    bg = "#000000"
  end

  if winType ~= "stats" then
    return
  end

  local exred = get_hl("ExRed").fg
  api.nvim_set_hl(ns, "TyprRed", { bg = mix(exred, bg, 80), fg = exred })

  local exgreen = get_hl("ExGreen").fg

  api.nvim_set_hl(ns, "TyprGreen", { bg = mix(exgreen, bg, 80), fg = exgreen })
  api.nvim_set_hl(ns, "TyprGreen0", { fg = mix(exgreen, bg, 10) })
  api.nvim_set_hl(ns, "TyprGreen1", { fg = mix(exgreen, bg, 40) })
  api.nvim_set_hl(ns, "TyprGreen2", { fg = mix(exgreen, bg, 60) })
  api.nvim_set_hl(ns, "TyprGreen3", { fg = mix(exgreen, bg, 80) })

  local exblue = get_hl("ExBlue").fg
  api.nvim_set_hl(ns, "TyprBlue", { bg = mix(exblue, bg, 80), fg = exblue })
  api.nvim_set_hl(ns, "TyprBlue0", { fg = mix(exblue, bg, 10) })
  api.nvim_set_hl(ns, "TyprBlue1", { fg = mix(exblue, bg, 40) })
  api.nvim_set_hl(ns, "TyprBlue2", { fg = mix(exblue, bg, 60) })
  api.nvim_set_hl(ns, "TyprBlue3", { fg = mix(exblue, bg, 80) })

  api.nvim_set_hl(ns, "TyprRed0", { fg = mix(exred, bg, 10) })
  api.nvim_set_hl(ns, "TyprRed1", { fg = mix(exred, bg, 40) })
  api.nvim_set_hl(ns, "TyprRed2", { fg = mix(exred, bg, 60) })
  api.nvim_set_hl(ns, "TyprRed3", { fg = mix(exred, bg, 80) })

  local exyellow = get_hl("ExYellow").fg
  api.nvim_set_hl(ns, "TyprYellow0", { fg = mix(exyellow, bg, 10) })
  api.nvim_set_hl(ns, "TyprYellow1", { fg = mix(exyellow, bg, 40) })
  api.nvim_set_hl(ns, "TyprYellow2", { fg = mix(exyellow, bg, 60) })
  api.nvim_set_hl(ns, "TyprYellow3", { fg = mix(exyellow, bg, 80) })

  -- local exyellow = get_hl("ExYellow").fg
  api.nvim_set_hl(ns, "TyprYellow", { bg = mix(exyellow, bg, 80, transparent), fg = exyellow })

  local x = vim.o.bg == "dark" and 1 or -1

  local commentfg = get_hl("comment").fg

  if transparent then
    api.nvim_set_hl(ns, "TyprGrey", { bg = lighten(commentfg, -22) })
  else
    api.nvim_set_hl(ns, "TyprGrey", { bg = lighten(bg, 6 * x), fg = lighten(commentfg, 10 * x) })
  end
end
