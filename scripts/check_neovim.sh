#!/bin/bash
# Script to validate the entire Neovim configuration

# Do not exit immediately on error to show more diagnostics
set +e
ERRORS=0

# Create directory for the script
mkdir -p "$(dirname "$0")"

# Print header
echo "========================================"
echo "   Checking Neovim Configuration      "
echo "========================================"

# Check if Neovim is installed
if ! command -v nvim >/dev/null 2>&1; then
  echo "❌ Neovim not found! Please install Neovim first."
  exit 1
fi

echo "✅ Neovim found"

# Temporary directory for test scripts
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 1. Validate init.lua syntax
echo ""
echo "Checking init.lua syntax..."
nvim --headless -c 'lua print("Checking init.lua syntax")' -c 'q' > "$TEMP_DIR/init_check.txt" 2>&1
cat "$TEMP_DIR/init_check.txt"

if grep -q "Error" "$TEMP_DIR/init_check.txt"; then
  echo "❌ init.lua has syntax errors"
  ERRORS=$((ERRORS+1))
else
  echo "✅ init.lua syntax is valid"
fi

# 2. Check if plugins can be loaded
echo ""
echo "Checking plugins..."
mkdir -p ~/.local/share/nvim/site/pack/packer/opt
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' > "$TEMP_DIR/plugin_check.txt" 2>&1 || true
cat "$TEMP_DIR/plugin_check.txt"
echo "✅ Plugin installation attempted"

# 3. List all plugins
echo ""
echo "Listing installed plugins..."
cat > "$TEMP_DIR/list_plugins.lua" << 'EOF'
local packer_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start"
local packer_opt_dir = vim.fn.stdpath("data") .. "/site/pack/packer/opt"

local function list_plugins_in_dir(dir)
  local plugins = {}
  local scan = vim.loop.fs_scandir(dir)
  if scan then
    print("Plugins in " .. dir .. ":")
    while true do
      local name, type = vim.loop.fs_scandir_next(scan)
      if not name then break end
      if type == "directory" then
        print("  - " .. name)
        table.insert(plugins, name)
      end
    end
  else
    print("Directory not found: " .. dir)
  end
  return plugins
end

print("Start plugins:")
list_plugins_in_dir(packer_dir)
print("\nOptional plugins:")
list_plugins_in_dir(packer_opt_dir)
EOF

nvim --headless -c "luafile $TEMP_DIR/list_plugins.lua" -c "q"

# 4. Check for configuration errors - using checkhealth instead of vim.health.report
echo ""
echo "Checking for configuration errors..."
nvim --headless -c "checkhealth" -c "q" > "$TEMP_DIR/health_check.txt" 2>&1 || true
cat "$TEMP_DIR/health_check.txt"

if grep -q "ERROR" "$TEMP_DIR/health_check.txt"; then
  echo "❌ Errors found in configuration"
  ERRORS=$((ERRORS+1))
else
  echo "✅ No critical errors found in configuration"
fi

# 5. Check LSP configuration files
echo ""
echo "Checking LSP configuration files..."
if [ ! -d "./lua/user/lsp" ]; then
  echo "❌ LSP configuration directory missing"
  ERRORS=$((ERRORS+1))
else
  echo "✅ LSP directory exists"
  
  # Check each LSP file
  echo ""
  echo "Validating individual LSP files..."
  for lsp_file in ./lua/user/lsp/*.lua; do
    echo "Checking $lsp_file..."
    nvim --headless -c "luafile $lsp_file" -c "q" > "$TEMP_DIR/lsp_check.txt" 2>&1
    
    if grep -q "Error" "$TEMP_DIR/lsp_check.txt"; then
      echo "❌ Error in $lsp_file"
      cat "$TEMP_DIR/lsp_check.txt"
      ERRORS=$((ERRORS+1))
    else
      echo "✅ $lsp_file is valid"
    fi
  done
fi

# 6. Run Luacheck (optional - only if installed)
echo ""
echo "Checking for Luacheck installation..."
if command -v luacheck >/dev/null 2>&1; then
  echo "Running Luacheck on Lua files..."
  luacheck lua/ --no-max-line-length --no-max-comment-line-length > "$TEMP_DIR/luacheck.txt" 2>&1
  cat "$TEMP_DIR/luacheck.txt"
  echo "✅ Luacheck completed"
else
  echo "⚠️ Luacheck not installed - skipping syntax validation"
  echo "Install with: luarocks install luacheck"
fi

# 7. Check tree-sitter (commonly used and often a source of issues)
echo ""
echo "Checking Tree-sitter status..."
cat > "$TEMP_DIR/check_treesitter.lua" << 'EOF'
local status_ok, ts = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  print("❌ Tree-sitter not available")
  os.exit(0)
end

print("✅ Tree-sitter is available")
print("Installed parsers:")

-- Safer way to check parsers
local parsers_ok, parsers = pcall(require, "nvim-treesitter.parsers")
if not parsers_ok then
  print("  Unable to load parsers module")
  os.exit(0)
end

local parser_configs = parsers.get_parser_configs()
local installed_count = 0

for name, config in pairs(parser_configs) do
  local is_installed, result = pcall(function() 
    return parsers.has_parser(name)
  end)
  
  if is_installed and result then
    print("  - " .. name)
    installed_count = installed_count + 1
  end
end

if installed_count == 0 then
  print("  No parsers installed yet")
end
EOF

nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_treesitter.lua" -c "q" || echo "Tree-sitter check completed"

# 8. Check Telescope (another common source of issues)
echo ""
echo "Checking Telescope status..."
cat > "$TEMP_DIR/check_telescope.lua" << 'EOF'
local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  print("❌ Telescope not available")
  os.exit(0)
end

print("✅ Telescope is available")
print("Loaded extensions:")
if telescope._extensions then
  for ext_name, _ in pairs(telescope._extensions) do
    print("  - " .. ext_name)
  end
else
  print("  No extensions loaded yet")
end
EOF

nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_telescope.lua" -c "q" || echo "Telescope check completed"

# Final summary
echo ""
echo "========================================"
echo "   Neovim Configuration Check Summary  "
echo "========================================"
if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed successfully!"
  exit 0
else
  echo "❌ Found $ERRORS errors during validation."
  exit 1
fi 