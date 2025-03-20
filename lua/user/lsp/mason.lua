local M = {}

function M.setup()
	local servers = {
		"lua_ls",
		"pyright",
		"jsonls",
		"rust_analyzer",
		"clangd",
	}

	local tools = {
		-- Python tools
		"black",
		"isort",
		"mypy",
		"ruff",
		"debugpy",
		"flake8",
	}

	local settings = {
		ui = {
			border = "none",
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
		log_level = vim.log.levels.INFO,
		max_concurrent_installers = 4,
	}

	require("mason").setup(settings)
	require("mason-lspconfig").setup({
		ensure_installed = servers,
		automatic_installation = true,
	})

	-- Install additional tools that aren't LSP servers
	local registry = require("mason-registry")
	for _, tool in ipairs(tools) do
		if not registry.is_installed(tool) then
			vim.cmd("MasonInstall " .. tool)
		end
	end

	local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
	if not lspconfig_status_ok then
		return
	end

	-- Initialize server options only once
	local server_opts = {}

	for _, server in pairs(servers) do
		server_opts = {
			on_attach = require("user.lsp.handlers").on_attach,
			capabilities = require("user.lsp.handlers").capabilities,
		}

		server = vim.split(server, "@")[1]

		local require_ok, conf_opts = pcall(require, "user.lsp.settings." .. server)
		if require_ok then
			server_opts = vim.tbl_deep_extend("force", conf_opts, server_opts)
		end

		-- Skip rust_analyzer as it's set up by rust-tools
		if server ~= "rust_analyzer" then
			lspconfig[server].setup(server_opts)
		end
	end

	-- Separate autocommand to update clangd client configuration when attached
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local current_client = vim.lsp.get_client_by_id(ev.data.client_id)
			if current_client and current_client.name == "clangd" then
				local clangd_opts = {
					args = { "--fallback-style=Google" },
					capabilities = { offsetEncoding = { "utf-16", "utf-8" } },
				}
				current_client.config.capabilities = vim.tbl_deep_extend("force", current_client.config.capabilities, clangd_opts.capabilities)
			end
		end,
	})
end

return M
