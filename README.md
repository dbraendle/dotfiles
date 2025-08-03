# 🚀 Mac Dotfiles & Development Setup

Automated macOS setup for developers and designers. Transform a fresh Mac into a fully configured development environment with a single command.

## ✨ Features

### 🛠️ Development Tools
- **Git** (latest version via Homebrew)
- **Node.js** with npm for JavaScript development
- **TypeScript** compiler
- **Prettier** code formatter
- **Claude Code** AI coding assistant

### 📱 Essential Apps
- **Visual Studio Code** - Primary code editor
- **Google Chrome** - Browser with developer tools
- **iTerm2** - Enhanced terminal
- **SF Symbols** - Apple's icon library

### ⚡ CLI Enhancements
- **ripgrep** (`rg`) - Blazing fast text search
- **bat** - `cat` with syntax highlighting
- **eza** - Modern `ls` replacement with colors
- **jq** - JSON processor
- **tree** - Directory visualization

### 🖥️ Terminal Configuration
- **Oh My Zsh** with robbyrussell theme
- **zsh-autosuggestions** for command completion
- **zsh-syntax-highlighting** for syntax colors
- Custom `.zshrc` with aliases and optimizations

### ⚙️ macOS System Optimizations
- **Finder**: All bars visible, list view, clean desktop
- **Screenshots**: Custom folder (`~/Desktop/Screenshots`), PNG format
- **Keyboard**: Fast key repeat for coding
- **Trackpad**: Tap-to-click enabled
- **Performance**: Faster animations, optimized energy settings
- **Security**: Firewall enabled

## 🎯 Quick Start

```bash
# Clone this repository
git clone https://github.com/dbraendle/dotfiles.git
cd dotfiles

# Make installer executable
chmod +x install.sh

# Run the setup (interactive - you choose what to install)
./install.sh
```

## 📋 Installation Process

The installer is fully interactive and modular. Each step is optional:

### Step 1: Xcode Command Line Tools
Required for development tools. Installs automatically if missing.

### Step 2: Homebrew Package Manager
Installs or updates Homebrew - the essential macOS package manager.

### Step 3: Apps Installation
Installs all packages from `Brewfile`. You'll be prompted:
```
📦 Install apps from Brewfile? (y/n):
```

### Step 4: Terminal Setup
Installs Oh My Zsh and configures your terminal:
```
🖥️ Install Oh My Zsh and terminal configuration? (y/n):
```

### Step 5: Git Configuration
Sets up Git with your name and email:
```
🔧 Configure Git user settings? (y/n):
📧 Git email address: your.email@example.com
👤 Git username: Your Name
```

### Step 6: NPM Global Packages
Installs essential Node.js tools:
```
📦 Install NPM global packages? (y/n):
```

### Step 7: macOS System Settings
Applies developer and designer optimizations:
```
🔧 Apply macOS system settings? (y/n):
```

## 📁 File Structure

```
dotfiles/
├── install.sh              # Main installer script
├── Brewfile                # Homebrew packages definition
├── npm-install.sh           # NPM global packages installer
├── macos-settings.sh        # macOS system preferences
├── .zshrc                   # Zsh terminal configuration
├── .gitconfig               # Git configuration template
├── README.md                # This file
└── LICENSE                  # MIT License
```

## 🔧 Individual Components

### Run Specific Parts Only

You can run individual components separately:

```bash
# Install Homebrew packages only
brew bundle install

# Apply macOS settings only
source macos-settings.sh

# Install NPM packages only
./npm-install.sh

# Install terminal configuration only
cp .zshrc ~/.zshrc && source ~/.zshrc
```

### Customize Before Installing

1. **Edit Brewfile**: Add/remove apps you want
2. **Edit npm-install.sh**: Modify the packages array
3. **Edit macos-settings.sh**: Adjust system preferences
4. **Edit .zshrc**: Customize terminal aliases and functions

## 🎨 What Gets Installed

### CLI Tools (via Homebrew)
```
git, curl, wget, jq, tree, node
ripgrep, bat, eza
zsh-autosuggestions, zsh-syntax-highlighting
```

### GUI Applications (via Homebrew Cask)
```
visual-studio-code    # Code editor
google-chrome         # Browser
iterm2               # Terminal
sf-symbols           # Apple icons
the-unarchiver       # Archive tool
appcleaner          # App uninstaller
```

### NPM Global Packages
```
@anthropic-ai/claude-code    # AI coding assistant
typescript                   # JavaScript with types
prettier                    # Code formatter
```

### Optional Apps (Commented in Brewfile)
Uncomment in `Brewfile` if you want them:
```
firefox, slack, discord, spotify, notion, figma
1password, rectangle, cleanmymac
```

## 🔄 Safe Re-runs

The installer is designed to be run multiple times safely:
- ✅ Checks existing installations
- ✅ Updates packages to latest versions
- ✅ Skips already configured settings
- ✅ Won't break existing configurations

## 🛠️ Troubleshooting

### Installation Fails
```bash
# Check if Xcode Command Line Tools are installed
xcode-select -p

# Manually install if needed
xcode-select --install
```

### Homebrew Issues
```bash
# Update Homebrew
brew update && brew upgrade

# Check for issues
brew doctor
```

### Terminal Not Loading Configuration
```bash
# Reload shell configuration
source ~/.zshrc

# Or restart terminal completely
```

### NPM Packages Fail
```bash
# Ensure Node.js is installed
node --version
npm --version

# Install Node.js if missing
brew install node
```

## ⚙️ Customization

### Add Your Own Apps
Edit `Brewfile` and add:
```ruby
# CLI tools
brew "your-tool"

# GUI apps
cask "your-app"
```

### Add NPM Packages
Edit `npm-install.sh` and add to the packages array:
```bash
packages=(
    "existing-package:Description"
    "your-package:Your description"
)
```

### Modify macOS Settings
Edit `macos-settings.sh` to add your preferences:
```bash
# Your custom setting
defaults write com.apple.something setting -bool true
```

## 🎯 Philosophy

This setup follows these principles:

- **Homebrew First**: Use Homebrew for system tools and GUI apps
- **Modular Design**: Each component can be installed separately
- **Interactive Setup**: You choose what gets installed
- **Safe Re-runs**: Can be executed multiple times without issues
- **No Personal Data**: Templates ask for user input interactively
- **Modern Defaults**: Uses current best practices (main branch, latest tools)

## 🤝 Contributing

Feel free to fork this repository and adapt it to your needs! If you have improvements or fixes, pull requests are welcome.

## 📱 After Installation

### Next Steps
1. **Restart Terminal** to apply new configuration
2. **Open VS Code** and sign in to GitHub for settings sync
3. **Configure Finder Sidebar** manually (add your favorite folders)
4. **Run Claude Code**: `claude` command is now available
5. **Customize Further**: Adjust any settings to your preference

### Useful Commands
```bash
# Start Claude Code
claude

# Format code with Prettier
prettier --write .

# Type check with TypeScript
tsc --noEmit

# Search files with ripgrep
rg "search term"

# Better file listing
eza -la
```

## 🐛 Known Limitations

- Some Finder sidebar settings require manual configuration
- DNS settings are preserved (won't override Pi-hole/custom DNS)
- Accent popup remains enabled (some prefer this for international characters)

## 📄 License

MIT License - see [LICENSE](LICENSE) file. Feel free to use, modify, and distribute.

## 🙏 Acknowledgments

Inspired by the amazing dotfiles community on GitHub. Special thanks to all the open-source tools that make development on macOS enjoyable.

---

**Happy coding!** 🎉

If you find this useful, consider starring ⭐ the repository!