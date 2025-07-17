#!/bin/bash
# ==============================================================================
# Cleanup Azure Resources for Terraform Backend
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined cleanup
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Use utility function for common validation
    validate_common_prerequisites true true false false true
    
    print_success "Prerequisites validated successfully"
}

# Function to get additional user input
get_additional_input() {
    print_status "Additional cleanup options..."
    
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

# Function to delete storage account
delete_storage_account() {
    print_status "Deleting storage account and container: $STORAGE_ACCOUNT_NAME"
    
    # Check if storage account exists
    if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT_NAME not found"
        return 0
    fi
    
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
        exit 1
    fi
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

# Function to update configuration file
update_config() {
    print_status "Updating configuration file..."
    
    local config_file="$SCRIPT_DIR/../setup/config.env"
    
    if [[ -f "$config_file" ]]; then
        # Update configuration file (no backup needed - cleanup operation)
        # Original backup from setup is preserved
        
        # If resource group was deleted, remove it from config too
        if [[ "$DELETE_RESOURCE_GROUP" == "y" || "$DELETE_RESOURCE_GROUP" == "Y" ]]; then
            sed -i '/^RESOURCE_GROUP_NAME=/d' "$config_file"
            sed -i '/^STORAGE_ACCOUNT_NAME=/d' "$config_file"
            sed -i '/^CONTAINER_NAME=/d' "$config_file"
            print_success "✓ Removed backend configuration from config file"
        else
            # Just remove storage account name to indicate it needs to be recreated
            sed -i '/^STORAGE_ACCOUNT_NAME=/d' "$config_file"
            print_success "✓ Removed storage account name from config file"
        fi
        
        print_status "Original configuration backup is preserved at: ${config_file}.backup"
        
        print_status ""
        print_status "To restore pre-setup configuration, run:"
        print_status "  cd ../setup && ./restore-config.sh"
    else
        print_warning "Configuration file not found: $config_file"
    fi
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
    print_status "If you need to recreate the backend, run: ./setup.sh"
}

# Function to clean up variables from environment
cleanup_vars() {
    print_status "Cleaning up variables from memory..."
    
    # Clear variables
    unset RESOURCE_GROUP_NAME
    unset STORAGE_ACCOUNT_NAME
    unset CONTAINER_NAME
    unset DELETE_RESOURCE_GROUP
    unset CONFIRM
    unset DELETE_CONFIRM
    
    # Clear bash history of this session (if running interactively)
    if [[ $- == *i* ]]; then
        history -c 2>/dev/null || true
    fi
    
    print_success "Variables cleared from memory"
}

# Main execution
main() {
    print_status "Starting Terraform backend cleanup for Power Platform governance..."
    print_status "======================================================================"
    
    # Set up trap to clean up on exit
    trap cleanup_vars EXIT
    
    # Initialize configuration
    if ! init_config; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    # Display configuration summary
    print_status "Configuration Summary:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Location: $LOCATION"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Get additional user input
    get_additional_input
    
    # Confirm cleanup
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
    
    # Perform cleanup
    list_terraform_state_files
    cleanup_deployment_history
    delete_storage_account
    delete_resource_group
    verify_cleanup
    update_config
    output_cleanup_summary
    
    # Clean up variables
    cleanup_vars
    
    print_success "Cleanup script completed successfully!"
    
    # Disable trap since we're cleaning up manually
    trap - EXIT
}

# Run the main function
main "$@"
