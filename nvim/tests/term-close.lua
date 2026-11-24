-- Run from the repository root: nvim --headless -u NONE -l nvim/tests/term-close.lua
local status
vim.api.nvim_create_autocmd("TermClose", {
  callback = function() status = vim.v.event.status end,
})
vim.cmd.source("nvim/ordinary.vim")

local function terminal(filetype, exit_code)
  status = nil
  vim.cmd.new()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].filetype = filetype
  assert(vim.fn.jobstart({ "sh", "-c", "exit " .. exit_code }, { term = true }) > 0)
  assert(vim.wait(3000, function() return status ~= nil end), "terminal did not exit")
  assert(status == exit_code)
  return vim.api.nvim_buf_is_loaded(buf)
end

assert(terminal("fzf", 0), "fzf-lua must handle its own terminal cleanup")
assert(not terminal("", 0), "successful ordinary terminals should still close")
assert(terminal("", 1), "failed ordinary terminals should stay open")
print("PASS: terminal cleanup skips fzf and preserves ordinary terminal behavior")
