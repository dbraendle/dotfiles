# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"

# Disable automatic updates (zsh plugins managed by Homebrew)
DISABLE_AUTO_UPDATE="true"

# Theme (clean and minimal)
ZSH_THEME="robbyrussell"

# Plugins (only built-in plugins - external ones loaded separately below)
plugins=(
    git
    macos
    brew
    docker
    node
    python
    golang
    rust
    vscode
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Environment Variables
export EDITOR="code"
export BROWSER="google-chrome"

# Basic Aliases
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Better CLI tools (if installed via Homebrew)
if command -v eza &> /dev/null; then
    alias ls='eza'
    alias ll='eza -la'
    alias la='eza -la'
    alias tree='eza --tree'
fi

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Git Aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --decorate --graph'

# Docker Aliases (if using Docker)
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Development Aliases
alias serve='python3 -m http.server'
alias myip='curl -s https://httpbin.org/ip | jq -r .origin'

# macOS Utilities
alias scanner='open -a "Image Capture"'
alias cleanup='brew cleanup && brew autoremove'

# Scanner Commands (load from external file if available)
if [ -f "$HOME/Dev/dotfiles/.scan-shortcuts.sh" ]; then
    source "$HOME/Dev/dotfiles/.scan-shortcuts.sh"
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/.scan-shortcuts.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/.scan-shortcuts.sh"
fi

# Dotfiles Management (works from anywhere)
alias .install='cd ~/Dev/dotfiles && ./install.sh'
alias .update='cd ~/Dev/dotfiles && ./update.sh'
alias .brew='cd ~/Dev/dotfiles && ./brew-install.sh'
alias .zsh='cd ~/Dev/dotfiles && ./zsh-install.sh'
alias ssh-setup='cd ~/Dev/dotfiles/ssh && ./ssh-setup.sh'
# Removed mas-helper.sh - use 'brew bundle install' instead
alias .license='sudo xcodebuild -license accept'

# Custom Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Auto-suggestions (installed via Homebrew)
if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting (must be at the end)
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Welcome message
echo "🚀 Terminal ready - $(date '+%H:%M')"
if command -v git &> /dev/null && [ -n "$(git config --global user.name 2>/dev/null)" ]; then
    echo "👤 Git: $(git config --global user.name)"
fi

