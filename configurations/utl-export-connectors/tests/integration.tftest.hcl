# Integration Tests for Export Power Platform Connectors Utility
#
# Validates the export of connectors against a real tenant. Requires OIDC authentication.

variables {
  test_timeout_minutes = 5
}

run "comprehensive_validation" {
  command = plan

  # Provider and data source accessibility
  assert {
    condition     = can(data.powerplatform_connectors.all)
    error_message = "Provider connectivity and data source accessibility failed."
  }

  # Data source returns a list (can be empty)
  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) >= 0
    error_message = "Connectors data source should return a list (can be empty)."
  }

  # Output accessibility
  assert {
    condition     = can(output.connector_ids)
    error_message = "Output 'connector_ids' should be accessible."
  }
  assert {
    condition     = can(output.connectors_summary)
    error_message = "Output 'connectors_summary' should be accessible."
  }

  # Output consistency: connector_ids and connectors_summary lengths match
  assert {
    condition     = length(output.connector_ids) == length(output.connectors_summary)
    error_message = "connector_ids and connectors_summary outputs should have matching lengths."
  }

  # Validate required properties for each connector (id, name, display_name)
  assert {
    condition     = all([for c in output.connectors_summary : can(c.id) && can(c.name) && can(c.display_name)])
    error_message = "Each connector must have id, name, and display_name properties."
  }

  # Edge case: empty connector list
  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) == 0 ? length(output.connector_ids) == 0 && length(output.connectors_summary) == 0 : true
    error_message = "If no connectors are present, outputs should be empty lists."
  }

  # Validate property types for first connector (if present)
  assert {
    condition     = length(output.connectors_summary) > 0 ? (type(output.connectors_summary[0].id) == string && type(output.connectors_summary[0].name) == string && type(output.connectors_summary[0].display_name) == string) : true
    error_message = "Connector properties id, name, display_name must be strings."
  }

  # Validate additional connector properties exist in summary
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : can(c.publisher) && can(c.tier) && can(c.type)]) : true
    error_message = "Each connector summary must include publisher, tier, and type properties."
  }

  # Validate connector IDs are non-empty strings
  assert {
    condition     = length(output.connector_ids) > 0 ? all([for id in output.connector_ids : length(id) > 0]) : true
    error_message = "All connector IDs must be non-empty strings."
  }

  # Validate connector names are non-empty strings
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : length(c.name) > 0]) : true
    error_message = "All connector names must be non-empty strings."
  }

  # Validate display names are non-empty strings
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : length(c.display_name) > 0]) : true
    error_message = "All connector display names must be non-empty strings."
  }

  # Validate connector IDs are unique
  assert {
    condition     = length(output.connector_ids) == length(toset(output.connector_ids))
    error_message = "All connector IDs must be unique (no duplicates)."
  }

  # Validate unblockable property is boolean
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : type(c.unblockable) == bool]) : true
    error_message = "Connector unblockable property must be boolean type."
  }

  # Validate data source schema consistency
  assert {
    condition     = can(data.powerplatform_connectors.all.connectors) && can(data.powerplatform_connectors.all.id)
    error_message = "Data source must have both 'connectors' list and 'id' attributes."
  }
}
