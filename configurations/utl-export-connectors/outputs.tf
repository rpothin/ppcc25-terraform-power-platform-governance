# Output Values for Export Power Platform Connectors Utility
#
# Implements AVM anti-corruption layer by outputting only computed attributes.
#
# Output Categories:
# - Resource Identifiers: Connector IDs
# - Computed Values: Connector metadata
# - Summary Information: Aggregated data for reporting

# List of all connector IDs in the tenant
output "connector_ids" {
  description = <<DESCRIPTION
List of all connector IDs in the tenant.
Useful for downstream automation, reporting, and governance.
DESCRIPTION
  value       = [for c in data.powerplatform_connectors.all.connectors : c.id]
}

# Summary of all connectors with key metadata
output "connectors_summary" {
  description = <<DESCRIPTION
Summary of all connectors with key metadata for governance and reporting.
DESCRIPTION
  value = [for c in data.powerplatform_connectors.all.connectors : {
    id           = c.id
    name         = c.name
    display_name = c.display_name
    publisher    = c.publisher
    tier         = c.tier
    type         = c.type
    unblockable  = c.unblockable
  }]
}

# Detailed metadata for all connectors
output "connectors_detailed" {
  description = <<DESCRIPTION
Comprehensive metadata for all connectors in the tenant, including all available properties from the provider.
Includes certification status, capabilities, API information, and more (if available in provider schema).
Performance note: For large tenants, this output may be large and impact plan/apply performance.
DESCRIPTION
  value = [for c in data.powerplatform_connectors.all.connectors : {
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
    # Add more fields as available in provider schema
  }]
}