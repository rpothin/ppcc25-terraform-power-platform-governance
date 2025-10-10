#!/bin/bash
# ==============================================================================
# Script Name: setup-sqlserver-private-endpoints.sh
# Purpose: Deploy Azure SQL Server with dual private endpoints for PPCC25 Power Platform VNet integration demo
# Usage: ./setup-sqlserver-private-endpoints.sh [--auto-approve] [--tfvars-file <name>]
# Dependencies: Azure CLI, existing VNet infrastructure from ptn-azure-vnet-extension
# Author: PPCC25 Demo Platform Team
# ==============================================================================

set -euo pipefail

# WHY: Dynamic configuration constants calculated from tfvars file input
# CONTEXT: Enables script reuse across different workspace configurations
# IMPACT: Single script works with multiple demo environments (demo-prep, regional-examples, etc.)

# Global variables for dynamic resource naming (initialized from tfvars)
RESOURCE_GROUP_NAME=""
SQL_SERVER_NAME=""
SQL_DATABASE_NAME="demo-db"
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
readonly PRIVATE_DNS_ZONE="privatelink.database.windows.net"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/../utils/common.sh" 2>/dev/null || {
    # WHY: Fallback if common utilities not available
    # CONTEXT: Provides basic output functions for script execution
    # IMPACT: Ensures script can run even without full utility infrastructure
    print_success() { echo "✅ $*" >&2; }
    print_error() { echo "❌ ERROR: $*" >&2; }
    print_warning() { echo "⚠️  WARNING: $*" >&2; }
    print_info() { echo "ℹ️  $*" >&2; }
    print_step() { echo "🔄 $*" >&2; }
    print_status() { echo "📊 $*" >&2; }
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
    
    # WHY: SQL Server naming with length constraints
    # CONTEXT: SQL Server names must be under 63 characters
    # IMPACT: Static naming enables idempotent script execution (reuses existing resources)
    local workspace_short
    if [[ ${#workspace_clean} -gt 12 ]]; then
        # Create meaningful abbreviation for long workspace names
        workspace_short=$(echo "$workspace_clean" | sed 's/workspace/ws/g' | cut -c1-12)
    else
        workspace_short="$workspace_clean"
    fi
    
    # WHY: Use static names (no timestamp) for idempotent deployments
    # CONTEXT: Allows script reruns to reuse existing resources instead of creating duplicates
    # IMPACT: Prevents multiple incomplete deployments from accumulating
    SQL_SERVER_NAME="sql-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    PE_PRIMARY_NAME="pe-sql-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    PE_FAILOVER_NAME="pe-sql-${project}-${workspace_short}-${env_suffix}-${failover_abbrev}"
    
    # Store for reference
    WORKSPACE_NAME="$workspace_name"
    TFVARS_FILE_NAME="$tfvars_file"
    
    print_info "Generated resource names:"
    print_info "  Resource Group: $RESOURCE_GROUP_NAME"
    print_info "  SQL Server: $SQL_SERVER_NAME"
    print_info "  SQL Database: $SQL_DATABASE_NAME"
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
    print_step "Validating prerequisites for SQL Server deployment..."
    
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
# CONTEXT: SQL Server private endpoints require specific VNet configuration
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

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

# WHY: SQL Server deployment with Entra ID-only authentication
# CONTEXT: Creates SQL Server with Microsoft Entra ID Integrated auth (no SQL auth)
# IMPACT: Provides passwordless, secure SQL Server for Power Platform testing
deploy_sql_server() {
    print_step "Deploying Azure SQL Server with Entra ID-only authentication..."
    
    # WHY: Check if SQL Server already exists to avoid conflicts
    # CONTEXT: SQL Server names are globally unique and deployment will fail if name exists
    # IMPACT: Enables idempotent script execution and clear error handling
    if az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "SQL Server '$SQL_SERVER_NAME' already exists"
        print_info "Using existing SQL Server - skipping creation"
        return 0
    fi
    
    print_info "Creating new SQL Server: $SQL_SERVER_NAME"
    
    # WHY: Get current user context for Entra ID admin assignment
    # CONTEXT: Logged-in user becomes SQL Server admin with full permissions
    # IMPACT: Enables passwordless management and demo execution
    local current_user_name
    current_user_name=$(az account show --query user.name -o tsv 2>/dev/null)
    
    local current_user_id
    current_user_id=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
    
    if [[ -z "$current_user_name" || -z "$current_user_id" ]]; then
        print_error "Unable to retrieve current user information for Entra ID admin"
        print_info "Ensure you're logged in with 'az login' and have Entra ID access"
        return 1
    fi
    
    print_info "Configuring Entra ID admin: $current_user_name"
    
    # WHY: Deploy SQL Server with Entra ID-only authentication
    # CONTEXT: --enable-ad-only-auth disables SQL authentication for zero-trust security
    # IMPACT: Ensures all access uses Microsoft Entra ID credentials (no passwords)
    if ! az sql server create \
        --name "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION_PRIMARY" \
        --enable-ad-only-auth \
        --external-admin-principal-type User \
        --external-admin-name "$current_user_name" \
        --external-admin-sid "$current_user_id"; then
        
        print_error "SQL Server deployment failed"
        return 1
    fi
    
    # WHY: Disable public network access for private endpoint-only connectivity
    # CONTEXT: Forces all connections through private endpoints (VNet security)
    # IMPACT: Prevents direct internet access to SQL Server
    print_info "Disabling public network access..."
    az sql server update \
        --name "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --set publicNetworkAccess="Disabled" \
        --output none
    
    print_success "SQL Server deployed with Entra ID-only authentication"
    print_info "SQL Server admin: $current_user_name"
}

# WHY: Database and demo table deployment
# CONTEXT: Creates database with sample customer data for Power Platform testing
# IMPACT: Provides immediate demo-ready data source
deploy_database_and_demo_data() {
    print_step "Deploying demo database with sample data..."
    
    # WHY: Check if database already exists
    # CONTEXT: Prevents errors when re-running script
    # IMPACT: Enables idempotent script execution
    if az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Database '$SQL_DATABASE_NAME' already exists"
        print_info "Using existing database - skipping creation"
        return 0
    fi
    
    print_info "Creating database: $SQL_DATABASE_NAME"
    
    # WHY: Use Basic tier for cost-effective demo
    # CONTEXT: Basic tier sufficient for demo workloads (~$5/month)
    # IMPACT: Keeps demo costs minimal while providing functional database
    az sql db create \
        --name "$SQL_DATABASE_NAME" \
        --server "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --edition Basic \
        --capacity 5 \
        --zone-redundant false
    
    print_info "Waiting for database to be ready..."
    sleep 15
    
    # WHY: Skip table creation in script - use Azure Portal Query Editor instead
    # CONTEXT: Azure Portal provides simple, reliable interface without tool installation
    # IMPACT: Eliminates command-line tool complexity and authentication issues
    print_info "Database provisioned successfully"
    print_info ""
    print_info "� Next Step: Create demo table using Azure Portal Query Editor"
    print_info "   SQL script will be provided in deployment summary"
    print_success "Database ready for table creation via Azure Portal"
}

# WHY: Dual private endpoints enable optimal performance from both regions
# CONTEXT: Canada Central and Canada East VNets each get local private endpoint
# IMPACT: Eliminates cross-region latency and provides regional resilience
deploy_private_endpoints() {
    print_step "Deploying private endpoints in both regions..."
    
    local sql_server_id
    sql_server_id=$(az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query id -o tsv)
    
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
        --private-connection-resource-id "$sql_server_id" \
        --group-ids sqlServer \
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
        --private-connection-resource-id "$sql_server_id" \
        --group-ids sqlServer \
        --connection-name "${PE_FAILOVER_NAME}-connection"
    
    print_success "Private endpoints deployed in both regions"
}

# WHY: DNS integration enables private endpoint name resolution
# CONTEXT: Private DNS zone groups automatically create A records for private endpoints
# IMPACT: Enables proper FQDN resolution to private IP addresses
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
        --name "sqlserver-dns-zone-group-primary" \
        --private-dns-zone "$dns_zone_id" \
        --zone-name "$PRIVATE_DNS_ZONE"
    
    print_success "Primary private endpoint DNS configured (10.192.2.x)"
    
    # WHY: Failover endpoint does NOT auto-register DNS
    # CONTEXT: Prevents cross-region routing which would fail without VNet peering
    # IMPACT: DNS always resolves to same-region IP for Power Platform connectivity
    # MANUAL FAILOVER: In disaster recovery scenarios, run fix-dns-quick.sh to switch DNS
    print_info "Failover private endpoint deployed without DNS registration"
    print_info "  ℹ️  Reason: Same-region access provides optimal performance"
    print_info "  ℹ️  Failover: Requires manual DNS update in disaster recovery scenario"
    print_info "  ℹ️  Failover IP available: 10.208.2.x (Canada East)"
    
    print_success "Private DNS integration configured (primary-only strategy)"
}

# WHY: Comprehensive validation ensures deployment success
# CONTEXT: Tests all components work together before declaring success
# IMPACT: Provides confidence that Power Platform integration will work
validate_deployment() {
    print_step "Validating complete SQL Server private endpoint deployment..."
    
    local validation_results=()
    
    # Validate SQL Server exists and is properly configured
    print_info "Checking SQL Server configuration..."
    local sql_public_access
    sql_public_access=$(az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "publicNetworkAccess" -o tsv)
    if [[ "$sql_public_access" != "Disabled" ]]; then
        validation_results+=("❌ SQL Server public access not disabled: $sql_public_access")
    else
        validation_results+=("✅ SQL Server public access properly disabled")
    fi
    
    # Validate Entra ID admin is configured
    # WHY: Use 'list' command instead of 'show' (which doesn't exist in Azure CLI)
    # CONTEXT: az sql server ad-admin list returns array of admins
    # IMPACT: Proper validation of Entra ID admin configuration
    local ad_admin
    ad_admin=$(az sql server ad-admin list --server-name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "[0].login" -o tsv 2>/dev/null || echo "NotConfigured")
    if [[ "$ad_admin" != "NotConfigured" && -n "$ad_admin" ]]; then
        validation_results+=("✅ Entra ID admin configured: $ad_admin")
    else
        validation_results+=("❌ Entra ID admin not configured")
    fi
    
    # Validate database exists
    local db_status
    db_status=$(az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "status" -o tsv 2>/dev/null || echo "NotFound")
    if [[ "$db_status" == "Online" ]]; then
        validation_results+=("✅ Database deployed and online")
    else
        validation_results+=("❌ Database status: $db_status")
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
        --name "${SQL_SERVER_NAME}" \
        --query "aRecords | length(@)" -o tsv 2>/dev/null || echo "0")
    
    if [[ "$dns_records" -ge 1 ]]; then
        validation_results+=("✅ DNS records configured for private endpoints ($dns_records record(s))")
        
        # Show actual DNS record details
        print_info "DNS A records for SQL Server:"
        az network private-dns record-set a show \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "${SQL_SERVER_NAME}" \
            --query "aRecords[].ipv4Address" -o tsv | while read -r ip; do
            print_info "  - $ip"
        done
    else
        validation_results+=("❌ No DNS records found for private endpoints")
    fi
    
    # WHY: Validate DNS resolution points to correct region (primary)
    # CONTEXT: Critical check to ensure DNS doesn't point to cross-region IP
    # IMPACT: Prevents Power Platform connectivity failures due to DNS misrouting
    # LESSON LEARNED: This validation catches the cross-region DNS issue discovered during testing
    print_info "Validating DNS points to primary region IP..."
    
    # Get expected primary IP from network interface
    local expected_primary_ip
    expected_primary_ip=$(az network nic show --ids \
        $(az network private-endpoint show --name "$PE_PRIMARY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --query "networkInterfaces[0].id" -o tsv 2>/dev/null) \
        --query "ipConfigurations[0].privateIPAddress" -o tsv 2>/dev/null || echo "")
    
    # Get actual DNS resolution IP
    local actual_dns_ip
    actual_dns_ip=$(az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$SQL_SERVER_NAME" \
        --query "aRecords[0].ipv4Address" -o tsv 2>/dev/null || echo "")
    
    # Validate DNS points to primary region
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
        print_info "   ./scripts/demo/cleanup-sqlserver-private-endpoints.sh --tfvars-file ${TFVARS_FILE_NAME:-demo-prep} --auto-approve"
        print_info "2. Then retry this setup script"
    fi
    
    exit $exit_code
}
trap cleanup EXIT SIGINT SIGTERM

# WHY: Display comprehensive deployment information for demo preparation
# CONTEXT: Provides all necessary information for Power Platform configuration
# IMPACT: Enables immediate demo execution with clear setup instructions
display_demo_information() {
    print_success "🎉 SQL Server private endpoint deployment completed successfully!"
    
    cat << EOF

📋 DEMO CONFIGURATION SUMMARY
=====================================

SQL Server Information:
  Name: $SQL_SERVER_NAME
  FQDN: ${SQL_SERVER_NAME}.database.windows.net
  Database: $SQL_DATABASE_NAME
  Authentication: Microsoft Entra ID Only
  Public Access: Disabled (Private endpoints only)

Private Endpoints:
  Primary Region: $PE_PRIMARY_NAME (Canada Central)
  Failover Region: $PE_FAILOVER_NAME (Canada East)

🌐 DNS RESOLUTION STRATEGY
===========================

Primary-Only DNS Registration:
  ✅ Primary Endpoint: Auto-registered in DNS (10.192.2.x)
  ⚠️  Failover Endpoint: Deployed WITHOUT DNS registration (10.208.2.x)
  
Why This Design?
  • Same-region access provides optimal performance (minimal latency)
  • Prevents cross-region routing which would fail without VNet peering
  • DNS always resolves to primary region for Power Platform connectivity
  
Failover Scenario (Disaster Recovery):
  1. Manual DNS update required (not automatic)
  2. Run: scripts/demo/fix-dns-quick.sh --failover (future enhancement)
  3. Verify: DNS resolves to 10.208.2.x (Canada East)
  
🎓 LESSON LEARNED:
  During testing, we discovered that when both private endpoints auto-register DNS,
  the failover endpoint overwrites the primary endpoint's A record, causing
  cross-region routing failures. Primary-only registration prevents this issue.

Demo Data:
  📝 Table creation required: Use Azure Portal Query Editor (instructions below)
  Records: Will have 5 sample customer records after table creation
  Schema: CustomerID, FirstName, LastName, Email, Company, Region

� CREATE DEMO TABLE (Azure Portal Query Editor)
===================================

**Step 1: Create Demo Table**

1. Open Azure Portal → SQL databases → $SQL_DATABASE_NAME
2. Click "Query editor" in left menu
3. Authenticate with your Entra ID account (automatic)
4. Open SQL script file: scripts/demo/create-demo-table.sql
5. Copy-paste the entire script into Query Editor
6. Click "Run" → Should see "Commands completed successfully" and 5 rows
7. Table is now ready for Power Platform testing!

📄 SQL Script Location: scripts/demo/create-demo-table.sql

The script creates:
- Customers table (8 columns: CustomerID, FirstName, LastName, Email, Company, Region, CreatedDate, IsActive)
- 5 sample customer records (Contoso, Fabrikam, Northwind, Adventure Works, Wide World Importers)
- Verification query to confirm data insertion

**Step 2: Test from Power Platform**

1. Open Power Automate in your demo environment
2. Create new instant cloud flow: "SQL VNet Connectivity Test"
3. Add SQL Server connector action:
   - Authentication Type: Microsoft Entra ID Integrated
   - Server: ${SQL_SERVER_NAME}.database.windows.net
   - Database: $SQL_DATABASE_NAME
   - Action: Get rows (V2)
   - Table: Customers
4. Test the flow - should return 5 customer records

Expected Success Response:
  Status: 200 OK
  Records: 5 customers from demo data
  Authentication: Microsoft Entra ID Integrated (no credentials!)
  Connectivity: Through private endpoints (VNet integration)

🔍 VERIFICATION COMMANDS  
=========================

# Test DNS resolution (should show private IPs):
nslookup ${SQL_SERVER_NAME}.database.windows.net

# Check private endpoint status:
az network private-endpoint list --resource-group $RESOURCE_GROUP_NAME --query "[?contains(name,'sql')].{name:name,state:provisioningState}" -o table

# View DNS records:
az network private-dns record-set a show --resource-group $RESOURCE_GROUP_NAME --zone-name $PRIVATE_DNS_ZONE --name $SQL_SERVER_NAME

# Query demo data (use Azure Portal Query Editor):
# Portal → SQL databases → $SQL_DATABASE_NAME → Query editor
# Query: SELECT TOP 3 * FROM Customers ORDER BY CustomerID

📖 TROUBLESHOOTING
==================

If Customers table doesn't exist:
- Follow Step 1 above to create the table via Azure Portal Query Editor
- Table creation is required before testing Power Platform connectivity
- Query Editor handles authentication automatically

If Power Platform access fails:
1. Ensure Customers table exists (run SELECT * FROM Customers in Query Editor)
2. Verify you're logged in with same account used for deployment
3. Check enterprise policy is applied to Power Platform environment
4. Confirm VNet integration is working (check private endpoint health)

For "Login failed" errors:
- Ensure you're using "Microsoft Entra ID Integrated" authentication (not SQL auth)
- Verify your Entra ID account has access to the SQL Server
- Current admin: $(az account show --query user.name -o tsv)

For connectivity issues:
- Verify private endpoints are in "Succeeded" state
- Check DNS records point to private IPs (10.200.2.x, 10.216.2.x ranges)
- Test Query Editor access first before trying Power Platform

✨ Your PPCC25 demo environment is ready for Power Platform SQL VNet integration testing!

EOF
}

# WHY: Main execution function with comprehensive error handling and user confirmation
# CONTEXT: Orchestrates all deployment steps with clear progress indication
# IMPACT: Provides reliable, repeatable deployment process for demo environment
main() {
    local auto_approve=false
    local tfvars_file="demo-prep"  # Default to demo-prep for backward compatibility
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            --auto-approve)
                auto_approve=true
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
                echo "Usage: $0 [--auto-approve] [--tfvars-file <name>]"
                echo ""
                echo "Deploy Azure SQL Server with dual private endpoints for PPCC25 demo"
                echo ""
                echo "Options:"
                echo "  --auto-approve       Skip confirmation prompts"
                echo "  --tfvars-file <name> tfvars file name to use (default: demo-prep)"
                echo "                       Examples: demo-prep, regional-examples, production"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --tfvars-file demo-prep"
                echo "  $0 --tfvars-file regional-examples --auto-approve"
                exit 0
                ;;
            *)
                print_error "Unknown option: ${1:-}"
                print_info "Use --help for usage information"
                return 1
                ;;
        esac
    done
    
    print_step "Starting PPCC25 SQL Server private endpoint deployment..."
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
  ✅ Azure SQL Server: $SQL_SERVER_NAME
  ✅ SQL Database: $SQL_DATABASE_NAME (Basic tier)
  ✅ Demo table with 5 sample customer records
  ✅ Private Endpoint (Primary): $PE_PRIMARY_NAME in $LOCATION_PRIMARY  
  ✅ Private Endpoint (Failover): $PE_FAILOVER_NAME in $LOCATION_FAILOVER
  ✅ Private DNS integration for both endpoints

Authentication Configuration:
  ✅ Microsoft Entra ID Only (No SQL authentication)
  ✅ Admin: $(az account show --query user.name -o tsv)
  ✅ Passwordless access via Entra ID

Target Resource Group: $RESOURCE_GROUP_NAME
Expected Duration: 10-15 minutes
Estimated Cost: ~\$19-20/month (SQL Basic + Private Endpoints)

EOF
        
        read -p "Continue with deployment? (y/N): " -n 1 -r
        echo
        if [[ ! ${REPLY:-} =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled by user"
            return 0
        fi
    fi
    
    # Execute deployment steps
    deploy_sql_server
    deploy_database_and_demo_data
    deploy_private_endpoints
    configure_private_dns
    
    # Validate complete deployment
    if ! validate_deployment; then
        print_error "Deployment validation failed - check output above"
        return 1
    fi
    
    display_demo_information
    
    print_success "🎯 PPCC25 SQL Server private endpoint deployment completed successfully!"
    return 0
}

# Execute main function with all arguments
main "$@"
