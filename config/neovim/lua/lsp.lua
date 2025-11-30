-- ========================
-- LSP and Completion Setup
-- ========================

local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local luasnip = require 'luasnip'
local cmp = require 'cmp'

-- ========================
-- on_attach function
-- ========================
local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, bufopts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>ce', vim.lsp.codelens.run, bufopts)
  vim.keymap.set('n', '<leader>cr', vim.lsp.codelens.refresh, bufopts)
  vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format { async = true }
  end, bufopts)

  -- Format before writing for certain filetypes
  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.go", "*.hs", "*.js", "*.ts", "*.tsx" },
    callback = function() vim.lsp.buf.format { async = false } end,
  })
end

-- ========================
-- Setup LSP servers
-- ========================

-- Go
lspconfig.gopls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    gopls = {
      buildFlags = { "-tags=unit,integration,functional,linux" },
    },
  },
})

-- Bash
lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Haskell
lspconfig.hls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "haskell", "lhaskell", "cabal" },
  settings = {
    haskell = {
      cabalFormattingProvider = "cabalfmt",
      formattingProvider = "ormolu",
    },
  },
})

-- Nix
lspconfig.nixd.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- JSON
lspconfig.jsonls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- YAML
lspconfig.yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Rust
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Lua
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
        Lua = {
          runtime = { version = 'LuaJIT' },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME },
          },
        },
      })
      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
    return true
  end,
})

-- ========================
-- TypeScript / JavaScript using ts_ls
-- ========================
lspconfig.ts_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascript", "javascriptreact" },
})

-- ========================
-- nvim-cmp setup
-- ========================
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = { { name = 'nvim_lsp' }, { name = 'luasnip' } },
})

