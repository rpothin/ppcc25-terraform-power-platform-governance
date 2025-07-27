# Output Values for Export Power Platform Connectors Utility
#
# Implements AVM anti-corruption layer by outputting only computed attributes.
# Organized by usage patterns to support different governance scenarios:
# - Basic outputs: For simple automation and reporting
# - Paged outputs: For large tenant scenarios requiring incremental processing  
# - Metrics outputs: For performance monitoring and capacity planning
# - Utility outputs: For analysis and relationship mapping
# - Export outputs: For integration with external governance tools

# ============================================================================
# Output Schema Version
# ============================================================================

locals {
  output_schema_version = "1.0.0"
}

output "output_schema_version" {
  description = "The version of the output schema for this module."
  value       = local.output_schema_version
}

# ============================================================================
# BASIC OUTPUTS - Primary connector data after filtering
# ============================================================================

output "connector_ids" {
  description = <<DESCRIPTION
List of all connector IDs in the tenant, after applying any filter criteria.
Useful for downstream automation, reporting, and governance.
DESCRIPTION
  value       = [for c in local.filtered_connectors : c.id]
}

output "connectors_summary" {
  description = <<DESCRIPTION
Summary of all connectors with key metadata for governance and reporting, after applying any filter criteria.
DESCRIPTION
  value = [for c in local.filtered_connectors : {
    id           = c.id
    name         = c.name
    display_name = c.display_name
    publisher    = c.publisher
    tier         = c.tier
    type         = c.type
    unblockable  = c.unblockable
  }]
}

output "connectors_detailed" {
  description = <<DESCRIPTION
Comprehensive metadata for all connectors in the tenant, after applying any filter criteria.
Includes certification status, capabilities, API information, and more (if available in provider schema).
Performance note: For large tenants, this output may be large and impact plan/apply performance.
DESCRIPTION
  value = [for c in local.filtered_connectors : {
    id              = c.id
    name            = c.name
    display_name    = c.display_name
    publisher       = c.publisher
    tier            = c.tier
    type            = c.type
    unblockable     = c.unblockable
    certified       = try(c.certified, null)
    capabilities    = try(c.capabilities, null)
    api             = try(c.api, null)
    description     = try(c.description, null)
    icon_url        = try(c.icon_url, null)
    swagger_url     = try(c.swagger_url, null)
    policy_template = try(c.policy_template, null)
  }]
}

# ============================================================================
# PAGED OUTPUTS - For large tenant scenarios
# ============================================================================

output "paged_connector_ids" {
  description = <<DESCRIPTION
List of connector IDs after filtering and pagination.
Use for incremental processing or large tenant scenarios where full dataset would impact performance.
DESCRIPTION
  value       = [for c in local.paged_connectors : c.id]
}

output "paged_connectors_summary" {
  description = <<DESCRIPTION
Summary of paged connectors with key metadata after filtering and pagination.
Optimized for scenarios requiring batch processing of large connector inventories.
DESCRIPTION
  value = [for c in local.paged_connectors : {
    id           = c.id
    name         = c.name
    display_name = c.display_name
    publisher    = c.publisher
    tier         = c.tier
    type         = c.type
    unblockable  = c.unblockable
  }]
}

output "paged_connectors_detailed" {
  description = <<DESCRIPTION
Comprehensive metadata for paged connectors after filtering and pagination.
Use when detailed analysis is needed for subset of connectors in large tenants.
DESCRIPTION
  value = [for c in local.paged_connectors : {
    id              = c.id
    name            = c.name
    display_name    = c.display_name
    publisher       = c.publisher
    tier            = c.tier
    type            = c.type
    unblockable     = c.unblockable
    certified       = try(c.certified, null)
    capabilities    = try(c.capabilities, null)
    api             = try(c.api, null)
    description     = try(c.description, null)
    icon_url        = try(c.icon_url, null)
    swagger_url     = try(c.swagger_url, null)
    policy_template = try(c.policy_template, null)
  }]
}

# ============================================================================
# METRICS OUTPUTS - Performance monitoring and capacity planning
# ============================================================================

output "connector_metrics" {
  description = <<DESCRIPTION
Performance metrics for connector export operation.
Provides total, filtered, and paged counts for capacity planning and performance monitoring.
DESCRIPTION
  value = {
    total    = local.connector_count_total
    filtered = local.connector_count_filtered
    paged    = local.connector_count_paged
  }
}

# ============================================================================
# UTILITY OUTPUTS - Analysis and relationship mapping
# ============================================================================

output "publishers_present" {
  description = <<DESCRIPTION
Set of publishers present in the filtered connector set.
Useful for governance analysis and publisher-based policy decisions.
DESCRIPTION
  value       = local.publishers_present
}

output "tiers_present" {
  description = <<DESCRIPTION
Set of tiers present in the filtered connector set.
Helps identify licensing implications and governance requirements.
DESCRIPTION
  value       = local.tiers_present
}

output "types_present" {
  description = <<DESCRIPTION
Set of types present in the filtered connector set.
Supports classification and governance rule application.
DESCRIPTION
  value       = local.types_present
}

output "connectors_by_publisher" {
  description = <<DESCRIPTION
Mapping of publisher name to list of connectors for that publisher (after filtering).
Enables publisher-specific governance policies and risk assessment.
DESCRIPTION
  value       = local.connectors_by_publisher
}

# ============================================================================
# EXPORT OUTPUTS - Integration with external governance tools
# ============================================================================

output "connectors_json" {
  description = <<DESCRIPTION
Paged connectors as a JSON string for integration with external tools.
Structured format for consumption by governance automation and reporting systems.
DESCRIPTION
  value       = local.connectors_json
}

output "connectors_csv" {
  description = <<DESCRIPTION
Paged connectors as a CSV string for integration with external tools.
Tabular format for spreadsheet analysis and legacy governance systems.
DESCRIPTION
  value       = local.connectors_csv
}