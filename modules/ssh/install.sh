#!/usr/bin/env bash
# install.sh - SSH module installation script
# Deploys SSH configuration template (actual config managed by Ansible)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${SCRIPT_DIR}/../../lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${SCRIPT_DIR}/../../lib/utils.sh"

#######################################
# Main installation function
#######################################
main() {
    print_section "Installing SSH Module (Template)"

    # Check if SSH is installed
    if ! command_exists ssh; then
        print_error "SSH is not installed"
        print_status "Please install OpenSSH first"
        return 1
    fi

    print_success "SSH is installed: $(ssh -V 2>&1 | head -n1)"

    # Create .ssh directory if it doesn't exist
    local ssh_dir="${HOME}/.ssh"
    if [[ ! -d "${ssh_dir}" ]]; then
        print_status "Creating ${ssh_dir}..."
        mkdir -p "${ssh_dir}"
        chmod 700 "${ssh_dir}"
        print_success "Created ${ssh_dir} with secure permissions (700)"
    else
        print_success "SSH directory exists: ${ssh_dir}"
        # Ensure correct permissions
        chmod 700 "${ssh_dir}"
    fi

    # Create control socket directory for SSH multiplexing
    local ssh_sockets="${ssh_dir}/sockets"
    if [[ ! -d "${ssh_sockets}" ]]; then
        print_status "Creating SSH control socket directory..."
        mkdir -p "${ssh_sockets}"
        chmod 700 "${ssh_sockets}"
        print_success "Created ${ssh_sockets}"
    fi

    # Get the template file location
    local dotfiles_dir
    dotfiles_dir="$(get_dotfiles_dir)" || return 1
    local template_file="${dotfiles_dir}/config/ssh/.ssh/config.template"

    if [[ ! -f "${template_file}" ]]; then
        print_error "Template file not found: ${template_file}"
        return 1
    fi

    local ssh_config="${ssh_dir}/config"

    # Important notice about Ansible management
    echo ""
    print_warning "IMPORTANT: SSH configuration is managed by Homelab Ansible"
    print_status "This script only deploys a template configuration"
    print_status "The actual server configurations will be managed by Ansible"
    echo ""

    # Check if config already exists
    if [[ -f "${ssh_config}" ]]; then
        print_warning "SSH config already exists: ${ssh_config}"

        # Check if it's our template or a real config
        if grep -q "ANSIBLE_MANAGED_HOSTS_START" "${ssh_config}" 2>/dev/null; then
            print_status "Existing config appears to be template-based"
            if ! confirm "Overwrite with fresh template?" "n"; then
                print_status "Keeping existing configuration"
                print_success "SSH module installation completed (no changes)"
                return 0
            fi
        else
            print_warning "Existing config does not appear to be from this template"
            if ! confirm "Backup and replace with template?" "n"; then
                print_status "Keeping existing configuration"
                print_success "SSH module installation completed (no changes)"
                return 0
            fi
            # Create backup
            create_backup "${ssh_config}" || return 1
        fi
    fi

    # Deploy the template
    print_status "Deploying SSH config template..."
    cp "${template_file}" "${ssh_config}"
    chmod 600 "${ssh_config}"
    print_success "Deployed template to ${ssh_config} with secure permissions (600)"

    echo ""
    print_success "SSH module installation completed"
    echo ""
    print_status "Next steps:"
    print_status "  1. This is a TEMPLATE configuration"
    print_status "  2. Real server configs will be deployed by Ansible"
    print_status "  3. See services.example.json for example server data structure"
    print_status "  4. Never commit real server IPs/credentials to this repo"
    echo ""
}

# Run main function
main "$@"
