-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)

  -- Package manager
  use 'wbthomason/packer.nvim'

  -- Fuzzy finder
  use {
    'nvim-telescope/telescope.nvim', 
    tag = '0.1.8',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }

  -- Color scheme
  use ({
      'rose-pine/neovim',
      as = 'rose-pine',
      config = function()
          vim.cmd('colorscheme rose-pine')
      end
  })

  -- Syntax highlighting and code analysis 
  use( 'nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
  use( 'nvim-treesitter/playground' )
  
  -- Quick file navigation 
  use( 'theprimeagen/harpoon' )

  -- Visualize undo history
  use( 'mbbill/undotree' )

  -- Git integration
  use( 'tpope/vim-fugitive' )

  -- Easy setup for Language Servere Protocol
  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      { 'williamboman/mason.nvim' },             -- Portable package manager
      { 'williamboman/mason-lspconfig.nvim' },   -- Bridges mason with lspconfig
      { 'neovim/nvim-lspconfig' },               -- Collection of LSP configurations
      { 'hrsh7th/nvim-cmp' },                    -- Autocompletion 
      { 'hrsh7th/cmp-nvim-lsp' },                -- LSP source for nvim-cmp
      { 'L3MON4D3/LuaSnip' },                    -- Lua snippets
    }
  }

  -- Discord integration (they should know that you use vim)
  use { 'andweeb/presence.nvim' }

  -- Async library for plugins
  use { "nvim-neotest/nvim-nio" }

  -- UI for debugger
  use { 
    'rcarriga/nvim-dap-ui', 
    requires = {
      { "mfussenegger/nvim-dap" },               -- Debugger 
    } 
  }

  -- Bridge between mason and debugger
  use {
    'jay-babu/mason-nvim-dap.nvim',
    requires = {
      {'williamboman/mason.nvim'},
      {'mfussenegger/nvim-dap'},
    } 
  }

  -- Inline virtual text support for debugger
  use { "theHamsta/nvim-dap-virtual-text" }
end)
