#!/bin/bash
# ==============================================================================
# Script Name: setup-keyvault-private-endpoints.sh
# Purpose: Deploy Key Vault with single primary private endpoint and VNet peering for PPCC25 Power Platform connectivity demo
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
LEGACY_PE_FAILOVER_NAME=""
PEERING_PRIMARY_TO_FAILOVER_NAME=""
PEERING_FAILOVER_TO_PRIMARY_NAME=""
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
    
    # WHY: Key Vault naming with length constraints and consecutive hyphen avoidance
    # CONTEXT: Key Vault names have 24 character limit and cannot have consecutive hyphens
    # IMPACT: Remove all hyphens from workspace portion to avoid consecutive hyphen issues
    local workspace_short
    if [[ ${#workspace_clean} -gt 12 ]]; then
        # Create meaningful abbreviation for long workspace names, remove hyphens
        workspace_short=$(echo "$workspace_clean" | sed 's/workspace/ws/g' | sed 's/-//g' | cut -c1-12)
    else
        # Remove hyphens from workspace name to avoid consecutive hyphen issues
        workspace_short=$(echo "$workspace_clean" | sed 's/-//g')
    fi
    
    KEY_VAULT_NAME="kv${project}${workspace_short}${env_suffix}${location_abbrev}"
    PE_PRIMARY_NAME="pe-kv-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    LEGACY_PE_FAILOVER_NAME="pe-kv-${project}-${workspace_short}-${env_suffix}-${failover_abbrev}"
    PEERING_PRIMARY_TO_FAILOVER_NAME="peer-${VNET_PRIMARY}-to-failover"
    PEERING_FAILOVER_TO_PRIMARY_NAME="peer-${VNET_FAILOVER}-to-primary"
    
    # Store for reference
    WORKSPACE_NAME="$workspace_name"
    TFVARS_FILE_NAME="$tfvars_file"
    
    print_info "Generated resource names:"
    print_info "  Resource Group: $RESOURCE_GROUP_NAME"
    print_info "  Key Vault: $KEY_VAULT_NAME"
    print_info "  VNet Primary: $VNET_PRIMARY"
    print_info "  VNet Failover: $VNET_FAILOVER"
    print_info "  PE Primary: $PE_PRIMARY_NAME"
    print_info "  Peering (primary→failover): $PEERING_PRIMARY_TO_FAILOVER_NAME"
    print_info "  Peering (failover→primary): $PEERING_FAILOVER_TO_PRIMARY_NAME"
    print_info "  Legacy PE (deprecated): $LEGACY_PE_FAILOVER_NAME"
    
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

# WHY: Single primary private endpoint combined with VNet peering simplifies architecture
# CONTEXT: Canada Central endpoint serves both regions through Terraform-managed peering
# IMPACT: Reduces cost and management overhead while maintaining connectivity
deploy_private_endpoints() {
    print_step "Deploying private endpoint in primary region..."
    
    local key_vault_id
    key_vault_id=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query id -o tsv)

    # WHY: Deploy single private endpoint in primary VNet
    # CONTEXT: Canada Central endpoint serves both regions via peering
    # IMPACT: Simplifies management and maintains acceptable latency for Canada East (~30ms)
    print_info "Creating primary region private endpoint: $PE_PRIMARY_NAME"
    az network private-endpoint create \
        --name "$PE_PRIMARY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION_PRIMARY" \
        --vnet-name "$VNET_PRIMARY" \
        --subnet "$SUBNET_PRIVATE_ENDPOINT" \
        --private-connection-resource-id "$key_vault_id" \
        --group-id vault \
        --connection-name "${PE_PRIMARY_NAME}-connection"

    print_success "Primary private endpoint deployed (accessible from both regions via peering)"
}

# WHY: DNS integration enables private endpoint name resolution for single-endpoint architecture
# CONTEXT: Only the primary endpoint registers in private DNS; peering handles cross-region access
# IMPACT: Ensures consistent resolution without juggling multiple records
configure_private_dns() {
    print_step "Configuring private DNS integration (primary-only strategy)..."
    
    local dns_zone_id
    dns_zone_id=$(az network private-dns zone show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$PRIVATE_DNS_ZONE" \
        --query id -o tsv)
    
    # WHY: Only primary region private endpoint registers DNS automatically
    # CONTEXT: Prevents failover endpoint from overwriting primary DNS record
    # IMPACT: Ensures same-region connectivity for optimal performance
    # LESSON LEARNED: When multiple private endpoints for same resource exist in different regions,
    #                 only the primary (same-region) endpoint should auto-register DNS
    print_info "Configuring DNS for primary region private endpoint..."
    az network private-endpoint dns-zone-group create \
        --endpoint-name "$PE_PRIMARY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "keyvault-dns-zone-group-primary" \
        --private-dns-zone "$dns_zone_id" \
        --zone-name "$PRIVATE_DNS_ZONE"
    
    print_success "Primary private endpoint DNS configured (10.96.2.x)"
    print_info "✅ Canada East traffic resolves via VNet peering - no secondary DNS registration needed"
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
        --value "Environment: Dev | Regions: CAC/CAE | Connectivity: Single Endpoint + VNet Peering" \
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
    
    # Validate primary private endpoint exists and is connected
    print_info "Checking private endpoint status..."
    local pe_primary_state
    pe_primary_state=$(az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")

    if [[ "$pe_primary_state" == "Succeeded" ]]; then
        validation_results+=("✅ Primary private endpoint deployed successfully")
    else
        validation_results+=("❌ Primary private endpoint status: $pe_primary_state")
    fi

    # Warn if legacy failover endpoint still exists (deprecated architecture)
    local legacy_failover_state
    legacy_failover_state=$(az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    if [[ "$legacy_failover_state" != "NotFound" ]]; then
        validation_results+=("⚠️  Legacy failover private endpoint detected - remove to avoid extra cost and confusion")
    fi
    
    # Validate DNS records exist and point to correct region
    print_info "Checking DNS record configuration..."
    local dns_records
    dns_records=$(az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "${KEY_VAULT_NAME}" \
        --query "aRecords | length(@)" -o tsv 2>/dev/null || echo "0")
    
    if [[ "$dns_records" -ge 1 ]]; then
        # Get the actual DNS IP address
        local actual_dns_ip
        actual_dns_ip=$(az network private-dns record-set a show \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "${KEY_VAULT_NAME}" \
            --query "aRecords[0].ipv4Address" -o tsv 2>/dev/null)

        # Get expected IP from network interface (stronger validation)
        local expected_primary_ip=""
        local primary_nic_id
        primary_nic_id=$(az network private-endpoint show \
            --name "$PE_PRIMARY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --query "networkInterfaces[0].id" -o tsv 2>/dev/null || echo "")

        if [[ -n "$primary_nic_id" ]]; then
            expected_primary_ip=$(az network nic show \
                --ids "$primary_nic_id" \
                --query "ipConfigurations[0].privateIPAddress" -o tsv 2>/dev/null || echo "")
        fi

        print_info "DNS validation:"
        print_info "  Expected IP (primary): $expected_primary_ip"
        print_info "  Actual DNS IP: $actual_dns_ip"

        if [[ -n "$expected_primary_ip" && -n "$actual_dns_ip" ]]; then
            if [[ "$actual_dns_ip" == "$expected_primary_ip" ]]; then
                validation_results+=("✅ DNS correctly points to primary region: $actual_dns_ip (Canada Central)")
            else
                validation_results+=("❌ DNS MISMATCH: Points to $actual_dns_ip but expected $expected_primary_ip")
                validation_results+=("⚠️  This indicates cross-region DNS issue - Power Platform connectivity may fail")
                validation_results+=("💡 Fix: Run scripts/demo/fix-dns-quick.sh to correct DNS resolution")
            fi
        else
            validation_results+=("⚠️  Could not validate DNS IP (expected: $expected_primary_ip, actual: $actual_dns_ip)")
        fi
    else
        validation_results+=("❌ No DNS records found for private endpoints")
    fi

    # Validate VNet peering ensures cross-region connectivity
    print_info "Validating VNet peering for cross-region access..."
    local peering_state_primary_to_failover
    peering_state_primary_to_failover=$(az network vnet peering show \
        --name "$PEERING_PRIMARY_TO_FAILOVER_NAME" \
        --vnet-name "$VNET_PRIMARY" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "peeringState" -o tsv 2>/dev/null || echo "NotFound")

    if [[ "$peering_state_primary_to_failover" == "Connected" ]]; then
        validation_results+=("✅ VNet peering connected (primary → failover)")
    else
        validation_results+=("⚠️  VNet peering state (primary → failover): $peering_state_primary_to_failover")
    fi

    local peering_state_failover_to_primary
    peering_state_failover_to_primary=$(az network vnet peering show \
        --name "$PEERING_FAILOVER_TO_PRIMARY_NAME" \
        --vnet-name "$VNET_FAILOVER" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "peeringState" -o tsv 2>/dev/null || echo "NotFound")

    if [[ "$peering_state_failover_to_primary" == "Connected" ]]; then
        validation_results+=("✅ VNet peering connected (failover → primary)")
    else
        validation_results+=("⚠️  VNet peering state (failover → primary): $peering_state_failover_to_primary")
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
    Canada East Access: Routed through VNet peering (no regional endpoint)

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

🌐 DNS RESOLUTION STRATEGY
===========================

This deployment uses a PRIMARY-ONLY DNS registration strategy:
- Primary endpoint (Canada Central): Registers DNS record in private DNS zone
- Canada East traffic reaches Key Vault through Terraform-managed VNet peering

WHY THIS DESIGN?
1. Simplifies architecture: Single private endpoint to manage and monitor
2. Reduces cost: 50% fewer private endpoints across SQL + Key Vault
3. Matches enterprise hub-spoke topology: Peering provides east-west connectivity
4. Prevents DNS drift: No secondary endpoint to overwrite primary DNS record

🎓 LESSON LEARNED from SQL Server troubleshooting:
When multiple endpoints auto-register, later registrations can overwrite the primary record.
Result: DNS might point to non-peered regions causing timeouts.
Fix Applied: Keep a single endpoint + enforce VNet peering.

DISASTER RECOVERY SCENARIO:
If Canada Central region fails, update DNS to point to an alternate endpoint before promoting it:
    az network private-dns record-set a add-record \\
        --resource-group $RESOURCE_GROUP_NAME \\
        --zone-name $PRIVATE_DNS_ZONE \\
        --record-set-name $KEY_VAULT_NAME \\
        --ipv4-address [ALTERNATE-IP]

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
                echo "Deploy Azure Key Vault with single private endpoint + VNet peering for PPCC25 demo"
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
    ✅ Private DNS integration for primary endpoint
    ✅ Demo secrets for Power Platform testing

Target Resource Group: $RESOURCE_GROUP_NAME
Expected Duration: 5-10 minutes
Estimated Cost: ~\$7-10/month for Key Vault + single Private Endpoint

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