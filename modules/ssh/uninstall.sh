#!/usr/bin/env bash
# uninstall.sh - SSH module uninstall script
# Removes SSH configuration (with backup)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Main uninstall function
#######################################
main() {
    print_section "Uninstalling SSH Module"

    local ssh_dir="${HOME}/.ssh"
    local ssh_config="${ssh_dir}/config"

    # Check if config exists
    if [[ ! -f "${ssh_config}" ]]; then
        print_warning "SSH config does not exist: ${ssh_config}"
        print_success "Nothing to uninstall"
        return 0
    fi

    echo ""
    print_warning "This will remove your SSH configuration file"
    print_status "A backup will be created before removal"
    print_status "Location: ${ssh_config}"
    echo ""

    if ! confirm "Continue with uninstall?" "n"; then
        print_status "Uninstall cancelled"
        return 0
    fi

    # Create backup
    print_status "Creating backup of SSH config..."
    create_backup "${ssh_config}" || return 1

    # Remove config file
    print_status "Removing SSH config..."
    rm -f "${ssh_config}"
    print_success "Removed ${ssh_config}"

    # Optionally clean up socket directory
    local ssh_sockets="${ssh_dir}/sockets"
    if [[ -d "${ssh_sockets}" ]]; then
        # Remove any stale sockets
        local socket_count
        socket_count=$(find "${ssh_sockets}" -type s 2>/dev/null | wc -l | tr -d ' ')
        if [[ "${socket_count}" -gt 0 ]]; then
            print_status "Cleaning up ${socket_count} SSH control socket(s)..."
            find "${ssh_sockets}" -type s -delete 2>/dev/null || true
        fi
    fi

    echo ""
    print_success "SSH module uninstall completed"
    print_status "SSH directory (~/.ssh) was preserved (contains keys)"
    print_status "A backup of your config was created"
    echo ""
}

# Run main function
main "$@"
