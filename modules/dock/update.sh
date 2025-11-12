#!/usr/bin/env bash
# update.sh - Dock module update script
# Re-configures macOS Dock with current settings from Dockfile

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"

#######################################
# Main update function
#######################################
main() {
    print_section "Updating Dock Module"

    print_status "Re-running Dock configuration..."
    echo ""

    # Simply run the install script again
    if "${SCRIPT_DIR}/install.sh"; then
        print_success "Dock module updated successfully"
    else
        print_error "Dock module update failed"
        return 1
    fi
}

# Run main function
main "$@"
