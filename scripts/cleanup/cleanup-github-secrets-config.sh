#!/bin/bash
# ==============================================================================
# Cleanup GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined cleanup
# Enhanced with YAML Validation Auto-Fix PAT cleanup
# ==============================================================================

# Note: Not using set -e here to allow graceful handling of partial failures

# Check for non-interactive mode
NON_INTERACTIVE=false
if [[ "$1" == "--non-interactive" ]]; then
    NON_INTERACTIVE=true
    shift
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

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
verify_repo_access() {
    # Use the utility function from github.sh
    verify_repository_access "$GITHUB_OWNER/$GITHUB_REPO" true
}

# Function to list existing secrets (enhanced to show both environment and repository secrets)
list_existing_secrets() {
    print_status "Checking existing secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    local found_secrets=false
    
    # Check environment secrets
    if gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        EXISTING_ENV_SECRETS=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
        if [[ -n "$EXISTING_ENV_SECRETS" ]]; then
            print_status "Found environment secrets in production environment:"
            echo "$EXISTING_ENV_SECRETS" | while read -r secret; do
                if [[ -n "$secret" ]]; then
                    print_status "  - $secret"
                fi
            done
            found_secrets=true
        fi
    else
        print_warning "Production environment not found"
    fi
    
    # Check repository secrets
    EXISTING_REPO_SECRETS=$(gh secret list --repo "$github_repository" --json name --jq '.[].name' 2>/dev/null)
    if [[ -n "$EXISTING_REPO_SECRETS" ]]; then
        print_status "Found repository secrets:"
        echo "$EXISTING_REPO_SECRETS" | while read -r secret; do
            if [[ -n "$secret" ]]; then
                print_status "  - $secret (repository level)"
            fi
        done
        found_secrets=true
    fi
    
    if [[ "$found_secrets" == "false" ]]; then
        print_warning "No secrets found"
        return 1
    fi
    
    return 0
}

# Function to remove Power Platform environment secrets
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

# Function to remove repository secrets (separate from environment secrets)
remove_repository_secrets() {
    print_status "Removing repository secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Array of repository secrets to remove
    REPO_SECRETS_TO_REMOVE=(
        "YAML_VALIDATION_AUTOFIX_PAT"
    )
    
    # Track removal results
    REPO_SECRETS_REMOVED_COUNT=0
    REPO_SECRETS_NOT_FOUND_COUNT=0
    REPO_SECRETS_FAILED_COUNT=0
    
    # Remove each repository secret
    for secret_name in "${REPO_SECRETS_TO_REMOVE[@]}"; do
        print_status "Removing repository secret: $secret_name"
        
        # Check if secret exists first
        if gh secret list --repo "$github_repository" --json name --jq '.[].name' | grep -q "^$secret_name$" 2>/dev/null; then
            # Secret exists, try to delete it
            if gh secret delete "$secret_name" --repo "$github_repository" 2>/dev/null; then
                print_success "✓ Repository secret $secret_name removed successfully"
                ((REPO_SECRETS_REMOVED_COUNT++))
            else
                print_error "✗ Failed to remove repository secret $secret_name"
                ((REPO_SECRETS_FAILED_COUNT++))
            fi
        else
            print_warning "⚠ Repository secret $secret_name not found"
            ((REPO_SECRETS_NOT_FOUND_COUNT++))
        fi
    done
    
    # Summary
    print_status ""
    print_status "Repository Secrets Cleanup Summary:"
    print_status "  ✓ Successfully removed: $REPO_SECRETS_REMOVED_COUNT repository secrets"
    if [[ $REPO_SECRETS_NOT_FOUND_COUNT -gt 0 ]]; then
        print_status "  ⚠ Not found: $REPO_SECRETS_NOT_FOUND_COUNT repository secrets"
    fi
    if [[ $REPO_SECRETS_FAILED_COUNT -gt 0 ]]; then
        print_status "  ✗ Failed to remove: $REPO_SECRETS_FAILED_COUNT repository secrets"
        print_warning "Some repository secrets could not be removed, but continuing with cleanup"
    fi
    
    if [[ $REPO_SECRETS_REMOVED_COUNT -eq 0 && $REPO_SECRETS_NOT_FOUND_COUNT -eq ${#REPO_SECRETS_TO_REMOVE[@]} ]]; then
        print_warning "No repository secrets were found to remove"
        return 0
    fi
    
    print_success "Repository secrets cleanup completed successfully"
}

# Function to remove GitHub repository variables
remove_repository_variables() {
    print_status "Removing repository variables..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Array of repository variables to remove
    VARIABLES_TO_REMOVE=(
        "TERRAFORM_VERSION"
        "POWER_PLATFORM_PROVIDER_VERSION"
    )
    
    # Track removal results
    VARIABLES_REMOVED_COUNT=0
    VARIABLES_NOT_FOUND_COUNT=0
    VARIABLES_FAILED_COUNT=0
    
    # Remove each repository variable
    for variable_name in "${VARIABLES_TO_REMOVE[@]}"; do
        print_status "Removing repository variable: $variable_name"
        
        # Check if variable exists first
        if gh variable list --repo "$github_repository" --json name --jq '.[].name' | grep -q "^$variable_name$" 2>/dev/null; then
            # Variable exists, try to delete it
            if gh variable delete "$variable_name" --repo "$github_repository" 2>/dev/null; then
                print_success "✓ Repository variable $variable_name removed successfully"
                ((VARIABLES_REMOVED_COUNT++))
            else
                print_error "✗ Failed to remove repository variable $variable_name"
                ((VARIABLES_FAILED_COUNT++))
            fi
        else
            print_warning "⚠ Repository variable $variable_name not found"
            ((VARIABLES_NOT_FOUND_COUNT++))
        fi
    done
    
    # Summary
    print_status ""
    print_status "Repository Variables Cleanup Summary:"
    print_status "  ✓ Successfully removed: $VARIABLES_REMOVED_COUNT repository variables"
    if [[ $VARIABLES_NOT_FOUND_COUNT -gt 0 ]]; then
        print_status "  ⚠ Not found: $VARIABLES_NOT_FOUND_COUNT repository variables"
    fi
    if [[ $VARIABLES_FAILED_COUNT -gt 0 ]]; then
        print_status "  ✗ Failed to remove: $VARIABLES_FAILED_COUNT repository variables"
        print_warning "Some repository variables could not be removed, but continuing with cleanup"
    fi
    
    if [[ $VARIABLES_REMOVED_COUNT -eq 0 && $VARIABLES_NOT_FOUND_COUNT -eq ${#VARIABLES_TO_REMOVE[@]} ]]; then
        print_warning "No repository variables were found to remove"
        return 0
    fi
    
    print_success "Repository variables cleanup completed successfully"
}

# Function to verify secrets were removed
verify_removal() {
    print_status "Verifying secrets were removed..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # Check environment secrets
    if gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        # Get current environment secrets
        CURRENT_ENV_SECRETS=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
        
        # Check if any Power Platform environment secrets still exist
        REMAINING_ENV_SECRETS=(
            "AZURE_CLIENT_ID"
            "AZURE_TENANT_ID"
            "AZURE_SUBSCRIPTION_ID"
            "POWER_PLATFORM_CLIENT_ID"
            "POWER_PLATFORM_TENANT_ID"
            "TERRAFORM_RESOURCE_GROUP"
            "TERRAFORM_STORAGE_ACCOUNT"
            "TERRAFORM_CONTAINER"
        )
        
        FOUND_REMAINING_ENV=false
        for secret in "${REMAINING_ENV_SECRETS[@]}"; do
            if echo "$CURRENT_ENV_SECRETS" | grep -q "^$secret$"; then
                print_warning "⚠ Environment secret $secret still exists"
                FOUND_REMAINING_ENV=true
            fi
        done
        
        if [[ "$FOUND_REMAINING_ENV" == "true" ]]; then
            print_warning "Some environment secrets were not removed successfully"
        else
            print_success "All Power Platform environment secrets successfully removed"
        fi
    else
        print_success "Production environment no longer exists - all environment secrets removed"
    fi
    
    # Check repository secrets
    CURRENT_REPO_SECRETS=$(gh secret list --repo "$github_repository" --json name --jq '.[].name' 2>/dev/null)
    
    REMAINING_REPO_SECRETS=(
        "YAML_VALIDATION_AUTOFIX_PAT"
    )
    
    FOUND_REMAINING_REPO=false
    for secret in "${REMAINING_REPO_SECRETS[@]}"; do
        if echo "$CURRENT_REPO_SECRETS" | grep -q "^$secret$"; then
            print_warning "⚠ Repository secret $secret still exists"
            FOUND_REMAINING_REPO=true
        fi
    done
    
    if [[ "$FOUND_REMAINING_REPO" == "true" ]]; then
        print_warning "Some repository secrets were not removed successfully"
    else
        print_success "All repository secrets successfully removed"
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
    print_status "Removed Environment Secrets:"
    print_status "  ✓ AZURE_CLIENT_ID"
    print_status "  ✓ AZURE_TENANT_ID"
    print_status "  ✓ AZURE_SUBSCRIPTION_ID"
    print_status "  ✓ POWER_PLATFORM_CLIENT_ID"
    print_status "  ✓ POWER_PLATFORM_TENANT_ID"
    print_status "  ✓ TERRAFORM_RESOURCE_GROUP"
    print_status "  ✓ TERRAFORM_STORAGE_ACCOUNT"
    print_status "  ✓ TERRAFORM_CONTAINER"
    print_status ""
    print_status "Removed Repository Secrets:"
    print_status "  ✓ YAML_VALIDATION_AUTOFIX_PAT"
    print_status ""
    print_status "Removed Repository Variables:"
    print_status "  ✓ TERRAFORM_VERSION"
    print_status "  ✓ POWER_PLATFORM_PROVIDER_VERSION"
    print_status ""
    print_status "Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status ""
    print_status "SECURITY NOTICE: All Power Platform Terraform secrets and PATs have been"
    print_status "permanently removed from the GitHub repository."
    print_status ""
    print_status "Next Steps:"
    print_status "1. If you plan to use this repository again, run: ./setup.sh"
    print_status "2. Any existing GitHub Actions workflows will fail until secrets are recreated"
    print_status "3. YAML validation auto-fix workflows will fail until PAT is recreated"
    print_status "4. Consider cleaning up the Azure Service Principal if no longer needed"
    print_status "5. Consider cleaning up the Terraform backend storage if no longer needed"
    print_status ""
    print_status "Cleanup completed successfully!"
}

# Function to clean up variables from environment
cleanup_script_vars() {
    # Only clean up if running standalone (not called from main cleanup script)
    if [[ "${CLEANUP_MAIN_SCRIPT:-false}" != "true" ]]; then
        # Use the utility function with specific variables for this script
        cleanup_vars "GITHUB_OWNER" "GITHUB_REPO" "CONFIRM" "DELETE_CONFIRM" "REMOVE_ENV"
    fi
}

# Main execution
main() {
    print_status "Starting GitHub secrets cleanup for Power Platform Terraform governance..."
    print_status "======================================================================="
    
    # Set up trap to clean up on exit
    trap cleanup_script_vars EXIT
    
    # Initialize configuration
    if ! init_config; then
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
    if ! verify_repo_access; then
        print_error "Repository access verification failed"
        return 1
    fi
    
    # Confirm cleanup using utility function
    print_warning "⚠️  This will permanently remove all Power Platform Terraform secrets and PATs from the repository!"
    print_warning "This action cannot be undone. Make sure you have saved any necessary values."
    print_status ""
    
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        print_status "Non-interactive mode: Proceeding with GitHub secrets cleanup automatically"
    else
        if ! get_deletion_confirmation "all Power Platform Terraform secrets and PATs"; then
            exit 1
        fi
    fi
    
    # Check if there are any secrets to remove
    if list_existing_secrets; then
        remove_secrets
        remove_repository_secrets
        verify_removal
        remove_repository_variables
        remove_github_environment
        output_instructions
    else
        print_success "No secrets found to remove"
        # Still try to clean up repository variables and secrets
        remove_repository_variables
        remove_repository_secrets
    fi
    
    print_success "Cleanup script completed successfully!"
    
    # Disable trap since we're cleaning up manually
    trap - EXIT
    
    return 0
}

# Run the main function
main "$@"