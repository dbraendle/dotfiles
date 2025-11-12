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

        # Check if user has admin rights (required for Homebrew installation)
        if ! check_admin_rights; then
            print_error "Homebrew installation requires administrator privileges"
            print_error "Current user '$(get_real_user)' is not in the admin group"
            echo ""
            print_status "To fix this:"
            print_status "1. Go to System Settings → Users & Groups"
            print_status "2. Unlock with your password"
            print_status "3. Select user '$(get_real_user)' and check 'Allow user to administer this computer'"
            print_status "4. Log out and log back in"
            print_status "5. Run this installation again"
            echo ""
            return 1
        fi

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

        # Trim any whitespace/newlines
        brew_count=$(echo "${brew_count}" | tr -d '\n\r ')
        cask_count=$(echo "${cask_count}" | tr -d '\n\r ')
        mas_count=$(echo "${mas_count}" | tr -d '\n\r ')

        print_status "Found ${brew_count} formulae, ${cask_count} casks, and ${mas_count} Mac App Store apps"

        # Check App Store sign-in for mas apps
        local use_brewfile="${BREWFILE}"
        if [[ ${mas_count} -gt 0 ]]; then
            if mas account &>/dev/null; then
                print_success "App Store signed in: $(mas account)"
                echo ""
            else
                # Not signed in - last chance to sign in or skip mas apps
                echo ""
                print_warning "Not signed in to App Store"
                print_status "${mas_count} App Store apps will fail without sign-in"
                echo ""

                if confirm "Open App Store to sign in now?" "y"; then
                    print_status "Opening App Store..."
                    open -a "App Store"
                    echo ""
                    print_warning "Please sign in to App Store, then press Enter to continue"
                    read -r
                    echo ""

                    # Check if signed in now
                    if mas account &>/dev/null; then
                        print_success "App Store signed in: $(mas account)"
                    else
                        print_warning "Still not signed in - Mac App Store apps will be skipped"
                        # Create temporary Brewfile without mas entries
                        use_brewfile="${BREWFILE}.tmp"
                        grep -v "^mas " "${BREWFILE}" > "${use_brewfile}"
                        print_debug "Created temporary Brewfile without mas apps: ${use_brewfile}"
                    fi
                else
                    print_status "Skipping App Store apps"
                    # Create temporary Brewfile without mas entries
                    use_brewfile="${BREWFILE}.tmp"
                    grep -v "^mas " "${BREWFILE}" > "${use_brewfile}"
                    print_debug "Created temporary Brewfile without mas apps: ${use_brewfile}"
                fi
                echo ""
            fi
        fi

        # Export profile for Brewfile conditionals (used by Ruby in Brewfile)
        # SELECTED_PROFILE is set by install.sh (desktop/laptop)
        export DOTFILES_PROFILE="${SELECTED_PROFILE:-desktop}"
        print_status "Using profile: ${DOTFILES_PROFILE}"
        echo ""

        # Run brew bundle with proper error handling
        if brew bundle install --file="${use_brewfile}"; then
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

    # Remove temporary Brewfile if created
    if [[ -f "${BREWFILE}.tmp" ]]; then
        rm -f "${BREWFILE}.tmp"
        print_debug "Removed temporary Brewfile"
    fi

    print_success "Homebrew installation complete!"
    print_status "Homebrew prefix: $(brew --prefix)"
    print_status "Installed packages: $(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
}

# Run main function
main "$@"
