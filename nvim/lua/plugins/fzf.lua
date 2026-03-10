return {
  "ibhagwan/fzf-lua",
  -- optional: provides file icons
  dependencies = { "nvim-tree/nvim-web-devicons" },
  get_selection_escaped = function(flags)
	-- flags:
	--  "e" \  -> \\
	--  "n" \n -> \\n  for multi-lines visual selection
	--  "N" \n removed
	--  "V" \V added   for marking plain ^, $, etc.
	local save_a = vim.fn.getreg('a')
	vim.fn.execute('normal! "ay')
	local result = vim.fn.getreg('a')
	vim.fn.setreg('a', save_a)
	local i = 0
	for c in flags:gmatch"." do
	  if c == 'e' then
		result = vim.fn.escape(result, '\\')
	  elseif c == 'n' then
		result = vim.fn.substitute(result, '\\n', '\\\\n', 'g')
	  elseif c == 'N' then
		result = vim.fn.substitute(result, '\\n', '', 'g')
	  elseif c == 'V' then
		result = "\\V" .. result
	  end
	end
	return result
  end,
  config = function()
	local fzf = require('fzf-lua')
	local actions = require('fzf-lua.actions')

	local custom_actions = {
	  files = {
		["default"] = fzf.actions.file_edit_or_qf,
		["ctrl-s"]  = actions.file_split,
		["ctrl-v"]  = actions.file_vsplit,
		["ctrl-t"]  = actions.file_tabedit,
		["alt-q"]   = actions.file_sel_to_qf,
		["alt-Q"]   = actions.file_sel_to_ll,
		["alt-i"]   = actions.toggle_ignore,
		["alt-h"]   = actions.toggle_hidden,
		["alt-f"]   = actions.toggle_follow,
		["ctrl-p"]  = climb_up,
	  },
	  grep = {
		["default"] = fzf.actions.file_edit_or_qf,
		["ctrl-s"]  = actions.file_split,
		["ctrl-v"]  = actions.file_vsplit,
		["ctrl-t"]  = actions.file_tabedit,
		["alt-q"]   = actions.file_sel_to_qf,
		["alt-Q"]   = actions.file_sel_to_ll,
		["alt-i"]   = actions.toggle_ignore,
		["alt-h"]   = actions.toggle_hidden,
		["alt-f"]   = actions.toggle_follow,
		["ctrl-p"]  = climb_up,
	  }
	}

	local function climb_up(_, opts)
	  local last_query = fzf.get_last_query()
	  local current_cwd = opts.cwd or vim.uv.cwd()
	  local parent_dir = vim.fn.fnamemodify(current_cwd, ":h")

	  local provider_name = opts.__resume_key or "files"
	  --vim.print(opts)
	  --vim.print(fzf)
	  --vim.print(provider_name)
	  local new_opts = {
		cwd = parent_dir,
		query = last_query,
	  }
	  if provider_name == "grep" then
		new_opts.search = opts.__call_opts.search
	  end

	  if fzf[provider_name] then
		fzf[provider_name](new_opts)
	  else
		-- Extreme fallback
		fzf.files({ cwd = parent_dir, query = last_query })
	  end
	end

	local function get_git_root()
	  local out = vim.system({'git','rev-parse','--show-toplevel'}, {text = true}):wait()
	  if out.code ~= 0 then
		return ''
	  end
	  local root = vim.split(out.stdout, '\n')[1]
	  --if vim.fn.has('win32') then
	  return root
	end


	function grep_git_root(args)
	  local opts = {
		cwd = get_git_root(),
	  }
	  if args ~= nil then
		opts.query = args
	  end
	  fzf.live_grep(opts)
	end

	function rg_git_root()
	  fzf.fzf_live(
		function(args)
		  return 'rg --column --color=always ' .. args[1]
		end,
		{
		  prompt = 'rg> ',
		  cwd = get_git_root(),
		  actions = custom_actions.files,
		  previewer = "builtin",
		  keymap = fzf.defaults.keymap,
		}
	  )
	end

	vim.api.nvim_set_keymap("n", "<C-b>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".history()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-f>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-_>", [[<Cmd>lua require"fzf-lua".resume()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false})<CR>]], {})
	vim.api.nvim_set_keymap("v", "<C-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false,query=require"plugins.fzf".get_selection_escaped("en")})<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep()<CR>]], {})
	--vim.api.nvim_set_keymap("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<F1>", [[<Cmd>lua require"fzf-lua".help_tags()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>f", [[<Cmd>lua require"fzf-lua".git_files()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>a", [[<Cmd>lua grep_git_root()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>A", [[<Cmd>lua rg_git_root()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>w", [[<Cmd>lua grep_git_root(vim.fn.expand("<cword>"))<CR>]], {})
	vim.api.nvim_set_keymap("v", "<Space>w", [[<Cmd>lua grep_git_root(require"plugins.fzf".get_selection_escaped("en"))<CR>]], {})

	vim.keymap.set({ "n", "v", "i" }, "<C-x><C-f>",
	function() FzfLua.complete_path() end,
	{ silent = true, desc = "Fuzzy complete path" })

	vim.keymap.set({ "i" }, "<C-x><C-l>",
	function() FzfLua.complete_line() end,
	{ silent = true, desc = "Fuzzy complete line" })

	-- Change the 'Files in' and '>' part to a specific color
	vim.api.nvim_set_hl(0, "FzfLuaDirPart", { fg = "#ff9e64", bold = true, force = true })
	vim.api.nvim_set_hl(0, "FzfLuaFilePart", { fg = "#9ece6a", bold = true, force = true })

	require("fzf-lua").setup({
	  winopts = {
		fullscreen = true,
		preview = {
		  layout = 'vertical',
		  vertical = "up:45%",
		},
	  },
	  files = {
		cwd_prompt = false,
	  },
	  -- Other configuration...
	  actions = custom_actions,
	})
  end,
}
