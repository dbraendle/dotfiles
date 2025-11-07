#!/usr/bin/env bash
# Module Validator - Validates module.json files against schema
set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/utils.sh"

readonly SCHEMA_FILE="${SCRIPT_DIR}/module-schema.json"

# Validate a module.json file
# Args:
#   $1 - Path to module.json file
# Returns:
#   0 if valid, 1 if invalid
validate_module() {
    local module_file="$1"
    local errors=0

    if [[ ! -f "$module_file" ]]; then
        print_error "Module file not found: $module_file"
        return 1
    fi

    print_status "Validating: $module_file"

    # Check if jq is available
    if ! command_exists "jq"; then
        print_error "jq is required for module validation"
        print_status "Install with: brew install jq"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$module_file" 2>/dev/null; then
        print_error "Invalid JSON syntax"
        ((errors++))
    fi

    # Extract module name
    local module_name
    module_name=$(jq -r '.name // "unknown"' "$module_file")

    # Required fields
    local required_fields=("name" "description" "category" "scripts")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$module_file" >/dev/null 2>&1; then
            print_error "Missing required field: $field"
            ((errors++))
        fi
    done

    # Validate name (kebab-case)
    if ! echo "$module_name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        print_error "Invalid module name: $module_name (must be kebab-case)"
        ((errors++))
    fi

    # Validate category
    local category
    category=$(jq -r '.category // ""' "$module_file")
    if [[ ! "$category" =~ ^(core|optional|experimental)$ ]]; then
        print_error "Invalid category: $category (must be: core, optional, experimental)"
        ((errors++))
    fi

    # Validate install script exists
    local install_script
    install_script=$(jq -r '.scripts.install // ""' "$module_file")
    if [[ -n "$install_script" ]]; then
        local dotfiles_dir
        dotfiles_dir=$(get_dotfiles_dir)
        local install_path="${dotfiles_dir}/${install_script}"

        if [[ ! -f "$install_path" ]]; then
            print_warning "Install script not found: $install_path"
        elif [[ ! -x "$install_path" ]]; then
            print_warning "Install script not executable: $install_path"
        fi
    else
        print_error "Missing install script path"
        ((errors++))
    fi

    # Validate profiles
    local profiles_count
    profiles_count=$(jq '.profiles | length' "$module_file" 2>/dev/null || echo "0")
    if [[ "$profiles_count" -eq 0 ]]; then
        print_warning "No profiles specified, defaulting to: desktop, laptop"
    fi

    # Check for invalid profile names
    if jq -e '.profiles[]' "$module_file" >/dev/null 2>&1; then
        while IFS= read -r profile; do
            if [[ ! "$profile" =~ ^(desktop|laptop)$ ]]; then
                print_error "Invalid profile: $profile (must be: desktop, laptop)"
                ((errors++))
            fi
        done < <(jq -r '.profiles[]' "$module_file" 2>/dev/null || true)
    fi

    # Validate dependencies (if any)
    if jq -e '.dependencies' "$module_file" >/dev/null 2>&1; then
        while IFS= read -r dep; do
            if ! echo "$dep" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
                print_error "Invalid dependency name: $dep (must be kebab-case)"
                ((errors++))
            fi
        done < <(jq -r '.dependencies[]?' "$module_file" 2>/dev/null || true)
    fi

    # Validate stow packages (if any)
    if jq -e '.stow_packages' "$module_file" >/dev/null 2>&1; then
        while IFS= read -r pkg; do
            local dotfiles_dir
            dotfiles_dir=$(get_dotfiles_dir)
            local pkg_dir="${dotfiles_dir}/config/${pkg}"

            if [[ ! -d "$pkg_dir" ]]; then
                print_warning "Stow package directory not found: $pkg_dir"
            fi
        done < <(jq -r '.stow_packages[]?' "$module_file" 2>/dev/null || true)
    fi

    # Summary
    if [[ $errors -eq 0 ]]; then
        print_success "Module '$module_name' is valid"
        return 0
    else
        print_error "Module '$module_name' has $errors error(s)"
        return 1
    fi
}

# Validate all modules in modules/ directory
validate_all_modules() {
    local dotfiles_dir
    dotfiles_dir=$(get_dotfiles_dir)
    local modules_dir="${dotfiles_dir}/modules"

    if [[ ! -d "$modules_dir" ]]; then
        print_error "Modules directory not found: $modules_dir"
        return 1
    fi

    print_section "Validating All Modules"

    local total=0
    local valid=0
    local invalid=0

    # Find all module.json files
    while IFS= read -r -d '' module_file; do
        ((total++))
        if validate_module "$module_file"; then
            ((valid++))
        else
            ((invalid++))
        fi
        echo ""  # Spacing between modules
    done < <(find "$modules_dir" -name "module.json" -type f -print0)

    # Summary
    print_section "Validation Summary"
    echo "Total modules:   $total"
    echo "Valid modules:   $valid"
    echo "Invalid modules: $invalid"

    if [[ $invalid -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Get module metadata
# Args:
#   $1 - Module name
#   $2 - Field to extract (optional, returns all if omitted)
get_module_info() {
    local module_name="$1"
    local field="${2:-}"

    local dotfiles_dir
    dotfiles_dir=$(get_dotfiles_dir)
    local module_file="${dotfiles_dir}/modules/${module_name}/module.json"

    if [[ ! -f "$module_file" ]]; then
        print_error "Module not found: $module_name"
        return 1
    fi

    if [[ -z "$field" ]]; then
        # Return entire module JSON
        jq '.' "$module_file"
    else
        # Return specific field
        jq -r ".$field // empty" "$module_file"
    fi
}

# List all available modules
list_modules() {
    local dotfiles_dir
    dotfiles_dir=$(get_dotfiles_dir)
    local modules_dir="${dotfiles_dir}/modules"

    if [[ ! -d "$modules_dir" ]]; then
        print_error "Modules directory not found: $modules_dir"
        return 1
    fi

    print_status "Available modules:"
    echo ""

    while IFS= read -r -d '' module_file; do
        local module_name
        local description
        local category

        module_name=$(jq -r '.name' "$module_file" 2>/dev/null || echo "unknown")
        description=$(jq -r '.description' "$module_file" 2>/dev/null || echo "No description")
        category=$(jq -r '.category' "$module_file" 2>/dev/null || echo "unknown")

        # Color-code by category
        case "$category" in
            "core")
                echo -e "  ${BOLD_GREEN}●${NC} ${BOLD}$module_name${NC} - $description"
                ;;
            "optional")
                echo -e "  ${BOLD_BLUE}●${NC} $module_name - $description"
                ;;
            "experimental")
                echo -e "  ${BOLD_YELLOW}●${NC} $module_name - $description"
                ;;
            *)
                echo -e "  ● $module_name - $description"
                ;;
        esac
    done < <(find "$modules_dir" -name "module.json" -type f -print0 | sort -z)
}

# Check if module exists
module_exists() {
    local module_name="$1"
    local dotfiles_dir
    dotfiles_dir=$(get_dotfiles_dir)
    local module_file="${dotfiles_dir}/modules/${module_name}/module.json"
    [[ -f "$module_file" ]]
}

# Get module dependencies
get_module_dependencies() {
    local module_name="$1"
    get_module_info "$module_name" "dependencies[]" 2>/dev/null || true
}

# Check if module supports current profile
module_supports_profile() {
    local module_name="$1"
    local profile="$2"

    local profiles
    profiles=$(get_module_info "$module_name" "profiles[]" 2>/dev/null || echo "desktop laptop")

    echo "$profiles" | grep -q "$profile"
}

# Main - if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        validate)
            if [[ -n "${2:-}" ]]; then
                validate_module "$2"
            else
                validate_all_modules
            fi
            ;;
        list)
            list_modules
            ;;
        info)
            if [[ -z "${2:-}" ]]; then
                print_error "Usage: $0 info <module-name> [field]"
                exit 1
            fi
            get_module_info "$2" "${3:-}"
            ;;
        *)
            cat << EOF
Module Validator - Validate and inspect module.json files

Usage:
  $0 validate [module.json]   Validate module file(s)
  $0 list                     List all available modules
  $0 info <module> [field]    Get module information

Examples:
  $0 validate                              # Validate all modules
  $0 validate modules/system/module.json   # Validate specific module
  $0 list                                  # List all modules
  $0 info system                           # Get system module info
  $0 info system description               # Get specific field

EOF
            ;;
    esac
fi
