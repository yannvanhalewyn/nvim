vim.keymap.set(
  "n", "q", "<cmd>cclose<CR>",
  { buffer = true, desc = "Quickfix Close", }
)

-- Easy :cdo rename with word at point
vim.keymap.set(
  "n", "<leader>cR", ":cdo s/<C-r><C-w>/<C-r><C-w>/gc<left><left><left>",
  { buffer = true, desc = "Quickfix Rename", }
)

-- Easy :cdo rename with confirm selected-text from visual mode.
vim.keymap.set(
  "v", "<leader>cR", "y:cdo s/<C-r>*/<C-r>*/gc<c-b><c-b><c-b>",
  { buffer = true, desc = "Quickfix Rename", }
)

vim.keymap.set(
  "n", "<", "<cmd>colder<CR>", { buffer = true, desc = "Quickfix Previous List", }
)

vim.keymap.set(
  "n", ">", "<cmd>cnewer<CR>", { buffer = true, desc = "Quickfix Next List", }
)
