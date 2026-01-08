-- lsp.lua

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "terraformls", "tflint" },
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
if pcall(require, 'cmp_nvim_lsp') then
    capabilities = require('cmp_nvim_lsp').default_capabilities()
end

vim.lsp.enable('teraformls', {
    capabilities = capabilities,
})

vim.lsp.enable('vtsls', {
    capabilities = capabilities,
})

---------------------------------------------------------
-- Format on save for Go
---------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
	local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    -- buf_request_sync defaults to a 1000ms timeout. Depending on your
    -- machine and codebase, you may want longer. Add an additional
    -- argument after params if you find that you have to write the file
    -- twice for changes to be saved.
    -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    vim.lsp.buf.format({async = false})
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.tf", "*.tfvars", "*.tftpl" },
  callback = function()
    vim.bo.filetype = "terraform"
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.tf", "*.tfvars" },
  callback = function()
    vim.lsp.buf.format({async = false})
  end,
})

---------------------------------------------------------
-- gopls configuration
---------------------------------------------------------
vim.lsp.config('gopls', {
  settings = {
	gopls = {
      buildFlags = { "-tags=wireinject,test" },
      ------------------------------------------
      -- Enable goimports style import fixing
      ------------------------------------------
      gofumpt = true,          -- optional: stricter formatting
      completeUnimported = true,
	  deepCompletion = true,
      usePlaceholders = true,

      -- extra features
      analyses = {
        unusedparams = true,
        nilness = true,
        unusedwrite = true,
        useany = true,
      },
      staticcheck = true,
    },
  },
})

vim.lsp.enable('gopls', {
  capabilities = capabilities,
})

vim.lsp.enable('eslint')


ShowHoverSignatureInCmdline = function()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if err or not result or not result.contents then
      return
    end

    local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    local signature

    for i, line in ipairs(lines) do
      -- Find the start of a Go code block
      if string.match(line, "^```go") then
        -- Check if there's a line after it
        if i + 1 <= #lines then
          signature = lines[i+1]
          -- We found what we need, so we can exit the loop
          break
        end
      end
    end

    if signature then
      -- Clear the command line and print the signature
      vim.cmd('echon ""')
      vim.api.nvim_echo({ {signature, "Normal"} }, false, {})
    end
  end)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { noremap = true, silent = true, buffer = ev.buf }

    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
    vim.keymap.set('n', '<space>i', ShowHoverSignatureInCmdline, { silent = true, buffer = true, desc = "Show hover info in cmdline" })

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

    -- show diagnostics
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  end,
})
