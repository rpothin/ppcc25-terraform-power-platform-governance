# Output Values for Export Power Platform Connectors Utility
#
# Implements AVM anti-corruption layer by outputting only computed attributes.
# Uses unified output structure that always represents the final processed data
# (filtered and paginated). This eliminates redundancy while maintaining clear,
# predictable API for all governance scenarios.

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
# SHARED TRANSFORMATIONS - DRY principle for connector data structures
# ============================================================================

locals {
  # Reusable connector summary transformation
  connector_summary_structure = {
    for idx, c in local.paged_connectors : idx => {
      id           = c.id
      name         = c.name
      display_name = c.display_name
      publisher    = c.publisher
      tier         = c.tier
      type         = c.type
      unblockable  = c.unblockable
    }
  }

  # Reusable connector detailed transformation
  connector_detailed_structure = {
    for idx, c in local.paged_connectors : idx => {
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
    }
  }
}

# ============================================================================
# PRIMARY OUTPUTS - Final processed connector data
# ============================================================================

output "connector_ids" {
  description = <<DESCRIPTION
List of connector IDs after applying filtering and pagination.
Always represents the final processed dataset for downstream consumption.
DESCRIPTION
  value       = [for c in local.paged_connectors : c.id]
}

output "connectors_summary" {
  description = <<DESCRIPTION
Summary of connectors with key metadata after filtering and pagination.
Optimized structure for governance reporting and automation scenarios.
DESCRIPTION
  value       = values(local.connector_summary_structure)
}

output "connectors_detailed" {
  description = <<DESCRIPTION
Comprehensive metadata for connectors after filtering and pagination.
Includes certification status, capabilities, API information, and more.
Performance note: For large result sets, consider using pagination to limit output size.
DESCRIPTION
  value       = values(local.connector_detailed_structure)
}

# ============================================================================
# METRICS OUTPUTS - Performance monitoring and capacity planning
# ============================================================================

output "connector_metrics" {
  description = <<DESCRIPTION
Performance metrics for connector export operation.
Provides processing pipeline visibility for capacity planning and performance monitoring.

Metrics include:
- total: All connectors in tenant before filtering
- filtered: Connectors remaining after applying filter criteria
- final: Connectors in the final output after filtering and pagination
- pagination_active: Whether pagination was applied (page_size > 0)
DESCRIPTION
  value = {
    total             = local.connector_count_total
    filtered          = local.connector_count_filtered
    final             = local.connector_count_paged
    pagination_active = var.page_size > 0
  }
}

# ============================================================================
# ANALYSIS OUTPUTS - Governance insights and relationship mapping
# ============================================================================

output "publishers_present" {
  description = <<DESCRIPTION
Set of publishers present in the final connector dataset.
Useful for governance analysis and publisher-based policy decisions.
DESCRIPTION
  value       = toset([for c in local.paged_connectors : c.publisher])
}

output "tiers_present" {
  description = <<DESCRIPTION
Set of tiers present in the final connector dataset.
Helps identify licensing implications and governance requirements.
DESCRIPTION
  value       = toset([for c in local.paged_connectors : c.tier])
}

output "types_present" {
  description = <<DESCRIPTION
Set of types present in the final connector dataset.
Supports classification and governance rule application.
DESCRIPTION
  value       = toset([for c in local.paged_connectors : c.type])
}

output "connectors_by_publisher" {
  description = <<DESCRIPTION
Mapping of publisher name to list of connectors for that publisher.
Enables publisher-specific governance policies and risk assessment.
Uses final processed dataset (after filtering and pagination).
DESCRIPTION
  value = {
    for p in toset([for c in local.paged_connectors : c.publisher]) :
    p => [for c in local.paged_connectors : c if c.publisher == p]
  }
}