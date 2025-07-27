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
}
