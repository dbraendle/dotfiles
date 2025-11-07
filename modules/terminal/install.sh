#!/usr/bin/env bash
# terminal/install.sh - Install Oh My Zsh and terminal configuration
# Part of the dotfiles v2 modular system

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
# shellcheck source=../../lib/logging.sh
source "${DOTFILES_DIR}/lib/logging.sh"
# shellcheck source=../../lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"
# shellcheck source=../../lib/stow-helpers.sh
source "${DOTFILES_DIR}/lib/stow-helpers.sh"

#######################################
# Main installation function
#######################################
main() {
    print_section "Terminal Module Installation"

    # Step 1: Install Oh My Zsh if not already installed
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        print_status "Installing Oh My Zsh..."

        # Download and run Oh My Zsh installer in unattended mode
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            print_success "Oh My Zsh installed successfully"
        else
            print_error "Failed to install Oh My Zsh"
            return 1
        fi
    else
        print_success "Oh My Zsh is already installed"
    fi

    # Step 2: Disable Oh My Zsh auto-update (we manage updates)
    print_status "Configuring Oh My Zsh to disable auto-updates..."
    local zshrc_omz="${HOME}/.oh-my-zsh/oh-my-zsh.sh"
    if [[ -f "${zshrc_omz}" ]]; then
        print_debug "Oh My Zsh will be updated via this module's update.sh script"
    fi

    # Step 3: Set Zsh as default shell (if not already)
    if [[ "${SHELL}" != "$(command -v zsh)" ]]; then
        print_status "Setting Zsh as default shell..."

        local zsh_path
        zsh_path="$(command -v zsh)"

        # Check if zsh is in /etc/shells
        if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
            print_warning "Adding ${zsh_path} to /etc/shells (requires sudo)"
            if sudo bash -c "echo '${zsh_path}' >> /etc/shells"; then
                print_success "Added ${zsh_path} to /etc/shells"
            else
                print_error "Failed to add ${zsh_path} to /etc/shells"
                return 1
            fi
        fi

        # Change default shell
        if chsh -s "${zsh_path}"; then
            print_success "Changed default shell to Zsh"
            print_warning "You may need to restart your terminal for this to take effect"
        else
            print_error "Failed to change default shell"
            return 1
        fi
    else
        print_success "Zsh is already the default shell"
    fi

    # Step 4: Stow the zsh configuration package
    print_status "Stowing zsh configuration..."
    if stow_package "zsh"; then
        print_success "Zsh configuration stowed successfully"
    else
        print_error "Failed to stow zsh configuration"
        return 1
    fi

    # Step 5: Note about Homebrew packages
    print_status "Note: Homebrew packages (zsh-autosuggestions, zsh-syntax-highlighting)"
    print_status "      are managed by the homebrew module via Brewfile"

    print_success "Terminal module installed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "  1. Restart your terminal or run: source ~/.zshrc"
    print_status "  2. Verify Oh My Zsh is working"
    print_status "  3. Enjoy your configured shell!"
}

# Run main function
main "$@"
