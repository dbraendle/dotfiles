#!/usr/bin/env bash
# Keyboard Settings
# Optimized for developers with fast key repeat and disabled autocorrect

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
    # shellcheck source=../../../lib/utils.sh
    source "${DOTFILES_ROOT}/lib/utils.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring keyboard settings..."
fi

print_status "Configuring keyboard settings..."

# =====================
# === KEY REPEAT ===
# =====================

print_debug "Configuring key repeat rates..."

# Faster key repeat when holding (lower = faster)
# Default: 6, Range: 1-120, Recommended for devs: 2
defaults write NSGlobalDomain KeyRepeat -int 2

# Shorter delay before repeat starts (lower = faster)
# Default: 25, Range: 15-120, Recommended for devs: 15
defaults write NSGlobalDomain InitialKeyRepeat -int 15

print_success "Key repeat configured (fast for coding)"

# ===========================
# === DISABLE AUTOCORRECT ===
# ===========================

print_debug "Disabling autocorrect and smart features..."

# Disable system-wide autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable continuous spell checking
defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false

# Disable inline predictive text
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false

# Disable suggested replies
defaults write NSGlobalDomain NSAutomaticSuggestedRepliesEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable automatic period substitution (two spaces to period)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

print_success "Autocorrect and smart features disabled"

# ===============================
# === TAHOE-SPECIFIC FIXES ===
# ===============================

# Check if running on macOS 15.0 (Tahoe) or later
if [[ -n "${MACOS_VERSION:-}" ]]; then
    version_compare "${MACOS_VERSION}" "15.0" || true
    version_check=$?

    if [[ ${version_check} -eq 0 || ${version_check} -eq 2 ]]; then
        print_debug "Applying macOS 15.0+ (Tahoe) specific settings..."

        # Disable automatic language detection for spell checking
        defaults write NSGlobalDomain KB_SpellingLanguage -dict KB_SpellingLanguageIsAutomatic -bool false

        # Disable WebKit-specific autocorrect (Safari, Mail, Notes)
        defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false

        # Ensure Safari respects autocorrect settings (may fail due to container permissions)
        defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false 2>/dev/null || true
        defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool false 2>/dev/null || true

        print_success "Tahoe-specific autocorrect fixes applied"
    else
        print_debug "macOS version < 15.0, skipping Tahoe-specific settings"
    fi
fi

# ===========================
# === ACCENT POPUP ===
# ===========================

print_debug "Accent popup configuration..."

# NOTE: ApplePressAndHoldEnabled is intentionally NOT disabled
# This keeps the accent popup enabled for international characters (ä, ö, ü, é, etc.)
# Developers who need to type international characters should keep this enabled

print_success "Accent popup kept enabled (for international characters)"

print_success "Keyboard settings configured"
