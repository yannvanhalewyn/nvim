-- Default is only a single ; comment
vim.bo.commentstring = ";;%s"

-- Make Conjure eval commands non-repeatable with dot
-- We need to remap them to use :normal which doesn't get recorded
local function noremap_conjure(lhs, rhs, desc)
  vim.keymap.set('n', lhs, function()
    vim.cmd('normal ' .. rhs)
  end, { buffer = true, silent = true, desc = desc })
end

noremap_conjure('<localleader>ee', '<localleader>ee', 'Eval current form')
noremap_conjure('<localleader>er', '<localleader>er', 'Eval root form')
noremap_conjure('<localleader>ew', '<localleader>ew', 'Eval word')
noremap_conjure('<localleader>e!', '<localleader>e!', 'Eval and replace form')
noremap_conjure('<localleader>em', '<localleader>em', 'Eval marked form')
noremap_conjure('<localleader>ef', '<localleader>ef', 'Eval file')
noremap_conjure('<localleader>eb', '<localleader>eb', 'Eval buffer')
