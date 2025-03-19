local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone", "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Install your plugins here
return packer.startup(function(use)
  -- My plugins here
  use "wbthomason/packer.nvim" -- Have packer manage itself

  use "nvim-lua/popup.nvim" -- An implementation of the Popup API from vim in Neovim

  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins

  use "folke/tokyonight.nvim" -- Tokyo Night colorscheme

  use "windwp/nvim-autopairs" -- Autopairs, integrates with both cmp and treesitter

  -- Icons for UI elements
  use 'nvim-tree/nvim-web-devicons'
  use 'kyazdani42/nvim-tree.lua'

   -- Fuzzy finder
  use {
    "nvim-telescope/telescope.nvim",
    requires = { "nvim-lua/plenary.nvim" }
  }

   -- Status line
  use {
    "nvim-lualine/lualine.nvim",
    requires = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end
  }

   -- Treesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }
  
  -- LSP
  use "neovim/nvim-lspconfig"
  use {
    "williamboman/mason.nvim",
    run = ":MasonUpdate"
  }
  use "williamboman/mason-lspconfig.nvim"
  use "jose-elias-alvarez/null-ls.nvim"

   -- Completion
  use "hrsh7th/nvim-cmp" -- The completion plugin
  use "hrsh7th/cmp-buffer" -- buffer completions
  use "hrsh7th/cmp-path" -- path completions
  use "hrsh7th/cmp-cmdline" -- cmd line completions

  -- Snippet Engine
  use "L3MON4D3/LuaSnip" --snippet engine
  use "rafamadriz/friendly-snippets"

  -- Toggleterm floating terminal window
  use "akinsho/toggleterm.nvim"
  
  -- Diffview for better diff viewing
  -- Rust tools for enhanced Rust development experience
  use {
    "sindrets/diffview.nvim",
    requires = "nvim-lua/plenary.nvim"
  }

  use {
    "simrat39/rust-tools.nvim",
    requires = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap"  -- For debugging support
    }
  }
  
  -- Gitsigns - provides line-by-line git blame, line indicators, and hunk actions
  use {
    "lewis6991/gitsigns.nvim",
    requires = "nvim-lua/plenary.nvim"
  }
  -- Debug adapter protocol for Rust debugging
  use "mfussenegger/nvim-dap"

  -- Easily comment stuff
  use "numToStr/Comment.nvim"

  -- Buffer management
  use "famiu/bufdelete.nvim"  -- Add this plugin for proper buffer deletion

  -- Bufferline 
  use { 
    "akinsho/bufferline.nvim", 
    tag = "v4.*",  -- Try the latest v4 version instead
    requires = "nvim-tree/nvim-web-devicons"
  }

  -- Project
  use "ahmedkhalf/project.nvim"

  -- Neovim welcome page
  use 'goolord/alpha-nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
