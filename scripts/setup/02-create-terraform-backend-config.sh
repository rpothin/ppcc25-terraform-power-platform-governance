#!/bin/bash
# ==============================================================================
# Create Azure Resources for Terraform Backend
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
    
    # Use utility function for common validation
    validate_common_prerequisites true true false false true
    
    # Check if AZURE_CLIENT_ID is set (from previous step)
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "AZURE_CLIENT_ID not found in configuration"
        print_error "Please run 01-create-service-principal-config.sh first"
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
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
    
    # Bicep file path
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
    print_status "Deploying storage account and container using Bicep template..."
    
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
    
    # Verify Owner role assignment
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
        print_error "Owner role not found. Please run 01-create-service-principal-config.sh first"
        exit 1
    fi
    
    print_status "Note: Bicep template automatically assigns 'Storage Blob Data Contributor' role"
    print_status "to the service principal for Terraform state storage access"
    
    print_success "Service principal permissions validated successfully"
}

# Function to validate deployment completion
validate_deployment_completion() {
    print_status "Validating deployment completion..."
    
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
    
    # Verify JIT network access script exists
    JIT_SCRIPT="$SCRIPT_DIR/../jit-network-access.sh"
    
    if [[ -f "$JIT_SCRIPT" ]]; then
        print_success "✓ JIT network access script is available for GitHub Actions"
    else
        print_error "✗ JIT network access script not found: $JIT_SCRIPT"
        return 1
    fi
    
    print_success "All deployment validation checks passed!"
}

# Function to output results
output_results() {
    print_success "Terraform backend setup completed successfully!"
    print_status ""
    print_status "Created Resources:"
    print_status "  ✓ Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  ✓ Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  ✓ Container: $CONTAINER_NAME"
    print_status "  ✓ Location: $LOCATION"
    print_status "  ✓ JIT Network Access: Configured"
    print_status ""
    print_status "Terraform Backend Configuration:"
    print_status "terraform {"
    print_status "  backend \"azurerm\" {"
    print_status "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
    print_status "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
    print_status "    container_name       = \"$CONTAINER_NAME\""
    print_status "    key                  = \"<your-state-file-name>.tfstate\""
    print_status "  }"
    print_status "}"
    print_status ""
    print_status "Configuration saved in: $SCRIPT_DIR/config.env"
}

# Main function
main() {
    print_status "Starting Terraform backend setup (configuration-driven)..."
    print_status "==========================================================="
    
    # Initialize configuration
    if ! init_config; then
        exit 1
    fi
    
    # Validate prerequisites
    validate_prerequisites
    
    # Create resource group
    create_resource_group
    
    # Create storage account and container
    create_storage_account_and_container
    
    # Validate service principal permissions
    validate_service_principal_permissions
    
    # Validate deployment completion
    validate_deployment_completion
    
    # Output results
    output_results
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
