#!/usr/bin/env bash
# System Module - Update Script
# Re-applies system settings with current profile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/logging.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

print_section "System Module - Update"

# Get current profile
if [[ -f "${HOME}/.dotfiles-profile" ]]; then
    PROFILE=$(cat "${HOME}/.dotfiles-profile")
else
    print_error "No profile set. Run ./install.sh first."
    exit 1
fi

print_status "Re-applying system settings for profile: $PROFILE"

# Re-run install with current profile
"${SCRIPT_DIR}/install.sh" --profile "$PROFILE"

print_success "System settings updated"
