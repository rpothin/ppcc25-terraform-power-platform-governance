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

  # Output structure validation
  assert {
    condition     = can(output.dlp_policies.policy_count)
    error_message = "dlp_policies output should contain policy_count attribute"
  }
  assert {
    condition     = can(output.dlp_policies.policies)
    error_message = "dlp_policies output should contain policies array"
  }
  assert {
    condition     = output.dlp_policies.policy_count >= 0
    error_message = "Policy count should be a non-negative integer"
  }
  assert {
    condition     = length(output.dlp_policies.policies) == output.dlp_policies.policy_count
    error_message = "Policy count should match the length of policies array"
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

  # Connector structure validation
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.business_connectors :
        can(connector.id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count)
      ]
    ]))
    error_message = "Business connectors should have required structure: id, default_action_rule_behavior, action_rules_count, endpoint_rules_count"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.non_business_connectors :
        can(connector.id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count)
      ]
    ]))
    error_message = "Non-business connectors should have required structure: id, default_action_rule_behavior, action_rules_count, endpoint_rules_count"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue(flatten([
      for policy in output.dlp_policies.policies : [
        for connector in policy.blocked_connectors :
        can(connector.id) &&
        can(connector.default_action_rule_behavior) &&
        can(connector.action_rules_count) &&
        can(connector.endpoint_rules_count)
      ]
    ]))
    error_message = "Blocked connectors should have required structure: id, default_action_rule_behavior, action_rules_count, endpoint_rules_count"
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

  # Sensitive output validation
  assert {
    condition     = can(output.dlp_policies_detailed_rules)
    error_message = "dlp_policies_detailed_rules output should be available"
  }
  assert {
    condition     = can(output.dlp_policies_detailed_rules.policies_with_detailed_rules)
    error_message = "dlp_policies_detailed_rules should contain policies_with_detailed_rules array"
  }
  assert {
    condition = output.dlp_policies.policy_count == 0 || (
      length(output.dlp_policies_detailed_rules.policies_with_detailed_rules) == output.dlp_policies.policy_count
    )
    error_message = "Detailed rules should match the number of policies"
  }

  # Data consistency between outputs
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for i, policy in output.dlp_policies.policies :
      policy.id == output.dlp_policies_detailed_rules.policies_with_detailed_rules[i].policy_id &&
      policy.display_name == output.dlp_policies_detailed_rules.policies_with_detailed_rules[i].policy_name
    ])
    error_message = "Policy IDs and names should be consistent between outputs"
  }

  # Provider configuration validation
  assert {
    condition     = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "Power Platform provider should be properly configured and authenticated"
  }

  # Basic plan execution validation
  assert {
    condition     = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "Power Platform provider should be properly configured and data source accessible"
  }
}