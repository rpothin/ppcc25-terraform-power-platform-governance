#!/bin/bash
# ==============================================================================
# Create GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined setup
# Enhanced with YAML Validation Auto-Fix PAT creation and validation
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

# Function to open PAT creation page (simple Python approach)
open_pat_creation_page() {
    print_status "Setting up GitHub PAT creation..."
    
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    local pat_description="YAML Validation AutoFix for ${GITHUB_REPO}"
    
    # Construct URL with pre-filled settings
    local pat_url="https://github.com/settings/tokens/new"
    pat_url+="?scopes=repo,workflow"
    pat_url+="&description=${pat_description// /+}"
    
    print_status ""
    print_status "🔗 GitHub PAT Creation URL:"
    print_status "$pat_url"
    print_status ""
    
    # Simple Python webbrowser approach
    if command -v python3 >/dev/null 2>&1; then
        print_status "� Opening in browser..."
        if python3 -m webbrowser "$pat_url" 2>/dev/null; then
            print_success "✓ Browser opened successfully"
        else
            print_warning "⚠️  Auto-open failed - please copy the URL above"
        fi
    else
        print_warning "⚠️  Python3 not available - please copy the URL above"
    fi
    
    print_status ""
    print_status "📋 Setup Instructions:"
    print_status "1. Verify these settings are pre-filled:"
    print_status "   • Description: $pat_description"
    print_status "   • Scopes: repo, workflow"
    print_status "2. Set expiration: 90 days (recommended)"
    print_status "3. Click 'Generate token'"
    print_status "4. Copy the generated token immediately"
}

# Function to validate PAT permissions and format
validate_pat_permissions() {
    local pat_token="$1"
    local github_repository="$2"
    
    print_status "Validating PAT format and permissions..."
    
    # Validate PAT format (flexible for both 36 and 40 character variants)
    if [[ ! "$pat_token" =~ ^ghp_[A-Za-z0-9]{36,40}$ ]]; then
        print_warning "⚠️  PAT format doesn't match expected GitHub classic PAT pattern (ghp_...)"
        print_status "Expected format: ghp_ followed by 36-40 alphanumeric characters"
        print_status "Your token length: ${#pat_token} total characters"
        
        if ! get_user_confirmation "Continue with this token anyway?"; then
            return 1
        fi
    else
        print_success "✓ PAT format validation passed"
    fi
    
    print_success "🎉 PAT validation completed successfully!"
    
    return 0
}

# Function to create YAML validation auto-fix PAT
create_yaml_validation_pat() {
    print_status "Setting up YAML Validation Auto-Fix PAT..."
    print_status "=============================================="
    print_status ""
    
    print_warning "📝 GitHub Personal Access Token (Classic) Required"
    print_status ""
    print_status "The YAML validation workflow requires a Personal Access Token to:"
    print_status "  • Auto-commit formatting fixes to YAML files"
    print_status "  • Modify workflow files in .github/workflows/"
    print_status "  • Prevent permission errors during auto-fix operations"
    print_status ""
    print_status "This PAT will be stored as a repository secret (not environment secret)"
    print_status "and can be used by any workflow in this repository."
    print_status ""
    
    if ! get_user_confirmation "Do you want to set up the YAML validation auto-fix PAT now?"; then
        print_status "Skipping YAML validation PAT setup"
        print_warning "⚠️  Without this PAT, YAML auto-fix workflows may fail"
        print_status "You can create it later by running this script again"
        return 0
    fi
    
    setup_yaml_validation_pat_interactive
}

# Function to interactively set up YAML validation PAT
setup_yaml_validation_pat_interactive() {
    print_status ""
    print_status "GitHub PAT Creation Instructions:"
    print_status "================================"
    print_status "You need to create a GitHub Personal Access Token (Classic) with specific permissions."
    print_status ""
    print_status "Required steps:"
    print_status "1. 🌐 Open the GitHub PAT creation page"
    print_status "2. 📝 Set description: 'YAML Validation AutoFix for $GITHUB_REPO'"
    print_status "3. ⏰ Set expiration: 90 days (recommended for security)"
    print_status "4. ✅ Select required scopes:"
    print_status "   ✅ repo (Full control of private repositories)"
    print_status "   ✅ workflow (Update GitHub Action workflows)"
    print_status "5. 🔄 Generate token and copy it immediately"
    print_status ""
    
    # Offer to open PAT creation page
    if get_user_confirmation "🚀 Open GitHub PAT creation page with pre-configured settings?"; then
        open_pat_creation_page
        print_status ""
        print_status "📋 After the page opens:"
        print_status "1. Verify the description and scopes are correct"
        print_status "2. Set expiration period (90 days recommended)"
        print_status "3. Click 'Generate token'"
        print_status "4. Copy the generated token immediately"
        print_status "5. Return to this terminal to continue"
    else
        print_status "Manual setup instructions:"
        print_status "1. Go to: https://github.com/settings/tokens"
        print_status "2. Click 'Generate new token (classic)'"
        print_status "3. Follow the configuration steps above"
    fi
    
    print_status ""
    print_warning "🔐 IMPORTANT: Copy the token immediately after generation!"
    print_warning "GitHub will only show the token once for security reasons."
    print_status ""
    
    # Wait for user to create PAT
    print_status "After creating your PAT, enter it below for validation and storage."
    print_status ""
    
    local pat_token
    local attempt=1
    local max_attempts=3
    
    while [[ $attempt -le $max_attempts ]]; do
        echo -n "🔑 Enter your GitHub PAT (attempt $attempt/$max_attempts): "
        read -r pat_token
        echo ""
        
        if [[ -z "$pat_token" ]]; then
            print_error "❌ PAT cannot be empty. Please try again."
            ((attempt++))
            continue
        fi
        
        # Validate PAT format and permissions
        if validate_pat_permissions "$pat_token" "$GITHUB_OWNER/$GITHUB_REPO"; then
            break
        else
            print_error "❌ PAT validation failed"
            
            if [[ $attempt -eq $max_attempts ]]; then
                print_error "Maximum attempts reached. PAT setup failed."
                print_status "You can run this script again to retry PAT setup"
                return 1
            fi
            
            print_status ""
            if get_user_confirmation "🔄 Try again with a different PAT?"; then
                ((attempt++))
                continue
            else
                print_status "PAT setup cancelled by user"
                return 1
            fi
        fi
    done
    
    # Create repository secret (not environment secret)
    print_status ""
    print_status "Creating YAML_VALIDATION_AUTOFIX_PAT repository secret..."
    
    local secret_name="YAML_VALIDATION_AUTOFIX_PAT"
    local github_repository="$GITHUB_OWNER/$GITHUB_REPO"
    
    if gh secret set "$secret_name" --body "$pat_token" --repo "$github_repository"; then
        print_success "✓ $secret_name repository secret created successfully"
    else
        print_error "✗ Failed to create $secret_name repository secret"
        
        # Clear PAT from memory before returning
        unset pat_token
        return 1
    fi
    
    # Verify the secret was created
    if gh secret list --repo "$github_repository" --json name --jq '.[].name' | grep -q "^$secret_name$"; then
        print_success "✓ Repository secret verified successfully"
    else
        print_warning "⚠️  Could not verify repository secret creation"
    fi
    
    # Clear PAT from memory
    unset pat_token
    
    print_success "🎉 YAML validation PAT setup completed successfully!"
    print_status ""
    print_status "✅ The YAML validation workflow can now:"
    print_status "  • Auto-fix YAML formatting issues"
    print_status "  • Commit changes to workflow files"
    print_status "  • Operate without permission errors"
    print_status ""
    print_warning "🔐 Security reminder:"
    print_status "  • Keep your PAT secure and don't share it"
    print_status "  • Consider regenerating it every 90 days"
    print_status "  • Revoke it immediately if compromised"
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
    
    print_status "Created Repository Secrets:"
    print_status "  ✓ YAML_VALIDATION_AUTOFIX_PAT (for workflow auto-fix)"
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
    print_status "YAML Validation Workflow:"
    print_status "• The YAML validation workflow will now automatically fix formatting issues"
    print_status "• Auto-fix commits use [skip ci] to prevent infinite loops"
    print_status "• You can disable auto-fix by adding [skip-autofix] to commit messages"
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
    print_status ""
    print_success "Repository Setup is now complete!"
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
    
    # Clear any PAT tokens that might still be in memory
    unset pat_token
    
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
    
    # Create YAML validation PAT (optional but recommended)
    create_yaml_validation_pat
    
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