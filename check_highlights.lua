-- Script to check highlight group colors
-- Run this in Neovim with :luafile check_highlights.lua

local function get_highlight_info(group_name)
  local hl = vim.api.nvim_get_hl(0, {name = group_name})
  print("Highlight group: " .. group_name)
  
  if next(hl) == nil then
    print("  No highlight defined")
    
    -- Check if it links to another group
    local ok, result = pcall(vim.api.nvim_get_hl_by_name, group_name, true)
    if ok and result.link then
      print("  Links to: " .. result.link)
      return get_highlight_info(result.link)
    end
    return nil
  end
  
  if hl.fg then
    print("  Foreground: #" .. string.format("%06x", hl.fg))
  end
  if hl.bg then
    print("  Background: #" .. string.format("%06x", hl.bg))
  end
  if hl.bold then print("  Bold: true") end
  if hl.italic then print("  Italic: true") end
  
  return hl
end

-- Check the specific highlight group you're interested in
get_highlight_info("@lsp.type.parameter.c")

-- Show available catppuccin colors for reference
print("\nCatppuccin Mocha colors available:")
local catppuccin = require("catppuccin.palettes").get_palette("mocha")
for name, color in pairs(catppuccin) do
  print("  " .. name .. ": " .. color)
end