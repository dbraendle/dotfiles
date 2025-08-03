#!/bin/bash

# System Updates Script
# Usage: ./update.sh

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
echo "🔄 System Updates Check"
echo "=========================================="

# Check what needs updating first
print_status "Checking for available updates..."

# macOS Updates
print_status "Checking macOS updates..."
softwareupdate -l 2>/dev/null | grep -v "No new software available" || print_success "macOS is up to date"

# Homebrew Updates
print_status "Checking Homebrew updates..."
brew update >/dev/null
outdated=$(brew outdated)

if [ -n "$outdated" ]; then
    echo ""
    print_warning "Outdated packages:"
    echo "$outdated"
    echo ""
    
    read -p "🔄 Update all Homebrew packages? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Updating Homebrew packages..."
        brew upgrade
        print_success "Homebrew packages updated"
    else
        print_status "Homebrew updates skipped"
    fi
else
    print_success "All Homebrew packages are up to date"
fi

# npm global packages
if command -v npm >/dev/null 2>&1; then
    print_status "Checking npm global packages..."
    npm_outdated=$(npm outdated -g 2>/dev/null || echo "")
    
    if [ -n "$npm_outdated" ]; then
        echo ""
        print_warning "Outdated npm global packages:"
        echo "$npm_outdated"
        echo ""
        
        read -p "🔄 Update npm global packages? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating npm global packages..."
            npm update -g
            print_success "npm global packages updated"
        else
            print_status "npm updates skipped"
        fi
    else
        print_success "All npm global packages are up to date"
    fi
fi

# Cleanup
print_status "Cleaning up..."
brew cleanup
print_success "Cleanup completed"

echo ""
echo "=========================================="
print_success "✅ Update check completed!"
echo "=========================================="