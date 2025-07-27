# Export Power Platform Connectors Utility Configuration
#
# This configuration exports all connectors in the tenant using AVM best practices.
#
# Key Features:
# - AVM-Inspired Structure: Modular, reusable, and secure
# - Anti-Corruption Layer: Outputs only computed attributes
# - Security-First: OIDC authentication, no secrets in code
# - Utility-Specific: No resource creation, only data export
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for direct API access
# - Backend Strategy: Azure Storage with OIDC for secure, keyless authentication
# - Resource Organization: Data source only, no stateful resources

provider "powerplatform" {
  use_oidc = true
}

data "powerplatform_connectors" "all" {}

# ============================================================================
# FILTERING LOGIC - Apply user-defined filters to connectors
# ============================================================================

locals {
  # Apply filtering based on publisher, tier, and type variables
  # Empty filter lists mean no filtering is applied for that dimension
  filtered_connectors = [
    for c in data.powerplatform_connectors.all.connectors : c
    if(
      (length(var.filter_publishers) == 0 || contains(var.filter_publishers, c.publisher)) &&
      (length(var.filter_tiers) == 0 || contains(var.filter_tiers, c.tier)) &&
      (length(var.filter_types) == 0 || contains(var.filter_types, c.type))
    )
  ]
}

# ============================================================================
# PAGINATION LOGIC - Support incremental processing for large tenants
# ============================================================================

locals {
  # Calculate pagination boundaries for filtered connectors
  # When page_size is 0, pagination is disabled (return all filtered connectors)
  page_start_index = var.page_size == 0 ? 0 : (var.page_number - 1) * var.page_size
  page_end_index   = var.page_size == 0 ? length(local.filtered_connectors) : min((var.page_number - 1) * var.page_size + var.page_size, length(local.filtered_connectors))

  # Apply pagination to filtered connectors
  paged_connectors = var.page_size == 0 ? local.filtered_connectors : slice(local.filtered_connectors, local.page_start_index, local.page_end_index)
}

# ============================================================================
# PERFORMANCE METRICS - Track connector counts for monitoring
# ============================================================================

locals {
  connector_count_total    = length(data.powerplatform_connectors.all.connectors)
  connector_count_filtered = length(local.filtered_connectors)
  connector_count_paged    = length(local.paged_connectors)
}

# ============================================================================
# UTILITY ANALYSIS - Extract metadata for governance insights
# ============================================================================

locals {
  publishers_present = toset([for c in local.filtered_connectors : c.publisher])
  tiers_present      = toset([for c in local.filtered_connectors : c.tier])
  types_present      = toset([for c in local.filtered_connectors : c.type])
  connectors_by_publisher = {
    for p in local.publishers_present :
    p => [for c in local.filtered_connectors : c if c.publisher == p]
  }
}

# ============================================================================
# EXPORT FORMATS - Generate integration-friendly output formats
# ============================================================================

locals {
  connectors_json = jsonencode(local.paged_connectors)
  connectors_csv = join("\n", concat([
    "id,name,display_name,publisher,tier,type,unblockable"
    ], [
    for c in local.paged_connectors : join(",", [c.id, c.name, c.display_name, c.publisher, c.tier, c.type, tostring(c.unblockable)])
  ]))
}