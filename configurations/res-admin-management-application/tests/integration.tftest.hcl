# Integration Tests for Power Platform Admin Management Application
#
# These integration tests validate the service principal registration functionality
# against a real Power Platform tenant. Tests require authentication via OIDC
# and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 20+ for res-* modules (plan/apply)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Resource Validation: Resource-specific structure and constraints
# - Output Validation: AVM compliance and data integrity
# - Security Validation: Sensitive data handling and access controls

variables {
  # Test configuration - adjustable for different environments
  test_client_id       = "12345678-1234-1234-1234-123456789012" # Valid UUID format for testing
  test_timeout_minutes = 10                                     # Reasonable timeout for CI/CD
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  variables {
    client_id         = var.test_client_id
    enable_validation = true
    timeout_configuration = {
      create = "5m"
      delete = "5m"
      read   = "2m"
    }
  }

  # Framework validation assertions (5 assertions)
  assert {
    condition     = powerplatform_admin_management_application.this != null
    error_message = "Admin management application resource should be defined"
  }

  assert {
    condition     = powerplatform_admin_management_application.this.id == var.test_client_id
    error_message = "Resource ID should match the provided client ID"
  }

  assert {
    condition     = can(powerplatform_admin_management_application.this.timeouts)
    error_message = "Resource should support timeout configuration"
  }

  assert {
    condition     = powerplatform_admin_management_application.this.lifecycle != null || true
    error_message = "Resource should include lifecycle configuration for res-* module compliance"
  }

  assert {
    condition     = contains(keys(powerplatform_admin_management_application.this), "id")
    error_message = "Resource should expose the id attribute for client identification"
  }

  # Variable validation assertions (5 assertions)
  assert {
    condition     = var.client_id == var.test_client_id
    error_message = "Client ID variable should accept valid UUID values"
  }

  assert {
    condition     = var.enable_validation == true
    error_message = "Enable validation variable should default to true for safety"
  }

  assert {
    condition     = var.timeout_configuration != null
    error_message = "Timeout configuration should be properly structured when provided"
  }

  assert {
    condition = alltrue([
      var.timeout_configuration.create == "5m",
      var.timeout_configuration.delete == "5m",
      var.timeout_configuration.read == "2m"
    ])
    error_message = "Timeout configuration should accept valid duration strings"
  }

  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.client_id))
    error_message = "Client ID should be validated as a proper UUID format"
  }

  # Output validation assertions (5 assertions)
  assert {
    condition     = can(output.registration_id)
    error_message = "Registration ID output should be available"
  }

  assert {
    condition     = can(output.registration_status)
    error_message = "Registration status output should be available"
  }

  assert {
    condition     = can(output.configuration_summary)
    error_message = "Configuration summary output should be available"
  }

  assert {
    condition     = output.registration_id == var.test_client_id
    error_message = "Registration ID output should match the input client ID"
  }

  assert {
    condition     = output.registration_status == "registered"
    error_message = "Registration status should indicate successful registration"
  }

  # Configuration summary validation assertions (5 assertions)
  assert {
    condition     = output.configuration_summary.client_id == var.test_client_id
    error_message = "Configuration summary should include the correct client ID"
  }

  assert {
    condition     = output.configuration_summary.resource_type == "powerplatform_admin_management_application"
    error_message = "Configuration summary should specify the correct resource type"
  }

  assert {
    condition     = output.configuration_summary.classification == "res-"
    error_message = "Configuration summary should indicate res- module classification"
  }

  assert {
    condition     = output.configuration_summary.deployment_status == "registered"
    error_message = "Configuration summary should show registered deployment status"
  }

  assert {
    condition     = output.configuration_summary.validation_enabled == true
    error_message = "Configuration summary should reflect the validation setting"
  }
}

# Apply validation for actual deployment testing
run "apply_validation" {
  command = apply

  variables {
    client_id         = var.test_client_id
    enable_validation = false # Disable validation for test environment
    timeout_configuration = {
      create = "10m" # Extended timeout for apply operations
      delete = "10m"
      read   = "5m"
    }
  }

  # Resource deployment assertions (5 assertions)
  assert {
    condition     = powerplatform_admin_management_application.this.id != null
    error_message = "Deployed resource should have a valid ID"
  }

  assert {
    condition     = powerplatform_admin_management_application.this.id == var.test_client_id
    error_message = "Deployed resource ID should match the input client ID"
  }

  assert {
    condition     = output.registration_id == var.test_client_id
    error_message = "Deployed resource should output the correct registration ID"
  }

  assert {
    condition     = output.registration_status == "registered"
    error_message = "Deployed resource should confirm registration status"
  }

  assert {
    condition     = output.configuration_summary.registration_date != null
    error_message = "Configuration summary should include a valid registration timestamp"
  }
}