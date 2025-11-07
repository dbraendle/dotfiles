#!/usr/bin/env bash
# Desktop Profile Settings
# For stationary Macs (Mac mini, iMac, Mac Studio)
#
# Characteristics:
# - No password after sleep (convenience, physically secure location)
# - Mac never sleeps (long-running tasks)
# - All modules available
# - Performance over battery life

# Security Settings
export ENABLE_PASSWORD_AFTER_SLEEP=false  # Convenience for desktop
export PASSWORD_DELAY_SECONDS=0

# Power Management
export DISPLAY_SLEEP_MINUTES=15  # Display sleeps after 15 min
export SYSTEM_SLEEP_MINUTES=0    # Mac never sleeps
export DISK_SLEEP_ENABLED=false  # Keep disks spinning

# Module Availability
export ENABLE_PRINTER_MODULE=true   # Desktops usually have printers nearby
export ENABLE_SCANNER_MODULE=true   # Scanner integration available
export ENABLE_NETWORK_MOUNTS=true   # NAS/server mounts useful
export ENABLE_DOCK_MODULE=true      # Configure dock layout

# Performance Settings
export ANIMATION_SPEED=fast         # Fast animations for responsiveness
export REDUCE_TRANSPARENCY=false    # Eye candy OK on desktop
export REDUCE_MOTION=false

# Display Settings
export AUTO_BRIGHTNESS=true         # Adjust to lighting
export NIGHT_SHIFT_ENABLED=true     # Eye comfort

# Network Settings
export WIFI_POWERSAVE=false         # Keep WiFi at full power
export BLUETOOTH_ENABLED=true       # Peripherals common

# Development Settings
export ENABLE_DEVELOPMENT_MODULE=true   # Dev tools available
export ENABLE_CREATIVE_MODULE=true      # Adobe/creative tools OK

# Backup Settings
export TIME_MACHINE_ENABLED=true    # Regular backups
export BACKUP_FREQUENCY=hourly      # Frequent backups OK

# Profile Metadata
export PROFILE_NAME="desktop"
export PROFILE_DESCRIPTION="Desktop/Stationary Mac Configuration"
export PROFILE_OPTIMIZED_FOR="performance and convenience"
