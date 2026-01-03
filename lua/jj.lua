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
