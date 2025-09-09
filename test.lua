local highlight_autocmds = {}

table.insert(highlight_autocmds, 1)
table.insert(highlight_autocmds, 2)
table.insert(highlight_autocmds, 3)

-- print(vim.inspect(highlight_autocmds))

for _, id in ipairs(highlight_autocmds) do
  print(id)
end
