#!/usr/bin/env bash
# uninstall.sh - Dock module uninstallation script
# Resets macOS Dock to system defaults

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "Uninstalling Dock Module"

    print_warning "This will reset your Dock to macOS defaults!"
    echo ""

    if ! confirm "Reset Dock to defaults?" "y"; then
        print_status "Dock reset cancelled"
        return 0
    fi
    echo ""

    print_status "Resetting Dock to macOS defaults..."

    # Delete Dock preferences
    if defaults delete com.apple.dock 2>/dev/null; then
        print_success "Dock preferences deleted"
    else
        print_warning "Could not delete Dock preferences (may already be at defaults)"
    fi

    # Restart Dock to apply defaults
    print_status "Restarting Dock..."
    killall Dock

    echo ""
    print_success "Dock module uninstalled successfully"
    print_status "Dock has been reset to macOS defaults"
}

# Run main function
main "$@"
