#!/usr/bin/env bash
# install.sh - Homebrew installation script
# Installs Homebrew and all packages defined in Brewfile

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
BREWFILE="${SCRIPT_DIR}/Brewfile"

# Parse command line arguments
FORCE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=1
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: $0 [--force]"
            exit 1
            ;;
    esac
done

#######################################
# Main installation function
#######################################
main() {
    print_section "Installing ${MODULE_NAME}"

    # Verify we're on macOS
    if ! is_macos; then
        print_error "This module only works on macOS"
        exit 1
    fi

    # Verify required commands exist
    if ! command_exists curl; then
        print_error "curl is required but not installed"
        exit 1
    fi

    # Check if Homebrew is already installed
    if command_exists brew; then
        print_success "Homebrew is already installed"
        brew --version

        if [[ ${FORCE} -eq 1 ]]; then
            print_warning "Force flag set, but Homebrew is already installed. Skipping reinstall."
            print_status "Use 'brew reinstall <package>' to reinstall specific packages"
        fi
    else
        print_subsection "Installing Homebrew"

        # Install Homebrew using official installation script
        print_status "Downloading and running Homebrew installation script..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH based on architecture
        if is_apple_silicon; then
            print_status "Configuring Homebrew for Apple Silicon..."
            BREW_PATH="/opt/homebrew"

            # Add to shell profile if not already present
            if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                print_success "Added Homebrew to ~/.zprofile"
            fi

            # Load Homebrew into current session
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            print_status "Configuring Homebrew for Intel..."
            BREW_PATH="/usr/local"

            # Intel Macs typically don't need PATH changes, but verify brew is accessible
            if ! command_exists brew; then
                print_warning "Homebrew installed but not in PATH. Adding to ~/.zprofile"
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi

        # Verify installation
        if command_exists brew; then
            print_success "Homebrew installed successfully"
            brew --version
        else
            print_error "Homebrew installation failed"
            exit 1
        fi
    fi

    # Update Homebrew
    print_subsection "Updating Homebrew"
    brew update || print_warning "Homebrew update had issues, continuing anyway..."

    # Install packages from Brewfile
    if [[ -f "${BREWFILE}" ]]; then
        print_subsection "Installing packages from Brewfile"
        print_status "Brewfile location: ${BREWFILE}"

        # Count packages for user feedback
        local brew_count cask_count mas_count
        brew_count=$(grep -c '^brew ' "${BREWFILE}" 2>/dev/null || echo "0")
        cask_count=$(grep -c '^cask ' "${BREWFILE}" 2>/dev/null || echo "0")
        mas_count=$(grep -c '^mas ' "${BREWFILE}" 2>/dev/null || echo "0")

        print_status "Found ${brew_count} formulae, ${cask_count} casks, and ${mas_count} Mac App Store apps"

        # Run brew bundle with proper error handling
        if brew bundle install --file="${BREWFILE}" --no-lock; then
            print_success "All packages installed successfully"
        else
            local exit_code=$?
            print_warning "Some packages failed to install (exit code: ${exit_code})"
            print_status "This is often normal - some packages may already be installed or have conflicts"
            print_status "Run 'brew bundle cleanup --file=${BREWFILE}' to see what's not in the Brewfile"
        fi
    else
        print_error "Brewfile not found at: ${BREWFILE}"
        exit 1
    fi

    # Final cleanup
    print_subsection "Cleaning up"
    brew cleanup || print_warning "Cleanup had issues, but installation is complete"

    print_success "Homebrew installation complete!"
    print_status "Homebrew prefix: $(brew --prefix)"
    print_status "Installed packages: $(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
}

# Run main function
main "$@"
