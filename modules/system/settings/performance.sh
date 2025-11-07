#!/usr/bin/env bash
# Performance Settings
# Faster animations for improved responsiveness

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring performance settings..."
fi

print_status "Configuring performance settings..."

# ===========================
# === FASTER ANIMATIONS ===
# ===========================

print_debug "Accelerating system animations..."

# Faster window resize animation
# Default: 0.2, Range: 0.001-1.0, Recommended: 0.1
defaults write NSGlobalDomain NSWindowResizeTime -float 0.1

# Faster Mission Control animation
# Default: 0.2, Range: 0.1-1.0, Recommended: 0.1
defaults write com.apple.dock expose-animation-duration -float 0.1

print_success "Animation speed optimized (window resize, Mission Control)"

print_success "Performance settings configured"
