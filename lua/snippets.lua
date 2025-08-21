local M = {}

local snippets = {
	global = {
		shebang = '#!/bin sh',
    },
	lua = {
		fun = "function ${1:name}(${2:args})\n\t$0\nend"
	}
};

M.expand_snippet = function()
	print("Expanding snippet")
	local line = vim.api.nvim_get_current_line()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	local word_start = col
	while word_start > 0 and line:sub(word_start, word_start):match('[%w_]') do
		word_start = word_start - 1
	end
	word_start = word_start + 1

	local trigger = line:sub(word_start, col)
	local filetype = vim.bo.filetype

	if snippets[filetype] and snippets[filetype][trigger] then
		vim.api.nvim_buf_set_text(0, row - 1, word_start - 1, row - 1, col, {""})
		vim.snippet.expand(snippets[filetype][trigger])
	else
		if vim.snippet.active() then
			vim.snippet.jump(1)
		end
	end

	return word_start
end

return M
