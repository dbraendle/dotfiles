#!/usr/bin/env bash
#######################################
# Dotfiles V2 - Main Installation Script
#
# A professional, modular dotfiles installation system for macOS
#
# Features:
#   - Automatic profile detection (laptop vs desktop)
#   - Modular architecture with dependency resolution
#   - Interactive menu-driven installation
#   - Command-line argument support
#   - Comprehensive error handling and logging
#   - GNU Stow integration for dotfile management
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --profile desktop|laptop    Force specific profile
#   --modules core,dock,...     Install specific modules
#   --yes                       Auto-accept all prompts
#   --help                      Show this help message
#
# Examples:
#   ./install.sh                           # Interactive installation
#   ./install.sh --profile laptop --yes    # Non-interactive laptop setup
#   ./install.sh --modules core,terminal   # Install specific modules
#
# Author: Dennis Brändle <me@dbraendle.com>
# GitHub: github.com/dbraendle/dotfiles
# Version: 2.0.0
# License: MIT
#######################################

set -euo pipefail

#######################################
# Source library files
#######################################

# Get the absolute path to the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# Source required libraries
# shellcheck source=lib/logging.sh
source "${DOTFILES_DIR}/lib/logging.sh"
# shellcheck source=lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"
# shellcheck source=lib/module-validator.sh
source "${DOTFILES_DIR}/lib/module-validator.sh"
# shellcheck source=lib/stow-helpers.sh
source "${DOTFILES_DIR}/lib/stow-helpers.sh"

#######################################
# Global Variables
#######################################

# Profile configuration
DETECTED_PROFILE=""
SELECTED_PROFILE=""
PROFILE_FILE="${HOME}/.dotfiles-profile"

# Module configuration
SELECTED_MODULES=()
MODULES_FILE="${HOME}/.dotfiles-modules"
CORE_MODULES=("system" "homebrew" "npm" "terminal" "git")

# Installation options
AUTO_YES=false
INTERACTIVE=true

# Temporary storage for user input
GIT_USER_NAME=""
GIT_USER_EMAIL=""
SCANNER_HOSTNAME=""

# Create log file with timestamp
LOG_DIR="${DOTFILES_DIR}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/install-$(date +%Y-%m-%d-%H%M%S).log"
export LOG_FILE

#######################################
# Helper Functions
#######################################

#######################################
# Display usage information
# Outputs:
#   Help text to stdout
#######################################
show_help() {
    cat << EOF
Dotfiles V2 - Main Installation Script

Usage:
  ./install.sh [OPTIONS]

Options:
  --profile PROFILE       Force specific profile (desktop|laptop)
  --modules MODULES       Comma-separated list of modules to install
  --yes                   Auto-accept all prompts (non-interactive mode)
  --help                  Show this help message

Examples:
  ./install.sh                              Interactive installation
  ./install.sh --profile laptop --yes       Non-interactive laptop setup
  ./install.sh --modules system,terminal    Install specific modules only

Core Modules (always available):
  system      - macOS system settings and preferences
  homebrew    - Homebrew package manager and packages
  terminal    - Zsh, Oh My Zsh, and terminal configuration
  git         - Git configuration and aliases

For more information, see: ${DOTFILES_DIR}/README.md
EOF
}

#######################################
# Parse command-line arguments
# Arguments:
#   $@ - All command-line arguments
#######################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                if [[ -z "${2:-}" ]] || [[ "$2" =~ ^-- ]]; then
                    print_error "Missing value for --profile"
                    exit 1
                fi
                SELECTED_PROFILE="$2"
                if [[ ! "$SELECTED_PROFILE" =~ ^(desktop|laptop)$ ]]; then
                    print_error "Invalid profile: $SELECTED_PROFILE (must be: desktop, laptop)"
                    exit 1
                fi
                shift 2
                ;;
            --profile=*)
                SELECTED_PROFILE="${1#*=}"
                if [[ ! "$SELECTED_PROFILE" =~ ^(desktop|laptop)$ ]]; then
                    print_error "Invalid profile: $SELECTED_PROFILE (must be: desktop, laptop)"
                    exit 1
                fi
                shift
                ;;
            --modules)
                if [[ -z "${2:-}" ]] || [[ "$2" =~ ^-- ]]; then
                    print_error "Missing value for --modules"
                    exit 1
                fi
                IFS=',' read -ra SELECTED_MODULES <<< "$2"
                INTERACTIVE=false
                shift 2
                ;;
            --modules=*)
                IFS=',' read -ra SELECTED_MODULES <<< "${1#*=}"
                INTERACTIVE=false
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

#######################################
# Detect hardware profile
# Sets DETECTED_PROFILE to "laptop" or "desktop"
#######################################
detect_profile() {
    print_status "Detecting hardware profile..."

    if is_laptop; then
        DETECTED_PROFILE="laptop"
        print_success "Detected: MacBook (Laptop)"
    else
        DETECTED_PROFILE="desktop"
        print_success "Detected: Desktop Mac (Mac mini/iMac/Mac Studio/Mac Pro)"
    fi

    # Use detected profile if not overridden
    if [[ -z "$SELECTED_PROFILE" ]]; then
        SELECTED_PROFILE="$DETECTED_PROFILE"
    fi

    # Save profile for future use
    echo "$SELECTED_PROFILE" > "$PROFILE_FILE"
    print_debug "Profile saved to: $PROFILE_FILE"
}

#######################################
# Check for required prerequisites
# Returns:
#   0 if all prerequisites met, 1 otherwise
#######################################
check_prerequisites() {
    print_section "Checking Prerequisites"

    local missing_prereqs=0

    # Check if running on macOS
    if ! is_macos; then
        print_error "This script is designed for macOS only"
        print_error "Detected OS: $(uname -s)"
        return 1
    fi
    print_success "Running on macOS $(get_macos_version)"

    # Check for Xcode Command Line Tools
    print_status "Checking for Xcode Command Line Tools..."
    if ! xcode-select -p &>/dev/null; then
        print_warning "Xcode Command Line Tools not installed"

        if [[ "$AUTO_YES" == "false" ]]; then
            if confirm "Install Xcode Command Line Tools now?" "y"; then
                print_status "Installing Xcode Command Line Tools..."
                xcode-select --install

                print_status "Waiting for installation to complete..."
                print_status "Please click 'Install' in the popup window"

                # Wait for installation with timeout
                local timeout=0
                local max_timeout=1800  # 30 minutes

                while ! xcode-select -p &>/dev/null; do
                    sleep 10
                    timeout=$((timeout + 10))

                    if [[ $timeout -ge $max_timeout ]]; then
                        print_error "Installation timeout after 30 minutes"
                        print_error "Please install manually: xcode-select --install"
                        return 1
                    fi

                    if [[ $((timeout % 60)) -eq 0 ]]; then
                        print_status "Waiting... (${timeout}s elapsed)"
                    fi
                done

                print_success "Xcode Command Line Tools installed"
            else
                print_error "Xcode Command Line Tools are required"
                return 1
            fi
        else
            print_error "Xcode Command Line Tools required for installation"
            print_error "Install with: xcode-select --install"
            return 1
        fi
    else
        print_success "Xcode Command Line Tools installed"
    fi

    # Check for jq (needed for module validation)
    if ! command_exists jq; then
        print_warning "jq is not installed (needed for module management)"
        print_status "jq will be installed with Homebrew"
    fi

    return 0
}

#######################################
# Get list of all available modules
# Outputs:
#   List of module names, one per line
#######################################
get_available_modules() {
    local modules_dir="${DOTFILES_DIR}/modules"

    if [[ ! -d "$modules_dir" ]]; then
        return 0
    fi

    find "$modules_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

#######################################
# Display interactive menu
# Sets SELECTED_MODULES array based on user selection
#######################################
show_interactive_menu() {
    clear

    cat << 'EOF'
╔════════════════════════════════════════════╗
║      Dotfiles V2 Installation             ║
╚════════════════════════════════════════════╝
EOF

    echo ""
    if [[ "$DETECTED_PROFILE" == "$SELECTED_PROFILE" ]]; then
        echo "Detected: $(echo "$DETECTED_PROFILE" | sed 's/./\U&/') Profile"
    else
        echo "Profile: $(echo "$SELECTED_PROFILE" | sed 's/./\U&/') (Override)"
    fi
    echo ""

    cat << EOF
Installation Options:
  [1] Full Installation (Recommended)
      ✓ System Settings (${SELECTED_PROFILE} Profile)
      ✓ Homebrew + All Packages
      ✓ Terminal (Zsh + Oh My Zsh)
      ✓ Git Configuration
      ✓ All Optional Modules

  [2] Minimal Installation (Core Only)
      ✓ System Settings
      ✓ Homebrew + Essential Packages
      ✓ Terminal
      ✓ Git Configuration

  [3] Custom - Select Modules Interactively

  [4] Change Profile (Switch to $(if [[ "$SELECTED_PROFILE" == "laptop" ]]; then echo "Desktop"; else echo "Laptop"; fi))

  [Q] Quit

EOF

    read -rp "Select option [1-4, Q]: " choice

    case "$choice" in
        1)
            # Full installation - all modules
            print_status "Full installation selected"
            SELECTED_MODULES=()
            while IFS= read -r module; do
                SELECTED_MODULES+=("$module")
            done < <(get_available_modules)
            ;;
        2)
            # Minimal installation - core modules only
            print_status "Minimal installation selected"
            SELECTED_MODULES=("${CORE_MODULES[@]}")
            ;;
        3)
            # Custom module selection
            select_modules_interactively
            ;;
        4)
            # Toggle profile
            if [[ "$SELECTED_PROFILE" == "laptop" ]]; then
                SELECTED_PROFILE="desktop"
            else
                SELECTED_PROFILE="laptop"
            fi
            echo "$SELECTED_PROFILE" > "$PROFILE_FILE"
            print_success "Profile changed to: $SELECTED_PROFILE"
            sleep 1
            show_interactive_menu  # Show menu again
            return
            ;;
        [Qq])
            print_status "Installation cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid option: $choice"
            sleep 2
            show_interactive_menu  # Show menu again
            return
            ;;
    esac
}

#######################################
# Interactive module selection
# Sets SELECTED_MODULES array based on user choices
#######################################
select_modules_interactively() {
    clear
    print_section "Custom Module Selection"

    echo "Core modules (always installed):"
    for module in "${CORE_MODULES[@]}"; do
        echo "  ✓ $module"
    done
    echo ""

    # Start with core modules
    SELECTED_MODULES=("${CORE_MODULES[@]}")

    # Get optional modules
    local optional_modules=()
    local all_modules=()
    while IFS= read -r module; do
        all_modules+=("$module")
    done < <(get_available_modules)

    for module in "${all_modules[@]}"; do
        # Skip core modules
        if [[ " ${CORE_MODULES[*]} " =~ " ${module} " ]]; then
            continue
        fi
        optional_modules+=("$module")
    done

    if [[ ${#optional_modules[@]} -eq 0 ]]; then
        print_warning "No optional modules available"
        return
    fi

    echo "Optional modules (select which to install):"
    echo ""

    for module in "${optional_modules[@]}"; do
        local description=""
        local module_file="${DOTFILES_DIR}/modules/${module}/module.json"

        if [[ -f "$module_file" ]] && command_exists jq; then
            description=$(jq -r '.description // "No description"' "$module_file" 2>/dev/null || echo "")
        fi

        if [[ -z "$description" ]]; then
            description="No description available"
        fi

        echo -ne "  Install ${BOLD}${module}${NC}? ($description) "
        if [[ "$AUTO_YES" == "true" ]] || confirm "" "n"; then
            SELECTED_MODULES+=("$module")
            print_success "  → $module will be installed"
        else
            print_status "  → $module skipped"
        fi
        echo ""
    done
}

#######################################
# Gather user input for configuration
#######################################
gather_user_input() {
    if [[ "$AUTO_YES" == "true" ]]; then
        return 0
    fi

    print_section "Configuration"

    # Git configuration
    if [[ " ${SELECTED_MODULES[*]} " =~ " git " ]]; then
        echo ""
        print_status "Git Configuration"

        # Get current git config if exists
        local current_name
        local current_email
        current_name=$(git config --global user.name 2>/dev/null || echo "")
        current_email=$(git config --global user.email 2>/dev/null || echo "")

        if [[ -n "$current_name" ]]; then
            read -rp "Git username [$current_name]: " GIT_USER_NAME
            GIT_USER_NAME="${GIT_USER_NAME:-$current_name}"
        else
            read -rp "Git username: " GIT_USER_NAME
        fi

        if [[ -n "$current_email" ]]; then
            read -rp "Git email [$current_email]: " GIT_USER_EMAIL
            GIT_USER_EMAIL="${GIT_USER_EMAIL:-$current_email}"
        else
            read -rp "Git email: " GIT_USER_EMAIL
        fi
    fi

    # Scanner hostname (if scanner module is selected)
    if [[ " ${SELECTED_MODULES[*]} " =~ " scanner " ]]; then
        echo ""
        print_status "Scanner Configuration"
        read -rp "Scanner server hostname (optional, press Enter to skip): " SCANNER_HOSTNAME
    fi

    echo ""
}

#######################################
# Validate module dependencies
# Arguments:
#   $1 - Module name
# Returns:
#   0 if dependencies satisfied, 1 otherwise
#######################################
validate_dependencies() {
    local module="$1"
    local module_file="${DOTFILES_DIR}/modules/${module}/module.json"

    if [[ ! -f "$module_file" ]]; then
        print_warning "Module file not found: $module_file"
        return 0  # Skip validation if module.json doesn't exist
    fi

    # Check if jq is available
    if ! command_exists jq; then
        print_debug "jq not available, skipping dependency validation for $module"
        return 0
    fi

    # Get dependencies
    local dependencies
    dependencies=$(jq -r '.dependencies[]? // empty' "$module_file" 2>/dev/null || echo "")

    if [[ -z "$dependencies" ]]; then
        return 0  # No dependencies
    fi

    # Check each dependency
    local missing_deps=()
    while IFS= read -r dep; do
        if [[ ! " ${SELECTED_MODULES[*]} " =~ " ${dep} " ]]; then
            missing_deps+=("$dep")
        fi
    done <<< "$dependencies"

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Module '$module' requires: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

#######################################
# Check if module supports current profile
# Arguments:
#   $1 - Module name
# Returns:
#   0 if supported, 1 otherwise
#######################################
check_profile_support() {
    local module="$1"
    local module_file="${DOTFILES_DIR}/modules/${module}/module.json"

    if [[ ! -f "$module_file" ]]; then
        return 0  # Assume supported if no module.json
    fi

    if ! command_exists jq; then
        return 0  # Assume supported if jq not available
    fi

    # Get supported profiles
    local profiles
    profiles=$(jq -r '.profiles[]? // empty' "$module_file" 2>/dev/null || echo "")

    # If no profiles specified, assume both are supported
    if [[ -z "$profiles" ]]; then
        return 0
    fi

    # Check if current profile is supported
    if echo "$profiles" | grep -q "^${SELECTED_PROFILE}$"; then
        return 0
    else
        print_warning "Module '$module' does not support profile: $SELECTED_PROFILE"
        return 1
    fi
}

#######################################
# Install a single module
# Arguments:
#   $1 - Module name
# Returns:
#   0 if successful, 1 otherwise
#######################################
install_module() {
    local module="$1"
    local module_dir="${DOTFILES_DIR}/modules/${module}"
    local install_script="${module_dir}/install.sh"

    print_subsection "Installing Module: $module"

    # Check if module exists
    if [[ ! -d "$module_dir" ]]; then
        print_error "Module directory not found: $module_dir"
        return 1
    fi

    # Validate dependencies
    if ! validate_dependencies "$module"; then
        print_error "Dependency check failed for: $module"
        return 1
    fi

    # Check profile support
    if ! check_profile_support "$module"; then
        print_warning "Skipping $module (not supported on $SELECTED_PROFILE)"
        return 0
    fi

    # Check if install script exists
    if [[ ! -f "$install_script" ]]; then
        print_warning "Install script not found: $install_script"
        print_warning "Skipping module: $module"
        return 0
    fi

    # Make install script executable
    chmod +x "$install_script"

    # Export configuration variables for module scripts
    export DOTFILES_DIR
    export SELECTED_PROFILE
    export GIT_USER_NAME
    export GIT_USER_EMAIL
    export SCANNER_HOSTNAME

    # Run install script
    print_status "Running: $install_script"

    if "$install_script"; then
        print_success "Module '$module' installed successfully"

        # Add to modules file
        if [[ -f "$MODULES_FILE" ]]; then
            if ! grep -q "^${module}$" "$MODULES_FILE" 2>/dev/null; then
                echo "$module" >> "$MODULES_FILE"
            fi
        else
            echo "$module" > "$MODULES_FILE"
        fi

        return 0
    else
        print_error "Module '$module' installation failed"
        return 1
    fi
}

#######################################
# Install all selected modules
# Returns:
#   0 if all successful, 1 if any failed
#######################################
install_modules() {
    print_section "Installing Modules"

    local total=${#SELECTED_MODULES[@]}
    local current=0
    local failed=0
    local succeeded=0
    local skipped=0

    print_status "Modules to install: ${SELECTED_MODULES[*]}"
    print_status "Profile: $SELECTED_PROFILE"
    echo ""

    for module in "${SELECTED_MODULES[@]}"; do
        current=$((current + 1))
        print_status "[$current/$total] Processing: $module"

        if install_module "$module"; then
            succeeded=$((succeeded + 1))
        else
            failed=$((failed + 1))

            # Ask user if they want to continue
            if [[ "$AUTO_YES" == "false" ]] && [[ " ${CORE_MODULES[*]} " =~ " ${module} " ]]; then
                print_error "Core module '$module' failed to install"
                if ! confirm "Continue with remaining modules?" "n"; then
                    print_error "Installation aborted"
                    return 1
                fi
            fi
        fi
        echo ""
    done

    # Summary
    print_section "Installation Summary"
    echo "Total modules:      $total"
    echo "Succeeded:          $succeeded"
    echo "Failed:             $failed"
    echo ""

    if [[ $failed -gt 0 ]]; then
        print_warning "Some modules failed to install"
        print_status "Check log file for details: $LOG_FILE"
        return 1
    else
        print_success "All modules installed successfully"
        return 0
    fi
}

#######################################
# Display final summary
#######################################
show_summary() {
    clear

    cat << 'EOF'
╔════════════════════════════════════════════╗
║      Installation Complete!                ║
╚════════════════════════════════════════════╝
EOF

    echo ""
    print_success "Dotfiles V2 installation completed successfully!"
    echo ""

    # Show active profile
    echo "Active Profile:"
    echo "  • $SELECTED_PROFILE"
    echo ""

    # Show installed modules
    echo "Installed Modules:"
    if [[ -f "$MODULES_FILE" ]]; then
        while IFS= read -r module; do
            [[ -z "$module" ]] && continue
            echo "  • $module"
        done < "$MODULES_FILE"
    else
        echo "  (none recorded)"
    fi
    echo ""

    # Next steps
    print_section "Next Steps"
    cat << EOF
  1. Restart Terminal or run: source ~/.zshrc
  2. Review module status: ./manage.sh modules status
  3. Customize settings in: $DOTFILES_DIR/config/
  4. Check logs for details: $LOG_FILE

EOF

    # Module-specific next steps
    if [[ " ${SELECTED_MODULES[*]} " =~ " terminal " ]]; then
        echo "  Terminal Configuration:"
        echo "    - Oh My Zsh installed at: ~/.oh-my-zsh"
        echo "    - Configuration file: ~/.zshrc"
        echo ""
    fi

    if [[ " ${SELECTED_MODULES[*]} " =~ " git " ]]; then
        echo "  Git Configuration:"
        echo "    - User: $GIT_USER_NAME <$GIT_USER_EMAIL>"
        echo "    - Config file: ~/.gitconfig"
        echo ""
    fi

    print_success "Installation log saved to: $LOG_FILE"
    echo ""
}

#######################################
# Confirm installation
# Returns:
#   0 if user confirms, 1 otherwise
#######################################
confirm_installation() {
    if [[ "$AUTO_YES" == "true" ]]; then
        return 0
    fi

    echo ""
    print_section "Installation Confirmation"

    echo "Profile:  $SELECTED_PROFILE"
    echo "Modules:  ${SELECTED_MODULES[*]}"
    echo "Log file: $LOG_FILE"
    echo ""

    if confirm "Proceed with installation?" "y"; then
        return 0
    else
        print_status "Installation cancelled by user"
        return 1
    fi
}

#######################################
# Main installation flow
#######################################
main() {
    # Parse command-line arguments first (handles --help before any output)
    parse_arguments "$@"

    # Print header
    clear
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║                         Dennis'                               ║
║                        Dotfiles                               ║
║                                                               ║
║             Professional macOS Setup & Configuration          ║
║                                                               ║
║   Version: 2.0.0                                              ║
║   Author:  Dennis Brändle                                     ║
║   GitHub:  github.com/dbraendle/dotfiles                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

    print_status "Starting Dotfiles V2 installation..."
    print_status "Log file: $LOG_FILE"
    echo ""

    # Check prerequisites
    if ! check_prerequisites; then
        print_error "Prerequisites check failed"
        print_error "Please resolve issues and try again"
        exit 1
    fi

    # Detect hardware profile
    detect_profile

    # Interactive menu or use provided modules
    if [[ "$INTERACTIVE" == "true" ]] && [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        show_interactive_menu
    fi

    # Validate that we have modules to install
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        print_error "No modules selected for installation"
        print_status "Use --modules option or run interactively"
        exit 1
    fi

    # Gather user input
    gather_user_input

    # Confirm installation
    if ! confirm_installation; then
        exit 0
    fi

    echo ""
    print_status "Starting installation process..."
    echo ""

    # Install modules
    if install_modules; then
        # Save profile
        echo "$SELECTED_PROFILE" > "$PROFILE_FILE"
        print_debug "Profile saved to: $PROFILE_FILE"

        # Show summary
        show_summary
        exit 0
    else
        print_error "Installation completed with errors"
        print_status "Check log file: $LOG_FILE"
        exit 1
    fi
}

#######################################
# Entry Point
#######################################

# Run main function with all arguments
main "$@"
