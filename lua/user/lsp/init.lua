local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "user.lsp.mason"
require("user.lsp.handlers").setup()
require "user.lsp.null-ls"

-- Load Rust Tools if available
local rust_tools_ok, _ = pcall(require, "rust-tools")
if rust_tools_ok then
  require("user.lsp.rust-tools").setup()
end
