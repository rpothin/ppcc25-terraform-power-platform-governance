#!/bin/bash
# ==============================================================================
# Cleanup Azure Resources for Terraform Backend
# ==============================================================================
# This script removes the Azure resources created for Terraform state storage:
# - Storage Container
# - Storage Account
# - Resource Group (optional)
# WARNING: This will permanently delete all Terraform state files!
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
    print_status "Gathering cleanup configuration information..."
    
    # Get resource group name
    echo -n "Enter resource group name (default: rg-terraform-powerplatform-governance): "
    read -r RESOURCE_GROUP_NAME
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
        RESOURCE_GROUP_NAME="rg-terraform-powerplatform-governance"
    fi
    
    # Get storage account name
    echo -n "Enter storage account name (from previous setup): "
    read -r STORAGE_ACCOUNT_NAME
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        print_error "Storage account name is required for cleanup"
        exit 1
    fi
    
    # Get container name
    echo -n "Enter container name (default: terraform-state): "
    read -r CONTAINER_NAME
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
    fi
    
    # Ask if user wants to delete the entire resource group
    echo -n "Delete entire resource group? This will remove ALL resources in the group (y/n, default: n): "
    read -r DELETE_RESOURCE_GROUP
    if [[ -z "$DELETE_RESOURCE_GROUP" ]]; then
        DELETE_RESOURCE_GROUP="n"
    fi
    
    print_status "Cleanup Configuration:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Delete Resource Group: $DELETE_RESOURCE_GROUP"
    
    print_warning "WARNING: This operation will permanently delete:"
    print_warning "  - All Terraform state files in the container"
    print_warning "  - The storage container"
    print_warning "  - The storage account"
    if [[ "$DELETE_RESOURCE_GROUP" == "y" || "$DELETE_RESOURCE_GROUP" == "Y" ]]; then
        print_warning "  - The entire resource group and ALL its resources"
    fi
    
    echo -n "Are you sure you want to proceed? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        exit 1
    fi
    
    echo -n "Type 'DELETE' to confirm: "
    read -r DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" != "DELETE" ]]; then
        print_error "Cleanup cancelled - confirmation not received"
        exit 1
    fi
}

# Function to list terraform state files before deletion
list_terraform_state_files() {
    print_status "Listing Terraform state files that will be deleted..."
    
    # Check if storage account exists
    if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT_NAME not found in resource group $RESOURCE_GROUP_NAME"
        return 0
    fi
    
    # List blobs in container
    print_status "Terraform state files in container '$CONTAINER_NAME':"
    if az storage blob list \
        --container-name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --query "[].name" \
        --output table 2>/dev/null; then
        print_success "Listed state files successfully"
    else
        print_warning "Could not list state files or container is empty"
    fi
}

# Function to delete deployment history (optional cleanup)
cleanup_deployment_history() {
    print_status "Cleaning up deployment history..."
    
    # Get deployments related to terraform backend
    DEPLOYMENTS=$(az deployment group list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[?contains(name, 'terraform-backend')].name" \
        --output tsv 2>/dev/null || echo "")
    
    if [[ -n "$DEPLOYMENTS" ]]; then
        print_status "Found deployment history to clean up:"
        echo "$DEPLOYMENTS" | while read -r deployment; do
            if [[ -n "$deployment" ]]; then
                print_status "  - $deployment"
                az deployment group delete \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --name "$deployment" \
                    --no-wait 2>/dev/null || true
            fi
        done
        print_success "Deployment history cleanup initiated"
    else
        print_status "No deployment history found to clean up"
    fi
}
delete_storage_account_avm() {
    print_status "Deleting AVM-deployed storage account and container: $STORAGE_ACCOUNT_NAME"
    
    # Check if storage account exists
    if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT_NAME not found"
        return 0
    fi
    
    # Create a temporary directory for Bicep cleanup
    TEMP_DIR=$(mktemp -d)
    BICEP_FILE="$TEMP_DIR/cleanup-storage-account.bicep"
    
    # Create a simple Bicep file to clean up the storage account
    cat > "$BICEP_FILE" << 'EOF'
@description('Name of the Storage Account to delete.')
param storageAccountName string

@description('Location for the deployment.')
param location string = resourceGroup().location

// This will effectively remove the storage account by not deploying anything
// The actual deletion will be handled by the Azure CLI command
resource placeholder 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'placeholder-${utcNow()}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

output message string = 'Storage account ${storageAccountName} will be deleted via Azure CLI'
EOF

    # First, try to delete the container if it exists
    print_status "Attempting to delete container: $CONTAINER_NAME"
    if az storage container delete \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --fail-not-exist 2>/dev/null; then
        print_success "Container deleted successfully"
    else
        print_warning "Container may not exist or already deleted"
    fi
    
    # Delete the storage account
    print_status "Deleting storage account: $STORAGE_ACCOUNT_NAME"
    if az storage account delete \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --yes; then
        print_success "Storage account deleted successfully"
    else
        print_error "Failed to delete storage account"
        # Clean up temp files
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Clean up temp files
    rm -rf "$TEMP_DIR"
}

# Function to delete resource group
delete_resource_group() {
    if [[ "$DELETE_RESOURCE_GROUP" == "y" || "$DELETE_RESOURCE_GROUP" == "Y" ]]; then
        print_status "Deleting resource group: $RESOURCE_GROUP_NAME"
        
        # Check if resource group exists
        if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
            
            # Delete resource group
            az group delete \
                --name "$RESOURCE_GROUP_NAME" \
                --yes \
                --no-wait
            
            if [[ $? -eq 0 ]]; then
                print_success "Resource group deletion initiated (running in background)"
                print_status "You can check the status with: az group show --name $RESOURCE_GROUP_NAME"
            else
                print_error "Failed to delete resource group"
                exit 1
            fi
        else
            print_warning "Resource group $RESOURCE_GROUP_NAME not found"
        fi
    else
        print_status "Skipping resource group deletion as requested"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if storage account still exists
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_error "Storage account still exists after cleanup"
        return 1
    else
        print_success "✓ Storage account successfully deleted"
    fi
    
    # Check resource group if we tried to delete it
    if [[ "$DELETE_RESOURCE_GROUP" == "y" || "$DELETE_RESOURCE_GROUP" == "Y" ]]; then
        if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
            print_warning "Resource group still exists (deletion may be in progress)"
        else
            print_success "✓ Resource group successfully deleted"
        fi
    fi
    
    print_success "Cleanup verification completed"
}

# Function to output cleanup summary
output_cleanup_summary() {
    print_success "Terraform backend cleanup completed!"
    print_status ""
    print_status "Cleanup Summary:"
    print_status "  ✓ Storage Container: $CONTAINER_NAME (deleted)"
    print_status "  ✓ Storage Account: $STORAGE_ACCOUNT_NAME (deleted)"
    if [[ "$DELETE_RESOURCE_GROUP" == "y" || "$DELETE_RESOURCE_GROUP" == "Y" ]]; then
        print_status "  ✓ Resource Group: $RESOURCE_GROUP_NAME (deletion initiated)"
    else
        print_status "  - Resource Group: $RESOURCE_GROUP_NAME (preserved)"
    fi
    print_status ""
    print_warning "IMPORTANT: All Terraform state files have been permanently deleted!"
    print_warning "You will need to re-import any existing resources if you recreate the backend."
    print_status ""
    print_status "If you need to recreate the backend, run: 02-create-terraform-backend.sh"
}

# Main execution
main() {
    print_status "Starting Terraform backend cleanup for Power Platform governance..."
    print_status "======================================================================"
    
    validate_prerequisites
    get_user_input
    list_terraform_state_files
    cleanup_deployment_history
    delete_storage_account_avm
    delete_resource_group
    verify_cleanup
    output_cleanup_summary
    
    print_success "Cleanup script completed successfully!"
}

# Run the main function
main "$@"
