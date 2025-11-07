#!/usr/bin/env bash
# terminal/uninstall.sh - Uninstall Oh My Zsh and terminal configuration
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
# Main uninstall function
#######################################
main() {
    print_section "Terminal Module Uninstall"

    print_warning "This will:"
    print_warning "  - Remove Oh My Zsh"
    print_warning "  - Unstow zsh configuration files"
    print_warning "  - Keep your original .zshrc if you had one (check backups)"
    echo ""

    if ! confirm "Are you sure you want to uninstall the terminal module?"; then
        print_status "Uninstall cancelled"
        return 0
    fi

    # Step 1: Unstow the zsh configuration package
    print_status "Unstowing zsh configuration..."
    if unstow_package "zsh"; then
        print_success "Zsh configuration unstowed successfully"
    else
        print_warning "Failed to unstow zsh configuration (may not have been stowed)"
    fi

    # Step 2: Remove Oh My Zsh
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        print_status "Removing Oh My Zsh..."

        # Use Oh My Zsh's uninstall script if available
        if [[ -f "${HOME}/.oh-my-zsh/tools/uninstall.sh" ]]; then
            print_status "Running Oh My Zsh uninstall script..."
            # Run uninstall script with unattended mode
            if sh "${HOME}/.oh-my-zsh/tools/uninstall.sh" --unattended; then
                print_success "Oh My Zsh uninstalled successfully"
            else
                print_warning "Oh My Zsh uninstall script failed, removing directory manually..."
                rm -rf "${HOME}/.oh-my-zsh"
                print_success "Oh My Zsh directory removed"
            fi
        else
            # Manually remove if uninstall script not found
            print_status "Removing Oh My Zsh directory..."
            rm -rf "${HOME}/.oh-my-zsh"
            print_success "Oh My Zsh directory removed"
        fi
    else
        print_success "Oh My Zsh is not installed"
    fi

    # Step 3: Information about restoring shell
    print_status ""
    print_status "Note: Your default shell is still set to Zsh"
    print_status "To change it back to bash, run:"
    print_status "  chsh -s /bin/bash"

    print_success "Terminal module uninstalled successfully!"
}

# Run main function
main "$@"
