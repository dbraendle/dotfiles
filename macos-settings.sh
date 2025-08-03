#!/bin/bash

# macOS System Settings for Developers & Designers

echo "Configuring macOS system settings..."

# =====================
# === FINDER ===
# =====================

echo "→ Configuring Finder..."

# --- Finder Bars (always visible - even in new/small windows) ---

# Path bar
defaults write com.apple.finder ShowPathbar -bool true

# Status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Toolbar
defaults write com.apple.finder ShowToolbar -bool true

# Sidebar
defaults write com.apple.finder ShowSidebar -bool true

# --- All new windows with complete UI ---

# Prevents forced column view in new windows
defaults write com.apple.finder AlwaysOpenWindowsInColumnView -bool false

# Folders always shown BEFORE files (not mixed)
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# NO automatic grouping (e.g. "By Date", "By Type") - everything in one list
defaults write com.apple.finder FXArrangeGroupViewBy -string "None"

# --- Window behavior ---

# New windows for USB drives
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# --- Finder behavior ---

# Full path in title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Search in current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# New windows open Home
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# List view as default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"



# ===========================
# === FINDER ADVANCED ===
# ===========================

echo "→ Advanced Finder settings..."

# --- Desktop (nothing shown) ---

# External drives not shown on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Internal drives not shown on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false

# Servers not shown on desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

# USB drives not shown on desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false


# --- Tags (hide from sidebar) ---

# Hide recent tags section in sidebar
defaults write com.apple.finder ShowRecentTags -bool false

# Collapse tags section in sidebar
defaults write com.apple.finder SidebarTagsSctionDisclosedState -bool false



# =========================
# === FINDER SIDEBAR ===
# =========================

echo "→ Configuring Finder sidebar..."

# --- Only expand sections - do NOT hide any drives or folders ---

# Expand favorites section
defaults write com.apple.finder SidebarPlacesSectionDisclosedState -bool true

# Expand devices section
defaults write com.apple.finder SidebarDevicesSectionDisclosedState -bool true

echo "→ Manual setup required: Finder → Settings → Sidebar for custom folder order"

# --- Advanced Finder settings ---

# No warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Text selectable in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true



# =======================
# === SCREENSHOTS ===
# =======================

echo "→ Configuring screenshots..."

# Screenshots to dedicated folder
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

# PNG instead of JPG (better quality)
defaults write com.apple.screencapture type -string "png"

# Remove shadows (commented out - shadows wanted)
# defaults write com.apple.screencapture disable-shadow -bool true

# Date in FILENAME (not in image)
defaults write com.apple.screencapture include-date -bool true



# ============================
# === DEVELOPER SETTINGS ===
# ============================

echo "→ Configuring developer settings..."

# --- Keyboard settings ---

# Disabled - keeps accent popup enabled for international characters
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Faster key repeat when holding
defaults write NSGlobalDomain KeyRepeat -int 2

# Shorter delay before repeat starts
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# --- Trackpad ---

# Tap to click (Bluetooth trackpad)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Tap to click (built-in trackpad)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true



# ===========================
# === DESIGNER SETTINGS ===
# ===========================

echo "→ Configuring designer settings..."

# --- Customize menu bar (top right) ---

# Get system language for appropriate date format
if [[ $(defaults read NSGlobalDomain AppleLanguages | head -1 | tr -d '", ') == "de"* ]]; then
    # German system: "Sa. 2. Aug. (KW31) 22:27:14"
    defaults write com.apple.menuextra.clock DateFormat -string "EEE. d. MMM. '(KW'ww')' HH:mm:ss"
else
    # English system: "Sat Aug 3 (Week31) 22:27:14"  
    defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d '(Week'ww')' HH:mm:ss"
fi

# Shows battery percentage (87%) instead of just icon
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# --- Power settings (important for rendering) ---

# Display sleep after 15 minutes
sudo pmset -a displaysleep 15

# Mac never sleeps
sudo pmset -a sleep 0



# =======================
# === PERFORMANCE ===
# =======================

echo "→ Optimizing performance..."

# --- Faster animations ---

# Faster window resize
defaults write NSGlobalDomain NSWindowResizeTime -float 0.1

# Faster Mission Control
defaults write com.apple.dock expose-animation-duration -float 0.1



# ====================
# === SECURITY ===
# ====================

echo "→ Configuring security..."

# Enable firewall
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1



# ====================
# === NETWORK ===
# ====================

echo "→ Network settings..."

# DNS settings (keep router/PiHole configuration)
# networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1 2>/dev/null || true  # Disabled - preserves existing DNS setup



# ===========================
# === APPLYING CHANGES ===
# ===========================

echo "→ Applying settings..."

# --- Restart apps to apply changes ---

killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# --- Create screenshots directory ---

mkdir -p "$HOME/Desktop/Screenshots"

echo ""
echo "✅ Settings applied successfully:"
echo "   • Finder: All bars visible, list view"
echo "   • Screenshots: Dedicated folder, PNG format"
echo "   • Keyboard: Fast repeat for coding"
echo "   • Trackpad: Tap-to-click enabled"
echo "   • Performance: Animations accelerated"
echo "   • Security: Firewall enabled"
echo "   • Network: DNS settings preserved"