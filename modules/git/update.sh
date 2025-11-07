#!/usr/bin/env bash
# Git Module - Update Script
# Re-applies git configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/logging.sh"
source "${SCRIPT_DIR}/../../lib/stow-helpers.sh"

print_section "Git Module - Update"

# Restow git config
print_status "Re-symlinking git configuration..."
if restow_package "git"; then
    print_success "Git configuration updated"
else
    print_error "Failed to restow git configuration"
    exit 1
fi

# Verify
CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$CURRENT_NAME" ]] && [[ -n "$CURRENT_EMAIL" ]]; then
    print_success "Git configured for: $CURRENT_NAME <$CURRENT_EMAIL>"
else
    print_warning "Git user not configured. Run ./install.sh to configure."
fi
