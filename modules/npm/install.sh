#!/usr/bin/env bash
# install.sh - NPM module installation script
# Installs essential NPM global packages for development

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

# Array of packages with descriptions
# Format: "package:description"
declare -a NPM_PACKAGES=(
    "typescript:TypeScript compiler and language support"
    "prettier:Code formatter for JavaScript, CSS, JSON, Markdown, etc"
    "@anthropic-ai/claude-code:Claude AI coding assistant (legacy npm version)"
)

#######################################
# Main installation function
#######################################
main() {
    print_section "Installing NPM Module"

    # Ensure Homebrew is in PATH (needed after fresh homebrew installation)
    if command_exists brew; then
        eval "$(brew shellenv)"
    fi

    # Check if npm is available
    if ! command_exists npm; then
        print_warning "npm is not installed"
        echo ""

        # Check if we can install via Homebrew
        if command_exists brew; then
            print_status "Node.js can be installed via Homebrew"
            echo ""

            if confirm "Install Node.js now?" "y"; then
                print_status "Installing Node.js via Homebrew..."
                if brew install node; then
                    print_success "Node.js installed successfully"
                    # Reload PATH
                    eval "$(brew shellenv)"

                    # Verify npm is now available
                    if ! command_exists npm; then
                        print_error "npm still not found after Node.js installation"
                        return 1
                    fi
                else
                    print_error "Failed to install Node.js"
                    return 1
                fi
            else
                print_error "Cannot proceed without Node.js"
                print_status "Install Node.js manually: brew install node"
                return 1
            fi
        else
            print_error "Homebrew is not installed"
            print_status "Please install Homebrew first, then run: brew install node"
            return 1
        fi
        echo ""
    fi

    print_success "Node.js version: $(node --version)"
    print_success "npm version: $(npm --version)"
    echo ""

    # Install each package
    local failed_packages=()
    local installed_count=0

    for package_info in "${NPM_PACKAGES[@]}"; do
        IFS=':' read -r package description <<< "$package_info"

        print_status "Installing: ${package}"
        echo "  ${description}"

        if npm install -g "${package}@latest" >/dev/null 2>&1; then
            print_success "  ✓ ${package} installed"
            ((installed_count++))
        else
            print_error "  ✗ Failed to install ${package}"
            failed_packages+=("${package}")
        fi
        echo ""
    done

    # Summary
    print_section "Installation Summary"
    print_status "Successfully installed: ${installed_count}/${#NPM_PACKAGES[@]} packages"

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_warning "Failed packages:"
        for pkg in "${failed_packages[@]}"; do
            print_error "  - ${pkg}"
        done
        echo ""
        print_status "You can retry failed packages manually with:"
        print_status "  npm install -g <package-name>"
        return 1
    fi

    print_success "NPM module installation completed"
    print_status "Installed packages can be updated with: npm update -g"
}

# Run main function
main "$@"
