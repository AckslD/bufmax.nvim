local M = {}

local ss = require('neoclip.sorted_set')

local seen_buffers = ss.new({hash = function(buf) return buf end})

local get_listed_buf_info = function()
  local bufinfos = vim.fn.getbufinfo({buflisted = true, bufloaded = true})
  local bufinfo_per_buf = {}
  for _, bufinfo in ipairs(bufinfos) do
    bufinfo_per_buf[bufinfo.bufnr] = bufinfo
  end
  return bufinfo_per_buf
end

local filter = function(condition, things)
  local res = {}
  for _, thing in pairs(things) do
    if condition(thing) then
      table.insert(res, thing)
    end
  end
  return res
end

local filter_key_by_value = function(condition, map)
  local keys = {}
  for key, value in pairs(map) do
    if condition(value) then
      table.insert(keys, key)
    end
  end
  return keys
end

local set = function(lst)
  local s = {}
  for _, value in ipairs(lst) do
    s[value] = true
  end
  return s
end

local last_removed = {}

M.raw_info = function()
  local seen = seen_buffers:values()
  local listed = get_listed_buf_info()
  return {
    seen = seen,
    listed = filter_key_by_value(function(_) return true end, listed),
    seen_non_listed = filter(function(b) return listed[b] == nil end, seen),
    listed_non_hidden = filter_key_by_value(function(b) return b.hidden == 0 end, listed),
    listed_hidden = filter_key_by_value(function(b) return b.hidden ~= 0 end, listed),
    listed_removable = filter_key_by_value(function(b) return b.hidden ~= 0 and b.changed == 0 end, listed),
    listed_hidden_changed = filter_key_by_value(function(b) return b.hidden ~= 0 and b.changed ~= 0 end, listed),
  }
end

local info_field_order = {
  'seen',
  'listed',
  'seen_non_listed',
  'listed_non_hidden',
  'listed_hidden',
  'listed_removable',
  'listed_hidden_changed',
}

local formatted_info = function()
  local text = ""
  local info = M.raw_info()
  for _, key in ipairs(info_field_order) do
    local bufs = info[key]
    text = text .. string.format("%s (%d): %s\n", key, #bufs, vim.inspect(bufs))
  end
  return text
end

M.print_info = function()
  print(string.format(
    "BufMax:\n%s\n=========\nlast removed (%d): %s",
    formatted_info(),
    #last_removed,
    vim.inspect(last_removed)
  ))
end

M.setup = function(options)
  local keep_last = options.keep_last or 10
  local notify = options.notify
  print('notify', notify)
  local group = vim.api.nvim_create_augroup('BufMax', {clear = true})

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    desc = 'remove listed, hidden, unchanged buffers if reached threshold',
    callback = function(opts)
      local before
      if notify then
        before = formatted_info()
      end
      seen_buffers:insert(opts.buf)

      local listed = get_listed_buf_info()
      local hidden = set(filter_key_by_value(function(bi) return bi.hidden ~= 0 end, listed))
      -- list of hidden bufs where the first is the last seen
      local sorted_hidden = {}
      for _, buf in ipairs(seen_buffers:values({reversed = true})) do
        if listed[buf] == nil then
          seen_buffers:remove(buf)
        end
        if hidden[buf] ~= nil then
          hidden[buf] = nil
          table.insert(sorted_hidden, buf)
        end
      end
      -- add any missing ones to the end of the list
      for buf, _ in pairs(hidden) do
        table.insert(sorted_hidden, buf)
      end

      last_removed = {}
      for i, buf in ipairs(sorted_hidden) do
        if i > keep_last then
          local bufinfo = listed[buf]
          if bufinfo.changed == 0 then
            local success = pcall(vim.cmd.bdelete, buf)
            if success then
              table.insert(last_removed, buf)
              seen_buffers:remove(buf)
            else
              vim.notify(string.format('could not delete buf %d', buf))
            end
          end
        end
      end

      -- local n_to_remove = #hidden - keep_last
      -- if n_to_remove <= 0 then
      --   return
      -- end

      -- last_removed = {}
      -- local i = 0
      -- -- NOTE we only clear seen buffers, if others are created they are expected to be cleared on their own
      -- for _, buf in ipairs(seen_buffers:values()) do
      --   if i >= n_to_remove then
      --     break
      --   end
      --   local bufinfo = listed[buf]
      --   if bufinfo == nil then
      --     seen_buffers:remove(buf)
      --   elseif bufinfo.hidden ~= 0 and bufinfo.changed == 0 then
      --     local success = pcall(vim.cmd.bdelete, buf)
      --     if success then
      --       table.insert(last_removed, buf)
      --       seen_buffers:remove(buf)
      --       i = i + 1
      --     else
      --       vim.notify(string.format('could not delete buf %d', buf))
      --     end
      --   end
      -- end

      if notify then
        local after = formatted_info()
        vim.notify(string.format(
          "BufMax:\n%s\n---------\n%s\n=========\nlast removed (%d): %s",
          before,
          after,
          #last_removed,
          vim.inspect(last_removed)
        ))
      end
    end
  })
end

return M
