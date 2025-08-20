vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.signcolumn = "yes"
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.o.undofile = true
vim.g.mapleader = " "

--------------------------------------------------------------------------------
-- Require Plugins

vim.pack.add({
	{ src = "https://github.com/vague2k/vague.nvim" },
	{ src = "https://github.com/tpope/vim-surround" },
	{ src = "https://github.com/tpope/vim-repeat" }, -- Make surround repeatable
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
})

require("mini.pick").setup()
require("oil").setup()
require("gitsigns").setup();

require('nvim-treesitter.configs').setup({
	highlight = {
		enable = true,
	},
})

--------------------------------------------------------------------------------
-- Mappings

-- Files and buffers
vim.keymap.set("n", "<leader>so", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>fs", ":write<CR>")
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>hh", ":Pick help<CR>")
vim.keymap.set("n", "<leader>bb", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>")
vim.keymap.set("n", "<leader> ", ":Pick files<CR>")
vim.keymap.set("n", "<leader>x", ":Pick grep_live<CR>")
vim.keymap.set("n", "<leader>d", ":Oil<CR>")

-- Editor
local gitsigns = require("gitsigns")

vim.keymap.set("n", "<esc>", ":noh<CR>", { silent = true } )
vim.keymap.set("v", "<leader>p", '"_dP') -- Paste without overwriting the default register
vim.keymap.set("x", "y", '"+y', s)       -- Yank to the system clipboard in visual mode
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP Go to definition" })
vim.keymap.set("n", "[c", gitsigns.prev_hunk, { desc = "Git Next Unstanged Hunk" })
vim.keymap.set("n", "]c", gitsigns.next_hunk, { desc = "Git Previous Unstanged Hunk" })
vim.keymap.set("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Git Reset Hunk", })
vim.keymap.set("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Git Stage Hunk", })
vim.keymap.set("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Git Stage Buffer", })
vim.keymap.set("n", "<leader>gy", gitsigns.undo_stage_hunk, { desc = "Git Undo Stage Hunk", })
vim.keymap.set("n", "<leader>gp", gitsigns.preview_hunk_inline, { desc = "Git Preview Hunk Inline" })
vim.keymap.set("n", "<leader>gP", gitsigns.preview_hunk, { desc = "Git Preview Hunk" })
vim.keymap.set("n", "<leader>gb", gitsigns.blame_line, { desc = "Git blame line", })
-- vim.keymap.set("<leader>gB", function() require("agitator").git_blame_toggle() end, { desc = "Git Blame", })

vim.keymap.set("n", "[e", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "]e", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float)

-- Tabs
vim.keymap.set("n", "[w", ":tabprev<CR>")
vim.keymap.set("n", "]w", ":tabnext<CR>")
vim.keymap.set("n", "<leader><tab>n", ":tabnew<CR>")
vim.keymap.set("n", "<leader><tab>d", ":tabclose<CR>")

-- Window
vim.keymap.set("n", "<leader>wv", ":vsplit<CR><C-w>l")
vim.keymap.set("n", "<leader>ws", ":split<CR><C-w>j")
vim.keymap.set("n", "<leader>wq", ":quit<CR>")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Completion keymaps
vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', { desc = 'Trigger completion' })
vim.keymap.set('i', '<C-n>', '<C-n>', { desc = 'Next completion' })
vim.keymap.set('i', '<C-p>', '<C-p>', { desc = 'Previous completion' })
vim.keymap.set('i', '<C-e>', vim.snippet.expand, { desc = 'Snippet Expand' })

--------------------------------------------------------------------------------
-- LSP / Completion

vim.lsp.enable({ "lua_ls", "clojure_lsp" })

vim.opt.completeopt = { "menu", "menuone", "noselect" }

require("blink.cmp").setup({
    fuzzy = { implementation = "lua" }, -- "prefer_rust_with_warning"
    signature = { enabled = true },
    keymap = {
        preset = "default",
        ["<Tab>"] = { "select_and_accept", "fallback" },
        ["<C-y>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-n>"] = { "select_next" },
        ["<C-p>"] = { "select_prev" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_down", "fallback" },
        ["<C-f>"] = { "scroll_documentation_up", "fallback" },
    },

    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
        }
    },
})

--------------------------------------------------------------------------------
-- UI

vim.cmd("colorscheme vague")
vim.cmd(":hi statusline guibg=NONE")
vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ timeout = 140 })
	end,
})
