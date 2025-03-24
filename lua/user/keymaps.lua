local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

keymap("n", "<leader>e", ":Lex 30<cr>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts)

-- Telescope 
keymap("n", "<leader>f", "<cmd>Telescope find_files<cr>", opts)
keymap("n", "<leader>f", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
keymap("n", "<c-t>", "<cmd>Telescope live_grep<cr>", opts)
keymap("n", "<leader>p", "<cmd>Telescope projects<cr>", opts)

-- CodeCompanion keymaps

-- Using <leader>i as prefix for AI companion commands
keymap("n", "<leader>ic", "<cmd>CodeCompanion<CR>", opts)  -- Open chat interface
keymap("v", "<leader>ic", "<cmd>CodeCompanion<CR>", opts)  -- Open chat with selection

-- Predefined prompts (visual mode only)
keymap("v", "<leader>ie", "<cmd>CodeCompanionToggle explain_code<CR>", opts)  -- Explain code
keymap("v", "<leader>ii", "<cmd>CodeCompanionToggle improve_code<CR>", opts)  -- Improve code
keymap("v", "<leader>if", "<cmd>CodeCompanionToggle fix_bugs<CR>", opts)      -- Fix bugs
keymap("v", "<leader>it", "<cmd>CodeCompanionToggle add_tests<CR>", opts)     -- Add tests
keymap("v", "<leader>id", "<cmd>CodeCompanionToggle documentation<CR>", opts) -- Add documentation

-- Additional controls
keymap("n", "<leader>ir", "<cmd>CodeCompanionActions<CR>", opts)              -- Show actions menu
keymap("n", "<leader>ik", "<cmd>CodeCompanionToggle<CR>", opts)               -- Toggle companion window

-- Toggle hidden files in Telescope
local telescope_hidden = true
function _G.toggle_telescope_hidden()
    telescope_hidden = not telescope_hidden
    local telescope_builtin = require('telescope.builtin')
    require('telescope').setup({
        pickers = {
            find_files = {
                hidden = telescope_hidden,
                no_ignore = telescope_hidden,
            },
            live_grep = {
                additional_args = telescope_hidden and function() return {"--hidden"} end or function() return {} end
            }
        }
    })
    print("Telescope hidden files: " .. (telescope_hidden and "ON" or "OFF"))
end

-- Map it to a key
vim.api.nvim_set_keymap("n", "<leader>fh", ":lua toggle_telescope_hidden()<CR>", {noremap = true, silent = true})

