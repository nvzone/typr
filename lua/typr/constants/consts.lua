local M = {}

M.DICTIONARIES = {
  Words = "words",
  SOWPODS = "sowpods",
  TypeRacer = "typeracer",
  Monkeytype = "monkeytype",
}

M.MODES = {
  "words",
  "sentences",
  Words = "words",
  Sentences = "sentences",
}

M.ALLOWED_DICTIONARIES = {

  [M.MODES.Words] = {
    [M.DICTIONARIES.Words] = true,
    [M.DICTIONARIES.SOWPODS] = true,
  },

  [M.MODES.Sentences] = {
    [M.DICTIONARIES.Monkeytype] = true,
    [M.DICTIONARIES.TypeRacer] = true,
  },
}

return M
