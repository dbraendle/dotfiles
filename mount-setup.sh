#!/bin/bash

# MODERN AUTOFS MOUNT SETUP
# Reads mounts.config and creates autofs configuration
# Non-destructive approach - uses system autofs

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[AUTOFS]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🗂️  Modern Autofs Mount Setup"

# Config paths
AUTO_MASTER="/etc/auto_master"
AUTOFS_SYSTEM="/etc/auto_mounts"
MOUNT_BASE="/Volumes/auto_mounts"
AUTOFS_MOUNT_PATH="/../Volumes/auto_mounts"  # Using /../ trick for autofs

# Global temp directory for this script instance
TEMP_DIR="/tmp/mount_setup_$$"

# Parse config
parse_config() {
    # Check if mounts.config exists
    if [ ! -f "mounts.config" ]; then
        print_error "mounts.config file not found in current directory"
        return 1
    fi

    # Check if mounts.config is readable
    if [ ! -r "mounts.config" ]; then
        print_error "mounts.config is not readable"
        return 1
    fi

    # Use unique temp directory to avoid race conditions
    mkdir -p "$TEMP_DIR"

    # Clean up any old temp files from previous runs (legacy - be careful not to affect other scripts)
    # Only remove very old mount_* files (older than 1 hour)
    find /tmp -name "mount_*" -type f -mmin +60 -delete 2>/dev/null || true

    local current_section=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        if [[ "$line" =~ ^\[([^\]]+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]] && [[ -n "$current_section" ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            echo "$value" > "$TEMP_DIR/mount_${current_section}_${key}"
        fi
    done < "mounts.config"

    # Verify we found any config sections (more robust check)
    local found_sections=false
    for file in "$TEMP_DIR"/mount_*_enabled; do
        if [ -f "$file" ]; then
            found_sections=true
            break
        fi
    done

    if [ "$found_sections" = false ]; then
        print_error "No mount sections found in mounts.config"
        return 1
    fi
}

# Generate autofs map file directly to system
generate_autofs_map() {
    print_status "Generating autofs map to $AUTOFS_SYSTEM..."

    # Create temp file first (use unique name)
    local temp_map_file="$TEMP_DIR/auto_mounts"
    cat > "$temp_map_file" << 'HEADER_EOF'
# Autofs map for network mounts
# Auto-generated - do not edit manually
# Managed by dotfiles mount-setup.sh

HEADER_EOF

    local mount_count=0

    for config_file in "$TEMP_DIR"/mount_*_enabled; do
        if [ -f "$config_file" ] && [ "$(cat "$config_file")" = "true" ]; then
            local section=$(basename "$config_file" | sed 's/mount_\(.*\)_enabled/\1/')
            local type=$(cat "$TEMP_DIR/mount_${section}_type" 2>/dev/null || echo "nfs")
            local server=$(cat "$TEMP_DIR/mount_${section}_server" 2>/dev/null)
            local path=$(cat "$TEMP_DIR/mount_${section}_path" 2>/dev/null)
            local local_path=$(cat "$TEMP_DIR/mount_${section}_local" 2>/dev/null)
            local options=$(cat "$TEMP_DIR/mount_${section}_options" 2>/dev/null)

            if [ -n "$server" ] && [ -n "$path" ] && [ -n "$local_path" ]; then
                # Extract mount point name from local path
                local mount_name=$(basename "$local_path")

                # Add entry to autofs map
                if [ "$type" = "nfs" ]; then
                    echo "$mount_name -fstype=nfs,$options $server:$path" >> "$temp_map_file"
                elif [ "$type" = "smb" ]; then
                    echo "$mount_name -fstype=smbfs,$options ://$server$path" >> "$temp_map_file"
                fi

                print_status "Added: $mount_name -> $server:$path (${type})"
                ((mount_count++))
            fi
        fi
    done

    if [ $mount_count -eq 0 ]; then
        print_error "No enabled mounts found in config"
        return 1
    fi

    # Copy to system location with error handling
    if ! sudo cp "$temp_map_file" "$AUTOFS_SYSTEM"; then
        print_error "Failed to copy autofs map to system location"
        return 1
    fi
    sudo chmod 644 "$AUTOFS_SYSTEM"
    rm "$temp_map_file"

    print_success "Generated autofs map with $mount_count mounts"
}

# Check and update auto_master (kugelsicher)
update_auto_master() {
    print_status "Checking auto_master integration..."

    local autofs_entry="$AUTOFS_MOUNT_PATH auto_mounts"
    local comment_marker="# Dotfiles network mounts - managed by dotfiles/mount-setup.sh"

    # Check if our specific entry exists (not just any auto_mounts)
    if grep -q "^$MOUNT_BASE[[:space:]]\+auto_mounts" "$AUTO_MASTER" 2>/dev/null; then
        print_status "auto_master already correctly configured"
        return 0
    fi

    # Backup auto_master only if not already backed up today
    local backup_file="${AUTO_MASTER}.backup.$(date +%Y%m%d)"
    if [ ! -f "$backup_file" ]; then
        print_status "Creating daily backup of auto_master..."
        sudo cp "$AUTO_MASTER" "$backup_file"

        # Keep only last 10 backups
        print_status "Cleaning old backups (keeping max 10)..."
        sudo ls -t "${AUTO_MASTER}".backup.* 2>/dev/null | tail -n +11 | while read -r file; do sudo rm -f "$file"; done 2>/dev/null || true
    fi

    # Remove any old/conflicting entries first
    if grep -q "auto_mounts" "$AUTO_MASTER" 2>/dev/null; then
        print_status "Removing old auto_mounts entries..."
        sudo sed -i.tmp '/auto_mounts/d' "$AUTO_MASTER"
        sudo sed -i.tmp '/# Dotfiles network mounts/d' "$AUTO_MASTER"
        sudo rm -f "${AUTO_MASTER}.tmp"
    fi

    # Add our clean entry
    print_status "Adding auto_mounts entry to auto_master..."
    echo "$comment_marker" | sudo tee -a "$AUTO_MASTER" > /dev/null
    echo "$autofs_entry" | sudo tee -a "$AUTO_MASTER" > /dev/null

    print_success "Added entry to auto_master"
}

# Restart autofs
restart_autofs() {
    # Create mount base directory
    sudo mkdir -p "$MOUNT_BASE"

    # Smarter autofs restart - check if reload is sufficient first
    print_status "Reloading autofs configuration..."

    # Try simple reload first (often sufficient)
    if sudo automount -vc 2>/dev/null; then
        print_status "Configuration reloaded successfully"
    else
        # If simple reload fails, do full restart
        print_status "Simple reload failed, performing full restart..."

        # Check if autofsd is actually running first
        if sudo launchctl list | grep -q com.apple.autofsd; then
            print_status "Stopping autofs daemon..."
            sudo launchctl unload /System/Library/LaunchDaemons/com.apple.autofsd.plist 2>/dev/null || {
                print_status "Daemon was not loaded (this is normal)"
            }
        fi

        sleep 2

        print_status "Starting autofs daemon..."
        if ! sudo launchctl load /System/Library/LaunchDaemons/com.apple.autofsd.plist 2>/dev/null; then
            print_error "Failed to start autofs daemon"
            return 1
        fi

        sleep 2

        # Verify it started and reload config
        if ! sudo automount -vc 2>/dev/null; then
            print_error "Failed to reload autofs configuration after restart"
            return 1
        fi
    fi

    # Wait a moment for autofs to initialize
    sleep 3

    print_success "Autofs configuration reloaded"
}

# Clean up old unused mount points
cleanup_old_mounts() {
    print_status "Cleaning up old unused mount points..."

    # Get list of current mount names from config
    local current_mounts=()
    for config_file in "$TEMP_DIR"/mount_*_enabled; do
        if [ -f "$config_file" ] && [ "$(cat "$config_file")" = "true" ]; then
            local section=$(basename "$config_file" | sed 's/mount_\(.*\)_enabled/\1/')
            local local_path=$(cat "$TEMP_DIR/mount_${section}_local" 2>/dev/null)
            if [ -n "$local_path" ]; then
                local mount_name=$(basename "$local_path")
                current_mounts+=("$mount_name")
            fi
        fi
    done

    # Check each directory in auto_mounts
    if [ -d "$MOUNT_BASE" ]; then
        # Use nullglob to handle empty directory safely
        shopt -s nullglob
        for dir in "$MOUNT_BASE"/*; do
            # Skip if no files match (nullglob handles this, but double-check)
            [ -e "$dir" ] || continue
            if [ -d "$dir" ]; then
                local dir_name=$(basename "$dir")
                local is_current=false

                # Check if this directory is in current config
                for current in "${current_mounts[@]}"; do
                    if [ "$current" = "$dir_name" ]; then
                        is_current=true
                        break
                    fi
                done

                # Only remove if NOT in current config AND not an autofs mount point
                if [ "$is_current" = false ]; then
                    # Check if it's an autofs mount point by checking /etc/auto_mounts
                    if grep -q "^$dir_name " /etc/auto_mounts 2>/dev/null; then
                        print_status "Keeping $dir_name (defined in autofs configuration)"
                    elif mount | grep -q "$dir"; then
                        print_status "Keeping $dir_name (still mounted, will be cleaned after auto-unmount)"
                    else
                        # Only remove if directory is empty, not mounted, AND not in autofs config
                        if [ ! "$(ls -A "$dir" 2>/dev/null)" ]; then
                            print_status "Removing unused empty mount point: $dir_name"
                            sudo rmdir "$dir" 2>/dev/null && print_status "Removed: $dir_name" || print_status "Could not remove $dir_name"
                        else
                            print_status "Keeping $dir_name (contains files)"
                        fi
                    fi
                fi
            fi
        done
        shopt -u nullglob  # Reset nullglob
    fi
}

# Test mounts
test_mounts() {
    print_status "Testing mounts..."

    local success=0
    local total=0

    # First check if autofs mount point exists
    if [ ! -d "$MOUNT_BASE" ]; then
        print_error "Autofs mount point $MOUNT_BASE does not exist"
        return 1
    fi

    for config_file in "$TEMP_DIR"/mount_*_enabled; do
        if [ -f "$config_file" ] && [ "$(cat "$config_file")" = "true" ]; then
            local section=$(basename "$config_file" | sed 's/mount_\(.*\)_enabled/\1/')
            local local_path=$(cat "$TEMP_DIR/mount_${section}_local" 2>/dev/null)

            if [ -n "$local_path" ]; then
                local mount_name=$(basename "$local_path")
                local autofs_path="$MOUNT_BASE/$mount_name"

                ((total++))

                print_status "Testing $section at $autofs_path..."

                # Try to access the mount (this triggers autofs)
                if ls "$autofs_path" >/dev/null 2>&1; then
                    print_success "✅ $section works at $autofs_path"

                    # Create symlink to expected location if different
                    if [ "$autofs_path" != "$local_path" ]; then
                        sudo mkdir -p "$(dirname "$local_path")"
                        if [ ! -e "$local_path" ]; then
                            sudo ln -sf "$autofs_path" "$local_path"
                            print_status "Created symlink: $local_path -> $autofs_path"
                        fi
                    fi

                    ((success++))
                else
                    print_error "❌ $section failed at $autofs_path"
                    print_status "Check: sudo automount -v"
                fi
            fi
        fi
    done

    if [ $success -eq $total ] && [ $total -gt 0 ]; then
        print_success "🎉 ALL $total MOUNTS WORKING with autofs!"
        print_status "Access paths: $MOUNT_BASE/[mount_name]"
        print_status "Mounts are on-demand and will unmount automatically when not used"
    else
        print_error "$success/$total mounts working"
        print_status "Debug with: sudo automount -v"
    fi
}

# Cleanup temp files
cleanup() {
    # Only clean up our specific temp directory - don't touch other scripts' files
    rm -rf "$TEMP_DIR" 2>/dev/null || true

    # Legacy cleanup (remove after transition period)
    rm -f /tmp/auto_mounts 2>/dev/null || true
}
trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root! Use your regular user account."
        print_status "The script will use sudo when needed."
        exit 1
    fi

    # Check if sudo is available
    if ! command -v sudo >/dev/null 2>&1; then
        print_error "sudo command not found. This script requires sudo access."
        exit 1
    fi

    # Test sudo access
    print_status "Checking sudo access..."
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo access for system modifications."
        print_status "You may be prompted for your password."
        if ! sudo true; then
            print_error "Failed to obtain sudo access"
            exit 1
        fi
    fi
}

# Main execution
print_status "Checking prerequisites..."
check_prerequisites

print_status "Parsing config..."
if ! parse_config; then
    print_error "Failed to parse mounts.config"
    exit 1
fi

if ! generate_autofs_map; then
    print_error "Failed to generate autofs map"
    exit 1
fi

if ! update_auto_master; then
    print_error "Failed to update auto_master"
    exit 1
fi

if ! restart_autofs; then
    print_error "Failed to restart autofs"
    exit 1
fi

# Create LaunchDaemon to ensure mount point exists at boot
create_launchdaemon() {
    local plist_path="/Library/LaunchDaemons/com.dotfiles.auto-mounts-setup.plist"

    print_status "Creating LaunchDaemon for persistent mount point..."

    sudo tee "$plist_path" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.auto-mounts-setup</string>
    <key>RunAtLoad</key>
    <true/>
    <key>Program</key>
    <string>/bin/mkdir</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/mkdir</string>
        <string>-p</string>
        <string>/Volumes/auto_mounts</string>
    </array>
    <key>StandardOutPath</key>
    <string>/var/log/auto-mounts-setup.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/auto-mounts-setup.log</string>
</dict>
</plist>
EOF

    # Load the daemon
    if sudo launchctl load "$plist_path" 2>/dev/null; then
        print_success "LaunchDaemon created and loaded"
    else
        print_status "LaunchDaemon created (will load at next boot)"
    fi
}

cleanup_old_mounts
create_launchdaemon
test_mounts

print_success "🎉 DONE! Autofs mounts configured at $MOUNT_BASE/"
print_status "Mounts will auto-mount on access and auto-unmount when idle"
print_status "LaunchDaemon will ensure mount point exists after reboot"