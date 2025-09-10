local highlight_autocmds = {}

highlight_autocmds[12] = 1
highlight_autocmds[3] = 2
highlight_autocmds[296] = 3
-- table.insert(highlight_autocmds, 12, 1)
-- table.insert(highlight_autocmds, 3, 2)
-- table.insert(highlight_autocmds, 296, 3)

print(vim.inspect(highlight_autocmds))

for buf, id in pairs(highlight_autocmds) do
  print(buf, id)
end
