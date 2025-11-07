#!/usr/bin/env bash
# Laptop Profile Settings
# For portable Macs (MacBook Air, MacBook Pro)
#
# Characteristics:
# - Password after sleep (security for portable device)
# - Battery optimizations
# - Reduced background processes
# - Security-first approach

# Security Settings
export ENABLE_PASSWORD_AFTER_SLEEP=true  # CRITICAL for portable devices
export PASSWORD_DELAY_SECONDS=0          # Immediate password requirement

# Power Management
export DISPLAY_SLEEP_MINUTES=10  # Conserve battery
export SYSTEM_SLEEP_MINUTES=30   # Sleep when inactive
export DISK_SLEEP_ENABLED=true   # Put disks to sleep

# Module Availability
export ENABLE_PRINTER_MODULE=false  # Printers less common on mobile
export ENABLE_SCANNER_MODULE=false  # Scanner integration rarely needed
export ENABLE_NETWORK_MOUNTS=true   # Useful when on home WiFi
export ENABLE_DOCK_MODULE=true      # Configure dock layout

# Performance Settings
export ANIMATION_SPEED=normal       # Balance performance and battery
export REDUCE_TRANSPARENCY=false    # Visual quality OK
export REDUCE_MOTION=false          # Animations OK

# Display Settings
export AUTO_BRIGHTNESS=true         # Critical for battery life
export NIGHT_SHIFT_ENABLED=true     # Eye comfort

# Network Settings
export WIFI_POWERSAVE=true          # Save battery
export BLUETOOTH_ENABLED=true       # Headphones, trackpad, etc.

# Development Settings
export ENABLE_DEVELOPMENT_MODULE=true   # Dev on the go
export ENABLE_CREATIVE_MODULE=true      # Adobe/creative tools OK

# Backup Settings
export TIME_MACHINE_ENABLED=true    # Regular backups when docked
export BACKUP_FREQUENCY=daily       # Less frequent to save battery

# Battery Optimization
export LOW_POWER_MODE_AUTO=true     # Enable low power mode automatically
export BACKGROUND_APP_REFRESH=false # Reduce background activity

# Profile Metadata
export PROFILE_NAME="laptop"
export PROFILE_DESCRIPTION="Laptop/Portable Mac Configuration"
export PROFILE_OPTIMIZED_FOR="security and battery life"
