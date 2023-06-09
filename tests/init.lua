vim.o.runtimepath = vim.o.runtimepath .. ',./rtps/plenary.nvim'
vim.o.runtimepath = vim.o.runtimepath .. ',./rtps/nvim-neoclip.lua'
vim.o.runtimepath = vim.o.runtimepath .. ',.'

_G.assert_equal_tables = function(tbl1, tbl2)
    assert(vim.deep_equal(tbl1, tbl2), string.format("%s ~= %s", vim.inspect(tbl1), vim.inspect(tbl2)))
end

require('bufmax').setup({max_buffers = 3})
