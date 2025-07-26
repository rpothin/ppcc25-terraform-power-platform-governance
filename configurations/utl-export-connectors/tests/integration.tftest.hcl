# Integration Tests for Export Power Platform Connectors Utility
#
# Validates the export of connectors against a real tenant. Requires OIDC authentication.

variables {
  test_timeout_minutes = 5
}

run "comprehensive_validation" {
  command = plan

  assert {
    condition     = can(data.powerplatform_connectors.all)
    error_message = "Provider connectivity and data source accessibility failed."
  }

  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) >= 0
    error_message = "Connectors data source should return a list (can be empty)."
  }

  assert {
    condition     = can(output.connector_ids)
    error_message = "Output 'connector_ids' should be accessible."
  }

  assert {
    condition     = can(output.connectors_summary)
    error_message = "Output 'connectors_summary' should be accessible."
  }
}
