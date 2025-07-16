#!/bin/bash
# ========================    # Based on the terminal output, we know:
    # - Service Principal Name: terraform-powerplatform-governance  
    # - App ID: 64af8fc4-4467-49d2-a751-95cb8c281602 (current correct ID from latest run)
    
    SP_NAME="terraform-powerplatform-governance"
    APP_ID="64af8fc4-4467-49d2-a751-95cb8c281602"================================================
# Cleanup Service Principal and Associated Resources
# ==============================================================================
# This script removes the service principal and all associated resources
# created by the 01-create-service-principal.sh script
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

# Function to cleanup service principal
cleanup_service_principal() {
    print_status "Cleaning up service principal..."
    
    # Based on the terminal output, we know:
    # - Service Principal Name: terraform-powerplatform-governance  
    # - App ID: 55a94b50-7ecf-4d38-9bdd-75bcedd6a854 (current correct ID from latest run)
    
    SP_NAME="terraform-powerplatform-governance"
    APP_ID="2c650f10-cc0e-45ac-934f-f53ef7111e01"
    
    # Method 1: Delete by App ID (most reliable)
    print_status "Deleting service principal by App ID: $APP_ID"
    if az ad sp delete --id "$APP_ID" 2>/dev/null; then
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
    if az ad app delete --id "$APP_ID" 2>/dev/null; then
        print_success "✓ App registration deleted (includes federated credentials)"
    else
        print_warning "⚠ App registration not found"
    fi
}

# Function to cleanup Power Platform registration
cleanup_power_platform() {
    print_status "Cleaning up Power Platform registration..."
    
    APP_ID="64af8fc4-4467-49d2-a751-95cb8c281602"
    
    # Check if user is logged in to Power Platform
    if ! pac auth list &> /dev/null; then
        print_warning "Not logged in to Power Platform. Skipping Power Platform cleanup."
        print_status "The app registration will be automatically removed from Power Platform"
        print_status "when the Azure AD service principal is deleted."
        return
    fi
    
    # Try to unregister the application from Power Platform
    print_status "Attempting to unregister from Power Platform..."
    if pac admin application unregister --application-id "$APP_ID" 2>/dev/null; then
        print_success "✓ Application unregistered from Power Platform"
    else
        print_warning "⚠ Application not found in Power Platform or already removed"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    APP_ID="64af8fc4-4467-49d2-a751-95cb8c281602"
    SP_NAME="terraform-powerplatform-governance"
    
    # Check if service principal still exists
    if az ad sp show --id "$APP_ID" &> /dev/null; then
        print_error "✗ Service principal still exists!"
        return 1
    else
        print_success "✓ Service principal successfully removed"
    fi
    
    # Check if app registration still exists
    if az ad app show --id "$APP_ID" &> /dev/null; then
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

# Main execution
main() {
    print_status "Starting cleanup of service principal and associated resources..."
    print_status "=============================================================="
    
    # Confirm cleanup
    print_warning "This will delete:"
    print_warning "  - Service Principal: terraform-powerplatform-governance"
    print_warning "  - App Registration: 64af8fc4-4467-49d2-a751-95cb8c281602"
    print_warning "  - All associated permissions and federated credentials"
    print_warning "  - Power Platform registration"
    print_warning ""
    
    echo -n "Are you sure you want to proceed? (y/n): "
    read -r CONFIRM
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        exit 1
    fi
    
    cleanup_service_principal
    cleanup_power_platform
    verify_cleanup
    
    print_success "Cleanup completed successfully!"
    print_status ""
    print_status "You can now run the 01-create-service-principal.sh script again"
    print_status "to create a fresh service principal."
}

# Run the main function
main "$@"
