#!/usr/bin/env bash
# Trackpad Settings
# Enables tap-to-click for both Bluetooth and built-in trackpads

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring trackpad settings..."
fi

print_status "Configuring trackpad settings..."

# ===========================
# === TAP TO CLICK ===
# ===========================

print_debug "Enabling tap-to-click for all trackpads..."

# Tap to click for Bluetooth trackpad (Magic Trackpad)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Tap to click for built-in trackpad (MacBook)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Also enable in login screen
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

print_success "Tap-to-click enabled for all trackpads"

print_success "Trackpad settings configured"
