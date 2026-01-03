#!/usr/bin/env bash
# terminal/update.sh - Update Oh My Zsh and terminal configuration
# Part of the dotfiles v2 modular system

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${DOTFILES_DIR}/lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"
# shellcheck source=../../lib/stow-helpers.sh
source "${DOTFILES_DIR}/lib/stow-helpers.sh"

#######################################
# Main update function
#######################################
main() {
    print_section "Terminal Module Update"

    # Step 1: Update Oh My Zsh
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        print_status "Updating Oh My Zsh..."

        # Save current directory
        local original_dir="${PWD}"

        # Change to Oh My Zsh directory and pull updates
        if cd "${HOME}/.oh-my-zsh" && git pull origin master; then
            print_success "Oh My Zsh updated successfully"
        else
            print_error "Failed to update Oh My Zsh"
            cd "${original_dir}"
            return 1
        fi

        # Return to original directory
        cd "${original_dir}"
    else
        print_warning "Oh My Zsh is not installed"
        print_status "Run the install script first: modules/terminal/install.sh"
        return 1
    fi

    # Step 2: Restow configuration (in case it changed)
    print_status "Restowing zsh configuration..."
    if restow_package "zsh"; then
        print_success "Zsh configuration restowed successfully"
    else
        print_warning "Failed to restow zsh configuration (may already be up to date)"
    fi

    print_success "Terminal module updated successfully!"
    print_status ""
    print_status "Changes will take effect:"
    print_status "  - Restart your terminal, or"
    print_status "  - Run: source ~/.zshrc"
}

# Run main function
main "$@"
