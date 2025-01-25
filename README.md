# Typr

A Neovim plugin for practice typing with a very beautiful dashboard.

![typr](https://github.com/user-attachments/assets/4426d1c4-c4d3-4da7-987a-3b4c4395a4b5)
![typrstats](https://github.com/user-attachments/assets/b1653de3-05f3-4b90-b35e-9341eed8bf3e)
![typrstats vertical](https://github.com/user-attachments/assets/1ca824a0-5227-48c4-991c-f793cf62074a)

## Install

- Users which used Typr before, delete your previous typrstats file.

```lua
{
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },
}
```

- Note: Activity UI is still WIP so dont expect it to work.

## Config

[Default config](https://github.com/nvzone/typr/blob/main/lua/typr/state.lua#L18).

### Disable auto pairing and completion

The Typr buffer has the file type set to `typr`. Refer to your completion
and auto-pairing plugins documentation on how to disable it for that
file type which you can read using the buffer-scoped option `vim.bo.filetype`.

#### [blink.cmp](https://github.com/Saghen/blink.cmp)

```lua
{
  "Saghen/blink.cmp",
  opts = {
    enabled = function()
      return not vim.tbl_contains({ "typr" }, vim.bo.filetype)
        and vim.bo.buftype ~= "prompt"
        and vim.b.completion ~= false
    end,
  },
}
```

#### [nvim-autopairs](https://github.com/windwp/nvim-autopairs)

```lua
{
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    disable_filetype = { "TelescopePrompt", "spectre_panel", "typr" },
  },
}
```

## Mappings

Whatever buttons you see, the mapping starts from their first letter i.e.

In Typr window:

- s = toggle symbols
- n = toggle numbers
- r = toggle random
- 3 = set 3 lines, and so on!

In TyprStats vertical window:

- D = dashboard
- H = history
- K = Keystrokes
