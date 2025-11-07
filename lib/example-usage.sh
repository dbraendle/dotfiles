#!/usr/bin/env bash
# example-usage.sh - Comprehensive example of using the dotfiles libraries
# This script demonstrates best practices for using all library functions

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
# Note: stow-helpers.sh automatically sources logging.sh and utils.sh
# so you only need to source the highest-level library you need
source "${SCRIPT_DIR}/stow-helpers.sh"

# Optionally enable debug mode
# export DEBUG=1

#######################################
# Example: System detection and information
#######################################
system_info() {
    print_section "System Information"

    # Check operating system
    if is_macos; then
        print_success "Running on macOS"
        print_status "Version: $(get_macos_version)"
    else
        print_error "Not running on macOS"
        return 1
    fi

    # Check architecture
    if is_apple_silicon; then
        print_status "Architecture: Apple Silicon (ARM64)"
    else
        print_status "Architecture: Intel (x86_64)"
    fi

    # Check hardware type
    if is_laptop; then
        print_status "Hardware: MacBook (portable)"
    else
        print_status "Hardware: Desktop Mac"
    fi

    # Get dotfiles directory
    local dotfiles_dir
    if dotfiles_dir=$(get_dotfiles_dir); then
        print_status "Dotfiles directory: ${dotfiles_dir}"
    else
        print_error "Could not determine dotfiles directory"
        return 1
    fi

    # Check user
    print_status "User: $(get_real_user)"
    if is_root; then
        print_warning "Running with root privileges"
    fi

    # Check if in CI
    if is_ci; then
        print_status "Running in CI environment"
    fi
}

#######################################
# Example: Command availability checks
#######################################
check_dependencies() {
    print_section "Dependency Checks"

    local required_commands=("bash" "git")
    local optional_commands=("stow" "brew" "curl" "wget")
    local missing=0

    # Check required commands
    print_subsection "Required Commands"
    for cmd in "${required_commands[@]}"; do
        if command_exists "${cmd}"; then
            print_success "${cmd} is installed"
        else
            print_error "${cmd} is missing (required)"
            missing=$((missing + 1))
        fi
    done

    # Check optional commands
    print_subsection "Optional Commands"
    for cmd in "${optional_commands[@]}"; do
        if command_exists "${cmd}"; then
            print_success "${cmd} is installed"
        else
            print_warning "${cmd} is not installed (optional)"
        fi
    done

    if [[ ${missing} -gt 0 ]]; then
        print_error "Missing ${missing} required command(s)"
        return 1
    fi

    return 0
}

#######################################
# Example: File operations
#######################################
file_operations() {
    print_section "File Operations Examples"

    # Create a test directory
    local test_dir="${HOME}/.dotfiles-test"
    print_status "Creating test directory: ${test_dir}"
    if ensure_dir "${test_dir}"; then
        print_success "Directory created/verified"
    fi

    # Create a test file
    local test_file="${test_dir}/example.txt"
    echo "Test content" > "${test_file}"
    print_status "Created test file: ${test_file}"

    # Create backup
    print_status "Creating backup of test file"
    if create_backup "${test_file}"; then
        print_success "Backup created"
    fi

    # List backups
    print_status "Backup files:"
    ls -lh "${test_dir}"/example.txt.backup-* 2>/dev/null || print_warning "No backups found"

    # Clean up
    print_status "Cleaning up test directory"
    rm -rf "${test_dir}"
}

#######################################
# Example: Symlink management
#######################################
symlink_operations() {
    print_section "Symlink Operations Examples"

    local test_dir="${HOME}/.dotfiles-symlink-test"
    ensure_dir "${test_dir}"

    # Create source file
    local source="${test_dir}/source.txt"
    echo "Source content" > "${source}"

    # Create safe symlink
    local target="${test_dir}/link.txt"
    print_status "Creating symlink: ${target} -> ${source}"
    if safe_symlink "${source}" "${target}"; then
        print_success "Symlink created"
    fi

    # Verify symlink
    if [[ -L "${target}" ]]; then
        print_success "Symlink verified: $(readlink "${target}")"
    fi

    # Clean up
    rm -rf "${test_dir}"
}

#######################################
# Example: User interaction
#######################################
user_interaction() {
    print_section "User Interaction Examples"

    # Ask for confirmation
    if confirm "Do you want to see a success message?" "y"; then
        print_success "You answered yes!"
    else
        print_status "You answered no"
    fi

    # Ask with default no
    if confirm "Do you want to see a warning?" "n"; then
        print_warning "This is a warning!"
    else
        print_status "Warning skipped"
    fi
}

#######################################
# Example: Stow operations (dry-run, no actual stowing)
#######################################
stow_operations() {
    print_section "Stow Operations Examples"

    # Check if stow is installed
    if ensure_stow_installed; then
        print_success "GNU Stow is available"

        # List currently stowed packages
        list_stowed_packages

        # Example: Would stow a package (commented out to avoid changes)
        # print_status "To stow a package, use:"
        # print_status '  stow_package "zsh"'
        # print_status "To unstow a package, use:"
        # print_status '  unstow_package "zsh"'
        # print_status "To restow all packages, use:"
        # print_status '  restow_all'

        print_status "Stow operations ready"
    else
        print_warning "GNU Stow is not installed"
        print_status "Install with: brew install stow"
    fi
}

#######################################
# Example: Version comparison
#######################################
version_operations() {
    print_section "Version Comparison Examples"

    local v1="1.2.3"
    local v2="1.2.4"

    print_status "Comparing versions: ${v1} vs ${v2}"
    local result
    version_compare "${v1}" "${v2}" || result=$?

    case ${result} in
        0)
            print_status "${v1} == ${v2}"
            ;;
        1)
            print_status "${v1} < ${v2}"
            ;;
        2)
            print_status "${v1} > ${v2}"
            ;;
    esac

    # Check macOS version
    if is_macos; then
        local current_version
        current_version=$(get_macos_version)
        print_status "Current macOS version: ${current_version}"

        local ver_result
        version_compare "${current_version}" "14.0" || ver_result=$?
        case ${ver_result:-0} in
            0|2)
                print_success "macOS version is 14.0 or higher"
                ;;
            1)
                print_warning "macOS version is below 14.0"
                ;;
        esac
    fi
}

#######################################
# Example: Debug mode
#######################################
debug_example() {
    print_section "Debug Mode Example"

    print_status "Debug is currently: ${DEBUG:-0}"

    DEBUG=0
    print_debug "This will NOT appear (DEBUG=0)"

    DEBUG=1
    print_debug "This WILL appear (DEBUG=1)"
    print_debug "Debug messages are useful for troubleshooting"

    # Reset
    DEBUG=0
}

#######################################
# Example: Logging to file
#######################################
logging_example() {
    print_section "Logging Example"

    # Show current log file
    print_status "Log file: ${LOG_FILE}"

    if [[ -f "${LOG_FILE}" ]]; then
        print_success "Log file exists"
        print_status "Last 5 log entries:"
        tail -5 "${LOG_FILE}" | while IFS= read -r line; do
            echo "  ${line}"
        done
    else
        print_status "Log file will be created on first log entry"
    fi
}

#######################################
# Main function
#######################################
main() {
    print_section "Dotfiles Library Examples"
    print_status "This script demonstrates all library functions"
    print_warning "No actual changes will be made to your system"
    echo ""

    # Run all examples
    system_info
    check_dependencies
    file_operations
    symlink_operations
    version_operations
    debug_example
    stow_operations
    logging_example

    # Interactive example (optional)
    if confirm "Run interactive user interaction example?" "n"; then
        user_interaction
    fi

    print_section "Examples Complete"
    print_success "All library functions demonstrated successfully!"
    print_status "Review the source code to see how each function is used"
    print_status "Edit this script to experiment with different functions"
}

# Run main function
main "$@"
