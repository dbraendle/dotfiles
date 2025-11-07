#!/usr/bin/env bash
# uninstall.sh - Scanner module uninstallation script
# Removes scanner shortcuts and optionally configuration

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

# Configuration
SCANNER_CONFIG="${HOME}/.scanner-config"
INSTALL_PREFIX="/usr/local/bin"

# Scanner command names
SCANNER_COMMANDS=(
    "scan-document"
    "scan-photo"
    "scan-multipage"
    "scan-test"
    "scan-config"
)

#######################################
# Remove scanner shortcuts
# Returns:
#   0 if successful, 1 otherwise
#######################################
remove_scanner_shortcuts() {
    local main_script="${INSTALL_PREFIX}/scan-shortcuts"

    print_status "Removing scanner shortcuts..."

    # Check if we need sudo for /usr/local/bin
    local use_sudo=""
    if [[ ! -w "${INSTALL_PREFIX}" ]]; then
        use_sudo="sudo"
    fi

    # Remove each command symlink
    local removed=0
    for cmd in "${SCANNER_COMMANDS[@]}"; do
        local cmd_path="${INSTALL_PREFIX}/${cmd}"

        if [[ -L "${cmd_path}" || -f "${cmd_path}" ]]; then
            if [[ -n "${use_sudo}" ]]; then
                ${use_sudo} rm -f "${cmd_path}"
            else
                rm -f "${cmd_path}"
            fi
            print_success "  Removed ${cmd}"
            ((removed++))
        fi
    done

    # Remove main script
    if [[ -f "${main_script}" ]]; then
        if [[ -n "${use_sudo}" ]]; then
            ${use_sudo} rm -f "${main_script}"
        else
            rm -f "${main_script}"
        fi
        print_success "  Removed scan-shortcuts"
        ((removed++))
    fi

    if [[ ${removed} -eq 0 ]]; then
        print_warning "No scanner shortcuts found to remove"
    else
        print_success "Removed ${removed} scanner command(s)"
    fi

    return 0
}

#######################################
# Main uninstallation function
#######################################
main() {
    print_section "Uninstalling Scanner Module"

    # Remove scanner shortcuts
    if ! remove_scanner_shortcuts; then
        print_error "Failed to remove scanner shortcuts"
        return 1
    fi

    echo ""

    # Ask if user wants to remove the scanner configuration
    if [[ -f "${SCANNER_CONFIG}" ]]; then
        print_warning "Scanner configuration file exists: ${SCANNER_CONFIG}"
        echo ""

        if confirm "Remove scanner configuration?" "y"; then
            if create_backup "${SCANNER_CONFIG}"; then
                rm -f "${SCANNER_CONFIG}"
                print_success "Removed scanner configuration (backup created)"
            else
                print_error "Failed to create backup of scanner configuration"
                return 1
            fi
        else
            print_status "Kept scanner configuration file"
            print_status "You can remove it manually later: rm ${SCANNER_CONFIG}"
        fi
    else
        print_status "No scanner configuration found"
    fi

    echo ""
    print_success "Scanner module uninstallation completed"
    echo ""

    # Show reminder about scanned files
    local scan_dir="${HOME}/Documents/Scans"
    if [[ -d "${scan_dir}" ]]; then
        print_status "Note: Scanned files are still in: ${scan_dir}"
        print_status "Remove manually if no longer needed: rm -rf ${scan_dir}"
    fi
}

# Run main function
main "$@"
