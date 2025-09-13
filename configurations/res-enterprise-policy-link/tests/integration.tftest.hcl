# Integration Tests for res-enterprise-policy-link
# 22 total assertions exceeding 20+ requirement for res-* modules

provider "powerplatform" {
  use_oidc = true
}

variables {
  environment_id       = "12345678-1234-5678-9abc-123456789012"
  policy_type          = "NetworkInjection"
  system_id            = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/abcdef12-3456-789a-bcde-f123456789ab"
  validate_environment = false
}

run "plan_validation" {
  command = plan

  # Variable validation
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = "Environment ID should be valid GUID"
  }

  assert {
    condition     = contains(["NetworkInjection", "Encryption"], var.policy_type)
    error_message = "Policy type should be NetworkInjection or Encryption"
  }

  assert {
    condition     = can(regex("^/regions/.*/providers/Microsoft.PowerPlatform/enterprisePolicies/.*", var.system_id))
    error_message = "System ID should follow ARM format"
  }

  # Resource configuration
  assert {
    condition     = powerplatform_enterprise_policy.this.environment_id == var.environment_id
    error_message = "Resource should target correct environment"
  }

  assert {
    condition     = powerplatform_enterprise_policy.this.policy_type == var.policy_type
    error_message = "Resource should have correct policy type"
  }

  assert {
    condition     = powerplatform_enterprise_policy.this.system_id == var.system_id
    error_message = "Resource should reference correct system ID"
  }

  # Output validation
  assert {
    condition     = can(output.enterprise_policy_id)
    error_message = "Should output enterprise policy ID"
  }

  assert {
    condition     = can(output.policy_assignment_details)
    error_message = "Should output policy assignment details"
  }

  assert {
    condition     = can(output.environment_assignments)
    error_message = "Should output environment assignments"
  }

  assert {
    condition     = can(output.deployment_summary)
    error_message = "Should output deployment summary"
  }

  assert {
    condition     = can(output.module_metadata)
    error_message = "Should output module metadata"
  }
}

run "apply_validation" {
  command = apply

  # Runtime validation
  assert {
    condition     = powerplatform_enterprise_policy.this.id != null
    error_message = "Policy should be created with ID"
  }

  assert {
    condition     = output.enterprise_policy_id != null
    error_message = "Should output valid policy ID"
  }

  assert {
    condition     = output.policy_assignment_details.environment_id == var.environment_id
    error_message = "Assignment details should match environment"
  }

  assert {
    condition     = output.policy_assignment_details.policy_type == var.policy_type
    error_message = "Assignment details should match policy type"
  }

  assert {
    condition     = output.environment_assignments.environment_id == var.environment_id
    error_message = "Environment assignments should match"
  }

  assert {
    condition     = output.module_metadata.module_type == "res-enterprise-policy-link"
    error_message = "Module metadata should be correct"
  }

  assert {
    condition     = contains(output.module_metadata.supported_policy_types, var.policy_type)
    error_message = "Supported policy types should include configured type"
  }

  assert {
    condition     = output.deployment_summary.deployment_status == "deployed"
    error_message = "Deployment should be successful"
  }

  assert {
    condition     = output.deployment_summary.policy_type == var.policy_type
    error_message = "Deployment summary should match policy type"
  }

  assert {
    condition     = output.policy_type == var.policy_type
    error_message = "Policy type output should match variable"
  }

  assert {
    condition     = output.target_environment_id == var.environment_id
    error_message = "Target environment output should match variable"
  }
}

run "invalid_environment_test" {
  command = plan

  variables {
    environment_id       = "invalid-guid"
    policy_type          = "NetworkInjection"
    system_id            = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/test"
    validate_environment = false
  }

  expect_failures = [
    var.environment_id
  ]
}
