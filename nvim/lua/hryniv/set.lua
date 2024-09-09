-- Use block cursor
vim.opt.guicursor = ""

-- Enable line numbers
vim.opt.nu = true
--Enable relative line numbers
vim.opt.relativenumber = true

-- Set tab width to 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Enable smart indenting
vim.opt.smartindent = true

-- Disable line wrapping
vim.opt.wrap = false

-- Disable swap file
vim.opt.swapfile = false
-- Disable backup file
vim.opt.backup = false
-- Set undo directory
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- Enable persistent undo
vim.opt.undofile = true

-- Disable highlight search
vim.opt.hlsearch = false
-- Enable incremental search
vim.opt.incsearch = true

-- Enable true color support
vim.opt.termguicolors = true

-- Keep 8 lines above/below cursor when scrolling
vim.opt.scrolloff = 8
-- Disable sign column
vim.opt.signcolumn = "no"
-- Add '@' to the list of characters considered part of a file name
vim.opt.isfname:append("@-@")

-- Reduce update time to 50ms
vim.opt.updatetime = 50
