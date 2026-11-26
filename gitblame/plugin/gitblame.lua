-- Loads :GitBlame. Safe to source twice.
if vim.g.loaded_gitblame then
  return
end
vim.g.loaded_gitblame = true

require('gitblame.config').set_highlights()

vim.api.nvim_create_user_command('GitBlame', function(opts)
  local ok, err = require('gitblame').open(opts.args ~= '' and opts.args or nil)
  if not ok then
    vim.notify('gitblame: ' .. tostring(err), vim.log.levels.ERROR)
  end
end, {
  nargs = '?',
  complete = 'file',
  desc = 'Browse the git history of a file (defaults to the current buffer)',
})
