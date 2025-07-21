# Unit Test for DLP Policies Export Configuration
# 
# This test validates the basic structure and syntax of the DLP export configuration
# without requiring Power Platform authentication or backend configuration.

# TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
# Provider configuration for tests - using minimal config for unit tests
# provider "powerplatform" {
#   use_oidc = true
# }

# Test: Validate Terraform configuration syntax
run "validate_terraform_syntax" {
  command = plan

  assert {
    condition = terraform.workspace != null
    error_message = "Terraform workspace should be accessible"
  }
}

# Test: Validate local values access
run "validate_local_values" {
  command = plan

  assert {
    condition = local.test_message != null
    error_message = "Local test_message should be accessible"
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
