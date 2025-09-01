local components = {} -- statusline components

--- highlight pattern
-- This has three parts:
-- 1. the highlight group
-- 2. text content
-- 3. special sequence to restore highlight: %*
-- Example pattern: %#SomeHighlight#some-text%*
local hl_pattern = "%%#%s#%s%%*"

local function hl(hl_name, body)
  return hl_pattern:format(hl_name, body)
end

function _G._statusline_component(name)
  return components[name]()
end

components.diagnostic_status = function()
  if not rawget(vim, "lsp") then
    return ""
  end

  local err = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warn = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

  local err_segment = (err and err > 0) and hl("St_lspError", " " .. err .. " ") or ""
  local warn_segment = (warn and warn > 0) and hl("St_lspWarning", " " .. warn .. " ") or ""
  local hints_segment = (hints and hints > 0) and hl("St_lspHints", "󰛩 " .. hints .. " ") or ""
  local info_segment = (info and info > 0) and hl("St_lspInfo", "󰋼 " .. info .. " ") or ""

  return " " .. err_segment .. warn_segment .. hints_segment .. info_segment
end


function components.position()
  return hl_pattern:format("rainbow4","%3l:%-2c ")
end

local function abbreviate_path(path)
  local terms = {
    "src",
    "com",
    "arqiver"
  }

  local segments = {}
  for segment in path:gmatch("[^/]+") do
    table.insert(segments, segment)
  end

  for i, segment in ipairs(segments) do
    for _, term in ipairs(terms) do
      if segment == term then
        -- segments[i] = "%#Comment#" .. term:sub(1,1) .. "%#StatusLine#"
        segments[i] = term:sub(1, 1)
        break
      end
    end
  end

  return table.concat(segments, "/")
end

components.file_module = function()
  local icon = "󰈚"
  local path = vim.api.nvim_buf_get_name(0)
  local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

  if name ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(name)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
  end

  local relative_path = vim.fn.expand("%:~:.")
  return hl("St_file", " " .. icon .. " " .. abbreviate_path(relative_path) .. " %r%m") .. hl("St_file_sep", "")
end

components.cwd = function()
  if vim.o.columns > 85 then
    local cwd = vim.uv.cwd()
    local name = (cwd and (cwd:match("([^/\\]+)[/\\]*$") or cwd))
    return hl("St_cwd_sep_left", "") .. hl("St_cwd_icon", " 󰉋 ") .. hl("St_cwd_text", name .. " ") .. hl("St_file_sep", "")
  else
    return ""
  end
end

local state = { lsp_msg = "" }

components.lsp_msg = function()
  return vim.o.columns < 120 and "" or hl("St_lsp_msg", state.lsp_msg)
end

components.lsp_client = function()
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[vim.api.nvim_win_get_buf(0)] then
        return (vim.o.columns > 100 and hl("St_lspClient", "   LSP ~ " .. client.name .. " ") or "   LSP ")
      end
    end
  end

  return ""
end

local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥", "" }

vim.api.nvim_create_autocmd("LspProgress", {
  pattern = { "begin", "report", "end" },
  callback = function(args)
    if not args.data or not args.data.params then
      return
    end

    local data = args.data.params.value
    local progress = ""

    if data.percentage then
      local idx = math.max(1, math.floor(data.percentage / 10))
      local icon = spinners[idx]
      progress = icon .. " " .. data.percentage .. "%% "
    end

    local loaded_count = data.message and string.match(data.message, "^(%d+/%d+)") or ""
    local str = progress .. (data.title or "") .. " " .. (loaded_count or "")
    state.lsp_msg = data.kind == "end" and "" or str
    vim.cmd.redrawstatus()
  end
})

local statusline = {
  '%{%v:lua._statusline_component("file_module")%}',
  "%=",
  '%{%v:lua._statusline_component("lsp_msg")%}',
  "%=",
  '%{%v:lua._statusline_component("lsp_client")%}',
  '%{%v:lua._statusline_component("diagnostic_status")%}',
  '%{%v:lua._statusline_component("cwd")%} ',
  '%{%v:lua._statusline_component("position")%}'
}

vim.o.statusline = table.concat(statusline, '')
