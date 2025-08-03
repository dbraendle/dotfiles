#!/bin/bash

# Mac Development Environment Setup
# Modular setup script
#
# Usage:
#   chmod +x install.sh
#   ./install.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "=========================================="
echo "🛠️  Mac Development Setup"
echo "=========================================="

# Step 1: Xcode Command Line Tools
print_status "Step 1: Xcode Command Line Tools"
if ! xcode-select -p &> /dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    xcode-select --install
    
    print_status "Waiting for installation to complete..."
    echo "→ Please click 'Install' in the popup window"
    echo "→ Press Ctrl+C to cancel if installation fails"
    
    # Wait with timeout
    timeout=0
    max_timeout=1800  # 30 minutes maximum
    
    while ! xcode-select -p &> /dev/null; do
        sleep 30
        timeout=$((timeout + 30))
        
        if [ $timeout -ge $max_timeout ]; then
            echo ""
            echo "❌ Installation timeout after 30 minutes"
            echo "Please install manually: xcode-select --install"
            exit 1
        fi
        
        echo "→ Installation in progress... (${timeout}s elapsed)"
    done
    
    print_success "Xcode Command Line Tools installed"
else
    print_success "Xcode Command Line Tools already installed"
fi

# Step 2: Homebrew Package Manager
print_status "Step 2: Homebrew Package Manager"

# Check if Homebrew binary exists and load PATH
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Now check if brew command is available
if command -v brew &> /dev/null; then
    print_success "Homebrew already installed"
    
    # Check if updates are available
    print_status "Checking for Homebrew updates..."
    if brew outdated --quiet 2>/dev/null | head -1 | grep -q .; then
        print_status "Updates available - updating Homebrew..."
        brew update
    else
        print_status "Homebrew is up to date"
    fi
else
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    print_success "Homebrew installed"
fi

# Step 3: Apps Installation (optional)
if [ -f "Brewfile" ]; then
    print_status "Step 3: Apps Installation" 
    read -p "📦 Install apps from Brewfile? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing apps from Brewfile..."
        brew bundle install
        print_success "Apps installed"
    else
        print_status "Apps installation skipped"
    fi
else
    print_status "Step 3: Brewfile not found - skipping app installation"
fi

# Step 4: Terminal Setup (optional)
print_status "Step 4: Terminal Setup"
read -p "🖥️  Install Oh My Zsh and terminal configuration? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    else
        print_success "Oh My Zsh already installed"
    fi
    
    # Install .zshrc configuration
    if [ -f ".zshrc" ]; then
        print_status "Installing .zshrc configuration..."
        cp .zshrc "$HOME/.zshrc"
        print_success "Terminal configuration installed"
        print_status "Restart terminal or run: source ~/.zshrc"
    else
        print_status ".zshrc template not found - skipping terminal configuration"
    fi
else
    print_status "Terminal setup skipped"
fi

# Step 5: Git Configuration (optional)
print_status "Step 5: Git Configuration"
if command -v git &> /dev/null; then
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -z "$current_name" ] || [ -z "$current_email" ]; then
        read -p "🔧 Configure Git user settings? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            read -p "📧 Git email address: " git_email
            read -p "👤 Git username: " git_username
            
            if [ -n "$git_email" ] && [ -n "$git_username" ]; then
                # Install .gitconfig template if available
                if [ -f ".gitconfig" ]; then
                    print_status "Installing .gitconfig template..."
                    # Replace placeholders and copy
                    sed "s/PLACEHOLDER_NAME/$git_username/g; s/PLACEHOLDER_EMAIL/$git_email/g" .gitconfig > "$HOME/.gitconfig"
                    print_success "Git configuration installed with aliases and settings"
                else
                    # Fallback: basic git config
                    git config --global user.name "$git_username"
                    git config --global user.email "$git_email"
                    git config --global init.defaultBranch main
                    git config --global core.editor "code --wait"
                    git config --global pull.rebase false
                    git config --global push.default simple
                    print_success "Basic Git configuration set"
                fi
                
                print_success "Git configured: $git_username <$git_email>"
            else
                print_status "Git configuration skipped (empty values)"
            fi
        else
            print_status "Git configuration skipped"
        fi
    else
        print_success "Git already configured: $current_name <$current_email>"
    fi
else
    print_status "Git not found - install via Brewfile first"
fi

# Step 6: NPM Global Packages (optional)
if [ -f "npm-install.sh" ]; then
    print_status "Step 6: NPM Global Packages"
    read -p "📦 Install NPM global packages? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Running NPM packages installation..."
        chmod +x npm-install.sh
        ./npm-install.sh
        print_success "NPM packages installed"
    else
        print_status "NPM packages installation skipped"
    fi
else
    print_status "Step 6: npm-install.sh not found - skipping NPM packages"
fi

# Step 7: macOS System Settings (optional)
if [ -f "macos-settings.sh" ]; then
    print_status "Step 7: macOS System Settings"
    read -p "🔧 Apply macOS system settings? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying macOS settings..."
        source macos-settings.sh
        print_success "macOS settings applied"
    else
        print_status "macOS settings skipped"
    fi
else
    print_status "Step 7: macOS settings file not found - skipping"
fi

echo ""
echo "=========================================="
print_success "✅ Setup completed successfully!"
echo "=========================================="
print_status "Next steps:"
echo "  • Restart terminal to apply new configuration"
echo "  • Open VS Code and sign in to GitHub for settings sync"
echo "  • Customize Finder sidebar manually if needed"
echo "  • Enjoy your new Mac setup! 🎉"