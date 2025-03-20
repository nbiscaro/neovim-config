-- Neovim Lua configuration

-- Allow accessing vim as a global
globals = {
  "vim",
  "PACKER_BOOTSTRAP",
  "_LAZYGIT_TOGGLE",
  "_NODE_TOGGLE",
  "_NCDU_TOGGLE",
  "_HTOP_TOGGLE",
  "_PYTHON_TOGGLE",
  "is_diffview_buffer",
  "has_diffview_open",
  "toggle_diffview",
  "toggle_file_history",
  "toggle_repo_history",
  "vertical_diffview"
}

-- Reuse globals
read_globals = {
  "vim",
  string = { fields = { "split" } },
  table = { fields = { "concat", "insert", "unpack" } },
}

-- Ignore unused self parameter in methods
self = false

-- Configure specific rules
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "122", -- Mutating read-only field (vim.opt, vim.g, etc.)
  "631", -- Line is too long, disabled for now
  "611", -- Line contains trailing whitespace
  "612", -- Line contains trailing whitespace in a comment
  "613", -- Line contains only whitespace
  "614", -- Trailing whitespace in a string
  "311", -- Value assigned to variable * is unused
}

-- Files to exclude from checking
exclude_files = {
  "lua/plenary/**",
  "lua/packer_compiled.lua",
  ".luarocks/**",
}

-- Allow a bit more complex functions
max_line_length = 120
max_code_line_length = 120
max_string_line_length = 120
max_comment_line_length = 120 