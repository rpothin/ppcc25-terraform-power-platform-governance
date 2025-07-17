#!/bin/bash
# ==============================================================================
# Cleanup Service Principal and Associated Resources
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined cleanup
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration loader from setup directory
source "$SCRIPT_DIR/../setup/config-loader.sh"

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

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Power Platform CLI is installed
    if ! command -v pac &> /dev/null; then
        print_warning "Power Platform CLI is not installed. Power Platform cleanup will be skipped."
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to cleanup service principal
cleanup_service_principal() {
    print_status "Cleaning up service principal..."
    
    # Validate that required variables are set
    if [[ -z "$SP_NAME" ]]; then
        print_error "Service Principal Name is not set in configuration"
        exit 1
    fi
    
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "Azure Client ID is not set in configuration"
        print_error "This may mean the service principal was not created with the config-driven scripts"
        exit 1
    fi
    
    # Method 1: Delete by App ID (most reliable)
    print_status "Deleting service principal by App ID: $AZURE_CLIENT_ID"
    if az ad sp delete --id "$AZURE_CLIENT_ID" 2>/dev/null; then
        print_success "✓ Service principal deleted by App ID"
    else
        print_warning "⚠ Service principal not found by App ID, trying by name..."
        
        # Method 2: Delete by display name (fallback)
        if az ad sp delete --display-name "$SP_NAME" 2>/dev/null; then
            print_success "✓ Service principal deleted by name"
        else
            print_warning "⚠ Service principal not found by name either"
        fi
    fi
    
    # Also delete the app registration (this removes federated credentials too)
    print_status "Deleting app registration..."
    if az ad app delete --id "$AZURE_CLIENT_ID" 2>/dev/null; then
        print_success "✓ App registration deleted (includes federated credentials)"
    else
        print_warning "⚠ App registration not found"
    fi
}

# Function to cleanup Power Platform registration
cleanup_power_platform() {
    print_status "Cleaning up Power Platform registration..."
    
    # Check if user is logged in to Power Platform
    if ! pac auth list &> /dev/null; then
        print_warning "Not logged in to Power Platform. Skipping Power Platform cleanup."
        print_status "The app registration will be automatically removed from Power Platform"
        print_status "when the Azure AD service principal is deleted."
        return
    fi
    
    # Try to unregister the application from Power Platform
    print_status "Attempting to unregister from Power Platform..."
    if pac admin application unregister --application-id "$AZURE_CLIENT_ID" 2>/dev/null; then
        print_success "✓ Application unregistered from Power Platform"
    else
        print_warning "⚠ Application not found in Power Platform or already removed"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if service principal still exists
    if az ad sp show --id "$AZURE_CLIENT_ID" &> /dev/null; then
        print_error "✗ Service principal still exists!"
        return 1
    else
        print_success "✓ Service principal successfully removed"
    fi
    
    # Check if app registration still exists
    if az ad app show --id "$AZURE_CLIENT_ID" &> /dev/null; then
        print_error "✗ App registration still exists!"
        return 1
    else
        print_success "✓ App registration successfully removed"
    fi
    
    # List any remaining apps with the same name (just in case)
    print_status "Checking for any remaining apps with same name..."
    REMAINING_APPS=$(az ad app list --display-name "$SP_NAME" --query "[].{Name:displayName, AppId:appId}" -o table 2>/dev/null)
    
    if [[ -n "$REMAINING_APPS" && "$REMAINING_APPS" != "Name    AppId" ]]; then
        print_warning "Found remaining apps with same name:"
        echo "$REMAINING_APPS"
    else
        print_success "✓ No remaining apps with same name"
    fi
}

# Function to update configuration file
update_config() {
    print_status "Updating configuration file..."
    
    local config_file="$SCRIPT_DIR/../setup/config.env"
    
    if [[ -f "$config_file" ]]; then
        # Remove the AZURE_CLIENT_ID line from config file
        if grep -q "AZURE_CLIENT_ID" "$config_file"; then
            # Create a backup
            cp "$config_file" "${config_file}.backup"
            
            # Remove the AZURE_CLIENT_ID line
            sed -i '/^AZURE_CLIENT_ID=/d' "$config_file"
            
            print_success "✓ Removed AZURE_CLIENT_ID from configuration file"
            print_status "Configuration backup saved as: ${config_file}.backup"
        else
            print_status "AZURE_CLIENT_ID not found in configuration file"
        fi
    else
        print_warning "Configuration file not found: $config_file"
    fi
}

# Function to clean up variables from environment
cleanup_vars() {
    print_status "Cleaning up variables from memory..."
    
    # Clear variables
    unset SP_NAME
    unset AZURE_CLIENT_ID
    unset AZURE_TENANT_ID
    unset AZURE_SUBSCRIPTION_ID
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
    print_status "Starting cleanup of service principal and associated resources..."
    print_status "=============================================================="
    
    # Set up trap to clean up on exit
    trap cleanup_vars EXIT
    
    # Initialize configuration
    if ! init_config "$SCRIPT_DIR/../setup/config.env"; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    # Display configuration summary
    print_status "Configuration Summary:"
    print_status "  Service Principal: $SP_NAME"
    print_status "  GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    if [[ -n "$AZURE_CLIENT_ID" ]]; then
        print_status "  Azure Client ID: $AZURE_CLIENT_ID"
    else
        print_warning "  Azure Client ID: Not found in configuration"
        print_warning "  This may mean the service principal was not created with config-driven scripts"
    fi
    
    # Validate prerequisites
    validate_prerequisites
    
    # Confirm cleanup
    print_warning "This will delete:"
    print_warning "  - Service Principal: $SP_NAME"
    if [[ -n "$AZURE_CLIENT_ID" ]]; then
        print_warning "  - App Registration: $AZURE_CLIENT_ID"
    fi
    print_warning "  - All associated permissions and federated credentials"
    print_warning "  - Power Platform registration"
    print_warning ""
    
    echo -n "Are you sure you want to proceed? (y/n): "
    read -r CONFIRM
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        exit 1
    fi
    
    echo -n "Type 'DELETE' to confirm service principal removal: "
    read -r DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" != "DELETE" ]]; then
        print_error "Cleanup cancelled - confirmation not received"
        exit 1
    fi
    
    # Perform cleanup
    cleanup_service_principal
    cleanup_power_platform
    verify_cleanup
    update_config
    
    # Clean up variables
    cleanup_vars
    
    print_success "Cleanup completed successfully!"
    print_status ""
    print_status "You can now run the setup.sh script again to create a fresh service principal."
    
    # Disable trap since we're cleaning up manually
    trap - EXIT
}

# Run the main function
main "$@"
