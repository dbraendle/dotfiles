#!/usr/bin/env bash
# update.sh - Update Homebrew and all installed packages

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
# Main update function
#######################################
main() {
    print_section "Updating ${MODULE_NAME}"

    # Verify we're on macOS
    if ! is_macos; then
        print_error "This module only works on macOS"
        exit 1
    fi

    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_error "Homebrew is not installed"
        print_status "Run the install script first: modules/homebrew/install.sh"
        exit 1
    fi

    print_status "Current Homebrew version: $(brew --version | head -n 1)"

    # Update Homebrew itself
    print_subsection "Updating Homebrew"
    if brew update; then
        print_success "Homebrew updated successfully"
    else
        print_error "Failed to update Homebrew"
        exit 1
    fi

    # Show outdated packages
    print_subsection "Checking for outdated packages"
    local outdated_formulae outdated_casks

    outdated_formulae=$(brew outdated --formula 2>/dev/null || echo "")
    outdated_casks=$(brew outdated --cask 2>/dev/null || echo "")

    if [[ -n "${outdated_formulae}" ]]; then
        print_status "Outdated formulae:"
        echo "${outdated_formulae}" | while IFS= read -r line; do
            echo "  - ${line}"
        done
    else
        print_success "All formulae are up to date"
    fi

    if [[ -n "${outdated_casks}" ]]; then
        print_status "Outdated casks:"
        echo "${outdated_casks}" | while IFS= read -r line; do
            echo "  - ${line}"
        done
    else
        print_success "All casks are up to date"
    fi

    # Upgrade all packages
    if [[ -n "${outdated_formulae}" || -n "${outdated_casks}" ]]; then
        print_subsection "Upgrading packages"

        if brew upgrade; then
            print_success "All packages upgraded successfully"
        else
            print_warning "Some packages failed to upgrade"
            print_status "This is often normal - some packages may have been upgraded or have conflicts"
        fi
    fi

    # Run cleanup to remove old versions
    print_subsection "Cleaning up old versions"
    if brew cleanup -s; then
        print_success "Cleanup completed successfully"
    else
        print_warning "Cleanup had some issues, but update is complete"
    fi

    # Run autoremove to remove unused dependencies
    print_subsection "Removing unused dependencies"
    local unused_deps
    unused_deps=$(brew autoremove --dry-run 2>/dev/null | grep -c "Would remove" || echo "0")

    if [[ "${unused_deps}" -gt 0 ]]; then
        print_status "Found ${unused_deps} unused dependencies"
        if brew autoremove; then
            print_success "Unused dependencies removed"
        else
            print_warning "Failed to remove some unused dependencies"
        fi
    else
        print_success "No unused dependencies found"
    fi

    # Check for issues
    print_subsection "Running diagnostics"
    if brew doctor; then
        print_success "No issues found"
    else
        print_warning "Some issues detected, but they may not be critical"
        print_status "Review the output above for details"
    fi

    # Display summary
    print_subsection "Update Summary"
    print_status "Installed packages: $(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
    print_status "Homebrew prefix: $(brew --prefix)"

    print_success "Homebrew update complete!"
}

# Run main function
main "$@"
