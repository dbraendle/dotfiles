# Dotfiles V2 - Complete Roadmap & Architecture

> **Version:** 2.0.0
> **Date:** 2025-01-07
> **Author:** Analysis & Recommendations by Claude (Sonnet 4.5)
> **Status:** Planning Phase

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problems with V1](#2-problems-with-v1)
3. [V2 Vision & Goals](#3-v2-vision--goals)
4. [Architecture Overview](#4-architecture-overview)
5. [GNU Stow Integration](#5-gnu-stow-integration)
6. [Modular System Design](#6-modular-system-design)
7. [Profile System](#7-profile-system)
8. [Homelab Integration](#8-homelab-integration)
9. [SSH & Secrets Management](#9-ssh--secrets-management)
10. [Installation Flow](#10-installation-flow)
11. [Update Strategy](#11-update-strategy)
12. [Security Improvements](#12-security-improvements)
13. [File Structure](#13-file-structure)
14. [Tools & Technologies](#14-tools--technologies)
15. [Migration Path](#15-migration-path)
16. [Implementation Roadmap](#16-implementation-roadmap)
17. [Summary](#17-summary)

---

## 1. Executive Summary

**Current State:** V1 dotfiles are functional but chaotic - 3000+ lines of shell scripts with security issues, code duplication, documentation drift, and accumulating technical debt.

**Goal:** Transform into a professional, modular, Homelab-integrated dotfiles system that:
- Uses **GNU Stow** for symlink-based config management (no more copying)
- Offers **modular installation** via interactive CLI menu
- Integrates with **Ansible** for automated nightly updates across all Macs
- Separates **Desktop vs Laptop profiles** for device-specific settings
- Implements **proper secrets management** (Bitwarden CLI or Ansible Vault)
- Maintains **maximum coverage** - if a setting can be automated, it will be
- Keeps **VS Code settings** out (handled by GitHub Settings Sync)

**Key Change:** From "copy configs on install" to "symlink everything + Ansible orchestration"

**Timeline:** 4-6 weeks for full V2 implementation

---

## 2. Problems with V1

### Critical Issues

**Security:**
- Real server IPs/usernames committed to repository (`ssh/services.json`)
- Password after sleep disabled on all devices (line `macos-settings.sh:252`)
- Incorrect SSH config permissions (644 instead of 600)
- Unverified remote downloads (`curl | sudo tee`)
- CUPS web interface enabled without documentation

**Code Quality:**
- 6 scripts duplicate color definitions and print functions
- 1012-line `ssh-setup.sh` with complex menu system
- `npm-install.sh` uses `return 1` outside functions (should be `exit 1`)
- Hardcoded paths (`~/Dev/dotfiles`) break if repo moved
- System command aliases (`ls→eza`, `cat→bat`) break scripts

**Architecture:**
- Two parallel SSH systems (ssh-wunderbar + legacy script)
- Config files copied instead of symlinked (changes not tracked)
- No automated sync between machines
- Brewfile has duplicate entries (`cask "stats"` twice)
- Mixed German/English documentation

**Maintenance:**
- Documentation claims features not implemented (`--headless`, `--ssh-only`)
- Orphaned files (`temp-apps-list.md`, `true/` directory)
- Commented code everywhere
- No shell linting (shellcheck)
- No testing infrastructure

### What Works Well (Keep!)

✅ **Modular design** - scripts can run standalone
✅ **Idempotency** - safe to run multiple times
✅ **Interactive prompts** - good UX
✅ **Comprehensive coverage** - handles system settings, packages, terminal, git, dock, mounts
✅ **Smart automation** - detects Apple Silicon vs Intel, offers fallbacks
✅ **Backup creation** - before making changes

---

## 3. V2 Vision & Goals

### Core Principles

1. **Symlink Everything** - GNU Stow manages all dotfiles, changes immediately reflected
2. **Modular by Design** - Every feature is an optional module
3. **Homelab-Orchestrated** - Ansible triggers nightly updates, manages secrets
4. **Profile-Based** - Desktop vs Laptop have different security/power settings
5. **Security-First** - No secrets in repo, proper permissions, verified downloads
6. **Maximum Coverage** - Automate everything possible (Alfred, iTerm2, Dock, Printing, etc.)
7. **Single Source of Truth** - GitHub repo + Homelab secrets vault
8. **Zero Manual Work** - New Mac: clone repo, run install, answer 3 questions, done

### Target Workflow

**Initial Setup (Fresh Mac):**
```bash
git clone https://github.com/dbraendle/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
# Interactive menu appears:
#   [1] Full Installation (Desktop Profile)
#   [2] Full Installation (Laptop Profile)
#   [3] Custom - Select Modules
# Select option, enter Git user details, done in 30 min
```

**Daily Operations:**
```bash
# Edit any config file directly in ~/dotfiles/
vim ~/dotfiles/zsh/.zshrc
# Changes immediately active (symlinked)
git commit -am "Update zsh config"
git push
# Homelab Ansible pulls changes nightly to all Macs
```

**Module Management:**
```bash
./manage.sh --enable module-name   # Activate a module
./manage.sh --disable module-name  # Deactivate a module
./manage.sh --status               # Show active modules
```

---

## 4. Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│              github.com/dbraendle/dotfiles                   │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  Config    │  │  Modules   │  │  Scripts   │           │
│  │  Files     │  │  (opt-in)  │  │  (core)    │           │
│  │  (Stow)    │  │            │  │            │           │
│  └────────────┘  └────────────┘  └────────────┘           │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │ git pull (nightly via Ansible)
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                    Homelab Ansible                           │
│                                                              │
│  ┌────────────────┐  ┌─────────────────┐                   │
│  │  Secrets Vault │  │  Update Playbook│                   │
│  │  (Bitwarden/   │  │  - brew update  │                   │
│  │   Ansible Vault)│  │  - git pull     │                   │
│  │                │  │  - stow restow  │                   │
│  └────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐      ┌──────────┐      ┌──────────┐
   │  Mac     │      │  Mac     │      │  Mac     │
   │  Mini    │      │  Book    │      │  Book    │
   │ (Desktop)│      │ (Laptop) │      │(Desktop) │
   └──────────┘      └──────────┘      └──────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                Symlinks to ~/dotfiles/* (via Stow)
```

### Component Breakdown

**1. GitHub Repository (Public)**
- Source code for all scripts
- Config file templates (no secrets)
- Documentation
- Brewfile with package definitions
- Module definitions

**2. Homelab Ansible**
- Central orchestration server
- Secrets storage (Bitwarden CLI or Ansible Vault)
- Nightly update playbooks
- SSH config distribution
- Security patch management

**3. Individual Macs**
- Clone of dotfiles repo in `~/dotfiles`
- GNU Stow symlinks: `~/.zshrc` → `~/dotfiles/zsh/.zshrc`
- Active modules tracked in `~/.dotfiles-modules`
- Profile stored in `~/.dotfiles-profile` (`desktop` or `laptop`)

---

## 5. GNU Stow Integration

### What is GNU Stow?

GNU Stow is a symlink farm manager. It creates symlinks from a source directory tree to a target directory tree.

**Traditional Approach (V1):**
```bash
# Dotfiles copied to home directory
cp ~/dotfiles/.zshrc ~/.zshrc
# Problem: Changes in ~/.zshrc NOT tracked in Git
# Must manually copy back to dotfiles repo
```

**GNU Stow Approach (V2):**
```bash
# Dotfiles symlinked to home directory
stow -d ~/dotfiles -t ~ zsh
# Creates: ~/.zshrc → ~/dotfiles/zsh/.zshrc
# Changes in ~/.zshrc automatically in Git repo
```

### Directory Structure for Stow

```
~/dotfiles/
├── zsh/
│   ├── .zshrc          # Will become ~/.zshrc
│   └── .zshenv         # Will become ~/.zshenv
├── git/
│   └── .gitconfig      # Will become ~/.gitconfig
├── ssh/
│   └── .ssh/
│       └── config      # Will become ~/.ssh/config
├── vscode/             # OPTIONAL - only if not using GitHub Sync
│   └── .config/
│       └── Code/
│           └── User/
│               └── settings.json
├── alfred/
│   └── Library/
│       └── Application Support/
│           └── Alfred/
│               └── Alfred.alfredpreferences/
└── iterm2/
    └── .config/
        └── iterm2/
            └── com.googlecode.iterm2.plist
```

### Stow Workflow

**Initial Setup:**
```bash
# Install Stow via Homebrew
brew install stow

# Stow all packages
cd ~/dotfiles
stow -t ~ zsh git ssh alfred iterm2

# Verify symlinks
ls -la ~ | grep "\->"
# Output:
# .zshrc -> dotfiles/zsh/.zshrc
# .gitconfig -> dotfiles/git/.gitconfig
```

**Making Changes:**
```bash
# Edit file directly (symlink resolves to dotfiles)
vim ~/.zshrc
# Or edit in repo
vim ~/dotfiles/zsh/.zshrc
# Both are the same file!

# Commit changes
cd ~/dotfiles
git add zsh/.zshrc
git commit -m "Update zsh aliases"
git push
```

**Restowing (e.g., after git pull):**
```bash
cd ~/dotfiles
stow -R -t ~ zsh  # Restow to pick up new files
```

### Benefits

✅ **Single Source of Truth** - Only one copy of each config file
✅ **Immediate Sync** - Changes instantly reflected
✅ **Version Control** - All changes tracked in Git
✅ **Easy Rollback** - `git revert` works on live configs
✅ **Multi-Machine Sync** - Git pull + restow = instant sync
✅ **Selective Deployment** - Stow only what you need

### Caveats

⚠️ **Existing Files:** Stow refuses to overwrite. Must backup/remove first.
⚠️ **Directory Structure:** Must match target paths exactly.
⚠️ **Protected Files:** Some macOS files require specific permissions.
⚠️ **Templating:** Git user placeholders need pre-processing before stowing.

---

## 6. Modular System Design

### Module Architecture

Each module is self-contained with:
- Config files (if applicable)
- Installation script (`install.sh`)
- Uninstallation script (`uninstall.sh`)
- Dependencies list
- Documentation

### Core Modules (Always Installed)

**1. system** - macOS System Settings
- Finder, Keyboard, Trackpad, Screenshots
- Performance optimizations
- Security baseline (firewall, etc.)
- Profile-aware (Desktop vs Laptop differences)

**2. homebrew** - Package Manager
- Installs Homebrew (Apple Silicon / Intel detection)
- Processes Brewfile
- Sets up auto-cleanup

**3. terminal** - Shell Configuration
- Oh My Zsh installation
- Zsh plugins (autosuggestions, syntax highlighting)
- `.zshrc` with aliases and functions
- Stow-managed

**4. git** - Version Control
- `.gitconfig` with aliases and settings
- Interactive user/email setup
- Credential helper (macOS keychain)
- Stow-managed

### Optional Modules

**5. dock** - Dock Management
- `dockutil` for automated dock layout
- Loads from `dock-apps.txt`
- Spacers and folders

**6. mounts** - Network Mounts
- autofs configuration for NFS/SMB
- On-demand mounting
- Loads from `mounts.config`
- LaunchDaemon management

**7. ssh** - SSH Configuration
- SSH config generation
- Alias creation (`ssh myserver` → `ssh user@192.168.1.10`)
- Managed by Homelab (secrets from Ansible)
- Public key distribution handled by Ansible

**8. printer** - Printing Setup
- CUPS configuration
- Printer auto-discovery
- Default printer setup
- Optional (manual opt-in)

**9. iterm2** - iTerm2 Configuration
- Color schemes
- Profiles
- Hotkeys
- Stow-managed

**10. alfred** - Alfred Workflows
- Custom workflows
- Hotkeys
- Preferences
- Stow-managed (if using Dropbox sync, skip)

**11. development** - Development Tools
- Docker daemon configuration
- Node version manager setup
- Custom dev aliases
- Project templates

**12. creative** - Creative Tools
- Adobe preferences (if applicable)
- Font installation
- Color profiles

**13. scanner** - Scanner Integration
- Scanner shortcuts (`.scan-shortcuts.sh`)
- Requires hostname variable for scan server
- Optional

### Module Manifest

Each module has a `module.json`:

```json
{
  "name": "dock",
  "description": "Automated Dock configuration",
  "category": "optional",
  "dependencies": ["homebrew"],
  "conflicts": [],
  "stow_packages": [],
  "scripts": {
    "install": "modules/dock/install.sh",
    "uninstall": "modules/dock/uninstall.sh",
    "update": "modules/dock/update.sh"
  },
  "profiles": ["desktop", "laptop"],
  "settings": {
    "dock_apps_file": "config/dock-apps.txt"
  }
}
```

### Module CLI

```bash
# Interactive menu
./install.sh
# > Select modules:
# > [x] core (system, homebrew, terminal, git)
# > [ ] dock
# > [ ] mounts
# > [ ] ssh (managed by Homelab)
# > ...

# Direct module management
./manage.sh modules list                  # List all modules
./manage.sh modules enable dock           # Enable dock module
./manage.sh modules disable dock          # Disable dock module
./manage.sh modules status                # Show active modules
./manage.sh modules install dock          # Install specific module
./manage.sh modules uninstall dock        # Uninstall specific module
```

---

## 7. Profile System

### Profile Types

**Desktop Profile:**
- **No password after sleep** (convenience, stationary machine)
- **Mac never sleeps** (long-running tasks)
- **All modules available** (mounts, printer, scanner)
- **Performance optimizations**

**Laptop Profile:**
- **Password after sleep ENABLED** (security, portable)
- **Battery optimizations** (display sleep 10min)
- **Reduced background processes**
- **Optional modules** (skip printer, scanner)

### Profile Detection

**Automatic (Recommended):**
```bash
# Detect if MacBook (portable) or Mac mini/iMac (desktop)
if system_profiler SPHardwareDataType | grep -q "MacBook"; then
    PROFILE="laptop"
else
    PROFILE="desktop"
fi
```

**Manual Override:**
```bash
./install.sh --profile desktop
./install.sh --profile laptop
```

**Change Profile Later:**
```bash
./manage.sh profile set laptop
# Re-applies profile-specific settings
```

### Profile-Specific Settings

**File:** `profiles/desktop.sh`
```bash
# Desktop-specific macOS settings
export ENABLE_PASSWORD_AFTER_SLEEP=false
export DISPLAY_SLEEP_MINUTES=15
export SYSTEM_SLEEP_MINUTES=0
export ENABLE_PRINTER_MODULE=true
export ENABLE_SCANNER_MODULE=true
export ENABLE_NETWORK_MOUNTS=true
```

**File:** `profiles/laptop.sh`
```bash
# Laptop-specific macOS settings
export ENABLE_PASSWORD_AFTER_SLEEP=true
export DISPLAY_SLEEP_MINUTES=10
export SYSTEM_SLEEP_MINUTES=30
export ENABLE_PRINTER_MODULE=false  # Optional, ask user
export ENABLE_SCANNER_MODULE=false
export ENABLE_NETWORK_MOUNTS=true   # Useful on home WiFi
```

### Profile Storage

```bash
# After installation, profile stored locally
echo "laptop" > ~/.dotfiles-profile

# Scripts load profile on every run
PROFILE=$(cat ~/.dotfiles-profile)
source "$(dirname "$0")/profiles/${PROFILE}.sh"
```

---

## 8. Homelab Integration

### Architecture

**Homelab Responsibilities:**
1. **Automated Updates** - Nightly Ansible playbook runs on all Macs
2. **Secrets Distribution** - SSH keys, API tokens, certificates
3. **Centralized Logging** - Update success/failure tracking
4. **Configuration Enforcement** - Ensure dotfiles are current
5. **Security Patching** - Minor OS updates (not major versions)

### Ansible Playbook Structure

```
~/homelab/ansible/
├── inventory/
│   ├── hosts.yml          # All Mac hosts
│   └── group_vars/
│       └── macs.yml       # Mac-specific variables
├── playbooks/
│   ├── mac-update.yml     # Nightly update playbook
│   ├── mac-setup.yml      # Initial setup (runs install.sh)
│   └── mac-secrets.yml    # Secrets distribution
├── roles/
│   ├── dotfiles/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── git-pull.yml
│   │   │   ├── stow-restow.yml
│   │   │   └── homebrew-update.yml
│   │   └── templates/
│   │       └── ssh_config.j2
│   ├── secrets/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── ssh-keys.yml
│   │   │   └── certificates.yml
│   │   └── vars/
│   │       └── main.yml    # Encrypted with ansible-vault
│   └── updates/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── macos-minor-updates.yml
│       │   └── homebrew-updates.yml
└── ansible.cfg
```

### Nightly Update Playbook

**File:** `playbooks/mac-update.yml`
```yaml
---
- name: Nightly Mac Dotfiles & Package Updates
  hosts: macs
  become: no
  vars:
    dotfiles_path: "{{ ansible_env.HOME }}/dotfiles"

  tasks:
    - name: Check if dotfiles repo exists
      stat:
        path: "{{ dotfiles_path }}"
      register: dotfiles_repo

    - name: Pull latest dotfiles from GitHub
      git:
        repo: "https://github.com/dbraendle/dotfiles.git"
        dest: "{{ dotfiles_path }}"
        update: yes
        force: no
      when: dotfiles_repo.stat.exists

    - name: Restow all active modules
      shell: |
        cd {{ dotfiles_path }}
        for module in $(cat ~/.dotfiles-modules); do
          stow -R -t ~ "$module"
        done
      args:
        executable: /bin/zsh

    - name: Update Homebrew packages
      homebrew:
        update_homebrew: yes
        upgrade_all: yes
      ignore_errors: yes

    - name: Cleanup Homebrew
      shell: brew cleanup && brew autoremove
      args:
        executable: /bin/zsh

    - name: Update npm global packages
      npm:
        name: "*"
        global: yes
        state: latest
      ignore_errors: yes

    - name: Update Oh My Zsh
      shell: |
        cd ~/.oh-my-zsh
        git pull --rebase --autostash
      args:
        executable: /bin/zsh
      ignore_errors: yes

    - name: Check for macOS minor updates
      shell: softwareupdate --list 2>&1 | grep -v "No new software available"
      register: macos_updates
      ignore_errors: yes
      changed_when: false

    - name: Install macOS minor updates (security only)
      shell: softwareupdate --install --no-scan --agree-to-license --recommended
      when: macos_updates.stdout != ""
      become: yes

    - name: Log update timestamp
      shell: echo "$(date): Dotfiles updated successfully" >> ~/.dotfiles-update.log
```

### Secrets Distribution

**File:** `playbooks/mac-secrets.yml`
```yaml
---
- name: Distribute SSH Keys and Secrets
  hosts: macs
  become: no
  vars_files:
    - ../roles/secrets/vars/main.yml  # ansible-vault encrypted

  tasks:
    - name: Ensure .ssh directory exists
      file:
        path: "{{ ansible_env.HOME }}/.ssh"
        state: directory
        mode: '0700'

    - name: Deploy SSH private keys
      copy:
        content: "{{ item.private_key }}"
        dest: "{{ ansible_env.HOME }}/.ssh/{{ item.name }}"
        mode: '0600'
      loop: "{{ ssh_keys }}"
      no_log: yes

    - name: Deploy SSH public keys
      copy:
        content: "{{ item.public_key }}"
        dest: "{{ ansible_env.HOME }}/.ssh/{{ item.name }}.pub"
        mode: '0644'
      loop: "{{ ssh_keys }}"

    - name: Generate SSH config from template
      template:
        src: ../roles/secrets/templates/ssh_config.j2
        dest: "{{ ansible_env.HOME }}/.ssh/config"
        mode: '0600'

    - name: Add SSH keys to agent
      shell: |
        eval "$(ssh-agent -s)"
        ssh-add {{ ansible_env.HOME }}/.ssh/{{ item.name }}
      loop: "{{ ssh_keys }}"
      no_log: yes
```

### Ansible Inventory

**File:** `inventory/hosts.yml`
```yaml
all:
  children:
    macs:
      hosts:
        mac-mini:
          ansible_host: 192.168.178.50
          ansible_user: db
          profile: desktop
        macbook-pro:
          ansible_host: 192.168.178.51
          ansible_user: db
          profile: laptop
        macbook-air:
          ansible_host: 192.168.178.52
          ansible_user: db
          profile: desktop  # Repurposed as desktop
```

### Ansible Cron Job

**On Homelab Server:**
```bash
# Run nightly at 3 AM
0 3 * * * cd ~/homelab/ansible && ansible-playbook playbooks/mac-update.yml >> /var/log/ansible-mac-updates.log 2>&1
```

### Benefits

✅ **All Macs Stay Synced** - Changes pushed to GitHub propagate nightly
✅ **Security Patches** - Minor updates applied automatically
✅ **Centralized Secrets** - No SSH keys in dotfiles repo
✅ **Audit Trail** - Ansible logs all changes
✅ **Rollback Capability** - Ansible can revert to previous state

---

## 9. SSH & Secrets Management

### Problem with V1

- `ssh/services.json` contains real server IPs/users (security risk)
- SSH keys managed locally per-Mac (inconsistent)
- No central authority for key rotation
- ssh-wunderbar useful but redundant with Homelab

### V2 Approach: Ansible-Managed SSH

**Secrets Storage Options:**

**Option A: Bitwarden CLI (Recommended for You)**

**Pros:**
- Already using Bitwarden (both desktop + MAS app)
- Official CLI tool: `brew install bitwarden-cli`
- Secure item storage with encryption
- Easy integration with Ansible
- Can store SSH keys, API tokens, passwords
- Accessible from any device

**Cons:**
- Requires internet for first auth (cached after)
- Subscription needed for some features (you likely have)

**Implementation:**
```yaml
# Ansible playbook uses Bitwarden CLI
- name: Get SSH key from Bitwarden
  shell: bw get item "github-ssh-key" --session {{ bw_session }} | jq -r '.notes'
  register: github_key
  no_log: yes

- name: Deploy SSH key
  copy:
    content: "{{ github_key.stdout }}"
    dest: "~/.ssh/id_ed25519"
    mode: '0600'
```

**Setup:**
```bash
# On Homelab server
brew install bitwarden-cli
bw login your-email@example.com
bw unlock  # Get session token
export BW_SESSION="session-token"

# Store SSH keys in Bitwarden as Secure Notes
bw create item '{
  "type": 2,
  "name": "github-ssh-key",
  "notes": "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
  "secureNote": {"type": 0}
}'
```

**Option B: Ansible Vault**

**Pros:**
- Built into Ansible
- No external dependencies
- Encrypted with master password
- Simple key-value storage

**Cons:**
- Another password to manage
- No GUI
- Less flexible than Bitwarden

**Implementation:**
```bash
# Create encrypted vars file
ansible-vault create roles/secrets/vars/main.yml

# Content:
---
ssh_keys:
  - name: id_ed25519_github
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    public_key: "ssh-ed25519 AAAA... user@host"
    services:
      - github.com
  - name: id_ed25519_pihole
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
    public_key: "ssh-ed25519 AAAA..."
    services:
      - pihole
      - 192.168.178.32

# Use in playbooks
ansible-playbook --ask-vault-pass playbooks/mac-secrets.yml
```

**Recommendation: Use Bitwarden CLI**

You already have Bitwarden infrastructure, so leverage it. Ansible Vault adds another password layer unnecessarily.

### SSH Config Management

**Template:** `roles/secrets/templates/ssh_config.j2`
```jinja
# Generated by Ansible - DO NOT EDIT MANUALLY
# Last updated: {{ ansible_date_time.iso8601 }}

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes
    UseKeychain yes

{% for server in ssh_servers %}
# {{ server.description }}
Host {{ server.alias }}
    HostName {{ server.hostname }}
    User {{ server.user }}
    Port {{ server.port | default(22) }}
    IdentityFile ~/.ssh/{{ server.key_name }}
    {% if server.forward_agent | default(false) %}
    ForwardAgent yes
    {% endif %}
    AddKeysToAgent yes
    UseKeychain yes
{% endfor %}
```

**Variables (from Bitwarden or Ansible Vault):**
```yaml
ssh_servers:
  - alias: pihole
    description: Home PiHole DNS Server
    hostname: 192.168.178.32
    user: pi
    key_name: id_ed25519_pihole

  - alias: digitalocean
    description: DigitalOcean VPS
    hostname: 209.38.217.45
    user: root
    key_name: id_ed25519_do
    forward_agent: yes

  - alias: allinkl
    description: All-Inkl Web Hosting
    hostname: w0103394.kasserver.com
    user: ssh-w0103394
    key_name: id_ed25519_allinkl
```

### SSH Aliases in .zshrc

Generated automatically from Ansible inventory:

```bash
# ~/.zshrc (generated section)
# SSH Aliases - Auto-generated by Ansible
alias ssh-pihole='ssh pihole'
alias ssh-do='ssh digitalocean'
alias ssh-allinkl='ssh allinkl'
```

### Key Rotation

```bash
# On Homelab server
ansible-playbook playbooks/rotate-ssh-keys.yml --limit macbook-pro
# Generates new keys, updates Bitwarden, deploys to Mac, updates servers
```

### Benefits

✅ **No Secrets in GitHub** - Dotfiles repo is public-safe
✅ **Centralized Management** - One Bitwarden vault for all keys
✅ **Easy Rotation** - Update Bitwarden, run playbook, done
✅ **Consistent SSH Config** - All Macs have identical setup
✅ **Audit Trail** - Ansible logs when keys were deployed

---

## 10. Installation Flow

### Fresh Mac Setup (V2)

**Step 1: Bootstrap**
```bash
# New Mac out of the box
# Open Terminal.app

# Install Xcode Command Line Tools
xcode-select --install

# Clone dotfiles repo
git clone https://github.com/dbraendle/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**Step 2: Run Installer**
```bash
./install.sh
```

**Step 3: Interactive Menu**
```
╔════════════════════════════════════════════════════════════╗
║               Dotfiles V2 Installation                     ║
╚════════════════════════════════════════════════════════════╝

Detected: MacBook Pro (Laptop Profile)

Installation Options:
  [1] Full Installation (Recommended)
      - System Settings (Laptop Profile)
      - Homebrew + All Packages
      - Terminal (Zsh + Oh My Zsh)
      - Git Configuration
      - Dock Configuration
      - Network Mounts
      - iTerm2 Configuration
      - Alfred Configuration

  [2] Minimal Installation (Core Only)
      - System Settings
      - Homebrew + Essential Packages
      - Terminal (Zsh + Oh My Zsh)
      - Git Configuration

  [3] Custom - Select Modules

  [4] Change Profile (Switch to Desktop)

  [Q] Quit

Select option [1-4, Q]:
```

**Step 4: User Input**
```
Git Configuration
-----------------
Enter your Git name: Daniel Brändle
Enter your Git email: daniel@example.com

SSH Configuration
-----------------
SSH keys will be managed by Homelab Ansible.
Do you want to generate a temporary key for GitHub? [y/N]: y

Scanner Configuration (Optional)
---------------------------------
Enter scanner server hostname (leave empty to skip): scanserver.local

Installation will begin in 5 seconds...
Press Ctrl+C to cancel.
```

**Step 5: Installation Progress**
```
╔════════════════════════════════════════════════════════════╗
║                  Installing Modules                        ║
╚════════════════════════════════════════════════════════════╝

[1/8] System Settings (Laptop Profile).................... ✓
[2/8] Homebrew Installation............................... ✓
[3/8] Brewfile Processing (25 packages)................... ✓
[4/8] Terminal Setup (Zsh + Oh My Zsh).................... ✓
[5/8] Git Configuration................................... ✓
[6/8] GNU Stow - Symlinking dotfiles...................... ✓
[7/8] Dock Configuration.................................. ✓
[8/8] iTerm2 Configuration................................ ✓

╔════════════════════════════════════════════════════════════╗
║              Installation Complete! 🎉                     ║
╚════════════════════════════════════════════════════════════╝

Active Modules:
  • system (laptop profile)
  • homebrew
  • terminal
  • git
  • dock
  • iterm2

Next Steps:
  1. Restart Terminal or run: source ~/.zshrc
  2. Log into Mac App Store: mas signin
  3. Run: brew bundle install  (for MAS apps)
  4. Homelab Ansible will deploy SSH keys on next run
  5. Customize: vim ~/dotfiles/zsh/.zshrc

Useful Commands:
  ./manage.sh modules status       - Show active modules
  ./manage.sh modules list         - List all modules
  ./manage.sh profile info         - Show current profile
  ./update.sh                      - Manual update trigger

Installation log: ~/dotfiles/logs/install-2025-01-07.log
```

**Step 6: First Ansible Run**
```bash
# On Homelab server (or automatic on nightly cron)
ansible-playbook playbooks/mac-setup.yml --limit macbook-pro

# Deploys:
# - SSH keys from Bitwarden
# - SSH config with aliases
# - Any additional secrets
# - Registers Mac for nightly updates
```

---

## 11. Update Strategy

### Update Types

**1. Dotfiles Changes (Immediate)**
- User edits `~/dotfiles/zsh/.zshrc`
- Changes symlinked, immediately active
- Git commit + push
- Other Macs get changes on next Ansible run (nightly)

**2. Homebrew Packages (Nightly via Ansible)**
- Ansible runs `brew update && brew upgrade`
- Minor version updates only (e.g., 1.2.3 → 1.2.4)
- Major versions skipped (require manual approval)

**3. npm Packages (Nightly via Ansible)**
- `npm update -g` for global packages
- Minor security updates applied

**4. macOS Security Updates (Nightly via Ansible)**
- `softwareupdate --install --recommended`
- Only security and minor patches
- **Major macOS versions excluded** (e.g., Sonoma → Sequoia)

**5. Oh My Zsh (Nightly via Ansible)**
- `cd ~/.oh-my-zsh && git pull`

**6. Manual Updates (On-Demand)**
- User runs `./update.sh` for immediate update
- Useful after changing Brewfile or system settings

### Ansible Update Logic

**Smart Update Rules:**
```yaml
# Homebrew - Skip major updates
- name: List outdated packages
  shell: brew outdated --json
  register: outdated_packages

- name: Filter minor updates only
  set_fact:
    safe_updates: "{{ outdated_packages.stdout | from_json | selectattr('current_version', 'match', '^[0-9]+\\.[0-9]+\\.') | list }}"

- name: Upgrade safe packages
  homebrew:
    name: "{{ item.name }}"
    state: latest
  loop: "{{ safe_updates }}"

# macOS - Skip major versions
- name: Check macOS updates
  shell: softwareupdate --list --no-scan 2>&1
  register: macos_updates

- name: Filter security updates only
  set_fact:
    security_updates: "{{ macos_updates.stdout_lines | select('search', 'recommended|security') | list }}"

- name: Install security updates
  shell: softwareupdate --install --no-scan --agree-to-license {{ item }}
  loop: "{{ security_updates }}"
  become: yes
```

### Manual Update Script

**File:** `update.sh`
```bash
#!/bin/bash
set -e

echo "╔════════════════════════════════════════╗"
echo "║     Dotfiles Manual Update             ║"
echo "╚════════════════════════════════════════╝"

# Pull latest from GitHub
echo "[1/6] Pulling latest dotfiles from GitHub..."
git pull

# Restow all active modules
echo "[2/6] Re-symlinking dotfiles..."
while read -r module; do
    stow -R -t ~ "$module"
done < ~/.dotfiles-modules

# Update Homebrew
echo "[3/6] Updating Homebrew packages..."
brew update
brew upgrade

# Update npm global packages
echo "[4/6] Updating npm global packages..."
npm update -g

# Update Oh My Zsh
echo "[5/6] Updating Oh My Zsh..."
(cd ~/.oh-my-zsh && git pull)

# Re-apply system settings (profile-aware)
echo "[6/6] Re-applying system settings..."
PROFILE=$(cat ~/.dotfiles-profile)
./modules/system/install.sh --profile "$PROFILE"

echo ""
echo "✅ Update complete!"
echo "   Restart Terminal: source ~/.zshrc"
```

### Update Frequency

| Component | Frequency | Trigger | Major Versions |
|-----------|-----------|---------|----------------|
| Dotfiles | Immediate | Git commit + symlink | N/A |
| Homebrew | Nightly | Ansible | Manual only |
| npm | Nightly | Ansible | Manual only |
| macOS | Nightly | Ansible | **Manual only** |
| Oh My Zsh | Nightly | Ansible | N/A |
| Manual | On-demand | `./update.sh` | All components |

---

## 12. Security Improvements

### Fixes for V1 Issues

**1. Remove Real Server Data**
```bash
# Immediate action
git rm ssh/services.json
git commit -m "Remove sensitive server data"

# Create example template
cat > ssh/services.example.json << 'EOF'
{
  "github": {
    "hostname": "github.com",
    "user": "git",
    "description": "GitHub"
  },
  "example-server": {
    "hostname": "192.168.1.100",
    "user": "your-username",
    "description": "Example server"
  }
}
EOF

# Add to .gitignore
echo "ssh/services.json" >> .gitignore
echo "*.secret" >> .gitignore
echo "*.vault" >> .gitignore
```

**2. Fix SSH Config Permissions**
```bash
# In ssh module install script
chmod 600 ~/.ssh/config  # Not 644
chmod 600 ~/.ssh/id_*    # Private keys
chmod 644 ~/.ssh/id_*.pub # Public keys OK
chmod 700 ~/.ssh         # Directory
```

**3. Password After Sleep - Profile-Aware**
```bash
# profiles/laptop.sh
if [[ "$PROFILE" == "laptop" ]]; then
    # ENABLE password requirement (security)
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
else
    # Desktop - optional
    read -p "Disable password after sleep (desktop)? [y/N]: " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        defaults write com.apple.screensaver askForPassword -int 0
    fi
fi
```

**4. Verify Remote Downloads**
```bash
# Use signed releases with checksums
SSH_WUNDERBAR_VERSION="v1.0.0"
SSH_WUNDERBAR_URL="https://github.com/dbraendle/ssh-wunderbar/releases/download/${SSH_WUNDERBAR_VERSION}/ssh-wunderbar"
SSH_WUNDERBAR_SHA256="expected-checksum-here"

curl -fsSL "$SSH_WUNDERBAR_URL" -o /tmp/ssh-wunderbar
echo "${SSH_WUNDERBAR_SHA256}  /tmp/ssh-wunderbar" | shasum -a 256 -c || exit 1
sudo mv /tmp/ssh-wunderbar /usr/local/bin/
```

**5. CUPS Web Interface - Optional**
```bash
# Only enable if needed
read -p "Enable CUPS Web Interface (http://localhost:631)? [y/N]: " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cupsctl WebInterface=yes
    echo "⚠️  CUPS accessible at http://localhost:631 (localhost only)"
fi
```

**6. Alias Safety - Interactive Only**
```bash
# .zshrc - Only override in interactive shells
if [[ $- == *i* ]]; then
    # Safe to override commands in interactive mode
    alias ls='eza'
    alias cat='bat'
    alias grep='rg'
fi
```

**7. Secrets in .gitignore**
```bash
# .gitignore
.env
.env.*
*.secret
*.vault
ssh/services.json
ssh/id_*
*.key
*.pem
.ssh-services.json
mounts.config  # May contain internal IPs
.DS_Store
```

**8. Shellcheck Integration**
```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.2
    hooks:
      - id: shellcheck
        args: [--severity=warning]

# Install pre-commit
brew install pre-commit
cd ~/dotfiles
pre-commit install
```

### Security Checklist

- [ ] No real IPs/usernames in repository
- [ ] SSH config permissions: 600
- [ ] Private keys permissions: 600
- [ ] Password after sleep: enabled on laptops
- [ ] CUPS web interface: documented + optional
- [ ] Remote downloads: verified checksums
- [ ] Secrets: stored in Bitwarden/Ansible Vault
- [ ] .gitignore: covers all sensitive files
- [ ] Shellcheck: runs on pre-commit
- [ ] Firewall: enabled by default

---

## 13. File Structure

### V2 Directory Layout

```
~/dotfiles/
├── install.sh                  # Main installation script
├── update.sh                   # Manual update trigger
├── manage.sh                   # Module management CLI
├── README.md                   # User documentation
├── SECURITY.md                 # Security considerations
├── CHANGELOG.md                # Version history
├── LICENSE                     # MIT License
├── .gitignore                  # Secrets exclusion
├── .editorconfig               # Editor standards
├── .pre-commit-config.yaml     # Shellcheck integration
│
├── lib/                        # Shared utilities
│   ├── colors.sh               # Color definitions
│   ├── logging.sh              # Print functions
│   ├── utils.sh                # Common functions
│   └── stow-helpers.sh         # Stow wrappers
│
├── profiles/                   # Device profiles
│   ├── desktop.sh              # Desktop settings
│   └── laptop.sh               # Laptop settings
│
├── modules/                    # Modular components
│   ├── system/                 # macOS system settings
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   └── settings/
│   │       ├── finder.sh
│   │       ├── keyboard.sh
│   │       ├── trackpad.sh
│   │       └── security.sh
│   │
│   ├── homebrew/               # Package manager
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── update.sh
│   │   └── Brewfile
│   │
│   ├── terminal/               # Shell configuration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── git/                    # Git configuration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── dock/                   # Dock management
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   └── dock-apps.txt
│   │
│   ├── mounts/                 # Network mounts
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   ├── mounts.config.example
│   │   └── README.md
│   │
│   ├── ssh/                    # SSH configuration
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── services.example.json
│   │   └── README.md
│   │
│   ├── printer/                # Printing setup
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── iterm2/                 # iTerm2 configuration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── alfred/                 # Alfred workflows
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── scanner/                # Scanner shortcuts
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── scan-shortcuts.sh
│   │
│   ├── development/            # Dev tools
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── docker-config.json
│   │
│   └── creative/               # Creative tools
│       ├── module.json
│       ├── install.sh
│       └── README.md
│
├── config/                     # Stow packages (symlinked)
│   ├── zsh/
│   │   ├── .zshrc
│   │   └── .zshenv
│   │
│   ├── git/
│   │   └── .gitconfig
│   │
│   ├── ssh/                    # Template only (Ansible manages real)
│   │   └── .ssh/
│   │       └── config.template
│   │
│   ├── iterm2/
│   │   └── Library/
│   │       └── Preferences/
│   │           └── com.googlecode.iterm2.plist
│   │
│   ├── alfred/
│   │   └── Library/
│   │       └── Application Support/
│   │           └── Alfred/
│   │
│   └── vscode/                 # Optional - only if not using GitHub Sync
│       └── .config/
│           └── Code/
│               └── User/
│                   └── settings.json
│
├── scripts/                    # Utility scripts
│   ├── bootstrap.sh            # First-run setup
│   ├── backup.sh               # Create backup before changes
│   ├── restore.sh              # Restore from backup
│   └── uninstall.sh            # Complete uninstallation
│
├── docs/                       # Documentation
│   ├── installation.md
│   ├── modules.md
│   ├── homelab-integration.md
│   ├── troubleshooting.md
│   └── migration-v1-to-v2.md
│
├── logs/                       # Installation logs (gitignored)
│   └── .gitkeep
│
└── backups/                    # Backups before changes (gitignored)
    └── .gitkeep
```

### Comparison: V1 vs V2

| V1 (Current) | V2 (Proposed) |
|--------------|---------------|
| `install.sh` (593 lines) | `install.sh` (200 lines) + modules |
| `.zshrc` copied to `~/.zshrc` | `config/zsh/.zshrc` symlinked |
| `Brewfile` in root | `modules/homebrew/Brewfile` |
| `ssh/ssh-setup.sh` (1012 lines) | `modules/ssh/` (Ansible-managed) |
| Hardcoded colors in every script | `lib/colors.sh` shared |
| No profile system | `profiles/desktop.sh`, `profiles/laptop.sh` |
| No module management | `manage.sh modules enable/disable` |
| Manual updates | Ansible nightly updates |

---

## 14. Tools & Technologies

### Core Technologies

**1. GNU Stow**
- **Purpose:** Symlink farm manager
- **Installation:** `brew install stow`
- **Usage:** `stow -d ~/dotfiles/config -t ~ zsh git`
- **Why:** Changes immediately reflected, no sync needed

**2. Ansible**
- **Purpose:** Homelab orchestration
- **Installation:** On Homelab server via `pip install ansible`
- **Usage:** `ansible-playbook playbooks/mac-update.yml`
- **Why:** Centralized updates, secrets management, nightly automation

**3. Bitwarden CLI**
- **Purpose:** Secrets storage and retrieval
- **Installation:** `brew install bitwarden-cli`
- **Usage:** `bw get item "ssh-key" | jq -r '.notes'`
- **Why:** Already in use, secure, accessible, integrates with Ansible

**4. Homebrew**
- **Purpose:** Package management
- **Installation:** Automatic in install.sh
- **Usage:** `brew bundle install`
- **Why:** Standard macOS package manager

**5. Oh My Zsh**
- **Purpose:** Zsh framework
- **Installation:** Automatic in terminal module
- **Usage:** Plugins and themes
- **Why:** Rich ecosystem, good defaults

**6. dockutil**
- **Purpose:** Dock management CLI
- **Installation:** `brew install dockutil`
- **Usage:** `dockutil --add /Applications/VSCode.app`
- **Why:** Automate Dock configuration

**7. mas**
- **Purpose:** Mac App Store CLI
- **Installation:** `brew install mas`
- **Usage:** `mas install 497799835`  # Xcode
- **Why:** Automate MAS app installation

### Development Tools

**8. shellcheck**
- **Purpose:** Shell script linting
- **Installation:** `brew install shellcheck`
- **Usage:** `shellcheck install.sh`
- **Why:** Catch bugs before they happen

**9. shfmt**
- **Purpose:** Shell script formatting
- **Installation:** `brew install shfmt`
- **Usage:** `shfmt -w -i 4 install.sh`
- **Why:** Consistent code style

**10. pre-commit**
- **Purpose:** Git pre-commit hooks
- **Installation:** `brew install pre-commit`
- **Usage:** `pre-commit install`
- **Why:** Automatic linting on commit

**11. jq**
- **Purpose:** JSON processing
- **Installation:** `brew install jq`
- **Usage:** Parse module.json files
- **Why:** Module metadata parsing

### Optional Tools

**12. chezmoi** (Alternative to Stow)
- **Purpose:** Dotfile manager with templating
- **Why NOT using:** Stow is simpler, no templating needed
- **Could use:** If complex per-machine templating required

**13. yadm** (Alternative to Stow)
- **Purpose:** Git-based dotfile manager
- **Why NOT using:** Less flexible than Stow + Ansible
- **Could use:** If simpler setup preferred (no Ansible)

**14. Nix / nix-darwin** (Advanced Alternative)
- **Purpose:** Declarative system configuration
- **Why NOT using:** Steep learning curve, overkill for 3 Macs
- **Could use:** If scaling to 10+ machines

---

## 15. Migration Path

### V1 → V2 Migration Strategy

**Phase 1: Backup V1**
```bash
cd ~/Dev/dotfiles
git checkout -b v1-backup
git push origin v1-backup

# Create manual backup
cp -r ~/Dev/dotfiles ~/dotfiles-v1-backup-$(date +%Y%m%d)
```

**Phase 2: Restructure Repository**
```bash
# Create V2 branch
git checkout -b v2-development

# Create new directory structure
mkdir -p lib profiles modules config scripts docs logs backups

# Move existing files to modules
mkdir -p modules/homebrew
mv Brewfile modules/homebrew/

mkdir -p modules/system
mv macos-settings.sh modules/system/install.sh

mkdir -p modules/dock
mv dock-setup.sh modules/dock/install.sh
mv dock-apps.txt modules/dock/

mkdir -p modules/mounts
mv mount-setup.sh modules/mounts/install.sh
mv mounts.config.example modules/mounts/

# Move dotfiles to config/ for Stow
mkdir -p config/zsh config/git
mv .zshrc config/zsh/
mv .gitconfig config/git/

# Create shared libraries
cat > lib/colors.sh << 'EOF'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
EOF

cat > lib/logging.sh << 'EOF'
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
EOF

# Commit restructure
git add .
git commit -m "Restructure for V2 architecture"
```

**Phase 3: Implement Core Components**
```bash
# Create new install.sh with modular architecture
# Create manage.sh for module management
# Create module.json for each module
# Update README.md with V2 documentation

git add .
git commit -m "Implement V2 core components"
```

**Phase 4: Test on Single Mac**
```bash
# On MacBook Pro (test machine)
cd ~/dotfiles
git fetch
git checkout v2-development

# Backup current configs
./scripts/backup.sh

# Run V2 installer
./install.sh

# Test all modules
./manage.sh modules status
./manage.sh modules list

# Verify symlinks
ls -la ~ | grep "\->"

# Test updates
./update.sh

# If issues, rollback
./scripts/restore.sh
```

**Phase 5: Ansible Integration**
```bash
# On Homelab server
cd ~/homelab/ansible

# Create playbooks for V2
mkdir -p playbooks/dotfiles-v2
# Implement mac-update.yml, mac-secrets.yml, mac-setup.yml

# Test on single Mac
ansible-playbook playbooks/mac-update.yml --limit macbook-pro --check
ansible-playbook playbooks/mac-update.yml --limit macbook-pro

# Verify on Mac
ssh macbook-pro
cd ~/dotfiles
git status  # Should show "Your branch is up to date"
```

**Phase 6: Rollout to All Macs**
```bash
# Merge V2 to main
cd ~/dotfiles
git checkout main
git merge v2-development
git push origin main

# Ansible rollout to all Macs
cd ~/homelab/ansible
ansible-playbook playbooks/mac-setup.yml --limit macs

# Verify on each Mac
ansible macs -m shell -a "cd ~/dotfiles && git status"
```

**Phase 7: Enable Nightly Updates**
```bash
# On Homelab server
crontab -e
# Add:
0 3 * * * cd ~/homelab/ansible && ansible-playbook playbooks/mac-update.yml >> /var/log/ansible-mac-updates.log 2>&1

# Monitor first run
tail -f /var/log/ansible-mac-updates.log
```

### Rollback Plan

If V2 causes issues:

```bash
# On affected Mac
cd ~/dotfiles
git checkout v1-backup

# Restore from backup
./scripts/restore.sh

# Or manual restoration
cp -r ~/dotfiles-v1-backup-YYYYMMDD/* ~/

# Re-run V1 installer
./install.sh
```

---

## 16. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)

**Week 1: Repository Restructure**
- [ ] Create V2 branch
- [ ] Implement new directory structure
- [ ] Move files to modules/
- [ ] Create shared lib/ files (colors, logging, utils)
- [ ] Create profile system (desktop.sh, laptop.sh)
- [ ] Update .gitignore for secrets
- [ ] Remove sensitive data from repository
- [ ] Create example templates (services.example.json, mounts.config.example)

**Week 2: Core Scripts**
- [ ] Rewrite install.sh with modular architecture
- [ ] Create manage.sh for module management
- [ ] Implement module.json schema
- [ ] Create module install/uninstall scripts
- [ ] Implement GNU Stow integration
- [ ] Add shellcheck to pre-commit hooks
- [ ] Write unit tests for core functions
- [ ] Update README.md with V2 documentation

### Phase 2: Modules (Week 3-4)

**Week 3: Essential Modules**
- [ ] Module: system (macOS settings, profile-aware)
- [ ] Module: homebrew (Brewfile, auto-updates)
- [ ] Module: terminal (Zsh, Oh My Zsh, stow-managed)
- [ ] Module: git (config with placeholders, stow-managed)
- [ ] Fix security issues (permissions, password after sleep, CUPS)
- [ ] Test modules individually
- [ ] Test modules in combination

**Week 4: Optional Modules**
- [ ] Module: dock (dockutil, apps.txt)
- [ ] Module: mounts (autofs, config-driven)
- [ ] Module: ssh (template only, Ansible-managed)
- [ ] Module: iterm2 (config via stow)
- [ ] Module: alfred (preferences via stow)
- [ ] Module: printer (CUPS configuration)
- [ ] Module: scanner (shortcuts)
- [ ] Module: development (Docker, etc.)
- [ ] Test optional modules

### Phase 3: Homelab Integration (Week 5)

**Ansible Playbooks**
- [ ] Create Ansible inventory (hosts.yml)
- [ ] Create roles: dotfiles, secrets, updates
- [ ] Implement mac-update.yml (nightly updates)
- [ ] Implement mac-setup.yml (initial installation)
- [ ] Implement mac-secrets.yml (SSH keys, certificates)
- [ ] Set up Bitwarden CLI on Homelab server
- [ ] Migrate SSH keys to Bitwarden
- [ ] Create SSH config template (Jinja2)
- [ ] Test Ansible playbooks on single Mac
- [ ] Set up cron job for nightly updates

**Secrets Management**
- [ ] Install Bitwarden CLI on Homelab server
- [ ] Store SSH keys in Bitwarden as Secure Notes
- [ ] Store API tokens (GitHub, etc.)
- [ ] Create Ansible tasks to retrieve secrets
- [ ] Test secrets distribution to Macs
- [ ] Document secrets management process

### Phase 4: Testing & Documentation (Week 6)

**Testing**
- [ ] Test V2 on MacBook Pro (laptop profile)
- [ ] Test V2 on Mac Mini (desktop profile)
- [ ] Test module enable/disable
- [ ] Test manual updates (./update.sh)
- [ ] Test Ansible-triggered updates
- [ ] Test fresh Mac installation (VM or spare device)
- [ ] Test rollback to V1
- [ ] Fix all discovered bugs

**Documentation**
- [ ] Update README.md with V2 architecture
- [ ] Create SECURITY.md with considerations
- [ ] Create CHANGELOG.md with version history
- [ ] Write docs/installation.md
- [ ] Write docs/modules.md (usage guide)
- [ ] Write docs/homelab-integration.md
- [ ] Write docs/troubleshooting.md
- [ ] Write docs/migration-v1-to-v2.md
- [ ] Record demo video (optional)

### Phase 5: Rollout (Week 7)

**Production Deployment**
- [ ] Merge v2-development to main
- [ ] Tag release: v2.0.0
- [ ] Backup all Macs before migration
- [ ] Run install.sh on MacBook Pro
- [ ] Run install.sh on Mac Mini
- [ ] Run install.sh on MacBook Air (server)
- [ ] Enable Ansible nightly updates
- [ ] Monitor first week of nightly updates
- [ ] Verify all modules working correctly
- [ ] Verify secrets distribution
- [ ] Verify symlinks maintained after updates

### Phase 6: Maintenance (Ongoing)

**Regular Tasks**
- [ ] Weekly: Review Ansible update logs
- [ ] Monthly: Rotate SSH keys (if policy requires)
- [ ] Monthly: Review and clean Brewfile
- [ ] Quarterly: Review module usage, remove unused
- [ ] Quarterly: Update documentation
- [ ] Yearly: Major macOS updates (manual)

**Continuous Improvement**
- [ ] Add more modules as needed
- [ ] Refine Ansible playbooks
- [ ] Optimize update performance
- [ ] Expand test coverage
- [ ] Community feedback integration (if open-source)

---

## 17. Summary

### Key Changes from V1 to V2

| Aspect | V1 (Current) | V2 (Proposed) |
|--------|-------------|---------------|
| **Config Management** | Copy files on install | GNU Stow symlinks |
| **Updates** | Manual `./update.sh` | Ansible nightly automation |
| **Secrets** | Committed to repo | Bitwarden CLI / Ansible Vault |
| **SSH** | Local ssh-wunderbar | Homelab Ansible distribution |
| **Modularity** | Monolithic scripts | Modular with CLI management |
| **Profiles** | One-size-fits-all | Desktop vs Laptop profiles |
| **Security** | Issues present | Hardened permissions & practices |
| **Code Quality** | Duplication, no linting | Shared libs, shellcheck |
| **Documentation** | Drifted from reality | Accurate, comprehensive |
| **Scalability** | 3 Macs, manual sync | N Macs, automatic sync |

### Benefits of V2

**For You:**
✅ **Less Manual Work** - Edit once in Git, changes propagate automatically
✅ **Consistent Macs** - All machines identical, managed centrally
✅ **Homelab Integration** - Leverages your existing Ansible infrastructure
✅ **Security** - No secrets in public repo, proper permissions
✅ **Flexibility** - Enable/disable modules per machine
✅ **Maintainability** - Clean code, no duplication, easy to extend
✅ **Peace of Mind** - Nightly security updates, backups, audit trail

**For Your Workflow:**
✅ **New Mac Setup** - 30 minutes instead of hours
✅ **Config Changes** - Edit file, commit, done (no sync needed)
✅ **Updates** - Automatic every night (except major macOS)
✅ **Disaster Recovery** - Git clone + install.sh = restored Mac
✅ **Experimentation** - Test changes on one Mac, rollout to all

### Next Steps

**Immediate Actions (This Week):**
1. ✅ Read this entire roadmap
2. [ ] Ask clarifying questions
3. [ ] Decide on secrets management (Bitwarden CLI recommended)
4. [ ] Create V2 branch: `git checkout -b v2-development`
5. [ ] Start Phase 1: Repository restructure

**Short-Term (Next 2 Weeks):**
1. [ ] Implement new directory structure
2. [ ] Create shared lib/ files
3. [ ] Implement profile system
4. [ ] Remove sensitive data from repo

**Medium-Term (Next 4 Weeks):**
1. [ ] Rewrite install.sh with modular architecture
2. [ ] Implement all core modules
3. [ ] Add GNU Stow integration
4. [ ] Test on single Mac

**Long-Term (Next 6 Weeks):**
1. [ ] Create Ansible playbooks
2. [ ] Set up Bitwarden CLI on Homelab
3. [ ] Enable nightly updates
4. [ ] Rollout to all Macs

### Estimated Timeline

**Conservative:** 6-8 weeks (1-2 hours per day)
**Aggressive:** 4 weeks (3-4 hours per day)
**Realistic:** 6 weeks with 2 hours per day average

### Success Metrics

V2 is successful when:
- ✅ All 3 Macs running V2 dotfiles
- ✅ Ansible nightly updates functioning
- ✅ No secrets in GitHub repository
- ✅ GNU Stow managing all dotfiles
- ✅ Profile system working (Desktop vs Laptop)
- ✅ All modules tested and documented
- ✅ Fresh Mac setup completes in under 30 minutes
- ✅ You can edit any config file and it's immediately active
- ✅ Changes propagate to all Macs within 24 hours
- ✅ No manual intervention needed for 95% of updates

### Risk Mitigation

**Risks:**
1. **Breaking existing setup** → Mitigation: V2 branch, backups, rollback plan
2. **Ansible complexity** → Mitigation: Start with simple playbooks, iterate
3. **Stow conflicts** → Mitigation: Backup existing configs before stowing
4. **Time investment** → Mitigation: Modular approach, work in phases
5. **Learning curve** → Mitigation: Extensive documentation, test on one Mac first

### Final Thoughts

V1 served you well - it's functional and comprehensive. But it's reached the limit of manual management for multiple machines. V2 takes the strong foundation of V1 (modularity, comprehensiveness, good UX) and adds:

- **Automation** via Ansible
- **Centralization** via Homelab
- **Symlinks** via GNU Stow
- **Security** via proper secrets management
- **Profiles** for device-specific settings

The investment in V2 will pay off within weeks - every config change propagates automatically, security updates happen nightly, and new Macs are ready in 30 minutes instead of a full day of manual setup.

**Your V1 dotfiles score a B-. V2 will be an A.**

---

**Document Version:** 1.0.0
**Last Updated:** 2025-01-07
**Feedback:** Open issues at https://github.com/dbraendle/dotfiles/issues
**Questions:** Review docs/ or ask in discussions

---

## Appendix: Quick Reference

### Useful Commands

```bash
# Installation
./install.sh                              # Interactive installation
./install.sh --profile laptop             # Force laptop profile
./install.sh --modules core,dock,iterm2   # Select specific modules

# Module Management
./manage.sh modules list                  # List all modules
./manage.sh modules status                # Show active modules
./manage.sh modules enable dock           # Enable a module
./manage.sh modules disable dock          # Disable a module

# Profile Management
./manage.sh profile info                  # Show current profile
./manage.sh profile set laptop            # Change to laptop profile
./manage.sh profile set desktop           # Change to desktop profile

# Updates
./update.sh                               # Manual update
./update.sh --force                       # Force re-stow all modules

# Stow Operations
cd ~/dotfiles
stow -t ~ zsh git                         # Stow specific packages
stow -R -t ~ zsh                          # Restow (pick up new files)
stow -D -t ~ zsh                          # Unstow (remove symlinks)
stow -n -v -t ~ zsh                       # Dry run (see what would happen)

# Ansible (on Homelab server)
ansible-playbook playbooks/mac-update.yml              # Update all Macs
ansible-playbook playbooks/mac-update.yml --limit macbook-pro  # Update one Mac
ansible-playbook playbooks/mac-secrets.yml             # Deploy secrets
ansible macs -m shell -a "cd ~/dotfiles && git status" # Check Git status on all Macs

# Backup & Restore
./scripts/backup.sh                       # Create backup
./scripts/restore.sh                      # Restore from backup
./scripts/uninstall.sh                    # Complete uninstallation

# Debugging
./install.sh --debug                      # Verbose output
./manage.sh modules status --verbose      # Detailed module info
cat ~/.dotfiles-modules                   # See active modules
cat ~/.dotfiles-profile                   # See current profile
ls -la ~ | grep "\->"                     # Verify symlinks
```

### File Locations

```
~/dotfiles/                    # Dotfiles repository
~/.zshrc -> ~/dotfiles/config/zsh/.zshrc   # Symlinked zshrc
~/.gitconfig -> ~/dotfiles/config/git/.gitconfig   # Symlinked gitconfig
~/.dotfiles-modules            # List of active modules
~/.dotfiles-profile            # Current profile (desktop/laptop)
~/.dotfiles-update.log         # Ansible update history
~/dotfiles/logs/               # Installation logs
~/dotfiles/backups/            # Config backups
```

### Troubleshooting

**Problem: Stow refuses to create symlink**
**Solution:** Existing file at target location. Backup and remove first.
```bash
mv ~/.zshrc ~/.zshrc.backup
stow -t ~ zsh
```

**Problem: Ansible can't connect to Mac**
**Solution:** Ensure SSH access, check firewall.
```bash
ssh mac-mini  # Test SSH connection
ssh-copy-id mac-mini  # Copy SSH key if needed
```

**Problem: Module won't enable**
**Solution:** Check dependencies.
```bash
./manage.sh modules info dock  # See module requirements
cat modules/dock/module.json   # Check dependencies array
```

**Problem: Changes not propagating to other Macs**
**Solution:** Check Ansible cron job, manually trigger update.
```bash
# On Homelab server
ansible-playbook playbooks/mac-update.yml --limit macbook-pro
tail -f /var/log/ansible-mac-updates.log
```

**Problem: Symlink broken after macOS update**
**Solution:** Restow all modules.
```bash
cd ~/dotfiles
while read module; do stow -R -t ~ "$module"; done < ~/.dotfiles-modules
```

### Resources

- GNU Stow Manual: https://www.gnu.org/software/stow/manual/
- Ansible Documentation: https://docs.ansible.com/
- Bitwarden CLI: https://bitwarden.com/help/cli/
- Homebrew: https://brew.sh/
- Oh My Zsh: https://ohmyz.sh/
- ShellCheck: https://www.shellcheck.net/

---

**End of Roadmap**
