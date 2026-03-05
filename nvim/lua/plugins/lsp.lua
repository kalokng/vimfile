return {
  'mason-org/mason-lspconfig.nvim',
  dependencies = {
	'mason-org/mason.nvim',
  },
  config = function()
	require("mason").setup()
	require("mason-lspconfig").setup({
	  ensure_installed = { "terraformls", "tflint" },
	})
  end,
}
