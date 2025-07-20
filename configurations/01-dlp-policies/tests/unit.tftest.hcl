# Unit Test for DLP Policies Export Configuration
# 
# This test validates the basic structure and syntax of the DLP export configuration
# without requiring Power Platform authentication or backend configuration.

# Provider configuration for tests - using minimal config for unit tests
provider "powerplatform" {
  use_oidc = true
}

# Test: Validate Terraform configuration syntax
run "validate_terraform_syntax" {
  command = plan

  assert {
    condition = can(terraform.required_version)
    error_message = "Terraform version constraint must be accessible"
  }
}

# Test: Validate provider configuration structure
run "validate_provider_config" {
  command = plan

  assert {
    condition = can(terraform.required_providers.powerplatform)
    error_message = "Power Platform provider configuration must be accessible"
  }
}

# Test: File structure validation
run "validate_file_structure" {
  command = plan
  
  assert {
    condition = fileexists("${path.module}/main.tf")
    error_message = "main.tf file must exist in the module"
  }
}
