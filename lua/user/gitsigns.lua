local M = {}

function M.setup()
    local status_ok, gitsigns = pcall(require, "gitsigns")
    if not status_ok then
        return
    end

    gitsigns.setup {
        signs = {
            add          = { hl = 'GitSignsAdd',    text = '│', numhl='GitSignsAddNr',    linehl='GitSignsAddLn' },
            change       = { hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
            delete       = { hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
            topdelete    = { hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
            changedelete = { hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
            untracked    = { hl = 'GitSignsAdd',    text = '┆', numhl='GitSignsAddNr',    linehl='GitSignsAddLn' },
        },
        signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
        numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
            interval = 1000,
            follow_files = true
        },
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        preview_config = {
            -- Options passed to nvim_open_win
            border = 'single',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
        },
        yadm = {
            enable = false
        },
        -- Keymaps for gitsigns operations
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map('n', ']c', function()
                if vim.wo.diff then return ']c' end
                vim.schedule(function() gs.next_hunk() end)
                return '<Ignore>'
            end, {expr=true})

            map('n', '[c', function()
                if vim.wo.diff then return '[c' end
                vim.schedule(function() gs.prev_hunk() end)
                return '<Ignore>'
            end, {expr=true})

            -- Actions
            map('n', '<leader>ghs', gs.stage_hunk, { desc = 'Stage hunk' })
            map('n', '<leader>ghr', gs.reset_hunk, { desc = 'Reset hunk' })
            map('v', '<leader>ghs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Stage selected hunks' })
            map('v', '<leader>ghr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Reset selected hunks' })
            map('n', '<leader>ghS', gs.stage_buffer, { desc = 'Stage buffer' })
            map('n', '<leader>ghu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
            map('n', '<leader>ghR', gs.reset_buffer, { desc = 'Reset buffer' })
            map('n', '<leader>ghp', gs.preview_hunk, { desc = 'Preview hunk' })
            map('n', '<leader>ghb', function() gs.blame_line{full=true} end, { desc = 'Blame line' })
            map('n', '<leader>ghtb', gs.toggle_current_line_blame, { desc = 'Toggle line blame' })
            map('n', '<leader>ghd', gs.diffthis, { desc = 'Diff this' })
            map('n', '<leader>ghD', function() gs.diffthis('~') end, { desc = 'Diff this ~' })
            map('n', '<leader>ght', gs.toggle_deleted, { desc = 'Toggle deleted' })

            -- Text object
            map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'Select hunk' })
        end
    }
end

return M
