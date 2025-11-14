#!/usr/bin/env bash
# Dotfiles V2 - Manual Update Script
# Triggers on-demand updates of dotfiles, packages, and system components
#
# Usage:
#   ./update.sh                 # Interactive update (all)
#   ./update.sh all             # Update everything
#   ./update.sh brew            # Only update Homebrew
#   ./update.sh npm             # Only update npm
#   ./update.sh dotfiles        # Only update dotfiles repo
#   ./update.sh system          # Only update macOS system
#   ./update.sh --yes           # Auto-accept all prompts
#   ./update.sh --help          # Show help

set -euo pipefail

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/stow-helpers.sh"

# Configuration
readonly VERSION="2.0.0"
AUTO_YES=false
FORCE_RESTOW=false

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    cat << EOF
Dotfiles V2 - Manual Update Script

Usage:
  ./update.sh [COMPONENT] [OPTIONS]

Components:
  all          Update everything (default)
  brew         Update Homebrew packages from Brewfile
  npm          Update global npm packages
  dotfiles     Update dotfiles from GitHub
  system       Update macOS system software
  omz          Update Oh My Zsh

Options:
  --yes, -y           Auto-accept all prompts
  --force, -f         Force restow all modules
  --help, -h          Show this help message
  --version, -v       Show version

Examples:
  ./update.sh                    # Interactive update (all)
  ./update.sh all                # Update everything
  ./update.sh brew               # Only update Homebrew
  ./update.sh brew --yes         # Update Homebrew without prompts
  ./update.sh npm                # Only update npm packages

Note:
  For automatic nightly updates, use Ansible on your Homelab server.
  This script is for on-demand manual updates.

EOF
}

# ============================================================================
# Update Functions
# ============================================================================

update_dotfiles() {
    print_section "Updating Dotfiles from GitHub"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        print_warning "Not a git repository, skipping git pull"
        return 0
    fi

    local current_branch
    current_branch=$(git branch --show-current)

    print_status "Current branch: ${current_branch}"
    print_status "Pulling latest changes..."

    if git pull --rebase --autostash; then
        print_success "Dotfiles updated successfully"
    else
        print_error "Failed to pull latest changes"
        print_status "Resolve conflicts and try again"
        return 1
    fi
}

restow_modules() {
    print_section "Re-symlinking Dotfiles"

    local modules_file="${HOME}/.dotfiles-modules"

    if [[ ! -f "$modules_file" ]]; then
        print_warning "No active modules found"
        print_status "Run ./install.sh to set up modules"
        return 0
    fi

    local module_count
    module_count=$(wc -l < "$modules_file" | tr -d ' ')

    print_status "Re-symlinking $module_count active module(s)..."

    local count=0
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue
        ((count++))

        print_status "[$count/$module_count] Restowing: $module"

        if restow_package "$module"; then
            print_success "$module restowed"
        else
            print_warning "Failed to restow $module (may not have stow packages)"
        fi
    done < "$modules_file"

    print_success "Dotfiles re-symlinked"
}

update_homebrew() {
    print_section "Updating Homebrew Packages"

    if ! command_exists "brew"; then
        print_warning "Homebrew not installed, skipping"
        return 0
    fi

    # Auto-detect profile for Brewfile
    if is_laptop; then
        export DOTFILES_PROFILE="laptop"
        print_status "Profile: laptop"
    else
        export DOTFILES_PROFILE="desktop"
        print_status "Profile: desktop"
    fi

    print_status "Updating Homebrew..."
    if brew update; then
        print_success "Homebrew updated"
    else
        print_error "Failed to update Homebrew"
        return 1
    fi

    # Install/update packages from Brewfile
    if [[ -f "${SCRIPT_DIR}/Brewfile" ]]; then
        print_status "Installing/updating packages from Brewfile..."
        cd "${SCRIPT_DIR}"
        if brew bundle install; then
            print_success "Brewfile packages updated"
        else
            print_warning "Some Brewfile packages failed to install"
        fi
    else
        print_warning "Brewfile not found, skipping brew bundle"
    fi

    print_status "Upgrading all outdated packages..."
    if brew upgrade; then
        print_success "Packages upgraded"
    else
        print_warning "Some packages failed to upgrade"
    fi

    print_status "Cleaning up..."
    brew cleanup || true
    brew autoremove || true

    print_success "Homebrew update complete"
}

update_npm() {
    print_section "Updating NPM Global Packages"

    if ! command_exists "npm"; then
        print_warning "npm not installed, skipping"
        return 0
    fi

    print_status "Updating global packages..."

    if npm update -g; then
        print_success "npm packages updated"
    else
        print_warning "Some npm packages failed to update"
    fi
}

update_oh_my_zsh() {
    print_section "Updating Oh My Zsh"

    local omz_dir="${HOME}/.oh-my-zsh"

    if [[ ! -d "$omz_dir" ]]; then
        print_warning "Oh My Zsh not installed, skipping"
        return 0
    fi

    print_status "Updating Oh My Zsh..."

    if (cd "$omz_dir" && git pull --rebase --autostash); then
        print_success "Oh My Zsh updated"
    else
        print_warning "Failed to update Oh My Zsh"
    fi
}

reapply_system_settings() {
    print_section "Re-applying System Settings"

    local profile_file="${HOME}/.dotfiles-profile"

    if [[ ! -f "$profile_file" ]]; then
        print_warning "No profile set, skipping system settings"
        return 0
    fi

    local profile
    profile=$(cat "$profile_file")

    if [[ "$AUTO_YES" == true ]] || confirm "Re-apply system settings for $profile profile?"; then
        local system_script="${SCRIPT_DIR}/modules/system/install.sh"

        if [[ -f "$system_script" ]]; then
            print_status "Running system module..."
            if "$system_script" --profile "$profile"; then
                print_success "System settings re-applied"
            else
                print_warning "Failed to re-apply system settings"
            fi
        else
            print_warning "System module not found, skipping"
        fi
    else
        print_status "Skipping system settings"
    fi
}

update_modules() {
    print_section "Updating Active Modules"

    local modules_file="${HOME}/.dotfiles-modules"

    if [[ ! -f "$modules_file" ]]; then
        print_warning "No active modules found"
        return 0
    fi

    local module_count
    module_count=$(wc -l < "$modules_file" | tr -d ' ')

    print_status "Checking $module_count module(s) for updates..."

    local count=0
    while IFS= read -r module; do
        [[ -z "$module" ]] && continue
        ((count++))

        local update_script="${SCRIPT_DIR}/modules/${module}/update.sh"

        if [[ -f "$update_script" ]]; then
            print_status "[$count/$module_count] Updating: $module"

            if "$update_script"; then
                print_success "$module updated"
            else
                print_warning "Failed to update $module"
            fi
        fi
    done < "$modules_file"

    print_success "Module updates complete"
}

update_system() {
    print_section "Updating macOS System"

    if ! is_macos; then
        print_warning "Not on macOS, skipping"
        return 0
    fi

    print_status "Checking for macOS updates..."
    softwareupdate --list 2>/dev/null || true

    echo ""
    if [[ "$AUTO_YES" == true ]] || confirm "Install available macOS updates?" "n"; then
        print_status "Installing macOS updates (requires sudo)..."
        if sudo softwareupdate --install --all; then
            print_success "macOS updates installed"
        else
            print_warning "Some updates failed to install"
        fi
    else
        print_status "Skipped macOS update"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    local component="all"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            brew|npm|dotfiles|system|omz|all)
                component="$1"
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --force|-f)
                FORCE_RESTOW=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "Dotfiles V2 Update Script v${VERSION}"
                exit 0
                ;;
            *)
                print_error "Unknown component or option: $1"
                echo "Run './update.sh --help' for usage"
                exit 1
                ;;
        esac
    done

    # Create log file
    local log_dir="${SCRIPT_DIR}/logs"
    mkdir -p "$log_dir"
    export LOG_FILE="${log_dir}/update-$(date +%Y-%m-%d-%H%M%S).log"

    # Run updates based on component
    local start_time
    start_time=$(date +%s)

    case "$component" in
        brew)
            update_homebrew || true
            ;;
        npm)
            update_npm || true
            ;;
        dotfiles)
            update_dotfiles || true
            echo ""
            restow_modules || true
            ;;
        system)
            update_system || true
            ;;
        omz)
            update_oh_my_zsh || true
            ;;
        all)
            # Header
            print_section "Dotfiles V2 - Complete Update"
            echo ""

            # Confirm
            if [[ "$AUTO_YES" == false ]]; then
                echo "This will update:"
                echo "  • Dotfiles (git pull)"
                echo "  • Stow packages (restow)"
                echo "  • Homebrew packages (from Brewfile)"
                echo "  • NPM global packages"
                echo "  • Oh My Zsh"
                echo "  • Active modules"
                echo "  • System settings (optional)"
                echo ""

                if ! confirm "Proceed with update?"; then
                    print_status "Update cancelled"
                    exit 0
                fi

                echo ""
            fi

            print_status "Logging to: $LOG_FILE"
            echo ""

            update_dotfiles || true
            echo ""

            restow_modules || true
            echo ""

            update_homebrew || true
            echo ""

            update_npm || true
            echo ""

            update_oh_my_zsh || true
            echo ""

            update_modules || true
            echo ""

            reapply_system_settings || true
            echo ""
            ;;
    esac

    # Summary
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    print_success "Update Complete!"

    if [[ "$component" == "all" ]]; then
        echo ""
        echo "✓ Dotfiles updated and re-symlinked"
        echo "✓ Packages updated (Homebrew, npm)"
        echo "✓ Oh My Zsh updated"
        echo "✓ Active modules updated"
        echo ""
        echo "Duration: ${duration}s"
        echo "Log: $LOG_FILE"
        echo ""
        print_status "Next Steps:"
        echo "  1. Restart Terminal: source ~/.zshrc"
        echo "  2. Verify: ./manage.sh modules status"
    else
        echo "Component '${component}' updated successfully (${duration}s)"
        if [[ "$component" == "brew" ]] || [[ "$component" == "dotfiles" ]]; then
            echo ""
            print_status "You may need to restart your terminal: source ~/.zshrc"
        fi
    fi
    echo ""
}

# Run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
