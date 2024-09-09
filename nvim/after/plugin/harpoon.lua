-- Harpoon configuration


local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Keymap for adding a file
vim.keymap.set("n", "<leader>a", mark.add_file)
-- Keymap for showing harpoon menu
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

-- Keymaps for switching between files
vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-j>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-l>", function() ui.nav_file(4) end)

