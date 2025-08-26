local M = {}

M.grep_current_word = function()
  local word = vim.fn.expand("<cword>")
  require("mini.pick").builtin.grep({ pattern = word })
end

M.grep_current_WORD = function()
  local word = vim.fn.expand("<cWORD>")
  require("mini.pick").builtin.grep({ pattern = word })
end

M.toggle_color_column = function()
  if vim.api.nvim_get_option_value("colorcolumn", {}) == "" then
    vim.api.nvim_set_option_value("colorcolumn", "80", {})
  else
    vim.api.nvim_set_option_value("colorcolumn", "", {})
  end
end

M.toggle_quickfix_window = function()
  local qf_exists = false

  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end

  if qf_exists then
    vim.cmd.cclose()
  elseif not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd.copen()
  end
end

M.show_todos = function()
  local obsidian_root_dir = "/Users/yannvanhalewyn/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
  local width = 80

  -- vim.cmd("vsplit " .. vim.fn.getcwd() .. "/todos.md")
  vim.cmd("vsplit " .. obsidian_root_dir .. "ArQiver/todos.md")
  vim.cmd("vertical resize " .. width)

  vim.keymap.set("n", "q", ":quit<CR>", { buffer = true, silent = true })
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.wrap = true
  vim.wo.linebreak = true
end

M.copy_file_reference = function()
  local filepath = vim.fn.expand('%')
  local line_num = vim.fn.line('.')
  local reference = filepath .. ':' .. line_num
  vim.fn.setreg('"', reference)
  print('Copied: ' .. reference)
end

M.harpoon_quick_menu = function()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(
    harpoon:list(),
    { border = "rounded", title_pos = "center" }
  )
end

M.harpoon_select = function(n)
  return function()
    require("harpoon"):list():select(n)
  end
end

-- Returns a function that will call 'cmd', and execute a recenter 'zz' if and
-- only if the new scroll position is outside of the original viewport.
-- This allows jumping commands to keep the scroll position when staying inside
-- the page, but recenters when jumping outside.
M.recenter_if_scrolled = function(cmd)
  return function()
    local win = vim.api.nvim_get_current_win()
    local top_line = vim.fn.line('w0')
    local bottom_line = vim.fn.line('w$')

    -- Execute the command
    if type(cmd) == "function" then
      cmd()
    else
      vim.api.nvim_command(cmd)
    end

    local new_line = vim.api.nvim_win_get_cursor(win)[1]

    -- If new_line is outside of original scope, recenter
    if new_line <= top_line or new_line >= bottom_line then
      vim.api.nvim_command('normal! zz')
    end
  end
end

M.paredit_wrap = function(l, r, placement)
  return function()
    local paredit = require("nvim-paredit")
    paredit.wrap.wrap_element_under_cursor(l, r)
  end
end

M.paredit_wrap_and_insert = function(l, r, placement)
  return function()
    local paredit = require("nvim-paredit")
    paredit.cursor.place_cursor(
      paredit.wrap.wrap_element_under_cursor(l, r),
      { placement = placement, mode = "insert" }
    )
  end
end

return M
