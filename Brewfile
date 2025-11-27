# Brewfile - Developer Essentials + Utilities
# Usage: brew bundle install --file=modules/homebrew/Brewfile
#
# Profile Support:
#   This Brewfile supports desktop/laptop profiles via DOTFILES_PROFILE env var
#   Set by install.sh automatically based on hardware detection
#
# Uninstall commands:
# brew uninstall <package>                    # Basic uninstall (brew packages)
# brew uninstall --force <package>           # Force removal (brew packages)
# brew uninstall --cask <package>            # Basic cask uninstall
# brew uninstall --cask --zap <package>      # Complete removal with all files (recommended)
# brew uninstall --cask --force <package>    # Force removal if normal fails
# brew uninstall --cask --zap --force <package>  # Both (if needed)
# mas uninstall <app-id>                     # Mac App Store apps

# Get profile from environment (set by install.sh)
profile = ENV['DOTFILES_PROFILE'] || 'desktop'

#######################################
# Essential Command Line Tools
#######################################
brew "git"                      # Version control (overrides macOS system git)
brew "gh"                       # GitHub CLI for repository management
brew "stow"                     # Symlink manager for dotfiles
brew "curl"                     # HTTP requests
brew "wget"                     # Downloads
brew "jq"                       # JSON processor
brew "tree"                     # Directory structure visualization
brew "node"                     # Node.js for JavaScript development
brew "ffmpeg"                   # Video processing
brew "nmap"                     # Network scanner
brew "telnet"                   # Telnet client
brew "iperf3"                   # Network performance testing

#######################################
# AI Tools & Assistants
#######################################
cask "claude"                   # Anthropic Claude Desktop (full version)
cask "claude-code"              # Anthropic Claude Code CLI (native binary)
cask "chatgpt"                  # OpenAI ChatGPT Desktop App (official)
cask "chatgpt-atlas"            # OpenAI ChatGPT Atlas Browser (official)
cask "codex"                    # OpenAI Codex CLI coding agent (official)

#######################################
# Better CLI Tools
#######################################
brew "ripgrep"                  # Fast text search (rg)
brew "bat"                      # cat with syntax highlighting
brew "eza"                      # Better ls with colors

#######################################
# Mac App Store CLI
#######################################
brew "mas"                      # Command line interface for Mac App Store

#######################################
# macOS Dock Management
#######################################
brew "dockutil"                 # Manage Dock items from command line

#######################################
# Terminal Extensions
#######################################
brew "zsh-autosuggestions"      # Tab completion
brew "zsh-syntax-highlighting"  # Syntax colors in terminal

#######################################
# Security & Encryption
#######################################
# GPG Suite Beta (2024.1b3) with MailKit - install manually from gpgtools.org
# Homebrew version is outdated

#######################################
# Essential GUI Apps (All Profiles)
#######################################
cask "visual-studio-code"       # Code editor
cask "sublime-text"             # Lightweight code editor
cask "google-chrome"            # Browser with dev tools
cask "iterm2"                   # Better terminal
cask "docker-desktop"           # Docker Desktop (includes CLI + GUI)
cask "transmit"                 # File transfer client
cask "hiddenbar"                # Hide menu bar icons
cask "syncthing-app"            # File synchronization tool

#######################################
# Creative & Design
#######################################
# Adobe Creative Cloud removed - too heavy for automated installation
# Install manually if needed: brew install --cask adobe-creative-cloud
cask "affinity"                 # Free all-in-one design app (Photo, Designer, Publisher by Canva)
cask "figma"                    # Collaborative design tool

#######################################
# Productivity & Communication
#######################################
cask "stats"                    # Free system monitoring (alternative to iStat Menus)

#######################################
# Media & Entertainment
#######################################
cask "spotify"                  # Music streaming
cask "vlc"                      # Media player
cask "downie"                   # Video downloader

#######################################
# Scanner Software
#######################################
# No scanner software - ScanSnap iX500 discontinued for macOS Sequoia
# Alternative: Use phone scanning apps or buy new scanner

#######################################
# Utilities (All Profiles)
#######################################
cask "the-unarchiver"           # Archive tool (.zip, .rar, etc)
cask "appcleaner"               # App uninstaller
cask "knockknock"               # See what's persistently installed on your Mac (Malware detection)

#######################################
# Optional Apps (Uncomment to install)
#######################################
# cask "firefox"                # Alternative browser
# cask "slack"                  # Team communication
# cask "discord"                # Gaming/community chat
# cask "notion"                 # Notes and organization
# cask "figma"                  # Design tool
# cask "1password"              # Password manager (paid)
# cask "rectangle"              # Window management
# cask "cleanmymac"             # System cleaner (paid)
# cask "grok"                   # Grok Desktop (full version)
# cask "mark-text"              # Markdown editor
# cask "alfred"                 # Productivity app launcher
# cask "bitwarden"              # Password manager

#######################################
# Mac App Store Apps (All Profiles)
#######################################
# Note: You need to be logged into the App Store for these to work
# Use 'mas search "app name"' to find App IDs

# Productivity & Office
mas "Pages", id: 409201541       # Apple's word processor
mas "Numbers", id: 409203825     # Apple's spreadsheet app
mas "Keynote", id: 409183694     # Apple's presentation app
mas "Things 3", id: 904280696    # Task management app

# Password Management
mas "Strongbox", id: 897283731   # KeePass password manager
mas "Bitwarden", id: 1352778147  # Password manager

# Utilities
mas "DaisyDisk", id: 411643860   # Disk space analyzer

# Safari Extensions & Ad Blockers
mas "1Blocker", id: 1365531024        # Safari ad blocker with customization
mas "AdGuard for Safari", id: 1440147259  # Premium ad blocker, best performance
mas "Hush", id: 1544743900            # Safari extension to block cookie banners

#######################################
# Mac App Store - Optional
#######################################
# mas "MindSpace", id: 1585502524  # Mind mapping & diagrams (one-time purchase alternative to MindNode)
# mas "MindNode", id: 6446116532  # Mind mapping tool (for converting old files)
# mas "Wipr 2", id: 1662217862    # Minimalist Safari ad blocker

#######################################
# Desktop Only Apps
#######################################
if profile == 'desktop'
  cask "utm"                      # Virtual machine manager (resource intensive)
  cask "ankerwork"                # Video conferencing (desktop setup)
  # mas "Xcode", id: 497799835    # Apple's development environment (15+ GB)
  cask "tunnelblick"              # OpenVPN client (for travel/mobile)
  cask "balenaetcher"             # OS image flasher (USB workflow)
  cask "audiobook-builder"        # Audiobook creation

end

#######################################
# Laptop Only Apps
#######################################
if profile == 'laptop'

end

#######################################
# Notes on App Store Apps
#######################################
# UGREEN NAS - iOS app only, not available for macOS
# Claude by Anthropic - App Store version is restricted, use cask version above
# 1Password 7 - Consider using 1password cask or newer version
# Magnet - Window management (alternative: Rectangle is free)
# Pixelmator Pro - Image editor
