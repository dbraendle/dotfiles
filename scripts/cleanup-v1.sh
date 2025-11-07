#!/usr/bin/env bash
# Cleanup V1 Files - Remove deprecated files before V2 release
#
# This script removes old V1 files that have been replaced by V2 modules
# Creates a backup list before deletion for safety

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}  V1 Cleanup - Remove Deprecated Files ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo ""

# Files to remove (V1 deprecated)
V1_FILES=(
    "brew-install.sh"
    "npm-install.sh"
    "zsh-install.sh"
    "macos-settings.sh"
    "dock-setup.sh"
    "mount-setup.sh"
    "mount-setup-daemon.sh.deprecated"
    ".scan-shortcuts.sh"
    "ssh/ssh-setup.sh"
    "ssh/config.github"
    "ssh/config.pihole"
    "project_summary.md"
    "temp-apps-list.md"
    "chat-backup.md"
    "scansnap-home-legacy.rb"
    "FEEDBACK_CODEX.md"
    "true/"
)

# Files to KEEP (just for clarity)
KEEP_FILES=(
    "DEV_GUIDE.md"
    "DOTFILES_V2_ROADMAP.md"
    "DOTFILES_V2_ROADMAP_DE.md"
    "README.md"
    "LICENSE"
    ".editorconfig"
    "dock-apps.txt"  # Will be moved to modules/dock/ later
    "mounts.config.example"  # Template for mounts module
)

cd "$DOTFILES_DIR"

echo "This will remove the following V1 files:"
echo ""
for file in "${V1_FILES[@]}"; do
    if [[ -e "$file" ]]; then
        echo -e "  ${RED}✗${NC} $file"
    fi
done
echo ""

echo -e "${YELLOW}These files have been replaced by V2 modules.${NC}"
echo ""
read -p "Continue with cleanup? [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Removing V1 files..."

# Create backup list
BACKUP_LIST="backups/v1-removed-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p backups
echo "# V1 Files Removed on $(date)" > "$BACKUP_LIST"
echo "# Backup created for reference" >> "$BACKUP_LIST"
echo "" >> "$BACKUP_LIST"

REMOVED_COUNT=0

for file in "${V1_FILES[@]}"; do
    if [[ -e "$file" ]]; then
        echo "  Removing: $file"
        echo "$file" >> "$BACKUP_LIST"

        if [[ -d "$file" ]]; then
            rm -rf "$file"
        else
            rm -f "$file"
        fi

        ((REMOVED_COUNT++))
    fi
done

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo "Summary:"
echo "  • Removed: $REMOVED_COUNT files"
echo "  • Backup list: $BACKUP_LIST"
echo ""
echo "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Commit cleanup: git commit -m '🧹 Remove deprecated V1 files'"
echo "  3. Push to GitHub: git push origin v2-clean-rewrite"
echo ""
