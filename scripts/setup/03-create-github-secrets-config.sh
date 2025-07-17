#!/bin/bash
# ==============================================================================
# Create GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined setup
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Source the configuration loader
source "$SCRIPT_DIR/config-loader.sh"

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Use utility function for GitHub CLI validation
    validate_github_cli
    
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
    
    if verify_repository_access "$test_repo"; then
        print_success "✅ GitHub secrets access confirmed"
        return 0
    else
        print_warning "❌ GitHub secrets access failed"
        return 1
    fi
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

# Function to create GitHub secrets in the production environment
create_github_secrets() {
    print_status "Creating GitHub secrets in production environment..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
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
    
    # Create each secret in the production environment
    for secret_name in "${!SECRETS[@]}"; do
        secret_value="${SECRETS[$secret_name]}"
        
        print_status "Creating environment secret: $secret_name"
        
        # Create or update the secret using utility function
        if create_github_secret "$secret_name" "$secret_value" "$github_repository" "$environment_name"; then
            print_success "✓ Environment secret $secret_name created successfully"
        else
            print_error "✗ Failed to create environment secret $secret_name"
            exit 1
        fi
    done
    
    # Clear sensitive variables from memory
    cleanup_vars SECRETS
}

# Function to verify secrets were created in the production environment
verify_secrets() {
    print_status "Verifying created environment secrets..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local environment_name="production"
    
    # List all environment secrets
    EXISTING_SECRETS=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
    
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
            print_success "✓ Environment secret $secret verified"
        else
            print_error "✗ Environment secret $secret not found"
            exit 1
        fi
    done
    
    print_success "All environment secrets verified successfully"
}

# Function to create GitHub environment (required for secure secrets)
create_github_environment() {
    print_status "Creating GitHub environment for secure secrets management..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Ensure we're using the correct authentication token
    unset GITHUB_TOKEN
    
    # Create production environment - this is now required for secure secrets
    print_status "Creating 'production' environment..."
    
    # Use basic environment creation without advanced protection rules
    # Advanced rules (wait_timer, prevent_self_review) require higher billing plans
    if gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$github_repository/environments/production" \
        -F "deployment_branch_policy[protected_branches]=true" \
        -F "deployment_branch_policy[custom_branch_policies]=false" \
        > /dev/null 2>&1; then
        
        print_success "Production environment created successfully"
        print_status "Environment configured with protected branches policy"
        print_status "Secrets will be stored securely within this environment"
        return 0
    else
        print_error "Failed to create production environment"
        print_error "This is required for secure secrets management"
        print_error "Please ensure you have admin access to the repository"
        exit 1
    fi
}

# Function to output final instructions
output_instructions() {
    print_success "GitHub environment and secrets setup completed successfully!"
    print_status ""
    print_status "Created Environment:"
    print_status "  ✓ Production environment with protected branches policy"
    print_status ""
    print_status "Created Environment Secrets:"
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
    print_status "  • Environment: production"
    print_status "  • Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  • Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  • Container: $CONTAINER_NAME"
    print_status ""
    print_status "Next Steps:"
    print_status "1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO"
    print_status "2. Navigate to Actions tab"
    print_status "3. Run the 'Terraform Plan and Apply' workflow"
    print_status "4. Select your desired configuration and tfvars file"
    print_status "5. Ensure your workflow uses environment: production"
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
    print_status "Starting GitHub environment and secrets setup (configuration-driven)..."
    print_status "====================================================================="
    
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
    
    # Create GitHub environment (required for secure secrets)
    create_github_environment
    
    # Create GitHub secrets in the production environment
    create_github_secrets
    
    # Verify secrets were created
    verify_secrets
    
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
