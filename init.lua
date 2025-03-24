-- First load plugins
require("user.plugins")

-- Options should be loaded early to ensure settings like termguicolors are set
require("user.options")

-- Then load UI components that depend on those settings
require("user.colorscheme")
require("user.bufferline")
require("user.lualine")
require("user.nvim-tree")

-- Then load other modules
require("user.alpha")
require("user.autopairs")
require("user.cmp")
require("user.comments")
require("user.indentline")
require("user.keymaps")
require("user.lsp")
require("user.project")
require("user.settings")
require("user.telescope")
require("user.toggleterm")
require("user.git").setup()
require("user.gitsigns")
require("user.whichkey")
require("user.codecompanion")
require("user.diffview").setup()
require("user.dap").setup()
