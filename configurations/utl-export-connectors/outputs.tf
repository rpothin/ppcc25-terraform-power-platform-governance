# Output Values for Export Power Platform Connectors Utility
#
# Implements AVM anti-corruption layer by outputting only computed attributes.
#
# Output Categories:
# - Resource Identifiers: Connector IDs
# - Computed Values: Connector metadata
# - Summary Information: Aggregated data for reporting

output "connector_ids" {
  description = <<DESCRIPTION
List of all connector IDs in the tenant.
Useful for downstream automation, reporting, and governance.
DESCRIPTION
  value = [for c in data.powerplatform_connectors.all.connectors : c.id]
}

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
