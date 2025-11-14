#!/usr/bin/env bash
# brew-update.sh - Quick Homebrew package update from Brewfile
# Usage: ./brew-update.sh (from anywhere)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging library
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"

print_section "Homebrew Package Update"

# Auto-detect profile
if is_laptop; then
    export DOTFILES_PROFILE="laptop"
    print_status "Detected: MacBook (laptop profile)"
else
    export DOTFILES_PROFILE="desktop"
    print_status "Detected: Desktop Mac (desktop profile)"
fi

# Check if Brewfile exists
if [[ ! -f "${SCRIPT_DIR}/Brewfile" ]]; then
    print_error "Brewfile not found in ${SCRIPT_DIR}"
    exit 1
fi

print_status "Updating Homebrew packages from Brewfile..."
echo ""

# Run brew bundle
cd "${SCRIPT_DIR}"
if brew bundle install; then
    echo ""
    print_success "Homebrew packages updated successfully!"
    print_status "Profile: ${DOTFILES_PROFILE}"
else
    echo ""
    print_error "Homebrew bundle install failed"
    exit 1
fi
