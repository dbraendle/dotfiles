#!/bin/bash

# SSH Setup Manager - Ultimate Edition
# Usage: ./ssh-setup.sh [service] [hostname] [user] [port]
# Examples:
#   ./ssh-setup.sh                              # Interactive menu
#   ./ssh-setup.sh github                       # Setup GitHub (from JSON)
#   ./ssh-setup.sh pihole                       # Setup Pi-hole (from JSON)
#   ./ssh-setup.sh nas 192.168.1.50 admin 22   # Setup NAS (non-interactive)
#   ./ssh-setup.sh --add-service nas 192.168.1.50 admin 22
#   ./ssh-setup.sh --setup-all                  # Setup all JSON services
#   ./ssh-setup.sh --list                       # List all services
#   ./ssh-setup.sh --help                       # Show help

# Get script directory for JSON file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_JSON="$SCRIPT_DIR/services.json"

# Signal handler for Ctrl+C
cleanup_and_exit() {
    echo ""
    print_status "Setup interrupted by user"
    exit 130
}

# Set up signal traps
trap cleanup_and_exit SIGINT SIGTERM

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}[SSH-MANAGER]${NC} $1"
}

# Check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install with: brew install jq"
        exit 1
    fi
}

# Show help
show_help() {
    echo "🔑 SSH Setup Manager - Ultimate Edition"
    echo ""
    echo "Usage:"
    echo "  ./ssh-setup.sh                                 Interactive service menu"
    echo "  ./ssh-setup.sh <service>                       Setup service from JSON"
    echo "  ./ssh-setup.sh <service> <host> <user> <port>  Setup service non-interactive"
    echo ""
    echo "Service Management:"
    echo "  ./ssh-setup.sh --add-service <name> <host> <user> <port> [description]"
    echo "  ./ssh-setup.sh --remove-service <name>         Remove service from JSON"
    echo "  ./ssh-setup.sh --setup-all                     Setup all JSON services"
    echo "  ./ssh-setup.sh --list                          List all services"
    echo "  ./ssh-setup.sh --rotate-keys <service>         Generate new key + cleanup old"
    echo ""
    echo "Examples:"
    echo "  ./ssh-setup.sh github                          # From JSON config"
    echo "  ./ssh-setup.sh pihole                          # From JSON config"
    echo "  ./ssh-setup.sh nas 192.168.1.50 admin 22      # Non-interactive"
    echo "  ./ssh-setup.sh --add-service work 10.0.0.1 root 2222 \"Work server\""
    echo "  ./ssh-setup.sh --setup-all                     # Setup everything"
}

# Load service from JSON
load_service() {
    local service="$1"
    
    if [ ! -f "$SERVICES_JSON" ]; then
        return 1
    fi
    
    if ! jq -e ".services.\"$service\"" "$SERVICES_JSON" > /dev/null 2>&1; then
        return 1
    fi
    
    echo "$(jq -r ".services.\"$service\"" "$SERVICES_JSON")"
}

# Save service to JSON
save_service() {
    local service="$1"
    local hostname="$2" 
    local user="$3"
    local port="$4"
    local description="$5"
    local type="server"
    
    # Special handling for GitHub
    if [ "$service" = "github" ]; then
        type="git"
        hostname="github.com"
        user="git"
        port="22"
        description="GitHub SSH authentication"
    fi
    
    # Create JSON structure if it doesn't exist
    if [ ! -f "$SERVICES_JSON" ]; then
        cat > "$SERVICES_JSON" << 'EOF'
{
  "version": "1.0",
  "services": {},
  "settings": {
    "default_key_type": "ed25519",
    "auto_backup_config": true,
    "cleanup_old_keys": false,
    "key_rotation_days": 365
  }
}
EOF
    fi
    
    # Add service to JSON
    local temp_file=$(mktemp)
    jq ".services.\"$service\" = {
        \"type\": \"$type\",
        \"hostname\": \"$hostname\",
        \"user\": \"$user\",
        \"port\": $port,
        \"description\": \"$description\",
        \"test_command\": \"uptime\"
    }" "$SERVICES_JSON" > "$temp_file" && mv "$temp_file" "$SERVICES_JSON"
    
    print_success "Service '$service' saved to configuration"
}

# Remove service from JSON
remove_service() {
    local service="$1"
    
    if [ ! -f "$SERVICES_JSON" ]; then
        print_error "No services configuration found"
        return 1
    fi
    
    if ! jq -e ".services.\"$service\"" "$SERVICES_JSON" > /dev/null 2>&1; then
        print_error "Service '$service' not found in configuration"
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq "del(.services.\"$service\")" "$SERVICES_JSON" > "$temp_file" && mv "$temp_file" "$SERVICES_JSON"
    
    print_success "Service '$service' removed from configuration"
}

# List all services
list_services() {
    print_header "Configured SSH Services"
    echo "=========================="
    
    if [ ! -f "$SERVICES_JSON" ]; then
        echo "No services configuration found."
        echo "Add services with: ./ssh-setup.sh --add-service <name> <host> <user> <port>"
        return 1
    fi
    
    echo ""
    echo "📋 Services in configuration:"
    jq -r '.services | to_entries[] | "  • \(.key): \(.value.user)@\(.value.hostname):\(.value.port) - \(.value.description)"' "$SERVICES_JSON" 2>/dev/null || {
        echo "  No services configured"
        return 1
    }
    
    echo ""
    echo "🖥️  Local SSH config status:"
    local ssh_config="$HOME/.ssh/config"
    if [ -f "$ssh_config" ]; then
        jq -r '.services | keys[]' "$SERVICES_JSON" 2>/dev/null | while read -r service; do
            if grep -q "Host $service" "$ssh_config" 2>/dev/null; then
                echo "  ✅ $service - Configured"
            else
                echo "  ❌ $service - Not configured"
            fi
        done
    else
        echo "  ❌ No SSH config found"
    fi
}

# Interactive service menu
interactive_menu() {
    if [ ! -f "$SERVICES_JSON" ]; then
        print_error "No services configuration found. Add services first:"
        echo "  ./ssh-setup.sh --add-service <name> <host> <user> <port>"
        echo "  ./ssh-setup.sh --add-service pihole 192.168.178.32 pi 22"
        return 1
    fi
    
    print_header "SSH Service Setup Menu"
    echo "=============================="
    echo ""
    
    # Get services from JSON
    local services=($(jq -r '.services | keys[]' "$SERVICES_JSON" 2>/dev/null))
    
    if [ ${#services[@]} -eq 0 ]; then
        echo "No services configured. Add some first:"
        echo "  ./ssh-setup.sh --add-service <name> <host> <user> <port>"
        return 1
    fi
    
    echo "Available services:"
    local count=1
    for service in "${services[@]}"; do
        local desc=$(jq -r ".services.\"$service\".description" "$SERVICES_JSON" 2>/dev/null)
        local host=$(jq -r ".services.\"$service\".hostname" "$SERVICES_JSON" 2>/dev/null)
        echo "  $count) $service - $desc ($host)"
        ((count++))
    done
    
    echo "  $count) Add new service"
    local add_option=$count
    ((count++))
    
    echo "  $count) Setup all services"
    local all_option=$count
    ((count++))
    
    echo "  $count) Exit"
    local exit_option=$count
    echo ""
    
    while true; do
        read -p "Choice (1-$count): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $count ]; then
            if [ "$choice" -eq "$exit_option" ]; then
                print_status "Exiting SSH setup"
                exit 0
            elif [ "$choice" -eq "$all_option" ]; then
                setup_all_services
                return $?
            elif [ "$choice" -eq "$add_option" ]; then
                echo ""
                read -p "Service name: " new_service
                
                # Check if service already exists
                if jq -e ".services.\"$new_service\"" "$SERVICES_JSON" > /dev/null 2>&1; then
                    print_warning "Service '$new_service' already exists in configuration"
                    echo "Current config: $(jq -r ".services.\"$new_service\" | \"\(.user)@\(.hostname):\(.port)\"" "$SERVICES_JSON")"
                    echo ""
                    echo "Options:"
                    echo "  1) Overwrite existing service"
                    echo "  2) Use different name"  
                    echo "  3) Cancel"
                    echo ""
                    
                    while true; do
                        read -p "Choice (1-3): " choice
                        case "$choice" in
                            1)
                                print_status "Will overwrite existing service '$new_service'"
                                break
                                ;;
                            2)
                                read -p "Enter new service name: " new_service
                                if [ -z "$new_service" ]; then
                                    print_error "Service name cannot be empty"
                                    continue
                                fi
                                # Check if new name exists too
                                if jq -e ".services.\"$new_service\"" "$SERVICES_JSON" > /dev/null 2>&1; then
                                    print_warning "Service '$new_service' also exists. Please choose a different name."
                                    continue
                                fi
                                break
                                ;;
                            3)
                                print_status "Service creation cancelled"
                                return 1
                                ;;
                            *)
                                echo "Invalid choice. Please enter 1, 2, or 3."
                                ;;
                        esac
                    done
                fi
                
                read -p "Hostname/IP: " new_host
                read -p "Username: " new_user
                read -p "Port (default: 22): " new_port
                new_port=${new_port:-22}
                read -p "Description (optional): " new_desc
                
                # First try to setup SSH (validation)
                local ssh_result
                setup_service_ssh "$new_service" "$new_host" "$new_user" "$new_port"
                ssh_result=$?
                
                # Only save to JSON if SSH setup was successful
                if [ $ssh_result -eq 0 ]; then
                    save_service "$new_service" "$new_host" "$new_user" "$new_port" "$new_desc"
                    print_success "Service '$new_service' saved to configuration"
                else
                    print_warning "Service setup failed - not saved to configuration"
                fi
                
                return $ssh_result
            else
                # Service selected
                local selected_service="${services[$((choice-1))]}"
                setup_service_from_json "$selected_service"
                local result=$?
                
                # If user wants to go back to menu, restart interactive menu
                if [ $result -eq 2 ]; then
                    interactive_menu
                    return $?
                elif [ $result -eq 0 ]; then
                    # Service setup completed successfully - ask if user wants to continue
                    echo ""
                    read -p "🔄 Setup another service? (y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        interactive_menu
                        return $?
                    fi
                fi
                return $result
            fi
        else
            echo "Invalid choice. Please enter a number between 1 and $count."
        fi
    done
}

# Setup service from JSON configuration
setup_service_from_json() {
    local service="$1"
    
    local service_data=$(load_service "$service")
    if [ $? -ne 0 ]; then
        print_error "Service '$service' not found in configuration"
        return 1
    fi
    
    local hostname=$(echo "$service_data" | jq -r '.hostname')
    local user=$(echo "$service_data" | jq -r '.user')
    local port=$(echo "$service_data" | jq -r '.port')
    local type=$(echo "$service_data" | jq -r '.type')
    
    print_header "Setting up SSH for: $service"
    echo "Host: $hostname, User: $user, Port: $port"
    echo ""
    
    if [ "$type" = "git" ]; then
        setup_github_ssh "$service"
        local result=$?
    else
        setup_service_ssh "$service" "$hostname" "$user" "$port"
        local result=$?
    fi
    
    # Pass through return code (including "back to menu" = 2)
    return $result
}

# Setup all services from JSON
setup_all_services() {
    print_header "Setting up ALL services from configuration"
    echo ""
    
    if [ ! -f "$SERVICES_JSON" ]; then
        print_error "No services configuration found"
        return 1
    fi
    
    local services=($(jq -r '.services | keys[]' "$SERVICES_JSON" 2>/dev/null))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_warning "No services configured"
        return 1
    fi
    
    for service in "${services[@]}"; do
        echo "🔄 Setting up: $service"
        setup_service_from_json "$service"
        echo ""
    done
    
    print_success "All services setup completed!"
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

# Show key selection menu
show_key_menu() {
    local service="$1"
    local hostname="$2"
    local user="$3"
    local port="$4"
    
    echo ""
    echo "🔑 SSH Key Selection for: $service"
    echo "┌─ Choose SSH key:"
    
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
    echo "│  $count) Generate new key for $service"
    local generate_option=$count
    ((count++))
    
    echo "│  $count) Import key from clipboard"
    local import_option=$count
    ((count++))
    
    echo "│  $count) ← Back to service menu"
    local back_option=$count
    ((count++))
    
    echo "│  $count) Cancel setup (exit)"
    local cancel_option=$count
    echo "│"
    
    while true; do
        read -p "└─ Choice (1-$count): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $count ]; then
            if [ "$choice" -eq "$cancel_option" ]; then
                print_status "SSH setup cancelled"
                exit 0
            elif [ "$choice" -eq "$back_option" ]; then
                print_status "Returning to service menu..."
                return 2  # Special return code for "back to menu"
            elif [ "$choice" -eq "$generate_option" ]; then
                generate_service_key "$service"
                local key_file="$HOME/.ssh/${service}_ed25519"
                configure_ssh "$service" "$key_file" "$hostname" "$user" "$port"
                return $?
            elif [ "$choice" -eq "$import_option" ]; then
                import_key_for_service "$service"
                local result=$?
                if [ $result -eq 0 ]; then
                    # Find the imported key file (could be any type now)
                    local key_file=""
                    for key_type in ed25519 rsa ecdsa dsa unknown; do
                        if [ -f "$HOME/.ssh/${service}_${key_type}" ]; then
                            key_file="$HOME/.ssh/${service}_${key_type}"
                            break
                        fi
                    done
                    
                    if [ -n "$key_file" ]; then
                        configure_ssh "$service" "$key_file" "$hostname" "$user" "$port"
                        return $?
                    else
                        print_error "Could not find imported key file"
                        return 1
                    fi
                fi
                return $result
            else
                # Existing key selected
                local selected_key_info="${keys[$((choice-1))]}"
                IFS='|' read -r selected_key_file email created <<< "$selected_key_info"
                configure_ssh "$service" "$selected_key_file" "$hostname" "$user" "$port"
                return $?
            fi
        else
            echo "Invalid choice. Please enter a number between 1 and $count."
        fi
    done
}

# Generate new SSH key for service
generate_service_key() {
    local service="$1"
    
    echo ""
    read -p "📧 Enter email for new $service key: " email
    
    if [ -z "$email" ]; then
        print_error "Email cannot be empty"
        return 1
    fi
    
    local key_file="$HOME/.ssh/${service}_ed25519"
    
    if [ -f "$key_file" ]; then
        read -p "⚠️  Key for $service already exists. Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Key generation cancelled"
            return 1
        fi
    fi
    
    print_status "Generating new SSH key: $key_file"
    ssh-keygen -t ed25519 -C "$email ($service)" -f "$key_file" -N ""
    
    if [ $? -eq 0 ]; then
        print_success "SSH key generated successfully"
        return 0
    else
        print_error "Failed to generate SSH key"
        return 1
    fi
}

# Import key for service
import_key_for_service() {
    local service="$1"
    
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
    
    # Create temporary file to detect key type
    local temp_key_file=$(mktemp)
    echo "$private_key" > "$temp_key_file"
    chmod 600 "$temp_key_file"
    
    # Generate public key to detect type
    local temp_pub_file="${temp_key_file}.pub"
    ssh-keygen -y -f "$temp_key_file" > "$temp_pub_file" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        print_error "Invalid private key format or corrupted key"
        rm -f "$temp_key_file" "$temp_pub_file"
        return 1
    fi
    
    # Detect key type from public key
    local key_type_raw=$(ssh-keygen -l -f "$temp_pub_file" 2>/dev/null | awk '{print $4}' | tr -d '()')
    local key_type=""
    
    case "$key_type_raw" in
        "ED25519"|"ed25519")
            key_type="ed25519"
            ;;
        "RSA"|"rsa")
            key_type="rsa"
            ;;
        "ECDSA"|"ecdsa")
            key_type="ecdsa"
            ;;
        "DSA"|"dsa")
            key_type="dsa"
            ;;
        *)
            # Fallback: try to detect from private key content
            if [[ "$private_key" =~ "BEGIN OPENSSH PRIVATE KEY" ]]; then
                key_type="ed25519"  # Most likely for OpenSSH format
            elif [[ "$private_key" =~ "BEGIN RSA PRIVATE KEY" ]]; then
                key_type="rsa"
            elif [[ "$private_key" =~ "BEGIN EC PRIVATE KEY" ]]; then
                key_type="ecdsa"
            elif [[ "$private_key" =~ "BEGIN DSA PRIVATE KEY" ]]; then
                key_type="dsa"
            else
                key_type="unknown"
            fi
            ;;
    esac
    
    print_status "Detected key type: $(echo "$key_type" | tr '[:lower:]' '[:upper:]')"
    
    # Create final key file with correct naming
    local key_file="$HOME/.ssh/${service}_${key_type}"
    
    if [ -f "$key_file" ]; then
        read -p "⚠️  Key file ${service}_${key_type} already exists. Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Import cancelled"
            rm -f "$temp_key_file" "$temp_pub_file"
            return 1
        fi
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    
    # Move temporary files to final location
    mv "$temp_key_file" "$key_file"
    mv "$temp_pub_file" "${key_file}.pub"
    
    # Set proper permissions
    chmod 600 "$key_file"
    chmod 644 "${key_file}.pub"
    
    print_success "SSH key imported successfully as ${service}_${key_type}"
    return 0
}

# Main SSH configuration function
configure_ssh() {
    local service="$1"
    local key_file="$2"
    local hostname="$3"
    local user="$4"
    local port="$5"
    
    print_status "Configuring SSH for $service..."
    
    # Ensure .ssh directory exists
    mkdir -p "$HOME/.ssh"
    
    # Create or update SSH config
    local ssh_config="$HOME/.ssh/config"
    local service_config_exists=false
    
    if [ -f "$ssh_config" ]; then
        if grep -q "Host $service" "$ssh_config"; then
            service_config_exists=true
            print_warning "$service SSH config already exists"
            read -p "🔄 Update existing $service SSH config? (y/n): " -n 1 -r
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
    
    # Add or update service configuration
    if [ "$service_config_exists" = true ]; then
        # Update existing config
        if [ "$service" = "github" ]; then
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
        else
            sed -i.tmp "/Host $service/,/^$/c\\
Host $service\\
    HostName $hostname\\
    User $user\\
    Port $port\\
    IdentityFile $key_file\\
    UseKeychain yes\\
    AddKeysToAgent yes\\
    ServerAliveInterval 60\\
    ServerAliveCountMax 30\\
" "$ssh_config"
        fi
        rm -f "${ssh_config}.tmp"
    else
        # Add new config
        {
            echo ""
            echo "# $service SSH Configuration"
            if [ "$service" = "github" ]; then
                echo "Host github.com"
                echo "    HostName github.com"
                echo "    User git"
            else
                echo "Host $service"
                echo "    HostName $hostname"
                echo "    User $user"
                echo "    Port $port"
            fi
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
    
    # Handle key deployment
    if [ "$service" = "github" ]; then
        deploy_github_key "$key_file"
    else
        deploy_server_key "$service" "$key_file" "$hostname" "$user" "$port"
    fi
}

# Deploy GitHub key
deploy_github_key() {
    local key_file="$1"
    
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
}

# Deploy server key
deploy_server_key() {
    local service="$1"
    local key_file="$2"
    local hostname="$3"
    local user="$4"
    local port="$5"
    
    print_success "✅ $service SSH key configured!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Copy your public key to $service server:"
    echo "   ssh-copy-id -i ${key_file}.pub -p $port $user@$hostname"
    echo ""
    echo "2. Or manually add it:"
    echo "   • Copy: pbcopy < ${key_file}.pub"
    echo "   • SSH to server: ssh -p $port $user@$hostname"
    echo "   • Add to: ~/.ssh/authorized_keys"
    echo ""
    echo "3. Test connection:"
    echo "   ssh $service"
    
    # Auto-copy to clipboard if pbcopy is available
    if command -v pbcopy &> /dev/null; then
        pbcopy < "${key_file}.pub"
        print_success "Public key copied to clipboard!"
    fi
    
    # Ask if user wants to try ssh-copy-id now
    read -p "🚀 Try to copy key to $service now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Attempting to copy key to $service..."
        if [ "$port" = "22" ]; then
            ssh-copy-id -i "${key_file}.pub" "$user@$hostname"
        else
            ssh-copy-id -i "${key_file}.pub" -p "$port" "$user@$hostname"
        fi
        
        if [ $? -eq 0 ]; then
            print_success "Key successfully copied to $service!"
            print_status "Testing connection..."
            ssh -o ConnectTimeout=5 "$service" "echo '$service SSH connection successful!'"
        else
            print_warning "Key copy failed - you may need to do it manually"
        fi
    fi
}

# Setup service SSH (main entry point)
setup_service_ssh() {
    local service="$1"
    local hostname="$2"
    local user="$3"  
    local port="$4"
    
    show_key_menu "$service" "$hostname" "$user" "$port"
}

# Setup GitHub SSH
setup_github_ssh() {
    local service="github"
    setup_service_ssh "$service" "github.com" "git" "22"
}

# Rotate keys for a service
rotate_keys() {
    local service="$1"
    
    print_header "Rotating SSH keys for: $service"
    
    # Check if service exists
    local service_data=$(load_service "$service")
    if [ $? -ne 0 ]; then
        print_error "Service '$service' not found in configuration"
        return 1
    fi
    
    local hostname=$(echo "$service_data" | jq -r '.hostname')
    local user=$(echo "$service_data" | jq -r '.user')
    local port=$(echo "$service_data" | jq -r '.port')
    
    echo "This will:"
    echo "  1. Generate a new SSH key for $service"
    echo "  2. Deploy the new key to $hostname"
    echo "  3. Remove old keys from the server (optional)"
    echo ""
    
    read -p "Continue with key rotation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Key rotation cancelled"
        return 1
    fi
    
    # Generate new key
    generate_service_key "$service"
    local new_key_file="$HOME/.ssh/${service}_ed25519"
    
    # Configure SSH
    configure_ssh "$service" "$new_key_file" "$hostname" "$user" "$port"
    
    # Optional: Clean up old keys on server
    read -p "🧹 Remove old keys from server? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up old keys on $service..."
        ssh "$service" "cd ~/.ssh && cp authorized_keys authorized_keys.backup && tail -1 authorized_keys > authorized_keys.new && mv authorized_keys.new authorized_keys"
        print_success "Old keys removed, backup saved as authorized_keys.backup"
    fi
    
    print_success "Key rotation completed for $service!"
}

# Main function
main() {
    local command="$1"
    
    # Check for jq
    check_jq
    
    case "$command" in
        "--help"|"-h"|"help")
            show_help
            ;;
        "--list"|"-l"|"list")
            list_services
            ;;
        "--add-service")
            shift
            if [ $# -lt 4 ]; then
                print_error "Usage: --add-service <name> <hostname> <user> <port> [description]"
                exit 1
            fi
            local name="$1"
            local hostname="$2"
            local user="$3"
            local port="$4"
            local description="${5:-$name server}"
            
            save_service "$name" "$hostname" "$user" "$port" "$description"
            print_status "Service '$name' added to configuration. Setup with: ./ssh-setup.sh $name"
            ;;
        "--remove-service")
            shift
            if [ $# -lt 1 ]; then
                print_error "Usage: --remove-service <name>"
                exit 1
            fi
            remove_service "$1"
            ;;
        "--setup-all")
            setup_all_services
            ;;
        "--rotate-keys")
            shift
            if [ $# -lt 1 ]; then
                print_error "Usage: --rotate-keys <service>"
                exit 1
            fi
            rotate_keys "$1"
            ;;
        "")
            # No arguments - interactive mode
            interactive_menu
            ;;
        *)
            # Service specified - check for additional parameters
            local service="$1"
            local hostname="$2"
            local user="$3"
            local port="$4"
            
            if [ -n "$hostname" ] && [ -n "$user" ] && [ -n "$port" ]; then
                # Non-interactive mode with all parameters
                print_header "Non-interactive setup: $service"
                local ssh_result
                setup_service_ssh "$service" "$hostname" "$user" "$port"
                ssh_result=$?
                
                # Only save to JSON if SSH setup was successful
                if [ $ssh_result -eq 0 ]; then
                    save_service "$service" "$hostname" "$user" "$port" "$service server"
                else
                    print_warning "Service setup failed - not saved to configuration"
                fi
                
                return $ssh_result
            else
                # Try to load from JSON, fallback to interactive
                setup_service_from_json "$service"
            fi
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi