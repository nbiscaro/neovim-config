local M = {}

-- Setup lazygit terminal
local function setup_lazygit()
    local Terminal = require("toggleterm.terminal").Terminal
    
    -- Lazygit terminal setup
    local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
            border = "curved",
        },
        on_open = function(term)
            vim.cmd("startinsert!")
            -- Disable line numbers to avoid clutter on lazygit interface
            vim.api.nvim_buf_set_option(term.bufnr, "number", false)
            vim.api.nvim_buf_set_option(term.bufnr, "relativenumber", false)
        end,
        hidden = true
    })
    
    -- Define global lazygit toggle function
    function _G._LAZYGIT_TOGGLE()
        lazygit:toggle()
    end
end

-- Setup keymaps
local function setup_keymaps()
    local opts = { noremap = true, silent = true }
    local keymap = vim.api.nvim_set_keymap

    -- Lazygit
    keymap("n", "<leader>gg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", opts)
end

-- Initialize git functionality
function M.setup()
    -- Setup lazygit
    setup_lazygit()
    
    -- Setup gitsigns
    require("user.gitsigns").setup()
    
    -- Setup keymaps
    setup_keymaps()
end

return M 
