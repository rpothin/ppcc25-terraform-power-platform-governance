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

# Test: Simple validation to ensure test framework is working
run "test_framework_validation" {
  command = plan

  assert {
    condition = true
    error_message = "This basic assertion should always pass - framework test"
  }
}

# Test: Basic data source functionality
run "data_source_basic_functionality" {
  command = plan

  assert {
    condition = can(data.powerplatform_data_loss_prevention_policies.current.policies)
    error_message = "DLP policies data source should be accessible and return a policies attribute"
  }

  assert {
    condition = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "DLP policies data source should not be null"
  }
}

# Test: Output structure validation
run "output_structure_validation" {
  command = plan

  assert {
    condition = can(output.dlp_policies.policy_count)
    error_message = "dlp_policies output should contain policy_count attribute"
  }

  assert {
    condition = can(output.dlp_policies.policies)
    error_message = "dlp_policies output should contain policies array"
  }

  assert {
    condition = output.dlp_policies.policy_count >= 0
    error_message = "Policy count should be a non-negative integer"
  }

  assert {
    condition = length(output.dlp_policies.policies) == output.dlp_policies.policy_count
    error_message = "Policy count should match the length of policies array"
  }
}

# Test: Policy structure validation
run "policy_structure_validation" {
  command = plan

  # Skip this test if no policies exist
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

  # Validate environment_type values
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], policy.environment_type)
    ])
    error_message = "Policy environment_type must be one of: AllEnvironments, ExceptEnvironments, OnlyEnvironments"
  }

  # Validate connector classifications exist
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      can(policy.business_connectors) &&
      can(policy.non_business_connectors) &&
      can(policy.blocked_connectors)
    ])
    error_message = "Each policy should have business_connectors, non_business_connectors, and blocked_connectors arrays"
  }
}

# Test: Connector structure validation
run "connector_structure_validation" {
  command = plan

  # Validate business connectors structure
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

  # Validate non-business connectors structure
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

  # Validate blocked connectors structure
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
}

# Test: Summary counts validation
run "summary_counts_validation" {
  command = plan

  # Validate connector summary structure and calculations
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

  # Validate summary calculations are correct
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
}

# Test: Audit information validation
run "audit_information_validation" {
  command = plan

  # Validate audit fields exist
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

  # Validate timestamps are not empty when policies exist
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for policy in output.dlp_policies.policies :
      policy.created_time != "" && policy.last_modified_time != ""
    ])
    error_message = "Created and modified timestamps should not be empty"
  }
}

# Test: Custom connectors patterns validation
run "custom_connectors_patterns_validation" {
  command = plan

  # Validate custom connector patterns structure when they exist
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
}

# Test: Sensitive output validation
run "sensitive_output_validation" {
  command = plan

  assert {
    condition = can(output.dlp_policies_detailed_rules)
    error_message = "dlp_policies_detailed_rules output should be available"
  }

  assert {
    condition = can(output.dlp_policies_detailed_rules.policies_with_detailed_rules)
    error_message = "dlp_policies_detailed_rules should contain policies_with_detailed_rules array"
  }

  # Validate detailed rules structure when policies exist
  assert {
    condition = output.dlp_policies.policy_count == 0 || (
      length(output.dlp_policies_detailed_rules.policies_with_detailed_rules) == output.dlp_policies.policy_count
    )
    error_message = "Detailed rules should match the number of policies"
  }
}

# Test: Data consistency between outputs
run "data_consistency_validation" {
  command = plan

  # Validate consistency between main output and detailed rules
  assert {
    condition = output.dlp_policies.policy_count == 0 || alltrue([
      for i, policy in output.dlp_policies.policies :
      policy.id == output.dlp_policies_detailed_rules.policies_with_detailed_rules[i].policy_id &&
      policy.display_name == output.dlp_policies_detailed_rules.policies_with_detailed_rules[i].policy_name
    ])
    error_message = "Policy IDs and names should be consistent between outputs"
  }
}

# Test: Provider configuration validation
run "provider_configuration_validation" {
  command = plan

  assert {
    condition = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "Power Platform provider should be properly configured and authenticated"
  }
}

# Test: Basic plan execution validation
run "plan_execution_validation" {
  command = plan

  # Just validate that we can execute the plan successfully
  # If the plan fails, the run block itself will fail
  assert {
    condition = data.powerplatform_data_loss_prevention_policies.current != null
    error_message = "Power Platform provider should be properly configured and data source accessible"
  }
}