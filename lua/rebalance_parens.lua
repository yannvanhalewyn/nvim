local M = {}

-- Track if we're currently rebalancing to avoid infinite loops
local rebalancing = false

-- Count parentheses in text, respecting strings and comments
local function count_parens_smart(text)
  local open = 0
  local close = 0
  local in_string = false
  local in_comment = false
  local escape_next = false
  local i = 1

  while i <= #text do
    local char = text:sub(i, i)

    if escape_next then
      escape_next = false
    elseif char == '\\' and in_string then
      escape_next = true
    elseif char == '"' and not in_comment then
      in_string = not in_string
    elseif char == ';' and not in_string then
      in_comment = true
    elseif char == '\n' then
      in_comment = false
    elseif not in_string and not in_comment then
      if char == '(' then
        open = open + 1
      elseif char == ')' then
        close = close + 1
      end
    end

    i = i + 1
  end

  return open, close
end

local function find_insertion_point(lines)
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line:match('%S') and not line:match('^%s*;') then
      return i, #line
    end
  end
  return #lines, #lines[#lines]
end

local function remove_excess_closing_parens(lines, excess)
  local removed = 0

  for i = #lines, 1, -1 do
    if removed >= excess then break end

    local line = lines[i]
    local new_line = line

    while removed < excess and new_line:sub(-1) == ')' do
      new_line = new_line:sub(1, -2)
      removed = removed + 1
    end

    -- Remove trailing whitespace after removing parens
    new_line = new_line:gsub('%s+$', '')
    lines[i] = new_line

    -- If we've made the line empty, we might want to remove it entirely
    -- (but let's be conservative and just leave empty lines)
  end

  return removed
end

-- Main rebalancing function
local function rebalance_buffer()
  if rebalancing then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 0 then return end

  local text = table.concat(lines, '\n')
  local open, close = count_parens_smart(text)

  if open == close then return end

  rebalancing = true

  if open > close then
    -- Need to add closing parentheses
    local needed = open - close
    local insert_line, insert_col = find_insertion_point(lines)

    -- Add the closing parens to the appropriate line
    if insert_line <= #lines then
      lines[insert_line] = lines[insert_line] .. string.rep(')', needed)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end

  elseif close > open then
    -- Need to remove excess closing parentheses
    local excess = close - open
    local removed = remove_excess_closing_parens(lines, excess)

    if removed > 0 then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end
  end

  rebalancing = false
end

-- Set up autocommands for rebalancing
function M.setup(opts)
  opts = opts or {}
  local filetypes = opts.filetypes or {'clojure', 'lisp', 'scheme', 'fennel', 'janet'}
  local group = vim.api.nvim_create_augroup('ParenRebalancer', { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = '*',
    callback = function()
      local ft = vim.bo.filetype
      if vim.tbl_contains(filetypes, ft) then
        vim.defer_fn(rebalance_buffer, 50)
      end
    end,
  })
end

-- Toggle rebalancing on/off
function M.toggle()
  if rebalancing then
    vim.api.nvim_del_augroup_by_name('ParenRebalancer')
    print('Parentheses rebalancing disabled')
  else
    M.setup()
    print('Parentheses rebalancing enabled')
  end
end

return M
