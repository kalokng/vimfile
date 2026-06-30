return {
	'neovim/nvim-lspconfig',
	'tpope/vim-sensible',
	'rust-lang/rust.vim',
	'junegunn/vim-easy-align',
	'jreybert/vimagit',
	'mbbill/undotree',
	'justinmk/vim-sneak',
	'inkarkat/vim-ingo-library',
	'inkarkat/vim-mark',
	'sindrets/diffview.nvim',
	'mileszs/ack.vim',
	'preservim/nerdtree',
	'ryanoasis/vim-devicons',
	'tpope/vim-eunuch',
	'will133/vim-dirdiff',
	'nvim-lua/plenary.nvim',
	'CopilotC-Nvim/CopilotChat.nvim',
	'nvim-treesitter/nvim-treesitter-textobjects',
	'petertriho/nvim-scrollbar',
	{
	  'folke/tokyonight.nvim',
	  lazy = false,
	  priority = 1000,
	  opts = { style = "moon" },
	},
	{
	  'ribru17/bamboo.nvim',
	  lazy = false,
	  priority = 1000,
	  config = function()
		require('bamboo').setup {
		  -- optional configuration here
		}
		require('bamboo').load()
	  end,
	},

  {
	'PProvost/vim-ps1',
	ft = 'ps1',
  },
  {
	"nicolasgb/jj.nvim",
	version = "*", -- Use latest stable release
	-- Or from the main branch (uncomment the branch line and comment the version line)
	-- branch = "main",
	config = function()
	  require("jj").setup({})
	end,
  }
}

