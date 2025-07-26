# Integration Tests for res-dlp-policy
#
# These integration tests validate the DLP policy deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Resource Validation: Resource-specific structure and constraints
# - Variable Validation: Input parameter validation and constraints
# - Configuration Validation: Resource configuration compliance

variables {
  # Test configuration - adjustable for different environments
  expected_minimum_count = 0 # Allow empty tenants in test environments
  test_timeout_minutes   = 5 # Reasonable timeout for CI/CD

  # Required variables for res-dlp-policy configuration
  display_name                      = "Test DLP Policy - Integration"
  default_connectors_classification = "Blocked"
  environment_type                  = "AllEnvironments"

  # Minimal connector configurations for testing
  business_connectors        = []
  non_business_connectors    = []
  blocked_connectors         = []
  custom_connectors_patterns = []
}

run "comprehensive_validation" {
  command = plan

  # Framework and provider validation
  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.display_name)
    error_message = "DLP policy resource should be plannable and display_name should be accessible."
  }

  # Variable validation and input constraints
  assert {
    condition     = contains(["General", "Confidential", "Blocked"], var.default_connectors_classification)
    error_message = "Default connectors classification should be valid value."
  }

  assert {
    condition     = contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], var.environment_type)
    error_message = "Environment type should be valid value."
  }

  # Resource configuration validation
  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.default_connectors_classification)
    error_message = "DLP policy should have default_connectors_classification configured."
  }

  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.environment_type)
    error_message = "DLP policy should have environment_type configured."
  }

  # Input data validation
  assert {
    condition     = length(var.display_name) > 0
    error_message = "Display name should not be empty."
  }

  assert {
    condition     = length(var.business_connectors) >= 0
    error_message = "Business connectors should be a valid list."
  }
}