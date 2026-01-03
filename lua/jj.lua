-- Custom jj integration for Neovim
--
-- Provides a simple interface for running jj commands and displaying results
-- in Neovim buffers with custom keymaps and highlighting.
--
-- Usage:
--   :JJ log           - Open interactive log view
--   :JJ <any command> - Run any jj command

local M = {}

-- Window and buffer tracking
M.jj_window = nil
M.jj_buffer = nil

-- Highlight group for jj log change lines
vim.api.nvim_set_hl(0, "JJLogChange", { link = "CursorLine" })

local function strip_ansi(str)
  return str:gsub("\27%[[0-9;]*m", "")
end

local function extract_change_id(line)
  local clean_line = strip_ansi(line)

  -- Try to extract change ID from jj log output
  -- Format: "◉  mrtwmypl yann.vanhalewyn@gmail.com 2026-01-03 22:53:01 02a96588"
  local change_id = nil

  -- Pattern 1: Extract the first alphanumeric string after box-drawing/special chars
  -- This matches the change ID like "mrtwmypl" which comes after "◉ " or "○ " etc.
  change_id = clean_line:match "^[^%w]*(%w+)%s+%S+@"

  -- Pattern 2: If that fails, try to get 8-char hex at the end of the line
  -- This matches commit hashes like "02a96588"
  if not change_id then
    change_id = clean_line:match "(%x%x%x%x%x%x%x%x)%s*$"
  end

  -- Pattern 3: For lines with branch names, extract the first word
  -- "│ ○  oxwquwxy yann.vanhalewyn@gmail.com ..." -> "oxwquwxy"
  if not change_id then
    change_id = clean_line:match "[│├└─╮╯]*%s*[◉○◆@]+%s+(%w+)"
  end

  return change_id
end

local function setup_log_keymaps(buf, original_window)
  local opts = { buffer = buf, silent = true }

  -- Open difftastic for change under cursor
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      -- Switch to original window before opening difft
      if original_window and vim.api.nvim_win_is_valid(original_window) then
        vim.api.nvim_set_current_win(original_window)
      end
      vim.cmd("DifftTab " .. change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end, vim.tbl_extend("force", opts, { desc = "JJ: Open Difft for change" }))

  -- Describe change
  vim.keymap.set("n", "d", function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      M.describe(change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end, vim.tbl_extend("force", opts, { desc = "JJ: Describe change" }))

  -- New change after this one
  vim.keymap.set("n", "n", function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      M.new_change(change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end, vim.tbl_extend("force", opts, { desc = "JJ: New change after this" }))

  -- Abandon change
  vim.keymap.set("n", "A", function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      M.abandon_change(change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end, vim.tbl_extend("force", opts, { desc = "JJ: Abandon change" }))

  -- Edit (check out) change
  vim.keymap.set("n", "e", function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      M.edit_change(change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end, vim.tbl_extend("force", opts, { desc = "JJ: Edit (check out) change" }))

  -- Move by 2 lines for easier navigation
  vim.keymap.set("n", "j", "2j", vim.tbl_extend("force", opts, { desc = "JJ: Move down 2 lines" }))
  vim.keymap.set("n", "k", "2k", vim.tbl_extend("force", opts, { desc = "JJ: Move up 2 lines" }))

  -- Close window and clean up buffer
  vim.keymap.set("n", "q", function()
    if M.jj_buffer and vim.api.nvim_buf_is_valid(M.jj_buffer) then
      vim.api.nvim_buf_delete(M.jj_buffer, { force = true })
    end
    M.jj_buffer = nil
    M.jj_window = nil
  end, vim.tbl_extend("force", opts, { desc = "JJ: Close window" }))

  -- Refresh log
  vim.keymap.set("n", "R", function()
    M.log()
  end, vim.tbl_extend("force", opts, { desc = "JJ: Refresh log" }))
end

-- Run jj describe for a change (opens editor buffer)
function M.describe(change_id)
  change_id = change_id or "@"
  
  -- Get current description using jj log
  local result = vim.system(
    { "jj", "log", "--no-graph", "-r", change_id, "-T", "description" },
    { text = true }
  ):wait()
  
  if result.code ~= 0 then
    vim.notify("Failed to get description: " .. (result.stderr or ""), vim.log.levels.ERROR)
    return
  end
  
  local description = result.stdout or ""
  
  -- Create a new buffer for editing
  local buf = vim.api.nvim_create_buf(false, false)
  local temp_file = vim.fn.tempname()
  
  -- Set buffer options to make it behave like a file
  vim.api.nvim_buf_set_name(buf, temp_file)
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'jjdescription')
  
  -- Split description into lines and set in buffer
  local lines = vim.split(description, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open buffer in a split
  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.4))
  
  -- Add help text at the bottom
  local help_lines = {
    "",
    "JJ: Save and close to update description, or :cq to abort",
  }
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, help_lines)
  
  -- Move cursor to first line
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  
  local aborted = false
  
  -- Setup keymaps
  local function submit()
    -- Get the buffer content (excluding help lines)
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1 - #help_lines, false)
    local new_description = table.concat(content, "\n")
    
    -- Write to temp file
    local file = io.open(temp_file, "w")
    if file then
      file:write(new_description)
      file:close()
    end
    
    -- Run jj describe with the message from file
    local describe_result = vim.system(
      { "jj", "describe", "-r", change_id, "-m", new_description },
      { text = true }
    ):wait()
    
    if describe_result.code == 0 then
      vim.notify("Description updated for " .. change_id, vim.log.levels.INFO)
    else
      vim.notify("Failed to update description: " .. (describe_result.stderr or ""), vim.log.levels.ERROR)
    end
    
    -- Close buffer
    vim.api.nvim_buf_delete(buf, { force = true })
    
    -- Refresh log
    M.log()
  end
  
  local function abort()
    aborted = true
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify("Aborted description edit", vim.log.levels.INFO)
  end
  
  -- Map q to abort, ZZ and C-c C-c to submit
  vim.keymap.set("n", "q", abort, { buffer = buf, silent = true, desc = "JJ: Abort" })
  vim.keymap.set("n", "ZZ", submit, { buffer = buf, silent = true, desc = "JJ: Submit" })
  vim.keymap.set("n", "<C-c><C-c>", submit, { buffer = buf, silent = true, desc = "JJ: Submit" })
  vim.keymap.set("i", "<C-c><C-c>", function()
    vim.cmd.stopinsert()
    submit()
  end, { buffer = buf, silent = true, desc = "JJ: Submit" })
  vim.keymap.set("n", "<leader>w", submit, { buffer = buf, silent = true, desc = "JJ: Submit" })
  
  -- Handle :wq and :x
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      submit()
      return true
    end
  })
  
  -- Cleanup temp file on exit
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      vim.fn.delete(temp_file)
    end
  })
  
  -- Start in insert mode
  vim.cmd("startinsert")
end

-- Create a new change after the given change
function M.new_change(change_id)
  change_id = change_id or "@"
  
  -- Run jj new
  local result = vim.system(
    { "jj", "new", change_id },
    { text = true }
  ):wait()
  
  if result.code == 0 then
    vim.notify("Created new change after " .. change_id, vim.log.levels.INFO)
    -- Refresh the log
    M.log()
  else
    vim.notify("Failed to create new change: " .. (result.stderr or ""), vim.log.levels.ERROR)
  end
end

-- Abandon a change
function M.abandon_change(change_id)
  -- Show confirmation prompt
  vim.ui.input({
    prompt = string.format("Abandon change %s? (y/N): ", change_id:sub(1, 8))
  }, function(input)
    if not input or (input:lower() ~= "y" and input:lower() ~= "yes") then
      vim.notify("Abandon cancelled", vim.log.levels.INFO)
      return
    end
    
    -- Run jj abandon
    local result = vim.system(
      { "jj", "abandon", change_id },
      { text = true }
    ):wait()
    
    if result.code == 0 then
      vim.notify("Abandoned change " .. change_id, vim.log.levels.INFO)
      -- Refresh the log
      M.log()
    else
      vim.notify("Failed to abandon change: " .. (result.stderr or ""), vim.log.levels.ERROR)
    end
  end)
end

-- Edit (check out) a change
function M.edit_change(change_id)
  -- Run jj edit
  local result = vim.system(
    { "jj", "edit", change_id },
    { text = true }
  ):wait()
  
  if result.code == 0 then
    vim.notify("Checked out change " .. change_id, vim.log.levels.INFO)
    -- Refresh the log
    M.log()
  else
    vim.notify("Failed to edit change: " .. (result.stderr or ""), vim.log.levels.ERROR)
  end
end

-- Run a jj command in a terminal buffer
function M.run_command_in_terminal(args, title, setup_keymaps_fn)
  -- Close existing window and buffer if open
  if M.jj_buffer and vim.api.nvim_buf_is_valid(M.jj_buffer) then
    vim.api.nvim_buf_delete(M.jj_buffer, { force = true })
  end
  if M.jj_window and vim.api.nvim_win_is_valid(M.jj_window) then
    vim.api.nvim_win_close(M.jj_window, true)
  end
  M.jj_buffer = nil
  M.jj_window = nil

  local cmd_args = { "jj", "--no-pager", "--color=always" }
  vim.list_extend(cmd_args, args)

  -- Build shell command
  local cmd_str = table.concat(vim.tbl_map(vim.fn.shellescape, cmd_args), " ")
  local shell_cmd = "sh -c " .. vim.fn.shellescape(cmd_str)

  -- Save original window
  local original_window = vim.api.nvim_get_current_win()

  -- Create terminal buffer
  vim.cmd("botright split term://" .. vim.fn.fnameescape(shell_cmd))

  M.jj_buffer = vim.api.nvim_get_current_buf()
  M.jj_window = vim.api.nvim_get_current_win()

  -- Set buffer name (use a unique name to avoid conflicts)
  local buf_name = title or "[JJ]"
  pcall(vim.api.nvim_buf_set_name, M.jj_buffer, buf_name)

  -- Resize window
  vim.api.nvim_win_set_height(M.jj_window, math.floor(vim.o.lines * 0.4))

  -- Setup keymaps
  if setup_keymaps_fn then
    setup_keymaps_fn(M.jj_buffer, original_window)
  end

  -- Auto-cleanup on buffer wipeout
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = M.jj_buffer,
    once = true,
    callback = function()
      M.jj_window = nil
      M.jj_buffer = nil
    end,
  })
end

-- Open jj log
function M.log(args)
  args = args or {}
  local log_args = { "log" }
  vim.list_extend(log_args, args)

  M.run_command_in_terminal(log_args, "JJ Log", setup_log_keymaps)
end

-- Run any jj command interactively
function M.run(args_str)
  if not args_str or args_str == "" then
    vim.ui.input({ prompt = "jj command: " }, function(input)
      if input then
        M.run(input)
      end
    end)
    return
  end

  local args = vim.split(args_str, "%s+")

  local setup_keymaps = function(buf)
    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true, desc = "JJ: Close window" })
  end

  M.run_command_in_terminal(args, "JJ: " .. args_str, setup_keymaps)
end

return M
