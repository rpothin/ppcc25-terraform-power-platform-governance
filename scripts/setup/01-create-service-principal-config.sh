#!/bin/bash
# ==============================================================================
# Create Service Principal with OIDC for GitHub and Power Platform Access
# ==============================================================================
# Configuration-driven version that uses config.env for streamlined setup
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the configuration loader
source "$SCRIPT_DIR/config-loader.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
ADMIN_CONSENT_CAPABLE=false
ADMIN_CONSENT_GRANTED=false
AZURE_CLIENT_ID=""
GRAPH_SP_ID=""

# Required Graph API permissions for Power Platform governance
declare -A GRAPH_PERMISSIONS=(
    ["Group.ReadWrite.All"]="62a82d76-70ea-41e2-9197-370581804d09"
    ["Directory.Read.All"]="7ab1d382-f21e-4acd-a863-ba3e13f7da61"
    ["Application.Read.All"]="9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
)

# Function to cleanup existing permissions and role assignments
cleanup_existing_permissions() {
    print_status "Cleaning up existing Microsoft Graph permissions and assignments..."
    
    # Get service principal object ID
    local SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv 2>/dev/null)
    
    if [[ -n "$SP_OBJECT_ID" ]]; then
        # Remove existing app role assignments
        print_status "Removing existing app role assignments..."
        local existing_assignments=$(az rest --method GET \
            --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
            --query "value[?resourceId=='$GRAPH_SP_ID'].id" -o tsv 2>/dev/null)
        
        if [[ -n "$existing_assignments" ]]; then
            while IFS= read -r assignment_id; do
                if [[ -n "$assignment_id" ]]; then
                    print_status "  Removing assignment: $assignment_id"
                    az rest --method DELETE \
                        --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments/$assignment_id" 2>/dev/null || true
                fi
            done <<< "$existing_assignments"
            
            print_status "Waiting for assignment deletions to propagate..."
            sleep 5
        fi
    fi
    
    # Remove API permissions from the application
    print_status "Removing existing API permissions..."
    az ad app permission delete --id "$AZURE_CLIENT_ID" --api 00000003-0000-0000-c000-000000000000 2>/dev/null || true
    
    print_success "✓ Cleanup completed"
}

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
    
    # Check if jq is installed (needed for JSON parsing)
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Power Platform CLI is installed
    if ! command -v pac &> /dev/null; then
        print_error "Power Platform CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if user has sufficient Azure AD permissions
    print_status "Validating Azure AD permissions..."
    CURRENT_USER=$(az account show --query user.name -o tsv)
    
    # Check if user can read Azure AD (minimum requirement)
    if ! az ad user show --id "$CURRENT_USER" &> /dev/null; then
        print_warning "Limited Azure AD permissions detected"
        print_status "You may need Global Administrator or Application Administrator role"
        print_status "to grant Microsoft Graph API permissions and admin consent."
    else
        print_success "✓ Azure AD access confirmed"
    fi
    
    # Check for admin consent capable roles
    print_status "Checking for admin consent permissions..."
    USER_ROLES=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/me/memberOf" --query "value[].displayName" -o tsv 2>/dev/null)
    
    ADMIN_CONSENT_CAPABLE=false
    if echo "$USER_ROLES" | grep -q "Global Administrator\|Privileged Role Administrator\|Cloud Application Administrator\|Application Administrator"; then
        ADMIN_CONSENT_CAPABLE=true
        print_success "✓ Admin consent permissions detected"
    else
        print_warning "⚠ Limited admin consent permissions detected"
        print_status "  You may need to grant consent manually via Azure Portal"
        print_status "  Required roles: Global Administrator, Privileged Role Administrator,"
        print_status "                  Cloud Application Administrator, or Application Administrator"
    fi
    
    # Check if user is logged in to Power Platform
    if ! pac auth list &> /dev/null; then
        print_warning "You are not logged in to Power Platform. Please run 'pac auth create' first."
        print_status "You need to authenticate with Power Platform tenant admin privileges."
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to create service principal
create_service_principal() {
    print_status "Creating service principal: $SP_NAME"
    
    # Create the service principal with Owner role for comprehensive access
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role "Owner" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID")
    
    if [[ $? -eq 0 ]]; then
        print_success "Service principal created successfully with Owner role"
        
        # Extract values from the output (modern format)
        CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
        TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenant')
        SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
        
        # Validate extracted values
        if [[ -z "$CLIENT_ID" || "$CLIENT_ID" == "null" ]]; then
            print_error "Failed to extract Client ID from service principal output"
            exit 1
        fi
        
        if [[ -z "$TENANT_ID" || "$TENANT_ID" == "null" ]]; then
            print_error "Failed to extract Tenant ID from service principal output"
            exit 1
        fi
        
        # Store in global variables for later use
        AZURE_CLIENT_ID="$CLIENT_ID"
        
        # Validate service principal was created properly
        print_status "Validating service principal creation..."
        if az ad sp show --id "$CLIENT_ID" --query "appId" -o tsv &> /dev/null; then
            print_success "✓ Service principal validation confirmed"
        else
            print_error "Service principal validation failed"
            exit 1
        fi
        
        print_status "Service Principal created with the following details:"
        print_status "  Display Name: $SP_NAME"
        print_status "  Role: Owner (subscription-level)"
        print_status "  Application ID: $CLIENT_ID"
        print_status "  Tenant ID: $TENANT_ID"
        print_status "  Subscription ID: $SUBSCRIPTION_ID"
    else
        print_error "Failed to create service principal"
        exit 1
    fi
}

# Function to setup OIDC trust with GitHub
setup_github_oidc() {
    print_status "Setting up OIDC trust with GitHub repository..."
    
    # Create federated credential for GitHub Actions
    FEDERATED_CREDENTIAL_NAME="github-actions-main"
    
    # Create a secure temporary file with proper permissions
    TEMP_CREDENTIAL_FILE=$(mktemp)
    chmod 600 "$TEMP_CREDENTIAL_FILE"
    
    # Create the federated credential JSON
    cat > "$TEMP_CREDENTIAL_FILE" << EOF
{
    "name": "$FEDERATED_CREDENTIAL_NAME",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:$GITHUB_OWNER/$GITHUB_REPO:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF
    
    # Create the federated credential
    az ad app federated-credential create \
        --id "$AZURE_CLIENT_ID" \
        --parameters "@$TEMP_CREDENTIAL_FILE"
    
    if [[ $? -eq 0 ]]; then
        print_success "OIDC trust configured for GitHub repository"
        # Securely remove the temporary file
        rm -f "$TEMP_CREDENTIAL_FILE"
    else
        print_error "Failed to configure OIDC trust"
        # Securely remove the temporary file
        rm -f "$TEMP_CREDENTIAL_FILE"
        exit 1
    fi
}

# Function to assign additional Azure permissions
assign_azure_permissions() {
    print_status "Validating Azure permissions..."
    
    # The Owner role already includes all necessary permissions
    print_status "Verifying Owner role assignment..."
    
    # Verify the Owner role is properly assigned
    if az role assignment list \
        --assignee "$AZURE_CLIENT_ID" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
        --role "Owner" \
        --query "[0].roleDefinitionName" -o tsv | grep -q "Owner"; then
        print_success "✓ Owner role confirmed at subscription level"
        print_status "  This includes all required permissions for:"
        print_status "    - Resource management (Contributor)"
        print_status "    - Access control management (User Access Administrator)"
        print_status "    - Storage operations (Storage Blob Data Contributor)"
        print_status "    - Terraform state management"
        print_status "    - Identity and access management"
    else
        print_error "Owner role assignment verification failed"
        exit 1
    fi
}

# Function to assign Microsoft Graph API permissions
assign_graph_permissions() {
    print_status "Configuring Microsoft Graph API permissions..."
    
    # Get Microsoft Graph service principal ID
    GRAPH_SP_ID=$(az ad sp list --display-name "Microsoft Graph" --query "[0].id" -o tsv)
    
    if [[ -z "$GRAPH_SP_ID" ]]; then
        print_error "Failed to find Microsoft Graph service principal"
        exit 1
    fi
    
    print_status "Assigning Microsoft Graph API permissions..."
    
    # First, check and clean up any existing permissions/assignments
    print_status "Checking for existing Microsoft Graph permissions..."
    cleanup_existing_permissions
    
    # Wait for cleanup to propagate
    sleep 3
    
    for permission_name in "${!GRAPH_PERMISSIONS[@]}"; do
        permission_id="${GRAPH_PERMISSIONS[$permission_name]}"
        
        print_status "  Adding permission: $permission_name"
        
        # Add the API permission with retry logic
        local max_retries=3
        local retry_count=0
        local permission_added=false
        
        while [[ $retry_count -lt $max_retries ]]; do
            if az ad app permission add \
                --id "$AZURE_CLIENT_ID" \
                --api 00000003-0000-0000-c000-000000000000 \
                --api-permissions "$permission_id=Role" \
                --only-show-errors; then
                print_success "    ✓ Permission $permission_name added"
                permission_added=true
                break
            else
                retry_count=$((retry_count + 1))
                print_warning "    ⚠ Attempt $retry_count failed, retrying..."
                sleep 2
            fi
        done
        
        if [[ "$permission_added" != "true" ]]; then
            print_error "    ✗ Failed to add permission $permission_name after $max_retries attempts"
            exit 1
        fi
    done
    
    # Enhanced admin consent granting with multiple approaches
    grant_admin_consent_enhanced
}

# Enhanced function for admin consent with multiple approaches
grant_admin_consent_enhanced() {
    print_status "Granting admin consent for Microsoft Graph API permissions..."
    
    # Longer wait for permissions to propagate
    print_status "  (Waiting for permissions to propagate...)"
    sleep 10
    
    # Approach 1: Direct admin consent command
    if [[ "$ADMIN_CONSENT_CAPABLE" == "true" ]]; then
        print_status "Attempting admin consent (Approach 1: Direct command)..."
        
        if az ad app permission admin-consent --id "$AZURE_CLIENT_ID" 2>/dev/null; then
            print_success "✓ Admin consent granted successfully via direct command"
            ADMIN_CONSENT_GRANTED=true
            
            # Verify the consent was actually granted
            if verify_admin_consent; then
                return 0
            else
                print_warning "⚠ Consent command succeeded but verification failed, trying alternative approaches..."
                ADMIN_CONSENT_GRANTED=false
            fi
        else
            print_warning "⚠ Direct admin consent failed, trying alternative approaches..."
        fi
    fi
    
    # Approach 2: Grant consent using Microsoft Graph REST API
    if [[ "$ADMIN_CONSENT_GRANTED" != "true" && "$ADMIN_CONSENT_CAPABLE" == "true" ]]; then
        print_status "Attempting admin consent (Approach 2: Microsoft Graph REST API)..."
        
        # Get the service principal object for our app
        SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv)
        
        # Grant consent for each permission using REST API
        for permission_name in "${!GRAPH_PERMISSIONS[@]}"; do
            permission_id="${GRAPH_PERMISSIONS[$permission_name]}"
            
            print_status "  Granting consent for: $permission_name"
            
            # Create app role assignment
            if az rest --method POST \
                --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
                --body "{
                    \"principalId\": \"$SP_OBJECT_ID\",
                    \"resourceId\": \"$GRAPH_SP_ID\",
                    \"appRoleId\": \"$permission_id\"
                }" 2>/dev/null; then
                print_success "    ✓ Consent granted for $permission_name"
            else
                print_warning "    ⚠ Failed to grant consent for $permission_name via REST API"
            fi
        done
        
        # Wait and verify
        sleep 5
        if verify_admin_consent; then
            print_success "✓ Admin consent granted successfully via REST API"
            ADMIN_CONSENT_GRANTED=true
            return 0
        fi
    fi
    
    # Approach 3: Azure CLI with explicit tenant context
    if [[ "$ADMIN_CONSENT_GRANTED" != "true" && "$ADMIN_CONSENT_CAPABLE" == "true" ]]; then
        print_status "Attempting admin consent (Approach 3: Explicit tenant context)..."
        
        # Set explicit tenant context and retry
        az account set --subscription "$AZURE_SUBSCRIPTION_ID"
        
        if az ad app permission admin-consent \
            --id "$AZURE_CLIENT_ID" \
            --tenant "$AZURE_TENANT_ID" 2>/dev/null; then
            
            sleep 5
            if verify_admin_consent; then
                print_success "✓ Admin consent granted successfully with explicit tenant context"
                ADMIN_CONSENT_GRANTED=true
                return 0
            fi
        fi
    fi
    
    # If all automated approaches failed, provide detailed manual instructions
    if [[ "$ADMIN_CONSENT_GRANTED" != "true" ]]; then
        provide_manual_consent_instructions
    fi
}

# Function to verify admin consent was actually granted
verify_admin_consent() {
    print_status "Verifying admin consent status..."
    
    # Get service principal object ID
    local SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv)
    
    if [[ -z "$SP_OBJECT_ID" ]]; then
        print_error "Failed to get service principal object ID"
        return 1
    fi
    
    # Check app role assignments for Microsoft Graph
    local consent_verified=true
    
    for permission_name in "${!GRAPH_PERMISSIONS[@]}"; do
        permission_id="${GRAPH_PERMISSIONS[$permission_name]}"
        
        # Check if the app role assignment exists
        if az rest --method GET \
            --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
            --query "value[?appRoleId=='$permission_id' && resourceId=='$GRAPH_SP_ID']" | jq -e '. | length > 0' &>/dev/null; then
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

# Enhanced manual consent instructions
provide_manual_consent_instructions() {
    print_warning "⚠ Automated admin consent failed - manual intervention required"
    
    # Get service principal object ID for instructions
    local SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv)
    
    print_status ""
    print_status "MANUAL ADMIN CONSENT REQUIRED:"
    print_status "=============================="
    print_status ""
    print_status "Option 1 - Azure Portal (Recommended):"
    print_status "--------------------------------------"
    print_status "1. Go to: https://portal.azure.com"
    print_status "2. Navigate to: Azure Active Directory > App registrations"
    print_status "3. Search for: $SP_NAME"
    print_status "4. Click on the application"
    print_status "5. Go to: API permissions"
    print_status "6. Click: Grant admin consent for [Your Organization]"
    print_status ""
    print_status "Option 2 - Direct Consent URL:"
    print_status "------------------------------"
    print_status "Open this URL in your browser (requires Global Admin):"
    print_status "https://login.microsoftonline.com/$AZURE_TENANT_ID/adminconsent?client_id=$AZURE_CLIENT_ID"
    print_status ""
    if [[ -n "$SP_OBJECT_ID" ]]; then
        print_status "Option 3 - PowerShell (if available):"
        print_status "------------------------------------"
        print_status "Connect-MgGraph -Scopes 'AppRoleAssignment.ReadWrite.All'"
        for permission_name in "${!GRAPH_PERMISSIONS[@]}"; do
            permission_id="${GRAPH_PERMISSIONS[$permission_name]}"
            print_status "New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId '$SP_OBJECT_ID' -ResourceId '$GRAPH_SP_ID' -AppRoleId '$permission_id'  # $permission_name"
        done
        print_status ""
    fi
    
    # Interactive consent verification
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        echo -n "Have you granted admin consent? (y/n/retry): "
        read -r CONSENT_RESPONSE
        
        case "$CONSENT_RESPONSE" in
            "y"|"Y"|"yes"|"YES")
                print_status "Verifying consent grant..."
                sleep 3
                if verify_admin_consent; then
                    print_success "✓ Manual admin consent verified successfully"
                    ADMIN_CONSENT_GRANTED=true
                    return 0
                else
                    print_warning "⚠ Admin consent verification failed"
                    if [[ $attempt -lt $max_attempts ]]; then
                        print_status "Please ensure all permissions show 'Granted for [Organization]' status"
                        attempt=$((attempt + 1))
                        continue
                    fi
                fi
                ;;
            "retry"|"r")
                print_status "Retrying automated consent..."
                if az ad app permission admin-consent --id "$AZURE_CLIENT_ID" 2>/dev/null; then
                    sleep 5
                    if verify_admin_consent; then
                        print_success "✓ Retry successful - admin consent granted"
                        ADMIN_CONSENT_GRANTED=true
                        return 0
                    fi
                fi
                print_warning "⚠ Retry failed, please use manual approach"
                ;;
            "n"|"N"|"no"|"NO")
                print_error "Admin consent is required for Power Platform operations"
                print_status "The setup can continue, but validation will fail"
                echo -n "Continue without consent? (y/N): "
                read -r CONTINUE_RESPONSE
                if [[ "$CONTINUE_RESPONSE" == "y" || "$CONTINUE_RESPONSE" == "Y" ]]; then
                    print_warning "⚠ Proceeding without admin consent - some operations may fail"
                    ADMIN_CONSENT_GRANTED=false
                    return 0
                else
                    exit 1
                fi
                ;;
            *)
                print_warning "Invalid response. Please enter 'y', 'n', or 'retry'"
                ;;
        esac
        
        attempt=$((attempt + 1))
    done
    
    print_error "Max attempts reached. Admin consent could not be verified."
    exit 1
}

# Function to register service principal with Power Platform
register_with_power_platform() {
    print_status "Registering service principal with Power Platform..."
    
    # Check current Power Platform authentication
    print_status "Validating Power Platform authentication..."
    
    CURRENT_PP_USER=$(pac auth list 2>/dev/null | grep '\*' | awk '{print $4}' 2>/dev/null)
    
    if [[ -z "$CURRENT_PP_USER" ]]; then
        print_error "No active Power Platform authentication found"
        print_error "Please run 'pac auth create' to authenticate with Power Platform"
        exit 1
    fi
    
    print_status "Authenticated as: $CURRENT_PP_USER"
    
    # Register the application with Power Platform
    print_status "Registering application with Power Platform tenant..."
    print_status "App ID: $AZURE_CLIENT_ID"
    
    # Check if already registered
    print_status "Checking if service principal is already registered..."
    PP_APP_LIST=$(pac admin application list 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to list Power Platform applications"
        print_error "Please ensure you have Power Platform tenant admin privileges"
        exit 1
    fi
    
    if echo "$PP_APP_LIST" | grep -q "$AZURE_CLIENT_ID"; then
        print_success "✓ Service principal is already registered with Power Platform"
        return 0
    fi
    
    # Register with Power Platform
    print_status "Service principal not found - proceeding with registration..."
    
    if pac admin application register --application-id "$AZURE_CLIENT_ID" 2>/dev/null; then
        print_success "✓ Service principal registered with Power Platform"
        print_status "  The service principal now has Power Platform tenant admin privileges"
        
        # Validate registration
        sleep 3
        if pac admin application list 2>/dev/null | grep -q "$AZURE_CLIENT_ID"; then
            print_success "✓ Power Platform registration validated"
        else
            print_warning "⚠ Registration validation failed (may be timing issue)"
        fi
    else
        print_error "Failed to register service principal with Power Platform"
        exit 1
    fi
}

# Function to output results
output_results() {
    print_success "Service principal setup completed successfully!"
    print_status ""
    print_status "Created Resources:"
    print_status "  ✓ Azure AD Service Principal: $SP_NAME"
    print_status "  ✓ OIDC Trust: GitHub Repository $GITHUB_OWNER/$GITHUB_REPO"
    print_status "  ✓ Azure Permissions: Owner role"
    if [[ "$ADMIN_CONSENT_GRANTED" == "true" ]]; then
        print_status "  ✓ Microsoft Graph: Admin consent granted"
    else
        print_status "  ⚠ Microsoft Graph: Manual consent required"
    fi
    print_status "  ✓ Power Platform: Tenant admin privileges"
    print_status ""
    print_status "Service Principal Details:"
    print_status "  Application ID: $AZURE_CLIENT_ID"
    print_status "  Tenant ID: $AZURE_TENANT_ID"
    print_status "  Subscription ID: $AZURE_SUBSCRIPTION_ID"
    print_status ""
    print_status "Configuration updated in: $SCRIPT_DIR/config.env"
}

# Function to save service principal info to config
save_service_principal_config() {
    # Update the configuration file with the service principal client ID
    AZURE_CLIENT_ID="$AZURE_CLIENT_ID"
    save_runtime_config
}

# Cleanup function for error handling
cleanup_on_error() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_error "Script failed with exit code: $exit_code"
        
        if [[ -n "$AZURE_CLIENT_ID" ]]; then
            print_status "Service principal created: $AZURE_CLIENT_ID"
            print_status "You can continue with the next step or clean up:"
            print_status "  ./cleanup-service-principal-config.sh"
        fi
    fi
}

# Main function
main() {
    print_status "Starting service principal setup (configuration-driven)..."
    print_status "==========================================================="
    
    # Set up error handling
    trap cleanup_on_error EXIT
    
    # Initialize configuration
    if ! init_config; then
        exit 1
    fi
    
    # Validate prerequisites
    validate_prerequisites
    
    # Create service principal
    create_service_principal
    
    # Setup GitHub OIDC
    setup_github_oidc
    
    # Assign Azure permissions
    assign_azure_permissions
    
    # Assign Graph permissions
    assign_graph_permissions
    
    # Register with Power Platform
    register_with_power_platform
    
    # Save configuration
    save_service_principal_config
    
    # Output results
    output_results
    
    # Disable error trap on successful completion
    trap - EXIT
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
