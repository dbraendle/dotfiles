#!/usr/bin/env bash
# utils.sh - Utility functions for dotfiles scripts
# Provides system detection, file operations, and helper functions
# Usage: source this file after sourcing logging.sh

# Guard: prevent double-sourcing
[[ -n "${UTILS_SH_LOADED:-}" ]] && return 0
UTILS_SH_LOADED=1

# Get the directory where this library is located (use unique var name to avoid conflicts)
UTILS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging.sh from the same directory
# shellcheck source=./logging.sh
source "${UTILS_LIB_DIR}/logging.sh"

#######################################
# Check if running on macOS
# Returns:
#   0 if running on macOS, 1 otherwise
#######################################
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

#######################################
# Check if running on Apple Silicon (M1/M2/M3/M4)
# Returns:
#   0 if running on Apple Silicon, 1 otherwise
#######################################
is_apple_silicon() {
    if is_macos; then
        [[ "$(uname -m)" == "arm64" ]]
    else
        return 1
    fi
}

#######################################
# Check if running on a MacBook (laptop/portable)
# Returns:
#   0 if running on a MacBook, 1 otherwise
#######################################
is_laptop() {
    if is_macos; then
        local model
        model="$(sysctl -n hw.model 2>/dev/null)"
        [[ "${model}" =~ ^MacBook ]]
    else
        return 1
    fi
}

#######################################
# Check if a command exists in PATH
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if command exists, 1 otherwise
#######################################
command_exists() {
    local cmd="$1"
    command -v "${cmd}" >/dev/null 2>&1
}

#######################################
# Ask user a yes/no confirmation question
# Arguments:
#   $1 - Question to ask (default: "Continue?")
#   $2 - Default answer (y/n, default: n)
# Returns:
#   0 if user answered yes, 1 if user answered no
# Outputs:
#   Writes question to stdout, reads answer from stdin
#######################################
confirm() {
    local question="${1:-Continue?}"
    local default="${2:-n}"
    local prompt
    local answer

    # Set up prompt based on default (convert to lowercase for comparison)
    local default_lower
    default_lower="$(echo "${default}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${default_lower}" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    # Ask the question (force flush to stderr to ensure prompt appears)
    # Use %b for color variables to interpret ANSI escape sequences
    printf "%b%s %s%b " "${YELLOW}" "${question}" "${prompt}" "${NC}" >&2
    read -er answer

    # Handle empty answer (use default)
    if [[ -z "${answer}" ]]; then
        answer="${default}"
    fi

    # Check answer (convert to lowercase for comparison)
    local answer_lower
    answer_lower="$(echo "${answer}" | tr '[:upper:]' '[:lower:]')"
    [[ "${answer_lower}" =~ ^y(es)?$ ]]
}

#######################################
# Clean up old backup files
# Arguments:
#   $1 - Base file path (e.g., /Users/db/.zshrc)
# Returns:
#   0 always
# Notes:
#   - Keeps the 10 newest backups
#   - Deletes backups older than 3 months (90 days)
#   - Always keeps at least 10 backups regardless of age
#######################################
cleanup_old_backups() {
    local base_file="$1"
    local backup_pattern="${base_file}.backup-*"

    # Find all backups for this file, sorted by modification time (newest first)
    local backups=()
    while IFS= read -r backup; do
        backups+=("$backup")
    done < <(find "$(dirname "${base_file}")" -maxdepth 1 -name "$(basename "${backup_pattern}")" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null)

    local total_backups=${#backups[@]}

    # If we have 10 or fewer backups, keep all
    if [[ ${total_backups} -le 10 ]]; then
        print_debug "Found ${total_backups} backups for ${base_file}, keeping all"
        return 0
    fi

    print_debug "Found ${total_backups} backups for ${base_file}, cleaning up old ones"

    # Current time in seconds since epoch
    local now
    now="$(date +%s)"
    local three_months_ago=$((now - 7776000))  # 90 days * 24 hours * 60 min * 60 sec

    # Process backups starting from the 11th one
    local index=0
    local deleted=0
    for backup in "${backups[@]}"; do
        ((index++))

        # Skip the first 10 (newest)
        if [[ ${index} -le 10 ]]; then
            continue
        fi

        # Get file modification time
        local file_time
        file_time="$(stat -f %m "${backup}" 2>/dev/null || stat -c %Y "${backup}" 2>/dev/null)"

        # Delete if older than 3 months
        if [[ ${file_time} -lt ${three_months_ago} ]]; then
            print_debug "Deleting old backup: ${backup}"
            rm -f "${backup}"
            ((deleted++))
        fi
    done

    if [[ ${deleted} -gt 0 ]]; then
        print_debug "Deleted ${deleted} old backup(s) for ${base_file}"
    fi

    return 0
}

#######################################
# Create a backup of a file with timestamp
# Arguments:
#   $1 - File path to backup
# Returns:
#   0 if backup successful, 1 otherwise
# Outputs:
#   Creates backup file with .backup-TIMESTAMP extension
#   Automatically cleans up old backups
#######################################
create_backup() {
    local file="$1"

    if [[ -z "${file}" ]]; then
        print_error "create_backup: No file specified"
        return 1
    fi

    if [[ ! -e "${file}" ]]; then
        print_debug "create_backup: File does not exist, skipping: ${file}"
        return 0
    fi

    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_file="${file}.backup-${timestamp}"

    print_debug "Creating backup: ${file} -> ${backup_file}"

    if cp -a "${file}" "${backup_file}"; then
        print_success "Backup created: ${backup_file}"

        # Clean up old backups
        cleanup_old_backups "${file}"

        return 0
    else
        print_error "Failed to create backup of ${file}"
        return 1
    fi
}

#######################################
# Get the absolute path to the dotfiles directory
# This function attempts to find the dotfiles directory using multiple methods
# Returns:
#   0 if found, 1 otherwise
# Outputs:
#   Writes absolute path to dotfiles directory to stdout
#######################################
get_dotfiles_dir() {
    local dotfiles_dir=""

    # Method 1: Use DOTFILES_DIR environment variable if set
    if [[ -n "${DOTFILES_DIR:-}" && -d "${DOTFILES_DIR:-}" ]]; then
        dotfiles_dir="${DOTFILES_DIR}"

    # Method 2: Check if we're in a script inside the dotfiles directory
    elif [[ -n "${BASH_SOURCE[0]}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        if [[ -d "${script_dir}" && -d "${script_dir}/lib" ]]; then
            dotfiles_dir="${script_dir}"
        fi

    # Method 3: Check common locations
    elif [[ -d "${HOME}/dotfiles" ]]; then
        dotfiles_dir="${HOME}/dotfiles"
    elif [[ -d "${HOME}/.dotfiles" ]]; then
        dotfiles_dir="${HOME}/.dotfiles"
    fi

    if [[ -n "${dotfiles_dir}" ]]; then
        echo "${dotfiles_dir}"
        return 0
    else
        print_error "Could not find dotfiles directory"
        return 1
    fi
}

#######################################
# Ensure a directory exists, create if necessary
# Arguments:
#   $1 - Directory path
# Returns:
#   0 if directory exists or was created, 1 otherwise
#######################################
ensure_dir() {
    local dir="$1"

    if [[ -z "${dir}" ]]; then
        print_error "ensure_dir: No directory specified"
        return 1
    fi

    if [[ -d "${dir}" ]]; then
        print_debug "Directory already exists: ${dir}"
        return 0
    fi

    print_debug "Creating directory: ${dir}"
    if mkdir -p "${dir}"; then
        return 0
    else
        print_error "Failed to create directory: ${dir}"
        return 1
    fi
}

#######################################
# Create a symlink with backup of existing file
# Arguments:
#   $1 - Source file
#   $2 - Target symlink location
# Returns:
#   0 if successful, 1 otherwise
#######################################
safe_symlink() {
    local source="$1"
    local target="$2"

    if [[ -z "${source}" || -z "${target}" ]]; then
        print_error "safe_symlink: Source and target required"
        return 1
    fi

    if [[ ! -e "${source}" ]]; then
        print_error "safe_symlink: Source does not exist: ${source}"
        return 1
    fi

    # If target exists and is not a symlink to source, back it up
    if [[ -e "${target}" || -L "${target}" ]]; then
        if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
            print_debug "Symlink already correct: ${target} -> ${source}"
            return 0
        else
            print_warning "Target exists, creating backup: ${target}"
            create_backup "${target}" || return 1
            rm -rf "${target}"
        fi
    fi

    # Create parent directory if needed
    local target_dir
    target_dir="$(dirname "${target}")"
    ensure_dir "${target_dir}" || return 1

    # Create symlink
    if ln -s "${source}" "${target}"; then
        print_success "Created symlink: ${target} -> ${source}"
        return 0
    else
        print_error "Failed to create symlink: ${target} -> ${source}"
        return 1
    fi
}

#######################################
# Get the current macOS version
# Returns:
#   0 if successful, 1 otherwise
# Outputs:
#   Writes macOS version to stdout (e.g., "14.0" for Sonoma)
#######################################
get_macos_version() {
    if is_macos; then
        sw_vers -productVersion
        return 0
    else
        return 1
    fi
}

#######################################
# Compare two version strings
# Arguments:
#   $1 - First version (e.g., "1.2.3")
#   $2 - Second version (e.g., "1.2.4")
# Returns:
#   0 if v1 == v2, 1 if v1 < v2, 2 if v1 > v2
#######################################
version_compare() {
    local v1="$1"
    local v2="$2"

    if [[ "${v1}" == "${v2}" ]]; then
        return 0
    fi

    local IFS=.
    local i ver1=($v1) ver2=($v2)

    # Fill empty positions with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]:-} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 2
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done

    return 0
}

#######################################
# Get modules compatible with a specific profile
# Arguments:
#   $1 - Profile name (e.g., "laptop" or "desktop")
#   $2 - Modules directory path (optional, defaults to DOTFILES_DIR/modules)
# Returns:
#   0 if successful, 1 otherwise
# Outputs:
#   Writes list of module names (one per line) that match the profile
#######################################
get_modules_for_profile() {
    local profile="$1"
    local modules_dir="${2:-${DOTFILES_DIR}/modules}"

    if [[ -z "${profile}" ]]; then
        print_error "get_modules_for_profile: Profile name required"
        return 1
    fi

    if [[ ! -d "${modules_dir}" ]]; then
        print_error "get_modules_for_profile: Modules directory not found: ${modules_dir}"
        return 1
    fi

    # Iterate through all module directories
    while IFS= read -r module_dir; do
        local module_name
        module_name="$(basename "${module_dir}")"
        local module_json="${module_dir}/module.json"

        # Skip if module.json doesn't exist
        if [[ ! -f "${module_json}" ]]; then
            print_debug "Skipping ${module_name}: No module.json found"
            continue
        fi

        # Check if jq is available for JSON parsing (preferred method)
        if command_exists jq; then
            # Read profiles array from module.json
            local profiles
            profiles="$(jq -r '.profiles // [] | .[]' "${module_json}" 2>/dev/null)"

            # If no profiles defined, module works with all profiles
            if [[ -z "${profiles}" ]]; then
                echo "${module_name}"
                continue
            fi

            # Check if current profile is in the list
            if echo "${profiles}" | grep -q "^${profile}$"; then
                echo "${module_name}"
            else
                print_debug "Skipping ${module_name}: Not compatible with profile '${profile}'"
            fi
        else
            # Fallback: Parse JSON with grep (less robust but works without jq)
            if grep -q '"profiles"' "${module_json}" 2>/dev/null; then
                # Has profiles field, check if our profile is in it
                if grep -q "\"${profile}\"" "${module_json}" 2>/dev/null; then
                    echo "${module_name}"
                else
                    print_debug "Skipping ${module_name}: Not compatible with profile '${profile}' (parsed without jq)"
                fi
            else
                # No profiles field = compatible with all profiles
                echo "${module_name}"
            fi
        fi
    done < <(find "${modules_dir}" -mindepth 1 -maxdepth 1 -type d | sort)

    return 0
}

#######################################
# Check if script is running with sudo/root privileges
# Returns:
#   0 if running as root, 1 otherwise
#######################################
is_root() {
    [[ "${EUID}" -eq 0 ]]
}

#######################################
# Check if current user has administrator privileges
# Returns:
#   0 if user is admin, 1 otherwise
#######################################
check_admin_rights() {
    local current_user
    current_user="$(get_real_user)"

    # Check if user is in admin group (macOS)
    if groups "${current_user}" 2>/dev/null | grep -q '\badmin\b'; then
        return 0
    else
        return 1
    fi
}

#######################################
# Get the current user's username (even when using sudo)
# Returns:
#   0 if successful, 1 otherwise
# Outputs:
#   Writes username to stdout
#######################################
get_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "${SUDO_USER}"
    else
        echo "${USER}"
    fi
}

#######################################
# Check if running in CI environment
# Returns:
#   0 if running in CI, 1 otherwise
#######################################
is_ci() {
    [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${TRAVIS:-}" ]] || [[ -n "${CIRCLECI:-}" ]]
}

#######################################
# Prompt user for input with optional default value
# Arguments:
#   $1 - Prompt text (e.g., "Git user name")
#   $2 - Default value (optional, shown in brackets)
# Returns:
#   0 always
# Outputs:
#   Writes user input (or default) to stdout
#######################################
prompt_input() {
    local prompt_text="$1"
    local default_value="${2:-}"
    local user_input

    # Build prompt with default if provided (output to stderr so it's not buffered)
    # Use %b for color variables to interpret ANSI escape sequences
    if [[ -n "${default_value}" ]]; then
        printf "%b%s [%s]:%b " "${YELLOW:-}" "${prompt_text}" "${default_value}" "${NC:-}" >&2
    else
        printf "%b%s:%b " "${YELLOW:-}" "${prompt_text}" "${NC:-}" >&2
    fi

    # Read user input (with readline editing support for arrow keys)
    read -er user_input

    # Use default if input is empty
    if [[ -z "${user_input}" && -n "${default_value}" ]]; then
        echo "${default_value}"
    else
        echo "${user_input}"
    fi
}
