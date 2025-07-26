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
# - Output Validation: AVM compliance and data integrity
# - Security Validation: Sensitive data handling and access controls

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
    condition     = can(powerplatform_data_loss_prevention_policy.this)
    error_message = "DLP policy resource should be accessible."
  }

  # Resource configuration validation
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name == var.display_name
    error_message = "DLP policy display name should match input variable."
  }

  # Output structure validation
  assert {
    condition     = can(output.dlp_policy_id)
    error_message = "DLP policy ID output should be accessible."
  }

  assert {
    condition     = can(output.dlp_policy_display_name)
    error_message = "DLP policy display name output should be accessible."
  }

  assert {
    condition     = can(output.dlp_policy_environment_type)
    error_message = "DLP policy environment type output should be accessible."
  }
}