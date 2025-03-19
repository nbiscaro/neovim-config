return {
	settings = {
		["rust-analyzer"] = {
			-- Enable cargo features
			cargo = {
				allFeatures = true,
				loadOutDirsFromCheck = true,
				runBuildScripts = true,
			},
			-- Enable proc-macro support
			procMacro = {
				enable = true,
			},
			-- Enable additional diagnostics and suggestions
			checkOnSave = {
				command = "clippy",
				extraArgs = { "--all", "--all-features" },
			},
			-- Inline hints
			inlayHints = {
				lifetimeElisionHints = {
					enable = "always",
				},
				reborrowHints = {
					enable = "always",
				},
			},
			-- Hover actions
			hover = {
				actions = {
					enable = true,
					documentation = true,
					gotoTypeDef = true,
					implementations = true,
					references = true,
				},
			},
			-- Completion settings
			completion = {
				postfix = {
					enable = true,
				},
				callable = {
					snippets = "fill_arguments",
				},
				fullFunctionSignatures = {
					enable = true,
				},
			},
		}
	}
} 