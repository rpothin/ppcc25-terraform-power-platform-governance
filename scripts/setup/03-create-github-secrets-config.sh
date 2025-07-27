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

# Note: Using utility functions from github.sh for repository access and secrets testing

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

# Function to create GitHub repository variables
create_github_variables() {
    print_status "Creating GitHub repository variables..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    # Array of repository variables to create
    declare -A VARIABLES=(
        ["TERRAFORM_VERSION"]="1.12.2"
        ["POWER_PLATFORM_PROVIDER_VERSION"]="~> 3.8"
    )
    
    # Create each repository variable
    for variable_name in "${!VARIABLES[@]}"; do
        variable_value="${VARIABLES[$variable_name]}"
        
        print_status "Creating repository variable: $variable_name"
        
        # Create or update the variable using GitHub CLI
        if gh variable set "$variable_name" --body "$variable_value" --repo "$github_repository"; then
            print_success "✓ Repository variable $variable_name created successfully"
        else
            print_error "✗ Failed to create repository variable $variable_name"
            exit 1
        fi
    done
    
    print_success "Repository variables created successfully"
}

# Note: Using verify_github_secrets from utility functions

# Note: Using create_github_environment from utility functions

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
    print_status "Created Repository Variables:"
    print_status "  ✓ TERRAFORM_VERSION (1.12.2)"
    print_status "  ✓ POWER_PLATFORM_PROVIDER_VERSION (~> 3.8)"
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
    print_status "To update Terraform version:"
    print_status "1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/settings/variables/actions"
    print_status "2. Update TERRAFORM_VERSION repository variable"
    print_status "3. All workflows will automatically use the new version"
    print_status ""
    print_status "To update Power Platform provider version:"
    print_status "1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/settings/variables/actions"
    print_status "2. Update POWER_PLATFORM_PROVIDER_VERSION repository variable"
    print_status "3. All AVM compliance checks will use the new version"
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
    if ! verify_repository_access "$GITHUB_OWNER/$GITHUB_REPO" true; then
        print_error "Repository access verification failed"
        exit 1
    fi
    
    # Create GitHub environment (required for secure secrets)
    if ! create_github_environment "$GITHUB_OWNER/$GITHUB_REPO" "production"; then
        print_error "Failed to create GitHub environment"
        exit 1
    fi
    
    # Create GitHub secrets in the production environment
    create_github_secrets
    
    # Create GitHub repository variables
    create_github_variables
    
    # Verify secrets were created
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
    if ! verify_github_secrets "$GITHUB_OWNER/$GITHUB_REPO" "production" "${REQUIRED_SECRETS[@]}"; then
        print_error "Secrets verification failed"
        exit 1
    fi
    
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
