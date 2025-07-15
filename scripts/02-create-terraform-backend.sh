#!/bin/bash
# ==============================================================================
# Create Azure Resources for Terraform Backend
# ==============================================================================
# This script creates the necessary Azure resources for storing Terraform state:
# - Resource Group
# - Storage Account
# - Storage Container
# It also configures proper access permissions for the service principal.
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
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to get user input with validation
get_user_input() {
    print_status "Gathering configuration information..."
    
    # Get service principal client ID
    echo -n "Enter the service principal client ID from previous step: "
    read -r AZURE_CLIENT_ID
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "Service principal client ID cannot be empty"
        exit 1
    fi
    
    # Get resource group name
    echo -n "Enter resource group name (default: rg-terraform-powerplatform-governance): "
    read -r RESOURCE_GROUP_NAME
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
        RESOURCE_GROUP_NAME="rg-terraform-powerplatform-governance"
    fi
    
    # Get storage account name
    echo -n "Enter storage account name (default: stterraformpp<random>): "
    read -r STORAGE_ACCOUNT_NAME
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        # Generate a random suffix for storage account name
        RANDOM_SUFFIX=$(openssl rand -hex 4)
        STORAGE_ACCOUNT_NAME="stterraformpp${RANDOM_SUFFIX}"
    fi
    
    # Validate storage account name
    if [[ ! "$STORAGE_ACCOUNT_NAME" =~ ^[a-z0-9]{3,24}$ ]]; then
        print_error "Storage account name must be 3-24 characters, lowercase letters and numbers only"
        exit 1
    fi
    
    # Get container name
    echo -n "Enter container name (default: terraform-state): "
    read -r CONTAINER_NAME
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
    fi
    
    # Get location
    echo -n "Enter Azure location (default: East US): "
    read -r LOCATION
    if [[ -z "$LOCATION" ]]; then
        LOCATION="East US"
    fi
    
    # Get current subscription and tenant info
    AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
    
    print_status "Configuration:"
    print_status "  Service Principal ID: $AZURE_CLIENT_ID"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Location: $LOCATION"
    print_status "  Subscription: $AZURE_SUBSCRIPTION_ID"
    print_status "  Tenant: $AZURE_TENANT_ID"
    
    echo -n "Continue with this configuration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
}

# Function to create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP_NAME"
    
    # Check if resource group already exists
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Resource group $RESOURCE_GROUP_NAME already exists"
        return 0
    fi
    
    # Create resource group
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags \
            purpose="terraform-state" \
            project="power-platform-governance" \
            environment="shared"
    
    if [[ $? -eq 0 ]]; then
        print_success "Resource group created successfully"
    else
        print_error "Failed to create resource group"
        exit 1
    fi
}

# Function to create storage account
create_storage_account() {
    print_status "Creating storage account: $STORAGE_ACCOUNT_NAME"
    
    # Check if storage account already exists
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT_NAME already exists"
    else
        # Create storage account
        az storage account create \
            --name "$STORAGE_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --sku "Standard_LRS" \
            --kind "StorageV2" \
            --access-tier "Hot" \
            --https-only true \
            --min-tls-version "TLS1_2" \
            --allow-blob-public-access false \
            --tags \
                purpose="terraform-state" \
                project="power-platform-governance" \
                environment="shared"
        
        if [[ $? -eq 0 ]]; then
            print_success "Storage account created successfully"
        else
            print_error "Failed to create storage account"
            exit 1
        fi
    fi
    
    # Enable versioning and soft delete for better state management
    print_status "Configuring storage account features..."
    
    # Enable versioning
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --enable-versioning true
    
    # Enable soft delete
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --enable-delete-retention true \
        --delete-retention-days 7
    
    print_success "Storage account features configured"
}

# Function to create storage container
create_storage_container() {
    print_status "Creating storage container: $CONTAINER_NAME"
    
    # Get storage account key
    STORAGE_KEY=$(az storage account keys list \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[0].value" -o tsv)
    
    # Check if container already exists
    if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$STORAGE_KEY" &> /dev/null; then
        print_warning "Storage container $CONTAINER_NAME already exists"
    else
        # Create container
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --account-key "$STORAGE_KEY" \
            --public-access off
        
        if [[ $? -eq 0 ]]; then
            print_success "Storage container created successfully"
        else
            print_error "Failed to create storage container"
            exit 1
        fi
    fi
}

# Function to configure service principal permissions
configure_permissions() {
    print_status "Configuring service principal permissions..."
    
    # Get storage account resource ID
    STORAGE_ACCOUNT_ID=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    # Assign Storage Blob Data Contributor role to service principal
    az role assignment create \
        --assignee "$AZURE_CLIENT_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --description "Terraform state storage access"
    
    if [[ $? -eq 0 ]]; then
        print_success "Storage Blob Data Contributor role assigned"
    else
        print_warning "Failed to assign Storage Blob Data Contributor role"
    fi
    
    # Assign Contributor role to resource group for service principal
    RESOURCE_GROUP_ID=$(az group show \
        --name "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    az role assignment create \
        --assignee "$AZURE_CLIENT_ID" \
        --role "Contributor" \
        --scope "$RESOURCE_GROUP_ID" \
        --description "Resource group management access"
    
    if [[ $? -eq 0 ]]; then
        print_success "Contributor role assigned to resource group"
    else
        print_warning "Failed to assign Contributor role to resource group"
    fi
}

# Function to test backend configuration
test_backend_configuration() {
    print_status "Testing Terraform backend configuration..."
    
    # Create a temporary directory for testing
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Create a minimal Terraform configuration to test backend
    cat > main.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "test.tfstate"
  }
}

resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo 'Backend test successful'"
  }
}
EOF
    
    # Initialize Terraform (this will test the backend configuration)
    if terraform init; then
        print_success "Terraform backend configuration test passed"
    else
        print_error "Terraform backend configuration test failed"
        cd - > /dev/null
        rm -rf "$TEST_DIR"
        exit 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEST_DIR"
}

# Function to output results
output_results() {
    print_success "Terraform backend setup completed successfully!"
    print_status ""
    print_status "Backend Configuration Details:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Location: $LOCATION"
    print_status ""
    print_status "Add these values to your Terraform configuration:"
    print_status ""
    print_status "terraform {"
    print_status "  backend \"azurerm\" {"
    print_status "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
    print_status "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
    print_status "    container_name       = \"$CONTAINER_NAME\""
    print_status "    key                  = \"<your-state-file-name>.tfstate\""
    print_status "  }"
    print_status "}"
    print_status ""
    print_status "Save the following values for the GitHub secrets setup:"
    print_status ""
    print_status "TERRAFORM_RESOURCE_GROUP: $RESOURCE_GROUP_NAME"
    print_status "TERRAFORM_STORAGE_ACCOUNT: $STORAGE_ACCOUNT_NAME"
    print_status "TERRAFORM_CONTAINER: $CONTAINER_NAME"
    print_status ""
    print_status "You can now proceed to run the next script: 03-create-github-secrets.sh"
}

# Main execution
main() {
    print_status "Starting Terraform backend setup for Power Platform governance..."
    print_status "================================================================="
    
    validate_prerequisites
    get_user_input
    create_resource_group
    create_storage_account
    create_storage_container
    configure_permissions
    test_backend_configuration
    output_results
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
