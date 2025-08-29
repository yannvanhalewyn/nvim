--------------------------------------------------------------------------------
-- Options
-- Enable experimental message box: https://github.com/neovim/neovim/pull/27855
-- Disabled because it breaks vim.pack install
-- require('vim._extui').enable({})

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.signcolumn = "yes"
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.o.undofile = true
vim.o.splitright = true
vim.o.laststatus = 3 -- 2 for every window
vim.o.ignorecase = true
vim.g.mapleader = " "
vim.g.maplocalleader = ","

--------------------------------------------------------------------------------
-- Require Plugins

vim.pack.add({
  -- UI
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/catppuccin/nvim" },
  -- Editor
  { src = "https://github.com/tpope/vim-surround" },
  { src = "https://github.com/tpope/vim-repeat" },            -- Make surround repeatable
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" }, -- Used by Oil.nvim, NeoTree
  { src = "https://github.com/echasnovski/mini.pick" },
  { src = "https://github.com/saghen/blink.cmp",               version = vim.version.range("^1") },
  { src = "https://github.com/ThePrimeagen/harpoon",           version = "harpoon2" },
  { src = "https://github.com/mawkler/refjump.nvim" },        -- Jump LSP references in buffer with [r and ]r
  -- { src = "https://github.com/folke/which-key.nvim" },
  -- VCS
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/linrongbin16/gitlinker.nvim" },
  { src = "https://github.com/sindrets/diffview.nvim" },
  -- These packages are meant for usage with Jujutusu
  { src = "https://github.com/rafikdraoui/jj-diffconflicts" }, -- Better 2-way diff conflicts using Jujutusu
  { src = "https://github.com/julienvincent/hunk.nvim" },      -- Execute --interactive operations with Jujutusu
  -- Util
  { src = "https://github.com/nvim-lua/plenary.nvim" },        -- Required by Harpoon
  { src = "https://github.com/MunifTanjim/nui.nvim" },         -- Required by NeoTree
  { src = "https://github.com/MunifTanjim/nui.nvim" },         -- Required by clojure-test
  { src = "https://github.com/nvim-neotest/nvim-nio" },        -- Required by clojure-test
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  -- Clojure
  { src = "https://github.com/Olical/conjure" },
  { src = "https://github.com/julienvincent/nvim-paredit" },
  { src = "https://github.com/julienvincent/clojure-test.nvim" },
  { src = "https://github.com/NickvanDyke/opencode.nvim" },
  -- HTTP
  { src = "https://github.com/mistweaverco/kulala.nvim"}
})

--------------------------------------------------------------------------------
-- Picker and file trees

local minipick = require("mini.pick")
vim.ui.select = minipick.ui_select

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
  sources = {
    "filesystem",
    "buffers",
    "git_status",
    "document_symbols",
  },
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
  document_symbols = {
    follow_cursor = true
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
    preset = "none", -- frees up <C-y> and <C-e>
    ["<Tab>"] = { "select_and_accept", "fallback" },
    ["<C-q>"] = { "hide" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-d>"] = { "show_documentation", "hide_documentation" },
    ["<A-C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<A-C-f>"] = { "scroll_documentation_down", "fallback" },
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

vim.cmd.colorscheme("catppuccin")
vim.cmd(":hi statusline guibg=NONE")

local colors = require("catppuccin.palettes.mocha")

local overrides = {
  ["@function.call"] = { fg = "yellow" },
  -- Semantic higlights
  ["@lsp.type.namespace.clojure"] = { fg = "maroon" },
  ["@lsp.type.type.clojure"] = { fg = "teal" }, -- Namespace part of fn and kw
  ["@lsp.type.keyword.clojure"] = { fg = "blue" },
  ["@lsp.type.function.clojure"] = { fg = "yellow" },
  ["@lsp.type.interface.clojure"] = { fg = "teal" },
  -- This is the ':' part of the keyword
  ["@string.special.symbol.clojure"] = { fg = "blue" },
}

for hl_name, config in pairs(overrides) do
  local fg_hex = colors[config["fg"]]
  vim.cmd.highlight(hl_name .. " guifg=" .. fg_hex)
end

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
    enable = true,
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
  highlights = {
  	enable = false
  },
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
---@diagnostic disable-next-line: param-type-mismatch
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 140 })
  end,
})

-- Highlight LSP references after 300ms
vim.o.updatetime = 50
vim.cmd.highlight("LspReferenceText gui=underline guibg=NONE")
vim.cmd.highlight("LspReferenceRead gui=underline guibg=NONE")
vim.cmd.highlight("LspReferenceWrite gui=underline guibg=NONE")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight", event.buf) then
      vim.api.nvim_create_autocmd("CursorHold", {
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.document_highlight()
        end
      })

      vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.clear_references()
        end
      })
    end
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function ()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
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
paredit.setup({
  indent = {
    enabled = true
  }
})

require("clojure-test").setup({
  keys = {
    ui = {
      expand_node = { "l", "<Right>" },
      collapse_node = { "h", "<Left>" },
      go_to = { "<Cr>", "gd" },

      cycle_focus_forwards = "<Tab>",
      cycle_focus_backwards = "<S-Tab>",

      quit = { "q", "<Esc>" },
    },
  },
})

--------------------------------------------------------------------------------
-- Mappings

local f = require("functions")
local snippets = require("snippets")
local zen_mode = require("zen_mode")
-- require("rebalance_parens").setup({
--   filetypes = {'clojure', 'lisp', 'scheme', 'fennel'}
-- })

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

local kulala = require("kulala")
kulala.setup()

-- vim.keymap.set("n", "<leader>?", function() require("which-key").show({ global = false }) end, { desc = "Buffer Local Keymaps (which-key)" })

-- Files and buffers
vim.keymap.set("n", "<leader>so", ":update<CR> :source<CR>", { desc = "Source Current File" })
vim.keymap.set("n", "<leader>fs", ":write<CR>", { desc = "File Save"})
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "Code Format" })
vim.keymap.set("n", "<leader>hh", ":Pick help<CR>", { desc = "Help Help Tags"})
vim.keymap.set("n", "<leader>bb", ":Pick buffers<CR>", { desc = "Buffer Browse"})
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Buffer Delete" })
vim.keymap.set("n", "<leader> ", ":Pick files<CR>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", ":Pick files tool='git'<CR>", { desc = "Files Git" })
vim.keymap.set("n", "<leader>x", ":Pick grep_live<CR>", { desc = "Grep Live"})
vim.keymap.set("n", "<leader>'", ":Pick resume<CR>", { desc = "Resume Find" })
vim.keymap.set("n", "<leader>d", ":Oil<CR>", { desc = "Browse Directory" })
vim.keymap.set("n", "<leader>N", ":Neotree<CR>", { desc = "Neotree" })
vim.keymap.set("n", "<leader>nf", ":Neotree float<cr>", { desc = "Neotree Git Status" })
vim.keymap.set("n", "<leader>nd", ":Neotree document_symbols right<CR>", { desc = "Neotree Document Symbols" })
vim.keymap.set("n", "<leader>nb", ":Neotree buffers left<cr>", { desc = "Neotree Document Symbols" })
vim.keymap.set("n", "<leader>ng", ":Neotree git_status left<cr>", { desc = "Neotree Git Status" })
vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon Add File" })
vim.keymap.set("n", "<leader>H", f.harpoon_quick_menu, { desc = "Harpoon Quick Menu" })
vim.keymap.set("n", "<A-h>", f.harpoon_select(1), { desc = "Harpoon Browse File (1)" })
vim.keymap.set("n", "<A-j>", f.harpoon_select(2), { desc = "Harpoon Browse File (2)" })
vim.keymap.set("n", "<A-k>", f.harpoon_select(3), { desc = "Harpoon Browse File (3)" })
vim.keymap.set("n", "<A-l>", f.harpoon_select(4), { desc = "Harpoon Browse File (4)" })
vim.keymap.set("n", "<A-;>", f.harpoon_select(5), { desc = "Harpoon Browse File (5)" })
vim.keymap.set("n", "<leader>fw", f.grep_current_word, { desc = "Find Word at Point" })
vim.keymap.set("n", "<leader>fW", f.grep_current_WORD, { desc = "Find WORD at Point" })
vim.keymap.set("n", "gt", f.show_todos, { desc = "Go TODOs" })

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
vim.keymap.set('i', "<C-e>", snippets.expand_snippet, { desc = 'Snippet Expand' })
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP: Signature Help" })
vim.keymap.set('i', "(", "()<left>")
vim.keymap.set('i', "[", "[]<left>")
vim.keymap.set('i', "{", "{}<left>")
vim.keymap.set('i', '"', '""<left>')
vim.keymap.set("n", "+", "<C-a>", { desc = "Edit Increment" })
vim.keymap.set("n", "-", "<C-x>", { desc = "Edit Decrement" })
vim.keymap.set("n", "\\", ",", { desc = "Reverse f, t, F or T" }) -- Since ',' is the localleader

-- Editor
vim.keymap.set("n", "<esc>", ":noh<CR>", { silent = true })
vim.keymap.set("n", "<A-c>", f.toggle_color_column, { desc = "Toggle Color Column" })
vim.keymap.set("n", "<A-C>", ":set cursorcolumn!<CR>", { desc = "Toggle Cursor Highlight" })
vim.keymap.set("n", "gF", f.goto_file_and_lnum, { desc = "Goto file:linenumber at cursor"})
vim.keymap.set("n", "<leader>tz", zen_mode.toggle, { desc = "Toggle Zen Mode" })
vim.keymap.set("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "Toggle Relative number" })
vim.keymap.set("n", "<leader>tf", ":set formatexpr=<cr>", { desc = "Toggle Format Expression" })
vim.keymap.set("n", "<leader>i", ":Inspect<cr>", { desc = "Inspect Highlight" })

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
vim.keymap.set("n", "<leader>gf", f.open_current_file_in_revision, { desc = "Git visit file from revision", })

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

-- VCS
vim.keymap.set("n", "<leader>gd", ":DiffviewOpen<CR>", { desc = "Git Diff current index", })
vim.keymap.set("n", "<leader>gD", ":DiffviewOpen master...HEAD", { desc = "Git diff something else", })
vim.keymap.set("n", "<leader>gt", ":DiffviewFileHistory %<CR>", { desc = "Git Timemachine" })
vim.keymap.set("n", "<leader>gT", ":DiffviewFileHistory<CR>", { desc = "Git Timemachine" })

-- Code / Diagnostics
vim.keymap.set("n", "[e", function()
  vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "]e", function()
  vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, { desc = "Code Diagnostics" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Actions" })
vim.keymap.set("n", "<leader>cr", f.copy_file_reference, { desc = "Code Copy File Reference" })

-- Quickfix
vim.keymap.set("n", "<leader>tq", f.toggle_quickfix_window, { desc = "Toggle Quickfix Window" })
vim.keymap.set("n", "[q", f.recenter_if_scrolled("cprev"), { desc = "Quickfix Prev" })
vim.keymap.set("n", "]q", f.recenter_if_scrolled("cnext"), { desc = "Quickfix Next" })

-- CLojure / Lisps
vim.keymap.set("n", "<A-H>", paredit.api.slurp_backwards, { desc = "Paredit Slurp backwards" })
vim.keymap.set("n", "<A-J>", paredit.api.barf_backwards, { desc = "Paredit Barf backwards" })
vim.keymap.set("n", "<A-K>", paredit.api.barf_forwards, { desc = "Paredit Barf forwards" })
vim.keymap.set("n", "<A-L>", paredit.api.slurp_forwards, { desc = "Paredit Slurp forwards" })
vim.keymap.set("n", "<A-]>", f.paredit_wrap("[", "]"), { desc = "Paredit Wrap Element ]" })
vim.keymap.set("n", "<A-}>", f.paredit_wrap("{", "}"), { desc = "Paredit Wrap Element }" })
vim.keymap.set("n", "<A-)>", f.paredit_wrap("(", ")"), { desc = "Paredit Wrap Element )" })
vim.keymap.set("n", "<localleader>w", f.paredit_wrap_and_insert("( ", ")", "inner_start"), { desc = "Paredit Wrap Element Insert Head" })
vim.keymap.set("n", "<localleader>W", f.paredit_wrap_and_insert("(", " )", "inner_end"), { desc = "Paredit Wrap Element Insert Tail" })

local clj_test = require("clojure-test.api")
-- 'ta' is overwritten by Conjure. I don't think it's possible to only
-- disable one of them (see clojure/nrepl/init.fnl in Conjure) but we can
-- disable all of them using
-- vim.g["conjure#mapping#enable_defaults"] = false
-- And rebinding the defaults that I did use.
vim.keymap.set("n", "<localleader>tA", clj_test.run_all_tests, { desc = "Run all tests" })
vim.keymap.set("n", "<localleader>tt", clj_test.run_tests, { desc = "Run tests" })
vim.keymap.set("n", "<localleader>tf", clj_test.run_tests_in_ns, { desc = "Run tests in file" })
vim.keymap.set("n", "<localleader>tl", clj_test.rerun_previous, { desc = "Rerun the most recently run tests" })
vim.keymap.set("n", "<localleader>tL", clj_test.load_tests, { desc = "Find and load test namespaces in classpath" })
vim.keymap.set("n", "<localleader>!", function() clj_test.analyze_exception("*e") end, { desc = "Inspect the most recent exception" })

-- HTTP
vim.keymap.set("n", "<leader>he", kulala.run, { desc = "HTTP Execute Request" })
vim.keymap.set("n", "<leader>hse", kulala.set_selected_env, { desc = "HTTP Set Env" })

-- Opencode
vim.keymap.set("n", "<leader>aA", function() require('opencode').ask() end, { desc = "AI ask" })
vim.keymap.set("n", "<leader>aa", function() require('opencode').ask('@cursor: ') end, { desc = "AI ask about this" })
vim.keymap.set("v", "<leader>aa", function() require('opencode').ask('@selection: ') end, { desc = "AI Ask About selection" })
vim.keymap.set("n", "<leader>an", function() require('opencode').command('session_new') end, { desc = "AI New session" })
vim.keymap.set("n", "<leader>ay", function() require('opencode').command('messages_copy') end, { desc = "AI Copy last message" })
vim.keymap.set({ "n", "v" }, "<leader>ap", function() require('opencode').select_prompt() end, { desc = "Select prompt" })
vim.keymap.set("n", "<A-C-u>", function() require('opencode').command('messages_half_page_up') end, { desc = "Scroll messages up" })
vim.keymap.set("n", "<A-C-d>", function() require('opencode').command('messages_half_page_down') end, { desc = "Scroll messages down" })
