local M = {}

-- TODO: backfill this to template
M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  local config = {
    -- disable virtual text
    virtual_text = false,
    -- show signs
    signs = {
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }

  vim.diagnostic.config(config)

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
  })
end

local function lsp_highlight_document(client)
  -- Set autocommands conditional on server_capabilities
  if client.server_capabilities.documentHighlight then
    vim.api.nvim_exec(
      [[
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]],
      false
    )
  end
end

local function lsp_keymaps(bufnr)
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "gl",
    '<cmd>lua vim.diagnostic.open_float()<CR>',
    opts
  )
  vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
  vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end

M.on_attach = function(client, bufnr)
  if client.name == "tsserver" then
    client.server_capabilities.documentFormattingProvider = false
  end
  
  -- Special handling for rust-analyzer
  if client.name == "rust_analyzer" then
    -- Set up inlay hints (if supported)
    if vim.fn.has('nvim-0.10') == 1 then
      vim.lsp.inlay_hint.enable(bufnr, true)
    end
    
    -- Add Rust-specific keymaps
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rr", "<cmd>RustRunnables<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rd", "<cmd>RustDebuggables<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rt", "<cmd>RustExpandMacro<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rc", "<cmd>RustOpenCargo<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rp", "<cmd>RustParentModule<CR>", opts)
  end
  
  -- Special handling for clangd
  if client.name == "clangd" then
    -- Add C/C++ specific keymaps (e.g., for switching between header and source)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>cs", "<cmd>ClangdSymbolInfo<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ct", "<cmd>ClangdTypeHierarchy<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>cm", "<cmd>ClangdMemoryUsage<CR>", opts)
    
    -- Set up inlay hints (if supported)
    if vim.fn.has('nvim-0.10') == 1 then
      vim.lsp.inlay_hint.enable(bufnr, true)
    end
  end
  
  lsp_keymaps(bufnr)
  lsp_highlight_document(client)
end

  lsp_keymaps(bufnr)
  lsp_highlight_document(client)
end

local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if status_ok then
  M.capabilities = cmp_nvim_lsp.default_capabilities()
end

return M
