#!/bin/bash

# Zsh Configuration Installer
# Updates and configures zsh settings
#
# Usage:
#   chmod +x zsh-install.sh
#   ./zsh-install.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "=========================================="
echo "🐚 Zsh Configuration Update"
echo "=========================================="

# Check if we're in the dotfiles directory
if [ ! -f ".zshrc" ]; then
    print_warning "Not in dotfiles directory or .zshrc not found"
    print_status "Please run this script from your dotfiles directory"
    exit 1
fi

# Step 1: Install/Update Oh My Zsh
print_status "Step 1: Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    read -p "🦄 Install Oh My Zsh? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    else
        print_status "Oh My Zsh installation skipped"
    fi
else
    read -p "🔄 Update Oh My Zsh? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Updating Oh My Zsh..."
        cd "$HOME/.oh-my-zsh"
        git pull origin master >/dev/null 2>&1
        cd - >/dev/null
        print_success "Oh My Zsh updated"
    else
        print_status "Oh My Zsh update skipped"
    fi
fi

# Step 2: Install .zshrc configuration
print_status "Step 2: Zsh Configuration"
read -p "📝 Install/update .zshrc configuration? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing .zshrc configuration..."
    cp .zshrc "$HOME/.zshrc"
    print_success "Zsh configuration installed"
    
    # Check for scan shortcuts
    if [ -f ".scan-shortcuts.sh" ]; then
        print_status "Scan shortcuts found - they will be loaded automatically"
    fi
else
    print_status "Zsh configuration installation skipped"
fi

# Step 3: Homebrew plugins (if Homebrew is installed)
if command -v brew &> /dev/null; then
    print_status "Step 3: Zsh Plugins via Homebrew"
    
    # Check if plugins are already installed
    plugins_to_install=()
    
    if ! brew list zsh-autosuggestions &> /dev/null; then
        plugins_to_install+=("zsh-autosuggestions")
    fi
    
    if ! brew list zsh-syntax-highlighting &> /dev/null; then
        plugins_to_install+=("zsh-syntax-highlighting")
    fi
    
    if [ ${#plugins_to_install[@]} -gt 0 ]; then
        echo "Missing plugins: ${plugins_to_install[*]}"
        read -p "🔌 Install missing zsh plugins? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for plugin in "${plugins_to_install[@]}"; do
                print_status "Installing $plugin..."
                brew install "$plugin"
            done
            print_success "Zsh plugins installed"
        else
            print_status "Zsh plugins installation skipped"
        fi
    else
        print_success "All zsh plugins already installed"
    fi
else
    print_status "Step 3: Homebrew not found - skipping plugin installation"
fi

# Step 4: Apply configuration
print_status "Step 4: Apply Configuration"
read -p "🔄 Reload zsh configuration now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Reloading zsh configuration..."
    # Source the new configuration
    if [ -n "$ZSH_VERSION" ]; then
        source "$HOME/.zshrc"
        print_success "Zsh configuration reloaded"
    else
        print_status "Not running in zsh - restart terminal to apply changes"
    fi
else
    print_status "Manual reload required - run: source ~/.zshrc"
fi

echo ""
echo "=========================================="
print_success "✅ Zsh configuration update completed!"
echo "=========================================="
print_status "Next steps:"
echo "  • Restart terminal if configuration wasn't auto-reloaded"
echo "  • Test your aliases and shortcuts"
if [ -f ".scan-shortcuts.sh" ]; then
    echo "  • Your scan shortcuts are ready to use"
fi
echo "  • Enjoy your updated shell! 🎉"