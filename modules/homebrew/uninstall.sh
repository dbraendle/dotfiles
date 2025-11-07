#!/usr/bin/env bash
# uninstall.sh - Uninstall Homebrew completely
# WARNING: This is a destructive operation that will remove Homebrew and all installed packages

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${DOTFILES_DIR}/lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"

# Module-specific configuration
MODULE_NAME="homebrew"

#######################################
# Main uninstall function
#######################################
main() {
    print_section "Uninstalling ${MODULE_NAME}"

    # Verify we're on macOS
    if ! is_macos; then
        print_error "This module only works on macOS"
        exit 1
    fi

    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_warning "Homebrew is not installed, nothing to uninstall"
        exit 0
    fi

    # Show what will be removed
    print_warning "WARNING: This will completely remove Homebrew and ALL installed packages!"
    echo ""
    print_status "Currently installed:"
    print_status "  - Formulae: $(brew list --formula | wc -l | tr -d ' ')"
    print_status "  - Casks: $(brew list --cask | wc -l | tr -d ' ')"
    print_status "  - Homebrew location: $(brew --prefix)"
    echo ""

    # Show some of the installed packages
    local formula_list cask_list
    formula_list=$(brew list --formula 2>/dev/null | head -10 | tr '\n' ' ')
    cask_list=$(brew list --cask 2>/dev/null | head -10 | tr '\n' ' ')

    if [[ -n "${formula_list}" ]]; then
        print_status "Some installed formulae: ${formula_list}..."
    fi
    if [[ -n "${cask_list}" ]]; then
        print_status "Some installed casks: ${cask_list}..."
    fi
    echo ""

    print_warning "This operation cannot be easily undone!"
    print_warning "You will need to reinstall Homebrew and all packages manually."
    echo ""

    # Require explicit confirmation
    if ! confirm "Are you absolutely sure you want to uninstall Homebrew?" "n"; then
        print_status "Uninstall cancelled"
        exit 0
    fi

    # Second confirmation for safety
    echo ""
    if ! confirm "Last chance! Really uninstall Homebrew and all packages?" "n"; then
        print_status "Uninstall cancelled"
        exit 0
    fi

    print_subsection "Uninstalling Homebrew"

    # Download and run official uninstall script
    print_status "Downloading official Homebrew uninstall script..."

    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"; then
        print_success "Homebrew uninstalled successfully"
    else
        print_error "Homebrew uninstall script failed"
        print_status "You may need to manually remove Homebrew directories"
        exit 1
    fi

    # Clean up shell profile entries
    print_subsection "Cleaning up shell configuration"

    local modified=0

    # Remove from .zprofile
    if [[ -f ~/.zprofile ]] && grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
        print_status "Removing Homebrew from ~/.zprofile..."
        create_backup ~/.zprofile
        grep -v 'brew shellenv' ~/.zprofile > ~/.zprofile.tmp && mv ~/.zprofile.tmp ~/.zprofile
        modified=1
    fi

    # Remove from .zshrc (in case it was added there)
    if [[ -f ~/.zshrc ]] && grep -q 'brew shellenv' ~/.zshrc 2>/dev/null; then
        print_status "Removing Homebrew from ~/.zshrc..."
        create_backup ~/.zshrc
        grep -v 'brew shellenv' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
        modified=1
    fi

    # Remove from .bash_profile (for older systems)
    if [[ -f ~/.bash_profile ]] && grep -q 'brew shellenv' ~/.bash_profile 2>/dev/null; then
        print_status "Removing Homebrew from ~/.bash_profile..."
        create_backup ~/.bash_profile
        grep -v 'brew shellenv' ~/.bash_profile > ~/.bash_profile.tmp && mv ~/.bash_profile.tmp ~/.bash_profile
        modified=1
    fi

    if [[ ${modified} -eq 1 ]]; then
        print_success "Shell configuration cleaned up (backups created)"
    else
        print_status "No shell configuration changes needed"
    fi

    # Verify uninstallation
    print_subsection "Verifying uninstallation"

    if command_exists brew; then
        print_warning "Homebrew command still exists in PATH"
        print_status "You may need to restart your shell or manually remove Homebrew directories"
    else
        print_success "Homebrew command successfully removed from PATH"
    fi

    # Check for remaining directories
    local remaining_dirs=()
    if is_apple_silicon; then
        [[ -d "/opt/homebrew" ]] && remaining_dirs+=("/opt/homebrew")
    else
        [[ -d "/usr/local/Homebrew" ]] && remaining_dirs+=("/usr/local/Homebrew")
    fi
    [[ -d "${HOME}/.homebrew" ]] && remaining_dirs+=("${HOME}/.homebrew")
    [[ -d "${HOME}/Library/Caches/Homebrew" ]] && remaining_dirs+=("${HOME}/Library/Caches/Homebrew")

    if [[ ${#remaining_dirs[@]} -gt 0 ]]; then
        print_warning "Some Homebrew directories still exist:"
        for dir in "${remaining_dirs[@]}"; do
            print_status "  - ${dir}"
        done
        print_status "These may be safe to manually remove if the uninstall was incomplete"
    else
        print_success "All Homebrew directories removed"
    fi

    print_success "Homebrew uninstallation complete!"
    print_warning "Please restart your terminal for changes to take effect"
}

# Run main function
main "$@"
