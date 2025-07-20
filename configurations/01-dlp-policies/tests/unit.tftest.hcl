# Unit Test for DLP Policies Export Configuration
# 
# This test validates the basic structure and syntax of the DLP export configuration
# without requiring Power Platform authentication or backend configuration.

# Test basic configuration validation
run "validate_configuration_structure" {
  command = plan

  assert {
    condition     = can(terraform.required_version)
    error_message = "Terraform version constraint must be defined"
  }

  assert {
    condition     = can(terraform.required_providers.powerplatform)
    error_message = "Power Platform provider must be configured"
  }
}

# Test provider configuration syntax
run "validate_provider_configuration" {
  command = plan

  # Verify Power Platform provider is properly configured
  assert {
    condition     = can(terraform.required_providers.powerplatform.source)
    error_message = "Power Platform provider source must be specified"
  }

  assert {
    condition     = can(terraform.required_providers.powerplatform.version)
    error_message = "Power Platform provider version must be specified"
  }
}

# Test data source configuration syntax
run "validate_data_source_syntax" {
  command = plan

  # Verify data source is properly configured (syntax only)
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "DLP policies data source must be syntactically valid"
  }
}
