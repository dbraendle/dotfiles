#!/usr/bin/env bash
# update.sh - NPM module update script
# Updates all global NPM packages

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Main update function
#######################################
main() {
    print_section "Updating NPM Module"

    # Check if npm is available
    if ! command_exists npm; then
        print_error "npm is not installed"
        return 1
    fi

    print_status "Checking for npm package updates..."
    echo ""

    # List outdated packages
    if npm outdated -g --depth=0 2>/dev/null | grep -v "Package" | grep -v "^$"; then
        print_warning "Found outdated packages"
        echo ""

        print_status "Updating all global packages..."
        if npm update -g; then
            print_success "All npm packages updated"
        else
            print_error "Failed to update some packages"
            return 1
        fi
    else
        print_success "All npm packages are up to date"
    fi

    echo ""
    print_status "Current global packages:"
    npm list -g --depth=0 2>/dev/null | grep -E "(typescript|prettier|claude-code)" || true

    print_success "NPM module update completed"
}

# Run main function
main "$@"
