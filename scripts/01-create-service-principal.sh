#!/bin/bash
# ==============================================================================
# Create Service Principal with OIDC for GitHub and Power Platform Access
# ==============================================================================
# This script creates an Azure AD service principal with the required permissions
# for both Azure and Power Platform, then registers it with Power Platform.
# It also sets up OIDC trust with the GitHub repository.
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
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Power Platform CLI is installed
    if ! command -v pac &> /dev/null; then
        print_error "Power Platform CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if user is logged in to Power Platform
    if ! pac auth list &> /dev/null; then
        print_warning "You are not logged in to Power Platform. Please run 'pac auth create' first."
        print_status "You need to authenticate with Power Platform tenant admin privileges."
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to get user input with validation
get_user_input() {
    print_status "Gathering configuration information..."
    
    # Get GitHub repository information
    echo -n "Enter GitHub repository owner/organization: "
    read -r GITHUB_OWNER
    if [[ -z "$GITHUB_OWNER" ]]; then
        print_error "GitHub owner cannot be empty"
        exit 1
    fi
    
    echo -n "Enter GitHub repository name: "
    read -r GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        print_error "GitHub repository name cannot be empty"
        exit 1
    fi
    
    # Get service principal name (optional)
    echo -n "Enter service principal name (default: terraform-powerplatform-governance): "
    read -r SP_NAME
    if [[ -z "$SP_NAME" ]]; then
        SP_NAME="terraform-powerplatform-governance"
    fi
    
    # Get Azure subscription ID (with current subscription as default)
    CURRENT_SUBSCRIPTION=$(az account show --query id -o tsv)
    echo -n "Enter Azure subscription ID (default: $CURRENT_SUBSCRIPTION): "
    read -r AZURE_SUBSCRIPTION_ID
    if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        AZURE_SUBSCRIPTION_ID="$CURRENT_SUBSCRIPTION"
    fi
    
    # Get tenant ID
    AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
    
    print_status "Configuration:"
    print_status "  GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status "  Service Principal: $SP_NAME"
    print_status "  Azure Subscription: $AZURE_SUBSCRIPTION_ID"
    print_status "  Azure Tenant: $AZURE_TENANT_ID"
    
    echo -n "Continue with this configuration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
}

# Function to create service principal
create_service_principal() {
    print_status "Creating service principal: $SP_NAME"
    
    # Create the service principal
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role "Contributor" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
        --json-auth)
    
    if [[ $? -eq 0 ]]; then
        print_success "Service principal created successfully"
        
        # Extract values from the output
        CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')
        TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenantId')
        SUBSCRIPTION_ID=$(echo "$SP_OUTPUT" | jq -r '.subscriptionId')
        
        # Store in global variables for later use
        AZURE_CLIENT_ID="$CLIENT_ID"
        
        print_status "Service Principal Details:"
        print_status "  Client ID: $CLIENT_ID"
        print_status "  Tenant ID: $TENANT_ID"
        print_status "  Subscription ID: $SUBSCRIPTION_ID"
    else
        print_error "Failed to create service principal"
        exit 1
    fi
}

# Function to setup OIDC trust with GitHub
setup_github_oidc() {
    print_status "Setting up OIDC trust with GitHub repository..."
    
    # Create federated credential for GitHub Actions
    FEDERATED_CREDENTIAL_NAME="github-actions-main"
    
    # Create the federated credential JSON
    cat > /tmp/federated-credential.json << EOF
{
    "name": "$FEDERATED_CREDENTIAL_NAME",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:$GITHUB_OWNER/$GITHUB_REPO:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF
    
    # Create the federated credential
    az ad app federated-credential create \
        --id "$AZURE_CLIENT_ID" \
        --parameters @/tmp/federated-credential.json
    
    if [[ $? -eq 0 ]]; then
        print_success "OIDC trust configured for GitHub repository"
        rm -f /tmp/federated-credential.json
    else
        print_error "Failed to configure OIDC trust"
        rm -f /tmp/federated-credential.json
        exit 1
    fi
}

# Function to assign additional Azure permissions
assign_azure_permissions() {
    print_status "Assigning additional Azure permissions..."
    
    # Assign Storage Blob Data Contributor for Terraform state
    az role assignment create \
        --assignee "$AZURE_CLIENT_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
        --description "Terraform state storage access"
    
    if [[ $? -eq 0 ]]; then
        print_success "Storage Blob Data Contributor role assigned"
    else
        print_warning "Failed to assign Storage Blob Data Contributor role"
    fi
    
    # Assign Reader role at subscription level (for resource group creation)
    az role assignment create \
        --assignee "$AZURE_CLIENT_ID" \
        --role "Reader" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
        --description "Subscription reader access"
    
    if [[ $? -eq 0 ]]; then
        print_success "Reader role assigned at subscription level"
    else
        print_warning "Failed to assign Reader role"
    fi
}

# Function to register service principal with Power Platform
register_with_power_platform() {
    print_status "Registering service principal with Power Platform..."
    
    # Register the application with Power Platform
    # This grants the service principal access to Power Platform APIs
    pac admin application register \
        --application-id "$AZURE_CLIENT_ID"
    
    if [[ $? -eq 0 ]]; then
        print_success "Service principal registered with Power Platform"
        print_status "The service principal now has Power Platform tenant admin privileges"
    else
        print_error "Failed to register service principal with Power Platform"
        print_error "Please ensure you have Power Platform tenant admin privileges"
        exit 1
    fi
}

# Function to output results
output_results() {
    print_success "Service principal setup completed successfully!"
    print_status ""
    print_status "Please save the following values for the next scripts:"
    print_status ""
    print_status "AZURE_CLIENT_ID: $AZURE_CLIENT_ID"
    print_status "AZURE_TENANT_ID: $AZURE_TENANT_ID"
    print_status "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
    print_status "GITHUB_OWNER: $GITHUB_OWNER"
    print_status "GITHUB_REPO: $GITHUB_REPO"
    print_status ""
    print_status "You can now proceed to run the next script: 02-create-terraform-backend.sh"
}

# Main execution
main() {
    print_status "Starting service principal setup for Power Platform Terraform governance..."
    print_status "=================================================="
    
    validate_prerequisites
    get_user_input
    create_service_principal
    setup_github_oidc
    assign_azure_permissions
    register_with_power_platform
    output_results
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
