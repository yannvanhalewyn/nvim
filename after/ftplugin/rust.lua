-- Rust-specific settings
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

-- Use rust-analyzer for formatting
vim.bo.formatexpr = "v:lua.vim.lsp.formatexpr()"

-- Common Rust comment style
vim.bo.commentstring = "//%s"