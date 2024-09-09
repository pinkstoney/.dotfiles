-- LSP configuration

-- Setup recommended LSP keybindings
local function setup_lsp_keymaps(bufnr)
  local opts = {buffer = bufnr}
  local map = vim.keymap.set

  map('n', 'gd', vim.lsp.buf.definition, opts)
  map('n', 'K', vim.lsp.buf.hover, opts)
  map('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)
  map('n', '<leader>vd', vim.diagnostic.open_float, opts)
  map('n', '[d', vim.diagnostic.goto_next, opts)
  map('n', ']d', vim.diagnostic.goto_prev, opts)
  map('n', '<leader>vca', vim.lsp.buf.code_action, opts)
  map('n', '<leader>vrr', vim.lsp.buf.references, opts)
  map('n', '<leader>vrn', vim.lsp.buf.rename, opts)
  map('i', '<C-h>', vim.lsp.buf.signature_help, opts)
end

-- Autocommand to setup keymaps when an LSP attaches to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {clear = true}),
  callback = function(ev)
    setup_lsp_keymaps(ev.buf)
  end,
})

-- Setup Mason and Mason-lspconfig
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {'rust_analyzer', 'clangd'},
})

-- Get LSP capabilities for nvim-cmp
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Configure LSP servers
local lspconfig = require('lspconfig')

-- Default LSP setup function
local function default_lsp_setup(server_name)
  lspconfig[server_name].setup({
    capabilities = lsp_capabilities,
  })
end

-- Special setup for lua_ls
local function setup_lua_ls()
  lspconfig.lua_ls.setup({
    capabilities = lsp_capabilities,
    settings = {
      Lua = {
        runtime = {version = 'LuaJIT'},
        diagnostics = {globals = {'vim'}},
        workspace = {library = {vim.env.VIMRUNTIME}}
      }
    }
  })
end

-- Setup LSP servers
require('mason-lspconfig').setup_handlers({
  default_lsp_setup,
  lua_ls = setup_lua_ls,
})

-- Setup nvim-cmp
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Load VSCode-like snippets
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}),
    ['<C-n>'] = cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}),
    ['<C-y>'] = cmp.mapping.confirm({select = true}),
    ['<C-Space>'] = cmp.mapping.complete(),
  }),
  sources = cmp.config.sources({
    {name = 'nvim_lsp'},
    {name = 'luasnip', keyword_length = 2},
    {name = 'buffer', keyword_length = 3},
    {name = 'path'},
  }),
})

