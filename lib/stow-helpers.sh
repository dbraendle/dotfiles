#!/usr/bin/env bash
# stow-helpers.sh - GNU Stow helper functions for dotfiles management
# Provides functions to manage dotfiles packages using GNU Stow
# Usage: source this file after sourcing utils.sh

# Get the directory where this library is located (use unique var name to avoid conflicts)
STOW_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
# shellcheck source=./logging.sh
source "${STOW_LIB_DIR}/logging.sh"
# shellcheck source=./utils.sh
source "${STOW_LIB_DIR}/utils.sh"

# File to track stowed modules
DOTFILES_MODULES="${HOME}/.dotfiles-modules"

#######################################
# Ensure GNU Stow is installed
# Returns:
#   0 if stow is installed, 1 otherwise
#######################################
ensure_stow_installed() {
    if ! command_exists stow; then
        print_error "GNU Stow is not installed"
        if is_macos; then
            print_status "Install with: brew install stow"
        fi
        return 1
    fi
    print_debug "GNU Stow is installed: $(command -v stow)"
    return 0
}

#######################################
# Get the dotfiles directory for Stow operations
# Returns:
#   0 if found, 1 otherwise
# Outputs:
#   Writes dotfiles directory path to stdout (points to config/ subdirectory)
#######################################
get_stow_dir() {
    local dotfiles_dir
    dotfiles_dir="$(get_dotfiles_dir)" || return 1

    # Stow packages are in the config/ subdirectory
    local stow_packages_dir="${dotfiles_dir}/config"

    if [[ ! -d "${stow_packages_dir}" ]]; then
        print_error "Stow packages directory not found: ${stow_packages_dir}"
        return 1
    fi

    echo "${stow_packages_dir}"
}

#######################################
# Check if a package directory exists
# Arguments:
#   $1 - Package name
# Returns:
#   0 if package directory exists, 1 otherwise
#######################################
package_exists() {
    local package="$1"
    local dotfiles_dir
    dotfiles_dir="$(get_stow_dir)" || return 1

    if [[ -d "${dotfiles_dir}/${package}" ]]; then
        return 0
    else
        print_error "Package directory does not exist: ${dotfiles_dir}/${package}"
        return 1
    fi
}

#######################################
# Add a module to the tracking file
# Arguments:
#   $1 - Module/package name
#######################################
add_to_modules() {
    local module="$1"

    # Create file if it doesn't exist
    touch "${DOTFILES_MODULES}"

    # Add module if not already present
    if ! grep -q "^${module}$" "${DOTFILES_MODULES}" 2>/dev/null; then
        echo "${module}" >> "${DOTFILES_MODULES}"
        print_debug "Added ${module} to ${DOTFILES_MODULES}"
    fi
}

#######################################
# Remove a module from the tracking file
# Arguments:
#   $1 - Module/package name
#######################################
remove_from_modules() {
    local module="$1"

    if [[ -f "${DOTFILES_MODULES}" ]]; then
        # Create temp file and filter out the module
        local temp_file
        temp_file="$(mktemp)"
        grep -v "^${module}$" "${DOTFILES_MODULES}" > "${temp_file}" 2>/dev/null || true
        mv "${temp_file}" "${DOTFILES_MODULES}"
        print_debug "Removed ${module} from ${DOTFILES_MODULES}"
    fi
}

#######################################
# Backup existing files before stowing
# Arguments:
#   $1 - Package name
#   $2 - Dotfiles directory
# Returns:
#   0 if successful or no conflicts, 1 on error
#######################################
backup_conflicts() {
    local package="$1"
    local dotfiles_dir="$2"
    local package_dir="${dotfiles_dir}/${package}"

    if [[ ! -d "${package_dir}" ]]; then
        return 0
    fi

    print_debug "Checking for conflicts with package: ${package}"

    # Find all files in the package
    while IFS= read -r -d '' file; do
        # Get relative path from package directory
        local rel_path="${file#${package_dir}/}"
        local target="${HOME}/${rel_path}"

        # If target exists and is not a symlink to our file, back it up
        if [[ -e "${target}" || -L "${target}" ]]; then
            local source="${package_dir}/${rel_path}"
            if [[ ! -L "${target}" ]] || [[ "$(readlink "${target}")" != "${source}" ]]; then
                print_warning "Backing up existing file: ${target}"
                create_backup "${target}" || return 1
                # Remove the original file so stow can create symlink
                rm -rf "${target}"
                print_debug "Removed ${target} after backup"
            fi
        fi
    done < <(find "${package_dir}" -type f -print0)

    return 0
}

#######################################
# Stow a package with error handling and backup
# Arguments:
#   $1 - Package name
#   $2 - Additional stow options (optional)
# Returns:
#   0 if successful, 1 otherwise
# Outputs:
#   Status messages about the stowing operation
#######################################
stow_package() {
    local package="$1"
    local stow_opts="${2:-}"

    if [[ -z "${package}" ]]; then
        print_error "stow_package: No package name specified"
        return 1
    fi

    # Ensure stow is installed
    ensure_stow_installed || return 1

    # Get dotfiles directory
    local dotfiles_dir
    dotfiles_dir="$(get_stow_dir)" || return 1

    # Check if package exists
    package_exists "${package}" || return 1

    print_status "Stowing package: ${package}"

    # Backup any conflicting files
    if ! backup_conflicts "${package}" "${dotfiles_dir}"; then
        print_error "Failed to backup conflicts for ${package}"
        return 1
    fi

    # Remove existing symlinks that might conflict
    # This handles the case where files were manually removed from the package
    print_debug "Cleaning up any existing stow symlinks for ${package}"
    stow --dir="${dotfiles_dir}" --target="${HOME}" --delete "${package}" 2>/dev/null || true

    # Stow the package
    print_debug "Running: stow --dir=${dotfiles_dir} --target=${HOME} ${stow_opts} ${package}"

    local stow_output
    if stow_output=$(stow --dir="${dotfiles_dir}" --target="${HOME}" ${stow_opts} --verbose=1 "${package}" 2>&1); then
        print_success "Successfully stowed: ${package}"
        add_to_modules "${package}"

        # Show what was stowed if in debug mode
        if [[ "${DEBUG}" == "1" && -n "${stow_output}" ]]; then
            print_debug "Stow output:\n${stow_output}"
        fi

        return 0
    else
        print_error "Failed to stow ${package}"
        print_error "Stow output:\n${stow_output}"
        return 1
    fi
}

#######################################
# Unstow a package
# Arguments:
#   $1 - Package name
# Returns:
#   0 if successful, 1 otherwise
# Outputs:
#   Status messages about the unstowing operation
#######################################
unstow_package() {
    local package="$1"

    if [[ -z "${package}" ]]; then
        print_error "unstow_package: No package name specified"
        return 1
    fi

    # Ensure stow is installed
    ensure_stow_installed || return 1

    # Get dotfiles directory
    local dotfiles_dir
    dotfiles_dir="$(get_stow_dir)" || return 1

    # Check if package exists
    if ! package_exists "${package}"; then
        print_warning "Package directory does not exist: ${package}"
        print_warning "Attempting to unstow anyway (may have been moved/deleted)"
    fi

    print_status "Unstowing package: ${package}"

    # Unstow the package
    print_debug "Running: stow --dir=${dotfiles_dir} --target=${HOME} --delete ${package}"

    local stow_output
    if stow_output=$(stow --dir="${dotfiles_dir}" --target="${HOME}" --delete --verbose=1 "${package}" 2>&1); then
        print_success "Successfully unstowed: ${package}"
        remove_from_modules "${package}"

        # Show what was unstowed if in debug mode
        if [[ "${DEBUG}" == "1" && -n "${stow_output}" ]]; then
            print_debug "Stow output:\n${stow_output}"
        fi

        return 0
    else
        print_error "Failed to unstow ${package}"
        print_error "Stow output:\n${stow_output}"
        return 1
    fi
}

#######################################
# Restow a single package (unstow then stow)
# Useful for updating after changes to the package
# Arguments:
#   $1 - Package name
# Returns:
#   0 if successful, 1 otherwise
#######################################
restow_package() {
    local package="$1"

    if [[ -z "${package}" ]]; then
        print_error "restow_package: No package name specified"
        return 1
    fi

    # Ensure stow is installed
    ensure_stow_installed || return 1

    # Get dotfiles directory
    local dotfiles_dir
    dotfiles_dir="$(get_stow_dir)" || return 1

    # Check if package exists
    package_exists "${package}" || return 1

    print_status "Restowing package: ${package}"

    # Restow using stow's --restow option
    print_debug "Running: stow --dir=${dotfiles_dir} --target=${HOME} --restow ${package}"

    local stow_output
    if stow_output=$(stow --dir="${dotfiles_dir}" --target="${HOME}" --restow --verbose=1 "${package}" 2>&1); then
        print_success "Successfully restowed: ${package}"

        # Show what was restowed if in debug mode
        if [[ "${DEBUG}" == "1" && -n "${stow_output}" ]]; then
            print_debug "Stow output:\n${stow_output}"
        fi

        return 0
    else
        print_error "Failed to restow ${package}"
        print_error "Stow output:\n${stow_output}"
        return 1
    fi
}

#######################################
# Restow all active modules from the tracking file
# Returns:
#   0 if all successful, 1 if any failed
# Outputs:
#   Status messages for each module
#######################################
restow_all() {
    if [[ ! -f "${DOTFILES_MODULES}" ]]; then
        print_warning "No modules file found at ${DOTFILES_MODULES}"
        print_status "No packages to restow"
        return 0
    fi

    print_section "Restowing All Active Modules"

    local failed=0
    local count=0

    while IFS= read -r module; do
        # Skip empty lines and comments
        [[ -z "${module}" || "${module}" =~ ^# ]] && continue

        count=$((count + 1))
        if ! restow_package "${module}"; then
            failed=$((failed + 1))
            print_error "Failed to restow: ${module}"
        fi
    done < "${DOTFILES_MODULES}"

    echo ""
    if [[ ${failed} -eq 0 ]]; then
        print_success "Successfully restowed ${count} package(s)"
        return 0
    else
        print_error "Failed to restow ${failed} of ${count} package(s)"
        return 1
    fi
}

#######################################
# List all currently stowed packages
# Outputs:
#   List of stowed package names
#######################################
list_stowed_packages() {
    if [[ ! -f "${DOTFILES_MODULES}" ]]; then
        print_warning "No modules file found at ${DOTFILES_MODULES}"
        return 0
    fi

    print_section "Currently Stowed Packages"

    local count=0
    while IFS= read -r module; do
        # Skip empty lines and comments
        [[ -z "${module}" || "${module}" =~ ^# ]] && continue

        count=$((count + 1))
        echo "  ${count}. ${module}"
    done < "${DOTFILES_MODULES}"

    if [[ ${count} -eq 0 ]]; then
        print_status "No packages are currently stowed"
    else
        echo ""
        print_status "Total: ${count} package(s)"
    fi
}

#######################################
# Adopt existing files into a package
# This moves existing files into the dotfiles package and creates symlinks
# Arguments:
#   $1 - Package name
# Returns:
#   0 if successful, 1 otherwise
#######################################
adopt_package() {
    local package="$1"

    if [[ -z "${package}" ]]; then
        print_error "adopt_package: No package name specified"
        return 1
    fi

    # Ensure stow is installed
    ensure_stow_installed || return 1

    # Get dotfiles directory
    local dotfiles_dir
    dotfiles_dir="$(get_stow_dir)" || return 1

    # Check if package exists
    package_exists "${package}" || return 1

    print_status "Adopting existing files for package: ${package}"
    print_warning "This will move existing files into ${dotfiles_dir}/${package}"

    if ! confirm "Continue with adoption?"; then
        print_status "Adoption cancelled"
        return 0
    fi

    # Use stow's --adopt option
    print_debug "Running: stow --dir=${dotfiles_dir} --target=${HOME} --adopt ${package}"

    local stow_output
    if stow_output=$(stow --dir="${dotfiles_dir}" --target="${HOME}" --adopt --verbose=1 "${package}" 2>&1); then
        print_success "Successfully adopted: ${package}"
        add_to_modules "${package}"

        # Show what was adopted if in debug mode
        if [[ "${DEBUG}" == "1" && -n "${stow_output}" ]]; then
            print_debug "Stow output:\n${stow_output}"
        fi

        print_warning "Review changes in ${dotfiles_dir}/${package} before committing"
        return 0
    else
        print_error "Failed to adopt ${package}"
        print_error "Stow output:\n${stow_output}"
        return 1
    fi
}
