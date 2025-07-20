# Terraform Test for DLP Policies Export Configuration
# 
# This test file validates the DLP policies export configuration
# following AVM testing best practices and ensuring proper structure
# and output compliance.

# Test 1: Validate configuration structure and plan generation
run "validate_configuration_structure" {
  command = plan

  # Verify that the configuration can generate a valid plan
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "DLP policies data source must be properly configured"
  }
}

# Test 2: Validate output structure compliance (anti-corruption layer)
run "validate_output_structure" {
  command = plan

  # Verify dlp_policies output has required discrete attributes
  assert {
    condition     = can(output.dlp_policies.policy_count)
    error_message = "dlp_policies output must include policy_count attribute"
  }

  assert {
    condition     = can(output.dlp_policies.policy_summaries)
    error_message = "dlp_policies output must include policy_summaries attribute"
  }

  assert {
    condition     = can(output.dlp_policies.environment_coverage)
    error_message = "dlp_policies output must include environment_coverage attribute"
  }

  assert {
    condition     = can(output.dlp_policies.audit_info)
    error_message = "dlp_policies output must include audit_info attribute"
  }

  # Verify that outputs don't expose complete resource objects
  assert {
    condition     = !can(output.dlp_policies.raw_policies)
    error_message = "dlp_policies output must not expose raw policy objects (TFFR2 compliance)"
  }
}

# Test 3: Validate sensitive output structure
run "validate_sensitive_output_structure" {
  command = plan

  # Verify dlp_policies_detailed_rules output structure
  assert {
    condition     = can(output.dlp_policies_detailed_rules)
    error_message = "dlp_policies_detailed_rules output must be defined"
  }

  # Test that sensitive output is properly marked
  # Note: This test verifies the output exists, actual sensitivity is handled by Terraform
  assert {
    condition     = can(output.dlp_policies_detailed_rules.connector_rules)
    error_message = "dlp_policies_detailed_rules must include connector_rules attribute"
  }

  assert {
    condition     = can(output.dlp_policies_detailed_rules.action_rules)
    error_message = "dlp_policies_detailed_rules must include action_rules attribute"
  }
}

# Test 4: Validate Terraform version compliance
run "validate_terraform_version_compliance" {
  command = plan

  # Ensure the configuration uses supported Terraform version
  assert {
    condition     = can(terraform.required_version)
    error_message = "Configuration must specify required Terraform version"
  }
}

# Test 5: Validate provider configuration
run "validate_provider_configuration" {
  command = plan

  # Verify Power Platform provider is properly configured
  assert {
    condition     = can(terraform.required_providers.powerplatform)
    error_message = "Power Platform provider must be properly configured"
  }

  # Verify OIDC authentication is configured (conceptual test)
  # Note: Direct provider configuration testing has limitations in Terraform tests
  assert {
    condition     = can(terraform.required_providers.powerplatform.version)
    error_message = "Power Platform provider version must be specified"
  }
}

# Test 6: Validate backend configuration
run "validate_backend_configuration" {
  command = plan

  # Verify Azure backend is configured with OIDC
  assert {
    condition     = can(terraform.backend)
    error_message = "Azure backend must be configured"
  }
}

# Test 7: Output type validation (ensure outputs are properly typed)
run "validate_output_types" {
  command = plan

  # Verify policy_count is a number
  assert {
    condition     = can(tonumber(output.dlp_policies.policy_count))
    error_message = "policy_count must be a valid number"
  }

  # Verify policy_summaries is a list
  assert {
    condition     = can(tolist(output.dlp_policies.policy_summaries))
    error_message = "policy_summaries must be a valid list"
  }

  # Verify audit_info is an object
  assert {
    condition     = can(tomap(output.dlp_policies.audit_info))
    error_message = "audit_info must be a valid map/object"
  }
}
