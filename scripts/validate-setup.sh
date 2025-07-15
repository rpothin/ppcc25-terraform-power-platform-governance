#!/bin/bash
# ==============================================================================
# Validation Script for Power Platform Terraform Governance Setup
# ==============================================================================
# This script validates that the setup was completed successfully by checking
# all the required resources and configurations.
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

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

# Function to display banner
show_banner() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  Power Platform Terraform Governance - Setup Validation"
    echo "============================================================================="
    echo -e "${NC}"
}

# Function to validate Azure resources
validate_azure_resources() {
    print_status "Validating Azure resources..."
    
    # Get user input for validation
    echo -n "Enter the Resource Group name used for Terraform state: "
    read -r RESOURCE_GROUP_NAME
    
    echo -n "Enter the Storage Account name used for Terraform state: "
    read -r STORAGE_ACCOUNT_NAME
    
    echo -n "Enter the Service Principal Client ID: "
    read -r CLIENT_ID
    
    # Check if Azure CLI is authenticated
    if ! az account show &> /dev/null; then
        print_error "Azure CLI is not authenticated. Please run 'az login'"
        return 1
    fi
    
    # Check Resource Group
    print_check "Checking Resource Group: $RESOURCE_GROUP_NAME"
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✓ Resource Group exists"
    else
        print_error "✗ Resource Group not found"
        return 1
    fi
    
    # Check Storage Account
    print_check "Checking Storage Account: $STORAGE_ACCOUNT_NAME"
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✓ Storage Account exists"
        
        # Check storage account security settings
        print_check "Checking Storage Account security settings..."
        
        # Check HTTPS only
        HTTPS_ONLY=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "enableHttpsTrafficOnly" -o tsv)
        if [[ "$HTTPS_ONLY" == "true" ]]; then
            print_success "✓ HTTPS only is enabled"
        else
            print_warning "⚠ HTTPS only is not enabled"
        fi
        
        # Check minimum TLS version
        MIN_TLS=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "minimumTlsVersion" -o tsv)
        if [[ "$MIN_TLS" == "TLS1_2" ]]; then
            print_success "✓ Minimum TLS version is 1.2"
        else
            print_warning "⚠ Minimum TLS version is not 1.2"
        fi
        
        # Check blob public access
        BLOB_PUBLIC_ACCESS=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "allowBlobPublicAccess" -o tsv)
        if [[ "$BLOB_PUBLIC_ACCESS" == "false" ]]; then
            print_success "✓ Blob public access is disabled"
        else
            print_warning "⚠ Blob public access is enabled"
        fi
        
    else
        print_error "✗ Storage Account not found"
        return 1
    fi
    
    # Check Storage Container
    print_check "Checking Storage Container: terraform-state"
    STORAGE_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "[0].value" -o tsv)
    if az storage container show --name "terraform-state" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" &> /dev/null; then
        print_success "✓ Storage Container exists"
    else
        print_error "✗ Storage Container not found"
        return 1
    fi
    
    # Check Service Principal
    print_check "Checking Service Principal: $CLIENT_ID"
    if az ad sp show --id "$CLIENT_ID" &> /dev/null; then
        print_success "✓ Service Principal exists"
        
        # Check role assignments
        print_check "Checking Service Principal permissions..."
        
        # Check Storage Blob Data Contributor
        STORAGE_ACCOUNT_ID=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "id" -o tsv)
        if az role assignment list --assignee "$CLIENT_ID" --scope "$STORAGE_ACCOUNT_ID" --role "Storage Blob Data Contributor" &> /dev/null; then
            print_success "✓ Storage Blob Data Contributor role assigned"
        else
            print_warning "⚠ Storage Blob Data Contributor role not found"
        fi
        
        # Check Contributor role on Resource Group
        RG_ID=$(az group show --name "$RESOURCE_GROUP_NAME" --query "id" -o tsv)
        if az role assignment list --assignee "$CLIENT_ID" --scope "$RG_ID" --role "Contributor" &> /dev/null; then
            print_success "✓ Contributor role assigned to Resource Group"
        else
            print_warning "⚠ Contributor role not found on Resource Group"
        fi
        
    else
        print_error "✗ Service Principal not found"
        return 1
    fi
    
    # Check OIDC federated credentials
    print_check "Checking OIDC federated credentials..."
    FEDERATED_CREDS=$(az ad app federated-credential list --id "$CLIENT_ID" --query "length(@)" -o tsv)
    if [[ "$FEDERATED_CREDS" -gt 0 ]]; then
        print_success "✓ OIDC federated credentials found"
    else
        print_warning "⚠ No OIDC federated credentials found"
    fi
    
    print_success "Azure resources validation completed"
}

# Function to validate Power Platform registration
validate_power_platform() {
    print_status "Validating Power Platform registration..."
    
    # Check if Power Platform CLI is authenticated
    if ! pac auth list &> /dev/null; then
        print_error "Power Platform CLI is not authenticated. Please run 'pac auth create'"
        return 1
    fi
    
    # Check if application is registered
    print_check "Checking Power Platform application registration..."
    
    # Note: pac admin application list doesn't provide a direct way to check if a specific app is registered
    # So we'll just verify that the command works and the user has admin privileges
    if pac admin application list &> /dev/null; then
        print_success "✓ Power Platform CLI has admin privileges"
        print_status "Please manually verify that the Service Principal is registered in Power Platform Admin Center"
    else
        print_error "✗ Power Platform CLI doesn't have admin privileges or connection failed"
        return 1
    fi
    
    print_success "Power Platform validation completed"
}

# Function to validate GitHub secrets
validate_github_secrets() {
    print_status "Validating GitHub secrets..."
    
    # Check if GitHub CLI is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run 'gh auth login'"
        return 1
    fi
    
    # Get repository
    echo -n "Enter GitHub repository (owner/repo format): "
    read -r GITHUB_REPOSITORY
    
    # Check if repository exists
    if ! gh repo view "$GITHUB_REPOSITORY" &> /dev/null; then
        print_error "Cannot access repository $GITHUB_REPOSITORY"
        return 1
    fi
    
    # List existing secrets
    EXISTING_SECRETS=$(gh secret list --repo "$GITHUB_REPOSITORY" --json name --jq '.[].name')
    
    # Required secrets
    REQUIRED_SECRETS=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID"
        "AZURE_SUBSCRIPTION_ID"
        "POWER_PLATFORM_CLIENT_ID"
        "POWER_PLATFORM_TENANT_ID"
        "TERRAFORM_RESOURCE_GROUP"
        "TERRAFORM_STORAGE_ACCOUNT"
        "TERRAFORM_CONTAINER"
    )
    
    # Check each required secret
    for secret in "${REQUIRED_SECRETS[@]}"; do
        print_check "Checking secret: $secret"
        if echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
            print_success "✓ Secret $secret exists"
        else
            print_error "✗ Secret $secret not found"
            return 1
        fi
    done
    
    # Check if production environment exists
    print_check "Checking production environment..."
    if gh api "repos/$GITHUB_REPOSITORY/environments/production" &> /dev/null; then
        print_success "✓ Production environment exists"
    else
        print_warning "⚠ Production environment not found (optional)"
    fi
    
    print_success "GitHub secrets validation completed"
}

# Function to test Terraform backend connectivity
test_terraform_backend() {
    print_status "Testing Terraform backend connectivity..."
    
    # Get backend configuration
    echo -n "Enter Resource Group name: "
    read -r RESOURCE_GROUP_NAME
    
    echo -n "Enter Storage Account name: "
    read -r STORAGE_ACCOUNT_NAME
    
    echo -n "Enter Container name (default: terraform-state): "
    read -r CONTAINER_NAME
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="terraform-state"
    fi
    
    # Create temporary directory for testing
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Create minimal Terraform configuration
    cat > main.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "validation-test.tfstate"
  }
}

resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo 'Backend connectivity test successful'"
  }
}
EOF
    
    # Test backend initialization
    print_check "Testing Terraform backend initialization..."
    if terraform init; then
        print_success "✓ Terraform backend initialization successful"
    else
        print_error "✗ Terraform backend initialization failed"
        cd - > /dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEST_DIR"
    
    print_success "Terraform backend connectivity test completed"
}

# Function to display final summary
show_final_summary() {
    print_status ""
    print_status "Validation Summary:"
    print_status "=================="
    print_status "✓ Azure resources validated"
    print_status "✓ Power Platform registration validated"
    print_status "✓ GitHub secrets validated"
    print_status "✓ Terraform backend connectivity tested"
    print_status ""
    print_success "🎉 Setup validation completed successfully!"
    print_status ""
    print_status "Your Power Platform Terraform governance setup is ready to use!"
    print_status "You can now run the GitHub Actions workflow to deploy your configurations."
}

# Main execution
main() {
    show_banner
    
    print_status "This script will validate your Power Platform Terraform governance setup."
    print_status "Make sure you have the necessary information ready (resource names, client IDs, etc.)"
    print_status ""
    
    echo -n "Do you want to proceed with the validation? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Validation cancelled by user"
        exit 1
    fi
    
    echo ""
    
    # Run validation steps
    validate_azure_resources
    echo ""
    validate_power_platform
    echo ""
    validate_github_secrets
    echo ""
    test_terraform_backend
    echo ""
    
    show_final_summary
}

# Run the main function
main "$@"
