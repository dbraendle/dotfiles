#!/usr/bin/env bash
# install.sh - Applications module installation script
# Manages configurations for macOS applications using GNU Stow

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
# Main installation function
#######################################
main() {
    print_section "Installing Applications Module"

    # Ensure stow is installed
    if ! ensure_stow_installed; then
        return 1
    fi

    # Get stow directory
    local stow_dir
    stow_dir="$(get_stow_dir)" || return 1

    # Stow packages (add more apps here as needed)
    local packages=("sublime")

    for package in "${packages[@]}"; do
        if [[ -d "${stow_dir}/${package}" ]]; then
            print_status "Stowing ${package}..."
            if stow_package "${package}"; then
                print_success "${package} configuration linked"
            else
                print_warning "Failed to stow ${package}"
            fi
        else
            print_debug "Package ${package} not found in ${stow_dir}, skipping"
        fi
    done

    print_success "Applications module installed successfully"
}

# Run main function
main "$@"
