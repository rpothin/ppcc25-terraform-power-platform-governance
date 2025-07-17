#!/bin/bash
# ==============================================================================
# Configuration Loader for Power Platform Terraform Governance Setup
# ==============================================================================
# This script loads configuration from config.env file and provides
# validation and helper functions for the setup scripts
# ==============================================================================

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

# Function to load configuration from config.env
load_config() {
    local config_file="$1"
    
    if [[ -z "$config_file" ]]; then
        config_file="$(dirname "${BASH_SOURCE[0]}")/config.env"
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

# Function to validate required configuration
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
        RANDOM_SUFFIX=$(openssl rand -hex 4)
        STORAGE_ACCOUNT_NAME="stterraformpp${RANDOM_SUFFIX}"
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
    
    print_success "Configuration validation passed"
    return 0
}

# Function to display configuration summary
display_config_summary() {
    print_status ""
    print_status "Configuration Summary:"
    print_status "====================="
    print_status "  GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status "  Service Principal: $SP_NAME"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status "  Location: $LOCATION"
    print_status "  Azure Subscription: ${AZURE_SUBSCRIPTION_ID:0:8}..."
    print_status "  Azure Tenant: ${AZURE_TENANT_ID:0:8}..."
    print_status ""
}

# Function to confirm configuration
confirm_config() {
    display_config_summary
    
    echo -n "Continue with this configuration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        print_status "You can modify the configuration in config.env and run the script again"
        return 1
    fi
    
    return 0
}

# Function to save runtime values to config (for sharing between scripts)
save_runtime_config() {
    local config_file="$(dirname "${BASH_SOURCE[0]}")/config.env"
    local temp_file=$(mktemp)
    
    # Create a backup
    cp "$config_file" "${config_file}.backup"
    
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

# Function to check if config.env exists and guide user
check_config_exists() {
    local config_file="$(dirname "${BASH_SOURCE[0]}")/config.env"
    
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
        
        echo -n "Would you like to create config.env now? (y/n): "
        read -r CREATE_CONFIG
        if [[ "$CREATE_CONFIG" == "y" || "$CREATE_CONFIG" == "Y" ]]; then
            cp "$(dirname "${BASH_SOURCE[0]}")/config.env.example" "$config_file"
            print_success "Created: $config_file"
            print_status "Please edit this file with your values and run the script again"
            print_status "  vim $config_file"
        fi
        
        return 1
    fi
    
    return 0
}

# Main function to initialize configuration
init_config() {
    local config_file="$1"
    
    # Check if config exists and guide user if not
    if ! check_config_exists; then
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
    
    # Export variables for use in other scripts
    export_config_vars
    
    return 0
}

# Allow this script to be sourced by other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    print_status "Configuration loader for Power Platform Terraform Governance"
    print_status "This script should be sourced by other setup scripts"
    print_status ""
    print_status "Usage:"
    print_status "  source config-loader.sh"
    print_status "  init_config"
    print_status ""
    print_status "Or run a setup script that uses this loader:"
    print_status "  ./setup.sh"
fi
