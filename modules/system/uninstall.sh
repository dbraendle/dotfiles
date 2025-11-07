#!/usr/bin/env bash
# System Module - Uninstallation Script
# Restores macOS default system settings

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source library functions
# shellcheck source=../../lib/logging.sh
source "${DOTFILES_ROOT}/lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${DOTFILES_ROOT}/lib/utils.sh"

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "System Settings Uninstallation"

    # Check if running on macOS
    if ! is_macos; then
        print_error "This module only works on macOS"
        exit 1
    fi

    print_warning "This will restore macOS default system settings"
    print_warning "Some settings may require manual restoration"
    echo ""

    if ! confirm "Do you want to continue?" "n"; then
        print_status "Uninstallation cancelled"
        exit 0
    fi

    print_subsection "Restoring Default Settings"

    # =====================
    # === FINDER ===
    # =====================

    print_status "Restoring Finder defaults..."

    # Bars (restore to macOS defaults - typically visible)
    defaults write com.apple.finder ShowPathbar -bool false
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowToolbar -bool true
    defaults write com.apple.finder ShowSidebar -bool true

    # View settings
    defaults delete com.apple.finder _FXSortFoldersFirst 2>/dev/null || true
    defaults delete com.apple.finder FXArrangeGroupViewBy 2>/dev/null || true
    defaults delete com.apple.finder _FXShowPosixPathInTitle 2>/dev/null || true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCev"  # Search This Mac
    defaults write com.apple.finder NewWindowTarget -string "PfDe"  # Desktop
    defaults delete com.apple.finder FXPreferredViewStyle 2>/dev/null || true  # Icon view

    # Desktop items (restore to showing)
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Tags
    defaults write com.apple.finder ShowRecentTags -bool true
    defaults write com.apple.finder SidebarTagsSctionDisclosedState -bool true

    # Advanced
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
    defaults write com.apple.finder QLEnableTextSelection -bool true

    print_success "Finder defaults restored"

    # =====================
    # === KEYBOARD ===
    # =====================

    print_status "Restoring keyboard defaults..."

    # Key repeat (restore to macOS defaults)
    defaults write NSGlobalDomain KeyRepeat -int 6
    defaults write NSGlobalDomain InitialKeyRepeat -int 25

    # Autocorrect (restore to enabled)
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticSuggestedRepliesEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true

    # Tahoe-specific settings
    defaults delete NSGlobalDomain KB_SpellingLanguage 2>/dev/null || true
    defaults delete NSGlobalDomain WebAutomaticSpellingCorrectionEnabled 2>/dev/null || true
    defaults delete com.apple.Safari WebAutomaticSpellingCorrectionEnabled 2>/dev/null || true
    defaults delete com.apple.Safari WebContinuousSpellCheckingEnabled 2>/dev/null || true

    print_success "Keyboard defaults restored"

    # =====================
    # === TRACKPAD ===
    # =====================

    print_status "Restoring trackpad defaults..."

    # Tap to click (default: disabled)
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
    defaults -currentHost delete NSGlobalDomain com.apple.mouse.tapBehavior 2>/dev/null || true
    defaults delete NSGlobalDomain com.apple.mouse.tapBehavior 2>/dev/null || true

    print_success "Trackpad defaults restored"

    # =====================
    # === SECURITY ===
    # =====================

    print_status "Restoring security defaults..."

    # Firewall (default: off, but we recommend leaving it on)
    print_warning "Firewall will be left enabled (recommended for security)"
    # sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 0

    # Password after sleep (default: enabled with 5-second delay)
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 5

    # CUPS (default: disabled)
    if command -v cupsctl >/dev/null 2>&1; then
        cupsctl WebInterface=no 2>/dev/null || true
    fi

    print_success "Security defaults restored"

    # =====================
    # === PERFORMANCE ===
    # =====================

    print_status "Restoring performance defaults..."

    # Animation speeds (restore to macOS defaults)
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.2
    defaults write com.apple.dock expose-animation-duration -float 0.2

    print_success "Performance defaults restored"

    # =====================
    # === POWER ===
    # =====================

    print_status "Restoring power management defaults..."

    # Display sleep (default: 10 minutes for battery, 10 for AC)
    sudo pmset -a displaysleep 10

    # System sleep (default: 10 minutes for battery, 0 for AC on desktops)
    local is_laptop_device=false
    if is_laptop; then
        is_laptop_device=true
    fi

    if [[ "${is_laptop_device}" == "true" ]]; then
        sudo pmset -a sleep 10
        print_success "System sleep set to 10 minutes (laptop default)"
    else
        sudo pmset -a sleep 0
        print_success "System sleep disabled (desktop default)"
    fi

    # Disk sleep (default: 10 minutes)
    sudo pmset -a disksleep 10

    print_success "Power management defaults restored"

    # =====================
    # === RESTART APPS ===
    # =====================

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

    # =====================
    # === SUMMARY ===
    # =====================

    echo ""
    print_section "Uninstallation Complete"

    print_success "System settings restored to macOS defaults"
    echo ""
    print_status "Restored settings:"
    echo "  • Finder: Default view settings and behavior"
    echo "  • Keyboard: Standard key repeat, autocorrect enabled"
    echo "  • Trackpad: Tap-to-click disabled"
    echo "  • Security: Password after sleep enabled (firewall kept on)"
    echo "  • Performance: Standard animation speeds"
    echo "  • Power: Default sleep settings"
    echo ""
    print_warning "Some settings may require logging out and back in to take full effect"
}

# Run main function
main "$@"
