# 🚀 Ultimate Mac Development Setup

**Transform any Mac into a fully configured development powerhouse with modern CLI tools and zero-friction automation.**

## 🎯 Key Principles

### **Modular by Design**
Every script works standalone or orchestrated together. Mix, match, and customize as needed.

### **Smart Automation** 
JSON-driven configuration with intelligent defaults. One command setup, zero manual configuration.

### **Modern CLI Patterns**
Built like the tools you love - Docker, Git, npm. Consistent, predictable, powerful.

### **Zero-Friction Experience**
From fresh Mac to fully configured development environment in minutes, not hours.

---

## 🛠️ Core Scripts

### 🔑 SSH Manager (Ultimate Edition)
**The most powerful SSH setup tool you'll ever use.**

```bash
# Interactive menu with all your services
./ssh-setup.sh

# Setup from configuration
./ssh-setup.sh github                    # GitHub SSH
./ssh-setup.sh pihole                    # Pi-hole server

# Non-interactive setup
./ssh-setup.sh nas 192.168.1.50 admin 22

# Service management
./ssh-setup.sh --add-service work 10.0.0.1 root 2222 "Work server"
./ssh-setup.sh --list                    # Show all services
./ssh-setup.sh --setup-all               # Configure everything
./ssh-setup.sh --rotate-keys pihole      # Generate new keys + cleanup old

# Advanced features
./ssh-setup.sh --remove-service old-server
./ssh-setup.sh --help                    # Full documentation
```

**Features:**
- **JSON-driven configuration** - Persistent service definitions
- **Smart key management** - Reuse existing or generate new keys
- **Automatic deployment** - `ssh-copy-id` integration with testing
- **Service discovery** - Never forget what servers you have
- **Key rotation** - Security best practices made easy
- **Batch operations** - Setup entire infrastructure at once

**Perfect for:**
- Fresh Mac setup - restore all SSH access instantly
- Team onboarding - consistent SSH configuration  
- Infrastructure management - systematic server access
- Security maintenance - regular key rotation

### 📦 Package Managers

```bash
# Install all applications
./brew-install.sh                        # GUI apps + CLI tools

# Homebrew only operations
brew bundle install                      # From Brewfile
brew bundle cleanup                      # Remove unused apps
```

### 🔄 System Maintenance

```bash
# Check everything for updates
./update.sh

# Targeted updates
./update.sh --brew-only                  # Just Homebrew packages
./update.sh --npm-only                   # Just npm packages
./update.sh --system-only                # Just macOS updates
```

### ⚙️ System Configuration

```bash
# Apply all macOS optimizations
source macos-settings.sh

# Individual configurations
defaults write com.apple.finder ShowPathbar -bool true
```

---

## 🎯 Orchestration

### Master Installer
```bash
# Interactive setup - choose what you want
./install.sh

# Headless automation - install everything
./install.sh --headless --yes-to-all

# Partial setups
./install.sh --skip-apps                 # Skip application installation
./install.sh --ssh-only                  # Only configure SSH
```

### Fresh Mac Workflow
```bash
# 1. Clone repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# 2. One command setup
./install.sh

# 3. Restore SSH access to entire infrastructure  
./ssh-setup.sh --setup-all
```

### Team/Corporate Setup
```bash
# 1. Fork and customize services.json with company servers
# 2. Team members clone and run
./install.sh && ./ssh-setup.sh --setup-all
# 3. Entire team has identical, working development environment
```

---

## 🏗️ Architecture

### File Structure
```
dotfiles/
├── install.sh              # Master orchestrator
├── update.sh                # System update manager  
├── brew-install.sh          # Standalone app installer
├── macos-settings.sh        # System configuration
├── Brewfile                 # Package definitions
├── .zshrc                   # Terminal configuration
├── .editorconfig           # Code editor settings
└── ssh/
    ├── ssh-setup.sh         # Ultimate SSH manager
    ├── services.json        # Service definitions
    └── config.github        # GitHub SSH template
```

### Configuration Files
- **`Brewfile`** - Declarative package management
- **`services.json`** - SSH service definitions
- **`.zshrc`** - Terminal aliases and functions
- **`.editorconfig`** - Consistent coding standards

### Smart Defaults
- **Homebrew-first** - Consistent package management
- **ED25519 keys** - Modern cryptography
- **JSON configuration** - Structured, portable settings
- **Backup-aware** - Never lose existing configurations

---

## 🎨 What Gets Installed

### Development Ecosystem
**CLI Tools:** `git`, `gh`, `node`, `npm`, `jq`, `ripgrep`, `bat`, `eza`  
**Editors:** VS Code, Sublime Text  
**Containers:** Docker Desktop  
**AI Tools:** Claude Desktop, Claude Code CLI

### Creative & Productivity  
**Design:** Adobe Creative Cloud  
**Media:** Spotify, VLC, Downie  
**Productivity:** Things 3, MindSpace  
**Communication:** AnkerWork

### System & Security
**Monitoring:** Stats (system monitor)  
**Security:** 1Blocker, AdGuard for Safari, Hush  
**Utilities:** The Unarchiver, AppCleaner

### Mac App Store Integration
Automated installation of App Store apps with `mas` CLI tool. Pre-configured with productivity essentials.

---

## 🚀 Advanced Usage

### SSH Service Management
```bash
# Add new infrastructure
./ssh-setup.sh --add-service prod-db 10.0.1.100 postgres 5432

# Batch server setup
./ssh-setup.sh --add-service web1 web1.company.com deploy 22
./ssh-setup.sh --add-service web2 web2.company.com deploy 22  
./ssh-setup.sh --setup-all

# Security maintenance
./ssh-setup.sh --rotate-keys prod-db    # New keys + old key cleanup
```

### Custom Configurations
```bash
# Extend package list
echo 'brew "your-tool"' >> Brewfile
echo 'cask "your-app"' >> Brewfile

# Add custom servers to services.json
{
  "services": {
    "your-server": {
      "hostname": "your-host.com",
      "user": "your-user", 
      "port": 22,
      "description": "Your custom server"
    }
  }
}
```

### Automation & CI/CD
```bash
# Non-interactive installation
export HOMEBREW_NO_INSTALL_CLEANUP=1
./install.sh --headless --skip-interactive

# SSH setup in pipelines
./ssh-setup.sh production prod.company.com deploy 22
```

---

## 🛠️ Troubleshooting & Maintenance

### Common Issues
```bash
# Missing dependencies
brew doctor                              # Check Homebrew health
./ssh-setup.sh --help                   # SSH manager documentation

# Permission issues  
sudo xcodebuild -license accept         # Accept Xcode license
chmod +x *.sh                          # Fix script permissions

# Update everything
./update.sh                             # System-wide updates
git pull && ./install.sh               # Update dotfiles
```

### Safe Operations
- **Automatic backups** - SSH configs backed up before changes
- **Non-destructive** - Existing configurations preserved
- **Rollback capable** - Git history for all changes  
- **Validation** - Scripts check dependencies and permissions

### Monitoring & Health
```bash
./ssh-setup.sh --list                   # Review SSH configuration
brew bundle check                       # Verify installed packages
./update.sh --check-only                # Check for updates without installing
```

---

## 🤝 Philosophy

### **"Make It Simple"**
Complex infrastructure management shouldn't require complex tools. One command should do what used to take hours.

### **Configuration as Code** 
Your development environment should be versioned, shareable, and reproducible. No more "it works on my machine."

### **Modern CLI Design**
Built with patterns from tools you already know and love. Consistent, discoverable, powerful.

### **Team-Ready**
Works for individuals and scales to entire engineering teams. Same configuration, same results, everywhere.

---

## 🎉 Quick Start

```bash
# Get started in 30 seconds
git clone https://github.com/your-username/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**That's it.** Your Mac is now a development powerhouse with enterprise-grade SSH management, modern tooling, and zero-friction workflows.

---

**Built with ❤️ for developers who value their time.**

*Transform your Mac. Transform your workflow. Transform your team.*