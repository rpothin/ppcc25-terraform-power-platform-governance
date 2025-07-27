# Integration Tests for Export Power Platform Connectors Utility
#
# Validates the export of connectors against a real tenant. Requires OIDC authentication.

variables {
  test_timeout_minutes = 5
}

run "comprehensive_validation" {
  command = plan

  # ============================================================================
  # SECTION 1: Provider and Data Source Validation
  # ============================================================================
  assert {
    condition     = can(data.powerplatform_connectors.all)
    error_message = "Provider connectivity and data source accessibility failed."
  }
  assert {
    condition     = can(data.powerplatform_connectors.all.connectors) && can(data.powerplatform_connectors.all.id)
    error_message = "Data source must have both 'connectors' list and 'id' attributes."
  }
  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) >= 0
    error_message = "Connectors data source should return a list (can be empty)."
  }

  # ============================================================================
  # SECTION 2: Output Accessibility and Consistency (including new outputs)
  # ============================================================================
  assert {
    condition = can(output.connector_ids) && can(output.connectors_summary) && can(output.connectors_detailed)
    error_message = "All outputs (connector_ids, connectors_summary, connectors_detailed) should be accessible."
  }
  assert {
    condition = can(output.paged_connector_ids) && can(output.paged_connectors_summary) && can(output.paged_connectors_detailed)
    error_message = "Paged outputs (paged_connector_ids, paged_connectors_summary, paged_connectors_detailed) should be accessible."
  }
  assert {
    condition = can(output.connector_metrics) && can(output.publishers_present) && can(output.tiers_present) && can(output.types_present) && can(output.connectors_by_publisher)
    error_message = "Utility and metrics outputs should be accessible."
  }
  assert {
    condition = can(output.connectors_json) && can(output.connectors_csv)
    error_message = "Export format outputs (JSON, CSV) should be accessible."
  }
  assert {
    condition     = length(output.connector_ids) == length(output.connectors_summary) && length(output.connector_ids) == length(output.connectors_detailed)
    error_message = "All outputs should have matching lengths."
  }
  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) == 0 ? (length(output.connector_ids) == 0 && length(output.connectors_summary) == 0 && length(output.connectors_detailed) == 0) : true
    error_message = "If no connectors are present, all outputs should be empty lists."
  }
  assert {
    condition     = length(output.connector_ids) == length(toset(output.connector_ids))
    error_message = "All connector IDs must be unique (no duplicates)."
  }

  # ============================================================================
  # SECTION 3: Basic Connector Properties Validation (connectors_summary)
  # ============================================================================
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : can(c.id) && can(c.name) && can(c.display_name) && can(c.publisher) && can(c.tier) && can(c.type) && can(c.unblockable)]) : true
    error_message = "Each connector summary must have all required properties: id, name, display_name, publisher, tier, type, unblockable."
  }
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : type(c.id) == string && type(c.name) == string && type(c.display_name) == string && type(c.publisher) == string && type(c.tier) == string && type(c.type) == string && type(c.unblockable) == bool]) : true
    error_message = "Connector properties must have correct types: strings for id/name/display_name/publisher/tier/type, boolean for unblockable."
  }
  assert {
    condition     = length(output.connectors_summary) > 0 ? all([for c in output.connectors_summary : length(c.id) > 0 && length(c.name) > 0 && length(c.display_name) > 0]) : true
    error_message = "Connector id, name, and display_name must be non-empty strings."
  }
  assert {
    condition     = length(output.connector_ids) > 0 ? all([for id in output.connector_ids : can(regex("^/providers/Microsoft\\.PowerApps/apis/", id))]) : true
    error_message = "All connector IDs must follow Power Platform format (/providers/Microsoft.PowerApps/apis/...)."
  }

  # ============================================================================
  # SECTION 4: Advanced Metadata Validation (connectors_detailed)
  # ============================================================================
  assert {
    condition     = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed : can(c.id) && can(c.name) && can(c.display_name) && can(c.publisher) && can(c.tier) && can(c.type) && can(c.unblockable)]) : true
    error_message = "Each connectors_detailed entry must include all core properties from summary."
  }
  assert {
    condition     = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed : can(c.certified) && can(c.capabilities) && can(c.api) && can(c.description) && can(c.icon_url) && can(c.swagger_url) && can(c.policy_template)]) : true
    error_message = "Each connectors_detailed entry must include advanced metadata fields."
  }
  assert {
    condition = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed :
      (c.certified == null || type(c.certified) == bool) &&
      (c.capabilities == null || type(c.capabilities) == list) &&
      (c.api == null || type(c.api) == string) &&
      (c.description == null || type(c.description) == string) &&
      (c.icon_url == null || type(c.icon_url) == string) &&
      (c.swagger_url == null || type(c.swagger_url) == string) &&
      (c.policy_template == null || type(c.policy_template) == string)
    ]) : true
    error_message = "Advanced metadata fields must have correct types or be null."
  }

  # ============================================================================
  # SECTION 5: Error Handling and Edge Cases
  # ============================================================================
  assert {
    condition     = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed : c.certified == null || type(c.certified) == bool]) : true
    error_message = "Certified field must be boolean or null when missing."
  }
  assert {
    condition     = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed : c.capabilities == null || length(c.capabilities) >= 0]) : true
    error_message = "Capabilities must be a list (can be empty) or null when missing."
  }
  assert {
    condition     = length(output.connectors_detailed) > 0 ? all([for c in output.connectors_detailed : c.api == null || (type(c.api) == string && length(c.api) >= 0)]) : true
    error_message = "API field must be string (can be empty) or null when missing."
  }

  # ============================================================================
  # SECTION 6: Performance, Pagination, and Export Format Validation
  # ============================================================================
  assert {
    condition = output.connector_metrics.total >= output.connector_metrics.filtered && output.connector_metrics.filtered >= output.connector_metrics.paged
    error_message = "Connector metrics should be consistent: total >= filtered >= paged."
  }
  assert {
    condition = length(output.paged_connector_ids) <= (var.page_size == 0 ? 1000 : var.page_size)
    error_message = "Paged connector IDs should not exceed page_size (or 1000 if not set)."
  }
  assert {
    condition = length(output.paged_connector_ids) == length(output.paged_connectors_summary) && length(output.paged_connector_ids) == length(output.paged_connectors_detailed)
    error_message = "Paged outputs should have matching lengths."
  }
  assert {
    condition = can(jsondecode(output.connectors_json))
    error_message = "connectors_json output should be valid JSON."
  }
  assert {
    condition = can(regex("^id,name,display_name,publisher,tier,type,unblockable", output.connectors_csv))
    error_message = "connectors_csv output should start with the correct header."
  }
  assert {
    condition     = length(output.connectors_detailed) <= 1000
    error_message = "Warning: More than 1000 connectors detected. Performance may be impacted for very large tenants."
  }
  assert {
    condition     = length(output.connector_ids) == 0 || length(output.connector_ids) >= 10
    error_message = "Expected either 0 connectors (empty tenant) or at least 10 (typical minimum for active tenants)."
  }
  assert {
    condition     = length(output.connectors_detailed) <= 500 || length(output.connectors_summary) > 0
    error_message = "For large connector datasets (>500), summary output should be preferred for performance."
  }
}