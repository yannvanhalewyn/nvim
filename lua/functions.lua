local M = {}

M.toggle_quickfix_window = function()
	local qf_exists = false

	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
		end
	end

	if qf_exists then
		vim.cmd.cclose()
	elseif not vim.tbl_isempty(vim.fn.getqflist()) then
		vim.cmd.copen()
	end
end

M.harpoon_quick_menu = function()
	local harpoon = require("harpoon")
	harpoon.ui:toggle_quick_menu(
		harpoon:list(),
		{ border = "rounded", title_pos = "center" }
	)
end

M.harpoon_select = function(n)
	return function()
		require("harpoon"):list():select(n)
	end
end

return M
