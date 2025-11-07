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

    # Get current Git user configuration (if exists)
    local current_name
    local current_email
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    # Prompt for Git user name
    local git_user_name
    if [[ -n "${current_name}" ]]; then
        git_user_name=$(prompt_input "Git user name" "${current_name}")
    else
        git_user_name=$(prompt_input "Git user name" "Your Name")
    fi

    # Prompt for Git user email
    local git_user_email
    if [[ -n "${current_email}" ]]; then
        git_user_email=$(prompt_input "Git user email" "${current_email}")
    else
        git_user_email=$(prompt_input "Git user email" "your@email.com")
    fi

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
