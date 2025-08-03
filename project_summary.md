# Mac dotfiles Setup Project - Overview

## 🎯 Project Goal
Create a comprehensive, automated Mac setup for developers/designers that can be run on a fresh macOS installation to get a fully configured development environment.

## 📁 Current File Structure
```
~/Dev/dotfiles/
├── install.sh              # Main installer script
├── Brewfile                # Homebrew packages (system tools + GUI apps)
├── npm-install.sh           # NPM global packages
├── .zshrc                  # Terminal configuration
├── .gitconfig              # Git configuration template
└── macos-settings.sh       # macOS system preferences
```

## 🔄 Installation Flow
The `install.sh` script runs these steps:

1. **Xcode Command Line Tools** - Required for development tools
2. **Homebrew** - Package manager for macOS
3. **Apps Installation** - From Brewfile (VS Code, Chrome, git, etc.)
4. **Terminal Setup** - Oh My Zsh + custom .zshrc
5. **Git Configuration** - Asks for name/email, installs aliases
6. **NPM Global Packages** - Claude Code, TypeScript, Prettier
7. **macOS System Settings** - Finder, keyboard, display preferences

## 🛠️ Key Components

### Brewfile Contents
- **CLI Tools**: git, curl, wget, jq, tree, ripgrep, bat, eza
- **Terminal**: zsh-autosuggestions, zsh-syntax-highlighting  
- **GUI Apps**: visual-studio-code, google-chrome, iterm2, sf-symbols
- **Utilities**: the-unarchiver, appcleaner

### NPM Packages
- `@anthropic-ai/claude-code` - AI coding assistant
- `typescript` - JavaScript with types
- `prettier` - Code formatter

### macOS Settings
- **Finder**: All bars visible, list view, show all extensions
- **Screenshots**: Custom folder, PNG format, no shadow
- **Keyboard**: Fast repeat, no accent popups
- **Trackpad**: Tap-to-click enabled

## ⚙️ Current Setup Philosophy
- **Homebrew-first** for system tools and GUI apps
- **NPM** for JavaScript/Node.js specific tools
- **No personal data** in templates (asks interactively)
- **Modular design** - each component can be run separately
- **Safe re-runs** - script checks existing installations

## 🎯 Target User
- Web developer who also does design/graphics
- Wants automated setup for new Mac or clean installs
- Uses VS Code, Chrome, Terminal, Git workflow
- Prefers Homebrew over other package managers

## 🐛 Known Issues
- NPM script uses `exit 1` instead of `return 1` (causes main script to stop)
- Node.js must be installed before NPM packages step
- Some Finder sidebar settings can't be scripted (need manual setup)

## 🚀 Usage
```bash
cd ~/Dev/dotfiles
chmod +x install.sh
./install.sh
```

Each step is optional and can be skipped interactively.

## 💡 Design Decisions Made
- **Git via Homebrew** instead of system git (for latest version)
- **Claude Code via NPM** instead of Homebrew cask (official recommendation)
- **No backup creation** for dotfiles (assumes fresh install)
- **robbyrussell theme** for Zsh (clean, no special fonts needed)
- **main branch** default for git (modern standard)