local M = {}

function M.setup()
  local status_ok, dap = pcall(require, "dap")
  if not status_ok then
    return
  end

  -- DAP UI setup
  local dapui_status_ok, dapui = pcall(require, "dapui")
  if dapui_status_ok then
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
      mappings = {
        -- Use a table to apply multiple mappings
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      -- Use this to override the default layouts
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40, -- 40 columns
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
      controls = {
        -- Requires Neovim nightly (or 0.8 when released)
        enabled = true,
        -- Display controls in this element
        element = "repl",
        icons = {
          pause = "",
          play = "",
          step_into = "",
          step_over = "",
          step_out = "",
          step_back = "",
          run_last = "",
          terminate = "",
        },
      },
      floating = {
        max_height = nil, -- These can be integers or a float between 0 and 1.
        max_width = nil, -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil, -- Can be integer or nil.
        max_value_lines = 100, -- Can be integer or nil.
      }
    })

    -- Automatically open UI when debugging starts
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end

  -- Virtual text setup
  local dap_vt_status_ok, dap_vt = pcall(require, "nvim-dap-virtual-text")
  if dap_vt_status_ok then
    dap_vt.setup({
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      virt_text_pos = 'eol',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil
    })
  end

  -- Mason-nvim-dap setup
  local mason_dap_ok, mason_dap = pcall(require, "mason-nvim-dap")
  if mason_dap_ok then
    mason_dap.setup({
      automatic_installation = true,
      ensure_installed = {
        "python",
        "delve",  -- Go debugger
        "cpptools", -- C/C++ debugger
      },
    })
  end

  -- Set up language specific debugging
  
  -- Python configuration
  local dap_python_ok, dap_python = pcall(require, "dap-python")
  if dap_python_ok then
    -- Assuming python installation with Mason
    local mason_registry = require("mason-registry")
    local python_path = ""

    if mason_registry.is_installed("debugpy") then
      python_path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
    end

    dap_python.setup(python_path)
    dap_python.test_runner = "pytest"
  end

  -- Go configuration
  local dap_go_ok, dap_go = pcall(require, "dap-go")
  if dap_go_ok then
    dap_go.setup()
  end

  -- Lua configuration (for Neovim plugin development)
  dap.configurations.lua = {
    {
      type = "nlua",
      request = "attach",
      name = "Attach to running Neovim instance",
    }
  }

  dap.adapters.nlua = function(callback, config)
    callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
  end

  -- C/C++/Rust configuration with codelldb
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = "codelldb",
      args = {"--port", "${port}"},
    }
  }

  dap.configurations.cpp = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    },
  }

  -- Reuse cpp configuration for c and rust
  dap.configurations.c = dap.configurations.cpp
  dap.configurations.rust = dap.configurations.cpp

  -- JavaScript/TypeScript configuration
  dap.adapters.node2 = {
    type = "executable",
    command = "node",
    args = {vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js"},
  }

  dap.configurations.javascript = {
    {
      name = "Launch",
      type = "node2",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      protocol = "inspector",
      console = "integratedTerminal",
    },
    {
      name = "Attach to process",
      type = "node2",
      request = "attach",
      processId = require("dap.utils").pick_process,
    },
  }

  dap.configurations.typescript = dap.configurations.javascript

  -- Icons setup
  vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticSignWarn", linehl = "Visual", numhl = "DiagnosticSignWarn" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "⚪", texthl = "DiagnosticSignHint", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "DiagnosticSignInfo", linehl = "", numhl = "" })
  vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "DiagnosticSignInfo", linehl = "", numhl = "" })

  -- Configure C++ adapter (inside the M.setup function)
  local function setup_cpp_adapter()
    -- For cpptools (Microsoft's C++ extension)
    dap.adapters.cppdbg = {
      id = 'cppdbg',
      type = 'executable',
      command = vim.fn.stdpath('data') .. '/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
    }

    -- Base configuration for C++ debugging
    dap.configurations.cpp = {
      {
        name = "Launch file",
        type = "cppdbg",
        request = "launch",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        setupCommands = {
          {
            text = '-enable-pretty-printing',
            description =  'enable pretty printing',
            ignoreFailures = false
          },
        },
      },
      {
        name = 'Attach to gdbserver',
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerServerAddress = 'localhost:1234',
        miDebuggerPath = '/usr/bin/gdb',
        cwd = '${workspaceFolder}',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        setupCommands = {
          {
            text = '-enable-pretty-printing',
            description =  'enable pretty printing',
            ignoreFailures = false
          },
        },
      },
    }

    -- Copy the same config for C
    dap.configurations.c = dap.configurations.cpp
  end

  -- Add this to M.setup()
  setup_cpp_adapter()
end

return M 