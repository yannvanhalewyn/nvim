-- My own custom simple built zen mode
local M = {}

local function copy_table(t)
   local t2 = {}
   for k,v in pairs(t)
   do
      t2[k] = v
   end
   return t2
end


local inactive_zen_state = {
  active = false,
  original_settings = {},
  side_buffers = {}
}

local zen_state = copy_table(inactive_zen_state)

M.enter = function()
  if zen_state.active then
    return
  end

  -- Check if there's only one window
  if #vim.api.nvim_tabpage_list_wins(0) ~= 1 then
    print("Zen mode requires only one window to be open")
    return
  end

  print('') -- Clear the last message

  -- Store original settings
  zen_state.original_settings = {
    cursorline = vim.wo.cursorline,
    cursorcolumn = vim.wo.cursorcolumn,
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    signcolumn = vim.wo.signcolumn,
    foldcolumn = vim.wo.foldcolumn,
    wrap = vim.wo.wrap,
    linebreak = vim.wo.linebreak,
    spell = vim.wo.spell,
    laststatus = vim.o.laststatus,
    showtabline = vim.o.showtabline,
    cmdheight = vim.o.cmdheight,
    completion = vim.b.completion
  }

  -- Get current window and calculate split positions
  local current_win = vim.api.nvim_get_current_win()
  local win_width = vim.api.nvim_win_get_width(current_win)
  local target_width = 80
  local margin_width = math.floor((win_width - target_width) / 2)

  -- Only proceed if we have enough space
  if margin_width < 1 then
    print("Window too narrow for zen mode (need at least 82 characters)")
    return
  end

  -- Create left margin split
  vim.cmd('leftabove ' .. margin_width .. 'vsplit')
  local left_win = vim.api.nvim_get_current_win()
  local left_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(left_win, left_buf)
  zen_state.side_buffers.left = { win = left_win, buf = left_buf }

  -- Go back to main window
  vim.api.nvim_set_current_win(current_win)

  -- Create right margin split
  vim.cmd('rightbelow ' .. margin_width .. 'vsplit')
  local right_win = vim.api.nvim_get_current_win()
  local right_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(right_win, right_buf)
  zen_state.side_buffers.right = { win = right_win, buf = right_buf }

  -- Go back to main window
  vim.api.nvim_set_current_win(current_win)

  -- Configure side windows to be non-focusable and hidden
  for _, side in pairs(zen_state.side_buffers) do
    vim.api.nvim_set_option_value('winfixwidth', true, { win = side.win })
    vim.api.nvim_set_option_value('number', false, { win = side.win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = side.win })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = side.win })
    vim.api.nvim_set_option_value('foldcolumn', '0', { win = side.win })
    vim.api.nvim_set_option_value('cursorline', false, { win = side.win })
    vim.api.nvim_set_option_value('cursorcolumn', false, { win = side.win })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = side.buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = side.buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = side.buf })
  end

  -- Apply zen mode settings to main window
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.foldcolumn = '0'
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.spell = true
  vim.b.completion = false

  -- Hide UI elements
  vim.o.laststatus = 0  -- Hide status line
  vim.o.showtabline = 0 -- Hide tab line
  vim.o.cmdheight = 1   -- Minimal command line height

  zen_state.active = true
end

M.exit = function()
  if not zen_state.active then
    return
  end

  -- Close margins
  for _, side in pairs(zen_state.side_buffers) do
    if vim.api.nvim_win_is_valid(side.win) then
      vim.api.nvim_win_close(side.win, true)
    end
  end

  -- Restore original settings
  for setting, value in pairs(zen_state.original_settings) do
    if setting == 'laststatus' or setting == 'showtabline' or setting == 'cmdheight' then
      vim.o[setting] = value
    elseif setting == 'completion' then
      vim.b[setting] = value
    else
      vim.wo[setting] = value
    end
  end

  -- Reset state
  zen_state = copy_table(inactive_zen_state)

  print("Zen mode deactivated")
end

-- Function to toggle zen mode
M.toggle = function()
  if zen_state.active then
    M.exit()
  else
    M.enter()
  end
end

-- Create user commands
vim.api.nvim_create_user_command('ZenModeEnter', M.enter, {})
vim.api.nvim_create_user_command('ZenModeExit', M.exit, {})
vim.api.nvim_create_user_command('ZenModeToggle', M.toggle, {})

return M
