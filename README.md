# Typr

A Neovim plugin for practice typing with a very beautiful dashboard.

![typr](https://github.com/user-attachments/assets/4426d1c4-c4d3-4da7-987a-3b4c4395a4b5)
![typrstats](https://github.com/user-attachments/assets/b1653de3-05f3-4b90-b35e-9341eed8bf3e)
![typrstats vertical](https://github.com/user-attachments/assets/1ca824a0-5227-48c4-991c-f793cf62074a)

# Install

- Users which used typr before, delete your previous typrstats file.

```lua
{
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },
}
```

- Note: Activity UI is still WIP so dont expect it to work.

# Config

https://github.com/nvzone/typr/blob/main/lua/typr/state.lua#L18

## Disable completion

The typr buffer has the filetype set to `typr`. Refer to your completion plugins documentation on
how to disable it for that filetype which you can read using the buffer-scoped option
`vim.bo.filetype`.

# Mappings

Whatever buttons you see, the mapping starts from their first letter i.e

In Typr window

- s = toggle symbols
- n = toggle numbers
- r = toggle random
- 3 = set 3 lines , and so on!

In Typrstats vertical window

- D = dashboard
- H = history
- K = Keystrokes
