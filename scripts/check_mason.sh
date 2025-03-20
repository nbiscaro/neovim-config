#!/bin/bash
# Script to check Mason setup in Neovim

# Do not exit immediately on error to show more diagnostics
set +e

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
nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_mason.lua" -c "q" > "$TEMP_DIR/mason_check_output.txt" 2>&1
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

nvim --headless -u init.lua -c "luafile $TEMP_DIR/check_mason_commands.lua" -c "q"

# Print Neovim health check
echo ""
echo "Running Mason health check..."
nvim --headless -c "checkhealth mason" -c "q" > "$TEMP_DIR/mason_health.txt" 2>&1 
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

echo "========================================"
echo "       Mason Check Completed            "
echo "========================================" 