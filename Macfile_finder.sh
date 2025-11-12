#!/usr/bin/env bash
# Finder Settings
# Configures Finder preferences for optimal developer/designer workflow

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring Finder settings..."
fi

print_status "Configuring Finder..."

# =====================
# === FINDER BARS ===
# =====================

print_debug "Enabling Finder bars (path, status, toolbar, sidebar)..."

# Path bar - shows folder path at bottom
defaults write com.apple.finder ShowPathbar -bool true

# Status bar - shows item count and available space
defaults write com.apple.finder ShowStatusBar -bool true

# Toolbar - shows navigation and view controls
defaults write com.apple.finder ShowToolbar -bool true

# Sidebar - shows favorites, devices, and locations
defaults write com.apple.finder ShowSidebar -bool true

# =====================
# === WINDOW BEHAVIOR ===
# =====================

print_debug "Configuring Finder window behavior..."

# Prevents forced column view in new windows
defaults write com.apple.finder AlwaysOpenWindowsInColumnView -bool false

# Folders always shown BEFORE files (not mixed)
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# NO automatic grouping (e.g. "By Date", "By Type") - everything in one list
defaults write com.apple.finder FXArrangeGroupViewBy -string "None"

# New windows for USB drives
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# =====================
# === FINDER BEHAVIOR ===
# =====================

print_debug "Configuring Finder behavior..."

# Full POSIX path in title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Search in current folder (not entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# New windows open Home directory
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# List view as default view style
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# ===========================
# === DESKTOP (MINIMAL) ===
# ===========================

print_debug "Configuring desktop (hiding all icons)..."

# External drives not shown on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Internal drives not shown on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false

# Servers not shown on desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

# USB drives not shown on desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# =====================
# === TAGS (HIDDEN) ===
# =====================

print_debug "Hiding tags in sidebar..."

# Hide recent tags section in sidebar
defaults write com.apple.finder ShowRecentTags -bool false

# Collapse tags section in sidebar
defaults write com.apple.finder SidebarTagsSctionDisclosedState -bool false

# =========================
# === FINDER SIDEBAR ===
# =========================

print_debug "Expanding sidebar sections..."

# Expand favorites section
defaults write com.apple.finder SidebarPlacesSectionDisclosedState -bool true

# Expand devices section
defaults write com.apple.finder SidebarDevicesSectionDisclosedState -bool true

# ===========================
# === ADVANCED SETTINGS ===
# ===========================

print_debug "Configuring advanced Finder settings..."

# No warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Text selectable in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

print_success "Finder settings configured"
