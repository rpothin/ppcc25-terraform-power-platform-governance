#!/bin/bash
# ==============================================================================
# Script Name: Assign Service Principal Permissions to Power Platform Environments
# ==============================================================================
# Purpose: Add the Terraform service principal as System Administrator on all Power Platform environments
# 
# Usage:
#   ./scripts/setup/assign-service-principal-permissions.sh [OPTIONS]
#   
# Examples:
#   ./scripts/setup/assign-service-principal-permissions.sh
#   ./scripts/setup/assign-service-principal-permissions.sh --config custom.env
#   ./scripts/setup/assign-service-principal-permissions.sh --auto-approve
#   ./scripts/setup/assign-service-principal-permissions.sh --environment "specific-env-id"
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
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/common.sh"

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

# Cleanup function
cleanup() {
    print_step "Cleaning up temporary resources..."
    # No temporary resources to clean up in this script
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
automation) the necessary permissions to manage Power Platform environments. This addresses
the permission requirements needed for the duplicate protection logic and Dataverse operations.

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
    $0 --config custom.env --auto-approve          # Custom config file

PERMISSION CONTEXT:
    This script addresses the "access denied" errors encountered when Terraform attempts
    to read existing environments for duplicate protection. The service principal needs
    System Administrator role on environments to access Dataverse metadata endpoints.

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
    
    # Source configuration with error handling
    if ! source "$CONFIG_FILE"; then
        print_error "Failed to load configuration from: $CONFIG_FILE"
        return 1
    fi
    
    # Validate required configuration
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
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed (required for JSON processing)"
        print_status "Install jq: sudo apt-get install jq"
        return 1
    fi
    
    # Check if pac CLI is installed
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
    
    # Check authentication status with retry
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        # Remove --json flag as pac auth list doesn't support it
        if pac auth list &> /dev/null; then
            print_success "Power Platform CLI authentication validated"
            
            # Additional check: verify we have an active authentication
            local auth_output
            if auth_output=$(pac auth list 2>/dev/null); then
                if echo "$auth_output" | grep -q "\*"; then
                    print_status "Active authentication profile found"
                else
                    print_warning "No active authentication profile found"
                fi
            fi
            
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

# Get list of environments using simplified JSON-to-array conversion
get_environments() {
    print_step "Retrieving Power Platform environments..."
    
    # Get JSON output directly
    local environments_json
    if ! environments_json=$(pac admin list --json 2>/dev/null); then
        print_error "Failed to retrieve environments list"
        print_status "Ensure you have Power Platform Administrator permissions"
        return 1
    fi
    
    # Validate JSON output
    if ! echo "$environments_json" | jq empty 2>/dev/null; then
        print_error "Invalid JSON response from pac admin list"
        return 1
    fi
    
    # Convert JSON to arrays using readarray
    local env_ids=()
    local env_names=()
    local env_types=()
    
    # Extract environment IDs into array
    if ! readarray -t env_ids < <(echo "$environments_json" | jq -r '.[].EnvironmentId'); then
        print_error "Failed to extract environment IDs"
        return 1
    fi
    
    # Extract environment names into array
    if ! readarray -t env_names < <(echo "$environments_json" | jq -r '.[].DisplayName'); then
        print_error "Failed to extract environment names"
        return 1
    fi
    
    # Extract environment types into array
    if ! readarray -t env_types < <(echo "$environments_json" | jq -r '.[].Type'); then
        print_error "Failed to extract environment types"
        return 1
    fi
    
    # Count environment IDs
    local env_count=${#env_ids[@]}
    
    # Validate we have environments
    if [[ $env_count -eq 0 ]]; then
        print_error "No environments found"
        return 1
    fi
    
    # Set global variable
    TOTAL_ENVIRONMENTS=$env_count
    
    print_success "Found $TOTAL_ENVIRONMENTS Power Platform environments"
    
    # Debug output if enabled
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "=== ENVIRONMENT ARRAYS DEBUG ===" >&2
        echo "Environment IDs:" >&2
        printf '  "%s"\n' "${env_ids[@]}" >&2
        echo "Environment Names:" >&2
        printf '  "%s"\n' "${env_names[@]}" >&2
        echo "Environment Types:" >&2
        printf '  "%s"\n' "${env_types[@]}" >&2
        echo "================================" >&2
        
        # Show first environment as example
        if [[ ${#env_ids[@]} -gt 0 ]]; then
            echo "First environment: ${env_names[0]} (${env_ids[0]}) - ${env_types[0]}" >&2
        fi
    fi
    
    # Set global arrays directly (more reliable than declare -ga)
    ENVIRONMENT_IDS=("${env_ids[@]}")
    ENVIRONMENT_NAMES=("${env_names[@]}")
    ENVIRONMENT_TYPES=("${env_types[@]}")
    
    # Return the original JSON for backward compatibility (if needed)
    echo "$environments_json"
}

# Assign service principal to environment
assign_service_principal_to_environment() {
    local environment_id="$1"
    local environment_name="$2"
    
    print_step "Processing environment: $environment_name ($environment_id)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_status "[DRY RUN] Would assign service principal $AZURE_CLIENT_ID as '$ROLE_NAME' to environment: $environment_name"
        # SAFER INCREMENT
        SUCCESSFUL_ASSIGNMENTS=$((SUCCESSFUL_ASSIGNMENTS + 1))
        return 0
    fi
    
    # Execute with retry logic
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

# Process all environments using the global arrays
process_environments() {
    print_step "Starting service principal assignment process..."

    # 🔍 CRITICAL DEBUG: Check array state
    echo "=== ARRAY DEBUG IN process_environments() ===" >&2
    echo "TOTAL_ENVIRONMENTS: $TOTAL_ENVIRONMENTS" >&2
    echo "ENVIRONMENT_IDS array length: ${#ENVIRONMENT_IDS[@]}" >&2
    echo "ENVIRONMENT_IDS indices: ${!ENVIRONMENT_IDS[@]}" >&2
    echo "ENVIRONMENT_IDS contents: ${ENVIRONMENT_IDS[*]}" >&2
    echo "=============================================" >&2
    
    if [[ "$SPECIFIC_ENVIRONMENT" != "" ]]; then
        # Process single environment - find it in the arrays
        local found=false
        for i in "${!ENVIRONMENT_IDS[@]}"; do
            if [[ "${ENVIRONMENT_IDS[$i]}" == "$SPECIFIC_ENVIRONMENT" ]]; then
                assign_service_principal_to_environment "${ENVIRONMENT_IDS[$i]}" "${ENVIRONMENT_NAMES[$i]}"
                found=true
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            print_error "Specified environment not found: $SPECIFIC_ENVIRONMENT"
            return 1
        fi
    else
        # Process all environments using arrays
        echo "DEBUG: About to start for loop with indices: ${!ENVIRONMENT_IDS[@]}" >&2
        for i in "${!ENVIRONMENT_IDS[@]}"; do
            echo "DEBUG: Processing index $i" >&2
            local env_id="${ENVIRONMENT_IDS[$i]}"
            local env_name="${ENVIRONMENT_NAMES[$i]}"
            local env_type="${ENVIRONMENT_TYPES[$i]}"
            
            local current=$((i + 1))
            print_status "Progress: $current/$TOTAL_ENVIRONMENTS [$env_type]"
            
            echo "DEBUG: About to call assign_service_principal_to_environment" >&2
            assign_service_principal_to_environment "$env_id" "$env_name"
            echo "DEBUG: assign_service_principal_to_environment completed with exit code: $?" >&2
            
            echo "DEBUG: About to sleep" >&2
            sleep 1
            echo "DEBUG: Sleep completed, continuing to next iteration" >&2
        done
        echo "DEBUG: For loop completed" >&2
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
            print_status "This resolves permission errors in Terraform duplicate protection logic"
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
    echo "This addresses the 'access denied' errors in Terraform by granting the service"
    echo "principal necessary permissions to read Dataverse metadata for duplicate protection."
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
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Load configuration
    load_configuration
    
    # Validate Power Platform CLI
    validate_pac_authentication
    
    # Get environments and populate global arrays
    get_environments > /dev/null  # Discard JSON output since we use arrays now

    # Confirm operation (TOTAL_ENVIRONMENTS is already set by get_environments)
    prompt_confirmation
    
    # Process environments using the global arrays
    process_environments
    
    # Display results
    display_summary
    
    print_success "Service principal permission assignment completed"
    print_status "Next steps: Re-run Terraform configuration to validate permission resolution"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi