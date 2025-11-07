#!/usr/bin/env bash
# update.sh - Mounts module update script
# Reloads autofs configuration and remounts network shares

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Configuration paths
#######################################
MOUNTS_CONFIG="${DOTFILES_ROOT}/mounts.config"

#######################################
# Main update function
#######################################
main() {
    print_section "Updating Mounts Module"

    # Check if running on macOS
    if ! is_macos; then
        print_error "This module is only supported on macOS"
        return 1
    fi

    # Check if automount command exists
    if ! command_exists automount; then
        print_error "automount command not found"
        return 1
    fi

    # Check if configuration exists
    if [[ ! -f "$MOUNTS_CONFIG" ]]; then
        print_error "Configuration file not found: $MOUNTS_CONFIG"
        print_status "Run install.sh first to set up mounts"
        return 1
    fi

    print_status "Reloading autofs configuration..."
    echo ""

    # Reload autofs
    if sudo automount -vc; then
        print_success "autofs configuration reloaded"
        echo ""
        print_status "All mounts will be remounted automatically when accessed"
    else
        print_error "Failed to reload autofs"
        echo ""
        print_status "You may need to reboot for changes to take effect"
        return 1
    fi

    echo ""
    print_success "Update completed successfully"
}

# Run main function
main "$@"
