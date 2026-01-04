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

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

-- Rebase state machine
M.rebase_state = {
  active = false,
  step = nil,  -- 'source_type', 'destination_select', 'destination_type'
  change_id = nil,
  change_ids = {},  -- For multi-select
  source_type = nil,
  destination_id = nil,
  destination_type = nil,
}

-- Selection state
M.selected_changes = {}

-- Clear rebase state
local function clear_rebase_state()
  M.rebase_state = {
    active = false,
    step = nil,
    change_id = nil,
    change_ids = {},
    source_type = nil,
    destination_id = nil,
    destination_type = nil,
  }
end

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local function strip_ansi(str)
  return str:gsub("\27%[[0-9;]*m", "")
end

local function extract_change_id(line)
  local clean_line = strip_ansi(line)

  -- Try to extract change ID from jj log output
  -- Format: "◉  mrtwmypl yann.vanhalewyn@gmail.com 2026-01-03 22:53:01 02a96588"

  -- Pattern 1: Extract the first alphanumeric string after box-drawing/special chars
  local change_id = clean_line:match "^[^%w]*(%w+)%s+%S+@"

  -- Pattern 2: If that fails, try to get 8-char hex at the end of the line
  if not change_id then
    change_id = clean_line:match "(%x%x%x%x%x%x%x%x)%s*$"
  end

  -- Pattern 3: For lines with branch names, extract the first word
  if not change_id then
    change_id = clean_line:match "[│├└─╮╯]*%s*[◉○◆@]+%s+(%w+)"
  end

  return change_id
end

-- Higher-order function to wrap operations on the change under cursor
-- Extracts change ID, validates it, and calls the operation function
local function with_change_at_cursor(operation)
  return function()
    local line = vim.api.nvim_get_current_line()
    local change_id = extract_change_id(line)

    if change_id and #change_id >= 4 then
      operation(change_id)
    else
      vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
    end
  end
end

-- Run a jj command and handle result with callback
local function run_jj_command(args, on_success, on_error)
  local result = vim.system(args, { text = true }):wait()

  if result.code == 0 then
    if on_success then on_success(result) end
  else
    if on_error then
      on_error(result)
    else
      vim.notify("Command failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
    end
  end
end

-- Cleanup jj window and buffer
local function close_jj_window()
  if M.jj_buffer and vim.api.nvim_buf_is_valid(M.jj_buffer) then
    vim.api.nvim_buf_delete(M.jj_buffer, { force = true })
  end
  if M.jj_window and vim.api.nvim_win_is_valid(M.jj_window) then
    vim.api.nvim_win_close(M.jj_window, true)
  end
  M.jj_buffer = nil
  M.jj_window = nil
end

--------------------------------------------------------------------------------
-- Change operations
--------------------------------------------------------------------------------

-- Run jj describe for a change (opens editor buffer)
function M.describe(change_id)
  change_id = change_id or "@"

  -- Get current description
  run_jj_command(
    { "jj", "log", "--no-graph", "-r", change_id, "-T", "description" },
    function(result)
      local description = result.stdout or ""
      M._open_description_editor(change_id, description)
    end,
    function(result)
      vim.notify("Failed to get description: " .. (result.stderr or ""), vim.log.levels.ERROR)
    end
  )
end

function M._open_description_editor(change_id, description)
  local buf = vim.api.nvim_create_buf(false, false)
  local temp_file = vim.fn.tempname()

  -- Set buffer options
  vim.api.nvim_buf_set_name(buf, temp_file)
  vim.bo[buf].buftype = ''
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'jjdescription'

  -- Set content
  local lines = vim.split(description, "\n")
  local help_lines = { "", "JJ: Save and close or hit <C-C> <C-c> to update description, or :cq to abort" }
  vim.list_extend(lines, help_lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Open buffer in a split
  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.4))
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  -- Submit and abort handlers
  local function submit()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1 - #help_lines, false)
    local new_description = table.concat(content, "\n")

    run_jj_command(
      { "jj", "describe", "-r", change_id, "-m", new_description },
      function()
        vim.notify("Description updated for " .. change_id, vim.log.levels.INFO)
        vim.api.nvim_buf_delete(buf, { force = true })
        M.log()
      end
    )
  end

  local function abort()
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify("Aborted description edit", vim.log.levels.INFO)
  end

  -- Setup keymaps
  local keymap_opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", abort, vim.tbl_extend("force", keymap_opts, { desc = "JJ: Abort" }))
  vim.keymap.set("n", "ZZ", submit, vim.tbl_extend("force", keymap_opts, { desc = "JJ: Submit" }))
  vim.keymap.set("n", "<C-c><C-c>", submit, vim.tbl_extend("force", keymap_opts, { desc = "JJ: Submit" }))
  vim.keymap.set("i", "<C-c><C-c>", function()
    vim.cmd.stopinsert()
    submit()
  end, vim.tbl_extend("force", keymap_opts, { desc = "JJ: Submit" }))

  -- Handle :wq
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      submit()
      return true
    end
  })

  -- Cleanup temp file
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function() vim.fn.delete(temp_file) end
  })

  vim.cmd("startinsert")
end

-- Create a new change after the given change
function M.new_change(change_id)
  change_id = change_id or "@"

  run_jj_command(
    { "jj", "new", change_id },
    function()
      vim.notify("Created new change after " .. change_id, vim.log.levels.INFO)
      M.log()
    end
  )
end

-- Abandon a change
function M.abandon_change(change_id)
  vim.ui.input({
    prompt = string.format("Abandon change %s? (y/N): ", change_id:sub(1, 8))
  }, function(input)
    if not input or (input:lower() ~= "y" and input:lower() ~= "yes") then
      vim.notify("Abandon cancelled", vim.log.levels.INFO)
      return
    end

    run_jj_command(
      { "jj", "abandon", change_id },
      function()
        vim.notify("Abandoned change " .. change_id, vim.log.levels.INFO)
        M.log()
      end
    )
  end)
end

-- Edit (check out) a change
function M.edit_change(change_id)
  run_jj_command(
    { "jj", "edit", change_id },
    function()
      vim.notify("Checked out change " .. change_id, vim.log.levels.INFO)
      M.log()
    end
  )
end

--------------------------------------------------------------------------------
-- Rebase operations
--------------------------------------------------------------------------------

-- Start rebase flow - prompt for source type
function M.rebase_change(change_id)
  clear_rebase_state()
  M.rebase_state.active = true
  M.rebase_state.change_id = change_id
  M.rebase_state.step = 'source_type'
  
  local source_types = {
    { key = 'r', label = 'Revision (single change)', flag = '-r' },
    { key = 's', label = 'Source (subtree - change + descendants)', flag = '-s' },
    { key = 'b', label = 'Branch (all revisions in branch)', flag = '-b' },
  }
  
  vim.ui.select(source_types, {
    prompt = 'Rebase source type:',
    format_item = function(item)
      return string.format('%s - %s', item.key, item.label)
    end
  }, function(choice)
    if not choice then
      vim.notify("Rebase cancelled", vim.log.levels.INFO)
      clear_rebase_state()
      return
    end
    
    M.rebase_state.source_type = choice.key
    M._rebase_select_destination()
  end)
end

-- Step 2: Select destination change
function M._rebase_select_destination()
  M.rebase_state.step = 'destination_select'
  vim.notify("Select destination change (navigate with j/k, <CR> to select, <Esc> to cancel)", vim.log.levels.INFO)
  
  -- Set up temporary keymaps for destination selection
  if M.jj_buffer and vim.api.nvim_buf_is_valid(M.jj_buffer) then
    local opts = { buffer = M.jj_buffer, silent = true }
    
    -- Confirm destination selection
    vim.keymap.set("n", "<CR>", function()
      local line = vim.api.nvim_get_current_line()
      local dest_id = extract_change_id(line)
      
      if dest_id and #dest_id >= 4 then
        M.rebase_state.destination_id = dest_id
        -- Remove temporary keymaps
        vim.keymap.del("n", "<CR>", { buffer = M.jj_buffer })
        vim.keymap.del("n", "<Esc>", { buffer = M.jj_buffer })
        -- Continue to destination type selection
        M._rebase_select_destination_type()
      else
        vim.notify("Could not find change ID on current line", vim.log.levels.WARN)
      end
    end, opts)
    
    -- Cancel rebase
    vim.keymap.set("n", "<Esc>", function()
      vim.keymap.del("n", "<CR>", { buffer = M.jj_buffer })
      vim.keymap.del("n", "<Esc>", { buffer = M.jj_buffer })
      vim.notify("Rebase cancelled", vim.log.levels.INFO)
      clear_rebase_state()
    end, opts)
  end
end

-- Step 3: Select destination type
function M._rebase_select_destination_type()
  M.rebase_state.step = 'destination_type'
  
  local dest_types = {
    { key = 'd', label = 'Destination (onto - default)', flag = '-d' },
    { key = 'A', label = 'After destination', flag = '-A' },
    { key = 'B', label = 'Before destination', flag = '-B' },
  }
  
  vim.ui.select(dest_types, {
    prompt = 'Rebase destination type:',
    format_item = function(item)
      return string.format('%s - %s', item.key, item.label)
    end
  }, function(choice)
    if not choice then
      vim.notify("Rebase cancelled", vim.log.levels.INFO)
      clear_rebase_state()
      return
    end
    
    M.rebase_state.destination_type = choice.key
    M._rebase_execute()
  end)
end

-- Step 4: Execute rebase command
function M._rebase_execute()
  local state = M.rebase_state
  
  -- Build command arguments
  local args = { "jj", "rebase" }
  
  -- Add source flag
  if state.source_type == "r" then
    table.insert(args, "-r")
  elseif state.source_type == "s" then
    table.insert(args, "-s")
  elseif state.source_type == "b" then
    table.insert(args, "-b")
  end
  table.insert(args, state.change_id)
  
  -- Add destination flag
  if state.destination_type == "A" then
    table.insert(args, "-A")
  elseif state.destination_type == "B" then
    table.insert(args, "-B")
  elseif state.destination_type == "d" then
    table.insert(args, "-d")
  end
  table.insert(args, state.destination_id)
  
  -- Build confirmation message
  local source_type_name = ({ r = "revision", s = "source", b = "branch" })[state.source_type]
  local dest_type_name = ({ A = "after", B = "before", d = "onto" })[state.destination_type]
  local confirm_msg = string.format(
    "Rebase %s %s %s %s? (y/N): ",
    source_type_name,
    state.change_id:sub(1, 8),
    dest_type_name,
    state.destination_id:sub(1, 8)
  )
  
  vim.ui.input({ prompt = confirm_msg }, function(input)
    if not input or (input:lower() ~= "y" and input:lower() ~= "yes") then
      vim.notify("Rebase cancelled", vim.log.levels.INFO)
      clear_rebase_state()
      return
    end
    
    run_jj_command(args, function()
      vim.notify(string.format(
        "Rebased %s %s %s",
        source_type_name,
        state.change_id:sub(1, 8),
        dest_type_name,
        state.destination_id:sub(1, 8)
      ), vim.log.levels.INFO)
      clear_rebase_state()
      M.log()
    end, function(result)
      vim.notify("Rebase failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      clear_rebase_state()
    end)
  end)
end

--------------------------------------------------------------------------------
-- Log view and keymaps
--------------------------------------------------------------------------------

local function setup_log_keymaps(buf, original_window)
  local opts = { buffer = buf, silent = true }

  -- Helper to create keymap with description
  local function map(key, action, desc)
    vim.keymap.set("n", key, action, vim.tbl_extend("force", opts, { desc = "JJ: " .. desc }))
  end

  -- Open difftastic for change under cursor
  map("<CR>", with_change_at_cursor(function(change_id)
    if original_window and vim.api.nvim_win_is_valid(original_window) then
      vim.api.nvim_set_current_win(original_window)
    end
    vim.cmd("DifftTab " .. change_id)
  end), "Open Difft for change")

  -- Change operations
  map("d", with_change_at_cursor(M.describe), "Describe change")
  map("n", with_change_at_cursor(M.new_change), "New change after this")
  map("A", with_change_at_cursor(M.abandon_change), "Abandon change")
  map("e", with_change_at_cursor(M.edit_change), "Edit (check out) change")
  map("r", with_change_at_cursor(M.rebase_change), "Rebase change")

  -- Navigation
  map("j", "2j", "Move down 2 lines")
  map("k", "2k", "Move up 2 lines")

  -- Window management
  map("q", close_jj_window, "Close window")
  map("R", M.log, "Refresh log")
end

--------------------------------------------------------------------------------
-- Terminal command execution
--------------------------------------------------------------------------------

function M.run_command_in_terminal(args, title, setup_keymaps_fn)
  close_jj_window()

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

  pcall(vim.api.nvim_buf_set_name, M.jj_buffer, title or "[JJ]")
  vim.api.nvim_win_set_height(M.jj_window, math.floor(vim.o.lines * 0.4))

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

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

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
      if input then M.run(input) end
    end)
    return
  end

  local args = vim.split(args_str, "%s+")

  M.run_command_in_terminal(args, "JJ: " .. args_str, function(buf)
    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true, desc = "JJ: Close window" })
  end)
end

M.setup = function()
  vim.api.nvim_create_user_command("JJ", function(opts)
    if opts.args == "" or opts.args == "log" then
      M.log()
    else
      M.run(opts.args)
    end
  end, {
  nargs = "*",
  desc = "Run jj commands"
})
end

return M
