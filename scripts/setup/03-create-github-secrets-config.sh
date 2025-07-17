#!/bin/bash
# ==============================================================================
# Create GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined setup
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration loader
source "$SCRIPT_DIR/config-loader.sh"

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

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first."
        print_error "Installation instructions: https://cli.github.com/"
        exit 1
    fi
    
    # Check if required configuration values are set
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "AZURE_CLIENT_ID not found in configuration"
        print_error "Please run previous setup scripts first"
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to test GitHub secrets access
test_github_secrets_access() {
    local test_repo="$1"
    
    print_status "Testing secrets access for repository: $test_repo"
    
    if gh secret list --repo "$test_repo" --json name &> /dev/null; then
        print_success "✅ GitHub secrets access confirmed"
        return 0
    else
        print_warning "❌ GitHub secrets access failed"
        return 1
    fi
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

# Function to authenticate with GitHub
authenticate_github() {
    print_status "Checking GitHub authentication..."
    
    # First, check if user is logged in to GitHub at all
    if ! gh auth status &> /dev/null; then
        print_status "Not logged in to GitHub. Authentication required."
        perform_github_login
        return $?
    fi
    
    # Check if we have the repo scope needed for secrets
    if gh auth status --show-token &> /dev/null; then
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

# Function to verify repository access
verify_repository_access() {
    print_status "Verifying repository access..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Check if repository exists and user has access
    if gh repo view "$github_repository" &> /dev/null; then
        print_success "Repository access verified"
    else
        print_error "Cannot access repository $github_repository"
        print_error "Please ensure the repository exists and you have admin access"
        exit 1
    fi
    
    # Check if user has admin access (required for secrets)
    PERMISSION=$(gh api "repos/$github_repository" --jq '.permissions.admin' 2>/dev/null)
    if [[ "$PERMISSION" != "true" ]]; then
        print_error "You need admin access to the repository to create secrets"
        exit 1
    fi
    
    print_success "Admin access confirmed"
    
    # Test secrets access specifically
    if ! test_github_secrets_access "$github_repository"; then
        print_warning "Secrets access test failed. Attempting re-authentication..."
        
        if perform_github_login; then
            # Test again after re-authentication
            if test_github_secrets_access "$github_repository"; then
                print_success "Secrets access restored after re-authentication"
            else
                print_error "Secrets access still failed after re-authentication"
                exit 1
            fi
        else
            print_error "Re-authentication failed"
            exit 1
        fi
    fi
}

# Function to create GitHub secrets
create_github_secrets() {
    print_status "Creating GitHub secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Array of secrets to create
    declare -A SECRETS=(
        ["AZURE_CLIENT_ID"]="$AZURE_CLIENT_ID"
        ["AZURE_TENANT_ID"]="$AZURE_TENANT_ID"
        ["AZURE_SUBSCRIPTION_ID"]="$AZURE_SUBSCRIPTION_ID"
        ["POWER_PLATFORM_CLIENT_ID"]="$AZURE_CLIENT_ID"
        ["POWER_PLATFORM_TENANT_ID"]="$AZURE_TENANT_ID"
        ["TERRAFORM_RESOURCE_GROUP"]="$RESOURCE_GROUP_NAME"
        ["TERRAFORM_STORAGE_ACCOUNT"]="$STORAGE_ACCOUNT_NAME"
        ["TERRAFORM_CONTAINER"]="$CONTAINER_NAME"
    )
    
    # Create each secret
    for secret_name in "${!SECRETS[@]}"; do
        secret_value="${SECRETS[$secret_name]}"
        
        print_status "Creating secret: $secret_name"
        
        # Create or update the secret securely
        if echo "$secret_value" | gh secret set "$secret_name" --repo "$github_repository" 2>/dev/null; then
            print_success "✓ Secret $secret_name created successfully"
        else
            print_error "✗ Failed to create secret $secret_name"
            exit 1
        fi
    done
    
    # Clear sensitive variables from memory
    unset SECRETS
}

# Function to verify secrets were created
verify_secrets() {
    print_status "Verifying created secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # List all secrets
    EXISTING_SECRETS=$(gh secret list --repo "$github_repository" --json name --jq '.[].name')
    
    # Required secrets
    REQUIRED_SECRETS=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID"
        "AZURE_SUBSCRIPTION_ID"
        "POWER_PLATFORM_CLIENT_ID"
        "POWER_PLATFORM_TENANT_ID"
        "TERRAFORM_RESOURCE_GROUP"
        "TERRAFORM_STORAGE_ACCOUNT"
        "TERRAFORM_CONTAINER"
    )
    
    # Check each required secret
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
            print_success "✓ Secret $secret verified"
        else
            print_error "✗ Secret $secret not found"
            exit 1
        fi
    done
    
    print_success "All secrets verified successfully"
}

# Function to create GitHub environment (optional)
create_github_environment() {
    print_status "Creating GitHub environment for additional security..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Create production environment
    gh api "repos/$github_repository/environments/production" \
        --method PUT \
        --field wait_timer=0 \
        --field prevent_self_review=true \
        --field reviewers='[]' \
        --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
        > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Production environment created"
        print_status "You can configure additional protection rules in the GitHub repository settings"
    else
        print_warning "Failed to create production environment (this is optional)"
    fi
}

# Function to output final instructions
output_instructions() {
    print_success "GitHub secrets setup completed successfully!"
    print_status ""
    print_status "Created Secrets:"
    print_status "  ✓ AZURE_CLIENT_ID"
    print_status "  ✓ AZURE_TENANT_ID"
    print_status "  ✓ AZURE_SUBSCRIPTION_ID"
    print_status "  ✓ POWER_PLATFORM_CLIENT_ID"
    print_status "  ✓ POWER_PLATFORM_TENANT_ID"
    print_status "  ✓ TERRAFORM_RESOURCE_GROUP"
    print_status "  ✓ TERRAFORM_STORAGE_ACCOUNT"
    print_status "  ✓ TERRAFORM_CONTAINER"
    print_status ""
    print_status "Configuration Summary:"
    print_status "  • GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status "  • Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  • Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  • Container: $CONTAINER_NAME"
    print_status ""
    print_status "Next Steps:"
    print_status "1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO"
    print_status "2. Navigate to Actions tab"
    print_status "3. Run the 'Terraform Plan and Apply' workflow"
    print_status "4. Select your desired configuration and tfvars file"
    print_status ""
    print_status "Repository Setup is now complete!"
}

# Function to clean up sensitive variables from environment
cleanup_sensitive_vars() {
    # Prevent double cleanup
    if [[ "${CLEANUP_DONE:-}" == "true" ]]; then
        return 0
    fi
    
    print_status "Cleaning up sensitive variables from memory..."
    
    # Clear all sensitive variables
    unset AZURE_CLIENT_ID
    unset AZURE_TENANT_ID
    unset AZURE_SUBSCRIPTION_ID
    unset RESOURCE_GROUP_NAME
    unset STORAGE_ACCOUNT_NAME
    unset CONTAINER_NAME
    unset GITHUB_OWNER
    unset GITHUB_REPO
    
    # Clear bash history of this session (if running interactively)
    if [[ $- == *i* ]]; then
        history -c 2>/dev/null || true
    fi
    
    # Mark cleanup as done
    CLEANUP_DONE=true
    
    print_success "Sensitive variables cleared from memory"
}

# Main function
main() {
    print_status "Starting GitHub secrets setup (configuration-driven)..."
    print_status "========================================================"
    
    # Set up trap to clean up on exit
    trap cleanup_sensitive_vars EXIT
    
    # Initialize configuration
    if ! init_config; then
        exit 1
    fi
    
    # Validate prerequisites
    validate_prerequisites
    
    # Authenticate with GitHub
    authenticate_github
    
    # Verify repository access
    verify_repository_access
    
    # Create GitHub secrets
    create_github_secrets
    
    # Verify secrets were created
    verify_secrets
    
    # Create GitHub environment (optional)
    create_github_environment
    
    # Output instructions
    output_instructions
    
    # Clean up sensitive variables
    cleanup_sensitive_vars
    
    # Disable the EXIT trap since we're cleaning up manually
    trap - EXIT
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
