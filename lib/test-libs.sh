#!/usr/bin/env bash
# test-libs.sh - Test script for dotfiles libraries
# This script tests all the library functions to ensure they work correctly

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the libraries
source "${SCRIPT_DIR}/colors.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/stow-helpers.sh"

# Test colors and logging
print_section "Testing Colors and Logging Functions"

print_status "This is a status message"
print_success "This is a success message"
print_warning "This is a warning message"
print_error "This is an error message"

DEBUG=1
print_debug "This is a debug message (DEBUG=1)"
DEBUG=0
print_debug "This should not appear (DEBUG=0)"

# Test utility functions
print_section "Testing Utility Functions"

print_status "System Detection:"
if is_macos; then
    print_success "Running on macOS"
    print_status "macOS version: $(get_macos_version)"
else
    print_warning "Not running on macOS"
fi

if is_apple_silicon; then
    print_success "Running on Apple Silicon"
else
    print_status "Running on Intel"
fi

if is_laptop; then
    print_success "Running on a MacBook"
else
    print_status "Running on a desktop Mac"
fi

print_status "Command checks:"
for cmd in bash git stow; do
    if command_exists "${cmd}"; then
        print_success "${cmd} is installed"
    else
        print_warning "${cmd} is not installed"
    fi
done

print_status "Dotfiles directory: $(get_dotfiles_dir)"

# Test stow helpers
print_section "Testing Stow Helper Functions"

if ensure_stow_installed; then
    print_success "GNU Stow is available"
else
    print_warning "GNU Stow is not installed"
fi

print_status "Stow directory: $(get_stow_dir || echo 'Not found')"

if [[ -f "${HOME}/.dotfiles-modules" ]]; then
    print_status "Active modules file exists"
    list_stowed_packages
else
    print_status "No active modules file yet"
fi

print_section "All Tests Complete"
print_success "Library files are working correctly!"
