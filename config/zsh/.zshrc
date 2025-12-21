# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"

# Disable automatic updates (zsh plugins managed by Homebrew)
DISABLE_AUTO_UPDATE="true"

# Theme (Powerlevel10k - fancy git info, icons, colors)
ZSH_THEME="powerlevel10k/powerlevel10k"

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

# Powerlevel10k (installed via Homebrew)
if [ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi

# To customize Powerlevel10k, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add ~/bin to PATH (for dotfiles commands like 'update')
export PATH="$HOME/bin:$PATH"

# Environment Variables
export EDITOR="code"
export BROWSER="google-chrome"

# Basic Aliases
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Better CLI tools (if installed via Homebrew)
# Only override in interactive shells to avoid breaking scripts
if [[ $- == *i* ]]; then
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
alias dc='docker compose'  # Modern syntax (no hyphen)
alias dps='docker ps'
alias di='docker images'

# Development Aliases
alias serve='python3 -m http.server'
alias myip='curl -s https://httpbin.org/ip | jq -r .origin'

# macOS Utilities
alias scanner='open -a "Image Capture"'
alias cleanup='brew cleanup && brew autoremove'

# Scanner Commands (load from external file if available)
if [ -f "${DOTFILES_DIR}/.scan-shortcuts.sh" ]; then
    source "${DOTFILES_DIR}/.scan-shortcuts.sh"
fi

# Dotfiles Management (works from anywhere)
alias .install='cd ${DOTFILES_DIR} && ./install.sh'
alias .update='cd ${DOTFILES_DIR} && ./update.sh'
alias .manage='cd ${DOTFILES_DIR} && ./manage.sh'
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

export HA_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjYzc0ZDcwODRiYWI0YjFiYjdmMjM5Yjg0MzkxYjMwNSIsImlhdCI6MTc2MzA3NDAzMywiZXhwIjoyMDc4NDM0MDMzfQ.SxaSjbNSUXjuIDdUDQyp4EAhrRgKIdLCb3SAM_SEzTY'
export HA_URL='http://homeassistant.local:8123'
