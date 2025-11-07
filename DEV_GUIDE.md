# Dotfiles V2 - Developer Guide

> **FOR FUTURE CLAUDE INSTANCES:** This is your primary reference. Read this FIRST before making any changes.

**Last Updated:** 2025-01-07
**Version:** 2.0.0
**Branch:** v2-clean-rewrite

---

## Quick Reference for Common Tasks

### Adding a New Package to Brewfile

**Location:** `modules/homebrew/Brewfile`

**Steps:**
1. Edit `modules/homebrew/Brewfile`
2. Add package in appropriate section:
   ```ruby
   brew "package-name"    # CLI tool
   cask "app-name"        # GUI application
   mas "App Name", id: 123456  # Mac App Store app
   ```
3. Test: `brew bundle install --file=modules/homebrew/Brewfile`
4. Commit: `git commit -m "➕ Add package-name to Brewfile"`

### Changing a macOS System Setting

**Location:** `modules/system/settings/*.sh`

**Steps:**
1. Find relevant file in `modules/system/settings/`:
   - `finder.sh` - Finder settings
   - `keyboard.sh` - Keyboard/typing settings
   - `trackpad.sh` - Trackpad settings
   - `security.sh` - Security settings
   - `performance.sh` - Animation/performance
2. Add/modify `defaults write` command
3. Test on Desktop profile: `./modules/system/install.sh --profile desktop`
4. Test on Laptop profile: `./modules/system/install.sh --profile laptop`
5. Commit: `git commit -m "⚙️ Change [setting description]"`

### Adding a New Module

**Location:** `modules/[module-name]/`

**Steps:**
1. Create directory: `mkdir -p modules/[module-name]`
2. Create `modules/[module-name]/module.json`:
   ```json
   {
     "name": "module-name",
     "description": "What this module does",
     "category": "optional",
     "dependencies": ["homebrew"],
     "conflicts": [],
     "stow_packages": ["module-name"],
     "scripts": {
       "install": "modules/module-name/install.sh",
       "uninstall": "modules/module-name/uninstall.sh",
       "update": "modules/module-name/update.sh"
     },
     "profiles": ["desktop", "laptop"]
   }
   ```
3. Create `modules/[module-name]/install.sh`:
   ```bash
   #!/bin/bash
   set -e
   source "$(dirname "$0")/../../lib/logging.sh"

   print_status "Installing [module-name]..."
   # Installation logic here
   print_success "[module-name] installed"
   ```
4. Make executable: `chmod +x modules/[module-name]/install.sh`
5. If using Stow, create: `config/[module-name]/.[config-file]`
6. Test: `./manage.sh modules install [module-name]`
7. Commit: `git commit -m "✨ Add [module-name] module"`

### Modifying Profile-Specific Settings

**Location:** `profiles/desktop.sh` or `profiles/laptop.sh`

**Desktop Profile:**
- No password after sleep
- Mac never sleeps
- All modules available

**Laptop Profile:**
- Password after sleep enabled
- Battery optimizations
- Reduced background processes

**Steps:**
1. Edit `profiles/desktop.sh` or `profiles/laptop.sh`
2. Add/modify environment variable:
   ```bash
   export ENABLE_PASSWORD_AFTER_SLEEP=false  # desktop
   export ENABLE_PASSWORD_AFTER_SLEEP=true   # laptop
   ```
3. Use in module install scripts:
   ```bash
   source "$(dirname "$0")/../../profiles/$(cat ~/.dotfiles-profile).sh"
   if [[ "$ENABLE_PASSWORD_AFTER_SLEEP" == "true" ]]; then
       # Apply setting
   fi
   ```
4. Test both profiles
5. Commit: `git commit -m "🔧 Update profile settings"`

### Adding/Modifying Ansible Playbooks

**Location:** `ansible/playbooks/`

**Steps:**
1. Edit relevant playbook:
   - `mac-update.yml` - Nightly updates
   - `mac-setup.yml` - Initial Mac setup
   - `mac-secrets.yml` - Secrets distribution
2. Test with dry-run: `ansible-playbook playbooks/mac-update.yml --check`
3. Test on single Mac: `ansible-playbook playbooks/mac-update.yml --limit macbook-pro`
4. Commit: `git commit -m "🤖 Update Ansible playbook"`

---

## Architecture Overview

### Directory Structure

```
~/dotfiles/
├── install.sh              # Main installer (interactive menu)
├── update.sh               # Manual update script
├── manage.sh               # Module management CLI
├── lib/                    # Shared utilities
│   ├── colors.sh           # Color definitions
│   ├── logging.sh          # Print functions
│   ├── utils.sh            # Common functions
│   └── stow-helpers.sh     # Stow wrappers
├── profiles/               # Device profiles
│   ├── desktop.sh          # Desktop settings
│   └── laptop.sh           # Laptop settings
├── modules/                # Modular components
│   ├── system/             # macOS system settings
│   ├── homebrew/           # Package manager
│   ├── terminal/           # Shell configuration
│   ├── git/                # Git configuration
│   ├── dock/               # Dock management
│   ├── mounts/             # Network mounts
│   └── [others]/           # Additional modules
├── config/                 # Stow packages (symlinked)
│   ├── zsh/.zshrc          # Becomes ~/.zshrc
│   ├── git/.gitconfig      # Becomes ~/.gitconfig
│   └── [others]/           # Other configs
├── ansible/                # Homelab integration
│   ├── inventory/          # Hosts and variables
│   ├── playbooks/          # Ansible playbooks
│   └── roles/              # Reusable roles
├── scripts/                # Utility scripts
├── docs/                   # Documentation
└── logs/                   # Installation logs
```

### How It Works

1. **Installation:** User runs `./install.sh`, selects profile and modules
2. **Symlinking:** GNU Stow creates symlinks: `~/.zshrc` → `~/dotfiles/config/zsh/.zshrc`
3. **Daily Updates:** Ansible runs nightly on Homelab server:
   - Pulls latest from GitHub
   - Restows all active modules
   - Updates Homebrew packages
   - Applies security patches
4. **Secrets:** Managed by Bitwarden CLI on Homelab, distributed via Ansible

### Core Principles

- **Symlinks, not copies:** All configs symlinked via GNU Stow
- **Modular:** Every feature is an optional module
- **Profile-aware:** Desktop vs Laptop have different settings
- **Homelab-orchestrated:** Ansible handles updates and secrets
- **Self-documenting:** This guide + inline comments

---

## Key Files Explained

### `install.sh`

**Purpose:** Main installation script with interactive menu
**Usage:** `./install.sh [--profile desktop|laptop] [--modules core,dock,...]`

**Flow:**
1. Detect hardware (MacBook → laptop, Mac mini → desktop)
2. Show interactive menu (Full/Minimal/Custom)
3. Prompt for Git user details
4. Install core modules (system, homebrew, terminal, git)
5. Install selected optional modules
6. Stow all config files
7. Save active modules to `~/.dotfiles-modules`
8. Save profile to `~/.dotfiles-profile`

### `manage.sh`

**Purpose:** Module management CLI
**Usage:**
- `./manage.sh modules list` - List all available modules
- `./manage.sh modules status` - Show active modules
- `./manage.sh modules enable dock` - Enable a module
- `./manage.sh modules disable dock` - Disable a module
- `./manage.sh profile set laptop` - Change profile

### `update.sh`

**Purpose:** Manual update trigger (for on-demand updates)
**Usage:** `./update.sh [--force]`

**Steps:**
1. `git pull` - Pull latest from GitHub
2. Restow all active modules
3. `brew upgrade` - Update Homebrew packages
4. `npm update -g` - Update npm packages
5. Update Oh My Zsh
6. Re-apply system settings (profile-aware)

### `lib/logging.sh`

**Purpose:** Shared print functions for consistent output
**Usage:**
```bash
source "$(dirname "$0")/../../lib/logging.sh"
print_status "Doing something..."   # Blue [INFO]
print_success "Done!"                # Green [✓]
print_error "Failed!"                # Red [✗]
print_warning "Be careful!"          # Yellow [!]
```

### `profiles/*.sh`

**Purpose:** Profile-specific environment variables
**Loaded by:** Module install scripts

**Variables:**
- `ENABLE_PASSWORD_AFTER_SLEEP` - Password requirement after sleep
- `DISPLAY_SLEEP_MINUTES` - Display sleep timeout
- `SYSTEM_SLEEP_MINUTES` - System sleep timeout
- `ENABLE_PRINTER_MODULE` - Whether to install printer module
- `ENABLE_SCANNER_MODULE` - Whether to install scanner module

### `modules/*/module.json`

**Purpose:** Module metadata and configuration
**Schema:**
```json
{
  "name": "string",              // Module identifier
  "description": "string",        // Short description
  "category": "core|optional",    // Module category
  "dependencies": ["array"],      // Required modules
  "conflicts": ["array"],         // Conflicting modules
  "stow_packages": ["array"],     // Stow packages to link
  "scripts": {
    "install": "path/to/install.sh",
    "uninstall": "path/to/uninstall.sh",
    "update": "path/to/update.sh"
  },
  "profiles": ["desktop", "laptop"]  // Supported profiles
}
```

### `config/*/`

**Purpose:** Stow packages (configs that get symlinked)
**Convention:** Directory name matches package name, contents mirror home directory structure

**Example:**
```
config/zsh/
  .zshrc          → ~/.zshrc
  .zshenv         → ~/.zshenv

config/git/
  .gitconfig      → ~/.gitconfig

config/iterm2/
  Library/
    Preferences/
      com.googlecode.iterm2.plist  → ~/Library/Preferences/com.googlecode.iterm2.plist
```

---

## Common Patterns

### Profile-Aware Module Installation

```bash
#!/bin/bash
set -e
source "$(dirname "$0")/../../lib/logging.sh"

# Load profile
PROFILE=$(cat ~/.dotfiles-profile 2>/dev/null || echo "desktop")
source "$(dirname "$0")/../../profiles/${PROFILE}.sh"

print_status "Installing module (profile: $PROFILE)..."

if [[ "$PROFILE" == "laptop" ]]; then
    # Laptop-specific installation
    print_status "Applying laptop-specific settings..."
else
    # Desktop-specific installation
    print_status "Applying desktop-specific settings..."
fi

print_success "Module installed"
```

### Stow Integration

```bash
#!/bin/bash
set -e
source "$(dirname "$0")/../../lib/logging.sh"
source "$(dirname "$0")/../../lib/stow-helpers.sh"

MODULE_NAME="zsh"

print_status "Symlinking $MODULE_NAME configs..."

# Stow the package
stow_package "$MODULE_NAME"

# Add to active modules list
echo "$MODULE_NAME" >> ~/.dotfiles-modules
sort -u ~/.dotfiles-modules -o ~/.dotfiles-modules

print_success "$MODULE_NAME configs symlinked"
```

### Idempotent Installation

```bash
#!/bin/bash
set -e
source "$(dirname "$0")/../../lib/logging.sh"

# Check if already installed
if command -v some-tool &> /dev/null; then
    print_warning "some-tool already installed, skipping..."
    exit 0
fi

print_status "Installing some-tool..."
brew install some-tool
print_success "some-tool installed"
```

### Error Handling

```bash
#!/bin/bash
set -e  # Exit on any error
source "$(dirname "$0")/../../lib/logging.sh"

# Function with error handling
install_something() {
    print_status "Installing something..."

    if ! some-command; then
        print_error "Failed to install something"
        return 1
    fi

    print_success "Something installed"
}

# Call function and handle errors
if ! install_something; then
    print_error "Installation failed, rolling back..."
    # Rollback logic here
    exit 1
fi
```

---

## Testing

### Testing a Module

```bash
# Test module installation
./manage.sh modules install module-name

# Verify symlinks
ls -la ~ | grep module-name

# Test module functionality
# (module-specific tests)

# Test module uninstallation
./manage.sh modules uninstall module-name

# Verify cleanup
ls -la ~ | grep module-name  # Should be empty
```

### Testing Profiles

```bash
# Test desktop profile
./manage.sh profile set desktop
./modules/system/install.sh --profile desktop
# Verify: No password after sleep

# Test laptop profile
./manage.sh profile set laptop
./modules/system/install.sh --profile laptop
# Verify: Password after sleep enabled
```

### Testing Full Installation

```bash
# Backup current setup
./scripts/backup.sh

# Run full installation
./install.sh

# Verify all modules active
./manage.sh modules status

# Verify symlinks
ls -la ~ | grep "\->"

# Test update
./update.sh

# Rollback if needed
./scripts/restore.sh
```

---

## Git Workflow

### Commit Message Convention

Use emoji prefixes for clarity:

- `✨` `:sparkles:` - New feature/module
- `🔧` `:wrench:` - Configuration change
- `🐛` `:bug:` - Bug fix
- `📝` `:memo:` - Documentation
- `♻️` `:recycle:` - Refactoring
- `🎨` `:art:` - Code style/formatting
- `⚡` `:zap:` - Performance improvement
- `🔒` `:lock:` - Security fix
- `➕` `:heavy_plus_sign:` - Add dependency
- `➖` `:heavy_minus_sign:` - Remove dependency
- `🤖` `:robot:` - Ansible/automation

**Examples:**
```bash
git commit -m "✨ Add iterm2 module"
git commit -m "🔧 Update desktop profile settings"
git commit -m "🐛 Fix SSH config permissions"
git commit -m "📝 Update DEV_GUIDE with new patterns"
git commit -m "🤖 Add nightly update playbook"
```

### Branch Strategy

- `main` - Stable V2 production
- `v2-clean-rewrite` - Active development
- `v1-backup` - V1 backup for rollback

### Typical Workflow

```bash
# Make changes
vim modules/system/settings/finder.sh

# Test changes
./modules/system/install.sh --profile desktop

# Commit
git add modules/system/settings/finder.sh
git commit -m "🔧 Update Finder default view to list"

# Push
git push origin v2-clean-rewrite
```

---

## Ansible Integration

### Homelab Structure

```
~/homelab/ansible/
├── inventory/
│   └── hosts.yml           # Mac mini, MacBook Pro, MacBook Air
├── playbooks/
│   ├── mac-update.yml      # Nightly updates
│   ├── mac-setup.yml       # Initial setup
│   └── mac-secrets.yml     # Secrets distribution
└── roles/
    ├── dotfiles/           # Dotfiles management
    ├── secrets/            # Secrets distribution
    └── updates/            # Update management
```

### Triggering Updates from Homelab

**Manual:**
```bash
# On Homelab server
cd ~/homelab/ansible
ansible-playbook playbooks/mac-update.yml              # All Macs
ansible-playbook playbooks/mac-update.yml --limit macbook-pro  # One Mac
```

**Automatic (Cron):**
```bash
# /etc/crontab on Homelab server
0 3 * * * cd ~/homelab/ansible && ansible-playbook playbooks/mac-update.yml >> /var/log/ansible-mac-updates.log 2>&1
```

### Secrets Management via Bitwarden CLI

**On Homelab Server:**
```bash
# Install Bitwarden CLI
brew install bitwarden-cli

# Login
bw login your-email@example.com

# Unlock and get session
export BW_SESSION=$(bw unlock --raw)

# Retrieve secret in playbook
bw get item "ssh-key-github" --session $BW_SESSION | jq -r '.notes'
```

**In Ansible Playbook:**
```yaml
- name: Get SSH key from Bitwarden
  shell: bw get item "ssh-key-github" --session {{ bw_session }} | jq -r '.notes'
  register: github_key
  no_log: yes
```

---

## Troubleshooting

### Module won't install

**Check:**
1. Dependencies installed? `./manage.sh modules info module-name`
2. Script executable? `chmod +x modules/module-name/install.sh`
3. Conflicts? Check `module.json` conflicts array
4. Logs: `tail -f logs/install-$(date +%Y-%m-%d).log`

### Stow fails with "existing target is not a link"

**Solution:**
```bash
# Backup existing file
mv ~/.zshrc ~/.zshrc.backup

# Try stow again
stow -t ~ zsh

# If backup is identical, remove it
rm ~/.zshrc.backup
```

### Ansible can't connect to Mac

**Check:**
1. SSH access: `ssh mac-mini`
2. Firewall: System Settings → Network → Firewall
3. Remote Login: System Settings → Sharing → Remote Login (enable)
4. SSH key: `ssh-copy-id mac-mini`

### Settings not applied after profile change

**Solution:**
```bash
# Re-run system module installation
./modules/system/install.sh --profile $(cat ~/.dotfiles-profile)

# Restart affected apps
killall Finder
killall SystemUIServer
```

---

## Important Notes for Future Claude

### DO:
- ✅ Read this guide FIRST before making changes
- ✅ Test changes on one Mac before rolling out
- ✅ Commit frequently with descriptive messages
- ✅ Update this guide when adding new patterns
- ✅ Maintain backward compatibility when possible
- ✅ Document breaking changes in CHANGELOG.md

### DON'T:
- ❌ Commit secrets (SSH keys, passwords, server IPs)
- ❌ Modify V1 files (they're for reference only)
- ❌ Force-push to main branch
- ❌ Skip testing on real hardware
- ❌ Change core architecture without discussing with user
- ❌ Remove safety checks (backups, confirmations)

### When in Doubt:
1. Check this guide
2. Check DOTFILES_V2_ROADMAP.md for architectural decisions
3. Check existing module code for patterns
4. Ask user if making significant architectural changes

---

## Version History

- **2025-01-07:** Initial V2 structure created
- *[Future updates will be added here]*

---

**END OF DEV_GUIDE.md**

This document should be kept up-to-date as the project evolves.
