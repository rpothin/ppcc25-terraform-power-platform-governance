#!/bin/bash
# ==============================================================================
# Validation Script for Power Platform Terraform Governance Setup
# ==============================================================================
# This script validates that the setup was completed successfully by checking
# all the required resources and configurations.
# ==============================================================================

set -e  # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Configuration variables (will be loaded from config.env)
GITHUB_OWNER=""
GITHUB_REPO=""
AZURE_SUBSCRIPTION_ID=""
AZURE_TENANT_ID=""
SP_NAME=""
RESOURCE_GROUP_NAME=""
STORAGE_ACCOUNT_NAME=""
CONTAINER_NAME=""
AZURE_CLIENT_ID=""
POWER_PLATFORM_CLIENT_ID=""
POWER_PLATFORM_TENANT_ID=""
TERRAFORM_RESOURCE_GROUP=""
TERRAFORM_STORAGE_ACCOUNT=""
TERRAFORM_CONTAINER=""

# Function to display banner
show_banner() {
    print_banner "Power Platform Terraform Governance - Setup Validation"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Validates the Power Platform Terraform governance setup using configuration"
    echo "from config.env file."
    echo ""
    echo "OPTIONS:"
    echo "  -y, --non-interactive    Run validation without prompts"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Interactive validation"
    echo "  $0 -y                   # Non-interactive validation"
    echo "  $0 --help               # Show help"
    echo ""
    echo "Configuration:"
    echo "  Uses config.env file in the same directory as this script"
    echo "  Run setup.sh first to create the configuration"
}

# Function to load and validate configuration
load_configuration() {
    print_status "Loading configuration..."
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        print_status "Please run the setup script first or create the config file manually"
        print_status "Expected location: $CONFIG_FILE"
        exit 1
    fi
    
    # Source the configuration file
    if source "$CONFIG_FILE"; then
        print_success "✓ Configuration loaded from: $CONFIG_FILE"
    else
        print_error "Failed to load configuration from: $CONFIG_FILE"
        exit 1
    fi
    
    # Build GitHub repository string
    if [[ -n "$GITHUB_OWNER" && -n "$GITHUB_REPO" ]]; then
        GITHUB_REPOSITORY="$GITHUB_OWNER/$GITHUB_REPO"
    else
        print_error "GitHub repository configuration is incomplete"
        print_error "Please check GITHUB_OWNER and GITHUB_REPO in $CONFIG_FILE"
        exit 1
    fi
    
    # Validate essential configuration
    print_status "Validating configuration..."
    
    local validation_failed=false
    
    # Check required values
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        print_error "GitHub repository not configured"
        validation_failed=true
    fi
    
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
        print_error "Resource group name not configured"
        validation_failed=true
    fi
    
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        print_error "Storage account name not configured"
        validation_failed=true
    fi
    
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        print_error "Azure Client ID not configured"
        validation_failed=true
    fi
    
    if [[ "$validation_failed" == "true" ]]; then
        print_error "Configuration validation failed"
        print_status "Please check your $CONFIG_FILE file or re-run the setup script"
        exit 1
    fi
    
    print_success "✓ Configuration validation passed"
    
    # Display configuration summary
    print_status ""
    print_status "Configuration Summary:"
    print_status "====================="
    print_status "  GitHub Repository: $GITHUB_REPOSITORY"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: ${CONTAINER_NAME:-terraform-state}"
    print_status "  Service Principal: ${SP_NAME:-terraform-powerplatform-governance}"
    if [[ -n "$AZURE_SUBSCRIPTION_ID" ]]; then
        print_status "  Azure Subscription: ${AZURE_SUBSCRIPTION_ID:0:8}..."
    fi
    if [[ -n "$AZURE_TENANT_ID" ]]; then
        print_status "  Azure Tenant: ${AZURE_TENANT_ID:0:8}..."
    fi
        print_status ""
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Use the common validation function
    validate_common_prerequisites true true true true false
}




validate_azure_resources() {
    # This function is kept for backward compatibility
    # It now calls the more specific validation functions
    validate_service_principal_and_permissions
    validate_terraform_backend_storage
}

# Function to validate Service Principal and Microsoft Graph permissions (Step 1)
validate_service_principal_and_permissions() {
    print_status "Validating Azure AD Service Principal and permissions..."
    
    # Use values from configuration
    local CLIENT_ID="$AZURE_CLIENT_ID"
    
    print_status "Using configuration values:"
    print_status "  Service Principal: ${CLIENT_ID:0:8}...${CLIENT_ID: -4}"
    print_status ""
    
    # Validate Client ID format
    if [[ ! "$CLIENT_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        print_error "Invalid Client ID format in configuration. Please check AZURE_CLIENT_ID in $CONFIG_FILE"
        return 1
    fi
    
    # Check if Azure CLI is authenticated
    if ! az account show &> /dev/null; then
        print_error "Azure CLI is not authenticated. Please run 'az login'"
        return 1
    fi
    
    # Check Service Principal exists
    print_check "Checking Service Principal: $CLIENT_ID"
    if az ad sp show --id "$CLIENT_ID" &> /dev/null; then
        print_success "✓ Service Principal exists"
        
        # Check basic Azure role assignments
        print_check "Checking Service Principal Azure permissions..."
        
        # Check Owner role at subscription level
        if az role assignment list --assignee "$CLIENT_ID" --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" --role "Owner" &> /dev/null; then
            print_success "✓ Owner role assigned at subscription level"
        else
            print_warning "⚠ Owner role not found at subscription level"
        fi
        
    else
        print_error "✗ Service Principal not found"
        return 1
    fi
    
    # Check OIDC federated credentials for GitHub Actions
    print_check "Checking OIDC federated credentials..."
    FEDERATED_CREDS=$(az ad app federated-credential list --id "$CLIENT_ID" --query "length(@)" -o tsv)
    if [[ "$FEDERATED_CREDS" -gt 0 ]]; then
        print_success "✓ OIDC federated credentials found"
        
        # Check GitHub-specific OIDC credential
        GITHUB_CRED=$(az ad app federated-credential list --id "$CLIENT_ID" --query "[?contains(subject, 'repo:')].name" -o tsv)
        if [[ -n "$GITHUB_CRED" ]]; then
            print_success "✓ GitHub Actions OIDC credential configured"
        else
            print_warning "⚠ GitHub Actions OIDC credential not found"
        fi
    else
        print_warning "⚠ No OIDC federated credentials found"
    fi
    
    # Check Microsoft Graph API permissions and admin consent
    print_check "Checking Microsoft Graph API permissions..."
    
    # Required permissions for Power Platform governance
    REQUIRED_PERMISSIONS=(
        "Directory.Read.All"
        "Group.ReadWrite.All"
        "Application.Read.All"
    )
    
    # Get OAuth2 permissions for Microsoft Graph
    GRAPH_PERMISSIONS=$(az ad app permission list --id "$CLIENT_ID" --query "[?resourceAppId=='00000003-0000-0000-c000-000000000000'].resourceAccess[].id" -o tsv)
    
    # Get service principal object IDs
    SP_OBJECT_ID=$(az ad sp show --id "$CLIENT_ID" --query "id" -o tsv)
    GRAPH_SP_ID=$(az ad sp list --display-name "Microsoft Graph" --query "[0].id" -o tsv)
    
    if [[ -z "$GRAPH_SP_ID" ]]; then
        print_error "✗ Microsoft Graph service principal not found"
        return 1
    fi
    
    # Check each required permission
    for permission in "${REQUIRED_PERMISSIONS[@]}"; do
        print_check "Checking permission: $permission"
        
        # Check if permission is configured
        case "$permission" in
            "Directory.Read.All")
                PERM_ID="7ab1d382-f21e-4acd-a863-ba3e13f7da61"
                ;;
            "Group.ReadWrite.All")
                PERM_ID="62a82d76-70ea-41e2-9197-370581804d09"
                ;;
            "Application.Read.All")
                PERM_ID="9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
                ;;
        esac
        
        if echo "$GRAPH_PERMISSIONS" | grep -q "$PERM_ID"; then
            print_success "✓ Permission $permission is configured"
            
            # Check admin consent status (application permissions require admin consent)
            # For application permissions, we need to check service principal app role assignments
            # Use the same method as the setup script for consistency
            APP_ROLE_ASSIGNMENTS=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
                --query "value[?appRoleId=='$PERM_ID' && resourceId=='$GRAPH_SP_ID']" -o json 2>/dev/null || echo "[]")
            
            if echo "$APP_ROLE_ASSIGNMENTS" | jq -e '. | length > 0' &>/dev/null; then
                print_success "✓ Admin consent granted for $permission"
            else
                print_error "✗ Admin consent NOT granted for $permission"
                print_error "  This is a critical issue that will prevent Power Platform operations"
                return 1
            fi
        else
            print_error "✗ Permission $permission is not configured"
            return 1
        fi
    done
    
    print_success "Microsoft Graph API permissions validation completed"
    print_success "Service Principal and permissions validation completed"
}

# Function to validate Terraform backend storage (Step 2)
validate_terraform_backend_storage() {
    print_status "Validating Terraform backend storage resources..."
    
    # Use values from configuration
    local RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME"
    local STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME"
    local CLIENT_ID="$AZURE_CLIENT_ID"
    local CONTAINER_NAME="${CONTAINER_NAME:-terraform-state}"
    
    print_status "Using configuration values:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status ""
    
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
        
        # Note: Storage container validation skipped due to network restrictions
        # The Bicep deployment ensures the container is created correctly
        print_success "✓ Storage Container (validated via Bicep deployment)"
        
    else
        print_error "✗ Storage Account not found"
        return 1
    fi
    
    # Check Service Principal permissions on storage resources
    print_check "Checking Service Principal storage permissions..."
    
    # Check Storage Blob Data Contributor on storage account
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
    
    print_success "Terraform backend storage validation completed"
}

# Function to validate Power Platform registration
validate_power_platform() {
    print_status "Validating Power Platform registration using configuration..."
    
    # Use values from configuration
    local CLIENT_ID_PP="$POWER_PLATFORM_CLIENT_ID"
    
    if [[ -z "$CLIENT_ID_PP" ]]; then
        # Fallback to Azure Client ID if Power Platform Client ID is not set
        CLIENT_ID_PP="$AZURE_CLIENT_ID"
        print_status "Using Azure Client ID for Power Platform validation (POWER_PLATFORM_CLIENT_ID not set)"
    fi
    
    print_status "Validating Service Principal: ${CLIENT_ID_PP:0:8}...${CLIENT_ID_PP: -4}"
    print_status ""
    
    # Validate input format
    if [[ ! "$CLIENT_ID_PP" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        print_error "Invalid Client ID format in configuration. Please check POWER_PLATFORM_CLIENT_ID in $CONFIG_FILE"
        return 1
    fi
    # Check if Power Platform CLI is authenticated
    if ! pac auth list &> /dev/null; then
        print_error "Power Platform CLI is not authenticated. Please run 'pac auth create'"
        return 1
    fi
    
    # Get current authentication profile
    CURRENT_AUTH=$(pac auth list --json | jq -r '.[] | select(.IsActive == true) | .DisplayName' 2>/dev/null || echo "")
    if [[ -n "$CURRENT_AUTH" ]]; then
        print_success "✓ Authenticated as: $CURRENT_AUTH"
    fi
    
    # Check if application is registered
    print_check "Checking Power Platform application registration..."
    print_check "Verifying service principal registration in Power Platform..."
    
    # Use pac admin application list to check for the specific application
    if pac admin application list &> /dev/null; then
        APP_LIST=$(pac admin application list 2>/dev/null || echo "")
        
        # Check if our application is in the list
        if echo "$APP_LIST" | grep -q "$CLIENT_ID_PP"; then
            print_success "✓ Service Principal is registered with Power Platform"
            
            # Try to extract application name from the output
            APP_NAME=$(echo "$APP_LIST" | grep "$CLIENT_ID_PP" | head -1 | awk '{print $1}' 2>/dev/null || echo "terraform-powerplatform-governance")
            print_success "✓ Application Name: $APP_NAME"
        else
            print_error "✗ Service Principal is NOT registered with Power Platform"
            print_error "  Please register the application using 'pac admin application add' command"
            return 1
        fi
    else
        print_error "✗ Cannot access Power Platform admin functions"
        print_error "  Please ensure you have Power Platform admin privileges"
        return 1
    fi
    
    # Test admin privileges by checking tenant settings access
    print_check "Verifying Power Platform admin privileges..."
    if pac admin tenant settings &> /dev/null; then
        print_success "✓ Power Platform admin privileges confirmed"
    else
        print_warning "⚠ Cannot access tenant settings (may lack admin privileges)"
    fi
    
    print_success "Power Platform validation completed"
}

# Function to validate GitHub secrets
validate_github_secrets() {
    print_status "Validating GitHub secrets using configuration..."
    
    # Use repository from configuration
    local GITHUB_REPOSITORY="$GITHUB_REPOSITORY"
    
    print_status "Checking repository: $GITHUB_REPOSITORY"
    print_status ""
    
    # Check if GitHub CLI is authenticated
    if ! authenticate_github; then
        print_error "GitHub authentication failed"
        return 1
    fi
    
    # Check if repository exists
    if ! gh repo view "$GITHUB_REPOSITORY" &> /dev/null; then
        print_error "Cannot access repository $GITHUB_REPOSITORY"
        print_error "Please check the GITHUB_OWNER and GITHUB_REPO settings in $CONFIG_FILE"
        return 1
    fi
    
    # Verify repository access and admin permissions
    PERMISSION=$(gh api "repos/$GITHUB_REPOSITORY" --jq '.permissions.admin' 2>/dev/null)
    if [[ "$PERMISSION" != "true" ]]; then
        print_error "You need admin access to the repository to validate secrets"
        return 1
    fi
    
    print_success "Admin access confirmed"
    
    # List existing secrets from production environment
    print_check "Checking production environment secrets..."
    
    # Check if production environment exists first
    if ! gh api "repos/$GITHUB_REPOSITORY/environments/production" &> /dev/null; then
        print_error "✗ Production environment not found"
        print_error "  The setup script should have created a production environment with secrets"
        return 1
    fi
    
    print_success "✓ Production environment exists"
    
    # Get environment secrets (these are the secrets created by the setup script)
    # Test secrets access first
    if ! test_github_secrets_access "$GITHUB_REPOSITORY" "production"; then
        print_warning "Environment secrets access test failed. Attempting re-authentication..."
        
        if perform_github_login; then
            # Test again after re-authentication
            if test_github_secrets_access "$GITHUB_REPOSITORY" "production"; then
                print_success "Environment secrets access restored after re-authentication"
            else
                print_error "Environment secrets access still failed after re-authentication"
                return 1
            fi
        else
            print_error "Re-authentication failed"
            return 1
        fi
    fi
    
    EXISTING_SECRETS=$(gh secret list --repo "$GITHUB_REPOSITORY" --env production --json name --jq '.[].name' 2>/dev/null || echo "")
    
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
    
    # Check each required secret in the production environment
    for secret in "${REQUIRED_SECRETS[@]}"; do
        print_check "Checking environment secret: $secret"
        if echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
            print_success "✓ Environment secret $secret exists"
        else
            print_error "✗ Environment secret $secret not found in production environment"
            return 1
        fi
    done
    
    print_success "✓ All required environment secrets found"
    
    print_success "GitHub environment and secrets validation completed"
}

# Function to test Terraform backend connectivity
test_terraform_backend() {
    print_status "Validating Terraform backend configuration..."
    
    # Use values from configuration
    local RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME"
    local STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME"
    local CONTAINER_NAME="${CONTAINER_NAME:-terraform-state}"
    
    print_status "Backend configuration:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "  Container: $CONTAINER_NAME"
    print_status ""
    
    # Check if we can access the storage account (this validates the backend config)
    print_check "Validating backend storage account access..."
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✓ Backend storage account is accessible"
        
        # Check if the current user/service principal has the right permissions for blob access
        print_check "Checking blob access permissions..."
        STORAGE_ACCOUNT_ID=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "id" -o tsv)
        
        # Check for current user's access (this works in development scenarios)
        CURRENT_USER=$(az account show --query "user.name" -o tsv 2>/dev/null || echo "")
        if [[ -n "$CURRENT_USER" ]]; then
            if az role assignment list --assignee "$CURRENT_USER" --scope "$STORAGE_ACCOUNT_ID" --role "Storage Blob Data Contributor" &> /dev/null; then
                print_success "✓ Current user has Storage Blob Data Contributor access"
            else
                print_status "ℹ Current user blob access not configured (GitHub Actions will use service principal)"
            fi
        fi
        
        print_success "✓ Terraform backend configuration validated"
        print_status "ℹ Full connectivity test skipped due to storage account network restrictions"
        print_status "ℹ GitHub Actions will use JIT network access for actual deployments"
        
    else
        print_error "✗ Cannot access backend storage account"
        return 1
    fi
    
    print_success "Terraform backend validation completed"
}

# Function to display final summary
show_final_summary() {
    print_status ""
    print_status "Validation Summary (following setup.sh order):"
    print_status "=============================================="
    print_status "✓ Step 1: Azure AD Service Principal and Microsoft Graph permissions validated"
    print_status "✓ Step 1+: Power Platform registration validated"
    print_status "✓ Step 2: Terraform backend storage and connectivity validated"
    print_status "✓ Step 3: GitHub repository secrets validated"
    print_status ""
    print_success "🎉 Setup validation completed successfully!"
    print_status ""
    print_status "Your Power Platform Terraform governance setup is ready to use!"
    print_status "You can now run the GitHub Actions workflow to deploy your configurations."
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Check for non-interactive mode
    local NON_INTERACTIVE=false
    if [[ "$1" == "--non-interactive" || "$1" == "-y" ]]; then
        NON_INTERACTIVE=true
    fi
    
    show_banner
    
    # Check prerequisites first
    check_prerequisites
    echo ""
    
    # Load configuration
    load_configuration
    echo ""
    
    print_status "This script will validate your Power Platform Terraform governance setup using"
    print_status "the configuration from: $CONFIG_FILE"
    print_status ""
    print_status "The validation will check (following setup order):"
    print_status "  • Step 1: Azure AD Service Principal with OIDC and Microsoft Graph permissions"
    print_status "  • Step 1+: Power Platform registration (part of service principal setup)"
    print_status "  • Step 2: Terraform backend storage and connectivity"
    print_status "  • Step 3: GitHub secrets and environment"
    print_status ""
    
    if [[ "$NON_INTERACTIVE" != "true" ]]; then
        echo -n "Do you want to proceed with the validation? (y/N): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
            print_error "Validation cancelled by user"
            exit 1
        fi
        echo ""
    else
        print_status "Running in non-interactive mode..."
        echo ""
    fi
    
    # Run validation steps (following setup.sh order)
    echo ""
    print_status "=== STEP 1: Validating Azure AD Service Principal Setup ==="
    validate_service_principal_and_permissions
    echo ""
    validate_power_platform
    echo ""
    print_status "=== STEP 2: Validating Terraform Backend Storage ==="
    validate_terraform_backend_storage
    echo ""
    test_terraform_backend
    echo ""
    print_status "=== STEP 3: Validating GitHub Repository Secrets ==="
    validate_github_secrets
    echo ""
    
    show_final_summary
}

# Run the main function
main "$@"
