#!/bin/bash

# Homebrew Installation Script
# This script only handles Homebrew and Brewfile installation
# Usage: ./brew-install.sh

set -e  # Exit on any error

echo "🍺 Starting Homebrew installation..."

# Check if Homebrew is already installed
if command -v brew >/dev/null 2>&1; then
    echo "✅ Homebrew is already installed"
    brew --version
else
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo "🔧 Adding Homebrew to PATH for Apple Silicon..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# Install packages from Brewfile
if [ -f "Brewfile" ]; then
    echo "📋 Installing packages from Brewfile..."
    
    brew bundle install
    echo "✅ All packages installed successfully!"
else
    echo "❌ Brewfile not found in current directory"
    exit 1
fi

echo "🎉 Homebrew setup complete!"