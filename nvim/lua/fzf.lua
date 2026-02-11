local fzf = require('fzf-lua')
local actions = require('fzf-lua.actions')

local function climb_up(_, opts)
  local last_query = fzf.get_last_query()
  local current_cwd = opts.cwd or vim.uv.cwd()
  local parent_dir = vim.fn.fnamemodify(current_cwd, ":h")

  local provider_name = opts.__resume_key or "files"
  --vim.print(opts)
  --vim.print(fzf)
  vim.print(provider_name)
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

fzf.setup({
  files = {
	cwd_prompt = false,
  },
  -- Other configuration...
  actions = {
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
      ["ctrl-p"]  = climb_up,
	}
  }
})

vim.api.nvim_set_keymap("n", "<C-b>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".history()<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-k>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-_>", [[<Cmd>lua require"fzf-lua".resume()<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files({cwd_prompt=false})<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep()<CR>]], {})
vim.api.nvim_set_keymap("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
vim.api.nvim_set_keymap("n", "<F1>", [[<Cmd>lua require"fzf-lua".help_tags()<CR>]], {})
vim.api.nvim_set_keymap("n", "<Space>f", [[<Cmd>lua require"fzf-lua".git_files()<CR>]], {})

vim.keymap.set({ "n", "v", "i" }, "<C-x><C-f>",
  function() FzfLua.complete_path() end,
  { silent = true, desc = "Fuzzy complete path" })

-- Change the 'Files in' and '>' part to a specific color
vim.api.nvim_set_hl(0, "FzfLuaDirPart", { fg = "#ff9e64", bold = true, force = true })
vim.api.nvim_set_hl(0, "FzfLuaFilePart", { fg = "#9ece6a", bold = true, force = true })

