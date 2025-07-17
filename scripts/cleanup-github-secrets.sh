#!/bin/bash
# ==============================================================================
# Cleanup GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# This script removes all GitHub secrets created by the 03-create-github-secrets.sh
# script. It uses the GitHub CLI to securely remove the secrets from the repository.
# ==============================================================================

# Note: Not using set -e here to allow graceful handling of partial failures
# set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to validate required tools
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first."
        print_error "Installation instructions: https://cli.github.com/"
        return 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to test GitHub secrets access
test_github_secrets_access() {
    local test_repo="$1"
    
    # Try to list secrets from the repository to test access
    print_status "Testing secrets access for repository: $test_repo"
    
    if gh secret list --repo "$test_repo" --json name &> /dev/null; then
        print_success "✅ GitHub secrets access confirmed"
        return 0
    else
        print_warning "❌ GitHub secrets access failed"
        return 1
    fi
}

# Function to authenticate with GitHub
authenticate_github() {
    print_status "Checking GitHub authentication..."
    
    # First, check if user is logged in to GitHub at all
    if ! gh auth status &> /dev/null; then
        print_status "Not logged in to GitHub. Authentication required."
        perform_github_login
        return $?
    fi
    
    # Check if we have the repo scope needed for secrets by testing a simple API call
    if gh auth status --show-token &> /dev/null; then
        # Test if we can actually use the current token for API operations
        print_status "Testing GitHub authentication with current token..."
        
        if gh api user --silent &> /dev/null; then
            print_success "GitHub authentication verified and working"
            return 0
        else
            print_warning "Current GitHub token has insufficient permissions"
        fi
    fi
    
    # If we get here, we need to re-authenticate
    print_status "GitHub re-authentication required for secrets management..."
    perform_github_login
    return $?
}

# Function to perform GitHub login
perform_github_login() {
    print_status "🔐 Authenticating with GitHub (this will open your browser)..."
    
    # Clear any existing token that might have insufficient scopes
    unset GITHUB_TOKEN
    
    # Authenticate with required scopes for secrets management
    if gh auth login --scopes "repo"; then
        print_success "✅ GitHub authentication successful!"
        
        # Verify the new authentication works
        if gh api user --silent &> /dev/null; then
            print_success "✅ GitHub authentication verified and working"
            return 0
        else
            print_error "GitHub authentication succeeded but API access failed"
            return 1
        fi
    else
        print_error "GitHub authentication failed"
        return 1
    fi
}

# Function to get user input with validation
get_user_input() {
    print_status "Gathering repository information..."
    
    # Get GitHub repository information
    echo -n "Enter GitHub repository (owner/repo format): "
    read -r GITHUB_REPOSITORY
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        print_error "GitHub repository cannot be empty"
        return 1
    fi
    
    # Validate repository format
    if [[ ! "$GITHUB_REPOSITORY" =~ ^[^/]+/[^/]+$ ]]; then
        print_error "Repository must be in owner/repo format"
        return 1
    fi
    
    # Split repository into owner and repo
    GITHUB_OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
    GITHUB_REPO=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
    
    print_status "Repository: $GITHUB_REPOSITORY"
    
    # Warning confirmation
    print_warning "⚠️  This will permanently remove all Power Platform Terraform secrets from the repository!"
    print_warning "This action cannot be undone. Make sure you have saved any necessary values."
    print_status ""
    
    echo -n "Are you sure you want to continue? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        return 1
    fi
    
    echo -n "Type 'DELETE' to confirm secret removal: "
    read -r DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" != "DELETE" ]]; then
        print_error "Cleanup cancelled - confirmation not received"
        return 1
    fi
}

# Function to verify repository access
verify_repository_access() {
    print_status "Verifying repository access..."
    
    # Check if repository exists and user has access
    if gh repo view "$GITHUB_REPOSITORY" &> /dev/null; then
        print_success "Repository access verified"
    else
        print_error "Cannot access repository $GITHUB_REPOSITORY"
        print_error "Please ensure the repository exists and you have admin access"
        return 1
    fi
    
    # Check if user has admin access (required for secrets)
    PERMISSION=$(gh api "repos/$GITHUB_REPOSITORY" --jq '.permissions.admin' 2>/dev/null)
    if [[ "$PERMISSION" != "true" ]]; then
        print_error "You need admin access to the repository to manage secrets"
        return 1
    fi
    
    print_success "Admin access confirmed"
    
    # Test secrets access specifically
    if ! test_github_secrets_access "$GITHUB_REPOSITORY"; then
        print_warning "Secrets access test failed. Attempting re-authentication..."
        
        if perform_github_login; then
            # Test again after re-authentication
            if test_github_secrets_access "$GITHUB_REPOSITORY"; then
                print_success "Secrets access restored after re-authentication"
            else
                print_error "Secrets access still failed after re-authentication"
                return 1
            fi
        else
            print_error "Re-authentication failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to list existing secrets
list_existing_secrets() {
    print_status "Checking existing secrets..."
    
    # Get list of existing secrets
    EXISTING_SECRETS=$(gh secret list --repo "$GITHUB_REPOSITORY" --json name --jq '.[].name')
    
    if [[ -z "$EXISTING_SECRETS" ]]; then
        print_warning "No secrets found in repository"
        return 1
    fi
    
    print_status "Found secrets in repository:"
    echo "$EXISTING_SECRETS" | while read -r secret; do
        if [[ -n "$secret" ]]; then
            print_status "  - $secret"
        fi
    done
    
    return 0
}

# Function to remove Power Platform secrets
remove_secrets() {
    print_status "Removing Power Platform Terraform secrets..."
    
    # Array of secrets to remove (same as created by create-github-secrets.sh)
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
    
    # Remove each secret
    for secret_name in "${SECRETS_TO_REMOVE[@]}"; do
        print_status "Removing secret: $secret_name"
        
        # Try to remove the secret
        if gh secret delete "$secret_name" --repo "$GITHUB_REPOSITORY" 2>/dev/null; then
            print_success "✓ Secret $secret_name removed successfully"
            ((REMOVED_COUNT++))
        else
            # Check if secret exists to determine if it's a failure or not found
            EXISTING_SECRETS_CHECK=$(gh secret list --repo "$GITHUB_REPOSITORY" --json name --jq '.[].name' 2>/dev/null || echo "")
            
            if echo "$EXISTING_SECRETS_CHECK" | grep -q "^$secret_name$" 2>/dev/null; then
                print_error "✗ Failed to remove secret $secret_name"
                ((FAILED_COUNT++))
            else
                print_warning "⚠ Secret $secret_name not found (may have been already removed)"
                ((NOT_FOUND_COUNT++))
            fi
        fi
    done
    
    # Summary
    print_status ""
    print_status "Cleanup Summary:"
    print_status "  ✓ Successfully removed: $REMOVED_COUNT secrets"
    if [[ $NOT_FOUND_COUNT -gt 0 ]]; then
        print_status "  ⚠ Not found: $NOT_FOUND_COUNT secrets"
    fi
    if [[ $FAILED_COUNT -gt 0 ]]; then
        print_status "  ✗ Failed to remove: $FAILED_COUNT secrets"
        print_warning "Some secrets could not be removed, but continuing with cleanup"
    fi
    
    if [[ $REMOVED_COUNT -eq 0 && $NOT_FOUND_COUNT -eq ${#SECRETS_TO_REMOVE[@]} ]]; then
        print_warning "No Power Platform secrets were found to remove"
        return 0
    fi
    
    print_success "Secret cleanup completed successfully"
}

# Function to verify secrets were removed
verify_removal() {
    print_status "Verifying secrets were removed..."
    
    # Get current secrets
    CURRENT_SECRETS=$(gh secret list --repo "$GITHUB_REPOSITORY" --json name --jq '.[].name')
    
    # Check if any Power Platform secrets still exist
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
            print_warning "⚠ Secret $secret still exists"
            FOUND_REMAINING=true
        fi
    done
    
    if [[ "$FOUND_REMAINING" == "true" ]]; then
        print_warning "Some secrets were not removed successfully"
        print_status "This may be expected if some secrets were already removed"
    else
        print_success "All Power Platform secrets successfully removed"
    fi
}

# Function to remove GitHub environment (optional)
remove_github_environment() {
    print_status "Checking for GitHub environment..."
    
    # Check if production environment exists
    if gh api "repos/$GITHUB_REPOSITORY/environments/production" &> /dev/null; then
        print_status "Found production environment"
        
        echo -n "Do you want to remove the production environment as well? (y/n): "
        read -r REMOVE_ENV
        if [[ "$REMOVE_ENV" == "y" || "$REMOVE_ENV" == "Y" ]]; then
            if gh api "repos/$GITHUB_REPOSITORY/environments/production" --method DELETE &> /dev/null; then
                print_success "Production environment removed"
            else
                print_warning "Failed to remove production environment (this is optional)"
            fi
        else
            print_status "Production environment left intact"
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
    print_status "SECURITY NOTICE: All Power Platform Terraform secrets have been"
    print_status "permanently removed from the GitHub repository."
    print_status ""
    print_status "Next Steps:"
    print_status "1. If you plan to use this repository again, run 03-create-github-secrets.sh"
    print_status "2. Any existing GitHub Actions workflows will fail until secrets are recreated"
    print_status "3. Consider cleaning up the Azure Service Principal if no longer needed"
    print_status "4. Consider cleaning up the Terraform backend storage if no longer needed"
    print_status ""
    print_status "Cleanup completed successfully!"
}

# Function to clean up variables from environment
cleanup_vars() {
    print_status "Cleaning up variables from memory..."
    
    # Clear variables
    unset GITHUB_REPOSITORY
    unset GITHUB_OWNER
    unset GITHUB_REPO
    unset CONFIRM
    unset DELETE_CONFIRM
    unset REMOVE_ENV
    
    # Clear bash history of this session (if running interactively)
    if [[ $- == *i* ]]; then
        history -c
    fi
    
    print_success "Variables cleared from memory"
}

# Main execution
main() {
    print_status "Starting GitHub secrets cleanup for Power Platform Terraform governance..."
    print_status "======================================================================="
    
    # Set up trap to clean up on exit
    trap cleanup_vars EXIT
    
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
    
    # Get user input
    if ! get_user_input; then
        print_error "User input validation failed"
        return 1
    fi
    
    # Verify repository access
    if ! verify_repository_access; then
        print_error "Repository access verification failed"
        return 1
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
    return 0
}

# Run the main function
main "$@"
