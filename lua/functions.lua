local M = {}

local function remove(list, pred)
  local filtered = {}
  for _, v in ipairs(list) do
    if not pred(v) then
      table.insert(filtered, v)
    end
  end
  return filtered
end

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

-- TODO make this work with visual mode, getting a range
M.copy_file_reference = function(registry)
  local filepath = vim.fn.expand('%')
  local line_num = vim.fn.line('.')
  local reference = filepath .. ':' .. line_num
  vim.fn.setreg(registry or '"', reference)
  print('Copied: ' .. reference)
end

-- If the cursor is on a 'filename:line-number' combination it will navigate to the
-- file at that linenumber.
-- Also works for filename without line-number. And for text between parenthesis.
M.goto_file_and_lnum = function()
  local word = vim.fn.expand("<cWORD>")

  -- Try to extract content from parenthesis if any
  local paren_context = word:match("%(([^%)]+)%)")
  print(paren_context)
  if paren_context then
    word = paren_context
  end

  local file, line_num = word:match("([^:]+):(%d+)")
  if file then
    vim.cmd('edit ' .. file)
    if line_num then
      vim.cmd(line_num)
    end
  end
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

-- Opens a sidepanel to local todo markdown files
-- Checks if there's a ,todos.md in the current project
-- If not opens ArQiver's todos.md in the Obsidian vault
-- Since that's a sizeable project with important information, I use this for
-- backup and access via mobile devices
M.show_todos = function()
  local obsidian_root_dir = "/Users/yannvanhalewyn/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
  local project_todos_file = vim.fn.getcwd() .. "/,todos.md"
  local width = 80

  local todos_file
  if vim.fn.filereadable(project_todos_file) == 0 then
    todos_file = obsidian_root_dir .. "ArQiver/todos.md"
  else
    todos_file = project_todos_file
  end

  vim.cmd("vsplit " .. todos_file)
  vim.cmd("vertical resize " .. width)

  vim.keymap.set("n", "q", ":quit<CR>", { buffer = true, silent = true })
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.wrap = true
  vim.wo.linebreak = true
end

M.open_current_file_in_revision = function()
  local current_filename = vim.fn.expand("%")
  vim.ui.input(
    { prompt = "Insert revision: ", default = "main" },
    function(revision)
      if revision then
        vim.cmd.new("[" .. revision .. "] " .. current_filename)
        vim.cmd("read !git show " .. revision .. ":" .. current_filename)
        vim.cmd("setlocal readonly nomodifiable buftype=nofile") -- bufhidden=wipe
        vim.keymap.set("n", "q", ":quit<CR>", { buffer = true, silent = true })
      end
    end
  )
end

M.paredit_wrap = function(l, r)
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

M.select_branch = function (cb)
  local result = vim.fn.systemlist("git branch")
  local branches = remove(
    vim.tbl_map(vim.trim, result),
    function(v)
      return v == "* (no branch)"
    end
  )

  if vim.v.shell_error ~= 0 or #branches == 0 then
    vim.notify("No brances found or not in a git repository", vim.log.levels.WARN)
    return
  end

  vim.ui.select(branches, { prompt = "Select branch", }, cb)
end

M.select_branch_for_diffview = function()
  local trunk_branch = vim.trim(vim.fn.system(
    "git remote show origin | grep 'HEAD branch' | cut -d' ' -f5"
  ))
  M.select_branch(function(choice)
    if choice then
      print("Diffing " .. trunk_branch .. ".." .. choice)
      vim.cmd("Difft " .. trunk_branch .. ".." .. choice)
    end
  end)
end

M.select_git_commit_for_diffview = function()
  local cmd = "git log --oneline --no-merges -n 100"
  local commits = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 or #commits == 0 then
    vim.notify("No git commits found or not in a git repository", vim.log.levels.WARN)
    return
  end

  vim.ui.select(commits, {
    prompt = "Select commit for DiffviewOpen:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      local hash = choice:match("^(%w+)")
      if hash then
        vim.cmd("Difft " .. hash) -- .. "^!")
      end
    end
  end)
end

M.align_to_pattern = function(pattern)
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  print("Running align from", start_line, end_line)

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local positions = {}
  for _, line in ipairs(lines) do
    local pos = line:find(pattern, 1, true)
    if pos then
      table.insert(positions, pos)
    end
  end

  if #positions == 0 then
    vim.notify("Pattern not found in selected lines", vim.log.levels.WARN)
    return
  end

  local max_pos = math.max(unpack(positions))

  local aligned_lines = {}
  for _, line in ipairs(lines) do
    print("searching", pattern, line)
    local pos = line:find(pattern, 1, true)
    if pos then
      print("Found match")
      local spaces_to_add = max_pos - pos
      local new_line = line:sub(1, pos - 1) .. string.rep(" ", spaces_to_add) .. line:sub(pos)
      table.insert(aligned_lines, new_line)
    else
      table.insert(aligned_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, aligned_lines)
end

M.align = function()
  vim.ui.input({ prompt = "Align to pattern: " }, function(pattern)
    if pattern and pattern ~= "" then
      M.align_to_pattern(pattern)
    end
  end)
end

return M
