#!/bin/bash
# ==============================================================================
# Main Utilities Loader
# ==============================================================================
# Loads all utility libraries and provides a single import point
# ==============================================================================

# Get the directory where this script is located
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all utility libraries in the correct order
source "$UTILS_DIR/colors.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/timing.sh"
source "$UTILS_DIR/prerequisites.sh"
source "$UTILS_DIR/config.sh"
source "$UTILS_DIR/azure.sh"
source "$UTILS_DIR/github.sh"

# Set up common variables
export UTILS_LOADED=true

# Function to show loaded utilities
show_loaded_utilities() {
    print_status "Loaded utility libraries:"
    print_status "  ✓ colors.sh - Color output functions"
    print_status "  ✓ common.sh - Common utility functions"
    print_status "  ✓ timing.sh - Performance measurement and ROI tracking"
    print_status "  ✓ prerequisites.sh - Prerequisites validation"
    print_status "  ✓ config.sh - Configuration management"
    print_status "  ✓ azure.sh - Azure operations"
    print_status "  ✓ github.sh - GitHub operations"
}

# Allow this script to be run directly for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_banner "Power Platform Terraform Governance - Utilities"
    show_loaded_utilities
    echo ""
    print_status "All utilities loaded successfully!"
    print_status ""
    print_status "Usage in other scripts:"
    print_status "  source \"\$(dirname \"\${BASH_SOURCE[0]}\")/utils/utils.sh\""
    print_status ""
    print_status "Or load individual utilities:"
    print_status "  source \"\$(dirname \"\${BASH_SOURCE[0]}\")/utils/colors.sh\""
    print_status "  source \"\$(dirname \"\${BASH_SOURCE[0]}\")/utils/azure.sh\""
    print_status "  # etc."
fi
