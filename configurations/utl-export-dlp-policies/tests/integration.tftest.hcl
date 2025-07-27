# Integration Tests for DLP Policies Configuration
#
# These integration tests validate the DLP policies export functionality against
# a real Power Platform tenant. Tests require authentication via OIDC (Azure AD)
# and are designed to run in CI/CD environments like GitHub Actions.
#
# Test Categories:
# - Data Source Validation: Ensures the data source returns expected structure
# - Output Structure Validation: Validates output compliance with AVM patterns
# - Data Integrity Checks: Verifies logical consistency of exported data
# - Security Validation: Ensures sensitive data is properly handled

variables {
  # Test configuration variables
  expected_minimum_policies = 0 # Allow for empty tenants in test environments
  test_timeout_minutes      = 5
}

# Optimized: All assertions consolidated into a single plan run for performance
run "dlp_policies_comprehensive_validation" {
  command = plan

  # Framework and data source validation
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "This basic assertion validates that the data source can be referenced - framework test"
  }
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current.policies)
    error_message = "DLP policies data source should be accessible and return a policies attribute"
  }
  assert {
    condition     = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "DLP policies data source should not be null"
  }

  # Output structure validation - Updated for unified output
  assert {
    condition     = can(output.dlp_policies.policy_count)
    error_message = "dlp_policies output should contain policy_count attribute"
  }
  assert {
    condition     = can(output.dlp_policies.policies)
    error_message = "dlp_policies output should contain policies array"
  }
  assert {
    condition     = can(output.dlp_policies.export_metadata)
    error_message = "dlp_policies output should contain export_metadata"
  }
  assert {
    condition     = output.dlp_policies.policy_count >= 0
    error_message = "Policy count should be a non-negative integer"
  }
  assert {
    condition     = length(output.dlp_policies.policies) == output.dlp_policies.policy_count
    error_message = "Policy count should match the length of policies array"
  }

  # Export metadata validation
  assert {
    condition     = can(output.dlp_policies.export_metadata.total_policies_in_tenant)
    error_message = "Export metadata should include total_policies_in_tenant"
  }
  assert {
    condition     = can(output.dlp_policies.export_metadata.filtered_policies_count)
    error_message = "Export metadata should include filtered_policies_count"
  }
  assert {
    condition     = can(output.dlp_policies.export_metadata.filter_applied)
    error_message = "Export metadata should include filter_applied flag"
  }
  assert {
    condition     = can(output.dlp_policies.export_metadata.detail_level)
    error_message = "Export metadata should include detail_level"
  }
  assert {
    condition     = contains(["summary", "detailed"], output.dlp_policies.export_metadata.detail_level)
    error_message = "Export metadata detail_level should be either 'summary' or 'detailed'"
  }

  # Policy structure validation
  assert {
    condition = output.dlp_policies.policy_count == 0 || (
      output.dlp_policies.policy_count > 0 &&
      alltrue([
        for policy in output.dlp_policies.policies :
        can(policy.id) &&
        can(policy.display_name) &&
        can(policy.environment_type) &&
        can(policy.environments)
      ])
    )
    error_message = "Each policy should have required attributes: id, display_name, environment_type, environments"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], policy.environment_type)
    ])
    error_message = "Policy environment_type must be one of: AllEnvironments, ExceptEnvironments, OnlyEnvironments"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      can(policy.business_connectors) &&
      can(policy.non_business_connectors) &&
      can(policy.blocked_connectors)
    ])
    error_message = "Each policy should have business_connectors, non_business_connectors, and blocked_connectors arrays"
  }

  # Connector structure validation - Unified schema: all fields present, with conditional population
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.business_connectors :
        can(connector.id) &&
        can(connector.connector_id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count) &&
        can(connector.action_rules) &&
        can(connector.endpoint_rules)
      ]
    ]))
    error_message = "Business connectors should have all unified schema fields"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.non_business_connectors :
        can(connector.id) &&
        can(connector.connector_id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count) &&
        can(connector.action_rules) &&
        can(connector.endpoint_rules)
      ]
    ]))
    error_message = "Non-business connectors should have all unified schema fields"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.blocked_connectors :
        can(connector.id) &&
        can(connector.connector_id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count) &&
        can(connector.action_rules) &&
        can(connector.endpoint_rules)
      ]
    ]))
    error_message = "Blocked connectors should have all unified schema fields"
  }

  # Summary counts validation
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      can(policy.connector_summary.business_count) &&
      can(policy.connector_summary.non_business_count) &&
      can(policy.connector_summary.blocked_count) &&
      can(policy.connector_summary.custom_patterns_count) &&
      can(policy.connector_summary.total_connectors)
    ])
    error_message = "Connector summary should have all required count fields"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      policy.connector_summary.business_count == length(policy.business_connectors) &&
      policy.connector_summary.non_business_count == length(policy.non_business_connectors) &&
      policy.connector_summary.blocked_count == length(policy.blocked_connectors) &&
      policy.connector_summary.custom_patterns_count == length(policy.custom_connectors_patterns) &&
      policy.connector_summary.total_connectors == (
        policy.connector_summary.business_count +
        policy.connector_summary.non_business_count +
        policy.connector_summary.blocked_count
      )
    ])
    error_message = "Summary counts should match actual connector array lengths"
  }

  # Audit information validation
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      can(policy.created_by) &&
      can(policy.created_time) &&
      can(policy.last_modified_by) &&
      can(policy.last_modified_time)
    ])
    error_message = "Each policy should have audit information: created_by, created_time, last_modified_by, last_modified_time"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      policy.created_time != "" && policy.last_modified_time != ""
    ])
    error_message = "Created and modified timestamps should not be empty"
  }

  # Custom connectors patterns validation
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for pattern in policy.custom_connectors_patterns :
        can(pattern.data_group) &&
        can(pattern.host_url_pattern) &&
        can(pattern.order) &&
        contains(["Business", "NonBusiness", "Blocked", "Ignore"], pattern.data_group)
      ]
    ]))
    error_message = "Custom connector patterns should have valid structure and data_group values"
  }

  # Governance analysis output validation
  assert {
    condition     = can(output.governance_analysis)
    error_message = "governance_analysis output should be available"
  }
  assert {
    condition     = can(output.governance_analysis.tenant_summary)
    error_message = "governance_analysis should contain tenant_summary"
  }
  assert {
    condition     = can(output.governance_analysis.connector_distribution)
    error_message = "governance_analysis should contain connector_distribution"
  }
  assert {
    condition     = can(output.governance_analysis.complexity_indicators)
    error_message = "governance_analysis should contain complexity_indicators"
  }

  # Governance analysis structure validation
  assert {
    condition = (
      can(output.governance_analysis.tenant_summary.total_policies) &&
      can(output.governance_analysis.tenant_summary.policies_by_type) &&
      can(output.governance_analysis.tenant_summary.policies_with_custom_patterns)
    )
    error_message = "Tenant summary should have all required fields"
  }
  assert {
    condition = (
      can(output.governance_analysis.connector_distribution.total_business_connectors) &&
      can(output.governance_analysis.connector_distribution.total_non_business_connectors) &&
      can(output.governance_analysis.connector_distribution.total_blocked_connectors)
    )
    error_message = "Connector distribution should have all required fields"
  }
  assert {
    condition = (
      can(output.governance_analysis.complexity_indicators.policies_with_action_rules) &&
      can(output.governance_analysis.complexity_indicators.policies_with_endpoint_rules) &&
      can(output.governance_analysis.complexity_indicators.average_connectors_per_policy)
    )
    error_message = "Complexity indicators should have all required fields"
  }

  # Data consistency validation
  assert {
    condition     = output.governance_analysis.tenant_summary.total_policies == output.dlp_policies.policy_count
    error_message = "Governance analysis total_policies should match dlp_policies policy_count"
  }
  assert {
    condition     = output.governance_analysis.tenant_summary.total_policies == output.dlp_policies.export_metadata.filtered_policies_count
    error_message = "Governance analysis total_policies should match export metadata filtered_policies_count"
  }

  # Provider configuration validation
  assert {
    condition     = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "Power Platform provider should be properly configured and authenticated"
  }

  # Output schema version validation
  assert {
    condition     = can(output.output_schema_version)
    error_message = "output_schema_version should be available"
  }
  assert {
    condition     = output.output_schema_version != ""
    error_message = "output_schema_version should not be empty"
  }
}

# Additional test run for detailed rules validation (when include_detailed_rules = true)
run "dlp_policies_detailed_validation" {
  command = plan

  variables {
    include_detailed_rules = true
  }

  # Validate detailed output structure
  assert {
    condition     = output.dlp_policies.export_metadata.detail_level == "detailed"
    error_message = "When include_detailed_rules = true, detail_level should be 'detailed'"
  }

  # Detailed connector structure validation (unified schema: all fields present, arrays populated)
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.business_connectors :
        can(connector.connector_id) &&
        can(connector.action_rules) &&
        can(connector.endpoint_rules) &&
        is_list(connector.action_rules) &&
        is_list(connector.endpoint_rules)
      ]
    ]))
    error_message = "In detailed mode, connectors should have connector_id and rule arrays (unified schema)"
  }

  # Action rules structure validation (when present)
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies :
      flatten([
        for connector in concat(policy.business_connectors, policy.non_business_connectors, policy.blocked_connectors) : [
          for rule in connector.action_rules :
          can(rule.action_id) && can(rule.behavior)
        ]
      ])
    ]))
    error_message = "Action rules should have action_id and behavior attributes"
  }

  # Endpoint rules structure validation (when present)
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies :
      flatten([
        for connector in concat(policy.business_connectors, policy.non_business_connectors, policy.blocked_connectors) : [
          for rule in connector.endpoint_rules :
          can(rule.endpoint) && can(rule.behavior) && can(rule.order)
        ]
      ])
    ]))
    error_message = "Endpoint rules structure validation (when present)"
  }
}