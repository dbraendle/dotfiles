#!/usr/bin/env bash
# install.sh - Dock module installation script
# Configures macOS Dock with apps from Dockfile

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Configuration
#######################################

# Path to Dockfile in repository root
DOCK_APPS_FILE="${SCRIPT_DIR}/../../Dockfile"

#######################################
# Helper Functions
#######################################

# Check if dockutil is installed
check_dockutil() {
    if ! command_exists dockutil; then
        print_warning "dockutil is not installed"
        echo ""

        if command_exists brew; then
            print_status "dockutil can be installed via Homebrew"
            echo ""

            if confirm "Install dockutil now?" "y"; then
                print_status "Installing dockutil via Homebrew..."
                if brew install dockutil; then
                    print_success "dockutil installed successfully"
                    # Reload PATH
                    eval "$(brew shellenv)"

                    # Verify dockutil is now available
                    if ! command_exists dockutil; then
                        print_error "dockutil still not found after installation"
                        return 1
                    fi
                else
                    print_error "Failed to install dockutil"
                    return 1
                fi
            else
                print_error "Cannot proceed without dockutil"
                print_status "Install dockutil manually: brew install dockutil"
                return 1
            fi
        else
            print_error "Homebrew is not installed"
            print_status "Please install Homebrew first, then run: brew install dockutil"
            return 1
        fi
        echo ""
    fi

    print_success "dockutil is installed"
    echo ""
}

# Find application path
find_app() {
    local app_name="$1"
    local app_path=""

    # Try common locations
    if [[ -d "/Applications/${app_name}.app" ]]; then
        app_path="/Applications/${app_name}.app"
    elif [[ -d "/System/Applications/${app_name}.app" ]]; then
        app_path="/System/Applications/${app_name}.app"
    elif [[ -d "/Applications/Utilities/${app_name}.app" ]]; then
        app_path="/Applications/Utilities/${app_name}.app"
    elif [[ -d "/System/Applications/Utilities/${app_name}.app" ]]; then
        app_path="/System/Applications/Utilities/${app_name}.app"
    elif [[ -d "$HOME/Applications/${app_name}.app" ]]; then
        app_path="$HOME/Applications/${app_name}.app"
    fi

    echo "$app_path"
}

# Add item to Dock
add_to_dock() {
    local item_type="$1"
    local item_path="$2"
    local item_name="$3"

    case "$item_type" in
        "app")
            if [[ -d "$item_path" ]]; then
                if dockutil --add "$item_path" --no-restart >/dev/null 2>&1; then
                    print_success "  Added: $item_name"
                    return 0
                else
                    print_warning "  Failed to add: $item_name"
                    return 1
                fi
            else
                print_warning "  Not found: $item_name"
                return 1
            fi
            ;;
        "spacer")
            if dockutil --add '' --type small-spacer-tile --section apps --no-restart >/dev/null 2>&1; then
                print_success "  Added: small spacer"
                return 0
            else
                print_warning "  Failed to add small spacer"
                return 1
            fi
            ;;
        "folder")
            # Expand tilde in path
            local expanded_path="${item_path/#\~/$HOME}"

            if [[ -d "$expanded_path" ]]; then
                if dockutil --add "$expanded_path" --view auto --display folder --no-restart >/dev/null 2>&1; then
                    print_success "  Added folder: $expanded_path"
                    return 0
                else
                    print_warning "  Failed to add folder: $expanded_path"
                    return 1
                fi
            else
                print_warning "  Folder not found: $expanded_path"
                return 1
            fi
            ;;
    esac
}

# Clear Dock
clear_dock() {
    print_status "Clearing current Dock..."

    # Remove all apps from Dock
    if dockutil --remove all --no-restart >/dev/null 2>&1; then
        print_success "Dock cleared"
    else
        print_warning "Could not clear Dock completely (some items may be protected)"
    fi
    echo ""
}

# Configure Dock from file
configure_dock() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi

    print_status "Configuring Dock from: $config_file"
    echo ""

    local added_count=0
    local skipped_count=0
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Skip comments
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Handle spacers
        if [[ "$line" == "---" ]]; then
            if add_to_dock "spacer" "" "spacer"; then
                ((added_count++))
            else
                ((skipped_count++))
            fi
            continue
        fi

        # Handle folders
        if [[ "$line" =~ ^folder: ]]; then
            local folder_path="${line#folder:}"
            if add_to_dock "folder" "$folder_path" "$folder_path"; then
                ((added_count++))
            else
                ((skipped_count++))
            fi
            continue
        fi

        # Handle apps
        local app_path
        app_path=$(find_app "$line")

        if add_to_dock "app" "$app_path" "$line"; then
            ((added_count++))
        else
            ((skipped_count++))
        fi

    done < "$config_file"

    echo ""
    print_section "Configuration Summary"
    print_status "Added to Dock: $added_count items"
    if [[ $skipped_count -gt 0 ]]; then
        print_warning "Skipped: $skipped_count items (not found or failed)"
    fi
    echo ""

    # Restart Dock to apply changes
    print_status "Restarting Dock to apply changes..."
    killall Dock
    print_success "Dock restarted"
}

#######################################
# Main installation function
#######################################
main() {
    print_section "Installing Dock Module"

    # Ensure Homebrew is in PATH (needed after fresh homebrew installation)
    if command_exists brew; then
        eval "$(brew shellenv)"
    fi

    # Check for dockutil
    if ! check_dockutil; then
        return 1
    fi

    # Check if configuration file exists
    if [[ ! -f "$DOCK_APPS_FILE" ]]; then
        print_error "Dockfile not found at: $DOCK_APPS_FILE"
        print_status "Please create this file in the repository root"
        return 1
    fi

    print_success "Found Dockfile"
    echo ""

    # Ask for confirmation before clearing Dock
    print_warning "This will replace your current Dock configuration!"
    echo ""
    if ! confirm "Continue and configure Dock?" "y"; then
        print_status "Dock configuration cancelled"
        return 0
    fi
    echo ""

    # Clear existing Dock
    clear_dock

    # Configure Dock from file
    if configure_dock "$DOCK_APPS_FILE"; then
        echo ""
        print_success "Dock module installation completed"
        print_status "Your Dock has been configured according to Dockfile"
    else
        print_error "Dock configuration failed"
        return 1
    fi
}

# Run main function
main "$@"
