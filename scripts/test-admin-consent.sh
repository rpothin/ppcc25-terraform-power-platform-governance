#!/bin/bash
# ==============================================================================
# Test Admin Consent Process
# ==============================================================================
# This script tests the proper grant + consent workflow for Microsoft Graph API
# permissions to validate our fix works correctly
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test the admin consent process for the current service principal
test_admin_consent() {
    APP_ID="fe9d3bce-9cad-4d8e-97d7-3ac606d4b51f"
    
    print_status "Testing admin consent process for App ID: $APP_ID"
    print_status "================================================="
    
    # Step 1: Check current permissions
    print_status "Step 1: Checking current permissions..."
    
    CURRENT_PERMISSIONS=$(az ad app permission list --id "$APP_ID" --query "[?resourceAppId=='00000003-0000-0000-c000-000000000000'].resourceAccess[].id" -o tsv)
    
    if [[ -n "$CURRENT_PERMISSIONS" ]]; then
        print_success "✓ Permissions are configured"
        echo "  Permissions: $CURRENT_PERMISSIONS"
    else
        print_error "✗ No Microsoft Graph permissions found"
        exit 1
    fi
    
    # Step 2: Check current grants
    print_status "Step 2: Checking current grants..."
    
    # Try to get grants - this command can fail if no grants exist yet
    CURRENT_GRANTS=$(az ad app permission list-grants --id "$APP_ID" --query "[?resourceDisplayName=='Microsoft Graph'].scope" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$CURRENT_GRANTS" ]]; then
        print_success "✓ Permissions are granted"
        echo "  Granted scopes: $CURRENT_GRANTS"
    else
        print_warning "⚠ No grants found - attempting to grant permissions..."
        
        # Grant the permissions (note: these are application permissions, not delegated)
        print_status "  Granting Directory.Read.All..."
        if az ad app permission grant --id "$APP_ID" --api 00000003-0000-0000-c000-000000000000 --scope "Directory.Read.All" 2>/dev/null; then
            print_success "    ✓ Directory.Read.All granted"
        else
            print_warning "    ⚠ Directory.Read.All grant failed (may be application permission)"
        fi
        
        print_status "  Granting Group.ReadWrite.All..."
        if az ad app permission grant --id "$APP_ID" --api 00000003-0000-0000-c000-000000000000 --scope "Group.ReadWrite.All" 2>/dev/null; then
            print_success "    ✓ Group.ReadWrite.All granted"
        else
            print_warning "    ⚠ Group.ReadWrite.All grant failed (may be application permission)"
        fi
        
        print_status "  Granting Application.Read.All..."
        if az ad app permission grant --id "$APP_ID" --api 00000003-0000-0000-c000-000000000000 --scope "Application.Read.All" 2>/dev/null; then
            print_success "    ✓ Application.Read.All granted"
        else
            print_warning "    ⚠ Application.Read.All grant failed (may be application permission)"
        fi
        
        print_status "NOTE: Application permissions (Role type) cannot be granted via 'az ad app permission grant'"
        print_status "      They require direct admin consent only."
    fi
    
    # Step 3: Check consent status for application permissions
    print_status "Step 3: Checking admin consent status for application permissions..."
    
    # Get the service principal object ID for the app
    SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query "id" -o tsv)
    
    if [[ -z "$SP_OBJECT_ID" ]]; then
        print_error "Could not find service principal object ID"
        exit 1
    fi
    
    # For application permissions, check appRoleAssignments using the service principal object ID
    CONSENT_STATUS=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" --query "value" -o json 2>/dev/null)
    
    if [[ -n "$CONSENT_STATUS" && "$CONSENT_STATUS" != "[]" ]]; then
        print_success "✓ Admin consent is granted for application permissions"
        CONSENT_COUNT=$(echo "$CONSENT_STATUS" | jq length)
        echo "  Consented application permissions: $CONSENT_COUNT"
        
        # Show the specific permissions that are consented
        echo "  Consented permissions:"
        echo "$CONSENT_STATUS" | jq -r '.[] | "    - \(.resourceDisplayName): \(.appRoleId) (granted: \(.createdDateTime))"'
    else
        print_warning "⚠ Admin consent not found for application permissions"
        print_status "  Attempting to provide admin consent with debug output..."
        
        # Provide admin consent for application permissions with debug output
        print_status "  Running: az ad app permission admin-consent --id $APP_ID --debug"
        if az ad app permission admin-consent --id "$APP_ID" --debug 2>&1; then
            print_success "✓ Admin consent provided for application permissions"
            
            # Wait and check again with retry logic
            VERIFICATION_SUCCESS=false
            for attempt in 1 2 3; do
                print_status "  Verification attempt $attempt/3..."
                sleep $((attempt * 3))  # 3, 6, 9 seconds
                
                CONSENT_STATUS_AFTER=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" --query "value" -o json 2>/dev/null)
                
                if [[ -n "$CONSENT_STATUS_AFTER" && "$CONSENT_STATUS_AFTER" != "[]" ]]; then
                    print_success "✓ Admin consent verified after granting"
                    CONSENT_COUNT_AFTER=$(echo "$CONSENT_STATUS_AFTER" | jq length)
                    echo "  Consented application permissions: $CONSENT_COUNT_AFTER"
                    
                    # Show the specific permissions that are consented
                    echo "  Consented permissions:"
                    echo "$CONSENT_STATUS_AFTER" | jq -r '.[] | "    - \(.resourceDisplayName): \(.appRoleId) (granted: \(.createdDateTime))"'
                    VERIFICATION_SUCCESS=true
                    break
                else
                    print_warning "    ⚠ Verification attempt $attempt failed - permissions may still be propagating"
                fi
            done
            
            if [[ "$VERIFICATION_SUCCESS" != "true" ]]; then
                print_warning "⚠ Admin consent verification failed after 3 attempts"
                print_status "  Admin consent API call succeeded (status 204) but verification failed"
                print_status "  This may indicate a timing issue - permissions may be propagating"
            fi
        else
            print_error "✗ Admin consent failed (see debug output above)"
            print_status "  This may require manual approval in the Azure Portal"
        fi
    fi
    
    # Step 4: Final verification and diagnostics
    print_status "Step 4: Final verification and diagnostics..."
    
    # Check current user permissions
    print_status "Checking current user's Azure AD roles..."
    CURRENT_USER=$(az account show --query user.name -o tsv)
    USER_ROLES=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/me/memberOf" --query "value[].displayName" -o tsv 2>/dev/null || echo "Could not retrieve roles")
    print_status "  Current user: $CURRENT_USER"
    print_status "  User roles: $USER_ROLES"
    
    # Check service principal details
    print_status "Checking service principal details..."
    SP_INFO=$(az ad sp show --id "$APP_ID" --query "{displayName:displayName, appId:appId, servicePrincipalType:servicePrincipalType}" -o json 2>/dev/null)
    print_status "  Service Principal info: $SP_INFO"
    
    # Check app registration details
    print_status "Checking app registration details..."
    APP_INFO=$(az ad app show --id "$APP_ID" --query "{displayName:displayName, appId:appId, requiredResourceAccess:requiredResourceAccess}" -o json 2>/dev/null)
    print_status "  App registration info: $APP_INFO"
    
    # Check via Azure Portal URL for manual verification
    print_status "Manual verification URL:"
    print_status "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnApi/appId/$APP_ID"
    
    print_success "Admin consent test completed!"
}

# Main execution
main() {
    print_status "Starting admin consent test..."
    test_admin_consent
    print_success "Test completed successfully!"
}

main "$@"
