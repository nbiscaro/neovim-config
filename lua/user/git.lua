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

    -- Diffview toggle keybindings
    keymap("n", "<leader>dd", "<cmd>lua toggle_diffview()<CR>", opts)
    keymap("n", "<leader>dh", "<cmd>lua toggle_file_history()<CR>", opts)
    keymap("n", "<leader>dH", "<cmd>lua toggle_repo_history()<CR>", opts)

    -- Additional Diffview commands (these don't need toggles as they're one-time actions)
    keymap("n", "<leader>dD", ":DiffviewOpen ", opts)  -- For specific branch/commit comparison
    keymap("n", "<leader>df", ":DiffviewFocusFiles<CR>", opts)  -- Focus files panel
    keymap("n", "<leader>dr", ":DiffviewRefresh<CR>", opts)  -- Refresh view
end

-- Helper function to check if a buffer is a Diffview buffer
function _G.is_diffview_buffer(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    return bufname:match("Diffview") ~= nil
end

-- Helper function to check if any Diffview buffer is open
function _G.has_diffview_open()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if is_diffview_buffer(bufnr) then
            return true
        end
    end
    return false
end

-- Diffview toggle functions
function _G.toggle_diffview()
    if has_diffview_open() then
        vim.cmd("DiffviewClose")
    else
        vim.cmd("DiffviewOpen -layout=diff2_vertical")
    end
end

function _G.toggle_file_history()
    if has_diffview_open() then
        vim.cmd("DiffviewClose")
    else
        vim.cmd("DiffviewFileHistory %")
    end
end

function _G.toggle_repo_history()
    if has_diffview_open() then
        vim.cmd("DiffviewClose")
    else
        vim.cmd("DiffviewFileHistory")
    end
end

-- Configure Diffview
local function setup_diffview()
    local status_ok, diffview = pcall(require, "diffview")
    if not status_ok then
        return
    end

    local actions = require("diffview.actions")

    diffview.setup({
        diff_binaries = false,    -- Show diffs for binaries
        enhanced_diff_hl = true,  -- See ':h diffview-config-enhanced_diff_hl'
        git_cmd = { "git" },      -- The git executable followed by default args
        use_icons = true,         -- Requires nvim-web-devicons
        icons = {                 -- Only applies when use_icons is true
            folder_closed = "",
            folder_open = "",
        },
        signs = {
            fold_closed = "",
            fold_open = "",
            done = "✓",
        },
        view = {
            -- Configure the default view
            merge_tool = {
                -- Layout configurations for merge tool
                layout = "diff3_mixed",
                disable_diagnostics = true,
            },
            file_history = {
                -- Layout configuration for file history view
                layout = "diff2_horizontal",
            },
        },
        file_panel = {
            listing_style = "tree",             -- One of 'list' or 'tree'
            tree_options = {                    -- Only applies when listing_style is 'tree'
                flatten_dirs = true,              -- Flatten dirs that only contain one single dir
                folder_statuses = "only_folded",  -- One of 'never', 'only_folded' or 'always'
            },
            win_config = {                      -- See ':h diffview-config-win_config'
                position = "left",
                width = 35,
            },
        },
        file_history_panel = {
            log_options = {   -- See ':h diffview-config-log_options'
                git = {
                    follow = true,
                    all = true,
                    max_count = 256,
                },
            },
            win_config = {    -- See ':h diffview-config-win_config'
                position = "bottom",
                height = 16,
            },
        },
        default_args = {    -- Default args prepended to the arg-list for the listed commands
            DiffviewOpen = {},
            DiffviewFileHistory = {},
        },
        hooks = {},         -- See ':h diffview-config-hooks'
        keymaps = {
            view = {
                -- Disable default keymaps and use our custom ones from keymaps.lua
                ["<tab>"]      = actions.select_next_entry,
                ["<s-tab>"]    = actions.select_prev_entry,
                ["gf"]         = actions.goto_file,
                ["<C-w><C-f>"] = actions.goto_file_split,
                ["<C-w>gf"]    = actions.goto_file_tab,
                ["<leader>e"]  = actions.focus_files,
                ["<leader>b"]  = actions.toggle_files,
                ["q"]          = actions.close,
            },
            file_panel = {
                ["j"]             = actions.next_entry,
                ["<down>"]        = actions.next_entry,
                ["k"]             = actions.prev_entry,
                ["<up>"]          = actions.prev_entry,
                ["<cr>"]          = actions.select_entry,
                ["o"]             = actions.select_entry,
                ["<2-LeftMouse>"] = actions.select_entry,
                ["s"]             = actions.toggle_stage_entry,
                ["S"]             = actions.stage_all,
                ["U"]             = actions.unstage_all,
                ["X"]             = actions.restore_entry,
                ["R"]             = actions.refresh_files,
                ["L"]             = actions.open_commit_log,
                ["<c-b>"]         = actions.scroll_view(-0.25),
                ["<c-f>"]         = actions.scroll_view(0.25),
                ["<tab>"]         = actions.select_next_entry,
                ["<s-tab>"]       = actions.select_prev_entry,
                ["gf"]            = actions.goto_file,
                ["<C-w><C-f>"]    = actions.goto_file_split,
                ["<C-w>gf"]       = actions.goto_file_tab,
                ["<leader>e"]     = actions.focus_files,
                ["<leader>b"]     = actions.toggle_files,
                ["q"]             = actions.close,
            },
            file_history_panel = {
                ["g!"]            = actions.options,
                ["<C-A-d>"]       = actions.open_in_diffview,
                ["y"]             = actions.copy_hash,
                ["L"]             = actions.open_commit_log,
                ["zR"]            = actions.open_all_folds,
                ["zM"]            = actions.close_all_folds,
                ["j"]             = actions.next_entry,
                ["<down>"]        = actions.next_entry,
                ["k"]             = actions.prev_entry,
                ["<up>"]          = actions.prev_entry,
                ["<cr>"]          = actions.select_entry,
                ["o"]             = actions.select_entry,
                ["<2-LeftMouse>"] = actions.select_entry,
                ["<c-b>"]         = actions.scroll_view(-0.25),
                ["<c-f>"]         = actions.scroll_view(0.25),
                ["<tab>"]         = actions.select_next_entry,
                ["<s-tab>"]       = actions.select_prev_entry,
                ["gf"]            = actions.goto_file,
                ["<C-w><C-f>"]    = actions.goto_file_split,
                ["<C-w>gf"]       = actions.goto_file_tab,
                ["<leader>e"]     = actions.focus_files,
                ["<leader>b"]     = actions.toggle_files,
                ["q"]             = actions.close,
            },
            option_panel = {
                ["<tab>"] = actions.select_entry,
                ["q"]     = actions.close,
            },
        },
    })
end

-- Initialize git functionality
function M.setup()
    -- Setup lazygit
    setup_lazygit()
    
    -- Configure diffview
    setup_diffview()
    
    -- Setup gitsigns
    require("user.gitsigns").setup()
    
    -- Setup keymaps
    setup_keymaps()
end

return M 
