--------------------------------------------------------------------------------
-- Options

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.signcolumn = "yes"
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.o.undofile = true
vim.o.splitright = true
vim.g.mapleader = " "
vim.g.maplocalleader = ","

--------------------------------------------------------------------------------
-- Require Plugins

vim.pack.add({
	-- UI
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/nvchad/ui" },
	{ src = "https://github.com/nvchad/base46" },
	-- Editor
	{ src = "https://github.com/tpope/vim-surround" },
	{ src = "https://github.com/tpope/vim-repeat" },                -- Make surround repeatable
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },     -- Used by Oil.nvim, NeoTree and NvChad
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
	{ src = "https://github.com/mawkler/refjump.nvim" },            -- Jump LSP references in buffer with [r and ]r
	-- VCS
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/linrongbin16/gitlinker.nvim" },
	-- Util
	{ src = "https://github.com/nvim-lua/plenary.nvim" },           -- Required by Harpoon and NvChad
	{ src = "https://github.com/MunifTanjim/nui.nvim" },            -- Required by NeoTree
	{ src = "https://github.com/christoomey/vim-tmux-navigator" },
	{ src = "https://github.com/julienvincent/hunk.nvim" },         -- Used to execute interactive operations with Jujutusu
	-- Lang
	{ src = "https://github.com/Olical/conjure" },
	{ src = "https://github.com/julienvincent/nvim-paredit" },
})

--------------------------------------------------------------------------------
-- Picker and file trees

local minipick = require("mini.pick")

minipick.setup({
	mappings = {
		choose_all = {
			char = "<C-q>", -- Send to quickfix list
			func = function()
				local mappings = minipick.get_picker_opts().mappings
				vim.api.nvim_input(mappings.mark_all .. mappings.choose_marked)
			end
		},
	},
})

require("oil").setup()

local harpoon = require("harpoon")
harpoon.setup()

require("neo-tree").setup({
	enable_git_status = false,
	popup_border_style = "rounded",
	filesystem = {
		hijack_netrw_behavior = "disabled",
		window = {
			position = "left",
			mappings = {
				["<tab>"] = "open",
				["s"] = "open_split",
				["v"] = "open_vsplit",
			}
		}
	},
})

--------------------------------------------------------------------------------
-- LSP / Completion

vim.lsp.enable({ "lua_ls", "clojure_lsp" })

vim.opt.completeopt = { "menu", "menuone", "noselect" }

require("blink.cmp").setup({
	fuzzy = { implementation = "prefer_rust_with_warning" }, -- "prefer_rust_with_warning"
	signature = { enabled = true },
	keymap = {
		-- preset = "default",
		["<Tab>"] = { "select_and_accept", "fallback" },
		["<C-y>"] = { "fallback" }, -- This re-enables <C-y> in insert mode as copy from line above
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
		},
	},
})

--------------------------------------------------------------------------------
-- UI / Editor

-- Use NvChad's statusline and base46 colorschemes. See ./lua/chadrc.lua for options
require("nvchad")
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

local base46_integrations = {
	"blink",
	"defaults",
	"devicons",
	"git",
	"lsp",
	-- "nvimtree",
	"statusline",
	"syntax",
	"treesitter",
	-- "tbline",
	-- "telescope",
}

-- Compile base46 when files are missing. Should only be ran on install
if vim.tbl_contains(
		vim.tbl_map(
			function(name)
				return vim.fn.filereadable(vim.g.base46_cache .. name) ~= 0
			end,
			base46_integrations
		), false) then
	print("Compiling base46 integrations")
	require("base46").compile()
end

for _, name in ipairs(base46_integrations) do
	dofile(vim.g.base46_cache .. name)
end

vim.cmd.colorscheme("nvchad")

-- Configure diagnostic signs with nice icons like in NvChad
vim.diagnostic.config {
	-- virtual_text = { prefix = "" },
	signs = {
		text =
		{
			[vim.diagnostic.severity.ERROR] = "󰅙",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "󰋼",
			[vim.diagnostic.severity.HINT] = "󰌵"
		}
	},
	underline = true,
	float = { border = "single" },
}

require('nvim-treesitter.configs').setup({
	ensure_installed = { "lua", "luadoc", "clojure", "printf", "vim", "vimdoc" },
	highlight = {
		enable = false,
	},
	indent = { enable = true },
})

local gitsigns = require("gitsigns")
gitsigns.setup()

require("hunk").setup({
	keys = {
		global = {
			quit = { "q" },
			accept = { "<C-c><C-c>" },
			focus_tree = { "<leader>n" },
		},

		tree = {
			toggle_node = { "o" },
			expand_node = { "l", "<Right>" },
			collapse_node = { "h", "<Left>" },
			open_file = { "<Cr>" },
			toggle_file = { "s" },
		},

		diff = {
			-- toggles both left and right diff on line.
			-- Use `toggle_line` if you desire to select only one side.
			toggle_line_pair = { "s" },
			toggle_hunk = { "S" },
		},
	},
})

require("refjump").setup({
	-- highlights = {
	-- 	enable = false
	-- },
	integrations = {
		demicolon = {
			enable = false
		}
	},
	verbose = false
})

--------------------------------------------------------------------------------
-- AuCommands

-- Cleanup whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		local save_cursor = vim.fn.getpos(".")
		-- pcall catches errors
		pcall(function() vim.cmd [[%s/\s\+$//e]] end)
		vim.fn.setpos(".", save_cursor)
	end,
})

-- Reopen buffer at last stored position
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	-- silent! because may fail with truncated file before stored point
	command = "silent! normal! g`\"zzzv"
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ timeout = 140 })
	end,
})

vim.o.updatetime = 300
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.lsp.buf.document_highlight()
	end
})

vim.api.nvim_create_autocmd("CursorMoved", {
	callback = function()
		vim.lsp.buf.clear_references()
	end
})

--------------------------------------------------------------------------------
-- Clojure

vim.g["conjure#mapping#doc_word"] = false -- Disables annoying 'K' binding
vim.g["conjure#highlight#enabled"] = true -- Highlight evaluated forms
vim.g.clojure_align_multiline_strings = 1
vim.g.clojure_align_subforms = 0
vim.g.clojure_fuzzy_indent = 1
vim.g.clojure_fuzzy_indent_patterns = { ".*" }
vim.g.clojure_fuzzy_indent_blacklist = {
	"^or$", "^and$", "=", "^+$", "^-$", "^str$"
}

local paredit = require("nvim-paredit")
paredit.setup()

--------------------------------------------------------------------------------
-- Mappings

local f = require("functions")
local snippets = require("snippets")
local zen_mode = require("zen_mode")
require("gitlinker").setup({
	router = {
		-- Usage :GitLink commit [rev=... file=./] This is a change
		commit = {
			["^github%.com"] = "https://github.com/"
				.. "{_A.ORG}/"
				.. "{_A.REPO}/"
				.. "commit/"
				.. "{_A.REV}"
		},
		-- Usage :GitLink compare file=./ rev=master..<rev>
		compare = {
			["^github%.com"] = "https://github.com/"
				.. "{_A.ORG}/"
				.. "{_A.REPO}/"
				.. "compare/"
				.. "{_A.REV}"
		},
	}
})

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
vim.keymap.set("n", "<leader>n", ":Neotree<CR>", { desc = "Neotree", })
vim.keymap.set("n", "<leader>N", ":Neotree document_symbolds right<CR>", { desc = "Neotree", })
vim.keymap.set("n", "<leader>B", ":Neotree buffers left<cr>", { desc = "Toggle Neotree Document Symbols" })
vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon Add File" })
vim.keymap.set("n", "<leader>H", f.harpoon_quick_menu, { desc = "Harpoon Quick Menu" })
vim.keymap.set("n", "<A-h>", f.harpoon_select(1), { desc = "Harpoon Browse File (1)" })
vim.keymap.set("n", "<A-j>", f.harpoon_select(2), { desc = "Harpoon Browse File (2)" })
vim.keymap.set("n", "<A-k>", f.harpoon_select(3), { desc = "Harpoon Browse File (3)" })
vim.keymap.set("n", "<A-l>", f.harpoon_select(4), { desc = "Harpoon Browse File (4)" })
vim.keymap.set("n", "<A-;>", f.harpoon_select(5), { desc = "Harpoon Browse File (5)" })
vim.keymap.set("n", "<leader>fw", f.grep_current_word, { desc = "Find Word at Point" })
vim.keymap.set("n", "<leader>fW", f.grep_current_WORD, { desc = "Find WORD at Point" })

-- Tabs
vim.keymap.set("n", "[w", ":tabprev<CR>")
vim.keymap.set("n", "]w", ":tabnext<CR>")
vim.keymap.set("n", "<leader><tab>n", ":tabnew<CR>")
vim.keymap.set("n", "<leader><tab>d", ":tabclose<CR>")

-- Windows
vim.keymap.set("n", "<leader>wv", ":vsplit<CR><C-w>l")
vim.keymap.set("n", "<leader>ws", ":split<CR><C-w>j")
vim.keymap.set("n", "<leader>wq", ":quit<CR>")
vim.keymap.set("n", "<leader>wo", vim.cmd.only, { desc = "Window Close other windows" })
vim.keymap.set("n", "<leader>wQ", ":wall<CR>:qall<CR>", { desc = "Window Quit All" })
vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<cr>")
vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<cr>")
vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<cr>")

-- Editing
vim.keymap.set("i", "<C-f>", "<right>")
vim.keymap.set("i", "<C-b>", "<left>")
vim.keymap.set('i', '<C-s>', snippets.expand_snippet, { desc = 'Snippet Expand' })
vim.keymap.set("n", "+", "<C-a>", { desc = "Edit Increment" })
vim.keymap.set("n", "-", "<C-x>", { desc = "Edit Decrement" })
vim.keymap.set("n", "\\", ",", { desc = "Reverse f, t, F or T" }) -- Since ',' is the localleader

-- Editor
vim.keymap.set("n", "<leader>tt", function() require("base46").toggle_theme() end, { desc = "Toggle Theme" })
vim.keymap.set("n", "<esc>", ":noh<CR>", { silent = true })
vim.keymap.set("n", "<A-c>", f.toggle_color_column, { desc = "Toggle Color Column" })
vim.keymap.set("n", "<A-C>", ":set cursorcolumn!<CR>", { desc = "Toggle Cursor Highlight" })
vim.keymap.set("n", "<leader>tz", zen_mode.toggle, { desc = "Toggle Zen Mode" })
vim.keymap.set("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "Toggle Relative number" })
vim.keymap.set("n", "<leader>tf", ":set formatexpr=<cr>", { desc = "Toggle Format Expression" })

-- Yanking and pasting
vim.keymap.set("n", "<leader>y", '"+y')    -- Yank to system clipboard
vim.keymap.set("n", "<leader>p", '"+p')    -- Paste from system clipboard
vim.keymap.set("v", "<leader>p", '"_d"+P') -- Overwrite from clipboard without overwriting clipboard registry
vim.keymap.set("v", "<leader>P", '"_dP')   -- Paste without overwriting the default register
vim.keymap.set("x", "y", '"+y')            -- Yank to the system clipboard in visual mode
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP Go to definition" })

-- Git chunks
vim.keymap.set("n", "[c", gitsigns.prev_hunk, { desc = "Git Next Unstanged Hunk" })
vim.keymap.set("n", "]c", gitsigns.next_hunk, { desc = "Git Previous Unstanged Hunk" })
vim.keymap.set("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Git Reset Hunk", })
vim.keymap.set("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Git Stage Hunk", })
vim.keymap.set("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Git Stage Buffer", })
vim.keymap.set("n", "<leader>gy", gitsigns.undo_stage_hunk, { desc = "Git Undo Stage Hunk", })
vim.keymap.set("n", "<leader>gp", gitsigns.preview_hunk_inline, { desc = "Git Preview Hunk Inline" })
vim.keymap.set("n", "<leader>gP", gitsigns.preview_hunk, { desc = "Git Preview Hunk" })
vim.keymap.set("n", "<leader>gb", gitsigns.blame_line, { desc = "Git blame line", })

-- Git link
vim.keymap.set("n", "<leader>gll", ":GitLink current_branch<cr>", { desc = "Git Link Current Banch" })
vim.keymap.set("v", "<leader>gll", ":GitLink current_branch<cr>", { desc = "Git Link Current Banch" })
vim.keymap.set("n", "<leader>glL", ":GitLink! current_branch<cr>", { desc = "Git Link Current Branch and open" })
vim.keymap.set("v", "<leader>glL", ":GitLink! current_branch<cr>", { desc = "Git Link Current Branch and open" })
vim.keymap.set("n", "<leader>glm", ":GitLink default_branch<cr>", { desc = "Git Link Master" })
vim.keymap.set("v", "<leader>glm", ":GitLink default_branch<cr>", { desc = "Git Link Master" })
vim.keymap.set("n", "<leader>glM", ":GitLink! default_branch<cr>", { desc = "Git Link Master and open" })
vim.keymap.set("v", "<leader>glM", ":GitLink! default_branch<cr>", { desc = "Git Link Master and open" })
vim.keymap.set("n", "<leader>glc", ":GitLink commit file=./ rev=<c-r><c-w><cr>", { desc = "Git Link Commit" })
vim.keymap.set("n", "<leader>glC", ":GitLink! commit file=./ rev=<c-r><c-w><cr>", { desc = "Git Link Commit (Open)" })
vim.keymap.set("n", "<leader>gld", ":GitLink compare file=./ rev=master..<c-r><c-w>", { desc = "Git Link Diff" })
vim.keymap.set("n", "<leader>glD", ":GitLink! compare file=./ rev=master..<c-r><c-w>", { desc = "Git Link Diff (Open)" })

-- Code / Diagnostics
vim.keymap.set("n", "[e", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "]e", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)

-- Quickfix
vim.keymap.set("n", "<leader>tq", f.toggle_quickfix_window, { desc = "Toggle Quickfix Window" })
vim.keymap.set("n", "[q", f.recenter_if_scrolled("cprev"), { desc = "Quickfix Prev" })
vim.keymap.set("n", "]q", f.recenter_if_scrolled("cnext"), { desc = "Quickfix Next" })

-- CLojure / Lisps
vim.keymap.set("n", "<A-H>", function() require("nvim-paredit").api.slurp_backwards() end,
	{ desc = "Paredit Slurp backwards" })
vim.keymap.set("n", "<A-J>", function() require("nvim-paredit").api.barf_backwards() end,
	{ desc = "Paredit Barf backwards" })
vim.keymap.set("n", "<A-K>", function() require("nvim-paredit").api.barf_forwards() end,
	{ desc = "Paredit Barf forwards" })
vim.keymap.set("n", "<A-L>", function() require("nvim-paredit").api.slurp_forwards() end,
	{ desc = "Paredit Slurp forwards" })
vim.keymap.set("n", "<A-]>", f.paredit_wrap("[", "]", "inner_start"), { desc = "Paredit Wrap Element ]" })
vim.keymap.set("n", "<A-}>", f.paredit_wrap("{", "}", "inner_start"), { desc = "Paredit Wrap Element }" })
vim.keymap.set("n", "<localleader>w", f.paredit_wrap("( ", ")", "inner_start"),
	{ desc = "Paredit Wrap Element Insert Head" })
vim.keymap.set("n", "<localleader>W", f.paredit_wrap("(", ")", "inner_end"),
	{ desc = "Paredit Wrap Element Insert Tail" })
