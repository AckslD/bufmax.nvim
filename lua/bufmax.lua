local M = {}

local ss = require('neoclip.sorted_set')

local seen_buffers = ss.new({hash = function(buf) return buf end})

local get_listed_bufs = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- TODO does buflisted imply loaded?
    if vim.fn.buflisted(buf) == 1 and vim.api.nvim_buf_is_loaded(buf) then
      table.insert(bufs, buf)
    end
  end
  return bufs
end

local is_removable = function(buf)
  local buf_infos = vim.fn.getbufinfo(buf)
  if #buf_infos == 0 then
    return false
  end
  local buf_info = buf_infos[1]
  return buf_info.hidden ~= 0 and buf_info.changed == 0
end

local is_listed = function(buf)
  return vim.fn.buflisted(buf) ~= 0
end

M.setup = function(options)
  local max_buffers = options.max_buffers
  local group = vim.api.nvim_create_augroup('BufMax', {clear = true})

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    desc = 'remove listed, hidden, unchanged buffers if reached threshold',
    callback = function(opts)
      seen_buffers:insert(opts.buf)

      local listed_bufs = get_listed_bufs()
      local n_to_remove = #listed_bufs - max_buffers
      if n_to_remove <= 0 then
        return
      end

      local i = 0
      -- NOTE we only clear seen buffers, if others are created they are expected to be cleared on their own
      for _, buf in ipairs(seen_buffers:values()) do
        if i >= n_to_remove then
          break
        end
        if not is_listed(buf) then
          seen_buffers:remove(buf)
        elseif is_removable(buf) then
          vim.cmd.bdelete(buf)
          seen_buffers:remove(buf)
          i = i + 1
        end
      end
    end
  })
end

return M
