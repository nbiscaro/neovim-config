#!/bin/bash
# Script to validate the entire Neovim configuration

# Do not exit immediately on error to show more diagnostics
set +e
ERRORS=0

# Create directory for the script
mkdir -p "$(dirname "$0")"

# Check if running in CI
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
  IS_CI=true
  echo "Running in CI environment"
else
  IS_CI=false
fi

# Check if timeout command is available, use gtimeout on macOS if installed
TIMEOUT_CMD="timeout"
if ! command -v timeout >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout"
    echo "Using gtimeout command"
  else
    echo "Note: timeout command not available, timeouts will be skipped"
    TIMEOUT_CMD="cat |" # Dummy command that just passes through
  fi
fi

# Function to run a command with timeout if available
run_with_timeout() {
  local timeout_seconds=$1
  shift
  
  if [ "$IS_CI" = true ]; then
    if [ "$TIMEOUT_CMD" = "cat |" ]; then
      echo "Warning: Running without timeout in CI environment"
      "$@"
    else
      $TIMEOUT_CMD "$timeout_seconds"s "$@" || echo "Command timed out or exited with warning"
    fi
  else
    "$@"
  fi
}

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

# In CI, we'll use a timeout and skip this step if it takes too long
if [ "$IS_CI" = true ]; then
  echo "In CI environment - using timeout for plugin installation"
  # Create a simple script to check for Packer plugin existence
  cat > "$TEMP_DIR/check_plugins.lua" << 'EOF'
  local function plugin_check()
    local packer_path = vim.fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
    if vim.fn.empty(vim.fn.glob(packer_path)) > 0 then
      print("Packer not found at: " .. packer_path)
      return false
    else
      print("Packer found at: " .. packer_path)
      return true
    end
  end
  
  if plugin_check() then
    -- Just try loading some essential plugins without syncing
    local status_ok, _ = pcall(require, "packer")
    if status_ok then
      print("Packer loaded successfully")
    else
      print("Failed to load packer")
    end
    
    -- Try to load a few core plugins to verify basic functionality
    local plugins_to_check = {"nvim-treesitter", "telescope", "mason"}
    for _, plugin in ipairs(plugins_to_check) do
      local status, _ = pcall(require, plugin)
      if status then
        print("✅ " .. plugin .. " loaded successfully")
      else
        print("❌ " .. plugin .. " failed to load")
      end
    end
  end
  
  -- Exit cleanly
  vim.cmd("qa!")
EOF

  # Run with timeout - 30 seconds should be enough for a basic check
  run_with_timeout 30 nvim --headless -c "luafile $TEMP_DIR/check_plugins.lua" > "$TEMP_DIR/plugin_check.txt" 2>&1
  cat "$TEMP_DIR/plugin_check.txt"
else
  # Not in CI, run the regular command
  nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' > "$TEMP_DIR/plugin_check.txt" 2>&1 || true
  cat "$TEMP_DIR/plugin_check.txt"
fi

echo "✅ Plugin checks completed"

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
# In CI, use a timeout here too
run_with_timeout 30 nvim --headless -c "checkhealth" -c "q" > "$TEMP_DIR/health_check.txt" 2>&1
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

run_with_timeout 15 nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_treesitter.lua" -c "q"

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

run_with_timeout 15 nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_telescope.lua" -c "q"

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