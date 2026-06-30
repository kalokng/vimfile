return {
  'mason-org/mason-lspconfig.nvim',
  dependencies = {
	'mason-org/mason.nvim',
  },
  config = function()
	require("mason").setup()
	require("mason-lspconfig").setup({
	  ensure_installed = { "terraformls", "tflint", 'julials', 'zls' },
	  handlers = {
		-- The first entry (without a key) is the default setup for all servers
		function(server_name)
		  require("lspconfig")[server_name].setup({})
		end,
	  },
	})
  end,
}
