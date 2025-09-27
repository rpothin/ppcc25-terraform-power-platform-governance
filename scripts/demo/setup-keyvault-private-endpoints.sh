#!/bin/bash
# ==============================================================================
# Script Name: setup-keyvault-private-endpoints.sh
# Purpose: Deploy Key Vault with dual private endpoints for PPCC25 Power Platform VNet integration demo
# Usage: ./setup-keyvault-private-endpoints.sh [--auto-approve] [--tfvars-file <name>]
# Dependencies: Azure CLI, Power Platform CLI (optional), existing VNet infrastructure from ptn-azure-vnet-extension
# Author: PPCC25 Demo Platform Team
# ==============================================================================

set -euo pipefail

# WHY: Dynamic configuration constants calculated from tfvars file input
# CONTEXT: Enables script reuse across different workspace configurations
# IMPACT: Single script works with multiple demo environments (demo-prep, regional-examples, etc.)

# Global variables for dynamic resource naming (initialized from tfvars)
RESOURCE_GROUP_NAME=""
KEY_VAULT_NAME=""
VNET_PRIMARY=""
VNET_FAILOVER=""
SUBNET_PRIVATE_ENDPOINT=""
PE_PRIMARY_NAME=""
PE_FAILOVER_NAME=""
WORKSPACE_NAME=""
TFVARS_FILE_NAME=""

# Static constants
readonly LOCATION_PRIMARY="canadacentral"
readonly LOCATION_FAILOVER="canadaeast"
readonly PRIVATE_DNS_ZONE="privatelink.vaultcore.azure.net"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
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

# ============================================================================
# DYNAMIC CONFIGURATION - tfvars Parsing and Resource Naming
# ============================================================================

# WHY: Parse workspace name from environment group tfvars file
# CONTEXT: Enables dynamic resource naming based on actual Terraform configuration
# IMPACT: Single script works with any workspace configuration (demo-prep, regional-examples, etc.)
parse_workspace_name_from_tfvars() {
    local tfvars_file="$1"
    local env_group_tfvars_path="${SCRIPT_DIR}/../../configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
    
    if [[ ! -f "$env_group_tfvars_path" ]]; then
        print_error "Environment group tfvars file not found: $env_group_tfvars_path"
        print_info "Expected format: configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
        return 1
    fi
    
    # Extract workspace name from tfvars file (handle both quoted and unquoted values)
    local workspace_name
    workspace_name=$(grep -E '^[[:space:]]*name[[:space:]]*=' "$env_group_tfvars_path" | \
                     sed -E 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"?([^"#]*)"?[[:space:]]*#?.*$/\1/' | \
                     sed 's/[[:space:]]*$//' | head -n1)
    
    if [[ -z "$workspace_name" ]]; then
        print_error "Unable to parse workspace name from tfvars file: $env_group_tfvars_path"
        print_info "Expected format: name = \"WorkspaceName\""
        return 1
    fi
    
    print_info "Parsed workspace name: $workspace_name"
    echo "$workspace_name"
    return 0
}

# WHY: Apply same naming transformations as Terraform locals
# CONTEXT: Ensures bash script resource names match Terraform-generated names exactly
# IMPACT: Prevents resource naming conflicts between script and Terraform
generate_resource_names() {
    local workspace_name="$1"
    local tfvars_file="$2"
    
    # WHY: Apply Terraform naming transformations
    # CONTEXT: Match the logic from ptn-azure-vnet-extension/locals.tf
    local workspace_clean
    workspace_clean=$(echo "$workspace_name" | tr '[:upper:]' '[:lower:]')
    
    # WHY: Environment suffix transformation (basic template: Dev environment)
    # CONTEXT: " - Dev" becomes "dev" using same logic as Terraform
    local env_suffix="dev"  # For basic template, first environment is always Dev
    
    # WHY: CAF naming pattern components
    # CONTEXT: Match Cloud Adoption Framework patterns from Terraform configuration
    local project="ppcc25"
    local location_abbrev="cac"  # Canada Central
    local failover_abbrev="cae"  # Canada East
    
    # WHY: Generate resource names using CAF patterns
    # CONTEXT: Follow exact same patterns as defined in Terraform locals
    RESOURCE_GROUP_NAME="rg-${project}-${workspace_clean}-${env_suffix}-vnet-${location_abbrev}"
    VNET_PRIMARY="vnet-${project}-${workspace_clean}-${env_suffix}-${location_abbrev}-primary"
    VNET_FAILOVER="vnet-${project}-${workspace_clean}-${env_suffix}-${failover_abbrev}-failover"
    SUBNET_PRIVATE_ENDPOINT="snet-privateendpoint-${project}-${workspace_clean}-${env_suffix}"
    
    # WHY: Key Vault naming with length constraints
    # CONTEXT: Key Vault names have 24 character limit, use shortened workspace name
    local workspace_short
    if [[ ${#workspace_clean} -gt 12 ]]; then
        # Create meaningful abbreviation for long workspace names
        workspace_short=$(echo "$workspace_clean" | sed 's/workspace/ws/g' | cut -c1-12)
    else
        workspace_short="$workspace_clean"
    fi
    
    KEY_VAULT_NAME="kv-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    PE_PRIMARY_NAME="pe-kv-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    PE_FAILOVER_NAME="pe-kv-${project}-${workspace_short}-${env_suffix}-${failover_abbrev}"
    
    # Store for reference
    WORKSPACE_NAME="$workspace_name"
    TFVARS_FILE_NAME="$tfvars_file"
    
    print_info "Generated resource names:"
    print_info "  Resource Group: $RESOURCE_GROUP_NAME"
    print_info "  Key Vault: $KEY_VAULT_NAME"
    print_info "  VNet Primary: $VNET_PRIMARY"
    print_info "  VNet Failover: $VNET_FAILOVER"
    print_info "  PE Primary: $PE_PRIMARY_NAME"
    print_info "  PE Failover: $PE_FAILOVER_NAME"
    
    return 0
}

# WHY: Validate that both paired tfvars files exist
# CONTEXT: ptn-azure-vnet-extension requires paired environment group configuration
# IMPACT: Prevents deployment failures due to missing configuration files
validate_tfvars_files() {
    local tfvars_file="$1"
    
    local env_group_path="${SCRIPT_DIR}/../../configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
    local vnet_ext_path="${SCRIPT_DIR}/../../configurations/ptn-azure-vnet-extension/tfvars/${tfvars_file}.tfvars"
    
    local missing_files=()
    
    if [[ ! -f "$env_group_path" ]]; then
        missing_files+=("Environment Group: $env_group_path")
    fi
    
    if [[ ! -f "$vnet_ext_path" ]]; then
        missing_files+=("VNet Extension: $vnet_ext_path")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required tfvars files:"
        printf "  - %s\n" "${missing_files[@]}"
        print_info ""
        print_info "Both files must exist with matching names:"
        print_info "  - configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
        print_info "  - configurations/ptn-azure-vnet-extension/tfvars/${tfvars_file}.tfvars"
        return 1
    fi
    
    print_success "Validated paired tfvars files exist"
    return 0
}

# WHY: Initialize dynamic configuration from tfvars file
# CONTEXT: Single function to set up all dynamic variables
# IMPACT: Clean separation between static and dynamic configuration
initialize_dynamic_config() {
    local tfvars_file="$1"
    
    print_step "Initializing dynamic configuration from tfvars file: $tfvars_file"
    
    # Validate tfvars files exist
    if ! validate_tfvars_files "$tfvars_file"; then
        return 1
    fi
    
    # Parse workspace name
    local workspace_name
    workspace_name=$(parse_workspace_name_from_tfvars "$tfvars_file")
    if [[ $? -ne 0 || -z "$workspace_name" ]]; then
        return 1
    fi
    
    # Generate all resource names
    generate_resource_names "$workspace_name" "$tfvars_file"
    
    print_success "Dynamic configuration initialized successfully"
    return 0
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

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

# WHY: Key Vault deployment with enterprise security configuration and soft-delete handling
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
        
        # Update existing Key Vault configuration to match requirements
        az keyvault update \
            --name "$KEY_VAULT_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --public-network-access Disabled \
            --output none 2>/dev/null || print_warning "Some settings may not be updatable"
            
        print_success "Existing Key Vault configuration validated"
        return 0
    fi
    
    # Check for soft-deleted Key Vault that would block deployment
    if az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME']" | grep -q "$KEY_VAULT_NAME"; then
        print_error "Key Vault '$KEY_VAULT_NAME' exists in soft-deleted state"
        print_info "This prevents creating a new Key Vault with the same name"
        print_info ""
        print_info "Resolution options:"
        print_info "1. Run cleanup script with --purge-soft-deleted flag:"
        print_info "   ./scripts/demo/cleanup-keyvault-private-endpoints.sh --purge-soft-deleted"
        print_info "2. Recover the existing soft-deleted Key Vault:"
        print_info "   az keyvault recover --name $KEY_VAULT_NAME"
        print_info "3. Choose a different Key Vault name in the script"
        return 1
    fi
    
    print_info "Creating new Key Vault: $KEY_VAULT_NAME"
    
    # WHY: Deploy Key Vault with security-first configuration
    # CONTEXT: RBAC authorization and disabled public access follow zero-trust principles
    # IMPACT: Ensures Key Vault meets enterprise security standards for demo
    if ! az keyvault create \
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
            Pattern="demo-key-vault-private-endpoints"; then
        
        print_error "Key Vault deployment failed"
        
        # Check again for soft-delete conflict (race condition)
        if az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME']" | grep -q "$KEY_VAULT_NAME"; then
            print_error "Soft-deleted Key Vault detected during deployment"
            print_info "Run: ./scripts/demo/cleanup-keyvault-private-endpoints.sh --purge-soft-deleted --auto-approve"
            print_info "Then retry this setup script"
        fi
        
        return 1
    fi
    
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

# WHY: Demo secrets enable immediate Power Platform testing with temporary public access
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
    
    # WHY: Temporarily enable public access for secret creation
    # CONTEXT: Azure CLI cannot access Key Vault through private endpoints during initial setup
    # IMPACT: Allows secret creation, then re-secures Key Vault with private-only access
    print_info "Temporarily enabling public access for secret creation..."
    az keyvault update \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --public-network-access Enabled \
        --output none
    
    # Wait for public access to be enabled
    print_info "Waiting 15 seconds for public access to be enabled..."
    sleep 15
    
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
    
    # WHY: Re-disable public access for security after secret creation
    # CONTEXT: Ensures Key Vault returns to private-only access mode for demo
    # IMPACT: Maintains security posture while enabling private endpoint testing
    print_info "Re-disabling public access to maintain security posture..."
    az keyvault update \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --public-network-access Disabled \
        --output none
    
    # Wait for public access to be disabled
    print_info "Waiting 10 seconds for public access to be disabled..."
    sleep 10
    
    print_success "Key Vault secured with private-only access"
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
    
    if [[ "$dns_records" -ge 1 ]]; then
        validation_results+=("✅ DNS records configured for private endpoints ($dns_records record(s))")
        
        # Show actual DNS record details
        print_info "DNS A records for Key Vault:"
        az network private-dns record-set a show \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "${KEY_VAULT_NAME}" \
            --query "aRecords[].ipv4Address" -o tsv | while read -r ip; do
            print_info "  - $ip"
        done
        
        # Note about DNS record consolidation
        if [[ "$dns_records" -eq 1 ]]; then
            print_info "Note: Multiple private endpoints may share a single DNS record (normal behavior)"
        fi
    else
        validation_results+=("❌ No DNS records found for private endpoints")
    fi
    
    # Validate test secrets exist (only when public access is available)
    print_info "Checking demo secrets availability..."
    local secret_check_result="unknown"
    local secret_count=0
    
    # Check if public access is enabled for secret validation
    local current_public_access
    current_public_access=$(az keyvault show --name "$KEY_VAULT_NAME" --query "properties.publicNetworkAccess" -o tsv 2>/dev/null)
    
    if [[ "$current_public_access" == "Enabled" ]]; then
        secret_count=$(az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "length(@)" -o tsv 2>/dev/null || echo "0")
        if [[ "$secret_count" -ge 3 ]]; then
            validation_results+=("✅ Demo secrets created successfully ($secret_count secrets)")
            secret_check_result="success"
        else
            validation_results+=("⚠️ Limited demo secrets found: $secret_count")
            secret_check_result="limited"
        fi
    else
        # Cannot validate secrets when public access is disabled (expected for security)
        validation_results+=("ℹ️ Demo secrets validation skipped (public access disabled - normal for private endpoint setup)")
        secret_check_result="skipped"
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
        print_info ""
        print_info "Recovery options:"
        print_info "1. Run cleanup script to remove any partial deployment:"
        print_info "   ./scripts/demo/cleanup-keyvault-private-endpoints.sh --auto-approve"
        print_info "2. If Key Vault soft-delete conflict occurred, run:"
        print_info "   ./scripts/demo/cleanup-keyvault-private-endpoints.sh --purge-soft-deleted --auto-approve"
        print_info "3. Then retry this setup script"
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
    local secrets_only=false
    local tfvars_file="demo-prep"  # Default to demo-prep for backward compatibility
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --secrets-only)
                secrets_only=true
                shift
                ;;
            --tfvars-file)
                if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
                    tfvars_file="$2"
                    shift 2
                else
                    print_error "--tfvars-file requires a value (e.g., demo-prep, regional-examples)"
                    return 1
                fi
                ;;
            --help|-h)
                echo "Usage: $0 [--auto-approve] [--secrets-only] [--tfvars-file <name>]"
                echo ""
                echo "Deploy Azure Key Vault with dual private endpoints for PPCC25 demo"
                echo ""
                echo "Options:"
                echo "  --auto-approve       Skip confirmation prompts"
                echo "  --secrets-only       Only create demo secrets (for completing partial deployment)"
                echo "  --tfvars-file <name> tfvars file name to use (default: demo-prep)"
                echo "                       Examples: demo-prep, regional-examples, production"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --tfvars-file demo-prep"
                echo "  $0 --tfvars-file regional-examples --auto-approve"
                echo "  $0 --secrets-only  # Use default demo-prep configuration"
                exit 0
                ;;
            *)
                print_error "Unknown option: ${1:-}"
                print_info "Use --help for usage information"
                return 1
                ;;
        esac
    done
    
    print_step "Starting PPCC25 Key Vault private endpoint deployment..."
    print_info "Using tfvars configuration: $tfvars_file"
    
    # WHY: Initialize dynamic configuration from tfvars file
    # CONTEXT: Must happen before any validation that uses resource names
    # IMPACT: Sets up all global variables for script execution
    if ! initialize_dynamic_config "$tfvars_file"; then
        print_error "Failed to initialize dynamic configuration"
        print_info "Ensure both tfvars files exist:"
        print_info "  - configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
        print_info "  - configurations/ptn-azure-vnet-extension/tfvars/${tfvars_file}.tfvars"
        return 1
    fi
    
    # If secrets-only mode, skip infrastructure deployment
    if [[ "$secrets_only" == true ]]; then
        print_info "Secrets-only mode: Skipping infrastructure validation and deployment"
        print_info "Proceeding directly to demo secrets creation..."
        
        # Just create the secrets for existing infrastructure
        create_demo_secrets
        validate_deployment
        display_demo_information
        
        print_success "🎯 Demo secrets created successfully for existing infrastructure!"
        return 0
    fi
    
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
Estimated Cost: ~\$10-15/month for Key Vault + Private Endpoints

EOF
        
        read -p "Continue with deployment? (y/N): " -n 1 -r
        echo
        if [[ ! ${REPLY:-} =~ ^[Yy]$ ]]; then
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