return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--completion-style=detailed",
		"--header-insertion=iwyu",
		"--suggest-missing-includes",
		"--cross-file-rename",
		"--enable-config",
	},
	init_options = {
		-- Specify clang-tidy checks to enable
		clangTidy = {
			checks = {
				"*",
				"-fuchsia-*",
				"-google-*",
				"-zircon-*",
				"-abseil-*",
				"-modernize-use-trailing-return-type",
				"-llvm-*",
			},
			checkOptions = {},
		},
		-- Enable semantic highlighting
		semanticHighlighting = true,
		-- Configure signature help
		signatureHelp = {
			detailed = true,
		},
		-- Include completion settings
		completion = {
			detailedLabel = true,
			placeholder = true,
		},
	},
	-- Tell the language server which filetypes to associate with
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	-- Customize extensions if needed
	settings = {
		["clangd"] = {
			fallbackFlags = { "-std=c++17" },
			warningMatchers = { ".*" }, -- Match all warnings
		},
	},
} 