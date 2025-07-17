#!/bin/bash
# ==============================================================================
# Cleanup GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined cleanup
# ==============================================================================

# Note: Not using set -e here to allow graceful handling of partial failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Source the configuration loader from setup directory
source "$SCRIPT_DIR/../setup/config-loader.sh"

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Use the utility function for GitHub CLI validation
    if ! validate_github_cli true; then
        return 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to verify repository access
verify_repository_access() {
    # Use the utility function
    verify_repository_access "$GITHUB_OWNER/$GITHUB_REPO" true
}

# Function to list existing secrets
list_existing_secrets() {
    print_status "Checking existing environment secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # Check if production environment exists
    if ! gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        print_warning "Production environment not found"
        return 1
    fi
    
    # Get list of existing environment secrets
    EXISTING_SECRETS=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
    
    if [[ -z "$EXISTING_SECRETS" ]]; then
        print_warning "No environment secrets found in production environment"
        return 1
    fi
    
    print_status "Found environment secrets in production environment:"
    echo "$EXISTING_SECRETS" | while read -r secret; do
        if [[ -n "$secret" ]]; then
            print_status "  - $secret"
        fi
    done
    
    return 0
}

# Function to remove Power Platform secrets
remove_secrets() {
    print_status "Removing Power Platform Terraform environment secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # Check if production environment exists
    if ! gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        print_warning "Production environment not found - secrets may have been already cleaned up"
        return 0
    fi
    
    # Array of environment secrets to remove (same as created by create-github-secrets.sh)
    SECRETS_TO_REMOVE=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID"
        "AZURE_SUBSCRIPTION_ID"
        "POWER_PLATFORM_CLIENT_ID"
        "POWER_PLATFORM_TENANT_ID"
        "TERRAFORM_RESOURCE_GROUP"
        "TERRAFORM_STORAGE_ACCOUNT"
        "TERRAFORM_CONTAINER"
    )
    
    # Track removal results
    REMOVED_COUNT=0
    NOT_FOUND_COUNT=0
    FAILED_COUNT=0
    
    # Remove each environment secret using utility function
    for secret_name in "${SECRETS_TO_REMOVE[@]}"; do
        if delete_github_secret "$secret_name" "$github_repository" "$environment_name"; then
            ((REMOVED_COUNT++))
        else
            # Check if secret exists to determine if it's a failure or not found
            EXISTING_SECRETS_CHECK=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null || echo "")
            
            if echo "$EXISTING_SECRETS_CHECK" | grep -q "^$secret_name$" 2>/dev/null; then
                ((FAILED_COUNT++))
            else
                ((NOT_FOUND_COUNT++))
            fi
        fi
    done
    
    # Summary
    print_status ""
    print_status "Environment Secrets Cleanup Summary:"
    print_status "  ✓ Successfully removed: $REMOVED_COUNT environment secrets"
    if [[ $NOT_FOUND_COUNT -gt 0 ]]; then
        print_status "  ⚠ Not found: $NOT_FOUND_COUNT environment secrets"
    fi
    if [[ $FAILED_COUNT -gt 0 ]]; then
        print_status "  ✗ Failed to remove: $FAILED_COUNT environment secrets"
        print_warning "Some environment secrets could not be removed, but continuing with cleanup"
    fi
    
    if [[ $REMOVED_COUNT -eq 0 && $NOT_FOUND_COUNT -eq ${#SECRETS_TO_REMOVE[@]} ]]; then
        print_warning "No Power Platform environment secrets were found to remove"
        return 0
    fi
    
    print_success "Environment secrets cleanup completed successfully"
}

# Function to verify secrets were removed
verify_removal() {
    print_status "Verifying environment secrets were removed..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # Check if production environment still exists
    if ! gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        print_success "Production environment no longer exists - all secrets removed"
        return 0
    fi
    
    # Get current environment secrets
    CURRENT_SECRETS=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
    
    # Check if any Power Platform environment secrets still exist
    REMAINING_SECRETS=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID"
        "AZURE_SUBSCRIPTION_ID"
        "POWER_PLATFORM_CLIENT_ID"
        "POWER_PLATFORM_TENANT_ID"
        "TERRAFORM_RESOURCE_GROUP"
        "TERRAFORM_STORAGE_ACCOUNT"
        "TERRAFORM_CONTAINER"
    )
    
    FOUND_REMAINING=false
    for secret in "${REMAINING_SECRETS[@]}"; do
        if echo "$CURRENT_SECRETS" | grep -q "^$secret$"; then
            print_warning "⚠ Environment secret $secret still exists"
            FOUND_REMAINING=true
        fi
    done
    
    if [[ "$FOUND_REMAINING" == "true" ]]; then
        print_warning "Some environment secrets were not removed successfully"
        print_status "This may be expected if some secrets were already removed"
    else
        print_success "All Power Platform environment secrets successfully removed"
    fi
}

# Function to remove GitHub environment (optional)
remove_github_environment() {
    print_status "Checking for GitHub production environment..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # Check if production environment exists
    if gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        print_status "Found production environment"
        
        if get_user_confirmation "Do you want to remove the production environment as well?"; then
            if delete_github_environment "$github_repository" "$environment_name"; then
                print_status "This also removes any remaining environment secrets"
            else
                print_status "Environment secrets may still exist within the environment"
            fi
        else
            print_status "Production environment left intact"
            print_status "Note: Any remaining environment secrets will stay within the environment"
        fi
    else
        print_status "No production environment found"
    fi
}

# Function to output final instructions
output_instructions() {
    print_success "GitHub secrets cleanup completed successfully!"
    print_status ""
    print_status "Removed Secrets:"
    print_status "  ✓ AZURE_CLIENT_ID"
    print_status "  ✓ AZURE_TENANT_ID"
    print_status "  ✓ AZURE_SUBSCRIPTION_ID"
    print_status "  ✓ POWER_PLATFORM_CLIENT_ID"
    print_status "  ✓ POWER_PLATFORM_TENANT_ID"
    print_status "  ✓ TERRAFORM_RESOURCE_GROUP"
    print_status "  ✓ TERRAFORM_STORAGE_ACCOUNT"
    print_status "  ✓ TERRAFORM_CONTAINER"
    print_status ""
    print_status "Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status ""
    print_status "SECURITY NOTICE: All Power Platform Terraform secrets have been"
    print_status "permanently removed from the GitHub repository."
    print_status ""
    print_status "Next Steps:"
    print_status "1. If you plan to use this repository again, run: ./setup.sh"
    print_status "2. Any existing GitHub Actions workflows will fail until secrets are recreated"
    print_status "3. Consider cleaning up the Azure Service Principal if no longer needed"
    print_status "4. Consider cleaning up the Terraform backend storage if no longer needed"
    print_status ""
    print_status "Cleanup completed successfully!"
}

# Function to clean up variables from environment
cleanup_vars() {
    # Use the utility function with specific variables for this script
    cleanup_vars "GITHUB_OWNER" "GITHUB_REPO" "CONFIRM" "DELETE_CONFIRM" "REMOVE_ENV"
}

# Main execution
main() {
    print_status "Starting GitHub secrets cleanup for Power Platform Terraform governance..."
    print_status "======================================================================="
    
    # Set up trap to clean up on exit
    trap cleanup_vars EXIT
    
    # Initialize configuration
    if ! init_config "$SCRIPT_DIR/../setup/config.env"; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    # Display configuration summary
    print_status "Configuration Summary:"
    print_status "  GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        print_error "Prerequisites validation failed"
        return 1
    fi
    
    # Authenticate with GitHub
    if ! authenticate_github; then
        print_error "GitHub authentication failed"
        return 1
    fi
    
    # Verify repository access
    if ! verify_repository_access; then
        print_error "Repository access verification failed"
        return 1
    fi
    
    # Confirm cleanup using utility function
    print_warning "⚠️  This will permanently remove all Power Platform Terraform secrets from the repository!"
    print_warning "This action cannot be undone. Make sure you have saved any necessary values."
    print_status ""
    
    if ! get_deletion_confirmation "all Power Platform Terraform secrets"; then
        exit 1
    fi
    
    # Check if there are any secrets to remove
    if list_existing_secrets; then
        remove_secrets
        verify_removal
        remove_github_environment
        output_instructions
    else
        print_success "No secrets found to remove"
    fi
    
    cleanup_vars
    
    print_success "Cleanup script completed successfully!"
    
    # Disable trap since we're cleaning up manually
    trap - EXIT
    
    return 0
}

# Run the main function
main "$@"
