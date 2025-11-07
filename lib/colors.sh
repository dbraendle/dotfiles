#!/usr/bin/env bash
# colors.sh - Terminal color codes for dotfiles scripts
# This file defines ANSI color codes for consistent terminal output formatting
# Usage: source this file in any script that needs colored output

# Regular colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'
export BLACK='\033[0;30m'

# Bold colors
export BOLD='\033[1m'
export BOLD_RED='\033[1;31m'
export BOLD_GREEN='\033[1;32m'
export BOLD_YELLOW='\033[1;33m'
export BOLD_BLUE='\033[1;34m'
export BOLD_MAGENTA='\033[1;35m'
export BOLD_CYAN='\033[1;36m'
export BOLD_WHITE='\033[1;37m'
export BOLD_BLACK='\033[1;30m'

# Underline colors
export UNDERLINE='\033[4m'
export UNDERLINE_RED='\033[4;31m'
export UNDERLINE_GREEN='\033[4;32m'
export UNDERLINE_YELLOW='\033[4;33m'
export UNDERLINE_BLUE='\033[4;34m'
export UNDERLINE_MAGENTA='\033[4;35m'
export UNDERLINE_CYAN='\033[4;36m'

# Background colors
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'
export BG_MAGENTA='\033[45m'
export BG_CYAN='\033[46m'
export BG_WHITE='\033[47m'

# Special formatting
export DIM='\033[2m'
export ITALIC='\033[3m'
export BLINK='\033[5m'
export REVERSE='\033[7m'
export HIDDEN='\033[8m'

# Reset/No Color
export NC='\033[0m'
export RESET='\033[0m'

# Color test function (optional, for debugging)
# Uncomment to test: color_test
color_test() {
    echo -e "${RED}Red${NC} ${GREEN}Green${NC} ${YELLOW}Yellow${NC} ${BLUE}Blue${NC}"
    echo -e "${MAGENTA}Magenta${NC} ${CYAN}Cyan${NC} ${WHITE}White${NC}"
    echo -e "${BOLD_RED}Bold Red${NC} ${BOLD_GREEN}Bold Green${NC} ${BOLD_BLUE}Bold Blue${NC}"
}
