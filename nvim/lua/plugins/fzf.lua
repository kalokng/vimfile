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

	local function file_directory(opts)
	  local name = opts.__CTX.bname
	  return name ~= "" and vim.fn.fnamemodify(name, ":p:h") or opts.cwd or vim.uv.cwd()
	end

	local function change_directory(opts, cwd)
	  local last_query = fzf.get_last_query()

	  local provider_name = opts.__resume_key or "files"
	  local is_grep_provider = provider_name:match("grep") ~= nil

	  local new_opts = {
		cwd = cwd,
	  }

	  if is_grep_provider then
		local call_opts = opts.__call_opts or {}
		local search = call_opts.search or opts.search or ""
		new_opts.search = search
		new_opts.no_esc = call_opts.no_esc or opts.no_esc

		-- Prefer current prompt text, then fall back to fzf's tracked last query.
		local fuzzy_query = opts.last_query or last_query

		-- Resume edge-case parity: only set `query` when non-empty.
		-- Empty query must be omitted so grep keeps `search` as its prompt value.
		if type(fuzzy_query) == "string" and #fuzzy_query > 0 and fuzzy_query ~= search then
		  new_opts.query = fuzzy_query
		end
	  else
		new_opts.query = last_query
	  end

	  if fzf[provider_name] then
		fzf[provider_name](new_opts)
	  else
		-- Extreme fallback
		fzf.files({ cwd = cwd, query = last_query })
	  end
	end

	local function climb_up(_, opts)
	  change_directory(opts, vim.fn.fnamemodify(opts.cwd or vim.uv.cwd(), ":h"))
	end

	local function go_to_file_directory(_, opts)
	  change_directory(opts, file_directory(opts))
	end
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
		["alt-p"]   = go_to_file_directory,
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
		["alt-p"]   = go_to_file_directory,
	  }
	}
	local custom_keymap = require('fzf-lua').defaults.keymap
	custom_keymap.fzf["ctrl-q"] = "select-all+accept"

	local function live_grep_with_filetypes(call_opts)
	  local base_opts = vim.deepcopy(call_opts or {})
	  local initial_search = base_opts.search or base_opts.query or ""
	  base_opts.search = nil
	  base_opts.query = nil

	  local state = {
		grep = initial_search,
		filetypes = "",
		fuzzy = "",
		active_mode = "grep",
		return_mode = "grep",
	  }

	  local open_grep, open_fuzzy, open_filetypes

	  local function last_query(fallback)
		local query = fzf.get_last_query()
		return type(query) == "string" and query or fallback
	  end

	  local function parse_filetypes(value, opts)
		local args = {}
		local globs = {}

		for filter in value:gmatch("[^,]+") do
		  filter = vim.trim(filter)
		  if filter ~= "" then
			local glob
			if filter:sub(1, 1) == "." then
			  glob = "*" .. filter
			elseif not filter:find(".", 1, true)
				and not filter:find("*", 1, true)
				and not filter:find("?", 1, true)
				and not filter:find("/", 1, true)
				and not filter:find("\\", 1, true) then
			  glob = "*." .. filter
			else
			  glob = filter
			end
			table.insert(globs, glob)
			table.insert(args, opts.glob_flag .. " " .. vim.fn.shellescape(glob))
		  end
		end

		return table.concat(args, " "), globs
	  end

	  local function grep_glob_fn(query, opts)
		local args, globs = parse_filetypes(state.filetypes, opts)
		return query, args, globs
	  end

	  local function filetype_glob_fn(query, opts)
		local args, globs = parse_filetypes(query, opts)
		-- Avoid scanning every line when filetypes are entered before a grep query.
		local search = state.grep ~= "" and state.grep or "$^"
		return search, args, globs
	  end

	  local function picker_opts(extra)
		return vim.tbl_deep_extend("force", vim.deepcopy(base_opts), {
		  multiprocess = false,
		  rg_glob = true,
		  glob_separator = "^",
		  no_esc = true,
		}, extra)
	  end

	  local function capture_active_query()
		if state.active_mode == "grep" then
		  state.grep = last_query(state.grep)
		elseif state.active_mode == "fuzzy" then
		  state.fuzzy = last_query(state.fuzzy)
		else
		  state.filetypes = last_query(state.filetypes)
		end
	  end

	  local function reopen_active()
		if state.active_mode == "grep" then
		  open_grep()
		elseif state.active_mode == "fuzzy" then
		  open_fuzzy()
		else
		  open_filetypes()
		end
	  end

	  local function enter_filetypes()
		capture_active_query()
		state.return_mode = state.active_mode
		open_filetypes()
	  end

	  local function toggle_grep_fuzzy()
		capture_active_query()
		if state.active_mode == "grep" then
		  open_fuzzy()
		else
		  open_grep()
		end
	  end

	  local function climb_parent()
		capture_active_query()
		local cwd = base_opts.cwd or vim.uv.cwd()
		local parent = vim.fn.fnamemodify(cwd, ":h")
		if parent ~= cwd then
		  base_opts.cwd = parent
		end
		reopen_active()
	  end

	  local function toggle_option(name)
		return function(_, opts)
		  capture_active_query()
		  base_opts[name] = not opts[name]
		  reopen_active()
		end
	  end

	  local function mode_actions()
		local picker_actions = vim.deepcopy(custom_actions.grep)
		picker_actions["ctrl-p"] = { fn = climb_parent, reuse = true, header = "parent directory" }
		picker_actions["alt-p"] = {
		  fn = function(_, opts)
			capture_active_query()
			base_opts.cwd = file_directory(opts)
			reopen_active()
		  end,
		  reuse = true,
		  header = "current file directory",
		}
		picker_actions["alt-i"] = { fn = toggle_option("no_ignore"), reuse = true, header = "toggle ignore" }
		picker_actions["alt-h"] = { fn = toggle_option("hidden"), reuse = true, header = "toggle hidden" }
		picker_actions["alt-f"] = { fn = toggle_option("follow"), reuse = true, header = "toggle follow" }
		return picker_actions
	  end

	  local function main_actions()
		local picker_actions = mode_actions()
		picker_actions["ctrl-g"] = {
		  fn = toggle_grep_fuzzy,
		  reuse = true,
		  header = "toggle grep/fuzzy",
		}
		picker_actions["alt-t"] = {
		  fn = enter_filetypes,
		  reuse = true,
		  header = "edit filetypes",
		}
		return picker_actions
	  end

	  open_grep = function()
		state.active_mode = "grep"
		fzf.live_grep(picker_opts({
		  search = state.grep,
		  prompt = "Grep> ",
		  rg_glob_fn = grep_glob_fn,
		  actions = main_actions(),
		}))
	  end

	  open_fuzzy = function()
		state.active_mode = "fuzzy"
		fzf.grep(picker_opts({
		  search = state.grep ~= "" and state.grep or "$^",
		  query = state.fuzzy,
		  prompt = "Fuzzy> ",
		  rg_glob_fn = grep_glob_fn,
		  actions = main_actions(),
		}))
	  end

	  open_filetypes = function()
		state.active_mode = "filetype"
		local picker_actions = mode_actions()
		picker_actions["ctrl-g"] = false
		picker_actions["alt-t"] = {
		  fn = function()
			state.filetypes = last_query(state.filetypes)
			if state.return_mode == "fuzzy" then
			  open_fuzzy()
			else
			  open_grep()
			end
		  end,
		  reuse = true,
		  header = "return to search",
		}

		local opts = {
		  search = state.filetypes,
		  prompt = "Filetype> ",
		  exec_empty_query = true,
		  rg_glob_fn = filetype_glob_fn,
		  actions = picker_actions,
		}
		if state.return_mode == "fuzzy" and state.fuzzy ~= "" then
		  local preserve_fuzzy = "+transform-search(printf '%s\\n' " .. vim.fn.shellescape(state.fuzzy) .. ")"
		  opts.keymap = {
			fzf = {
			  start = preserve_fuzzy,
			  change = preserve_fuzzy,
			},
		  }
		end
		fzf.live_grep(picker_opts(opts))
	  end

	  open_grep()
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
	  live_grep_with_filetypes(opts)
	end

	function rg_git_root()
	  opts = {
		  prompt = 'rg> ',
		  cwd = get_git_root(),
		  actions = custom_actions.files,
		  previewer = "builtin",
		  keymap = fzf.defaults.keymap,
		  fzf_opts = {
			  ['--multi'] = '',
			  ['--bind'] = 'alt-a:toggle-all',
		  },
	  }
	  opts.fn_transform = function(x)
		return fzf.make_entry.file(x, opts)
	  end
	  fzf.fzf_live(function(args)
		return 'rg --column --color=always ' .. args[1]
	  end, opts)
	end

	vim.api.nvim_set_keymap("n", "<C-b>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".history()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-f>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-_>", [[<Cmd>lua require"fzf-lua".resume()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false})<CR>]], {})
	vim.api.nvim_set_keymap("v", "<C-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false,query=require"plugins.fzf".get_selection_escaped("en")})<CR>]], {})
	vim.api.nvim_set_keymap("n", "<M-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false,cwd=vim.fn.expand("%:p:h")})<CR>]], {})
	vim.api.nvim_set_keymap("v", "<M-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false,cwd=vim.fn.expand("%:p:h"),query=require"plugins.fzf".get_selection_escaped("en")})<CR>]], {})
	vim.keymap.set("n", "<C-l>", function()
	  live_grep_with_filetypes()
	end, { silent = true, desc = "Live grep" })
	vim.keymap.set("v", "<C-l>", function()
	  live_grep_with_filetypes({
		search = require("plugins.fzf").get_selection_escaped("en"),
	  })
	end, { silent = true, desc = "Live grep selection" })
	--vim.api.nvim_set_keymap("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<F1>", [[<Cmd>lua require"fzf-lua".help_tags()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<M-z>", [[<Cmd>lua require"fzf-lua".resume()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>f", [[<Cmd>lua require"fzf-lua".git_files()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>a", [[<Cmd>lua grep_git_root()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>A", [[<Cmd>lua rg_git_root()<CR>]], {})
	vim.api.nvim_set_keymap("n", "<Space>w", [[<Cmd>lua grep_git_root(vim.fn.expand("<cword>"))<CR>]], {})
	vim.api.nvim_set_keymap("v", "<Space>w", [[<Cmd>lua grep_git_root(require"plugins.fzf".get_selection_escaped("en"))<CR>]], {})

	vim.keymap.set({ "v", "i" }, "<C-x><C-f>",
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
	  keymap = custom_keymap,
	})
  end,
}
