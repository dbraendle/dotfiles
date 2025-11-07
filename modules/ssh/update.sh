#!/usr/bin/env bash
# update.sh - SSH module update script
# Re-deploys SSH configuration template

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Main update function
#######################################
main() {
    print_section "Updating SSH Module (Template)"

    local ssh_dir="${HOME}/.ssh"
    local ssh_config="${ssh_dir}/config"

    # Check if config exists
    if [[ ! -f "${ssh_config}" ]]; then
        print_warning "SSH config does not exist: ${ssh_config}"
        print_status "Run install.sh to create initial template"
        return 1
    fi

    # Important notice
    echo ""
    print_warning "IMPORTANT: This will re-deploy the SSH template"
    print_status "If you have Ansible-managed configurations, they will be lost"
    print_status "Only proceed if you want to reset to the base template"
    echo ""

    if ! confirm "Continue with template update?" "n"; then
        print_status "Update cancelled"
        return 0
    fi

    # Create backup first
    print_status "Creating backup of current SSH config..."
    create_backup "${ssh_config}" || return 1

    # Get the template file location
    local dotfiles_dir
    dotfiles_dir="$(get_dotfiles_dir)" || return 1
    local template_file="${dotfiles_dir}/config/ssh/.ssh/config.template"

    if [[ ! -f "${template_file}" ]]; then
        print_error "Template file not found: ${template_file}"
        return 1
    fi

    # Deploy the template
    print_status "Deploying fresh SSH config template..."
    cp "${template_file}" "${ssh_config}"
    chmod 600 "${ssh_config}"
    print_success "Template updated successfully"

    echo ""
    print_success "SSH module update completed"
    print_status "Remember: Real server configs should be deployed by Ansible"
    echo ""
}

# Run main function
main "$@"
