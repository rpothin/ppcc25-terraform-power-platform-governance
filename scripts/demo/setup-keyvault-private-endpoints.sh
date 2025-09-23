#!/bin/bash
# ==============================================================================
# Script Name: setup-keyvault-private-endpoints.sh
# Purpose: Deploy Key Vault with dual private endpoints for PPCC25 Power Platform VNet integration demo
# Usage: ./setup-keyvault-private-endpoints.sh [--auto-approve] [--config config.env]
# Dependencies: Azure CLI, Power Platform CLI (optional), existing VNet infrastructure from ptn-azure-vnet-extension
# Author: PPCC25 Demo Platform Team
# ==============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh" 2>/dev/null || {
    # WHY: Fallback if common utilities not available
    # CONTEXT: Provides basic output functions for script execution
    # IMPACT: Ensures script can run even without full utility infrastructure
    print_success() { echo "✅ $*"; }
    print_error() { echo "❌ ERROR: $*" >&2; }
    print_warning() { echo "⚠️  WARNING: $*" >&2; }
    print_info() { echo "ℹ️  $*"; }
    print_step() { echo "🔄 $*"; }
    print_status() { echo "📊 $*"; }
}

# WHY: Global configuration constants for PPCC25 demo consistency
# CONTEXT: These values match the deployed ptn-azure-vnet-extension infrastructure
# IMPACT: Ensures Key Vault integrates properly with existing VNet architecture
readonly RESOURCE_GROUP_NAME="rg-ppcc25-demoworkspace-dev-vnet-cac"
readonly KEY_VAULT_NAME="kv-ppcc25-demo-dev-cac"
readonly LOCATION_PRIMARY="canadacentral"
readonly LOCATION_FAILOVER="canadaeast"
readonly VNET_PRIMARY="vnet-ppcc25-demoworkspace-dev-cac-primary"
readonly VNET_FAILOVER="vnet-ppcc25-demoworkspace-dev-cae-failover"
readonly SUBNET_PRIVATE_ENDPOINT="snet-privateendpoint-ppcc25-demoworkspace-dev"
readonly PRIVATE_DNS_ZONE="privatelink.vaultcore.azure.net"
readonly PE_PRIMARY_NAME="pe-kv-ppcc25-demo-dev-cac"
readonly PE_FAILOVER_NAME="pe-kv-ppcc25-demo-dev-cae"

# WHY: Configuration validation prevents deployment failures
# CONTEXT: Validates Azure CLI authentication and subscription context
# IMPACT: Catches authentication issues before expensive resource operations
validate_prerequisites() {
    print_step "Validating prerequisites for Key Vault deployment..."
    
    # Check Azure CLI installation
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not installed"
        print_info "Install from: https://aka.ms/installazurecli"
        return 1
    fi
    
    # Check Azure authentication
    if ! az account show &> /dev/null; then
        print_error "Not authenticated to Azure"
        print_info "Run: az login --use-device-code"
        return 1
    fi
    
    # Validate subscription context
    local current_subscription
    current_subscription=$(az account show --query name -o tsv)
    print_info "Current subscription: $current_subscription"
    
    # Check for existing resource group
    if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_error "Resource group '$RESOURCE_GROUP_NAME' not found"
        print_info "Expected resource group should exist from ptn-azure-vnet-extension deployment"
        print_info "Run ptn-azure-vnet-extension deployment first"
        return 1
    fi
    
    print_success "Prerequisites validated successfully"
    return 0
}

# WHY: Infrastructure validation ensures VNet resources are properly deployed
# CONTEXT: Key Vault private endpoints require specific VNet configuration
# IMPACT: Prevents deployment failures due to missing or misconfigured VNets
validate_vnet_infrastructure() {
    print_step "Validating existing VNet infrastructure..."
    
    local validation_errors=()
    
    # Check primary VNet exists
    if ! az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$VNET_PRIMARY" &> /dev/null; then
        validation_errors+=("Primary VNet '$VNET_PRIMARY' not found")
    fi
    
    # Check failover VNet exists
    if ! az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$VNET_FAILOVER" &> /dev/null; then
        validation_errors+=("Failover VNet '$VNET_FAILOVER' not found")
    fi
    
    # Check private endpoint subnets exist
    if ! az network vnet subnet show --resource-group "$RESOURCE_GROUP_NAME" --vnet-name "$VNET_PRIMARY" --name "$SUBNET_PRIVATE_ENDPOINT" &> /dev/null; then
        validation_errors+=("Primary private endpoint subnet not found")
    fi
    
    if ! az network vnet subnet show --resource-group "$RESOURCE_GROUP_NAME" --vnet-name "$VNET_FAILOVER" --name "$SUBNET_PRIVATE_ENDPOINT" &> /dev/null; then
        validation_errors+=("Failover private endpoint subnet not found")
    fi
    
    # Check private DNS zone exists and is linked
    if ! az network private-dns zone show --resource-group "$RESOURCE_GROUP_NAME" --name "$PRIVATE_DNS_ZONE" &> /dev/null; then
        validation_errors+=("Private DNS zone '$PRIVATE_DNS_ZONE' not found")
    fi
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        print_error "VNet infrastructure validation failed:"
        printf "  - %s\n" "${validation_errors[@]}"
        print_info "Deploy ptn-azure-vnet-extension pattern first to create required infrastructure"
        return 1
    fi
    
    print_success "VNet infrastructure validation completed"
    return 0
}

# WHY: Key Vault deployment with enterprise security configuration
# CONTEXT: Creates Key Vault with RBAC, private network access, and demo secrets
# IMPACT: Provides secure, enterprise-grade Key Vault for Power Platform testing
deploy_key_vault() {
    print_step "Deploying Azure Key Vault with enterprise security configuration..."
    
    # WHY: Check if Key Vault already exists to avoid conflicts
    # CONTEXT: Key Vault names are globally unique and deployment will fail if name exists
    # IMPACT: Enables idempotent script execution and clear error handling
    if az keyvault show --name "$KEY_VAULT_NAME" &> /dev/null; then
        print_warning "Key Vault '$KEY_VAULT_NAME' already exists"
        print_info "Updating configuration to ensure compliance with requirements..."
    else
        print_info "Creating new Key Vault: $KEY_VAULT_NAME"
    fi
    
    # WHY: Deploy Key Vault with security-first configuration
    # CONTEXT: RBAC authorization and disabled public access follow zero-trust principles
    # IMPACT: Ensures Key Vault meets enterprise security standards for demo
    az keyvault create \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION_PRIMARY" \
        --sku standard \
        --enable-rbac-authorization true \
        --public-network-access Disabled \
        --retention-days 90 \
        --tags \
            Environment="Demo" \
            Project="PPCC25" \
            Owner="Platform Team" \
            Purpose="Power Platform VNet Integration Demo" \
            Component="key-vault" \
            Pattern="demo-key-vault-private-endpoints"
    
    print_success "Key Vault deployed with enterprise security configuration"
}

# WHY: Dual private endpoints enable optimal performance from both regions
# CONTEXT: Canada Central and Canada East VNets each get local private endpoint
# IMPACT: Eliminates cross-region latency and provides regional resilience
deploy_private_endpoints() {
    print_step "Deploying private endpoints in both regions..."
    
    local key_vault_id
    key_vault_id=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query id -o tsv)
    
    local primary_subnet_id
    primary_subnet_id=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --vnet-name "$VNET_PRIMARY" \
        --name "$SUBNET_PRIVATE_ENDPOINT" \
        --query id -o tsv)
    
    local failover_subnet_id
    failover_subnet_id=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --vnet-name "$VNET_FAILOVER" \
        --name "$SUBNET_PRIVATE_ENDPOINT" \
        --query id -o tsv)
    
    # WHY: Deploy primary region private endpoint for local VNet access
    # CONTEXT: Canada Central VNet gets local private endpoint for optimal performance
    # IMPACT: Power Platform workloads in primary region use local connectivity
    print_info "Creating primary region private endpoint: $PE_PRIMARY_NAME"
    az network private-endpoint create \
        --name "$PE_PRIMARY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION_PRIMARY" \
        --subnet "$primary_subnet_id" \
        --private-connection-resource-id "$key_vault_id" \
        --group-ids vault \
        --connection-name "${PE_PRIMARY_NAME}-connection"
    
    # WHY: Deploy failover region private endpoint for regional resilience
    # CONTEXT: Canada East VNet gets local private endpoint for performance consistency
    # IMPACT: Enables seamless failover with consistent private connectivity
    print_info "Creating failover region private endpoint: $PE_FAILOVER_NAME"
    az network private-endpoint create \
        --name "$PE_FAILOVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION_FAILOVER" \
        --subnet "$failover_subnet_id" \
        --private-connection-resource-id "$key_vault_id" \
        --group-ids vault \
        --connection-name "${PE_FAILOVER_NAME}-connection"
    
    print_success "Private endpoints deployed in both regions"
}

# WHY: DNS integration enables private endpoint name resolution
# CONTEXT: Private DNS zone groups automatically create A records for private endpoints
# IMPACT: Enables proper FQDN resolution to private IP addresses
configure_private_dns() {
    print_step "Configuring private DNS integration for both endpoints..."
    
    local dns_zone_id
    dns_zone_id=$(az network private-dns zone show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$PRIVATE_DNS_ZONE" \
        --query id -o tsv)
    
    # WHY: Create DNS zone group for primary region private endpoint
    # CONTEXT: Automatic DNS record creation for Canada Central private endpoint
    # IMPACT: Enables DNS resolution to primary region private IP (10.96.2.x)
    print_info "Configuring DNS for primary region private endpoint..."
    az network private-endpoint dns-zone-group create \
        --endpoint-name "$PE_PRIMARY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "keyvault-dns-zone-group-primary" \
        --private-dns-zone "$dns_zone_id" \
        --zone-name "$PRIVATE_DNS_ZONE"
    
    # WHY: Create DNS zone group for failover region private endpoint
    # CONTEXT: Automatic DNS record creation for Canada East private endpoint
    # IMPACT: Enables DNS resolution to failover region private IP (10.112.2.x)
    print_info "Configuring DNS for failover region private endpoint..."
    az network private-endpoint dns-zone-group create \
        --endpoint-name "$PE_FAILOVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "keyvault-dns-zone-group-failover" \
        --private-dns-zone "$dns_zone_id" \
        --zone-name "$PRIVATE_DNS_ZONE"
    
    print_success "Private DNS integration configured for both endpoints"
}

# WHY: Demo secrets enable immediate Power Platform testing
# CONTEXT: Creates test secrets that Power Platform Cloud Flows can retrieve
# IMPACT: Provides working demo scenario without additional secret management
create_demo_secrets() {
    print_step "Creating demonstration secrets for Power Platform testing..."
    
    # WHY: Get current user context for RBAC permission assignment
    # CONTEXT: Script executor needs Key Vault Secrets Officer role to create secrets
    # IMPACT: Enables secret creation during initial deployment
    local current_user_id
    current_user_id=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$current_user_id" ]]; then
        print_info "Assigning Key Vault Secrets Officer role to current user for secret creation..."
        local key_vault_scope
        key_vault_scope=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query id -o tsv)
        
        # WHY: Temporary elevated permissions for initial secret creation
        # CONTEXT: Key Vault Secrets Officer role enables secret management operations
        # IMPACT: Allows script to create demo secrets during deployment
        az role assignment create \
            --role "Key Vault Secrets Officer" \
            --assignee "$current_user_id" \
            --scope "$key_vault_scope" \
            --output none 2>/dev/null || print_warning "Role assignment may already exist"
        
        # WHY: Wait for RBAC propagation before secret operations
        # CONTEXT: Azure RBAC permissions need time to propagate across regions
        # IMPACT: Prevents permission errors during secret creation
        print_info "Waiting 30 seconds for RBAC permissions to propagate..."
        sleep 30
    fi
    
    # WHY: Create multiple test secrets for comprehensive Power Platform demo
    # CONTEXT: Different secret types demonstrate various integration scenarios
    # IMPACT: Enables rich demo scenarios with meaningful test data
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    print_info "Creating test secret: vnet-connectivity-test"
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "vnet-connectivity-test" \
        --value "SUCCESS: VNet integration working from Power Platform (Created: $timestamp)" \
        --output none
    
    print_info "Creating test secret: demo-configuration"
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "demo-configuration" \
        --value "PPCC25 Demo Configuration - Private Endpoint Connectivity Validated" \
        --output none
    
    print_info "Creating test secret: environment-info"
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "environment-info" \
        --value "Environment: Dev | Region: Canada Central/East | Pattern: Dual Private Endpoints" \
        --output none
    
    print_success "Demo secrets created successfully"
}

# WHY: Comprehensive validation ensures deployment success
# CONTEXT: Tests all components work together before declaring success
# IMPACT: Provides confidence that Power Platform integration will work
validate_deployment() {
    print_step "Validating complete Key Vault private endpoint deployment..."
    
    local validation_results=()
    
    # Validate Key Vault exists and is properly configured
    print_info "Checking Key Vault configuration..."
    local kv_public_access
    kv_public_access=$(az keyvault show --name "$KEY_VAULT_NAME" --query "properties.publicNetworkAccess" -o tsv)
    if [[ "$kv_public_access" != "Disabled" ]]; then
        validation_results+=("❌ Key Vault public access not disabled: $kv_public_access")
    else
        validation_results+=("✅ Key Vault public access properly disabled")
    fi
    
    # Validate both private endpoints exist and are connected
    print_info "Checking private endpoint status..."
    local pe_primary_state pe_failover_state
    pe_primary_state=$(az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    pe_failover_state=$(az network private-endpoint show --name "$PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    if [[ "$pe_primary_state" == "Succeeded" ]]; then
        validation_results+=("✅ Primary private endpoint deployed successfully")
    else
        validation_results+=("❌ Primary private endpoint status: $pe_primary_state")
    fi
    
    if [[ "$pe_failover_state" == "Succeeded" ]]; then
        validation_results+=("✅ Failover private endpoint deployed successfully")
    else
        validation_results+=("❌ Failover private endpoint status: $pe_failover_state")
    fi
    
    # Validate DNS records exist for both endpoints
    print_info "Checking DNS record configuration..."
    local dns_records
    dns_records=$(az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "${KEY_VAULT_NAME}" \
        --query "aRecords | length(@)" -o tsv 2>/dev/null || echo "0")
    
    if [[ "$dns_records" -ge 2 ]]; then
        validation_results+=("✅ DNS records configured for both private endpoints")
        
        # Show actual DNS record details
        print_info "DNS A records for Key Vault:"
        az network private-dns record-set a show \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "${KEY_VAULT_NAME}" \
            --query "aRecords[].ipv4Address" -o tsv | while read -r ip; do
            print_info "  - $ip"
        done
    else
        validation_results+=("❌ Insufficient DNS records found: $dns_records (expected: 2)")
    fi
    
    # Validate test secrets exist
    print_info "Checking demo secrets availability..."
    local secret_count
    secret_count=$(az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "length(@)" -o tsv 2>/dev/null || echo "0")
    if [[ "$secret_count" -ge 3 ]]; then
        validation_results+=("✅ Demo secrets created successfully ($secret_count secrets)")
    else
        validation_results+=("⚠️ Limited demo secrets found: $secret_count")
    fi
    
    # Display validation results
    print_info "Deployment validation results:"
    printf "%s\n" "${validation_results[@]}"
    
    # Check for any critical failures
    if printf "%s\n" "${validation_results[@]}" | grep -q "❌"; then
        print_error "Deployment validation found critical issues"
        return 1
    else
        print_success "Deployment validation completed successfully"
        return 0
    fi
}

# WHY: Cleanup function ensures resources are cleaned up on script interruption
# CONTEXT: Prevents orphaned resources if script is interrupted during deployment
# IMPACT: Maintains clean Azure environment and prevents resource conflicts
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_warning "Script interrupted with exit code: $exit_code"
        print_info "Some resources may have been partially created"
        print_info "Run script again or clean up manually if needed"
    fi
    
    exit $exit_code
}
trap cleanup EXIT SIGINT SIGTERM

# WHY: Display comprehensive deployment information for demo preparation
# CONTEXT: Provides all necessary information for Power Platform Cloud Flow configuration
# IMPACT: Enables immediate demo execution with clear setup instructions
display_demo_information() {
    print_success "🎉 Key Vault private endpoint deployment completed successfully!"
    
    cat << EOF

📋 DEMO CONFIGURATION SUMMARY
=====================================

Key Vault Information:
  Name: $KEY_VAULT_NAME
  Location: $LOCATION_PRIMARY
  URI: https://${KEY_VAULT_NAME}.vault.azure.net/
  Public Access: Disabled (Private endpoints only)

Private Endpoints:
  Primary Region: $PE_PRIMARY_NAME (Canada Central)
  Failover Region: $PE_FAILOVER_NAME (Canada East)

Demo Secrets Created:
  - vnet-connectivity-test
  - demo-configuration  
  - environment-info

🚀 POWER PLATFORM CLOUD FLOW SETUP
===================================

1. Open Power Automate in your DemoWorkspace - Dev environment
2. Create new instant cloud flow: "Key Vault VNet Connectivity Test"
3. Add HTTP action with these settings:
   - Method: GET
   - URI: https://${KEY_VAULT_NAME}.vault.azure.net/secrets/vnet-connectivity-test?api-version=7.4
   - Authentication: Managed Identity (System-assigned)
   - Audience: https://vault.azure.net

4. Add condition to check response:
   - If statusCode equals 200: Success message
   - Else: Error handling with details

Expected Success Response:
  Status: 200 OK
  Value: "SUCCESS: VNet integration working from Power Platform..."

🔍 VERIFICATION COMMANDS  
=========================

# Test DNS resolution (should show private IPs):
nslookup ${KEY_VAULT_NAME}.vault.azure.net

# Check private endpoint status:
az network private-endpoint list --resource-group $RESOURCE_GROUP_NAME --query "[].{name:name,state:provisioningState}" -o table

# View DNS records:
az network private-dns record-set a show --resource-group $RESOURCE_GROUP_NAME --zone-name $PRIVATE_DNS_ZONE --name $KEY_VAULT_NAME

# List available secrets:
az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[].name" -o table

📖 TROUBLESHOOTING
==================

If Power Platform access fails:
1. Verify enterprise policy is applied to environment
2. Check Key Vault RBAC permissions (Key Vault Secrets User role)
3. Confirm VNet integration is working (check enterprise policy health)
4. Test DNS resolution from Power Platform subnet

For permission issues:
az role assignment create --role "Key Vault Secrets User" --assignee [USER-ID] --scope [KEY-VAULT-RESOURCE-ID]

✨ Your PPCC25 demo environment is ready for Power Platform VNet integration testing!

EOF
}

# WHY: Main execution function with comprehensive error handling and user confirmation
# CONTEXT: Orchestrates all deployment steps with clear progress indication
# IMPACT: Provides reliable, repeatable deployment process for demo environment
main() {
    local auto_approve=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--auto-approve]"
                echo ""
                echo "Deploy Azure Key Vault with dual private endpoints for PPCC25 demo"
                echo ""
                echo "Options:"
                echo "  --auto-approve    Skip confirmation prompts"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                return 1
                ;;
        esac
    done
    
    print_step "Starting PPCC25 Key Vault private endpoint deployment..."
    
    # Validate prerequisites before starting deployment
    if ! validate_prerequisites; then
        return 1
    fi
    
    if ! validate_vnet_infrastructure; then
        return 1
    fi
    
    # WHY: User confirmation prevents accidental deployments
    # CONTEXT: Azure resource deployment has cost and time implications
    # IMPACT: Ensures intentional deployment and provides deployment preview
    if [[ "$auto_approve" != true ]]; then
        cat << EOF

🔍 DEPLOYMENT PREVIEW
====================

This script will deploy:
  ✅ Azure Key Vault: $KEY_VAULT_NAME
  ✅ Private Endpoint (Primary): $PE_PRIMARY_NAME in $LOCATION_PRIMARY  
  ✅ Private Endpoint (Failover): $PE_FAILOVER_NAME in $LOCATION_FAILOVER
  ✅ Private DNS integration for both endpoints
  ✅ Demo secrets for Power Platform testing

Target Resource Group: $RESOURCE_GROUP_NAME
Expected Duration: 5-10 minutes
Estimated Cost: ~$10-15/month for Key Vault + Private Endpoints

EOF
        
        read -p "Continue with deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled by user"
            return 0
        fi
    fi
    
    # Execute deployment steps
    deploy_key_vault
    deploy_private_endpoints
    configure_private_dns
    create_demo_secrets
    
    # Validate complete deployment
    if ! validate_deployment; then
        print_error "Deployment validation failed - check output above"
        return 1
    fi
    
    display_demo_information
    
    print_success "🎯 PPCC25 Key Vault private endpoint deployment completed successfully!"
    return 0
}

# Execute main function with all arguments
main "$@"