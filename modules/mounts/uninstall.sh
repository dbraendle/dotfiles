#!/usr/bin/env bash
# uninstall.sh - Mounts module uninstall script
# Removes network mount configuration from autofs

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Configuration paths
#######################################
AUTO_MASTER="/etc/auto_master"
AUTO_NFS="/etc/auto_nfs"
AUTO_SMB="/etc/auto_smb"

# Backup directory for /etc files
BACKUP_DIR="${HOME}/.dotfiles-backups/mounts"

#######################################
# Create backup of an /etc file
# Arguments:
#   $1 - File path to backup
#######################################
backup_etc_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        print_debug "File does not exist, no backup needed: $file"
        return 0
    fi

    ensure_dir "$BACKUP_DIR"

    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_file
    backup_file="${BACKUP_DIR}/$(basename "$file").backup-${timestamp}"

    print_debug "Backing up: $file -> $backup_file"

    if sudo cp -a "$file" "$backup_file"; then
        # Set ownership to current user for easier access
        sudo chown "$(get_real_user):staff" "$backup_file"
        print_success "Backup created: $backup_file"
        return 0
    else
        print_error "Failed to create backup of $file"
        return 1
    fi
}

#######################################
# Remove mount configurations
#######################################
remove_mount_configs() {
    print_subsection "Removing mount configurations"

    # Backup auto_master before modifying
    backup_etc_file "$AUTO_MASTER" || return 1

    # Remove NFS configuration
    if [[ -f "$AUTO_NFS" ]]; then
        print_status "Removing $AUTO_NFS"
        backup_etc_file "$AUTO_NFS"
        sudo rm -f "$AUTO_NFS"
        print_success "Removed $AUTO_NFS"

        # Remove NFS entry from auto_master
        if sudo grep -q "^/System/Volumes/Data/nfs" "$AUTO_MASTER" 2>/dev/null; then
            print_status "Removing NFS entry from $AUTO_MASTER"
            sudo sed -i.bak '/^\/System\/Volumes\/Data\/nfs/d' "$AUTO_MASTER"
            sudo rm -f "${AUTO_MASTER}.bak"
            print_success "Removed NFS entry from auto_master"
        fi
    fi

    # Remove SMB configuration
    if [[ -f "$AUTO_SMB" ]]; then
        print_status "Removing $AUTO_SMB"
        backup_etc_file "$AUTO_SMB"
        sudo rm -f "$AUTO_SMB"
        print_success "Removed $AUTO_SMB"

        # Remove SMB entry from auto_master
        if sudo grep -q "^/System/Volumes/Data/smb" "$AUTO_MASTER" 2>/dev/null; then
            print_status "Removing SMB entry from $AUTO_MASTER"
            sudo sed -i.bak '/^\/System\/Volumes\/Data\/smb/d' "$AUTO_MASTER"
            sudo rm -f "${AUTO_MASTER}.bak"
            print_success "Removed SMB entry from auto_master"
        fi
    fi

    return 0
}

#######################################
# Reload autofs
#######################################
reload_autofs() {
    print_subsection "Reloading autofs"

    print_status "Running: sudo automount -vc"

    if sudo automount -vc; then
        print_success "autofs reloaded successfully"
        return 0
    else
        print_error "Failed to reload autofs"
        return 1
    fi
}

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "Uninstalling Mounts Module"

    # Check if running on macOS
    if ! is_macos; then
        print_error "This module is only supported on macOS"
        return 1
    fi

    # Check if automount command exists
    if ! command_exists automount; then
        print_error "automount command not found"
        return 1
    fi

    # Check if any mount configurations exist
    if [[ ! -f "$AUTO_NFS" && ! -f "$AUTO_SMB" ]]; then
        print_warning "No mount configurations found"
        print_status "Module may not be installed or already uninstalled"
        return 0
    fi

    echo ""
    print_warning "This will remove all network mount configurations"
    print_warning "Backups will be created before removal"
    echo ""

    if ! confirm "Continue with uninstallation?" "n"; then
        print_status "Uninstallation cancelled"
        return 0
    fi

    echo ""

    # Remove configurations
    if ! remove_mount_configs; then
        print_error "Failed to remove mount configurations"
        return 1
    fi

    echo ""

    # Reload autofs
    if ! reload_autofs; then
        print_warning "Failed to reload autofs - you may need to reboot"
    fi

    echo ""
    print_section "Uninstallation Summary"
    print_success "Mounts module uninstalled successfully"
    echo ""
    print_status "Backups stored in: $BACKUP_DIR"
    echo ""
    print_status "Notes:"
    print_status "  - Mount point directories were not removed"
    print_status "  - Your Mountfile was preserved"
    print_status "  - Backups can be used to restore configuration if needed"
}

# Run main function
main "$@"
