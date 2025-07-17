#!/bin/bash
# ==============================================================================
# Color Output Utilities
# ==============================================================================
# Provides consistent colored output functions for all scripts
# ==============================================================================

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Function to print colored output with consistent formatting
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

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_header() {
    echo -e "${CYAN}${BOLD}$1${NC}"
}

# Function to print a separator line
print_separator() {
    echo "============================================================================="
}

# Function to print a banner with title
print_banner() {
    local title="$1"
    echo -e "${CYAN}${BOLD}"
    print_separator
    echo "  $title"
    print_separator
    echo -e "${NC}"
}

# Function to print formatted configuration summary
print_config_item() {
    local key="$1"
    local value="$2"
    local masked="${3:-false}"
    
    if [[ "$masked" == "true" && -n "$value" ]]; then
        # Mask sensitive values, showing first 8 and last 4 characters
        local masked_value="${value:0:8}...${value: -4}"
        print_status "  $key: $masked_value"
    else
        print_status "  $key: $value"
    fi
}

# Function to print a confirmation prompt
print_confirmation_prompt() {
    local message="$1"
    local default="${2:-N}"
    
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        echo -n "$message (Y/n): "
    else
        echo -n "$message (y/N): "
    fi
}

# Function to print danger zone warning
print_danger_zone() {
    local message="$1"
    echo -e "${RED}${BOLD}⚠️  DANGER ZONE ⚠️${NC}"
    echo ""
    echo -e "${RED}$message${NC}"
    echo ""
}

# Export functions for use in other scripts
export -f print_status print_success print_warning print_error print_check
export -f print_step print_header print_separator print_banner
export -f print_config_item print_confirmation_prompt print_danger_zone
