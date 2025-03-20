local M = {}

function M.setup()
    local status_ok, rust_tools = pcall(require, "rust-tools")
    if not status_ok then
        return
    end
    
    -- Custom on_attach function for Rust that includes RustHoverActions keybind
    local rust_on_attach = function(client, bufnr)
        -- Call the default on_attach first
        require("user.lsp.handlers").on_attach(client, bufnr)
        
        -- Add RustHoverActions keybind
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rh", "<cmd>RustHoverActions<CR>", opts)
    end

    local opts = {
        tools = {
            -- Automatically set inlay hints (type hints)
            autoSetHints = true,
            
            -- Remove deprecated option
            -- hover_with_actions = true,
            
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
            -- Use our custom on_attach with the RustHoverActions keybind
            on_attach = rust_on_attach,
            capabilities = require("user.lsp.handlers").capabilities,
            
            -- Merge settings from the rust-analyzer settings file and additional settings
            settings = vim.tbl_deep_extend(
                "force",
                require("user.lsp.settings.rust_analyzer"), 
                {
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
                }
            ),
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
