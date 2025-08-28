-- Investigate this, becuase running 0.12 on old config,
-- `NVIM_APPNAME=nvim-nvchad v ...` still colorizes Clojure code decently. It
-- seems as thought many new highlight classes have been added somehow.

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

local function file_module()
  local icon = "󰈚"
  local path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(vim.g.statusline_winid))
  local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

  if name ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(name)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
  end

  local relative_path = vim.fn.expand("%:~:.")
  return "%#St_file# " .. icon .. " " .. abbreviate_path(relative_path) .. " " .. "%#St_file_sep#" .. ""
end

return {
  base46 = {
    -- onedark, catppuccin, tokyodark, everblush, jellybeans, rxyhn, yoru
    -- eveblush
    theme = "catppuccin",
    theme_toggle = { "catppuccin", "everforest_light" },
    hl_override = {
      -- ["@spell"] = { italic = true },
      ["@comment"] = { italic = true },
      -- ["@symbol"] = { fg = "blue" },
      -- ["@function"] = { fg = "yellow" },
      -- Used heavily by vim diff
      DiffAdd = { fg = "NONE", bg = "#31352b" },
      DiffDelete = { fg = "NONE", bg = "#511c21" },
      Pmenu = { bg = "NONE" },
      -- Part of changed line that actually changed
      DiffText = { fg = "NONE", bg = "#373b43", bold = true },
    },

    hl_add = {
      ["@function.call"] = { fg = "yellow" },

      -- Semantic higlights
      ["@lsp.type.type.clojure"] = { fg = "purple" },
      ["@lsp.type.keyword.clojure"] = { fg = "blue" },
      ["@lsp.type.function.clojure"] = { fg = "yellow" },
      ["@lsp.type.interface.clojure"] = { fg = "orange" },
      -- This is the ':' part of the keyword
      ["@string.special.symbol.clojure"] = { fg = "blue" },

      -- Deleted line in git status when not higlighted
      NeogitDiffDelete = { fg = "#e06c75" },
      -- Deleted line in git status when higlighted
      NeogitDiffDeleteHighlight = { link = "DiffDelete" },
      -- Shows 'midified' in yellow in git status
      NeogitChangeModified = { fg = "yellow" },
      -- Shows 'deleted' in red in git status
      NeogitChangeDeleted = { fg = "red" },
      --
      DiffviewDiffChange = { bg = "#2d3139" },
      DiffviewDiffAddAsDelete = { link = "DiffDelete" },
    },
  },
  ui = {
    tabufline = {
      enabled = false
    },
    statusline = {
      theme = "default",
      order = { "mode", "file", "%=", "lsp_msg", "lsp", "diagnostics", "cwd", "cursor" },
      modules = {
        file = file_module
      }
    }
  },
  colorify = {
    enabled = false
  }
}
