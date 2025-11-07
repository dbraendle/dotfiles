#!/usr/bin/env bash
# logging.sh - Logging functions for dotfiles scripts
# Provides consistent logging output with colors and file logging
# Usage: source this file after sourcing colors.sh

# Get the directory where this library is located (use unique var name to avoid conflicts)
LOGGING_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source colors.sh from the same directory
# shellcheck source=./colors.sh
source "${LOGGING_LIB_DIR}/colors.sh"

# Default log directory and file
LOG_DIR="${HOME}/dotfiles/logs"
LOG_FILE="${LOG_DIR}/install-$(date +%Y-%m-%d).log"

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}" 2>/dev/null

# Enable debug mode if DEBUG environment variable is set
: "${DEBUG:=0}"

#######################################
# Print an informational status message
# Globals:
#   BLUE, NC, LOG_FILE
# Arguments:
#   $1 - Message to print
# Outputs:
#   Writes message to stdout and optionally to log file
#######################################
print_status() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} ${message}"
    log_to_file "INFO" "${message}"
}

#######################################
# Print a success message
# Globals:
#   BOLD_GREEN, NC, LOG_FILE
# Arguments:
#   $1 - Message to print
# Outputs:
#   Writes message to stdout and optionally to log file
#######################################
print_success() {
    local message="$1"
    echo -e "${BOLD_GREEN}[✓]${NC} ${message}"
    log_to_file "SUCCESS" "${message}"
}

#######################################
# Print an error message
# Globals:
#   BOLD_RED, NC, LOG_FILE
# Arguments:
#   $1 - Message to print
# Outputs:
#   Writes message to stderr and optionally to log file
#######################################
print_error() {
    local message="$1"
    echo -e "${BOLD_RED}[✗]${NC} ${message}" >&2
    log_to_file "ERROR" "${message}"
}

#######################################
# Print a warning message
# Globals:
#   BOLD_YELLOW, NC, LOG_FILE
# Arguments:
#   $1 - Message to print
# Outputs:
#   Writes message to stdout and optionally to log file
#######################################
print_warning() {
    local message="$1"
    echo -e "${BOLD_YELLOW}[!]${NC} ${message}"
    log_to_file "WARNING" "${message}"
}

#######################################
# Print a debug message (only if DEBUG=1)
# Globals:
#   DEBUG, CYAN, NC, LOG_FILE
# Arguments:
#   $1 - Message to print
# Outputs:
#   Writes message to stdout and optionally to log file (only if DEBUG=1)
#######################################
print_debug() {
    local message="$1"
    if [[ "${DEBUG}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} ${message}"
        log_to_file "DEBUG" "${message}"
    fi
}

#######################################
# Log a message to a file with timestamp
# Globals:
#   LOG_FILE
# Arguments:
#   $1 - Log level (INFO, SUCCESS, ERROR, WARNING, DEBUG)
#   $2 - Message to log
# Outputs:
#   Appends timestamped message to log file
#######################################
log_to_file() {
    local level="$1"
    local message="$2"

    # Only log if LOG_FILE is set and writable
    if [[ -n "${LOG_FILE}" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

        # Create log directory if it doesn't exist
        local log_dir
        log_dir="$(dirname "${LOG_FILE}")"
        mkdir -p "${log_dir}" 2>/dev/null

        # Append to log file, handle multi-line messages
        while IFS= read -r line; do
            echo "[${timestamp}] [${level}] ${line}" >> "${LOG_FILE}" 2>/dev/null
        done <<< "${message}"
    fi
}

#######################################
# Print a section header for better organization
# Globals:
#   BOLD_MAGENTA, NC
# Arguments:
#   $1 - Section title
# Outputs:
#   Writes formatted section header to stdout
#######################################
print_section() {
    local title="$1"
    echo ""
    echo -e "${BOLD_MAGENTA}===========================================================${NC}"
    echo -e "${BOLD_MAGENTA} ${title}${NC}"
    echo -e "${BOLD_MAGENTA}===========================================================${NC}"
    echo ""
    log_to_file "SECTION" "${title}"
}

#######################################
# Print a subsection header
# Globals:
#   BOLD, NC
# Arguments:
#   $1 - Subsection title
# Outputs:
#   Writes formatted subsection header to stdout
#######################################
print_subsection() {
    local title="$1"
    echo ""
    echo -e "${BOLD}--- ${title} ---${NC}"
    echo ""
    log_to_file "SUBSECTION" "${title}"
}
