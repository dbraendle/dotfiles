#!/usr/bin/env bash
# update.sh - Scanner module update script
# Updates scanner shortcuts with current configuration

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
TEMPLATE_FILE="${SCRIPT_DIR}/templates/scan-shortcuts.sh.template"

# Scanner command names
SCANNER_COMMANDS=(
    "scan-document"
    "scan-photo"
    "scan-multipage"
    "scan-test"
    "scan-config"
)

#######################################
# Read scanner host from config file
# Returns:
#   Scanner host string, or empty if not found
#######################################
get_scanner_host() {
    if [[ -f "${SCANNER_CONFIG}" ]]; then
        grep "^SCANNER_HOST=" "${SCANNER_CONFIG}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'"
    fi
}

#######################################
# Render template with scanner host
# Arguments:
#   $1 - Scanner hostname/IP
#   $2 - Output file path
# Returns:
#   0 if successful, 1 otherwise
#######################################
render_template() {
    local host="$1"
    local output_file="$2"

    if [[ ! -f "${TEMPLATE_FILE}" ]]; then
        print_error "Template file not found: ${TEMPLATE_FILE}"
        return 1
    fi

    # Replace {{SCANNER_HOST}} with actual hostname
    sed "s|{{SCANNER_HOST}}|${host}|g" "${TEMPLATE_FILE}" > "${output_file}"

    if [[ -f "${output_file}" ]]; then
        chmod +x "${output_file}"
        return 0
    else
        print_error "Failed to render template to ${output_file}"
        return 1
    fi
}

#######################################
# Update scanner shortcuts
# Arguments:
#   $1 - Scanner hostname/IP
# Returns:
#   0 if successful, 1 otherwise
#######################################
update_scanner_shortcuts() {
    local host="$1"
    local temp_script
    temp_script=$(mktemp)

    print_status "Updating scanner shortcuts..."

    # Render template to temporary file
    if ! render_template "${host}" "${temp_script}"; then
        rm -f "${temp_script}"
        return 1
    fi

    # Check if we need sudo for /usr/local/bin
    local use_sudo=""
    if [[ ! -w "${INSTALL_PREFIX}" ]]; then
        use_sudo="sudo"
    fi

    # Update the main script
    local main_script="${INSTALL_PREFIX}/scan-shortcuts"

    # Copy the rendered template to main script location
    if [[ -n "${use_sudo}" ]]; then
        ${use_sudo} cp "${temp_script}" "${main_script}"
        ${use_sudo} chmod +x "${main_script}"
    else
        cp "${temp_script}" "${main_script}"
        chmod +x "${main_script}"
    fi

    print_success "Updated main script: ${main_script}"

    # Verify all symlinks are in place
    for cmd in "${SCANNER_COMMANDS[@]}"; do
        local cmd_path="${INSTALL_PREFIX}/${cmd}"

        if [[ ! -L "${cmd_path}" ]]; then
            print_warning "Creating missing symlink: ${cmd}"

            if [[ -n "${use_sudo}" ]]; then
                ${use_sudo} ln -s "${main_script}" "${cmd_path}"
            else
                ln -s "${main_script}" "${cmd_path}"
            fi
        fi
    done

    # Clean up temp file
    rm -f "${temp_script}"

    return 0
}

#######################################
# Main update function
#######################################
main() {
    print_section "Updating Scanner Module"

    # Check if scanner is configured
    local scanner_host
    scanner_host=$(get_scanner_host)

    if [[ -z "${scanner_host}" ]]; then
        print_error "Scanner is not configured"
        print_status "Run install.sh first to set up scanner configuration"
        return 1
    fi

    print_status "Current scanner host: ${scanner_host}"
    echo ""

    # Check if scanner shortcuts are installed
    local main_script="${INSTALL_PREFIX}/scan-shortcuts"
    if [[ ! -f "${main_script}" ]]; then
        print_error "Scanner shortcuts are not installed"
        print_status "Run install.sh first to install scanner shortcuts"
        return 1
    fi

    # Update scanner shortcuts
    if ! update_scanner_shortcuts "${scanner_host}"; then
        print_error "Failed to update scanner shortcuts"
        return 1
    fi

    echo ""
    print_success "Scanner shortcuts updated successfully!"
    echo ""

    # Show installed commands
    print_status "Available commands:"
    for cmd in "${SCANNER_COMMANDS[@]}"; do
        local cmd_path="${INSTALL_PREFIX}/${cmd}"
        if [[ -L "${cmd_path}" ]]; then
            print_success "  ${cmd}"
        else
            print_warning "  ${cmd} (missing)"
        fi
    done

    echo ""
    print_success "Scanner module update completed"
}

# Run main function
main "$@"
