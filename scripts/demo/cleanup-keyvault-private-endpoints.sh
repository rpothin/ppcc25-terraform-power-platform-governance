#!/bin/bash
# ==============================================================================
# Script Name: cleanup-keyvault-private-endpoints.sh
# Purpose: Clean up Key Vault single-endpoint resources after PPCC25 demo
# Usage: ./cleanup-keyvault-private-endpoints.sh [--auto-approve] [--keep-keyvault] [--tfvars-file <name>]
# Dependencies: Azure CLI, existing demo resources from setup script
# Author: PPCC25 Demo Platform Team
# ==============================================================================

set -euo pipefail

# WHY: Dynamic configuration constants calculated from tfvars file input
# CONTEXT: Enables script reuse across different workspace configurations
# IMPACT: Single script works with multiple demo environments (demo-prep, regional-examples, etc.)

# Global variables for dynamic resource naming (initialized from tfvars)
RESOURCE_GROUP_NAME=""
KEY_VAULT_NAME=""
PE_PRIMARY_NAME=""
LEGACY_PE_FAILOVER_NAME=""
WORKSPACE_NAME=""
TFVARS_FILE_NAME=""
KEY_VAULT_RESOURCE_ID=""

# Static constants
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
# NOTE: These functions are duplicated from setup script for independence

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
    LEGACY_PE_FAILOVER_NAME="pe-kv-${project}-${workspace_short}-${env_suffix}-${failover_abbrev}"
    
    # Store for reference
    WORKSPACE_NAME="$workspace_name"
    TFVARS_FILE_NAME="$tfvars_file"
    
    print_info "Generated resource names:"
    print_info "  Resource Group: $RESOURCE_GROUP_NAME"
    print_info "  Key Vault: $KEY_VAULT_NAME"
    print_info "  PE Primary: $PE_PRIMARY_NAME"
    print_info "  Legacy PE (deprecated): $LEGACY_PE_FAILOVER_NAME"
    
    return 0
}

# WHY: Initialize dynamic configuration from tfvars file
# CONTEXT: Single function to set up all dynamic variables
# IMPACT: Clean separation between static and dynamic configuration
initialize_dynamic_config() {
    local tfvars_file="$1"
    
    print_step "Initializing dynamic configuration from tfvars file: $tfvars_file"
    
    # Validate tfvars file exists
    local env_group_tfvars_path="${SCRIPT_DIR}/../../configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
    if [[ ! -f "$env_group_tfvars_path" ]]; then
        print_error "tfvars file not found: $env_group_tfvars_path"
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
# UTILITY FUNCTIONS
# ============================================================================

# WHY: Soft-deleted Key Vault cleanup prevents deployment conflicts
# CONTEXT: Azure Key Vault soft-delete can block new deployments with same name
# IMPACT: Enables clean redeployment by purging any existing soft-deleted Key Vault
cleanup_soft_deleted_keyvault() {
    print_step "Checking for soft-deleted Key Vault that might block redeployment..."
    
    # Check if Key Vault exists in soft-deleted state
    if az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME']" | grep -q "$KEY_VAULT_NAME"; then
        print_warning "Found soft-deleted Key Vault: $KEY_VAULT_NAME"
        print_info "This will prevent redeployment with the same name"
        
        # Get soft-deleted Key Vault location for purge operation
        local deleted_location
        deleted_location=$(az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME'].properties.location" -o tsv 2>/dev/null || echo "canadacentral")
        
        print_info "Purging soft-deleted Key Vault to enable name reuse..."
        az keyvault purge --name "$KEY_VAULT_NAME" --location "$deleted_location" 2>/dev/null || {
            # Fallback: try without location (for older Azure CLI versions)
            az keyvault purge --name "$KEY_VAULT_NAME" 2>/dev/null || {
                print_warning "Unable to purge soft-deleted Key Vault automatically"
                print_info "Manual purge may be required: az keyvault purge --name $KEY_VAULT_NAME"
                return 1
            }
        }
        
        print_success "Soft-deleted Key Vault purged successfully"
        
        # Wait for purge to complete
        print_info "Waiting 15 seconds for purge operation to complete..."
        sleep 15
    else
        print_info "No soft-deleted Key Vault found - cleanup can proceed normally"
    fi
    
    return 0
}

# WHY: Safety validation prevents cleanup of wrong resources
# CONTEXT: Validates Azure context before destructive operations
# IMPACT: Prevents accidental deletion of production resources
validate_cleanup_context() {
    print_step "Validating cleanup context and permissions..."
    
    # Check Azure CLI authentication
    if ! az account show &> /dev/null; then
        print_error "Not authenticated to Azure"
        print_info "Run: az login --use-device-code"
        return 1
    fi
    
    # Validate resource group exists
    if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Resource group '$RESOURCE_GROUP_NAME' not found"
        print_info "Resources may already be deleted"
        return 0
    fi
    
    # Check for demo resources to confirm this is correct environment
    local demo_resources=0
    
    if az keyvault show --name "$KEY_VAULT_NAME" &> /dev/null; then
        ((demo_resources++))
    fi
    
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        ((demo_resources++))
    fi

    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        ((demo_resources++))
        print_warning "Detected legacy failover private endpoint: $LEGACY_PE_FAILOVER_NAME"
        print_info "This endpoint is deprecated in the single-endpoint architecture and will be removed"
    fi
    
    if [[ $demo_resources -eq 0 ]]; then
        print_warning "No demo resources found - cleanup may not be necessary"
    else
        print_info "Found $demo_resources demo resources to clean up"
    fi
    
    print_success "Cleanup context validated"
    return 0
}

# WHY: Private endpoint cleanup removes network connectivity components
# CONTEXT: Private endpoints must be deleted before Key Vault for clean removal
# IMPACT: Ensures proper cleanup order to avoid dependency conflicts
cleanup_private_endpoints() {
    print_step "Cleaning up private endpoints..."
    
    local endpoints_cleaned=0
    
    # Remove primary region private endpoint
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Removing primary private endpoint: $PE_PRIMARY_NAME"
        az network private-endpoint delete \
            --name "$PE_PRIMARY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --yes
        ((endpoints_cleaned++))
    else
        print_info "Primary private endpoint not found (may already be deleted)"
    fi
    
    # Remove legacy failover private endpoint if it still exists
    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Removing legacy failover private endpoint: $LEGACY_PE_FAILOVER_NAME"
        az network private-endpoint delete \
            --name "$LEGACY_PE_FAILOVER_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --yes
        ((endpoints_cleaned++))
    else
        print_info "Legacy failover private endpoint not found (already removed or never created)"
    fi
    
    if [[ $endpoints_cleaned -gt 0 ]]; then
        print_success "Cleaned up $endpoints_cleaned private endpoints"
    else
        print_info "No private endpoints required cleanup"
    fi
}

# WHY: DNS cleanup removes stale private endpoint A records
# CONTEXT: Private endpoint deletion may leave DNS records that should be cleaned
# IMPACT: Prevents DNS resolution to non-existent private endpoints
cleanup_dns_records() {
    print_step "Cleaning up private DNS records..."
    
    # Check if DNS records exist for Key Vault
    if az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$KEY_VAULT_NAME" &> /dev/null; then
        
        print_info "Removing DNS A records for Key Vault"
        az network private-dns record-set a delete \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "$KEY_VAULT_NAME" \
            --yes
        
        print_success "DNS records cleaned up"
    else
        print_info "No DNS records found for cleanup"
    fi
}

# WHY: Key Vault cleanup with soft-delete handling
# CONTEXT: Azure Key Vault soft-delete requires special handling for complete removal
# IMPACT: Ensures Key Vault name can be reused for future demos
cleanup_key_vault() {
    local keep_vault="$1"
    
    if [[ "$keep_vault" == true ]]; then
        print_info "Keeping Key Vault as requested (--keep-keyvault)"
        return 0
    fi
    
    print_step "Cleaning up Key Vault..."
    
    # Check if Key Vault exists
    if ! az keyvault show --name "$KEY_VAULT_NAME" &> /dev/null; then
        print_info "Key Vault not found (may already be deleted)"
        
        # Check if it's in soft-deleted state
        if az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME']" | grep -q "$KEY_VAULT_NAME"; then
            print_warning "Key Vault found in soft-deleted state"
            print_info "Purging soft-deleted Key Vault to enable name reuse..."
            az keyvault purge --name "$KEY_VAULT_NAME"
            print_success "Soft-deleted Key Vault purged"
        fi
        return 0
    fi
    
    print_info "Deleting Key Vault: $KEY_VAULT_NAME"
    az keyvault delete --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME"
    
    # WHY: Purge soft-deleted Key Vault to enable name reuse
    # CONTEXT: Azure Key Vault soft-delete prevents immediate name reuse
    # IMPACT: Enables running demo setup again with same Key Vault name
    print_info "Waiting for soft-delete state..."
    sleep 10
    
    if az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME']" | grep -q "$KEY_VAULT_NAME"; then
        print_info "Purging soft-deleted Key Vault to enable name reuse..."
        az keyvault purge --name "$KEY_VAULT_NAME"
        print_success "Key Vault completely removed"
    else
        print_warning "Key Vault not found in soft-deleted state"
        print_info "Manual purge may be required if name reuse is needed"
    fi
}

# WHY: Role assignment cleanup prevents permission accumulation
# CONTEXT: Demo script may have assigned RBAC roles that should be cleaned up
# IMPACT: Maintains clean RBAC state and follows least privilege principles
cleanup_role_assignments() {
    print_step "Cleaning up demo-related role assignments..."
    
    local current_user_id
    current_user_id=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$current_user_id" && -n "${KEY_VAULT_RESOURCE_ID:-}" ]]; then
        print_info "Removing Key Vault Secrets Officer role assignment..."
        az role assignment delete \
            --role "Key Vault Secrets Officer" \
            --assignee "$current_user_id" \
            --scope "$KEY_VAULT_RESOURCE_ID" \
            --output none 2>/dev/null || print_info "Role assignment not found or already removed"
    else
        print_info "Skipping role assignment cleanup (insufficient context)"
    fi
}

# WHY: Comprehensive cleanup validation ensures complete resource removal
# CONTEXT: Verifies all demo resources are properly cleaned up
# IMPACT: Provides confirmation that demo environment is ready for redeployment
validate_cleanup() {
    print_step "Validating cleanup completion..."
    
    local remaining_resources=()
    
    # Check Key Vault
    if az keyvault show --name "$KEY_VAULT_NAME" &> /dev/null; then
        remaining_resources+=("Key Vault: $KEY_VAULT_NAME")
    fi
    
    # Check private endpoints
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        remaining_resources+=("Primary Private Endpoint: $PE_PRIMARY_NAME")
    fi
    
    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        remaining_resources+=("Legacy Private Endpoint: $LEGACY_PE_FAILOVER_NAME")
    fi
    
    # Check DNS records
    if az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$KEY_VAULT_NAME" &> /dev/null; then
        remaining_resources+=("DNS A Records for Key Vault")
    fi
    
    if [[ ${#remaining_resources[@]} -eq 0 ]]; then
        print_success "Cleanup validation completed - all demo resources removed"
    else
        print_warning "Some demo resources may still exist:"
        printf "  - %s\n" "${remaining_resources[@]}"
        print_info "Manual cleanup may be required for remaining resources"
    fi
}

# WHY: Main cleanup orchestration with safety checks and user confirmation
# CONTEXT: Provides controlled cleanup process with clear progress indication
# IMPACT: Ensures safe and complete cleanup of demo resources
main() {
    local auto_approve=false
    local keep_keyvault=false
    local purge_soft_deleted=false
    local tfvars_file="demo-prep"  # Default to demo-prep for backward compatibility
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --keep-keyvault)
                keep_keyvault=true
                shift
                ;;
            --purge-soft-deleted)
                purge_soft_deleted=true
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
                echo "Usage: $0 [--auto-approve] [--keep-keyvault] [--purge-soft-deleted] [--tfvars-file <name>]"
                echo ""
                echo "Clean up Key Vault single-endpoint resources after PPCC25 demo"
                echo ""
                echo "Options:"
                echo "  --auto-approve       Skip confirmation prompts"
                echo "  --keep-keyvault      Keep Key Vault, only remove private endpoints"
                echo "  --purge-soft-deleted Purge any soft-deleted Key Vault first"
                echo "  --tfvars-file <name> tfvars file name to use (default: demo-prep)"
                echo "                       Examples: demo-prep, regional-examples, production"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --tfvars-file demo-prep --auto-approve"
                echo "  $0 --tfvars-file regional-examples --purge-soft-deleted"
                echo "  $0 --keep-keyvault  # Use default demo-prep configuration"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                return 1
                ;;
        esac
    done
    
    print_step "Starting PPCC25 demo resource cleanup..."
    print_info "Using tfvars configuration: $tfvars_file"
    
    # WHY: Initialize dynamic configuration from tfvars file
    # CONTEXT: Must happen before any validation that uses resource names
    # IMPACT: Sets up all global variables for script execution
    if ! initialize_dynamic_config "$tfvars_file"; then
        print_error "Failed to initialize dynamic configuration"
        print_info "Ensure tfvars file exists:"
        print_info "  - configurations/ptn-environment-group/tfvars/${tfvars_file}.tfvars"
        return 1
    fi
    
    # Handle soft-deleted Key Vault cleanup first if requested
    if [[ "$purge_soft_deleted" == true ]]; then
        if ! cleanup_soft_deleted_keyvault; then
            print_warning "Soft-deleted Key Vault cleanup had issues, but continuing..."
        fi
    fi
    
    # Validate cleanup context
    if ! validate_cleanup_context; then
        return 1
    fi
    
    # Get Key Vault resource ID before deletion for role cleanup
    if az keyvault show --name "$KEY_VAULT_NAME" &> /dev/null; then
        KEY_VAULT_RESOURCE_ID=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query id -o tsv)
    fi
    
    # Determine if legacy endpoint exists for preview messaging
    local legacy_endpoint_exists=false
    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        legacy_endpoint_exists=true
    fi

    # User confirmation for destructive operation
    if [[ "$auto_approve" != true ]]; then
        cat << EOF

⚠️  CLEANUP CONFIRMATION
========================

This script will remove:
  🗑️ Private Endpoint: $PE_PRIMARY_NAME
EOF

        if [[ "$legacy_endpoint_exists" == true ]]; then
            echo "  🗑️ Legacy Private Endpoint: $LEGACY_PE_FAILOVER_NAME"
        fi

        cat << EOF
  🗑️ DNS A records for Key Vault
EOF
        
        if [[ "$purge_soft_deleted" == true ]]; then
            echo "  🔥 Soft-deleted Key Vault: $KEY_VAULT_NAME (if exists)"
        fi
        
        if [[ "$keep_keyvault" != true ]]; then
            echo "  🗑️ Key Vault: $KEY_VAULT_NAME (including all secrets)"
        else
            echo "  ✅ Key Vault: $KEY_VAULT_NAME (KEEPING as requested)"
        fi
        
        cat << EOF

Target Resource Group: $RESOURCE_GROUP_NAME

⚠️  WARNING: This operation cannot be undone!

EOF
        
        read -p "Continue with cleanup? (y/N): " -n 1 -r
        echo
        if [[ ! ${REPLY:-} =~ ^[Yy]$ ]]; then
            print_info "Cleanup cancelled by user"
            return 0
        fi
    fi
    
    # Execute cleanup steps in proper order
    cleanup_private_endpoints
    cleanup_dns_records
    cleanup_key_vault "$keep_keyvault"
    cleanup_role_assignments
    
    # Validate cleanup completion
    validate_cleanup
    
    print_success "🧹 PPCC25 demo resource cleanup completed!"

    if [[ "$keep_keyvault" == true ]]; then
        print_info "Key Vault preserved - private endpoint connectivity disabled"
        print_info "Re-run setup script to restore single-endpoint architecture"
    elif [[ "$purge_soft_deleted" == true ]]; then
        print_info "All demo resources removed and soft-deleted Key Vault purged"
        print_info "Ready for fresh deployment without naming conflicts"
    else
        print_info "All demo resources removed - ready for fresh deployment"
        print_info "Note: Use --purge-soft-deleted flag if setup fails due to soft-delete conflicts"
    fi
    
    return 0
}

# Execute main function with all arguments
main "$@"