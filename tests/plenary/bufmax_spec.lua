local function escape_keys(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feedkeys(keys)
  vim.api.nvim_feedkeys(escape_keys(keys), 'xmt', true)
end

local function unload(name)
  for pkg, _ in pairs(package.loaded) do
    if vim.fn.match(pkg, name) ~= -1 then
      package.loaded[pkg] = nil
    end
  end
end

local function set_current_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
end

local function assert_current_lines(expected_lines)
  local current = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n')
  local expected = vim.fn.join(expected_lines, '\n')
  assert.are.equal(current, expected)
end

describe("bufmax", function()
  it("basic_usage", function()
    -- TODO need to figure out how to properly have delays between the commands, otherwise this won't work
    vim.cmd.edit('a')
    vim.cmd.edit('b')
    vim.cmd.edit('c')
    vim.cmd.edit('d')
    vim.cmd.edit('e')
    assert_equal_tables({}, vim.api.nvim_list_bufs())
  end)
end)
