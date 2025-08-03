#!/bin/bash

# NPM Global Packages Installation
# Install essential Node.js global packages
#
# Usage:
#   chmod +x npm-install.sh
#   ./npm-install.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "📦 NPM Global Packages Installation"
echo "=========================================="

# Check if npm is available
if ! command -v npm &> /dev/null; then
    print_error "npm not found!"
    echo ""
    read -p "📦 Node.js is required for NPM packages. Install it now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing Node.js via Homebrew..."
        if command -v brew &> /dev/null; then
            if brew install node; then
                print_success "Node.js installed successfully"
                print_status "Node.js version: $(node --version)"
                print_status "npm version: $(npm --version)"
            else
                print_error "Failed to install Node.js via Homebrew"
                print_status "Please install manually: brew install node"
                return 1
            fi
        else
            print_error "Homebrew not found - cannot install Node.js"
            print_status "Please install Homebrew first, then run: brew install node"
            return 1
        fi
    else
        print_status "Node.js installation skipped - NPM packages will not be installed"
        return 1
    fi
else
    print_status "Node.js version: $(node --version)"
    print_status "npm version: $(npm --version)"
fi

echo ""

# NPM Global Packages to install
packages=(
    "@anthropic-ai/claude-code:Claude AI coding assistant"
    "typescript:TypeScript compiler"
    "prettier:Code formatter"
    # Add more packages here as needed
    # "nodemon:Development server auto-restart"
    # "@vue/cli:Vue.js CLI"
    # "@angular/cli:Angular CLI"
)

print_status "Installing NPM global packages..."
echo ""

for package_info in "${packages[@]}"; do
    IFS=':' read -r package description <<< "$package_info"
    
    print_status "Ensuring $package is at latest version ($description)..."
    
    if npm install -g "$package@latest"; then
        print_success "$package ready"
    else
        print_error "Failed to install/update $package"
    fi
    echo ""
done

echo "=========================================="
print_success "✅ NPM packages installation completed!"
echo "=========================================="

print_status "Installed packages:"
npm list -g --depth=0 2>/dev/null | grep -E "(claude-code|typescript|prettier)" || echo "  Run 'npm list -g --depth=0' to see all packages"

echo ""
print_status "Next steps:"
echo "  • Restart terminal to ensure all commands are available"
echo "  • Run 'claude' to start Claude Code"
echo "  • Configure Claude Code: claude config"