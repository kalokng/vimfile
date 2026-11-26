-- Configuration, highlights and sign definitions for the gitblame view.
local M = {}

local defaults = {
  -- Start with `git log --follow` (rename tracking) enabled.
  follow = false,
  -- Start with the focus commit's +/- change markers visible.
  show_changes = true,
  -- Maximum height of the top commit-graph pane, as a ratio of the editor height.
  -- The pane shrinks to the number of commits, so a short history never wastes rows.
  top_ratio = 0.34,
  -- Width of the left blame-meta pane. It is fixed: the pane always shows an 8-digit
  -- hash and the full date, and the author column takes the space that is left over.
  meta_width = 37,
  -- Marker written in the left-most column of the focused commit row.
  focus_sign = '>',
  -- How many characters of the commit hash are shown in the graph pane.
  -- The left pane always shows 8.
  hash_length = 8,
  -- Column width reserved for the author name in the graph pane.
  author_width = 14,
  keymaps = {
    -- parent / child / toggles are bound in all three panes
    parent = 'p',
    child = 'P',
    toggle_changes = 't',
    toggle_follow = 'F',
    close = 'q',
    help = 'h',
    select = '<CR>', -- graph row / meta line -> focus that commit
    open_commit = 'o', -- open the full commit in a new tab
    next_change = ']c', -- content pane: next change of the focus commit
    prev_change = '[c', -- content pane: previous change of the focus commit
  },
}

local opts = vim.deepcopy(defaults)

function M.set_highlights()
  local links = {
    GitBlameIndicator = 'Special',
    GitBlameGraph = 'Comment',
    GitBlameHash = 'Statement',
    GitBlameAuthor = 'Identifier',
    GitBlameDate = 'Comment',
    GitBlameAdded = 'Added',
    GitBlameAddedLine = 'DiffAdd',
    GitBlameRemoved = 'Removed',
    GitBlameModified = 'DiffChange',
    GitBlameModifiedLine = 'DiffChange',
  }
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { default = true, link = link })
  end
  vim.api.nvim_set_hl(0, 'GitBlameFocus', { default = true, link = 'CursorLine' })
  vim.api.nvim_set_hl(0, 'GitBlameRemovedLine', {
    default = true, bg = '#652626', fg = '#ffffff', ctermbg = 1, ctermfg = 15,
  })
end

---@param user table?
function M.setup(user)
  opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user or {})
  M.set_highlights()
end

---@return table
function M.get()
  return opts
end

return M
