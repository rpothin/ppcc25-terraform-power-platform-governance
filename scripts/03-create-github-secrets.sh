#!/bin/bash
# ==============================================================================
# Create GitHub Secrets for Terraform Power Platform Governance
# ==============================================================================
# This script creates all the required GitHub secrets for running the
# Terraform plan and apply workflow. It uses the GitHub CLI to securely
# store the secrets in the repository.
# ==============================================================================

set -e  # Exit on any error

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
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to authenticate with GitHub
authenticate_github() {
    print_status "Checking GitHub authentication..."
    
    # Check if user is logged in to GitHub with proper scopes
    if gh auth status --show-token &> /dev/null; then
        # Check if we have the repo scope needed for secrets
        if gh auth token | gh api user --input-token - &> /dev/null; then
            print_success "GitHub authentication verified"
            return 0
        fi
    fi
    
    print_status "GitHub authentication required for secrets management..."
    print_status "🔐 Authenticating with GitHub (this will open your browser)..."
    
    # Clear any existing token that might have insufficient scopes
    unset GITHUB_TOKEN
    
    # Authenticate with required scopes for secrets management
    if gh auth login --scopes "repo"; then
        print_success "✅ GitHub authentication successful!"
    else
        print_error "GitHub authentication failed"
        exit 1
    fi
}

# Function to get user input with validation
get_user_input() {
    print_status "Gathering configuration information..."
    
    # Get GitHub repository information
    echo -n "Enter GitHub repository (owner/repo format): "
    read -r GITHUB_REPOSITORY
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        print_error "GitHub repository cannot be empty"
        exit 1
    fi
    
    # Validate repository format
    if [[ ! "$GITHUB_REPOSITORY" =~ ^[^/]+/[^/]+$ ]]; then
        print_error "Repository must be in owner/repo format"
        exit 1
    fi
    
    # Split repository into owner and repo
    GITHUB_OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
    GITHUB_REPO=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
    
    # Get Azure information
    echo -n "Enter Azure Client ID (Service Principal): "
    read -r AZURE_CLIENT_ID
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "Azure Client ID cannot be empty"
        exit 1
    fi
    
    echo -n "Enter Azure Tenant ID: "
    read -r AZURE_TENANT_ID
    if [[ -z "$AZURE_TENANT_ID" ]]; then
        print_error "Azure Tenant ID cannot be empty"
        exit 1
    fi
    
    echo -n "Enter Azure Subscription ID: "
    read -r AZURE_SUBSCRIPTION_ID
    if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        print_error "Azure Subscription ID cannot be empty"
        exit 1
    fi
    
    # Get Terraform backend information
    echo -n "Enter Terraform Resource Group Name: "
    read -r TERRAFORM_RESOURCE_GROUP
    if [[ -z "$TERRAFORM_RESOURCE_GROUP" ]]; then
        print_error "Terraform Resource Group cannot be empty"
        exit 1
    fi
    
    echo -n "Enter Terraform Storage Account Name: "
    read -r TERRAFORM_STORAGE_ACCOUNT
    if [[ -z "$TERRAFORM_STORAGE_ACCOUNT" ]]; then
        print_error "Terraform Storage Account cannot be empty"
        exit 1
    fi
    
    echo -n "Enter Terraform Container Name: "
    read -r TERRAFORM_CONTAINER
    if [[ -z "$TERRAFORM_CONTAINER" ]]; then
        print_error "Terraform Container cannot be empty"
        exit 1
    fi
    
    print_status "Configuration:"
    print_status "  GitHub Repository: $GITHUB_REPOSITORY"
    print_status "  Azure Client ID: $AZURE_CLIENT_ID"
    print_status "  Azure Tenant ID: $AZURE_TENANT_ID"
    print_status "  Azure Subscription ID: $AZURE_SUBSCRIPTION_ID"
    print_status "  Terraform Resource Group: $TERRAFORM_RESOURCE_GROUP"
    print_status "  Terraform Storage Account: $TERRAFORM_STORAGE_ACCOUNT"
    print_status "  Terraform Container: $TERRAFORM_CONTAINER"
    
    echo -n "Continue with this configuration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        exit 1
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
        exit 1
    fi
    
    # Check if user has admin access (required for secrets)
    PERMISSION=$(gh api "repos/$GITHUB_REPOSITORY" --jq '.permissions.admin')
    if [[ "$PERMISSION" != "true" ]]; then
        print_error "You need admin access to the repository to create secrets"
        exit 1
    fi
    
    print_success "Admin access confirmed"
}

# Function to create GitHub secrets
create_github_secrets() {
    print_status "Creating GitHub secrets..."
    
    # Array of secrets to create
    declare -A SECRETS=(
        ["AZURE_CLIENT_ID"]="$AZURE_CLIENT_ID"
        ["AZURE_TENANT_ID"]="$AZURE_TENANT_ID"
        ["AZURE_SUBSCRIPTION_ID"]="$AZURE_SUBSCRIPTION_ID"
        ["POWER_PLATFORM_CLIENT_ID"]="$AZURE_CLIENT_ID"
        ["POWER_PLATFORM_TENANT_ID"]="$AZURE_TENANT_ID"
        ["TERRAFORM_RESOURCE_GROUP"]="$TERRAFORM_RESOURCE_GROUP"
        ["TERRAFORM_STORAGE_ACCOUNT"]="$TERRAFORM_STORAGE_ACCOUNT"
        ["TERRAFORM_CONTAINER"]="$TERRAFORM_CONTAINER"
    )
    
    # Create each secret
    for secret_name in "${!SECRETS[@]}"; do
        secret_value="${SECRETS[$secret_name]}"
        
        print_status "Creating secret: $secret_name"
        
        # Create or update the secret
        if echo "$secret_value" | gh secret set "$secret_name" --repo "$GITHUB_REPOSITORY"; then
            print_success "✓ Secret $secret_name created successfully"
        else
            print_error "✗ Failed to create secret $secret_name"
            exit 1
        fi
    done
}

# Function to verify secrets were created
verify_secrets() {
    print_status "Verifying created secrets..."
    
    # List all secrets
    EXISTING_SECRETS=$(gh secret list --repo "$GITHUB_REPOSITORY" --json name --jq '.[].name')
    
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
    
    # Create production environment
    gh api "repos/$GITHUB_REPOSITORY/environments/production" \
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
    print_status "Next Steps:"
    print_status "1. Go to your GitHub repository: https://github.com/$GITHUB_REPOSITORY"
    print_status "2. Navigate to Actions tab"
    print_status "3. Run the 'Terraform Plan and Apply' workflow"
    print_status "4. Select your desired configuration and tfvars file"
    print_status ""
    print_status "Repository Setup is now complete!"
    print_status "You can now use the Terraform configurations to manage your Power Platform governance."
}

# Main execution
main() {
    print_status "Starting GitHub secrets setup for Power Platform Terraform governance..."
    print_status "======================================================================="
    
    validate_prerequisites
    authenticate_github
    get_user_input
    verify_repository_access
    create_github_secrets
    verify_secrets
    create_github_environment
    output_instructions
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
