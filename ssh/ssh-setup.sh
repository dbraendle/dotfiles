#!/bin/bash

# SSH GitHub Setup Script
# Handles SSH key detection, creation, and GitHub configuration

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect existing SSH keys
detect_ssh_keys() {
    local keys=()
    local key_files=(
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/github_ed25519"
        "$HOME/.ssh/*_ed25519"
        "$HOME/.ssh/*_rsa"
    )
    
    for pattern in "${key_files[@]}"; do
        for key_file in $pattern; do
            if [ -f "$key_file" ] && [ -f "${key_file}.pub" ]; then
                # Extract email from public key comment
                local email=$(ssh-keygen -l -f "${key_file}.pub" 2>/dev/null | awk '{print $NF}' | grep -E '^.+@.+\..+$' || echo "no-email")
                local created=$(stat -f "%Sm" -t "%Y-%m-%d" "$key_file" 2>/dev/null || echo "unknown")
                keys+=("$key_file|$email|$created")
            fi
        done
    done
    
    printf '%s\n' "${keys[@]}" | sort -u
}

# Function to show SSH key selection menu
show_key_menu() {
    echo ""
    echo "🔑 GitHub SSH Setup"
    echo "┌─ SSH Key options:"
    
    local keys=($(detect_ssh_keys))
    local count=1
    
    # Show existing keys
    if [ ${#keys[@]} -gt 0 ]; then
        echo "│  Existing keys:"
        for key_info in "${keys[@]}"; do
            IFS='|' read -r key_file email created <<< "$key_info"
            local key_name=$(basename "$key_file")
            echo "│  $count) $key_name ($email, created $created)"
            ((count++))
        done
        echo "│"
    fi
    
    # Additional options
    echo "│  $count) Import key from clipboard/paste"
    local import_option=$count
    ((count++))
    
    echo "│  $count) Generate new GitHub key"
    local generate_option=$count
    ((count++))
    
    echo "│  $count) Skip SSH setup"
    local skip_option=$count
    echo "│"
    
    while true; do
        read -p "└─ Choice (1-$count): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $count ]; then
            if [ "$choice" -eq "$skip_option" ]; then
                print_status "SSH setup skipped"
                return 1
            elif [ "$choice" -eq "$generate_option" ]; then
                generate_new_key
                return $?
            elif [ "$choice" -eq "$import_option" ]; then
                import_key_from_input
                return $?
            else
                # Existing key selected
                local selected_key_info="${keys[$((choice-1))]}"
                IFS='|' read -r selected_key_file email created <<< "$selected_key_info"
                configure_github_ssh "$selected_key_file"
                return $?
            fi
        else
            echo "Invalid choice. Please enter a number between 1 and $count."
        fi
    done
}

# Function to generate new SSH key
generate_new_key() {
    echo ""
    read -p "📧 Enter email for new GitHub key: " email
    
    if [ -z "$email" ]; then
        print_error "Email cannot be empty"
        return 1
    fi
    
    local key_file="$HOME/.ssh/github_ed25519"
    
    if [ -f "$key_file" ]; then
        read -p "⚠️  GitHub key already exists. Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Key generation cancelled"
            return 1
        fi
    fi
    
    print_status "Generating new SSH key: $key_file"
    ssh-keygen -t ed25519 -C "$email (GitHub)" -f "$key_file" -N ""
    
    if [ $? -eq 0 ]; then
        print_success "SSH key generated successfully"
        configure_github_ssh "$key_file"
        return $?
    else
        print_error "Failed to generate SSH key"
        return 1
    fi
}

# Function to import key from user input
import_key_from_input() {
    echo ""
    echo "📋 Paste your private SSH key (press Ctrl+D when done):"
    echo "   (Include -----BEGIN ... -----END lines)"
    echo ""
    
    local private_key=""
    while IFS= read -r line; do
        private_key+="$line"$'\n'
    done
    
    if [ -z "$private_key" ]; then
        print_error "No key provided"
        return 1
    fi
    
    # Validate key format
    if [[ ! "$private_key" =~ -----BEGIN.*PRIVATE\ KEY----- ]]; then
        print_error "Invalid private key format"
        return 1
    fi
    
    echo ""
    read -p "📧 Enter email for this key: " email
    read -p "💾 Save as (default: github_ed25519): " key_name
    
    key_name=${key_name:-"github_ed25519"}
    local key_file="$HOME/.ssh/$key_name"
    
    if [ -f "$key_file" ]; then
        read -p "⚠️  Key file already exists. Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Import cancelled"
            return 1
        fi
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    
    # Save private key
    echo "$private_key" > "$key_file"
    chmod 600 "$key_file"
    
    # Generate public key
    ssh-keygen -y -f "$key_file" > "${key_file}.pub"
    
    if [ $? -eq 0 ]; then
        print_success "SSH key imported successfully"
        configure_github_ssh "$key_file"
        return $?
    else
        print_error "Failed to import SSH key"
        rm -f "$key_file" "${key_file}.pub"
        return 1
    fi
}

# Function to configure GitHub SSH
configure_github_ssh() {
    local key_file="$1"
    
    print_status "Configuring SSH for GitHub..."
    
    # Ensure .ssh directory exists
    mkdir -p "$HOME/.ssh"
    
    # Create or update SSH config
    local ssh_config="$HOME/.ssh/config"
    local github_config_exists=false
    
    if [ -f "$ssh_config" ]; then
        if grep -q "Host github.com" "$ssh_config"; then
            github_config_exists=true
            print_warning "GitHub SSH config already exists"
            read -p "🔄 Update existing GitHub SSH config? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "SSH configuration skipped"
                return 0
            fi
        fi
    fi
    
    # Create backup if config exists
    if [ -f "$ssh_config" ]; then
        cp "$ssh_config" "${ssh_config}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "SSH config backed up"
    fi
    
    # Add or update GitHub configuration
    if [ "$github_config_exists" = true ]; then
        # Update existing config
        sed -i.tmp '/Host github.com/,/^$/c\
Host github.com\
    HostName github.com\
    User git\
    IdentityFile '"$key_file"'\
    UseKeychain yes\
    AddKeysToAgent yes\
    ServerAliveInterval 60\
    ServerAliveCountMax 30\
' "$ssh_config"
        rm -f "${ssh_config}.tmp"
    else
        # Add new config
        {
            echo ""
            echo "# GitHub SSH Configuration"
            echo "Host github.com"
            echo "    HostName github.com"
            echo "    User git"
            echo "    IdentityFile $key_file"
            echo "    UseKeychain yes"
            echo "    AddKeysToAgent yes"
            echo "    ServerAliveInterval 60"
            echo "    ServerAliveCountMax 30"
        } >> "$ssh_config"
    fi
    
    # Set proper permissions
    chmod 644 "$ssh_config"
    chmod 600 "$key_file"
    chmod 644 "${key_file}.pub"
    
    print_success "SSH configuration updated"
    
    # Add key to ssh-agent
    print_status "Adding key to ssh-agent..."
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add "$key_file" > /dev/null 2>&1
    
    # Test connection
    print_status "Testing GitHub connection..."
    ssh_test_output=$(ssh -T git@github.com 2>&1)
    
    if echo "$ssh_test_output" | grep -q "successfully authenticated"; then
        print_success "✅ GitHub SSH connection successful!"
        local username=$(echo "$ssh_test_output" | grep -o "Hi [^!]*" | cut -d' ' -f2)
        if [ -n "$username" ]; then
            print_success "Connected as: $username"
        fi
    else
        print_warning "SSH key configured but not yet authenticated with GitHub"
        echo ""
        echo "📋 Next steps:"
        echo "1. Copy your public key:"
        echo "   pbcopy < ${key_file}.pub"
        echo ""
        echo "2. Add it to GitHub:"
        echo "   → Go to https://github.com/settings/ssh/new"
        echo "   → Paste the key and give it a title"
        echo "   → Click 'Add SSH key'"
        echo ""
        echo "3. Test connection:"
        echo "   ssh -T git@github.com"
        
        # Auto-copy to clipboard if pbcopy is available
        if command -v pbcopy &> /dev/null; then
            pbcopy < "${key_file}.pub"
            print_success "Public key copied to clipboard!"
        fi
    fi
    
    return 0
}

# Main function
main() {
    show_key_menu
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi