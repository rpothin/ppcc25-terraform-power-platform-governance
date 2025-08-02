#!/bin/bash
# ==============================================================================
# Script Name: Assign Service Principal Permissions to Power Platform Environments
# ==============================================================================
# Purpose: Add the Terraform service principal as System Administrator on all Power Platform environments
# 
# Usage:
#   ./scripts/utils/assign-sp-power-platform-envs.sh [OPTIONS]
#   
# Examples:
#   ./scripts/utils/assign-sp-power-platform-envs.sh
#   ./scripts/utils/assign-sp-power-platform-envs.sh --config custom.env
#   ./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve
#   ./scripts/utils/assign-sp-power-platform-envs.sh --environment "specific-env-id"
#
# Dependencies:
#   - Power Platform CLI (pac) - authenticated and configured
#   - Configuration file: config.env (or specified with --config)
#   - Service principal must exist and be configured in Azure AD
#   - Current user must have Power Platform Administrator privileges
#   - jq - JSON processing tool
#
# Author: PPCC25 Terraform Power Platform Governance Team
# Last Modified: August 2, 2025
# ==============================================================================

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Script directory and utilities
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)"

# Source utility functions
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/common.sh"

# Configuration variables
CONFIG_FILE="$ROOT_DIR/config.env"
AUTO_APPROVE=false
SPECIFIC_ENVIRONMENT=""
ROLE_NAME="System Administrator"
DRY_RUN=false

# Statistics tracking
TOTAL_ENVIRONMENTS=0
SUCCESSFUL_ASSIGNMENTS=0
FAILED_ASSIGNMENTS=0
SKIPPED_ASSIGNMENTS=0

# Global environment arrays
declare -a ENVIRONMENT_IDS
declare -a ENVIRONMENT_NAMES
declare -a ENVIRONMENT_TYPES

# Cleanup function
cleanup() {
    # No temporary resources to clean up in this script
    :
}

# Signal handling
trap cleanup EXIT SIGINT SIGTERM

# ==============================================================================
# Utility Functions
# ==============================================================================

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Add the Terraform service principal as System Administrator on Power Platform environments.

This script automates the process of granting the service principal (used for Terraform
automation) the necessary permissions to manage Power Platform environments.

OPTIONS:
    --config FILE           Specify configuration file (default: config.env)
    --auto-approve          Skip interactive confirmations
    --environment ID        Target specific environment ID (default: all environments)
    --role NAME             Security role name (default: "System Administrator")
    --dry-run               Show what would be done without making changes
    --help                  Show this help message

EXAMPLES:
    $0                                              # Interactive mode, all environments
    $0 --auto-approve                               # Automated mode, all environments
    $0 --environment "12345-678-90ab-cdef"         # Target specific environment
    $0 --dry-run                                    # Preview actions without changes

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --auto-approve)
                AUTO_APPROVE=true
                shift
                ;;
            --environment)
                SPECIFIC_ENVIRONMENT="$2"
                shift 2
                ;;
            --role)
                ROLE_NAME="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# Load and validate configuration
load_configuration() {
    print_step "Loading configuration from: $CONFIG_FILE"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        print_status "Run setup script first: ./scripts/setup/setup.sh"
        return 1
    fi
    
    if ! source "$CONFIG_FILE"; then
        print_error "Failed to load configuration from: $CONFIG_FILE"
        return 1
    fi
    
    if [[ -z "${AZURE_CLIENT_ID:-}" ]]; then
        print_error "AZURE_CLIENT_ID not found in configuration"
        print_status "Ensure setup script has been run successfully"
        return 1
    fi
    
    print_success "Configuration loaded successfully"
    print_status "Service Principal ID: $AZURE_CLIENT_ID"
}

# Validate prerequisites
validate_prerequisites() {
    print_step "Validating prerequisites..."
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed (required for JSON processing)"
        print_status "Install jq: sudo apt-get install jq"
        return 1
    fi
    
    if ! command -v pac &> /dev/null; then
        print_error "Power Platform CLI (pac) is not installed"
        print_status "Install from: https://aka.ms/PowerPlatformCLI"
        return 1
    fi
    
    print_success "Prerequisites validated"
}

# Validate Power Platform CLI authentication
validate_pac_authentication() {
    print_step "Validating Power Platform CLI authentication..."
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if pac auth list &> /dev/null; then
            print_success "Power Platform CLI authentication validated"
            return 0
        fi
        
        print_warning "Authentication check failed (attempt $attempt/$max_attempts)"
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_error "Power Platform CLI not authenticated"
            print_status "Run: pac auth create --environment https://yourorg.crm.dynamics.com"
            return 1
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
}

# Get list of environments
get_environments() {
    print_step "Retrieving Power Platform environments..."
    
    local environments_json
    if ! environments_json=$(pac admin list --json 2>/dev/null); then
        print_error "Failed to retrieve environments list"
        print_status "Ensure you have Power Platform Administrator permissions"
        return 1
    fi
    
    if ! echo "$environments_json" | jq empty 2>/dev/null; then
        print_error "Invalid JSON response from pac admin list"
        return 1
    fi
    
    # Extract environment data into arrays
    readarray -t ENVIRONMENT_IDS < <(echo "$environments_json" | jq -r '.[].EnvironmentId')
    readarray -t ENVIRONMENT_NAMES < <(echo "$environments_json" | jq -r '.[].DisplayName')
    readarray -t ENVIRONMENT_TYPES < <(echo "$environments_json" | jq -r '.[].Type')
    
    TOTAL_ENVIRONMENTS=${#ENVIRONMENT_IDS[@]}
    
    if [[ $TOTAL_ENVIRONMENTS -eq 0 ]]; then
        print_error "No environments found"
        return 1
    fi
    
    print_success "Found $TOTAL_ENVIRONMENTS Power Platform environments"
}

# Assign service principal to environment
assign_service_principal_to_environment() {
    local environment_id="$1"
    local environment_name="$2"
    
    print_step "Processing environment: $environment_name"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_status "[DRY RUN] Would assign service principal $AZURE_CLIENT_ID as '$ROLE_NAME' to environment: $environment_name"
        SUCCESSFUL_ASSIGNMENTS=$((SUCCESSFUL_ASSIGNMENTS + 1))
        return 0
    fi
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if pac admin assign-user \
            --environment "$environment_id" \
            --user "$AZURE_CLIENT_ID" \
            --role "$ROLE_NAME" \
            --application-user \
            &> /dev/null; then
            
            print_success "Successfully assigned service principal to: $environment_name"
            SUCCESSFUL_ASSIGNMENTS=$((SUCCESSFUL_ASSIGNMENTS + 1))
            return 0
        fi
        
        print_warning "Assignment failed for $environment_name (attempt $attempt/$max_attempts)"
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_error "Failed to assign service principal to: $environment_name"
            FAILED_ASSIGNMENTS=$((FAILED_ASSIGNMENTS + 1))
            return 1
        fi
        
        attempt=$((attempt + 1))
        sleep 5
    done
}

# Process environments
process_environments() {
    print_step "Starting service principal assignment process..."
    
    if [[ "$SPECIFIC_ENVIRONMENT" != "" ]]; then
        # Process single environment
        local found=false
        for i in "${!ENVIRONMENT_IDS[@]}"; do
            if [[ "${ENVIRONMENT_IDS[$i]}" == "$SPECIFIC_ENVIRONMENT" ]]; then
                assign_service_principal_to_environment "$SPECIFIC_ENVIRONMENT" "${ENVIRONMENT_NAMES[$i]}"
                found=true
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            print_error "Specified environment not found: $SPECIFIC_ENVIRONMENT"
            return 1
        fi
    else
        # Process all environments
        for i in "${!ENVIRONMENT_IDS[@]}"; do
            local env_id="${ENVIRONMENT_IDS[$i]}"
            local env_name="${ENVIRONMENT_NAMES[$i]}"
            local env_type="${ENVIRONMENT_TYPES[$i]}"
            local current=$((i + 1))
            
            print_status "Progress: $current/$TOTAL_ENVIRONMENTS [$env_type]"
            assign_service_principal_to_environment "$env_id" "$env_name"
            sleep 1
        done
    fi
}

# Display summary statistics
display_summary() {
    print_step "Assignment Summary"
    
    echo "┌─────────────────────────────────────────┐"
    echo "│            Assignment Results           │"
    echo "├─────────────────────────────────────────┤"
    printf "│ Total Environments:       %3d          │\n" "$TOTAL_ENVIRONMENTS"
    printf "│ Successful Assignments:   %3d          │\n" "$SUCCESSFUL_ASSIGNMENTS"
    printf "│ Failed Assignments:       %3d          │\n" "$FAILED_ASSIGNMENTS"
    printf "│ Skipped (Already Assigned): %3d        │\n" "$SKIPPED_ASSIGNMENTS"
    echo "└─────────────────────────────────────────┘"
    
    if [[ $FAILED_ASSIGNMENTS -gt 0 ]]; then
        print_warning "$FAILED_ASSIGNMENTS environments failed assignment"
        print_status "Check individual environment permissions and retry if needed"
        return 1
    elif [[ $SUCCESSFUL_ASSIGNMENTS -gt 0 ]]; then
        print_success "All assignments completed successfully!"
        if [[ "$DRY_RUN" == "false" ]]; then
            print_status "Service principal now has System Administrator access to assigned environments"
        fi
    else
        print_status "No assignments were needed (all environments already configured)"
    fi
    
    return 0
}

# Confirmation prompt
prompt_confirmation() {
    if [[ "$AUTO_APPROVE" == "true" ]]; then
        return 0
    fi
    
    print_warning "This will assign the service principal as System Administrator on the target environments."
    print_status "Service Principal: $AZURE_CLIENT_ID"
    print_status "Role: $ROLE_NAME"
    
    if [[ "$SPECIFIC_ENVIRONMENT" != "" ]]; then
        print_status "Target: Specific environment ($SPECIFIC_ENVIRONMENT)"
    else
        print_status "Target: All environments ($TOTAL_ENVIRONMENTS total)"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_status "Mode: Dry run (no changes will be made)"
    fi
    
    echo ""
    read -p "Do you want to continue? (y/N): " -r response
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            print_status "Operation cancelled by user"
            exit 0
            ;;
    esac
}

# ==============================================================================
# Main Function
# ==============================================================================

main() {
    print_header "Power Platform Service Principal Permission Assignment"
    print_status "Automating System Administrator role assignment for Terraform service principal"
    echo ""
    
    parse_arguments "$@"
    validate_prerequisites
    load_configuration
    validate_pac_authentication
    get_environments
    prompt_confirmation
    process_environments
    display_summary
    
    print_success "Service principal permission assignment completed"
    print_status "Next steps: Re-run Terraform configuration to validate permission resolution"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi