#!/usr/bin/env bash
# Power Settings
# Profile-aware power management (desktop vs laptop)

set -euo pipefail

# Source logging if available
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    # shellcheck source=../../../lib/logging.sh
    source "${DOTFILES_ROOT}/lib/logging.sh"
else
    # Fallback if not running from install.sh
    echo "[INFO] Configuring power settings..."
fi

print_status "Configuring power management settings..."

# ===========================
# === DISPLAY SLEEP ===
# ===========================

print_debug "Configuring display sleep..."

# Get display sleep time from profile
local display_sleep="${DISPLAY_SLEEP_MINUTES:-15}"

print_debug "Setting display sleep to ${display_sleep} minutes"

# Set display sleep (applies to all power sources: battery, AC, UPS)
sudo pmset -a displaysleep "${display_sleep}"

print_success "Display sleep set to ${display_sleep} minutes"

# ===========================
# === SYSTEM SLEEP ===
# ===========================

print_debug "Configuring system sleep..."

# Get system sleep time from profile
local system_sleep="${SYSTEM_SLEEP_MINUTES:-0}"

print_debug "Setting system sleep to ${system_sleep} minutes"

# Set system sleep (applies to all power sources)
# 0 = never sleep
sudo pmset -a sleep "${system_sleep}"

if [[ "${system_sleep}" -eq 0 ]]; then
    print_success "System sleep disabled (Mac never sleeps)"
else
    print_success "System sleep set to ${system_sleep} minutes"
fi

# ===========================
# === DISK SLEEP ===
# ===========================

print_debug "Configuring disk sleep..."

# Get disk sleep setting from profile (if available)
if [[ -n "${DISK_SLEEP_ENABLED:-}" ]]; then
    if [[ "${DISK_SLEEP_ENABLED}" == "true" ]]; then
        # Enable disk sleep after 10 minutes
        sudo pmset -a disksleep 10
        print_success "Disk sleep enabled (10 minutes)"
    else
        # Disable disk sleep
        sudo pmset -a disksleep 0
        print_success "Disk sleep disabled"
    fi
else
    print_debug "DISK_SLEEP_ENABLED not set, keeping default disk sleep settings"
fi

# ===========================
# === POWER SUMMARY ===
# ===========================

print_debug "Current power settings:"
sudo pmset -g | grep -E "(sleep|displaysleep|disksleep)" || true

print_success "Power management settings configured"
