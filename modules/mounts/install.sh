#!/usr/bin/env bash
# install.sh - Mounts module installation script
# Configures network mounts (NFS/SMB) via macOS autofs

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Configuration paths
#######################################
MOUNTS_CONFIG="${DOTFILES_ROOT}/mounts.config"
MOUNTS_CONFIG_EXAMPLE="${DOTFILES_ROOT}/mounts.config.example"

AUTO_MASTER="/etc/auto_master"
AUTO_NFS="/etc/auto_nfs"
AUTO_SMB="/etc/auto_smb"

# Backup directory for /etc files
BACKUP_DIR="${HOME}/.dotfiles-backups/mounts"

#######################################
# Parse a mount configuration line
# Arguments:
#   $1 - Configuration line (mountpoint|server|sharepath|type|options)
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Sets global variables: MOUNT_POINT, MOUNT_SERVER, MOUNT_SHARE, MOUNT_TYPE, MOUNT_OPTIONS
#######################################
parse_mount_line() {
    local line="$1"

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && return 1

    # Parse pipe-separated format
    IFS='|' read -r MOUNT_POINT MOUNT_SERVER MOUNT_SHARE MOUNT_TYPE MOUNT_OPTIONS <<< "$line"

    # Trim whitespace
    MOUNT_POINT="${MOUNT_POINT#"${MOUNT_POINT%%[![:space:]]*}"}"
    MOUNT_POINT="${MOUNT_POINT%"${MOUNT_POINT##*[![:space:]]}"}"
    MOUNT_SERVER="${MOUNT_SERVER#"${MOUNT_SERVER%%[![:space:]]*}"}"
    MOUNT_SERVER="${MOUNT_SERVER%"${MOUNT_SERVER##*[![:space:]]}"}"
    MOUNT_SHARE="${MOUNT_SHARE#"${MOUNT_SHARE%%[![:space:]]*}"}"
    MOUNT_SHARE="${MOUNT_SHARE%"${MOUNT_SHARE##*[![:space:]]}"}"
    MOUNT_TYPE="${MOUNT_TYPE#"${MOUNT_TYPE%%[![:space:]]*}"}"
    MOUNT_TYPE="${MOUNT_TYPE%"${MOUNT_TYPE##*[![:space:]]}"}"
    MOUNT_OPTIONS="${MOUNT_OPTIONS#"${MOUNT_OPTIONS%%[![:space:]]*}"}"
    MOUNT_OPTIONS="${MOUNT_OPTIONS%"${MOUNT_OPTIONS##*[![:space:]]}"}"

    # Validate required fields
    if [[ -z "$MOUNT_POINT" || -z "$MOUNT_SERVER" || -z "$MOUNT_SHARE" || -z "$MOUNT_TYPE" ]]; then
        return 1
    fi

    # Validate mount type
    if [[ "$MOUNT_TYPE" != "nfs" && "$MOUNT_TYPE" != "smb" ]]; then
        print_error "Invalid mount type: $MOUNT_TYPE (must be 'nfs' or 'smb')"
        return 1
    fi

    return 0
}

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
# Configure autofs for mounts
#######################################
configure_autofs() {
    local has_nfs=0
    local has_smb=0

    print_subsection "Configuring autofs"

    # Parse config file to determine what mount types we need
    while IFS= read -r line; do
        if parse_mount_line "$line"; then
            if [[ "$MOUNT_TYPE" == "nfs" ]]; then
                has_nfs=1
            elif [[ "$MOUNT_TYPE" == "smb" ]]; then
                has_smb=1
            fi
        fi
    done < "$MOUNTS_CONFIG"

    # Backup /etc/auto_master
    backup_etc_file "$AUTO_MASTER" || return 1

    # Configure NFS mounts
    if [[ $has_nfs -eq 1 ]]; then
        print_status "Configuring NFS mounts..."

        # Create auto_nfs file
        backup_etc_file "$AUTO_NFS"

        # Build auto_nfs content
        local nfs_content="# Autofs NFS mounts - Managed by dotfiles\n"
        nfs_content+="# Generated: $(date '+%Y-%m-%d %H:%M:%S')\n\n"

        while IFS= read -r line; do
            if parse_mount_line "$line"; then
                if [[ "$MOUNT_TYPE" == "nfs" ]]; then
                    # Extract mount name (last path component)
                    local mount_name
                    mount_name="$(basename "$MOUNT_POINT")"

                    # Build autofs entry: mountname -options server:/sharepath
                    local opts="${MOUNT_OPTIONS:-resvport,bg,hard,intr}"
                    nfs_content+="${mount_name} -${opts} ${MOUNT_SERVER}:${MOUNT_SHARE}\n"

                    print_debug "NFS: ${mount_name} -> ${MOUNT_SERVER}:${MOUNT_SHARE}"
                fi
            fi
        done < "$MOUNTS_CONFIG"

        # Write auto_nfs
        echo -e "$nfs_content" | sudo tee "$AUTO_NFS" > /dev/null
        sudo chmod 644 "$AUTO_NFS"
        print_success "Created $AUTO_NFS"

        # Add to auto_master if not present
        if ! sudo grep -q "^/System/Volumes/Data/nfs" "$AUTO_MASTER" 2>/dev/null; then
            echo "/System/Volumes/Data/nfs auto_nfs" | sudo tee -a "$AUTO_MASTER" > /dev/null
            print_success "Added NFS to $AUTO_MASTER"
        else
            print_debug "NFS entry already in auto_master"
        fi
    fi

    # Configure SMB mounts
    if [[ $has_smb -eq 1 ]]; then
        print_status "Configuring SMB mounts..."

        # Create auto_smb file
        backup_etc_file "$AUTO_SMB"

        # Build auto_smb content
        local smb_content="# Autofs SMB mounts - Managed by dotfiles\n"
        smb_content+="# Generated: $(date '+%Y-%m-%d %H:%M:%S')\n\n"

        while IFS= read -r line; do
            if parse_mount_line "$line"; then
                if [[ "$MOUNT_TYPE" == "smb" ]]; then
                    # Extract mount name (last path component)
                    local mount_name
                    mount_name="$(basename "$MOUNT_POINT")"

                    # Build autofs entry: mountname -options ://server/sharepath
                    local opts="${MOUNT_OPTIONS:-soft}"
                    smb_content+="${mount_name} -fstype=smbfs,${opts} ://${MOUNT_SERVER}/${MOUNT_SHARE}\n"

                    print_debug "SMB: ${mount_name} -> //${MOUNT_SERVER}/${MOUNT_SHARE}"
                fi
            fi
        done < "$MOUNTS_CONFIG"

        # Write auto_smb
        echo -e "$smb_content" | sudo tee "$AUTO_SMB" > /dev/null
        sudo chmod 644 "$AUTO_SMB"
        print_success "Created $AUTO_SMB"

        # Add to auto_master if not present
        if ! sudo grep -q "^/System/Volumes/Data/smb" "$AUTO_MASTER" 2>/dev/null; then
            echo "/System/Volumes/Data/smb auto_smb" | sudo tee -a "$AUTO_MASTER" > /dev/null
            print_success "Added SMB to $AUTO_MASTER"
        else
            print_debug "SMB entry already in auto_master"
        fi
    fi

    return 0
}

#######################################
# Create mount point directories
#######################################
create_mountpoints() {
    print_subsection "Creating mount point directories"

    while IFS= read -r line; do
        if parse_mount_line "$line"; then
            # Get parent directory for autofs
            local autofs_dir
            autofs_dir="$(dirname "$MOUNT_POINT")"

            if [[ ! -d "$autofs_dir" ]]; then
                print_status "Creating: $autofs_dir"
                if sudo mkdir -p "$autofs_dir"; then
                    sudo chmod 755 "$autofs_dir"
                    print_success "Created: $autofs_dir"
                else
                    print_error "Failed to create: $autofs_dir"
                    return 1
                fi
            else
                print_debug "Directory exists: $autofs_dir"
            fi
        fi
    done < "$MOUNTS_CONFIG"

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
# Test mounts (attempt to access them)
#######################################
test_mounts() {
    print_subsection "Testing mounts"

    local tested=0
    local successful=0

    while IFS= read -r line; do
        if parse_mount_line "$line"; then
            ((tested++))

            print_status "Testing: $MOUNT_POINT"

            # Try to list directory (this triggers autofs)
            # Use timeout to avoid hanging
            if timeout 5 ls "$MOUNT_POINT" > /dev/null 2>&1; then
                print_success "Mount accessible: $MOUNT_POINT"
                ((successful++))
            else
                print_warning "Mount not accessible: $MOUNT_POINT"
                print_status "  This is normal if the server is not reachable"
                print_status "  The mount will be attempted when accessed"
            fi
        fi
    done < "$MOUNTS_CONFIG"

    echo ""
    print_status "Mount test results: ${successful}/${tested} accessible"

    return 0
}

#######################################
# Main installation function
#######################################
main() {
    print_section "Installing Mounts Module"

    # Check if running on macOS
    if ! is_macos; then
        print_error "This module is only supported on macOS"
        return 1
    fi

    # Check if automount command exists
    if ! command_exists automount; then
        print_error "automount command not found"
        print_error "This module requires macOS autofs support"
        return 1
    fi

    # Check for mounts.config
    if [[ ! -f "$MOUNTS_CONFIG" ]]; then
        print_warning "Configuration file not found: $MOUNTS_CONFIG"
        echo ""

        if [[ -f "$MOUNTS_CONFIG_EXAMPLE" ]]; then
            print_status "Example configuration available at:"
            print_status "  $MOUNTS_CONFIG_EXAMPLE"
            echo ""
            print_status "To configure mounts:"
            print_status "  1. Copy: cp $MOUNTS_CONFIG_EXAMPLE $MOUNTS_CONFIG"
            print_status "  2. Edit $MOUNTS_CONFIG with your mount details"
            print_status "  3. Run this installation again"
        else
            print_status "Create $MOUNTS_CONFIG with your mount configuration"
            print_status "Format: mountpoint|server|sharepath|type|options"
            print_status "Example: /System/Volumes/Data/nfs/media|192.168.1.100|/volume1/media|nfs|resvport,bg"
        fi

        echo ""
        print_error "Cannot proceed without configuration file"
        return 1
    fi

    print_success "Configuration file found: $MOUNTS_CONFIG"
    echo ""

    # Display warning about sudo
    print_warning "This module requires sudo access to modify /etc files"
    echo ""

    if ! confirm "Continue with installation?" "y"; then
        print_status "Installation cancelled"
        return 0
    fi

    echo ""

    # Configure autofs
    if ! configure_autofs; then
        print_error "Failed to configure autofs"
        return 1
    fi

    echo ""

    # Create mount points
    if ! create_mountpoints; then
        print_error "Failed to create mount points"
        return 1
    fi

    echo ""

    # Reload autofs
    if ! reload_autofs; then
        print_error "Failed to reload autofs"
        return 1
    fi

    echo ""

    # Test mounts
    test_mounts

    echo ""
    print_section "Installation Summary"
    print_success "Mounts module installation completed"
    echo ""
    print_status "Configuration files:"
    print_status "  - $AUTO_MASTER"
    [[ -f "$AUTO_NFS" ]] && print_status "  - $AUTO_NFS"
    [[ -f "$AUTO_SMB" ]] && print_status "  - $AUTO_SMB"
    echo ""
    print_status "Backups stored in: $BACKUP_DIR"
    echo ""
    print_status "Mounts will be automatically mounted when accessed"
    print_status "To manually test a mount: ls /System/Volumes/Data/nfs/<mountname>"
}

# Run main function
main "$@"
