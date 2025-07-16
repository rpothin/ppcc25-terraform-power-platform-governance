#!/bin/bash
# ==============================================================================
# Create Service Principal with OIDC for GitHub and Power Platform Access
# ==============================================================================
# This script creates an Azure AD service principal with the required permissions
# for both Azure and Power Platform, then registers it with Power Platform.
# It also sets up OIDC trust with the GitHub repository.
#
# SECURITY NOTE: This script assigns the Owner role at subscription level and
# Microsoft Graph API permissions to enable comprehensive governance scenarios:
# - Azure resource deployment and management
# - Identity and access management (managed identities, role assignments)
# - Entra ID security group creation and management
# - Storage account and container management for Terraform state
# - Power Platform environment and resource configuration
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
ADMIN_CONSENT_CAPABLE=false
ADMIN_CONSENT_GRANTED=false

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

# Function to validate required tools
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

# Function to get user input with validation
get_user_input() {
    print_status "Gathering configuration information..."
    
    # Get GitHub repository information
    echo -n "Enter GitHub repository owner/organization: "
    read -r GITHUB_OWNER
    if [[ -z "$GITHUB_OWNER" ]]; then
        print_error "GitHub owner cannot be empty"
        exit 1
    fi
    
    echo -n "Enter GitHub repository name: "
    read -r GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        print_error "GitHub repository name cannot be empty"
        exit 1
    fi
    
    # Get service principal name (optional)
    echo -n "Enter service principal name (default: terraform-powerplatform-governance): "
    read -r SP_NAME
    if [[ -z "$SP_NAME" ]]; then
        SP_NAME="terraform-powerplatform-governance"
    fi
    
    # Get Azure subscription ID (with current subscription as default)
    CURRENT_SUBSCRIPTION=$(az account show --query id -o tsv)
    echo -n "Enter Azure subscription ID (default: $CURRENT_SUBSCRIPTION): "
    read -r AZURE_SUBSCRIPTION_ID
    if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        AZURE_SUBSCRIPTION_ID="$CURRENT_SUBSCRIPTION"
    fi
    
    # Get tenant ID
    AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
    
    print_status "Configuration:"
    print_status "  GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status "  Service Principal: $SP_NAME"
    print_status "  Azure Subscription: $AZURE_SUBSCRIPTION_ID"
    print_status "  Azure Tenant: $AZURE_TENANT_ID"
    
    echo -n "Continue with this configuration? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
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
        
        # Only show non-sensitive information
        print_status "Service Principal created with the following details:"
        print_status "  Display Name: $SP_NAME"
        print_status "  Role: Owner (subscription-level)"
        print_status "  Application ID: [REDACTED - stored securely]"
        print_status "  Tenant ID: [REDACTED - stored securely]"
        print_status "  Subscription ID: [REDACTED - stored securely]"
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
    
    # The Owner role already includes all necessary permissions:
    # - Full access to all resources (including Contributor permissions)
    # - User Access Administrator (for managing role assignments)
    # - Storage Blob Data Contributor (for Terraform state management)
    # - Reader access (for resource discovery)
    
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
    
    # Required Graph API permissions for group management
    declare -A GRAPH_PERMISSIONS=(
        ["Group.ReadWrite.All"]="62a82d76-70ea-41e2-9197-370581804d09"
        ["Directory.Read.All"]="7ab1d382-f21e-4acd-a863-ba3e13f7da61"
        ["Application.Read.All"]="9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
    )
    
    print_status "Assigning Microsoft Graph API permissions..."
    
    for permission_name in "${!GRAPH_PERMISSIONS[@]}"; do
        permission_id="${GRAPH_PERMISSIONS[$permission_name]}"
        
        print_status "  Adding permission: $permission_name"
        
        # Add the API permission (this may show grant messages - this is normal)
        az ad app permission add \
            --id "$AZURE_CLIENT_ID" \
            --api 00000003-0000-0000-c000-000000000000 \
            --api-permissions "$permission_id=Role" \
            --only-show-errors
        
        if [[ $? -eq 0 ]]; then
            print_success "    ✓ Permission $permission_name added"
        else
            print_warning "    ⚠ Failed to add permission $permission_name"
        fi
    done
    
    # Grant admin consent for the API permissions
    print_status "Granting admin consent for Microsoft Graph API permissions..."
    
    if [[ "$ADMIN_CONSENT_CAPABLE" == "true" ]]; then
        print_status "  (Waiting for permissions to propagate...)"
        
        # Brief wait for permissions to propagate
        sleep 5
        
        # CRITICAL: For APPLICATION permissions (Role type), we cannot use 'az ad app permission grant'
        # Application permissions require direct admin consent only
        print_status "Step 1: Application permissions detected - skipping grant step"
        print_status "  Application permissions (Role type) cannot be granted via CLI"
        print_status "  They require direct admin consent only"
        
        # Step 2: Wait for application to propagate, then attempt admin consent
        print_status "Step 2: Waiting for application to propagate in Azure AD..."
        
        # Wait for application to be ready for admin consent
        PROPAGATION_SUCCESS=false
        for attempt in 1 2 3 4 5; do
            print_status "  Propagation check attempt $attempt/5..."
            
            # Check if we can successfully query the application
            if az ad app show --id "$AZURE_CLIENT_ID" --query "appId" -o tsv &>/dev/null; then
                print_success "  ✓ Application is ready for admin consent"
                PROPAGATION_SUCCESS=true
                break
            else
                print_status "  ⚠ Application still propagating, waiting 5 seconds..."
                sleep 5
            fi
        done
        
        if [[ "$PROPAGATION_SUCCESS" != "true" ]]; then
            print_error "Application failed to propagate properly"
            ADMIN_CONSENT_GRANTED=false
        else
            print_status "Step 3: Providing admin consent for application permissions..."
            
            print_status "  Running: az ad app permission admin-consent --id $AZURE_CLIENT_ID --debug"
            ADMIN_CONSENT_OUTPUT=$(az ad app permission admin-consent --id "$AZURE_CLIENT_ID" --debug 2>&1)
            ADMIN_CONSENT_RESULT=$?
            
            if [[ $ADMIN_CONSENT_RESULT -eq 0 ]]; then
                print_success "✓ Admin consent granted programmatically"
                
                # Verify the consent was actually granted with retry logic
                print_status "Verifying admin consent status..."
                
                # Get the service principal object ID for proper verification
                SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv)
                
                # Retry verification up to 3 times with increasing delays
                VERIFICATION_SUCCESS=false
                for attempt in 1 2 3; do
                    print_status "  Verification attempt $attempt/3..."
                    sleep $((attempt * 3))  # 3, 6, 9 seconds
                    
                    # Check if permissions are actually consented using the service principal object ID
                    CONSENT_STATUS=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" --query "value" -o json 2>/dev/null)
                    
                    if [[ -n "$CONSENT_STATUS" && "$CONSENT_STATUS" != "[]" ]]; then
                        print_success "✓ Admin consent verified after granting"
                        CONSENT_COUNT=$(echo "$CONSENT_STATUS" | jq length)
                        print_status "  Consented application permissions: $CONSENT_COUNT"
                        
                        # Show the specific permissions that are consented
                        print_status "  Consented permissions:"
                        echo "$CONSENT_STATUS" | jq -r '.[] | "    - \(.resourceDisplayName): \(.appRoleId) (granted: \(.createdDateTime))"'
                        
                        print_status "  This enables the service principal to:"
                        print_status "    - Create and manage security groups in Entra ID"
                        print_status "    - Read directory information"
                        print_status "    - Read application information"
                        ADMIN_CONSENT_GRANTED=true
                        VERIFICATION_SUCCESS=true
                        break
                    else
                        print_warning "    ⚠ Verification attempt $attempt failed - permissions may still be propagating"
                    fi
                done
                
                if [[ "$VERIFICATION_SUCCESS" != "true" ]]; then
                    print_warning "⚠ Admin consent verification failed after 3 attempts"
                    print_status "  Admin consent API call succeeded but verification failed"
                    print_status "  This may indicate a timing issue - permissions may be propagating"
                    print_status "  You can manually verify at: https://portal.azure.com"
                    ADMIN_CONSENT_GRANTED=false
                fi
            else
                print_warning "⚠ Programmatic admin consent failed (see debug output above)"
                
                # Check for specific error types
                if echo "$ADMIN_CONSENT_OUTPUT" | grep -q "application.*removed\|incorrect application identifier"; then
                    print_status "  Error: Application propagation timing issue detected"
                    print_status "  The application may need more time to propagate in Azure AD"
                    print_status "  Try running the script again in a few minutes"
                elif echo "$ADMIN_CONSENT_OUTPUT" | grep -q "Insufficient privileges\|unauthorized\|forbidden"; then
                    print_status "  Error: Insufficient permissions for admin consent"
                    print_status "  You may need Global Administrator role or equivalent"
                else
                    print_status "  Error: Unknown admin consent failure"
                fi
                
                print_status "  This may be due to timing issues or insufficient permissions"
                ADMIN_CONSENT_GRANTED=false
            fi
        fi
    else
        print_warning "⚠ Insufficient permissions for programmatic admin consent"
        ADMIN_CONSENT_GRANTED=false
    fi
    
    # Provide fallback instructions if programmatic consent failed
    if [[ "$ADMIN_CONSENT_GRANTED" != "true" ]]; then
        print_status ""
        print_status "MANUAL ADMIN CONSENT REQUIRED:"
        print_status "=============================="
        print_status ""
        print_status "The Microsoft Graph API permissions have been added to the application"
        print_status "but admin consent needs to be granted manually."
        print_status ""
        print_status "Option 1 - Azure Portal:"
        print_status "  1. Go to: https://portal.azure.com"
        print_status "  2. Navigate to: Azure Active Directory > App registrations"
        print_status "  3. Search for: $SP_NAME"
        print_status "  4. Click on: API permissions"
        print_status "  5. Click: Grant admin consent for [Your Organization]"
        print_status ""
        print_status "Option 2 - Direct URL (requires Global Admin):"
        print_status "  https://login.microsoftonline.com/$AZURE_TENANT_ID/adminconsent?client_id=$AZURE_CLIENT_ID"
        print_status ""
        print_status "Option 3 - Manual CLI commands (for application permissions):"
        print_status "  # Application permissions skip the grant step and go directly to admin consent:"
        print_status "  az ad app permission admin-consent --id $AZURE_CLIENT_ID"
        print_status "  # Note: 'az ad app permission grant' is only for delegated permissions"
        print_status ""
        print_status "Option 4 - Continue without Graph permissions:"
        print_status "  The service principal will work for basic Azure and Power Platform"
        print_status "  operations, but won't be able to create/manage security groups."
        print_status ""
        
        echo -n "Have you granted admin consent manually? (y/n/skip): "
        read -r CONSENT_RESPONSE
        
        if [[ "$CONSENT_RESPONSE" == "y" || "$CONSENT_RESPONSE" == "Y" ]]; then
            print_success "✓ Manual admin consent confirmed"
            ADMIN_CONSENT_GRANTED=true
        elif [[ "$CONSENT_RESPONSE" == "skip" || "$CONSENT_RESPONSE" == "s" ]]; then
            print_warning "⚠ Proceeding without Graph API permissions"
            print_status "  Some advanced features may not work without these permissions"
            ADMIN_CONSENT_GRANTED=false
        else
            print_error "Admin consent is required for full functionality"
            print_error "Please grant consent and run the script again"
            exit 1
        fi
    fi
}

# Function to register service principal with Power Platform
register_with_power_platform() {
    print_status "Registering service principal with Power Platform..."
    
    # Check current Power Platform authentication
    print_status "Validating Power Platform authentication..."
    CURRENT_PP_USER=$(pac auth list --json | jq -r '.[] | select(.IsActive == true) | .Name' 2>/dev/null)
    
    if [[ -z "$CURRENT_PP_USER" ]]; then
        print_error "No active Power Platform authentication found"
        print_error "Please run 'pac auth create' to authenticate with Power Platform"
        exit 1
    fi
    
    print_status "Authenticated as: $CURRENT_PP_USER"
    
    # Register the application with Power Platform
    # This grants the service principal access to Power Platform APIs
    print_status "Registering application with Power Platform tenant..."
    
    PP_OUTPUT=$(pac admin application register --application-id "$AZURE_CLIENT_ID" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "Service principal registered with Power Platform"
        print_status "The service principal now has Power Platform tenant admin privileges"
        
        # Validate the registration
        print_status "Validating Power Platform registration..."
        if pac admin application list --application-id "$AZURE_CLIENT_ID" &> /dev/null; then
            print_success "✓ Power Platform registration validated"
        else
            print_warning "⚠ Could not validate Power Platform registration"
            print_status "  Registration may still be propagating"
        fi
    else
        print_error "Failed to register service principal with Power Platform"
        print_error "Error output: $PP_OUTPUT"
        
        # Check for common issues
        if echo "$PP_OUTPUT" | grep -q "unauthorized\|forbidden\|permission"; then
            print_error "Insufficient permissions detected"
            print_error "Please ensure you have Power Platform tenant admin privileges"
            print_status "Required roles: Global Administrator, Power Platform Administrator, or System Administrator"
        fi
        
        exit 1
    fi
}

# Function to validate admin consent status
validate_admin_consent() {
    print_status "Validating admin consent status..."
    
    # Get the service principal object ID
    SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query "id" -o tsv 2>/dev/null)
    
    if [[ -z "$SP_OBJECT_ID" ]]; then
        print_error "Could not find service principal object ID"
        return 1
    fi
    
    # Check service principal app role assignments (most reliable for application permissions)
    CONSENTED_PERMISSIONS=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" --query "value" -o json 2>/dev/null)
    
    if [[ -n "$CONSENTED_PERMISSIONS" && "$CONSENTED_PERMISSIONS" != "[]" ]]; then
        print_success "✓ Admin consent validation passed"
        CONSENT_COUNT=$(echo "$CONSENTED_PERMISSIONS" | jq length)
        print_status "  Consented application permissions: $CONSENT_COUNT"
        
        # Show the specific permissions that are consented
        print_status "  Consented permissions:"
        echo "$CONSENTED_PERMISSIONS" | jq -r '.[] | "    - \(.resourceDisplayName): \(.appRoleId) (granted: \(.createdDateTime))"'
        return 0
    fi
    
    print_warning "⚠ Admin consent validation failed - no consented permissions found"
    return 1
}

# Function to output results
output_results() {
    print_success "Service principal setup completed successfully!"
    print_status ""
    print_status "NEXT STEPS:"
    print_status "==========="
    print_status ""
    print_status "1. Run the next script: 02-create-terraform-backend.sh"
    print_status "2. When prompted, use these values:"
    print_status ""
    print_status "   Azure Client ID: $AZURE_CLIENT_ID"
    print_status "   Azure Tenant ID: $AZURE_TENANT_ID"
    print_status "   Azure Subscription ID: $AZURE_SUBSCRIPTION_ID"
    print_status "   GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_status ""
    print_status "SECURITY NOTES:"
    print_status "- These values are safe to display (no secrets)"
    print_status "- Authentication uses OIDC (no long-lived secrets)"
    print_status "- All credentials are stored securely in Azure AD"
    print_status ""
    print_status "PERMISSIONS GRANTED:"
    print_status "- Azure: Owner role (subscription-level)"
    if [[ "$ADMIN_CONSENT_GRANTED" == "true" ]]; then
        print_status "- Microsoft Graph: Group.ReadWrite.All, Directory.Read.All, Application.Read.All (✓ CONSENTED)"
    else
        print_status "- Microsoft Graph: Group.ReadWrite.All, Directory.Read.All, Application.Read.All (⚠ CONSENT PENDING)"
        print_status "  Manual consent required - see instructions above"
    fi
    print_status "- Power Platform: Tenant admin privileges"
    
    if [[ "$ADMIN_CONSENT_GRANTED" != "true" ]]; then
        print_status ""
        print_status "IMPORTANT: Complete the admin consent process before proceeding"
        print_status "to ensure full functionality of the Terraform configurations."
    fi
}

# Main execution
main() {
    print_status "Starting service principal setup for Power Platform Terraform governance..."
    print_status "=================================================="
    
    validate_prerequisites
    get_user_input
    create_service_principal
    setup_github_oidc
    assign_azure_permissions
    assign_graph_permissions
    register_with_power_platform
    output_results
    
    print_success "Script completed successfully!"
}

# Run the main function
main "$@"
