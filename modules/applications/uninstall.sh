#!/usr/bin/env bash
# uninstall.sh - Applications module uninstallation script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../../lib/logging.sh"
source "${SCRIPT_DIR}/../../lib/stow-helpers.sh"

main() {
    print_section "Uninstalling Applications Module"

    local packages=("sublime")

    for package in "${packages[@]}"; do
        if unstow_package "${package}"; then
            print_success "${package} configuration unlinked"
        fi
    done

    print_success "Applications module uninstalled"
}

main "$@"
