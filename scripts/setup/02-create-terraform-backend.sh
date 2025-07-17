#!/bin/bash
# ==============================================================================
# Create Azure Resources for Terraform Backend
# ==============================================================================
# This script creates the necessary Azure resources for storing Terraform state:
# - Resource Group
# - Storage Account (with network access denied by default)
# - Storage Container
# It also configures proper access permissions for the service principal.
# Network access is managed via Just-In-Time (JIT) approach in GitHub Actions.
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
    print_status "  Service Principal ID: [REDACTED - will be used securely]"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Location: $LOCATION"
    print_status "  Network Access: Deny all by default (JIT access via GitHub Actions)"
    print_status "  Subscription: [REDACTED - current authenticated subscription]"
    print_status "  Tenant: [REDACTED - current authenticated tenant]"
    
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

# Function to create storage account and container using AVM Bicep
create_storage_account_and_container() {
    print_status "Creating storage account and container using Azure Verified Modules (AVM)"
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BICEP_FILE="$SCRIPT_DIR/terraform-backend-storage.bicep"
    
    # Verify the Bicep file exists
    if [[ ! -f "$BICEP_FILE" ]]; then
        print_error "Bicep template file not found: $BICEP_FILE"
        exit 1
    fi
    
    # Create a temporary directory for parameters file
    TEMP_DIR=$(mktemp -d)
    PARAMS_FILE="$TEMP_DIR/storage-account.parameters.json"

    # Create the parameters file
    cat > "$PARAMS_FILE" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "$STORAGE_ACCOUNT_NAME"
    },
    "containerName": {
      "value": "$CONTAINER_NAME"
    },
    "servicePrincipalClientId": {
      "value": "$AZURE_CLIENT_ID"
    },
    "tags": {
      "value": {
        "purpose": "terraform-state",
        "project": "power-platform-governance",
        "environment": "shared"
      }
    }
  }
}
EOF

    # Deploy the Bicep template
    print_status "Deploying storage account and container using Bicep template: $(basename "$BICEP_FILE")"
    
    DEPLOYMENT_NAME="terraform-backend-$(date +%s)"
    
    if az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$BICEP_FILE" \
        --parameters "@$PARAMS_FILE" \
        --name "$DEPLOYMENT_NAME" \
        --output table; then
        print_success "Storage account and container deployed successfully using AVM Bicep"
    else
        print_error "Failed to deploy storage account and container using Bicep"
        # Clean up temp files
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Clean up temp files
    rm -rf "$TEMP_DIR"
    
    print_success "Storage account and container configuration completed"
    
    # Assign Storage Blob Data Contributor role to current user for testing
    print_status "Assigning Storage Blob Data Contributor role to current user for testing..."
    CURRENT_USER=$(az account show --query user.name -o tsv)
    STORAGE_ACCOUNT_ID=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    if az role assignment create \
        --assignee "$CURRENT_USER" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output none; then
        print_success "✓ Storage Blob Data Contributor role assigned to current user"
    else
        print_warning "Failed to assign Storage Blob Data Contributor role to current user"
        print_status "This may affect testing but won't impact production functionality"
    fi
}

# Function to validate service principal permissions
validate_service_principal_permissions() {
    print_status "Validating service principal permissions..."
    
    # Verify Owner role assignment (should already exist from previous script)
    print_status "Verifying Owner role assignment at subscription level..."
    if az role assignment list \
        --assignee "$AZURE_CLIENT_ID" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
        --role "Owner" \
        --query "[0].roleDefinitionName" -o tsv | grep -q "Owner"; then
        print_success "✓ Owner role confirmed at subscription level"
        print_status "  This provides comprehensive permissions including:"
        print_status "    - Resource group and storage account management"
        print_status "    - Network access control (for JIT functionality)"
        print_status "    - Role assignments and access management"
    else
        print_error "Owner role not found. Please run 01-create-service-principal.sh first"
        exit 1
    fi
    
    # Note: The Bicep template automatically assigns 'Storage Blob Data Contributor' 
    # role to the service principal at the storage account level for Terraform state access
    print_status "Note: Bicep template automatically assigns 'Storage Blob Data Contributor' role"
    print_status "to the service principal for Terraform state storage access"
    print_status "Current user also has 'Storage Blob Data Contributor' role for testing"
    
    print_success "Service principal permissions validated successfully"
}

# Function to validate deployment completion
validate_deployment_completion() {
    print_status "Validating deployment completion..."
    print_status "================================="
    
    # Ensure required variables are set with defaults if empty
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
    fi
    
    # Verify that the Bicep deployment completed successfully
    print_status "Checking Bicep deployment status..."
    LATEST_DEPLOYMENT=$(az deployment group list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[?contains(name, 'terraform-backend')] | sort_by(@, &properties.timestamp) | [-1]" \
        --output json)
    
    if [[ -n "$LATEST_DEPLOYMENT" ]]; then
        DEPLOYMENT_STATE=$(echo "$LATEST_DEPLOYMENT" | jq -r '.properties.provisioningState')
        DEPLOYMENT_NAME=$(echo "$LATEST_DEPLOYMENT" | jq -r '.name')
        
        if [[ "$DEPLOYMENT_STATE" == "Succeeded" ]]; then
            print_success "✓ Bicep deployment '$DEPLOYMENT_NAME' completed successfully"
            print_status "  This confirms that all resources were created correctly:"
            print_status "    - Storage account with network access controls"
            print_status "    - Blob container for Terraform state"
            print_status "    - Service principal permissions"
            print_status "    - Network rules configuration"
        else
            print_error "✗ Bicep deployment failed with state: $DEPLOYMENT_STATE"
            return 1
        fi
    else
        print_error "✗ No terraform-backend deployment found"
        return 1
    fi
    
    # Verify JIT network access script exists for GitHub Actions
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    JIT_SCRIPT="$SCRIPT_DIR/jit-network-access.sh"
    
    if [[ -f "$JIT_SCRIPT" ]]; then
        print_success "✓ JIT network access script is available for GitHub Actions"
    else
        print_error "✗ JIT network access script not found: $JIT_SCRIPT"
        return 1
    fi
    
    print_success "All deployment validation checks passed!"
    print_status ""
    print_status "Next Steps:"
    print_status "  1. The Terraform backend is ready for use"
    print_status "  2. GitHub Actions will use the JIT network access script automatically"
    print_status "  3. Proceed with GitHub secrets setup: 03-create-github-secrets.sh"
}

# Function to output results
output_results() {
    print_success "Terraform backend setup completed successfully!"
    print_status ""
    
    # Ensure required variables are set with defaults if empty
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
    fi
    
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
    print_status "NOTE: You will also need the Service Principal Client ID, Tenant ID,"
    print_status "and Subscription ID from the previous script for the GitHub secrets setup."
    print_status ""
    print_status "JIT Network Access:"
    print_status "The storage account is configured with network access denied by default."
    print_status "Use the jit-network-access.sh script to manage temporary IP access:"
    print_status "  export STORAGE_ACCOUNT_NAME=\"$STORAGE_ACCOUNT_NAME\""
    print_status "  export RESOURCE_GROUP_NAME=\"$RESOURCE_GROUP_NAME\""
    print_status "  export RUNNER_IP=\"<your-ip-address>\""
    print_status "  ./jit-network-access.sh add    # Add IP access"
    print_status "  ./jit-network-access.sh remove # Remove IP access"
    print_status ""
    print_status "You can now proceed to run the next script: 03-create-github-secrets.sh"
}

# Main execution
main() {
    print_status "Starting Terraform backend setup for Power Platform governance..."
    print_status "Using Azure Verified Modules (AVM) with Just-In-Time (JIT) network access"
    print_status "================================================================="
    
    validate_prerequisites
    get_user_input
    create_resource_group
    create_storage_account_and_container
    validate_service_principal_permissions
    validate_deployment_completion
    output_results
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
