-- Local plugin: git blame browser. Source lives in <repo>/gitblame.
-- Auto-imported by lazy.nvim (`{ import = "plugins" }` in lua/plugins/plugins.lua).

-- The config directory is usually a symlink into this repo, so resolve it before
-- walking up to the repository root; fall back to this file's own location.
local candidates = {
  vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath('config')), ':h') .. '/gitblame',
  vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h:h') .. '/gitblame',
  vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h') .. '/gitblame',
}
local dir = candidates[1]
for _, candidate in ipairs(candidates) do
  if vim.fn.isdirectory(candidate) == 1 then
    dir = candidate
    break
  end
end

return {
  dir = dir,
  name = 'gitblame',
  cmd = 'GitBlame', -- makes the command itself load the plugin, not only the key
  keys = {
    { '<leader>gb', '<cmd>GitBlame<cr>', desc = 'Git blame view of the current file' },
  },
  config = function()
    require('gitblame').setup({
      -- Rename tracking for the commit list; toggle at runtime with F.
      follow = false,
      -- Show the focus commit's +/- change markers; toggle at runtime with t.
      show_changes = true,
      -- Top commit-graph pane height as a ratio of the screen.
      top_ratio = 0.34,
      -- Width of the left blame-meta pane.
      meta_width = 37,
    })
  end,
}
