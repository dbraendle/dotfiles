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

    # Ensure GNU Stow is installed
    if ! command_exists stow; then
        print_warning "GNU Stow is not installed"
        echo ""

        if command_exists brew; then
            print_status "GNU Stow can be installed via Homebrew"
            echo ""

            if confirm "Install GNU Stow now?" "y"; then
                print_status "Installing GNU Stow via Homebrew..."
                if brew install stow; then
                    print_success "GNU Stow installed successfully"
                else
                    print_error "Failed to install GNU Stow"
                    return 1
                fi
            else
                print_error "Cannot proceed without GNU Stow"
                print_status "Install manually: brew install stow"
                return 1
            fi
        else
            print_error "Homebrew is not installed"
            print_status "Please install Homebrew first, then run: brew install stow"
            return 1
        fi
        echo ""
    fi

    # Stow the Git configuration package
    print_status "Stowing Git configuration..."
    if ! stow_package "git"; then
        print_error "Failed to stow Git configuration"
        return 1
    fi

    # Create or update .gitconfig.local with user-specific values
    # This file is not tracked in the repo and contains personal data
    local gitconfig_local="${HOME}/.gitconfig.local"

    # Check if we need to create/update the file
    local needs_update=false
    if [[ ! -f "${gitconfig_local}" ]]; then
        needs_update=true
        print_status "Creating ${gitconfig_local} with user settings..."
    else
        # Check if values changed
        local existing_name
        local existing_email
        existing_name=$(git config --file="${gitconfig_local}" user.name 2>/dev/null || echo "")
        existing_email=$(git config --file="${gitconfig_local}" user.email 2>/dev/null || echo "")

        if [[ "${existing_name}" != "${git_user_name}" ]] || [[ "${existing_email}" != "${git_user_email}" ]]; then
            needs_update=true
            print_status "Updating ${gitconfig_local} with new user settings..."
        else
            print_success "${gitconfig_local} already up to date"
        fi
    fi

    if [[ "${needs_update}" == "true" ]]; then
        cat > "${gitconfig_local}" << EOF
# Local Git configuration (not tracked in dotfiles repo)
# This file is included by ~/.gitconfig

[user]
    name = ${git_user_name}
    email = ${git_user_email}
EOF

        if [[ -f "${gitconfig_local}" ]]; then
            print_success "Configured ${gitconfig_local}"
            print_success "  user.name: ${git_user_name}"
            print_success "  user.email: ${git_user_email}"
        else
            print_error "Failed to create ${gitconfig_local}"
            return 1
        fi
    fi

    print_success "Git module installation completed"
    print_status "Git configuration is now active"
}

# Run main function
main "$@"
