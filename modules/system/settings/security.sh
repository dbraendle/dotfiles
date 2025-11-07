#!/usr/bin/env bash
# Security Settings
# Profile-aware security configuration (desktop vs laptop)

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
    # shellcheck source=../../../lib/utils.sh
    source "${DOTFILES_ROOT}/lib/utils.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring security settings..."
fi

print_status "Configuring security settings..."

# ===========================
# === FIREWALL ===
# ===========================

print_debug "Enabling macOS firewall..."

# Enable firewall
# 0 = off, 1 = on for specific services, 2 = on for essential services
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

print_success "Firewall enabled"

# ===================================
# === PASSWORD AFTER SLEEP ===
# ===================================

print_debug "Configuring password after sleep/screensaver..."

# Check if we're running on a laptop
is_laptop_device=false
if is_laptop; then
    is_laptop_device=true
fi

# Determine password requirement based on profile and device type
require_password=false

if [[ "${is_laptop_device}" == "true" ]]; then
    # Laptops ALWAYS require password after sleep (security critical for portable devices)
    require_password=true
    print_debug "Device is a laptop - password will be required after sleep"
elif [[ -n "${ENABLE_PASSWORD_AFTER_SLEEP:-}" ]]; then
    # Desktop: use profile setting
    if [[ "${ENABLE_PASSWORD_AFTER_SLEEP}" == "true" ]]; then
        require_password=true
        print_debug "Desktop profile: password required after sleep"
    else
        require_password=false
        print_debug "Desktop profile: password NOT required after sleep"
    fi
else
    # Default: require password (security-first approach)
    require_password=true
    print_warning "ENABLE_PASSWORD_AFTER_SLEEP not set, defaulting to requiring password"
fi

# Apply password settings
if [[ "${require_password}" == "true" ]]; then
    # Require password immediately after sleep/screensaver
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    print_success "Password required immediately after sleep/screensaver"
else
    # Disable password requirement after sleep/screensaver (desktop convenience)
    defaults write com.apple.screensaver askForPassword -int 0
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    print_success "Password NOT required after sleep/screensaver (desktop mode)"
fi

# ===================================
# === CUPS WEB INTERFACE ===
# ===================================

print_debug "Enabling CUPS web interface for printer management..."

# Enable CUPS Web Interface for advanced printer management
# Access via: http://localhost:631
if command -v cupsctl >/dev/null 2>&1; then
    cupsctl WebInterface=yes 2>/dev/null || true
    print_success "CUPS web interface enabled (http://localhost:631)"
else
    print_debug "cupsctl not found, skipping CUPS configuration"
fi

print_success "Security settings configured"
