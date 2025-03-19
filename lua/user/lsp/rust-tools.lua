local M = {}

function M.setup()
    local status_ok, rust_tools = pcall(require, "rust-tools")
    if not status_ok then
        return
    end

    local opts = {
        tools = {
            -- Automatically set inlay hints (type hints)
            autoSetHints = true,
            
            -- Whether to show hover actions inside the hover window
            hover_with_actions = true,
            
            -- Experimental features that might change in the future
            -- see: https://github.com/simrat39/rust-tools.nvim#runnables
            runnables = {
                -- Whether to use telescope for selection menu or not
                use_telescope = true,
                
                -- Rest of the options are forwarded to telescope
                telescope_opts = {
                    previewer = false,
                },
            },
            
            -- Options same as lsp hover / vim.lsp.buf.hover()
            hover_actions = {
                -- Whether the hover action window gets automatically focused
                auto_focus = false,
            },
            
            -- Settings for showing the crate graph
            crate_graph = {
                backend = "x11",
                output = nil,
                full = true,
            },
        },
        
        -- All the opts to send to nvim-lspconfig
        server = {
            -- Get the language server options from our previous setup
            on_attach = require("user.lsp.handlers").on_attach,
            capabilities = require("user.lsp.handlers").capabilities,
            
            -- Add standalone file settings from the rust-analyzer settings
            settings = require("user.lsp.settings.rust_analyzer"),
            
            -- Additional rust-analyzer settings
            settings = {
                ["rust-analyzer"] = {
                    -- Enable experimental features
                    experimental = {
                        procAttrMacros = true,
                    },
                    -- Additional checkOnSave settings
                    checkOnSave = {
                        command = "clippy",
                        extraArgs = { "--all", "--all-features" },
                    },
                },
            },
        },
        
        -- Debugging settings
        dap = {
            adapter = {
                type = "executable",
                command = "lldb-vscode",
                name = "rt_lldb",
            },
        },
    }
    
    rust_tools.setup(opts)
end

return M 
