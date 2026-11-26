-- Run from the repository root: nvim --headless -u NONE -l nvim/tests/file-jump.lua
vim.opt.runtimepath:prepend("nvim")
require("config.file-jump")

local file = vim.fn.tempname() .. "#example.txt"
assert(vim.fn.writefile({ "one", "two", "three" }, file) == 0)
for _, suffix in ipairs({ "#L3", ":3" }) do
  vim.cmd.enew()
  vim.api.nvim_set_current_line(file .. suffix)
  vim.bo.modified = false
  vim.cmd.normal({ args = { "gF" } })
  assert(vim.api.nvim_buf_get_name(0) == file, "wrong file for " .. suffix)
  assert(vim.fn.line(".") == 3, "wrong line for " .. suffix)
end
vim.fn.delete(file)
print("PASS: gF jumps for both #L3 and :3")
