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

# Accept Xcode license (required for many developer tools)
if command -v xcodebuild >/dev/null 2>&1; then
    # Check if license is already accepted
    if ! xcodebuild -license check 2>/dev/null; then
        print_status "Xcode license needs to be accepted..."
        echo "→ Please enter your password to accept Xcode license:"
        sudo xcodebuild -license accept
        print_success "Xcode license accepted"
    else
        print_success "Xcode license already accepted"
    fi
fi

# Step 2: macOS System Settings (optional)
if [ -f "macos-settings.sh" ]; then
    print_status "Step 2: macOS System Settings"
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
    print_status "Step 2: macOS settings file not found - skipping"
fi

# Step 3: Homebrew Package Manager
print_status "Step 3: Homebrew Package Manager"

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

# Step 4: Apps Installation (optional)
if [ -f "Brewfile" ]; then
    print_status "Step 4: Apps Installation" 
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
    print_status "Step 4: Brewfile not found - skipping app installation"
fi

# Step 4.5: SSH Management Tool
install_ssh_wunderbar() {
    # Finde das aktuelle dotfiles Verzeichnis
    local dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dotfiles_name=$(basename "$dotfiles_dir")
    
    print_status "Installing ssh-wunderbar..."
    echo "📦 Where should ssh-wunderbar be installed?"
    echo "  1) /usr/local/bin (recommended - system-wide)"
    echo "  2) ~/.local/bin (user-only)"
    echo "  3) $dotfiles_dir/bin (with your $dotfiles_name)"
    
    read -p "Choice (1-3, default: 1): " install_choice
    install_choice=${install_choice:-1}
    
    case $install_choice in
        1) 
            install_dir="/usr/local/bin"
            # Check if we need sudo for /usr/local/bin
            if [ ! -w "$install_dir" ]; then
                print_status "Need sudo access for $install_dir"
                sudo mkdir -p "$install_dir"
            fi
            ;;
        2) 
            install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
            # Add to PATH if not already there
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
                print_status "Added ~/.local/bin to PATH in ~/.zshrc"
            fi
            ;;
        3) 
            install_dir="$dotfiles_dir/bin"
            mkdir -p "$install_dir"
            # Add to PATH if not already there
            if [[ ":$PATH:" != *":$install_dir:"* ]]; then
                echo "export PATH=\"$install_dir:\$PATH\"" >> ~/.zshrc
                print_status "Added $install_dir to PATH in ~/.zshrc"
            fi
            ;;
        *)
            print_status "Invalid choice, defaulting to /usr/local/bin"
            install_dir="/usr/local/bin"
            if [ ! -w "$install_dir" ]; then
                print_status "Need sudo access for $install_dir"
                sudo mkdir -p "$install_dir"
            fi
            ;;
    esac
    
    # Create directory if not exists (with sudo if needed)
    if [ ! -d "$install_dir" ]; then
        if [[ "$install_dir" == "/usr/local/bin" ]]; then
            sudo mkdir -p "$install_dir"
        else
            mkdir -p "$install_dir"
        fi
    fi
    
    # Download ssh-wunderbar
    if command -v gh &> /dev/null; then
        print_status "🐙 Downloading via GitHub CLI..."
        # Clean up any existing temp directory
        rm -rf /tmp/ssh-wunderbar
        if gh repo clone dbraendle/ssh-wunderbar /tmp/ssh-wunderbar; then
            if [[ "$install_dir" == "/usr/local/bin" ]]; then
                sudo cp /tmp/ssh-wunderbar/ssh-wunderbar "$install_dir/"
                sudo cp /tmp/ssh-wunderbar/test.sh "$install_dir/"
            else
                cp /tmp/ssh-wunderbar/ssh-wunderbar "$install_dir/"
                cp /tmp/ssh-wunderbar/test.sh "$install_dir/"
            fi
            rm -rf /tmp/ssh-wunderbar
        else
            print_status "GitHub CLI download failed, falling back to direct download..."
            if [[ "$install_dir" == "/usr/local/bin" ]]; then
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar | sudo tee "$install_dir/ssh-wunderbar" > /dev/null
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh | sudo tee "$install_dir/test.sh" > /dev/null
            else
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar > "$install_dir/ssh-wunderbar"
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh > "$install_dir/test.sh"
            fi
        fi
    else
        print_status "📥 Downloading directly from GitHub..."
        if [[ "$install_dir" == "/usr/local/bin" ]]; then
            curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar | sudo tee "$install_dir/ssh-wunderbar" > /dev/null
            curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh | sudo tee "$install_dir/test.sh" > /dev/null
        else
            curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar > "$install_dir/ssh-wunderbar"
            curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh > "$install_dir/test.sh"
        fi
    fi
    
    # Set permissions
    if [[ "$install_dir" == "/usr/local/bin" ]]; then
        sudo chmod +x "$install_dir/ssh-wunderbar"
        sudo chmod +x "$install_dir/test.sh"
    else
        chmod +x "$install_dir/ssh-wunderbar"
        chmod +x "$install_dir/test.sh"
    fi
    
    print_success "✅ ssh-wunderbar installed to $install_dir"
    print_status "Usage: ssh-wunderbar --help"
    
    return 0
}

print_status "Step 4.5: SSH Management Tool"
if command -v ssh-wunderbar &> /dev/null; then
    current_location=$(which ssh-wunderbar)
    print_status "ssh-wunderbar already installed at: $current_location"
    read -p "🔄 Update to latest version? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Updating ssh-wunderbar to latest version..."
        
        # Update at current location without asking where to install
        install_dir=$(dirname "$current_location")
        
        # Clean up any existing temp directory
        rm -rf /tmp/ssh-wunderbar
        
        # Download latest version
        if command -v gh &> /dev/null; then
            print_status "🐙 Downloading via GitHub CLI..."
            if gh repo clone dbraendle/ssh-wunderbar /tmp/ssh-wunderbar; then
                if [[ "$current_location" == "/usr/local/bin/ssh-wunderbar" ]]; then
                    sudo cp /tmp/ssh-wunderbar/ssh-wunderbar "$current_location"
                    sudo cp /tmp/ssh-wunderbar/test.sh "$install_dir/test.sh"
                    sudo chmod +x "$current_location"
                    sudo chmod +x "$install_dir/test.sh"
                else
                    cp /tmp/ssh-wunderbar/ssh-wunderbar "$current_location"
                    cp /tmp/ssh-wunderbar/test.sh "$install_dir/test.sh"
                    chmod +x "$current_location"
                    chmod +x "$install_dir/test.sh"
                fi
                rm -rf /tmp/ssh-wunderbar
            else
                print_status "GitHub CLI download failed, falling back to direct download..."
                if [[ "$current_location" == "/usr/local/bin/ssh-wunderbar" ]]; then
                    curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar | sudo tee "$current_location" > /dev/null
                    curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh | sudo tee "$install_dir/test.sh" > /dev/null
                    sudo chmod +x "$current_location"
                    sudo chmod +x "$install_dir/test.sh"
                else
                    curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar > "$current_location"
                    curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh > "$install_dir/test.sh"
                    chmod +x "$current_location"
                    chmod +x "$install_dir/test.sh"
                fi
            fi
        else
            print_status "📥 Downloading directly from GitHub..."
            if [[ "$current_location" == "/usr/local/bin/ssh-wunderbar" ]]; then
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar | sudo tee "$current_location" > /dev/null
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh | sudo tee "$install_dir/test.sh" > /dev/null
                sudo chmod +x "$current_location"
                sudo chmod +x "$install_dir/test.sh"
            else
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/ssh-wunderbar > "$current_location"
                curl -fsSL https://raw.githubusercontent.com/dbraendle/ssh-wunderbar/main/test.sh > "$install_dir/test.sh"
                chmod +x "$current_location"
                chmod +x "$install_dir/test.sh"
            fi
        fi
        
        print_success "✅ ssh-wunderbar updated at $current_location"
    else
        print_status "ssh-wunderbar update skipped"
    fi
else
    read -p "🔑 Install ssh-wunderbar for SSH key management? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_ssh_wunderbar
    else
        print_status "ssh-wunderbar installation skipped"
    fi
fi

# Step 5: NPM Global Packages (optional)
if [ -f "npm-install.sh" ]; then
    print_status "Step 5: NPM Global Packages"
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
    print_status "Step 5: npm-install.sh not found - skipping NPM packages"
fi

# Step 6: Terminal Setup (optional)
print_status "Step 6: Terminal Setup"
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

# Step 7: Git Configuration (optional)
print_status "Step 7: Git Configuration"
if command -v git &> /dev/null; then
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        print_success "Git already configured: $current_name <$current_email>"
        read -p "🔧 Reconfigure Git settings and install templates? (y/n): " -n 1 -r
    else
        read -p "🔧 Configure Git user settings? (y/n): " -n 1 -r
    fi
    
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        if [ -n "$current_email" ]; then
            read -p "📧 Git email address ($current_email): " git_email
            git_email=${git_email:-$current_email}
        else
            read -p "📧 Git email address: " git_email
        fi
        
        if [ -n "$current_name" ]; then
            read -p "👤 Git username ($current_name): " git_username
            git_username=${git_username:-$current_name}
        else
            read -p "👤 Git username: " git_username
        fi
        
        if [ -n "$git_email" ] && [ -n "$git_username" ]; then
            # Install .gitconfig template if available
            if [ -f ".gitconfig" ]; then
                print_status "Installing .gitconfig template with aliases and settings..."
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
    print_status "Git not found - install via Brewfile first"
fi

# Step 8: SSH Configuration (optional)
if command -v ssh-wunderbar &> /dev/null; then
    print_status "Step 8: SSH Configuration"
    read -p "🔑 Configure SSH keys and servers? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_status "🚀 Opening ssh-wunderbar interactive setup..."
        print_status "Configure your SSH keys and servers. When finished, the setup will continue."
        echo ""
        echo "Press Enter to continue..."
        read
        
        # Run ssh-wunderbar interactively - user returns to install.sh when done
        # Create ~/.ssh-services.json if it doesn't exist
        if [ ! -f "$HOME/.ssh-services.json" ]; then
            print_status "Creating SSH services configuration..."
            cat > "$HOME/.ssh-services.json" << 'EOF'
{
  "_comment": "SSH Services Configuration",
  "_description": "Personal SSH server and service definitions",
  "_managed_by": "ssh-wunderbar - https://github.com/dbraendle/ssh-wunderbar",
  "_location": "This file should be located at: ~/.ssh-services.json",
  
  "version": "1.0",
  "services": {},
  "settings": {
    "default_key_type": "ed25519",
    "auto_backup_config": true,
    "cleanup_old_keys": false,
    "key_rotation_days": 365
  }
}
EOF
        fi
        
        ssh-wunderbar
        
        echo ""
        print_success "🔑 SSH configuration completed!"
        print_status "Continuing with setup..."
    else
        print_status "SSH configuration skipped"
        print_status "You can run 'ssh-wunderbar' anytime to setup SSH keys"
    fi
elif [ -f "ssh/ssh-setup.sh" ]; then
    print_status "Step 8: SSH Configuration (Legacy)"
    read -p "🔑 Configure SSH using legacy script? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Running legacy SSH setup..."
        chmod +x ssh/ssh-setup.sh
        ./ssh/ssh-setup.sh
        if [ $? -eq 0 ]; then
            print_success "SSH setup completed"
        else
            print_status "SSH setup skipped or failed"
        fi
    else
        print_status "SSH setup skipped"
    fi
else
    print_status "Step 8: SSH setup not available - install ssh-wunderbar first"
fi

echo ""
echo "=========================================="
print_success "✅ Setup completed successfully!"
echo "=========================================="
print_status "Next steps:"
echo "  • Restart terminal to apply new configuration"
if command -v ssh-wunderbar &> /dev/null; then
    echo "  • Use 'ssh-wunderbar --help' to manage SSH keys"
    echo "  • Add servers with: ssh-wunderbar --add-service myserver host user port"
fi
echo "  • Open VS Code and sign in to GitHub for settings sync"
echo "  • Customize Finder sidebar manually if needed"
echo "  • Enjoy your new Mac setup! 🎉"