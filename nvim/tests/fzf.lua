-- Run from the repository root: nvim --headless -u NONE -l nvim/tests/fzf.lua
local query, setup_opts, last
local fzf = {
  actions = {},
  defaults = { keymap = { fzf = {} } },
  get_last_query = function() return query end,
  setup = function(opts) setup_opts = opts end,
}
for _, provider in ipairs({ "files", "grep", "live_grep" }) do
  fzf[provider] = function(opts) last = { provider = provider, opts = opts } end
end
package.loaded["fzf-lua"] = fzf
package.loaded["fzf-lua.actions"] = {}
dofile("nvim/lua/plugins/fzf.lua").config()

local context = { bname = "/tmp/project with spaces/src/main.lua" }
query = "needle"
for _, provider in ipairs({ "files", "grep" }) do
  local opts = { cwd = "/tmp/elsewhere", __CTX = context, __resume_key = provider, search = "text" }
  setup_opts.actions[provider]["alt-p"]({}, opts)
  assert(last.provider == provider)
  assert(last.opts.cwd == "/tmp/project with spaces/src")
  assert(last.opts.query == "needle")
  if provider == "grep" then assert(last.opts.search == "text") end
  setup_opts.actions[provider]["ctrl-p"]({}, opts)
  assert(last.opts.cwd == "/tmp")
end
local source_dir = vim.fn.tempname()
assert(vim.fn.mkdir(source_dir) == 1)
vim.cmd.split()
local source_win = vim.api.nvim_get_current_win()
vim.cmd.lcd(vim.fn.fnameescape(source_dir))
local empty_buffer_dir = vim.fn.expand("%:p:h")
vim.cmd.wincmd("p")
setup_opts.actions.files["alt-p"]({}, { cwd = "/tmp", __CTX = { bname = "", winid = source_win } })
assert(last.opts.cwd == empty_buffer_dir, "unnamed buffers must use the source window's working directory")
vim.api.nvim_win_close(source_win, false)
assert(vim.fn.delete(source_dir, "d") == 0)

local rhs = vim.fn.maparg("<C-l>", "n", false, true)
rhs.callback()
local function act(key, value)
  query = value
  local opts = last.opts
  opts.__CTX = context
  opts.actions[key].fn({}, opts)
end
act("alt-p", "search text")
assert(last.provider == "live_grep" and last.opts.search == "search text")
assert(last.opts.cwd == "/tmp/project with spaces/src")
act("alt-t", "search text")
act("alt-p", "lua, .vim")
assert(last.opts.prompt == "Filetype> " and last.opts.search == "lua, .vim")
act("alt-t", "lua, .vim")
act("ctrl-g", "search text")
act("alt-p", "fuzzy text")
assert(last.provider == "grep" and last.opts.query == "fuzzy text")
assert(last.opts.search == "search text")
assert(last.opts.cwd == "/tmp/project with spaces/src")
local _, _, globs = last.opts.rg_glob_fn("search text", { glob_flag = "--glob" })
assert(vim.deep_equal(globs, { "*.lua", "*.vim" }), "filetype filters must survive directory changes")
print("PASS: picker Alt-P preserves file/grep queries, fuzzy mode and filetypes; Ctrl-P still climbs")

local outside = vim.fn.tempname()
local root = outside .. "/repo with spaces"
local subdir = root .. "/src"
assert(vim.fn.mkdir(subdir, "p") == 1)
assert(vim.system({ "git", "-C", root, "init", "--quiet" }):wait().code == 0)

vim.api.nvim_buf_set_name(0, subdir .. "/main.lua")
vim.fn.maparg("<M-r>", "n", false, true).callback()
assert(last.provider == "files" and last.opts.cwd == root)
assert(vim.fn.maparg("<M-r>", "v", false, true).callback)

query = "needle"
for _, provider in ipairs({ "files", "grep" }) do
  local action = setup_opts.actions[provider]["alt-r"]
  action({}, { cwd = subdir, __resume_key = provider, search = "text" })
  assert(last.provider == provider and last.opts.cwd == root and last.opts.query == "needle")
  action({}, { cwd = outside, __resume_key = provider })
  assert(last.opts.cwd == outside, "outside Git, keep the picker directory")
end

rhs.callback()
act("alt-t", "search text")
last.opts.cwd = subdir
act("alt-r", "lua, .vim")
assert(last.opts.cwd == root and last.opts.prompt == "Filetype> " and last.opts.search == "lua, .vim")
act("alt-t", "lua, .vim")
act("ctrl-g", "search text")
last.opts.cwd = subdir
act("alt-r", "fuzzy text")
assert(last.opts.cwd == root and last.provider == "grep" and last.opts.query == "fuzzy text")
assert(last.opts.search == "search text")
print("PASS: Alt-R uses the Git root and preserves picker mode and query")
