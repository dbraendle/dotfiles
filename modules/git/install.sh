#!/usr/bin/env bash
# install.sh - Git module installation script
# Sets up Git configuration with user-specific settings

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
    print_section "Installing Git Module"

    # Check if Git is installed
    if ! command_exists git; then
        print_error "Git is not installed"
        print_status "Please install Git first (should be installed via homebrew module)"
        return 1
    fi

    print_success "Git is installed: $(git --version)"

    # Use values from environment (set by main install.sh) or current git config
    local git_user_name="${GIT_USER_NAME:-$(git config --global user.name 2>/dev/null)}"
    local git_user_email="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null)}"

    # Validate we have values
    if [[ -z "${git_user_name}" ]]; then
        print_error "Git user name not provided"
        return 1
    fi
    if [[ -z "${git_user_email}" ]]; then
        print_error "Git user email not provided"
        return 1
    fi

    print_status "Using Git user: ${git_user_name} <${git_user_email}>"

    # Stow the Git configuration package
    print_status "Stowing Git configuration..."
    if ! stow_package "git"; then
        print_error "Failed to stow Git configuration"
        return 1
    fi

    # Set user-specific values via git config
    print_status "Configuring Git user settings..."

    if git config --global user.name "${git_user_name}"; then
        print_success "Set Git user.name: ${git_user_name}"
    else
        print_error "Failed to set Git user.name"
        return 1
    fi

    if git config --global user.email "${git_user_email}"; then
        print_success "Set Git user.email: ${git_user_email}"
    else
        print_error "Failed to set Git user.email"
        return 1
    fi

    print_success "Git module installation completed"
    print_status "Git configuration is now active"
}

# Run main function
main "$@"
