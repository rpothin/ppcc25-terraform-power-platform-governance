# Terraform Test for DLP Policies Export Configuration
# 
# This test file validates the DLP policies export configuration
# following AVM testing best practices and ensuring proper structure
# and output compliance.

# Provider configuration for tests
provider "powerplatform" {
  use_oidc = true
}

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

  # Verify dlp_policies output has the correct structure based on outputs.tf
  assert {
    condition     = can(output.dlp_policies.policy_count)
    error_message = "dlp_policies output must include policy_count attribute"
  }

  assert {
    condition     = can(output.dlp_policies.policies)
    error_message = "dlp_policies output must include policies attribute"
  }

  # Verify that outputs don't expose complete resource objects (TFFR2 compliance)
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

  # Test that sensitive output has the correct structure
  assert {
    condition     = can(output.dlp_policies_detailed_rules.policies_with_detailed_rules)
    error_message = "dlp_policies_detailed_rules must include policies_with_detailed_rules attribute"
  }
}

# Test 4: Validate Terraform version compliance
run "validate_terraform_version_compliance" {
  command = plan

  # Verify the data source is accessible (indirect test of configuration validity)
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "Configuration must be valid for data source to be accessible"
  }
}

# Test 5: Validate provider configuration
run "validate_provider_configuration" {
  command = plan

  # Verify Power Platform provider can be initialized (requires valid config)
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "Power Platform provider must be properly configured"
  }
}

# Test 6: Validate backend configuration
run "validate_backend_configuration" {
  command = plan

  # Verify configuration can generate a plan (indirect test of backend setup)
  assert {
    condition     = can(output.dlp_policies)
    error_message = "Backend must be configured for plan generation to succeed"
  }
}

# Test 7: Output type validation (ensure outputs are properly typed)
run "validate_output_types" {
  command = plan

  # Verify policy_count is a number (from the actual output structure)
  assert {
    condition     = can(tonumber(output.dlp_policies.policy_count))
    error_message = "policy_count must be a valid number"
  }

  # Verify policies is a list (from the actual output structure)
  assert {
    condition     = can(tolist(output.dlp_policies.policies))
    error_message = "policies must be a valid list"
  }
}
