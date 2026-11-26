vim.keymap.set("n", "gF", function()
  local ref = vim.fn.expand("<cfile>")
  local path, line = ref:match("^(.+)#L([1-9]%d*)$")
  if not path or ref:match("^%a[%w+%.%-]*://") then
    vim.cmd.normal({ args = { vim.v.count1 .. "gF" }, bang = true })
    return
  end
  vim.cmd("edit +" .. line .. " " .. vim.fn.fnameescape(path))
end, { desc = "Go to file and line (also supports #L)" })
