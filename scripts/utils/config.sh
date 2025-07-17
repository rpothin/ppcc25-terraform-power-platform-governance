#!/bin/bash
# ==============================================================================
# Configuration Management Utilities
# ==============================================================================
# Provides common configuration loading and management functions
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Function to display configuration summary
display_config_summary() {
    local show_sensitive="${1:-false}"
    
    print_status ""
    print_status "Configuration Summary:"
    print_status "====================="
    print_config_item "GitHub Repository" "$GITHUB_OWNER/$GITHUB_REPO"
    print_config_item "Service Principal" "$SP_NAME"
    print_config_item "Resource Group" "$RESOURCE_GROUP_NAME"
    print_config_item "Storage Account" "$STORAGE_ACCOUNT_NAME"
    print_config_item "Container" "$CONTAINER_NAME"
    print_config_item "Location" "$LOCATION"
    
    if [[ "$show_sensitive" == "true" ]]; then
        print_config_item "Azure Subscription" "$AZURE_SUBSCRIPTION_ID" "true"
        print_config_item "Azure Tenant" "$AZURE_TENANT_ID" "true"
        if [[ -n "$AZURE_CLIENT_ID" ]]; then
            print_config_item "Azure Client ID" "$AZURE_CLIENT_ID" "true"
        fi
    else
        print_config_item "Azure Subscription" "${AZURE_SUBSCRIPTION_ID:0:8}..."
        print_config_item "Azure Tenant" "${AZURE_TENANT_ID:0:8}..."
    fi
    print_status ""
}

# Function to confirm configuration with user
confirm_config() {
    display_config_summary
    
    print_confirmation_prompt "Continue with this configuration?"
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Operation cancelled by user"
        print_status "You can modify the configuration in config.env and run the script again"
        return 1
    fi
    
    return 0
}

# Function to validate required configuration values
validate_config() {
    local errors=0
    
    print_status "Validating configuration..."
    
    # Required fields
    if [[ -z "$GITHUB_OWNER" ]]; then
        print_error "GITHUB_OWNER is required"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        print_error "GITHUB_REPO is required"
        errors=$((errors + 1))
    fi
    
    # Set defaults for optional fields
    if [[ -z "$SP_NAME" ]]; then
        SP_NAME="terraform-powerplatform-governance"
        print_status "Using default service principal name: $SP_NAME"
    fi
    
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
        RESOURCE_GROUP_NAME="rg-terraform-powerplatform-governance"
        print_status "Using default resource group name: $RESOURCE_GROUP_NAME"
    fi
    
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
        print_status "Using default container name: $CONTAINER_NAME"
    fi
    
    if [[ -z "$LOCATION" ]]; then
        LOCATION="East US"
        print_status "Using default location: $LOCATION"
    fi
    
    # Generate storage account name if not provided
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        local random_suffix=$(openssl rand -hex 4)
        STORAGE_ACCOUNT_NAME="stterraformpp${random_suffix}"
        print_status "Generated storage account name: $STORAGE_ACCOUNT_NAME"
    fi
    
    # Validate storage account name format
    if [[ ! "$STORAGE_ACCOUNT_NAME" =~ ^[a-z0-9]{3,24}$ ]]; then
        print_error "STORAGE_ACCOUNT_NAME must be 3-24 characters, lowercase letters and numbers only"
        errors=$((errors + 1))
    fi
    
    # Get Azure context if not specified
    if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        if command -v az &> /dev/null && az account show &> /dev/null; then
            AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
            print_status "Using current Azure subscription: $AZURE_SUBSCRIPTION_ID"
        else
            print_error "AZURE_SUBSCRIPTION_ID is required (Azure CLI not available or not logged in)"
            errors=$((errors + 1))
        fi
    fi
    
    if [[ -z "$AZURE_TENANT_ID" ]]; then
        if command -v az &> /dev/null && az account show &> /dev/null; then
            AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
            print_status "Using current Azure tenant: $AZURE_TENANT_ID"
        else
            print_error "AZURE_TENANT_ID is required (Azure CLI not available or not logged in)"
            errors=$((errors + 1))
        fi
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_error "Configuration validation failed with $errors errors"
        print_error "Please fix the errors in config.env and try again"
        return 1
    fi
    
    # Export all variables for use by other scripts
    export_config_vars
    
    print_success "Configuration validation passed"
    return 0
}

# Function to export variables for use in other scripts
export_config_vars() {
    export GITHUB_OWNER
    export GITHUB_REPO
    export AZURE_SUBSCRIPTION_ID
    export AZURE_TENANT_ID
    export SP_NAME
    export RESOURCE_GROUP_NAME
    export STORAGE_ACCOUNT_NAME
    export CONTAINER_NAME
    export LOCATION
    export AZURE_CLIENT_ID  # Set by service principal creation script
}

# Function to save runtime values to config
save_runtime_config() {
    local config_file="${1:-$(dirname "${BASH_SOURCE[0]}")/../setup/config.env}"
    local temp_file=$(mktemp)
    
    # Create a backup of the current configuration (pre-setup state)
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.backup"
        print_status "Configuration backed up to: ${config_file}.backup"
    fi
    
    # Update the config file with runtime values
    {
        echo "# This file was last updated: $(date)"
        echo "# Generated values from setup process"
        echo ""
        echo "GITHUB_OWNER=\"$GITHUB_OWNER\""
        echo "GITHUB_REPO=\"$GITHUB_REPO\""
        echo "AZURE_SUBSCRIPTION_ID=\"$AZURE_SUBSCRIPTION_ID\""
        echo "AZURE_TENANT_ID=\"$AZURE_TENANT_ID\""
        echo "SP_NAME=\"$SP_NAME\""
        echo "RESOURCE_GROUP_NAME=\"$RESOURCE_GROUP_NAME\""
        echo "STORAGE_ACCOUNT_NAME=\"$STORAGE_ACCOUNT_NAME\""
        echo "CONTAINER_NAME=\"$CONTAINER_NAME\""
        echo "LOCATION=\"$LOCATION\""
        if [[ -n "$AZURE_CLIENT_ID" ]]; then
            echo "AZURE_CLIENT_ID=\"$AZURE_CLIENT_ID\""
        fi
    } > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$config_file"
    
    print_status "Configuration updated: $config_file"
}

# Function to load configuration from file
load_config() {
    local config_file="$1"
    
    if [[ -z "$config_file" ]]; then
        config_file="$(dirname "${BASH_SOURCE[0]}")/../setup/config.env"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        print_error ""
        print_error "Please create the configuration file:"
        print_error "  cd $(dirname "$config_file")"
        print_error "  cp config.env.example config.env"
        print_error "  # Edit config.env with your values"
        print_error "  vim config.env"
        print_error ""
        print_error "The config.env file is excluded from version control for security."
        return 1
    fi
    
    # Source the configuration file
    set -a  # Export all variables
    source "$config_file"
    set +a  # Stop exporting
    
    print_success "Configuration loaded from: $config_file"
    return 0
}

# Function to check if config.env exists and guide user
check_config_exists() {
    local config_file="${1:-$(dirname "${BASH_SOURCE[0]}")/../setup/config.env}"
    
    if [[ ! -f "$config_file" ]]; then
        print_warning "Configuration file not found: $config_file"
        print_status ""
        print_status "QUICK SETUP:"
        print_status "============"
        print_status "1. Copy the example configuration:"
        print_status "   cp config.env.example config.env"
        print_status ""
        print_status "2. Edit with your values:"
        print_status "   vim config.env"
        print_status ""
        print_status "3. Required values:"
        print_status "   - GITHUB_OWNER (your GitHub username/organization)"
        print_status "   - GITHUB_REPO (your repository name)"
        print_status ""
        print_status "4. Optional values will use sensible defaults"
        print_status ""
        print_status "The config.env file is excluded from version control for security."
        print_status ""
        
        print_confirmation_prompt "Would you like to create config.env now?"
        read -r CREATE_CONFIG
        if [[ "$CREATE_CONFIG" == "y" || "$CREATE_CONFIG" == "Y" ]]; then
            local example_file="$(dirname "$config_file")/config.env.example"
            if [[ -f "$example_file" ]]; then
                cp "$example_file" "$config_file"
                print_success "Created: $config_file"
                print_status "Please edit this file with your values and run the script again"
                print_status "  vim $config_file"
            else
                print_error "Example file not found: $example_file"
            fi
        fi
        
        return 1
    fi
    
    return 0
}

# Function to initialize configuration (main entry point)
init_config() {
    local config_file="$1"
    
    # Check if config exists and guide user if not
    if ! check_config_exists "$config_file"; then
        return 1
    fi
    
    # Load configuration
    if ! load_config "$config_file"; then
        return 1
    fi
    
    # Validate configuration
    if ! validate_config; then
        return 1
    fi
    
    return 0
}

# Export functions for use in other scripts
export -f display_config_summary confirm_config validate_config export_config_vars
export -f save_runtime_config load_config check_config_exists init_config
