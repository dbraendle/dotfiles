#!/usr/bin/env bash
# uninstall.sh - Git module uninstallation script
# Removes Git configuration symlinks

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"
# shellcheck source=../../lib/stow-helpers.sh
source "${SCRIPT_DIR}/../../lib/stow-helpers.sh"

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "Uninstalling Git Module"

    # Unstow the Git configuration package
    print_status "Unstowing Git configuration..."
    if ! unstow_package "git"; then
        print_error "Failed to unstow Git configuration"
        return 1
    fi

    # Ask if user wants to remove the ~/.gitconfig file completely
    if [[ -f "${HOME}/.gitconfig" ]]; then
        print_warning "A ~/.gitconfig file still exists (may contain user settings)"

        if confirm "Do you want to remove ~/.gitconfig completely?"; then
            if create_backup "${HOME}/.gitconfig"; then
                rm -f "${HOME}/.gitconfig"
                print_success "Removed ~/.gitconfig (backup created)"
            else
                print_error "Failed to create backup of ~/.gitconfig"
                return 1
            fi
        else
            print_status "Kept existing ~/.gitconfig file"
        fi
    fi

    print_success "Git module uninstallation completed"
}

# Run main function
main "$@"
