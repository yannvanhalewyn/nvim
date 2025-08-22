# Neovim Simple Config

A lean and fast Neovim configuration designed for Clojure development. Inspired by [NvChad](https://nvchad.com/) but built from scratch while still incorporating the nice UI NvChad offers. It's meant to stay as clean as possible, and use few plugins while still having some quality of life plugins.

## Features

- **Modern Neovim**: Uses native LSP and vim.pack package management (requires Neovim 0.12+)
- **NvChad UI**: Retains the beautiful statusline and base46 colorschemes from the amazing NvChad distro
- **Clojure-focused**: Optimized specifically for Clojure development workflow
- **Minimal & Fast**: Clean, simple configuration without unnecessary bells and whistles. Most configuration fits in a single ~300 line [`init.lua`](./init.lua) file

## Why This Config?

While [NvChad](https://nvchad.com/) is an excellent Neovim distribution with fantastic UI components, this config strips away the complexity to focus on what matters most for Clojure development - speed, clarity, and simplicity.

## Key Mappings

| Mapping | Description |
|---------|-------------|
| `<space><space>` | Pick files |
| `<space>x` | Grep live |
| `<space>bb` | Pick buffers |
| `<space>d` | Oil (file browser) |
| `<space>n` | NeoTree |
| `<space>ha` | Harpoon add file |
| `<space>H` | Harpoon quick menu |
| `Alt-hjkl;` | Harpoon select files 1-5 |
| `<space>fs` | Save file |
| `<space>cf` | Format buffer |
| `<space>ca` | Code actions |
| `gd` | Go to definition |
| `[e` / `]e` | Previous/next diagnostic |
| `[c` / `]c` | Previous/next git hunk |
| `<space>gs` | Git stage hunk |
| `<space>gr` | Git reset hunk |
| `Alt-HJKL` | Paredit slurp/barf |
| `,w` | Paredit wrap with parens |
