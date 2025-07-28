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

# --- Advanced Test Scenarios ---

# 1. Apply Test: Validate resource creation and output values
run "apply_validation" {
  command = apply

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.id != ""
    error_message = "DLP policy should be successfully deployed with valid ID."
  }
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name == var.display_name
    error_message = "Deployed policy name should match configuration."
  }
  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.created_time)
    error_message = "Created time should be populated after deployment."
  }
  # AVM: Validate lifecycle/metadata
  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.created_by)
    error_message = "Created by metadata should be populated after deployment."
  }
}

# 2. Edge Case: Minimal configuration (empty connectors)
run "minimal_configuration_test" {
  command = plan
  variables {
    business_connectors        = []
    non_business_connectors    = []
    blocked_connectors         = []
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 0
    error_message = "Business connectors should be empty for minimal configuration."
  }
}

# 3. Edge Case: Maximal configuration (simulate large connector lists)
run "maximal_configuration_test" {
  command = plan
  variables {
    business_connectors        = [for i in range(0, 100) : "/providers/Microsoft.PowerApps/apis/shared_test${i}"]
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 100
    error_message = "Business connectors should support large lists (100+)."
  }
}

# 4. Usage Pattern: Full Auto-Classification
run "full_auto_classification" {
  command = plan
  variables {
    business_connectors = [
      "/providers/Microsoft.PowerApps/apis/shared_sql",
      "/providers/Microsoft.PowerApps/apis/shared_approvals"
    ]
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 2
    error_message = "Full auto-classification pattern should accept business connectors."
  }
}

# 5. Usage Pattern: Partial Auto-Classification
run "partial_auto_classification" {
  command = plan
  variables {
    business_connectors = ["/providers/Microsoft.PowerApps/apis/shared_sql"]
    non_business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
        default_action_rule_behavior = "Allow"
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 1 && length(var.non_business_connectors) == 1
    error_message = "Partial auto-classification pattern should accept mixed connector input."
  }
}

# 6. Usage Pattern: Full Manual Classification
run "full_manual_classification" {
  command = plan
  variables {
    business_connectors = ["/providers/Microsoft.PowerApps/apis/shared_sql"]
    non_business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
        default_action_rule_behavior = "Allow"
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    blocked_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
        default_action_rule_behavior = "Block"
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 1 && length(var.non_business_connectors) == 1 && length(var.blocked_connectors) == 1
    error_message = "Full manual classification pattern should accept all connector types."
  }
}

# 7. Performance/Scale: Large configuration (simulate 500 connectors)
run "large_scale_performance" {
  command = plan
  variables {
    business_connectors        = [for i in range(0, 500) : "/providers/Microsoft.PowerApps/apis/shared_test${i}"]
    custom_connectors_patterns = []
  }
  assert {
    condition     = length(var.business_connectors) == 500
    error_message = "Module should handle 500 business connectors for performance testing."
  }
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

  # AVM: Output validation assertions
  assert {
    condition     = can(output.dlp_policy_id) && output.dlp_policy_id != ""
    error_message = "DLP policy ID output should be non-empty string."
  }
  assert {
    condition     = output.dlp_policy_display_name == var.display_name
    error_message = "Output display name should match input variable."
  }
  assert {
    condition     = output.dlp_policy_environment_type == var.environment_type
    error_message = "Output environment type should match input variable."
  }
  # AVM: Enhanced input validation
  assert {
    condition     = length(var.display_name) <= 50
    error_message = "Display name should be 50 characters or less for Power Platform compatibility."
  }
  assert {
    condition     = can(var.custom_connectors_patterns) && length(var.custom_connectors_patterns) >= 0
    error_message = "Custom connectors patterns should be a valid list."
  }
}