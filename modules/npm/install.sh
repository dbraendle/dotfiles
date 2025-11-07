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

    # Check if npm is available
    if ! command_exists npm; then
        print_error "npm is not installed"
        print_status "Please install Node.js first (should be installed via homebrew module)"
        return 1
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
        print_info "  ${description}"

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
        print_info "You can retry failed packages manually with:"
        print_info "  npm install -g <package-name>"
        return 1
    fi

    print_success "NPM module installation completed"
    print_info "Installed packages can be updated with: npm update -g"
}

# Run main function
main "$@"
