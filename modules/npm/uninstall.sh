#!/usr/bin/env bash
# uninstall.sh - NPM module uninstallation script
# Removes global NPM packages

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# NPM Packages Configuration
#######################################

# Array of packages to uninstall
declare -a NPM_PACKAGES=(
    "typescript"
    "prettier"
    "@anthropic-ai/claude-code"
)

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "Uninstalling NPM Module"

    # Check if npm is available
    if ! command_exists npm; then
        print_warning "npm is not installed - nothing to uninstall"
        return 0
    fi

    print_status "Uninstalling npm global packages..."
    echo ""

    local uninstalled_count=0
    local skipped_count=0

    for package in "${NPM_PACKAGES[@]}"; do
        # Check if package is installed
        if npm list -g "${package}" >/dev/null 2>&1; then
            print_status "Uninstalling: ${package}"
            if npm uninstall -g "${package}" >/dev/null 2>&1; then
                print_success "  ✓ ${package} uninstalled"
                ((uninstalled_count++))
            else
                print_error "  ✗ Failed to uninstall ${package}"
            fi
        else
            print_info "  - ${package} not installed, skipping"
            ((skipped_count++))
        fi
    done

    echo ""
    print_section "Uninstallation Summary"
    print_status "Uninstalled: ${uninstalled_count} packages"
    print_status "Skipped: ${skipped_count} packages (not installed)"
    print_success "NPM module uninstallation completed"
}

# Run main function
main "$@"
