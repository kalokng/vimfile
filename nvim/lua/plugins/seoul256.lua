return {
  'junegunn/seoul256.vim',
  priority = 1000,
  config = function()
	vim.g.seoul256_background = 234
	vim.cmd.colorscheme("seoul256")
  end,
}
