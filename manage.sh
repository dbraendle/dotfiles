#!/usr/bin/env bash
# manage.sh - Module management CLI tool for Dotfiles V2
# Provides commands to manage modules, profiles, and system configuration
set -euo pipefail

# Get the directory where this script is located
MANAGE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="${MANAGE_SCRIPT_DIR}"

# Source libraries
# Note: logging.sh will source colors.sh and utils.sh automatically
# shellcheck source=./lib/logging.sh
source "${MANAGE_SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=./lib/stow-helpers.sh
source "${MANAGE_SCRIPT_DIR}/lib/stow-helpers.sh"
# shellcheck source=./lib/module-validator.sh
source "${MANAGE_SCRIPT_DIR}/lib/module-validator.sh"

# Configuration files
readonly DOTFILES_MODULES="${HOME}/.dotfiles-modules"
readonly DOTFILES_PROFILE="${HOME}/.dotfiles-profile"
readonly MODULES_DIR="${DOTFILES_DIR}/modules"
readonly PROFILES_DIR="${DOTFILES_DIR}/profiles"

# Version
readonly VERSION="2.0.0"

#######################################
# Get current profile
# Returns profile name or "unknown"
#######################################
get_current_profile() {
    if [[ -f "${DOTFILES_PROFILE}" ]]; then
        cat "${DOTFILES_PROFILE}"
    else
        echo "unknown"
    fi
}

#######################################
# Set current profile
# Arguments:
#   $1 - Profile name (desktop|laptop)
#######################################
set_current_profile() {
    local profile="$1"
    echo "${profile}" > "${DOTFILES_PROFILE}"
}

#######################################
# Check if module is active
# Arguments:
#   $1 - Module name
# Returns:
#   0 if active, 1 otherwise
#######################################
is_module_active() {
    local module="$1"

    if [[ ! -f "${DOTFILES_MODULES}" ]]; then
        return 1
    fi

    grep -q "^${module}$" "${DOTFILES_MODULES}" 2>/dev/null
}

#######################################
# Get module version
# Arguments:
#   $1 - Module name
# Returns version string
#######################################
get_module_version() {
    local module="$1"
    local module_file="${MODULES_DIR}/${module}/module.json"

    if [[ -f "${module_file}" ]] && command_exists jq; then
        jq -r '.version // "1.0.0"' "${module_file}" 2>/dev/null || echo "1.0.0"
    else
        echo "1.0.0"
    fi
}

#######################################
# Get module category
# Arguments:
#   $1 - Module name
# Returns category string
#######################################
get_module_category() {
    local module="$1"
    local module_file="${MODULES_DIR}/${module}/module.json"

    if [[ -f "${module_file}" ]] && command_exists jq; then
        jq -r '.category // "optional"' "${module_file}" 2>/dev/null || echo "optional"
    else
        echo "optional"
    fi
}

#######################################
# List all available modules
#######################################
cmd_modules_list() {
    print_section "Available Modules"

    if [[ ! -d "${MODULES_DIR}" ]]; then
        print_error "Modules directory not found: ${MODULES_DIR}"
        return 1
    fi

    # Check if any modules exist
    local module_count=0
    module_count=$(find "${MODULES_DIR}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

    if [[ ${module_count} -eq 0 ]]; then
        print_warning "No modules found in ${MODULES_DIR}"
        echo ""
        echo "Modules should be located in: ${MODULES_DIR}/<module-name>/module.json"
        return 0
    fi

    # Group modules by category
    local core_modules=""
    local optional_modules=""
    local experimental_modules=""

    # Collect all modules
    while IFS= read -r -d '' module_dir; do
        local module_name
        module_name=$(basename "${module_dir}")

        local category
        category=$(get_module_category "${module_name}")

        local status_symbol="○"
        local status_text="INACTIVE"
        local status_color="${DIM}"

        if is_module_active "${module_name}"; then
            status_symbol="●"
            status_text="ACTIVE"
            status_color="${BOLD_GREEN}"
        fi

        local description=""
        local module_file="${module_dir}/module.json"
        if [[ -f "${module_file}" ]] && command_exists jq; then
            description=$(jq -r '.description // "No description"' "${module_file}" 2>/dev/null || echo "No description")
        else
            description="No description"
        fi

        local line
        line=$(printf "  %b%s%b %s - %s [%b%s%b]\n" \
            "${status_color}" "${status_symbol}" "${NC}" \
            "${module_name}" "${description}" \
            "${status_color}" "${status_text}" "${NC}")

        case "${category}" in
            core)
                core_modules+="${line}"
                ;;
            optional)
                optional_modules+="${line}"
                ;;
            experimental)
                experimental_modules+="${line}"
                ;;
        esac
    done < <(find "${MODULES_DIR}" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    # Display by category
    if [[ -n "${core_modules}" ]]; then
        echo -e "\n${BOLD}Core Modules${NC} (always available):"
        echo -e "${core_modules}"
    fi

    if [[ -n "${optional_modules}" ]]; then
        echo -e "\n${BOLD}Optional Modules:${NC}"
        echo -e "${optional_modules}"
    fi

    if [[ -n "${experimental_modules}" ]]; then
        echo -e "\n${BOLD}Experimental Modules:${NC}"
        echo -e "${experimental_modules}"
    fi

    echo -e "\n${BOLD}Legend:${NC} ${BOLD_GREEN}●${NC} Active  ${DIM}○${NC} Inactive"
    echo ""
}

#######################################
# Show status of active modules
#######################################
cmd_modules_status() {
    local current_profile
    current_profile=$(get_current_profile)

    print_section "Module Status"

    echo -e "${BOLD}Current Profile:${NC} ${current_profile}"

    # Count active modules
    local active_count=0
    if [[ -f "${DOTFILES_MODULES}" ]]; then
        active_count=$(grep -c "^[^#]" "${DOTFILES_MODULES}" 2>/dev/null || true)
        # grep -c returns 0 when no matches, but we want 0 as a number not exit code
        active_count=${active_count:-0}
    fi

    echo -e "${BOLD}Active Modules:${NC} ${active_count}"
    echo ""

    if [[ "${active_count}" -eq 0 ]]; then
        print_warning "No modules are currently active"
        echo ""
        echo "Run './manage.sh modules list' to see available modules"
        echo "Run './manage.sh modules enable <name>' to activate a module"
        return 0
    fi

    # Group by category
    local core_modules=""
    local optional_modules=""

    while IFS= read -r module; do
        [[ -z "${module}" || "${module}" =~ ^# ]] && continue

        local category
        category=$(get_module_category "${module}")

        local version
        version=$(get_module_version "${module}")

        local line="  ${BOLD_GREEN}✓${NC} ${module} (v${version})\n"

        if [[ "${category}" == "core" ]]; then
            core_modules+="${line}"
        else
            optional_modules+="${line}"
        fi
    done < "${DOTFILES_MODULES}"

    # Display core modules
    if [[ -n "${core_modules}" ]]; then
        echo -e "${BOLD}Core:${NC}"
        echo -e "${core_modules}"
    fi

    # Display optional modules
    if [[ -n "${optional_modules}" ]]; then
        echo -e "${BOLD}Optional:${NC}"
        echo -e "${optional_modules}"
    fi

    echo "Run './manage.sh modules list' to see all available modules"
    echo ""
}

#######################################
# Enable/install a module
# Arguments:
#   $1 - Module name
#######################################
cmd_modules_enable() {
    local module="$1"

    if [[ -z "${module}" ]]; then
        print_error "Module name required"
        echo "Usage: ./manage.sh modules enable <name>"
        return 1
    fi

    # Check if module exists
    if ! module_exists "${module}"; then
        print_error "Module not found: ${module}"
        echo ""
        echo "Available modules:"
        cmd_modules_list
        return 1
    fi

    # Check if already active
    if is_module_active "${module}"; then
        print_warning "Module '${module}' is already active"
        return 0
    fi

    print_section "Enabling Module: ${module}"

    # Get module info
    local module_file="${MODULES_DIR}/${module}/module.json"
    local description=""

    if command_exists jq && [[ -f "${module_file}" ]]; then
        description=$(jq -r '.description // ""' "${module_file}" 2>/dev/null || echo "")
        if [[ -n "${description}" ]]; then
            echo -e "${BOLD}Description:${NC} ${description}"
            echo ""
        fi
    fi

    # Check profile compatibility
    local current_profile
    current_profile=$(get_current_profile)

    if [[ "${current_profile}" != "unknown" ]]; then
        if ! module_supports_profile "${module}" "${current_profile}" 2>/dev/null; then
            print_warning "Module '${module}' may not be optimized for profile '${current_profile}'"
            if ! confirm "Continue anyway?" "n"; then
                print_status "Installation cancelled"
                return 0
            fi
        fi
    fi

    # Check and install dependencies
    local dependencies
    if command_exists jq && [[ -f "${module_file}" ]]; then
        dependencies=$(jq -r '.dependencies[]? // empty' "${module_file}" 2>/dev/null || true)

        if [[ -n "${dependencies}" ]]; then
            print_subsection "Checking Dependencies"

            local missing_deps=()
            while IFS= read -r dep; do
                [[ -z "${dep}" ]] && continue

                if ! is_module_active "${dep}"; then
                    missing_deps+=("${dep}")
                    print_warning "Required dependency not active: ${dep}"
                fi
            done <<< "${dependencies}"

            if [[ ${#missing_deps[@]} -gt 0 ]]; then
                echo ""
                echo "The following dependencies are required:"
                for dep in "${missing_deps[@]}"; do
                    echo "  - ${dep}"
                done
                echo ""

                if confirm "Install missing dependencies?" "y"; then
                    for dep in "${missing_deps[@]}"; do
                        if ! cmd_modules_enable "${dep}"; then
                            print_error "Failed to install dependency: ${dep}"
                            return 1
                        fi
                    done
                else
                    print_error "Cannot install module without dependencies"
                    return 1
                fi
            fi
        fi
    fi

    # Run install script
    local install_script="${MODULES_DIR}/${module}/install.sh"

    if [[ -f "${install_script}" ]]; then
        print_subsection "Running Install Script"

        if [[ ! -x "${install_script}" ]]; then
            print_warning "Making install script executable"
            chmod +x "${install_script}"
        fi

        if "${install_script}"; then
            print_success "Install script completed successfully"
        else
            print_error "Install script failed"
            return 1
        fi
    else
        print_debug "No install script found for ${module}"
    fi

    # Stow packages if specified
    if command_exists jq && [[ -f "${module_file}" ]]; then
        local stow_packages
        stow_packages=$(jq -r '.stow_packages[]? // empty' "${module_file}" 2>/dev/null || true)

        if [[ -n "${stow_packages}" ]]; then
            print_subsection "Stowing Packages"

            while IFS= read -r package; do
                [[ -z "${package}" ]] && continue

                if stow_package "${package}"; then
                    print_success "Stowed package: ${package}"
                else
                    print_error "Failed to stow package: ${package}"
                    return 1
                fi
            done <<< "${stow_packages}"
        fi
    fi

    # Add to active modules
    add_to_modules "${module}"

    echo ""
    print_success "Module '${module}' has been enabled successfully"
    log_to_file "MODULE_ENABLE" "Enabled module: ${module}"
    echo ""
}

#######################################
# Disable/uninstall a module
# Arguments:
#   $1 - Module name
#######################################
cmd_modules_disable() {
    local module="$1"

    if [[ -z "${module}" ]]; then
        print_error "Module name required"
        echo "Usage: ./manage.sh modules disable <name>"
        return 1
    fi

    # Check if module is active
    if ! is_module_active "${module}"; then
        print_warning "Module '${module}' is not active"
        return 0
    fi

    print_section "Disabling Module: ${module}"

    # Check if other modules depend on this one
    if [[ -f "${DOTFILES_MODULES}" ]]; then
        local dependents=()

        while IFS= read -r active_module; do
            [[ -z "${active_module}" || "${active_module}" =~ ^# ]] && continue
            [[ "${active_module}" == "${module}" ]] && continue

            local module_file="${MODULES_DIR}/${active_module}/module.json"
            if [[ -f "${module_file}" ]] && command_exists jq; then
                local deps
                deps=$(jq -r ".dependencies[]? // empty" "${module_file}" 2>/dev/null || true)

                if echo "${deps}" | grep -q "^${module}$"; then
                    dependents+=("${active_module}")
                fi
            fi
        done < "${DOTFILES_MODULES}"

        if [[ ${#dependents[@]} -gt 0 ]]; then
            print_error "Cannot disable module '${module}' - other modules depend on it:"
            for dep in "${dependents[@]}"; do
                echo "  - ${dep}"
            done
            echo ""
            echo "Disable these modules first, or use --force to override"
            return 1
        fi
    fi

    # Confirm uninstallation
    echo -e "${BOLD_YELLOW}Warning:${NC} This will uninstall the module and remove its configuration."
    if ! confirm "Continue with uninstallation?" "n"; then
        print_status "Uninstallation cancelled"
        return 0
    fi

    # Unstow packages if specified
    local module_file="${MODULES_DIR}/${module}/module.json"
    if command_exists jq && [[ -f "${module_file}" ]]; then
        local stow_packages
        stow_packages=$(jq -r '.stow_packages[]? // empty' "${module_file}" 2>/dev/null || true)

        if [[ -n "${stow_packages}" ]]; then
            print_subsection "Unstowing Packages"

            while IFS= read -r package; do
                [[ -z "${package}" ]] && continue

                if unstow_package "${package}"; then
                    print_success "Unstowed package: ${package}"
                else
                    print_warning "Failed to unstow package: ${package}"
                fi
            done <<< "${stow_packages}"
        fi
    fi

    # Run uninstall script
    local uninstall_script="${MODULES_DIR}/${module}/uninstall.sh"

    if [[ -f "${uninstall_script}" ]]; then
        print_subsection "Running Uninstall Script"

        if [[ ! -x "${uninstall_script}" ]]; then
            print_warning "Making uninstall script executable"
            chmod +x "${uninstall_script}"
        fi

        if "${uninstall_script}"; then
            print_success "Uninstall script completed successfully"
        else
            print_warning "Uninstall script failed (continuing anyway)"
        fi
    else
        print_debug "No uninstall script found for ${module}"
    fi

    # Remove from active modules
    remove_from_modules "${module}"

    echo ""
    print_success "Module '${module}' has been disabled successfully"
    log_to_file "MODULE_DISABLE" "Disabled module: ${module}"
    echo ""
}

#######################################
# Show module information
# Arguments:
#   $1 - Module name
#######################################
cmd_modules_info() {
    local module="$1"

    if [[ -z "${module}" ]]; then
        print_error "Module name required"
        echo "Usage: ./manage.sh modules info <name>"
        return 1
    fi

    # Check if module exists
    if ! module_exists "${module}"; then
        print_error "Module not found: ${module}"
        return 1
    fi

    local module_file="${MODULES_DIR}/${module}/module.json"

    print_section "Module: ${module}"

    if ! command_exists jq; then
        print_error "jq is required for module info"
        print_status "Install with: brew install jq"
        return 1
    fi

    # Basic info
    local description category version
    description=$(jq -r '.description // "No description"' "${module_file}" 2>/dev/null)
    category=$(jq -r '.category // "optional"' "${module_file}" 2>/dev/null)
    version=$(jq -r '.version // "1.0.0"' "${module_file}" 2>/dev/null)

    echo -e "${BOLD}Description:${NC} ${description}"
    echo -e "${BOLD}Category:${NC} ${category}"
    echo -e "${BOLD}Version:${NC} ${version}"

    # Status
    if is_module_active "${module}"; then
        echo -e "${BOLD}Status:${NC} ${BOLD_GREEN}ACTIVE${NC}"
    else
        echo -e "${BOLD}Status:${NC} ${DIM}INACTIVE${NC}"
    fi
    echo ""

    # Dependencies
    local dependencies
    dependencies=$(jq -r '.dependencies[]? // empty' "${module_file}" 2>/dev/null || true)

    if [[ -n "${dependencies}" ]]; then
        echo -e "${BOLD}Dependencies:${NC}"
        while IFS= read -r dep; do
            [[ -z "${dep}" ]] && continue

            if is_module_active "${dep}"; then
                echo -e "  ${BOLD_GREEN}✓${NC} ${dep} (installed)"
            else
                echo -e "  ${BOLD_RED}✗${NC} ${dep} (not installed)"
            fi
        done <<< "${dependencies}"
        echo ""
    fi

    # Stow packages
    local stow_packages
    stow_packages=$(jq -r '.stow_packages[]? // empty' "${module_file}" 2>/dev/null || true)

    if [[ -n "${stow_packages}" ]]; then
        echo -e "${BOLD}Stow Packages:${NC}"
        while IFS= read -r package; do
            [[ -z "${package}" ]] && continue
            echo "  - ${package}"
        done <<< "${stow_packages}"
        echo ""
    fi

    # Profiles
    local profiles
    profiles=$(jq -r '.profiles[]? // empty' "${module_file}" 2>/dev/null || true)

    if [[ -n "${profiles}" ]]; then
        echo -e "${BOLD}Profiles:${NC}"
        local current_profile
        current_profile=$(get_current_profile)

        while IFS= read -r profile; do
            [[ -z "${profile}" ]] && continue

            if [[ "${profile}" == "${current_profile}" ]]; then
                echo -e "  ${BOLD_GREEN}✓${NC} ${profile} (current)"
            else
                echo "  ✓ ${profile}"
            fi
        done <<< "${profiles}"
        echo ""
    else
        echo -e "${BOLD}Profiles:${NC} All profiles supported"
        echo ""
    fi

    # Scripts
    echo -e "${BOLD}Scripts:${NC}"
    local install_script="${MODULES_DIR}/${module}/install.sh"
    local uninstall_script="${MODULES_DIR}/${module}/uninstall.sh"

    if [[ -f "${install_script}" ]]; then
        echo "  • Install: modules/${module}/install.sh"
    fi

    if [[ -f "${uninstall_script}" ]]; then
        echo "  • Uninstall: modules/${module}/uninstall.sh"
    fi

    echo ""

    # Action hints
    if is_module_active "${module}"; then
        echo "Run './manage.sh modules disable ${module}' to uninstall"
    else
        echo "Run './manage.sh modules enable ${module}' to install"
    fi

    echo ""
}

#######################################
# Update a specific module
# Arguments:
#   $1 - Module name
#######################################
cmd_modules_update() {
    local module="$1"

    if [[ -z "${module}" ]]; then
        print_error "Module name required"
        echo "Usage: ./manage.sh modules update <name>"
        return 1
    fi

    # Check if module is active
    if ! is_module_active "${module}"; then
        print_error "Module '${module}' is not active"
        echo "Enable it first with: ./manage.sh modules enable ${module}"
        return 1
    fi

    print_section "Updating Module: ${module}"

    # Check for update script
    local update_script="${MODULES_DIR}/${module}/update.sh"

    if [[ -f "${update_script}" ]]; then
        if [[ ! -x "${update_script}" ]]; then
            chmod +x "${update_script}"
        fi

        if "${update_script}"; then
            print_success "Module '${module}' updated successfully"
        else
            print_error "Update script failed for module '${module}'"
            return 1
        fi
    else
        # Re-run install script as fallback
        print_status "No update script found, re-running install script"
        local install_script="${MODULES_DIR}/${module}/install.sh"

        if [[ -f "${install_script}" ]]; then
            if "${install_script}"; then
                print_success "Module '${module}' updated successfully"
            else
                print_error "Install script failed for module '${module}'"
                return 1
            fi
        else
            print_warning "No update or install script found for module '${module}'"
        fi
    fi

    # Restow packages
    local module_file="${MODULES_DIR}/${module}/module.json"
    if command_exists jq && [[ -f "${module_file}" ]]; then
        local stow_packages
        stow_packages=$(jq -r '.stow_packages[]? // empty' "${module_file}" 2>/dev/null || true)

        if [[ -n "${stow_packages}" ]]; then
            print_subsection "Restowing Packages"

            while IFS= read -r package; do
                [[ -z "${package}" ]] && continue

                if restow_package "${package}"; then
                    print_success "Restowed package: ${package}"
                else
                    print_warning "Failed to restow package: ${package}"
                fi
            done <<< "${stow_packages}"
        fi
    fi

    log_to_file "MODULE_UPDATE" "Updated module: ${module}"
    echo ""
}

#######################################
# Update all active modules
#######################################
cmd_modules_update_all() {
    print_section "Updating All Active Modules"

    if [[ ! -f "${DOTFILES_MODULES}" ]]; then
        print_warning "No active modules found"
        return 0
    fi

    local total=0
    local success=0
    local failed=0

    while IFS= read -r module; do
        [[ -z "${module}" || "${module}" =~ ^# ]] && continue

        ((total++))
        echo ""

        if cmd_modules_update "${module}"; then
            ((success++))
        else
            ((failed++))
            print_error "Failed to update: ${module}"
        fi
    done < "${DOTFILES_MODULES}"

    echo ""
    print_section "Update Summary"
    echo "Total modules:      ${total}"
    echo "Updated:            ${success}"
    echo "Failed:             ${failed}"
    echo ""

    if [[ ${failed} -gt 0 ]]; then
        return 1
    fi
}

#######################################
# Show current profile information
#######################################
cmd_profile_info() {
    local current_profile
    current_profile=$(get_current_profile)

    print_section "Profile Information"

    if [[ "${current_profile}" == "unknown" ]]; then
        print_warning "No profile is currently set"
        echo ""
        echo "Set a profile with: ./manage.sh profile set <desktop|laptop>"
        return 0
    fi

    echo -e "${BOLD}Current Profile:${NC} ${current_profile}"
    echo ""

    # Load and display profile settings
    local profile_file="${PROFILES_DIR}/${current_profile}.sh"

    if [[ -f "${profile_file}" ]]; then
        echo -e "${BOLD}Profile Settings:${NC}"
        echo ""

        # Source the profile in a subshell to extract settings
        (
            source "${profile_file}"

            echo -e "${BOLD}Security:${NC}"
            echo "  Password after sleep: ${ENABLE_PASSWORD_AFTER_SLEEP}"
            echo ""

            echo -e "${BOLD}Power Management:${NC}"
            echo "  Display sleep: ${DISPLAY_SLEEP_MINUTES} minutes"
            echo "  System sleep: ${SYSTEM_SLEEP_MINUTES} minutes"
            echo "  Disk sleep: ${DISK_SLEEP_ENABLED}"
            echo ""

            echo -e "${BOLD}Features:${NC}"
            echo "  Printer module: ${ENABLE_PRINTER_MODULE}"
            echo "  Scanner module: ${ENABLE_SCANNER_MODULE}"
            echo "  Network mounts: ${ENABLE_NETWORK_MOUNTS}"
            echo "  Dock module: ${ENABLE_DOCK_MODULE}"
            echo ""

            if [[ -n "${PROFILE_OPTIMIZED_FOR:-}" ]]; then
                echo -e "${BOLD}Optimized for:${NC} ${PROFILE_OPTIMIZED_FOR}"
            fi
        )
    else
        print_warning "Profile file not found: ${profile_file}"
    fi

    echo ""
}

#######################################
# Set profile
# Arguments:
#   $1 - Profile name (desktop|laptop)
#######################################
cmd_profile_set() {
    local new_profile="$1"

    if [[ -z "${new_profile}" ]]; then
        print_error "Profile name required"
        echo "Usage: ./manage.sh profile set <desktop|laptop>"
        return 1
    fi

    # Validate profile
    if [[ ! "${new_profile}" =~ ^(desktop|laptop)$ ]]; then
        print_error "Invalid profile: ${new_profile}"
        echo "Valid profiles: desktop, laptop"
        return 1
    fi

    # Check if profile file exists
    local profile_file="${PROFILES_DIR}/${new_profile}.sh"
    if [[ ! -f "${profile_file}" ]]; then
        print_error "Profile file not found: ${profile_file}"
        return 1
    fi

    local current_profile
    current_profile=$(get_current_profile)

    if [[ "${current_profile}" == "${new_profile}" ]]; then
        print_warning "Profile '${new_profile}' is already active"
        return 0
    fi

    print_section "Changing Profile"

    echo -e "${BOLD}Current Profile:${NC} ${current_profile}"
    echo -e "${BOLD}New Profile:${NC} ${new_profile}"
    echo ""

    if [[ "${current_profile}" != "unknown" ]]; then
        if ! confirm "Change profile from '${current_profile}' to '${new_profile}'?" "y"; then
            print_status "Profile change cancelled"
            return 0
        fi
    fi

    # Set new profile
    set_current_profile "${new_profile}"
    print_success "Profile set to: ${new_profile}"
    log_to_file "PROFILE_CHANGE" "Changed profile from ${current_profile} to ${new_profile}"

    echo ""

    # Offer to re-apply system settings
    if command_exists jq && is_module_active "system" 2>/dev/null; then
        echo "The system settings module is active."
        if confirm "Re-apply system settings for the new profile?" "y"; then
            local system_script="${DOTFILES_DIR}/macos-settings.sh"
            if [[ -f "${system_script}" ]]; then
                print_status "Re-applying system settings..."
                "${system_script}" || print_warning "System settings script failed"
            fi
        fi
    fi

    echo ""
    print_status "Profile changed successfully"
    echo ""
    echo "Profile-specific modules may need to be re-enabled."
    echo "Run './manage.sh modules status' to check active modules."
    echo ""
}

#######################################
# List available profiles
#######################################
cmd_profile_list() {
    print_section "Available Profiles"

    if [[ ! -d "${PROFILES_DIR}" ]]; then
        print_error "Profiles directory not found: ${PROFILES_DIR}"
        return 1
    fi

    local current_profile
    current_profile=$(get_current_profile)

    echo -e "${BOLD}Current Profile:${NC} ${current_profile}"
    echo ""

    local count=0
    while IFS= read -r -d '' profile_file; do
        local profile_name
        profile_name=$(basename "${profile_file}" .sh)

        ((count++))

        # Load profile description
        local description=""
        if grep -q "^export PROFILE_DESCRIPTION=" "${profile_file}"; then
            description=$(grep "^export PROFILE_DESCRIPTION=" "${profile_file}" | cut -d'"' -f2)
        fi

        if [[ "${profile_name}" == "${current_profile}" ]]; then
            echo -e "  ${BOLD_GREEN}●${NC} ${BOLD}${profile_name}${NC} (current)"
        else
            echo -e "  ${DIM}○${NC} ${profile_name}"
        fi

        if [[ -n "${description}" ]]; then
            echo "    ${description}"
        fi
        echo ""
    done < <(find "${PROFILES_DIR}" -name "*.sh" -type f -print0 2>/dev/null | sort -z)

    if [[ ${count} -eq 0 ]]; then
        print_warning "No profiles found in ${PROFILES_DIR}"
    fi

    echo "Change profile with: ./manage.sh profile set <name>"
    echo ""
}

#######################################
# Check system requirements
#######################################
cmd_system_check() {
    print_section "System Requirements Check"

    local checks_passed=0
    local checks_failed=0

    # Check OS
    if is_macos; then
        print_success "Operating System: macOS $(get_macos_version)"
        ((checks_passed++))
    else
        print_error "Operating System: Not macOS"
        ((checks_failed++))
    fi

    # Check architecture
    if is_apple_silicon; then
        print_success "Architecture: Apple Silicon (ARM64)"
    else
        print_success "Architecture: Intel (x86_64)"
    fi
    ((checks_passed++))

    # Check device type
    if is_laptop; then
        print_success "Device Type: MacBook (Laptop)"
    else
        print_success "Device Type: Desktop Mac"
    fi
    ((checks_passed++))

    echo ""
    print_subsection "Required Tools"

    # Check for required commands
    local required_tools=("git" "stow" "jq")

    for tool in "${required_tools[@]}"; do
        if command_exists "${tool}"; then
            local version=""
            case "${tool}" in
                git)
                    version=$(git --version | cut -d' ' -f3)
                    ;;
                stow)
                    version=$(stow --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+' || echo "unknown")
                    ;;
                jq)
                    version=$(jq --version | cut -d'-' -f2)
                    ;;
            esac

            print_success "${tool} (${version})"
            ((checks_passed++))
        else
            print_error "${tool} - NOT INSTALLED"
            ((checks_failed++))

            case "${tool}" in
                git)
                    echo "  Install with: xcode-select --install"
                    ;;
                stow|jq)
                    echo "  Install with: brew install ${tool}"
                    ;;
            esac
        fi
    done

    echo ""
    print_subsection "Optional Tools"

    local optional_tools=("brew" "zsh" "curl" "wget")

    for tool in "${optional_tools[@]}"; do
        if command_exists "${tool}"; then
            print_success "${tool}"
        else
            print_warning "${tool} - not installed (optional)"
        fi
    done

    echo ""
    print_subsection "Directories"

    # Check important directories
    if [[ -d "${DOTFILES_DIR}" ]]; then
        print_success "Dotfiles directory: ${DOTFILES_DIR}"
        ((checks_passed++))
    else
        print_error "Dotfiles directory not found: ${DOTFILES_DIR}"
        ((checks_failed++))
    fi

    if [[ -d "${MODULES_DIR}" ]]; then
        print_success "Modules directory: ${MODULES_DIR}"
        ((checks_passed++))
    else
        print_warning "Modules directory not found: ${MODULES_DIR}"
        ((checks_failed++))
    fi

    if [[ -d "${PROFILES_DIR}" ]]; then
        print_success "Profiles directory: ${PROFILES_DIR}"
        ((checks_passed++))
    else
        print_warning "Profiles directory not found: ${PROFILES_DIR}"
        ((checks_failed++))
    fi

    echo ""
    print_section "Check Summary"
    echo "Passed: ${checks_passed}"
    echo "Failed: ${checks_failed}"
    echo ""

    if [[ ${checks_failed} -gt 0 ]]; then
        print_warning "Some checks failed. Install missing dependencies before proceeding."
        return 1
    else
        print_success "All system requirements are met"
        return 0
    fi
}

#######################################
# Validate all modules
#######################################
cmd_system_validate() {
    print_section "Validating System Configuration"

    # Validate all module.json files
    if command_exists jq; then
        validate_all_modules
    else
        print_error "jq is required for validation"
        print_status "Install with: brew install jq"
        return 1
    fi

    echo ""
    print_subsection "Checking Symlinks"

    # Check for broken symlinks in home directory
    local broken_count=0

    while IFS= read -r -d '' symlink; do
        if [[ ! -e "${symlink}" ]]; then
            ((broken_count++))
            print_warning "Broken symlink: ${symlink}"
        fi
    done < <(find "${HOME}" -maxdepth 3 -type l -print0 2>/dev/null)

    if [[ ${broken_count} -eq 0 ]]; then
        print_success "No broken symlinks found"
    else
        print_warning "Found ${broken_count} broken symlink(s)"
        echo ""
        echo "Run './manage.sh system repair' to fix broken symlinks"
    fi

    echo ""
}

#######################################
# Repair broken symlinks
#######################################
cmd_system_repair() {
    print_section "Repairing System Configuration"

    # Restow all active modules
    if [[ -f "${DOTFILES_MODULES}" ]]; then
        print_subsection "Restowing Active Modules"

        local count=0
        while IFS= read -r module; do
            [[ -z "${module}" || "${module}" =~ ^# ]] && continue

            ((count++))

            # Restow packages for this module
            local module_file="${MODULES_DIR}/${module}/module.json"
            if command_exists jq && [[ -f "${module_file}" ]]; then
                local stow_packages
                stow_packages=$(jq -r '.stow_packages[]? // empty' "${module_file}" 2>/dev/null || true)

                while IFS= read -r package; do
                    [[ -z "${package}" ]] && continue

                    if restow_package "${package}"; then
                        print_success "Restowed: ${package}"
                    else
                        print_error "Failed to restow: ${package}"
                    fi
                done <<< "${stow_packages}"
            fi
        done < "${DOTFILES_MODULES}"

        echo ""
        print_success "Restowed ${count} module(s)"
    fi

    # Remove broken symlinks
    print_subsection "Removing Broken Symlinks"

    local removed=0
    while IFS= read -r -d '' symlink; do
        if [[ ! -e "${symlink}" ]]; then
            if confirm "Remove broken symlink: ${symlink}?" "y"; then
                rm "${symlink}"
                ((removed++))
                print_success "Removed: ${symlink}"
            fi
        fi
    done < <(find "${HOME}" -maxdepth 3 -type l -print0 2>/dev/null)

    echo ""
    print_success "Repair complete (removed ${removed} broken symlink(s))"
    echo ""
}

#######################################
# Show help for modules command
#######################################
help_modules() {
    cat << 'EOF'
Modules Commands:

  list                  List all available modules
  status                Show active/installed modules
  enable <name>         Enable/install a module
  disable <name>        Disable/uninstall a module
  info <name>           Show detailed module information
  update <name>         Update specific module
  update-all            Update all active modules

Examples:
  ./manage.sh modules list
  ./manage.sh modules enable iterm2
  ./manage.sh modules disable dock
  ./manage.sh modules info system
  ./manage.sh modules update homebrew
  ./manage.sh modules update-all

EOF
}

#######################################
# Show help for profile command
#######################################
help_profile() {
    cat << 'EOF'
Profile Commands:

  info                  Show current profile information
  set <name>            Change to a different profile
  list                  List available profiles

Available Profiles:
  desktop              Desktop Mac configuration (performance, convenience)
  laptop               Laptop Mac configuration (security, battery life)

Examples:
  ./manage.sh profile info
  ./manage.sh profile set laptop
  ./manage.sh profile list

EOF
}

#######################################
# Show help for system command
#######################################
help_system() {
    cat << 'EOF'
System Commands:

  check                 Check system requirements and dependencies
  validate              Validate all module configurations
  repair                Repair broken symlinks and configuration

Examples:
  ./manage.sh system check
  ./manage.sh system validate
  ./manage.sh system repair

EOF
}

#######################################
# Show main help
#######################################
show_help() {
    cat << EOF
${BOLD}manage.sh${NC} - Dotfiles V2 Module Management Tool

${BOLD}USAGE:${NC}
  ./manage.sh <command> [subcommand] [options]

${BOLD}COMMANDS:${NC}

  ${BOLD}modules${NC}                 Manage dotfiles modules
    list                  List all available modules
    status                Show active/installed modules
    enable <name>         Enable/install a module
    disable <name>        Disable/uninstall a module
    info <name>           Show detailed module information
    update <name>         Update specific module
    update-all            Update all active modules

  ${BOLD}profile${NC}                 Manage system profiles
    info                  Show current profile information
    set <name>            Change profile (desktop|laptop)
    list                  List available profiles

  ${BOLD}system${NC}                  System management
    check                 Check system requirements
    validate              Validate all module configurations
    repair                Repair broken symlinks

  ${BOLD}help${NC}                    Show this help message
  ${BOLD}version${NC}                 Show version information

${BOLD}EXAMPLES:${NC}
  ./manage.sh modules list
  ./manage.sh modules enable homebrew
  ./manage.sh modules status
  ./manage.sh profile set laptop
  ./manage.sh system check

${BOLD}MORE HELP:${NC}
  ./manage.sh modules --help
  ./manage.sh profile --help
  ./manage.sh system --help

${BOLD}VERSION:${NC} ${VERSION}

EOF
}

#######################################
# Main function
#######################################
main() {
    local command="${1:-}"
    local subcommand="${2:-}"

    case "${command}" in
        modules)
            case "${subcommand}" in
                list)
                    cmd_modules_list
                    ;;
                status)
                    cmd_modules_status
                    ;;
                enable)
                    cmd_modules_enable "${3:-}"
                    ;;
                disable)
                    cmd_modules_disable "${3:-}"
                    ;;
                info)
                    cmd_modules_info "${3:-}"
                    ;;
                update)
                    cmd_modules_update "${3:-}"
                    ;;
                update-all)
                    cmd_modules_update_all
                    ;;
                --help|-h|help|"")
                    help_modules
                    ;;
                *)
                    print_error "Unknown modules subcommand: ${subcommand}"
                    echo ""
                    help_modules
                    exit 1
                    ;;
            esac
            ;;

        profile)
            case "${subcommand}" in
                info)
                    cmd_profile_info
                    ;;
                set)
                    cmd_profile_set "${3:-}"
                    ;;
                list)
                    cmd_profile_list
                    ;;
                --help|-h|help|"")
                    help_profile
                    ;;
                *)
                    print_error "Unknown profile subcommand: ${subcommand}"
                    echo ""
                    help_profile
                    exit 1
                    ;;
            esac
            ;;

        system)
            case "${subcommand}" in
                check)
                    cmd_system_check
                    ;;
                validate)
                    cmd_system_validate
                    ;;
                repair)
                    cmd_system_repair
                    ;;
                --help|-h|help|"")
                    help_system
                    ;;
                *)
                    print_error "Unknown system subcommand: ${subcommand}"
                    echo ""
                    help_system
                    exit 1
                    ;;
            esac
            ;;

        version|--version|-v)
            echo "manage.sh version ${VERSION}"
            ;;

        help|--help|-h|"")
            show_help
            ;;

        *)
            print_error "Unknown command: ${command}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
