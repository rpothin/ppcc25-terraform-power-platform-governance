#!/bin/bash
# ==============================================================================
# Script Name: cleanup-sqlserver-private-endpoints.sh
# Purpose: Clean up SQL Server and single-endpoint resources after PPCC25 demo
# Usage: ./cleanup-sqlserver-private-endpoints.sh [--auto-approve] [--tfvars-file <name>] [--keep-sqlserver]
# Dependencies: Azure CLI, existing demo resources from setup script
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
PE_PRIMARY_NAME=""
LEGACY_PE_FAILOVER_NAME=""
WORKSPACE_NAME=""
TFVARS_FILE_NAME=""

# Static constants
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

# WHY: Generate resource names matching setup script pattern
# CONTEXT: Must match SQL Server names created by setup script
# IMPACT: Ensures cleanup targets correct resources
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
    
    # WHY: SQL Server naming with length constraints
    # CONTEXT: Must match workspace abbreviation logic from setup script
    local workspace_short
    if [[ ${#workspace_clean} -gt 12 ]]; then
        workspace_short=$(echo "$workspace_clean" | sed 's/workspace/ws/g' | cut -c1-12)
    else
        workspace_short="$workspace_clean"
    fi
    
    # WHY: SQL Server name pattern without timestamp suffix
    # CONTEXT: We'll discover actual SQL Server name by searching with prefix
    # IMPACT: Handles timestamp suffix added by setup script
    SQL_SERVER_NAME="sql-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    PE_PRIMARY_NAME="pe-sql-${project}-${workspace_short}-${env_suffix}-${location_abbrev}"
    LEGACY_PE_FAILOVER_NAME="pe-sql-${project}-${workspace_short}-${env_suffix}-${failover_abbrev}"
    
    # Store for reference
    WORKSPACE_NAME="$workspace_name"
    TFVARS_FILE_NAME="$tfvars_file"
    
    print_info "Generated resource name patterns:"
    print_info "  Resource Group: $RESOURCE_GROUP_NAME"
    print_info "  SQL Server Pattern: ${SQL_SERVER_NAME}-*"
    print_info "  SQL Database: $SQL_DATABASE_NAME"
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
# DISCOVERY FUNCTIONS
# ============================================================================

# WHY: Discover actual SQL Server name with timestamp suffix
# CONTEXT: Setup script adds timestamp suffix for global uniqueness
# IMPACT: Finds correct SQL Server to clean up
discover_sql_server() {
    print_step "Discovering SQL Server resources in resource group..."
    
    # WHY: Search for SQL Server with our naming pattern
    # CONTEXT: SQL Server names include timestamp suffix: sql-ppcc25-*-dev-cac-12345
    local discovered_servers
    discovered_servers=$(az sql server list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[?starts_with(name, '${SQL_SERVER_NAME}')].name" \
        -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$discovered_servers" ]]; then
        print_warning "No SQL Server found matching pattern: ${SQL_SERVER_NAME}-*"
        return 1
    fi
    
    # WHY: Handle multiple matches (shouldn't happen but be safe)
    # CONTEXT: Return most recently created server if multiple exist
    local server_count
    server_count=$(echo "$discovered_servers" | wc -l)
    
    if [[ $server_count -gt 1 ]]; then
        print_warning "Found $server_count SQL Servers matching pattern:"
        echo "$discovered_servers" | while read -r server; do
            print_info "  - $server"
        done
        # Take the first one (most likely the correct one)
        SQL_SERVER_NAME=$(echo "$discovered_servers" | head -n1)
        print_info "Using SQL Server: $SQL_SERVER_NAME"
    else
        SQL_SERVER_NAME="$discovered_servers"
        print_success "Discovered SQL Server: $SQL_SERVER_NAME"
    fi
    
    return 0
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# WHY: Safety validation prevents cleanup of wrong resources
# CONTEXT: Validates Azure context before destructive operations
# IMPACT: Prevents accidental deletion of production resources
validate_prerequisites() {
    print_step "Validating prerequisites for cleanup operation..."
    
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
    
    # Check if resource group exists
    if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Resource group '$RESOURCE_GROUP_NAME' not found"
        print_info "Demo resources may have already been cleaned up"
        return 1
    fi
    
    print_success "Prerequisites validated successfully"
    return 0
}

# WHY: Identify which demo resources actually exist
# CONTEXT: Not all resources may be present (partial deployment, etc.)
# IMPACT: Provides clear status before cleanup operations
identify_existing_resources() {
    print_step "Identifying existing demo resources..."
    
    local resources_found=()
    local resources_missing=()
    
    # Discover SQL Server (with timestamp suffix)
    if discover_sql_server; then
        resources_found+=("SQL Server: $SQL_SERVER_NAME")
        
        # Check for database within the SQL Server
        if az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
            resources_found+=("SQL Database: $SQL_DATABASE_NAME")
        else
            resources_missing+=("SQL Database: $SQL_DATABASE_NAME")
        fi
    else
        resources_missing+=("SQL Server: ${SQL_SERVER_NAME}-*")
        resources_missing+=("SQL Database: $SQL_DATABASE_NAME")
    fi
    
    # Check for private endpoints
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        resources_found+=("Private Endpoint (Primary): $PE_PRIMARY_NAME")
    else
        resources_missing+=("Private Endpoint (Primary): $PE_PRIMARY_NAME")
    fi

    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        resources_found+=("⚠️  Legacy failover private endpoint detected: $LEGACY_PE_FAILOVER_NAME (manual cleanup recommended)")
    fi
    
    # Check for DNS records (if SQL Server exists)
    if [[ ${#resources_found[@]} -gt 0 ]] && [[ -n "$SQL_SERVER_NAME" ]]; then
        if az network private-dns record-set a show \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --zone-name "$PRIVATE_DNS_ZONE" \
            --name "$SQL_SERVER_NAME" &> /dev/null; then
            resources_found+=("DNS A Records: $SQL_SERVER_NAME")
        else
            resources_missing+=("DNS A Records: $SQL_SERVER_NAME")
        fi
    fi
    
    # Display findings
    if [[ ${#resources_found[@]} -gt 0 ]]; then
        print_info "Resources found for cleanup:"
        printf "  ✅ %s\n" "${resources_found[@]}"
    fi
    
    if [[ ${#resources_missing[@]} -gt 0 ]]; then
        print_info "Resources not found (already cleaned or never created):"
        printf "  ⊘ %s\n" "${resources_missing[@]}"
    fi
    
    if [[ ${#resources_found[@]} -eq 0 ]]; then
        print_warning "No demo resources found to clean up"
        return 1
    fi
    
    return 0
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

# WHY: DNS record cleanup prevents stale records
# CONTEXT: Private endpoint DNS records must be removed before endpoints
# IMPACT: Ensures clean DNS state after cleanup
cleanup_dns_records() {
    print_step "Cleaning up private DNS records..."
    
    # WHY: Check if DNS records exist before attempting deletion
    # CONTEXT: DNS records may not exist if private endpoints were never created
    if ! az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$SQL_SERVER_NAME" &> /dev/null; then
        print_info "No DNS records found for $SQL_SERVER_NAME - skipping"
        return 0
    fi
    
    print_info "Removing DNS A records for $SQL_SERVER_NAME..."
    
    # WHY: Delete DNS record set for SQL Server
    # CONTEXT: A records were created by private endpoint DNS zone groups
    # IMPACT: Removes private endpoint DNS entries
    if az network private-dns record-set a delete \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$SQL_SERVER_NAME" \
        --yes &> /dev/null; then
        print_success "DNS records removed successfully"
    else
        print_warning "DNS records may have already been removed"
    fi
    
    return 0
}

# WHY: Private endpoint cleanup must happen before SQL Server deletion
# CONTEXT: Private endpoints reference SQL Server resource
# IMPACT: Prevents dependency conflicts during cleanup
cleanup_private_endpoints() {
    print_step "Cleaning up private endpoints..."
    
    local cleanup_results=()

    # WHY: Delete primary region private endpoint (only endpoint in new architecture)
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Deleting primary private endpoint: $PE_PRIMARY_NAME..."
        if az network private-endpoint delete \
            --name "$PE_PRIMARY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
            cleanup_results+=("✅ Primary private endpoint deleted")
        else
            cleanup_results+=("⚠️  Primary private endpoint deletion failed")
        fi
    else
        cleanup_results+=("ℹ️  Primary private endpoint not found")
    fi

    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        cleanup_results+=("⚠️  Legacy failover private endpoint still present: $LEGACY_PE_FAILOVER_NAME (delete manually if no longer needed)")
    fi

    # Display cleanup results
    printf "%s\n" "${cleanup_results[@]}"

    print_success "Private endpoint cleanup completed"
    return 0
}

# WHY: Database deletion before SQL Server deletion
# CONTEXT: SQL Server cannot be deleted while databases exist
# IMPACT: Proper cleanup order prevents errors
cleanup_database() {
    print_step "Cleaning up SQL database..."
    
    # WHY: Check if database exists
    # CONTEXT: Database may not exist if setup was incomplete
    if ! az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Database '$SQL_DATABASE_NAME' not found - skipping"
        return 0
    fi
    
    print_info "Deleting database: $SQL_DATABASE_NAME..."
    
    # WHY: Delete database with confirmation bypass
    # CONTEXT: User already confirmed cleanup operation
    # IMPACT: Removes demo database and all data
    if az sql db delete \
        --name "$SQL_DATABASE_NAME" \
        --server "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --yes &> /dev/null; then
        print_success "Database deleted successfully"
    else
        print_error "Database deletion failed"
        return 1
    fi
    
    return 0
}

# WHY: SQL Server cleanup is final step
# CONTEXT: All dependent resources (database, private endpoints) must be deleted first
# IMPACT: Complete removal of SQL Server demo infrastructure
cleanup_sql_server() {
    local keep_sqlserver="$1"
    
    # WHY: Respect --keep-sqlserver flag for preservation
    # CONTEXT: User may want to keep SQL Server for continued testing
    # IMPACT: Allows selective cleanup of private endpoints only
    if [[ "$keep_sqlserver" == "true" ]]; then
        print_info "Keeping SQL Server as requested (--keep-sqlserver flag)"
        print_warning "SQL Server will continue incurring costs (~$5/month for Basic tier)"
        print_info "To delete later, run without --keep-sqlserver flag"
        return 0
    fi
    
    print_step "Cleaning up SQL Server..."
    
    # WHY: Check if SQL Server exists
    # CONTEXT: SQL Server may not exist or was already deleted
    if ! az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "SQL Server '$SQL_SERVER_NAME' not found - skipping"
        return 0
    fi
    
    print_info "Deleting SQL Server: $SQL_SERVER_NAME..."
    
    # WHY: Delete SQL Server with all configurations
    # CONTEXT: Removes Entra ID admin, firewall rules, and server configuration
    # IMPACT: Complete cleanup of SQL Server demo infrastructure
    if az sql server delete \
        --name "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --yes &> /dev/null; then
        print_success "SQL Server deleted successfully"
    else
        print_error "SQL Server deletion failed"
        return 1
    fi
    
    return 0
}

# WHY: Comprehensive validation ensures complete cleanup
# CONTEXT: Verifies all resources were successfully removed
# IMPACT: Provides confidence that cleanup was successful
validate_cleanup() {
    print_step "Validating cleanup completion..."
    
    local validation_results=()
    local cleanup_incomplete=false
    
    # Check SQL Server removal
    if az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        validation_results+=("⚠️  SQL Server still exists: $SQL_SERVER_NAME")
        cleanup_incomplete=true
    else
        validation_results+=("✅ SQL Server removed successfully")
    fi
    
    # Check database removal (only if server exists)
    if [[ "$cleanup_incomplete" == "true" ]]; then
        if az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
            validation_results+=("⚠️  Database still exists: $SQL_DATABASE_NAME")
        else
            validation_results+=("✅ Database removed successfully")
        fi
    fi
    
    # Check private endpoint removal
    if az network private-endpoint show --name "$PE_PRIMARY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        validation_results+=("⚠️  Primary private endpoint still exists")
        cleanup_incomplete=true
    else
        validation_results+=("✅ Primary private endpoint removed")
    fi

    if az network private-endpoint show --name "$LEGACY_PE_FAILOVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        validation_results+=("⚠️  Legacy failover private endpoint detected - consider manual deletion if unused")
    fi
    
    # Check DNS records removal
    if az network private-dns record-set a show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --zone-name "$PRIVATE_DNS_ZONE" \
        --name "$SQL_SERVER_NAME" &> /dev/null 2>&1; then
        validation_results+=("⚠️  DNS records still exist")
        cleanup_incomplete=true
    else
        validation_results+=("✅ DNS records removed")
    fi
    
    # Display validation results
    print_info "Cleanup validation results:"
    printf "%s\n" "${validation_results[@]}"
    
    if [[ "$cleanup_incomplete" == "true" ]]; then
        print_warning "Cleanup validation found remaining resources"
        print_info "Some resources may require manual cleanup"
        return 1
    else
        print_success "Cleanup validation completed - all resources removed"
        return 0
    fi
}

# WHY: Cleanup function ensures proper script exit
# CONTEXT: Handles script interruption gracefully
# IMPACT: Provides clear messaging if cleanup is interrupted
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_warning "Cleanup script interrupted with exit code: $exit_code"
        print_info "Some resources may not have been fully cleaned up"
        print_info "You can re-run this script to complete cleanup"
    fi
    
    exit $exit_code
}
trap cleanup EXIT SIGINT SIGTERM

# WHY: Display comprehensive cleanup summary
# CONTEXT: Provides confirmation and next steps after cleanup
# IMPACT: Ensures user understands cleanup results
display_cleanup_summary() {
    local keep_sqlserver="$1"
    
    print_success "🎉 SQL Server demo cleanup completed!"
    
    cat << EOF

📋 CLEANUP SUMMARY
==================

Resources Removed:
    ✅ Private Endpoint: Primary region connection
    ✅ DNS Records: Private endpoint A record
EOF

    if [[ "$keep_sqlserver" == "true" ]]; then
        cat << EOF
  ⚠️  SQL Server: KEPT (--keep-sqlserver flag)
  ⚠️  SQL Database: KEPT (server preserved)

💰 COST REMINDER
================
SQL Server and database are still running:
  - SQL Database (Basic tier): ~\$5/month
  - Private Endpoints: Removed - no cost
  
To complete cleanup later:
  ./scripts/demo/cleanup-sqlserver-private-endpoints.sh --tfvars-file ${TFVARS_FILE_NAME} --auto-approve

EOF
    else
        cat << EOF
  ✅ SQL Database: Removed (including demo data)
  ✅ SQL Server: Removed (including Entra ID configuration)

💰 COST SAVINGS
===============
All SQL Server demo resources removed:
  - SQL Database (Basic tier): ~\$5/month saved
  - SQL Server: No additional cost
  - Private Endpoints: No cost (removed)

EOF
    fi

    cat << EOF
🔄 REDEPLOYMENT
===============
To redeploy SQL Server demo infrastructure:
  ./scripts/demo/setup-sqlserver-private-endpoints.sh --tfvars-file ${TFVARS_FILE_NAME}

📖 NOTES
========
- VNet infrastructure (VNets, subnets, DNS zones) was NOT removed
- VNet infrastructure is managed by ptn-azure-vnet-extension Terraform pattern
- Key Vault demo resources (if deployed) are independent and unaffected

✨ Demo environment cleanup completed successfully!

EOF
}

# WHY: Main execution function with comprehensive safety checks
# CONTEXT: Orchestrates cleanup process with user confirmation
# IMPACT: Provides safe, reliable cleanup process
main() {
    local auto_approve=false
    local keep_sqlserver=false
    local tfvars_file="demo-prep"  # Default to demo-prep for backward compatibility
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --keep-sqlserver)
                keep_sqlserver=true
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
                echo "Usage: $0 [--auto-approve] [--tfvars-file <name>] [--keep-sqlserver]"
                echo ""
                echo "Clean up SQL Server demo resources deployed by setup-sqlserver-private-endpoints.sh"
                echo ""
                echo "Options:"
                echo "  --auto-approve       Skip confirmation prompts"
                echo "  --tfvars-file <name> tfvars file name used during setup (default: demo-prep)"
                echo "  --keep-sqlserver     Keep SQL Server and database (only remove private endpoints)"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --tfvars-file demo-prep"
                echo "  $0 --tfvars-file regional-examples --auto-approve"
                echo "  $0 --keep-sqlserver --auto-approve"
                exit 0
                ;;
            *)
                print_error "Unknown option: ${1:-}"
                print_info "Use --help for usage information"
                return 1
                ;;
        esac
    done
    
    print_step "Starting PPCC25 SQL Server demo cleanup..."
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
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        print_warning "Prerequisites validation failed - cleanup may not be possible"
        return 1
    fi
    
    # Identify existing resources
    if ! identify_existing_resources; then
        print_info "No resources found to clean up - exiting"
        return 0
    fi
    
    # WHY: User confirmation prevents accidental cleanup
    # CONTEXT: Deletion operations are irreversible
    # IMPACT: Ensures intentional cleanup and provides clear preview
    if [[ "$auto_approve" != true ]]; then
        cat << EOF

⚠️  CLEANUP CONFIRMATION
========================

This script will DELETE the following resources:
EOF

        if [[ "$keep_sqlserver" == "true" ]]; then
            cat << EOF
    🗑️  Private Endpoint (Primary): $PE_PRIMARY_NAME
    🗑️  DNS A Records for: $SQL_SERVER_NAME
  
  💾 KEEPING (--keep-sqlserver flag):
  ✅ SQL Server: $SQL_SERVER_NAME
  ✅ SQL Database: $SQL_DATABASE_NAME

⚠️  SQL Server and database will continue incurring costs (~$5/month)
EOF
        else
            cat << EOF
  🗑️  Private Endpoint (Primary): $PE_PRIMARY_NAME
  🗑️  DNS A Records for: $SQL_SERVER_NAME
  🗑️  SQL Database: $SQL_DATABASE_NAME (including all demo data)
  🗑️  SQL Server: $SQL_SERVER_NAME (including Entra ID configuration)

⚠️  THIS OPERATION CANNOT BE UNDONE
⚠️  All demo data in the database will be permanently deleted
EOF
        fi

        cat << EOF

Resource Group: $RESOURCE_GROUP_NAME
Expected Duration: 3-5 minutes

EOF
        
        read -p "Are you sure you want to proceed with cleanup? (y/N): " -n 1 -r
        echo
        if [[ ! ${REPLY:-} =~ ^[Yy]$ ]]; then
            print_info "Cleanup cancelled by user"
            return 0
        fi
    fi
    
    # Execute cleanup steps in proper order
    print_info "Starting cleanup operations..."
    
    # Step 1: DNS records (no dependencies)
    cleanup_dns_records
    
    # Step 2: Private endpoints (reference SQL Server)
    cleanup_private_endpoints
    
    # Step 3: Database (parent is SQL Server)
    if [[ "$keep_sqlserver" != "true" ]]; then
        cleanup_database
    fi
    
    # Step 4: SQL Server (final step)
    cleanup_sql_server "$keep_sqlserver"
    
    # Validate cleanup completion
    print_info "Performing cleanup validation..."
    validate_cleanup
    
    # Display summary
    display_cleanup_summary "$keep_sqlserver"
    
    print_success "🎯 PPCC25 SQL Server demo cleanup completed successfully!"
    return 0
}

# Execute main function with all arguments
main "$@"
