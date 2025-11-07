# Dotfiles Libraries

This directory contains shared library files for the dotfiles V2 modular system. These libraries provide consistent functionality across all installation and management scripts.

## Library Files

### 1. colors.sh
Defines ANSI color codes for terminal output formatting.

**Exports:**
- Regular colors: `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`, `BLACK`
- Bold colors: `BOLD_*` variants
- Special formatting: `BOLD`, `DIM`, `ITALIC`, `UNDERLINE`, `REVERSE`
- Reset: `NC` (no color) / `RESET`

**Usage:**
```bash
source lib/colors.sh
echo -e "${GREEN}Success!${NC}"
echo -e "${BOLD_RED}Error!${NC}"
```

### 2. logging.sh
Provides consistent logging functions with colored output and file logging.

**Dependencies:** `colors.sh`

**Functions:**
- `print_status(message)` - Blue [INFO] message
- `print_success(message)` - Green [✓] message
- `print_error(message)` - Red [✗] message (to stderr)
- `print_warning(message)` - Yellow [!] message
- `print_debug(message)` - Cyan [DEBUG] message (only if DEBUG=1)
- `print_section(title)` - Formatted section header
- `print_subsection(title)` - Formatted subsection header
- `log_to_file(level, message)` - Append timestamped message to log file

**Configuration:**
- `LOG_FILE` - Path to log file (default: `~/dotfiles/logs/install-YYYY-MM-DD.log`)
- `DEBUG` - Set to `1` to enable debug messages

**Usage:**
```bash
source lib/logging.sh

print_status "Installing packages..."
print_success "Package installed"
print_warning "Config file already exists"
print_error "Installation failed"

DEBUG=1
print_debug "Verbose output here"
```

### 3. utils.sh
General utility functions for system detection and file operations.

**Dependencies:** `logging.sh` (which includes `colors.sh`)

**Functions:**

**System Detection:**
- `is_macos()` - Returns 0 if running on macOS
- `is_apple_silicon()` - Returns 0 if Apple Silicon (M1/M2/M3/M4)
- `is_laptop()` - Returns 0 if MacBook (portable)
- `is_root()` - Returns 0 if running as root/sudo
- `is_ci()` - Returns 0 if running in CI environment
- `get_macos_version()` - Outputs macOS version (e.g., "14.0")

**Command Utilities:**
- `command_exists(cmd)` - Check if command is available
- `get_real_user()` - Get username even when using sudo

**User Interaction:**
- `confirm(question, default)` - Ask yes/no question, returns 0 if yes

**File Operations:**
- `create_backup(file)` - Backup file with timestamp
- `ensure_dir(dir)` - Create directory if it doesn't exist
- `safe_symlink(source, target)` - Create symlink with backup

**Path Utilities:**
- `get_dotfiles_dir()` - Get absolute path to dotfiles directory

**Version Utilities:**
- `version_compare(v1, v2)` - Compare version strings

**Usage:**
```bash
source lib/utils.sh

if is_macos; then
    print_status "Running on macOS $(get_macos_version)"
fi

if is_apple_silicon; then
    print_status "Apple Silicon detected"
fi

if command_exists "brew"; then
    print_success "Homebrew is installed"
fi

if confirm "Install package?" "y"; then
    print_status "Installing..."
fi

create_backup ~/.zshrc
safe_symlink ~/dotfiles/zsh/.zshrc ~/.zshrc

DOTFILES=$(get_dotfiles_dir)
```

### 4. stow-helpers.sh
Functions for managing dotfiles packages using GNU Stow.

**Dependencies:** `logging.sh`, `utils.sh`

**Configuration:**
- `DOTFILES_MODULES` - File tracking stowed packages (default: `~/.dotfiles-modules`)

**Functions:**

**Core Operations:**
- `stow_package(package, [opts])` - Stow a package with error handling and backup
- `unstow_package(package)` - Unstow a package
- `restow_package(package)` - Restow a single package (unstow then stow)
- `restow_all()` - Restow all active modules from tracking file

**Package Management:**
- `adopt_package(package)` - Adopt existing files into a package
- `list_stowed_packages()` - List all currently stowed packages

**Helper Functions:**
- `ensure_stow_installed()` - Check if GNU Stow is installed
- `package_exists(package)` - Check if package directory exists

**Usage:**
```bash
source lib/stow-helpers.sh

# Stow a package
if stow_package "zsh"; then
    print_success "zsh package stowed"
fi

# Unstow a package
unstow_package "zsh"

# Restow a package (after changes)
restow_package "zsh"

# Restow all active packages
restow_all

# List stowed packages
list_stowed_packages

# Adopt existing files
adopt_package "vim"
```

## Testing

Run the test script to verify all libraries are working:

```bash
./lib/test-libs.sh
```

## Best Practices

### Sourcing Libraries

Always source libraries from the same directory:

```bash
#!/usr/bin/env bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/stow-helpers.sh"
```

### Error Handling

Enable strict error handling in your scripts:

```bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures
```

### Logging

Always use the logging functions for consistent output:

```bash
# Good
print_status "Installing packages"
print_success "Installation complete"

# Avoid
echo "Installing packages"
echo "Installation complete"
```

### Function Return Values

- Return `0` for success
- Return `1` (or non-zero) for failure
- Check return values with `if` statements

```bash
if command_exists "git"; then
    print_success "Git is installed"
else
    print_error "Git not found"
    exit 1
fi
```

## Directory Structure

```
dotfiles/
├── lib/
│   ├── README.md           # This file
│   ├── colors.sh           # Color definitions
│   ├── logging.sh          # Logging functions
│   ├── utils.sh            # Utility functions
│   ├── stow-helpers.sh     # Stow management
│   └── test-libs.sh        # Test script
├── logs/                   # Log files
│   └── install-*.log
└── packages/               # Stow packages
    ├── zsh/
    ├── vim/
    └── ...
```

## Environment Variables

### Global Configuration
- `DOTFILES_DIR` - Override dotfiles directory path
- `DEBUG` - Set to `1` to enable debug output
- `LOG_FILE` - Override default log file path

### Example
```bash
export DEBUG=1
export DOTFILES_DIR="/custom/path/to/dotfiles"
source lib/logging.sh
```

## Integration Example

Complete example of a dotfiles installation script:

```bash
#!/usr/bin/env bash
# install.sh - Example installation script

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/stow-helpers.sh"

# Enable debug mode if needed
# export DEBUG=1

main() {
    print_section "Dotfiles Installation"

    # System checks
    if ! is_macos; then
        print_error "This script requires macOS"
        exit 1
    fi

    print_status "Detected: macOS $(get_macos_version)"
    is_apple_silicon && print_status "Architecture: Apple Silicon"

    # Install Stow if needed
    if ! command_exists stow; then
        print_warning "GNU Stow not found"
        if confirm "Install GNU Stow via Homebrew?"; then
            brew install stow
        fi
    fi

    # Stow packages
    local packages=("zsh" "vim" "git")
    for package in "${packages[@]}"; do
        if stow_package "${package}"; then
            print_success "Stowed: ${package}"
        else
            print_error "Failed to stow: ${package}"
        fi
    done

    print_section "Installation Complete"
}

main "$@"
```

## License

Part of the dotfiles V2 project.
