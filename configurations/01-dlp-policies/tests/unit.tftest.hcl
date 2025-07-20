# Unit Test for DLP Policies Export Configuration
# 
# This test validates the basic structure and syntax of the DLP export configuration
# without requiring Power Platform authentication or backend configuration.

# Test: Validate Terraform configuration syntax
run "validate_terraform_syntax" {
  command = validate

  assert {
    condition = can(terraform.required_version)
    error_message = "Terraform version constraint must be accessible"
  }
}

# Test: Validate provider configuration structure
run "validate_provider_config" {
  command = validate

  assert {
    condition = can(terraform.required_providers.powerplatform)
    error_message = "Power Platform provider configuration must be accessible"
  }
}

# Test: File structure validation
run "validate_file_structure" {
  command = validate
  
  assert {
    condition = fileexists("${path.module}/main.tf")
    error_message = "main.tf file must exist in the module"
  }
}
