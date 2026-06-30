local capabilities = vim.lsp.protocol.make_client_capabilities()
if pcall(require, 'cmp_nvim_lsp') then
    capabilities = require('cmp_nvim_lsp').default_capabilities()
end

-- `vim.lsp.enable()` only takes a config name and an optional boolean.
-- Put shared capabilities in the config layer so every server receives them.
vim.lsp.config('*', {
  capabilities = capabilities,
})

vim.lsp.enable('teraformls')

---------------------------------------------------------
-- vtsls configuration (TypeScript/JavaScript)
---------------------------------------------------------
-- vtsls advertises inlayHintProvider, and the LspAttach autocmd below
-- auto-enables hints on the Neovim side. The hint *kinds* are opt-in on
-- the TypeScript side: vtsls reads the flat VS Code keys
-- `typescript.inlayHints.*` / `javascript.inlayHints.*` (default: all off).
-- Note: keys must use the exact TS schema names (functionLikeReturnTypes,
-- enumMemberValues) -- the `vtsls.tsserver.inlayHints` path is ignored.
vim.lsp.config('vtsls', {
  settings = {
    typescript = {
      inlayHints = {
        parameterNames           = { enabled = 'all', suppressWhenArgumentMatchesName = true },
        parameterTypes           = { enabled = true },
        variableTypes            = { enabled = true, suppressWhenTypeMatchesName = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes  = { enabled = true },
        enumMemberValues         = { enabled = true },
      },
    },
    javascript = {
      inlayHints = {
        parameterNames           = { enabled = 'all', suppressWhenArgumentMatchesName = true },
        parameterTypes           = { enabled = true },
        variableTypes            = { enabled = true, suppressWhenTypeMatchesName = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes  = { enabled = true },
        enumMemberValues         = { enabled = true },
      },
    },
  },
})
vim.lsp.enable('vtsls')

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
-- Format on save for Zig
---------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.zig",
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

      -- gopls advertises inlay-hint support, but most Go hints are disabled
      -- unless they are explicitly enabled here.
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.enable('gopls')

---------------------------------------------------------
-- zls configuration (Zig)
---------------------------------------------------------
vim.lsp.config('zls', {
  settings = {
    zls = {
      -- Use the zig installed on PATH; set explicitly if needed:
      -- zig_exe_path = '/usr/bin/zig',
      enable_build_on_save = true,
      warn_style = true,
    },
  },
})
vim.lsp.enable('zls', {
  capabilities = capabilities,
})

vim.lsp.enable('eslint')

local function lsp_supports_inlay_hints(client, bufnr)
  if not client then
    return false
  end

  if client.supports_method then
    return client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr)
  end

  return client.server_capabilities and client.server_capabilities.inlayHintProvider ~= nil
end

local function buffer_supports_inlay_hints(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if lsp_supports_inlay_hints(client, bufnr) then
      return true
    end
  end

  return false
end

ToggleInlayHints = function(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())

  if not buffer_supports_inlay_hints(bufnr) then
    vim.notify("No LSP inlay hints available for this buffer", vim.log.levels.WARN)
    return
  end

  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
  vim.notify("Inlay hints " .. (enabled and "hidden" or "shown"))
end

vim.api.nvim_create_user_command("LspInlayHintsToggle", function()
  ToggleInlayHints(0)
end, { desc = "Toggle LSP inlay hints for the current buffer" })

vim.lsp.config('julials', {
    cmd = {
        "julia",
        "--project=".."~/.julia/environments/lsp/",
        "--startup-file=no",
        "--history-file=no",
        "-e", [[
            using Pkg
            Pkg.instantiate()
            using LanguageServer
        depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
        project_path = let
            dirname(something(
                ## 1. Finds an explicitly set project (JULIA_PROJECT)
                Base.load_path_expand((
                    p = get(ENV, "JULIA_PROJECT", nothing);
                        p === nothing ? nothing : isempty(p) ? nothing : p
                    )),
                        ## 2. Look for a Project.toml file in the current working directory,
                        ##    or parent directories, with $HOME as an upper boundary
                        Base.current_project(),
                        ## 3. First entry in the load path
                        get(Base.load_path(), 1, nothing),
                        ## 4. Fallback to default global environment,
                        ##    this is more or less unreachable
                    Base.load_path_expand("@v#.#"),
                ))
            end
                    @info "Running language server" VERSION pwd() project_path depot_path
                    server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
        server.runlinter = true
            run(server)
        ]]
    },
    filetypes = { 'julia' },
    root_markers = { "Project.toml", "JuliaProject.toml" },
    settings = {}
})
vim.lsp.enable('julials')

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
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if lsp_supports_inlay_hints(client, ev.buf) then
      -- Auto-enable inlay hints for any server that advertises support
      -- (e.g. gopls, zls). Toggle manually with <leader>ih.
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      vim.keymap.set("n", "<leader>ih", function()
        ToggleInlayHints(ev.buf)
      end, { noremap = true, silent = true, buffer = ev.buf, desc = "Toggle inlay hints" })
    end

    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
    vim.keymap.set('n', '<space>i', ShowHoverSignatureInCmdline, { silent = true, buffer = true, desc = "Show hover info in cmdline" })

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'LSP signature help' })

    -- show diagnostics
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  end,
})
