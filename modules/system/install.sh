#!/usr/bin/env bash
# System Module - Main Installation Script
# Configures macOS system settings with profile awareness

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source library functions
# shellcheck source=../../lib/logging.sh
source "${DOTFILES_ROOT}/lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${DOTFILES_ROOT}/lib/utils.sh"

#######################################
# Main installation function
#######################################
main() {
    print_section "System Settings Configuration"

    # Check if running on macOS
    if ! is_macos; then
        print_error "This module only works on macOS"
        return 1
    fi

    # Check macOS version (minimum 12.0 Monterey)
    local macos_version
    macos_version="$(get_macos_version)"

    # Version compare returns: 0 if equal, 1 if v1 < v2, 2 if v1 > v2
    # Use '|| true' to prevent set -e from exiting on non-zero return
    version_compare "${macos_version}" "12.0" || local version_result=$?

    if [[ ${version_result:-0} -eq 1 ]]; then
        print_error "This module requires macOS 12.0 (Monterey) or later"
        print_error "Current version: ${macos_version}"
        return 1
    fi

    print_status "macOS version: ${macos_version}"

    # Parse command line arguments
    local profile="desktop"  # Default profile

    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                profile="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Usage: $0 [--profile desktop|laptop]"
                return 1
                ;;
        esac
    done

    print_status "Using profile: ${profile}"

    # Validate profile
    if [[ "${profile}" != "desktop" && "${profile}" != "laptop" ]]; then
        print_error "Invalid profile: ${profile}"
        print_error "Valid profiles: desktop, laptop"
        return 1
    fi

    # Source profile settings
    local profile_file="${DOTFILES_ROOT}/profiles/${profile}.sh"
    if [[ ! -f "${profile_file}" ]]; then
        print_error "Profile file not found: ${profile_file}"
        return 1
    fi

    print_status "Loading profile settings from: ${profile_file}"
    # shellcheck source=/dev/null
    source "${profile_file}"

    # Export variables for child scripts
    export DOTFILES_ROOT
    export PROFILE_NAME="${profile}"
    export MACOS_VERSION="${macos_version}"

    # Run all settings scripts
    print_subsection "Applying System Settings"

    local settings_dir="${SCRIPT_DIR}/settings"
    local settings_scripts=(
        "finder.sh"
        "keyboard.sh"
        "trackpad.sh"
        "security.sh"
        "performance.sh"
        "power.sh"
    )

    local failed=0
    for script in "${settings_scripts[@]}"; do
        local script_path="${settings_dir}/${script}"

        if [[ ! -f "${script_path}" ]]; then
            print_warning "Settings script not found: ${script}"
            continue
        fi

        print_status "Running ${script}..."
        if bash "${script_path}"; then
            print_success "Completed ${script}"
        else
            print_error "Failed to run ${script}"
            ((failed++))
        fi
    done

    # Restart affected applications
    print_subsection "Restarting System Components"

    # Store current terminal app to refocus later
    local current_app
    current_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "Terminal")

    print_status "Restarting Finder..."
    killall Finder 2>/dev/null || true

    print_status "Restarting SystemUIServer..."
    killall SystemUIServer 2>/dev/null || true

    # Wait for restart
    sleep 2

    # Refocus terminal
    osascript -e "tell application \"${current_app}\" to activate" 2>/dev/null || true

    # Print summary
    echo ""
    print_section "Installation Complete"

    if [[ ${failed} -eq 0 ]]; then
        print_success "All system settings applied successfully"
        print_status "Profile: ${profile}"
        print_status "macOS version: ${macos_version}"
        echo ""
        print_status "Settings applied:"
        echo "  • Finder: All bars visible, list view, current folder search"
        echo "  • Keyboard: Fast repeat, autocorrect disabled"
        echo "  • Trackpad: Tap-to-click enabled"
        echo "  • Security: Firewall enabled, profile-aware password settings"
        echo "  • Performance: Faster animations"
        echo "  • Power: Profile-aware sleep settings"
    else
        print_warning "Installation completed with ${failed} error(s)"
        print_warning "Check the log file for details: ${LOG_FILE}"
        return 1
    fi
}

# Run main function with all arguments
main "$@"
