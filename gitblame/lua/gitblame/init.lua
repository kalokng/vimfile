-- Public entry point: `require('gitblame')`.
local config = require('gitblame.config')
local view = require('gitblame.view')

local M = {}

---@param opts table? see gitblame/config.lua defaults
function M.setup(opts)
  config.setup(opts)
end

M.open = view.open
M.close = view.close
M.refresh = view.refresh
M.state = view.state
M.select = view.select
M.focus_commit = view.focus_commit
M.focus_parent = view.focus_parent
M.focus_child = view.focus_child
M.focus_line_commit = view.focus_line_commit
M.toggle_changes = view.toggle_changes
M.toggle_follow = view.toggle_follow
M.open_commit = view.open_commit
M.open_commit_at_cursor = view.open_commit_at_cursor
M.next_change = view.next_change
M.prev_change = view.prev_change

return M
