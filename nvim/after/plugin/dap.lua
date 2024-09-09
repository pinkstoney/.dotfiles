-- DAP configuration

local dap = require('dap')
local dapui = require("dapui")

-- Set up nvim-dap-virtual-text
require("nvim-dap-virtual-text").setup()

-- Set up nvim-dap-ui
dapui.setup()

-- Integrate dap-ui with dap
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- CodeLLDB configuration
dap.adapters.codelldb = {
  type = 'server',
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. '/mason/packages/codelldb/extension/adapter/codelldb',
    args = {"--port", "${port}"},
  }
}

-- Function to find executable in build directory
local function find_executable()
  local source_dir = vim.fn.expand('%:p:h')
  local files = vim.fn.globpath(source_dir, '*', false, true)
  for _, file in ipairs(files) do
    if vim.fn.executable(file) == 1 then
      return file
    end
  end
  return nil
end

-- DAP configuration for C++
dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      local exe = find_executable()
      if exe then
        return exe
      else
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

-- Use the same configuration for C debugging
dap.configurations.c = dap.configurations.cpp

-- Keymaps for debugging
vim.keymap.set('n', '<Leader>dc', function() require('dap').continue() end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
