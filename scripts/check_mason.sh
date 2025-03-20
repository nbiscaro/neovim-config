#!/bin/bash
# Script to check Mason setup in Neovim

# Do not exit immediately on error to show more diagnostics
set +e

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

# Create directory for the script
mkdir -p "$(dirname "$0")"

# Print header
echo "========================================"
echo "   Checking Mason LSP Configuration   "
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

# Check Mason module structure with detailed error output
cat > "$TEMP_DIR/check_mason.lua" << 'EOF'
print("Starting Mason module check...")
local status_ok, mason = pcall(require, "user.lsp.mason")
if not status_ok then
  print("❌ Mason module could not be loaded!")
  print("Error: " .. tostring(mason))
  os.exit(1)
end

print("Module loaded, checking for setup function...")
if type(mason.setup) ~= "function" then
  print("❌ Mason module does not have a setup function!")
  print("Type of mason: " .. type(mason))
  print("Available fields:")
  for k, v in pairs(mason) do
    print("  - " .. k .. ": " .. type(v))
  end
  os.exit(1)
end

print("✅ Mason module structure is valid!")
EOF

echo "Checking Mason module structure..."
run_with_timeout 20 nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_mason.lua" -c "q" > "$TEMP_DIR/mason_check_output.txt" 2>&1
cat "$TEMP_DIR/mason_check_output.txt"

if grep -q "Mason module structure is valid" "$TEMP_DIR/mason_check_output.txt"; then
  echo "✅ Mason module structure is valid"
else
  echo "❌ Mason module has structural issues"
  # Continue to show more diagnostics
fi

# Show current LSP modules
echo ""
echo "Checking available LSP modules..."
cat > "$TEMP_DIR/list_lsp_modules.lua" << 'EOF'
local lsp_dir = vim.fn.stdpath("config") .. "/lua/user/lsp"
print("LSP directory: " .. lsp_dir)

local scan = vim.loop.fs_scandir(lsp_dir)
if scan then
  print("Available LSP modules:")
  while true do
    local name, type = vim.loop.fs_scandir_next(scan)
    if not name then break end
    print("  - " .. name .. " (" .. type .. ")")
  end
end
EOF

nvim --headless -c "luafile $TEMP_DIR/list_lsp_modules.lua" -c "q"

# Check if Mason command is registered
echo ""
echo "Checking Mason commands..."
cat > "$TEMP_DIR/check_mason_commands.lua" << 'EOF'
print("Checking Mason commands...")
local commands = vim.api.nvim_get_commands({})
if commands.Mason then
  print("✅ Mason command is available")
else
  print("❌ Mason command is not registered")
  print("Available commands that start with 'M':")
  for cmd_name, _ in pairs(commands) do
    if cmd_name:sub(1,1) == "M" then
      print("  - " .. cmd_name)
    end
  end
end
EOF

run_with_timeout 15 nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_mason_commands.lua" -c "q"

# Print Neovim health check
echo ""
echo "Running Mason health check..."
run_with_timeout 15 nvim --headless -c "checkhealth mason" -c "q" > "$TEMP_DIR/mason_health.txt" 2>&1
cat "$TEMP_DIR/mason_health.txt"

echo ""
echo "Checking Mason init.lua requires..."
cat > "$TEMP_DIR/check_init.lua" << 'EOF'
print("Looking at init.lua requires...")
local init_content = vim.fn.readfile(vim.fn.stdpath("config") .. "/init.lua")
for _, line in ipairs(init_content) do
  if line:match("require.*lsp") then
    print("LSP require found: " .. line)
  end
end
EOF

nvim --headless -c "luafile $TEMP_DIR/check_init.lua" -c "q"

# In CI, we verify Mason API but don't actually attempt installation
# which can cause hangs
if [ "$IS_CI" = false ]; then
  echo ""
  echo "Attempting to run Mason command directly..."
  run_with_timeout 5 nvim --headless -c "Mason" -c "q" > "$TEMP_DIR/mason_cmd.txt" 2>&1
  cat "$TEMP_DIR/mason_cmd.txt"
fi

echo "========================================"
echo "       Mason Check Completed            "
echo "========================================" 