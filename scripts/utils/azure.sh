#!/bin/bash
# ==============================================================================
# Azure Operations Utilities
# ==============================================================================
# Provides common Azure operations functions
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Function to validate Azure authentication
validate_azure_auth() {
    if ! az account show &> /dev/null; then
        print_error "Azure CLI is not authenticated. Please run 'az login' first."
        return 1
    fi
    return 0
}

# Function to get current Azure context
get_azure_context() {
    local subscription_id=$(az account show --query id -o tsv 2>/dev/null)
    local tenant_id=$(az account show --query tenantId -o tsv 2>/dev/null)
    local account_name=$(az account show --query name -o tsv 2>/dev/null)
    
    if [[ -n "$subscription_id" && -n "$tenant_id" ]]; then
        print_success "✓ Azure context obtained"
        print_status "  Subscription: $account_name"
        print_config_item "Subscription ID" "$subscription_id" "true"
        print_config_item "Tenant ID" "$tenant_id" "true"
        
        # Export for use by calling script
        export AZURE_SUBSCRIPTION_ID="$subscription_id"
        export AZURE_TENANT_ID="$tenant_id"
        return 0
    else
        print_error "Failed to get Azure context"
        return 1
    fi
}

# Function to check if Azure resource exists
azure_resource_exists() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_group="$3"
    local additional_params="${4:-}"
    
    case "$resource_type" in
        "group")
            az group show --name "$resource_name" &> /dev/null
            ;;
        "storage-account")
            az storage account show --name "$resource_name" --resource-group "$resource_group" &> /dev/null
            ;;
        "service-principal")
            az ad sp show --id "$resource_name" &> /dev/null
            ;;
        "app-registration")
            az ad app show --id "$resource_name" &> /dev/null
            ;;
        *)
            print_error "Unknown resource type: $resource_type"
            return 1
            ;;
    esac
}

# Function to verify Azure role assignments
verify_azure_role_assignment() {
    local assignee="$1"
    local role="$2"
    local scope="$3"
    
    if az role assignment list \
        --assignee "$assignee" \
        --scope "$scope" \
        --role "$role" \
        --query "[0].roleDefinitionName" -o tsv | grep -q "$role"; then
        print_success "✓ $role role confirmed at scope: $scope"
        return 0
    else
        print_warning "⚠ $role role not found at scope: $scope"
        return 1
    fi
}

# Function to create Azure resource group
create_azure_resource_group() {
    local resource_group_name="$1"
    local location="$2"
    local tags="${3:-}"
    
    print_status "Creating resource group: $resource_group_name"
    
    # Check if resource group already exists
    if azure_resource_exists "group" "$resource_group_name"; then
        print_warning "Resource group $resource_group_name already exists"
        return 0
    fi
    
    # Build command with optional tags
    local cmd="az group create --name \"$resource_group_name\" --location \"$location\""
    if [[ -n "$tags" ]]; then
        cmd="$cmd --tags $tags"
    fi
    
    # Create resource group
    if eval "$cmd" > /dev/null; then
        print_success "Resource group created successfully"
        return 0
    else
        print_error "Failed to create resource group"
        return 1
    fi
}

# Function to delete Azure resource group
delete_azure_resource_group() {
    local resource_group_name="$1"
    local wait_for_completion="${2:-false}"
    
    print_status "Deleting resource group: $resource_group_name"
    
    # Check if resource group exists
    if ! azure_resource_exists "group" "$resource_group_name"; then
        print_warning "Resource group $resource_group_name not found"
        return 0
    fi
    
    # Delete resource group
    local cmd="az group delete --name \"$resource_group_name\" --yes"
    if [[ "$wait_for_completion" != "true" ]]; then
        cmd="$cmd --no-wait"
    fi
    
    if eval "$cmd"; then
        if [[ "$wait_for_completion" == "true" ]]; then
            print_success "Resource group deleted successfully"
        else
            print_success "Resource group deletion initiated (running in background)"
        fi
        return 0
    else
        print_error "Failed to delete resource group"
        return 1
    fi
}

# Function to check Azure AD permissions
check_azure_ad_permissions() {
    local current_user=$(az account show --query user.name -o tsv)
    
    print_status "Checking Azure AD permissions for: $current_user"
    
    # Check if user can read Azure AD (minimum requirement)
    if ! az ad user show --id "$current_user" &> /dev/null; then
        print_warning "Limited Azure AD permissions detected"
        print_status "You may need Global Administrator or Application Administrator role"
        return 1
    else
        print_success "✓ Azure AD access confirmed"
    fi
    
    # Check for admin consent capable roles
    print_status "Checking for admin consent permissions..."
    local user_roles=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/me/memberOf" --query "value[].displayName" -o tsv 2>/dev/null)
    
    if echo "$user_roles" | grep -q "Global Administrator\|Privileged Role Administrator\|Cloud Application Administrator\|Application Administrator"; then
        print_success "✓ Admin consent permissions detected"
        export ADMIN_CONSENT_CAPABLE=true
        return 0
    else
        print_warning "⚠ Limited admin consent permissions detected"
        print_status "  You may need to grant consent manually via Azure Portal"
        export ADMIN_CONSENT_CAPABLE=false
        return 1
    fi
}

# Function to get Microsoft Graph service principal ID
get_graph_service_principal_id() {
    local graph_sp_id=$(az ad sp list --display-name "Microsoft Graph" --query "[0].id" -o tsv)
    
    if [[ -z "$graph_sp_id" ]]; then
        print_error "Failed to find Microsoft Graph service principal"
        return 1
    fi
    
    echo "$graph_sp_id"
    return 0
}

# Function to verify admin consent for Graph permissions
verify_graph_admin_consent() {
    local client_id="$1"
    local permissions_array_name="$2[@]"  # Pass associative array by reference
    local permissions=("${!permissions_array_name}")
    
    print_status "Verifying admin consent status..."
    
    # Get service principal object ID
    local sp_object_id=$(az ad sp show --id "$client_id" --query "id" -o tsv)
    local graph_sp_id=$(get_graph_service_principal_id)
    
    if [[ -z "$sp_object_id" || -z "$graph_sp_id" ]]; then
        print_error "Failed to get required object IDs for verification"
        return 1
    fi
    
    # Check each permission
    local consent_verified=true
    for permission_name in "${permissions[@]}"; do
        local permission_id="${permission_name#*:}"  # Extract permission ID after colon
        permission_name="${permission_name%:*}"      # Extract permission name before colon
        
        # Check if the app role assignment exists
        if az rest --method GET \
            --url "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_object_id/appRoleAssignments" \
            --query "value[?appRoleId=='$permission_id' && resourceId=='$graph_sp_id']" | jq -e '. | length > 0' &>/dev/null; then
            print_success "  ✓ $permission_name consent verified"
        else
            print_warning "  ⚠ $permission_name consent not verified"
            consent_verified=false
        fi
    done
    
    if [[ "$consent_verified" == "true" ]]; then
        print_success "✓ All admin consents verified successfully"
        return 0
    else
        print_warning "⚠ Admin consent verification failed"
        return 1
    fi
}

# Function to cleanup Azure deployments
cleanup_azure_deployments() {
    local resource_group_name="$1"
    local deployment_pattern="$2"
    
    print_status "Cleaning up deployment history..."
    
    # Get deployments matching the pattern
    local deployments=$(az deployment group list \
        --resource-group "$resource_group_name" \
        --query "[?contains(name, '$deployment_pattern')].name" \
        --output tsv 2>/dev/null || echo "")
    
    if [[ -n "$deployments" ]]; then
        print_status "Found deployment history to clean up:"
        echo "$deployments" | while read -r deployment; do
            if [[ -n "$deployment" ]]; then
                print_status "  - $deployment"
                az deployment group delete \
                    --resource-group "$resource_group_name" \
                    --name "$deployment" \
                    --no-wait 2>/dev/null || true
            fi
        done
        print_success "Deployment history cleanup initiated"
    else
        print_status "No deployment history found to clean up"
    fi
}

# Export functions for use in other scripts
export -f validate_azure_auth get_azure_context azure_resource_exists
export -f verify_azure_role_assignment create_azure_resource_group delete_azure_resource_group
export -f check_azure_ad_permissions get_graph_service_principal_id verify_graph_admin_consent
export -f cleanup_azure_deployments
