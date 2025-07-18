#!/bin/bash
# ==============================================================================
# Restore Configuration from Backup
# ==============================================================================
# This script restores the config.env file from its backup, useful after
# cleanup operations when you want to return to the original configuration
# ==============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the project root directory (two levels up from scripts/setup)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load utility functions (colors only for restore-config)
source "$SCRIPT_DIR/../utils/colors.sh"

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main function
main() {
    print_status "Restoring configuration from backup..."
    print_status "======================================"
    print_status ""
    print_status "This will restore config.env to its state before the last setup run."
    print_status "The backup contains the configuration before setup modifications."
    print_status ""
    
    local config_file="$PROJECT_ROOT/config.env"
    local backup_file="$PROJECT_ROOT/config.env.backup"
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        print_status ""
        print_status "This usually means:"
        print_status "  1. No setup has been run yet (no backup created)"
        print_status "  2. The backup file was manually deleted"
        print_status "  3. You're running this from the wrong directory"
        print_status ""
        print_status "To create a new configuration:"
        print_status "  cd $PROJECT_ROOT"
        print_status "  cp config.env.example config.env"
        print_status "  vim config.env"
        exit 1
    fi
    
    print_status "Current configuration:"
    if [[ -f "$config_file" ]]; then
        print_status "  $(wc -l < "$config_file") lines in config.env"
    else
        print_status "  config.env does not exist"
    fi
    
    print_status "Backup configuration:"
    print_status "  $(wc -l < "$backup_file") lines in config.env.backup"
    print_status "  Created: $(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file")"
    
    print_warning ""
    print_warning "This will overwrite the current config.env with the backup version"
    print_warning "Any changes made since the backup will be lost"
    print_warning ""
    
    echo -n "Continue with restoration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Restoration cancelled by user"
        exit 1
    fi
    
    # Restore the configuration
    if cp "$backup_file" "$config_file"; then
        print_success ""
        print_success "Configuration successfully restored!"
        print_status ""
        print_status "Restored from: $backup_file"
        print_status "Restored to: $config_file"
        print_status ""
        print_status "Next steps:"
        print_status "  1. Review the restored configuration: vim $PROJECT_ROOT/config.env"
        print_status "  2. Run setup again if needed: ./setup.sh"
        print_status "  3. The backup file is preserved for future use"
    else
        print_error "Failed to restore configuration"
        print_error "Check file permissions and try again"
        exit 1
    fi
}

# Run the main function
main "$@"
