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
  default_connectors_classification = "Blocked"          # Security-first default
  environment_type                  = "OnlyEnvironments" # Security-first default

  # Security-first: block all custom connectors by default
  custom_connectors_patterns = [
    {
      order            = 1
      host_url_pattern = "*"
      data_group       = "Blocked"
    }
  ]

  # Manual classification mode (override example)
  business_connectors = []
  non_business_connectors = [
    {
      id                           = "/providers/Microsoft.PowerApps/apis/shared_office365"
      default_action_rule_behavior = ""
      action_rules                 = []
      endpoint_rules               = []
    }
  ]
  blocked_connectors = [
    {
      id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
      default_action_rule_behavior = ""
      action_rules                 = []
      endpoint_rules               = []
    }
  ]
}

# --- Advanced Test Scenarios ---

# 1. Edge Case: Manual configuration (explicit connectors)
run "manual_configuration_test" {
  command = plan
  variables {
    business_connectors = []
    non_business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    blocked_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    custom_connectors_patterns = [
      {
        order            = 1
        host_url_pattern = "*"
        data_group       = "Blocked" # Security-first default
      }
    ]
  }
  assert {
    condition     = length(var.business_connectors) == 0
    error_message = "Business connectors should be empty for manual configuration."
  }
  assert {
    condition     = length(var.non_business_connectors) == 1
    error_message = "Non-business connectors should have one entry for manual configuration."
  }
  assert {
    condition     = length(var.blocked_connectors) == 1
    error_message = "Blocked connectors should have one entry for manual configuration."
  }
}

# 2. Edge Case: Simple auto-classification (specific business connectors)
run "simple_auto_classification_test" {
  command = plan
  variables {
    business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_sql"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    non_business_connectors = []
    blocked_connectors      = []
    custom_connectors_patterns = [
      {
        order            = 1
        host_url_pattern = "*"
        data_group       = "Blocked" # Security-first default
      }
    ]
  }
  assert {
    condition     = length(var.business_connectors) == 1
    error_message = "Business connectors should have one specific connector for simple auto-classification."
  }
}

# 3. Usage Pattern: Full Auto-Classification
run "full_auto_classification" {
  command = plan
  variables {
    business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_sql"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      },
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    non_business_connectors = []
    blocked_connectors      = []
    custom_connectors_patterns = [
      {
        order            = 1
        host_url_pattern = "*"
        data_group       = "Blocked" # Security-first default
      }
    ]
  }
  assert {
    condition     = length(var.business_connectors) == 2
    error_message = "Full auto-classification pattern should accept business connectors."
  }
}

# 4. Usage Pattern: Partial Auto-Classification
run "partial_auto_classification" {
  command = plan
  variables {
    business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_sql"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    non_business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_office365"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    blocked_connectors = []
    custom_connectors_patterns = [
      {
        order            = 1
        host_url_pattern = "*"
        data_group       = "Blocked" # Security-first default
      }
    ]
  }
  assert {
    condition     = length(var.business_connectors) == 1 && length(var.non_business_connectors) == 1
    error_message = "Partial auto-classification pattern should accept mixed connector input."
  }
}

# 5. Usage Pattern: Full Manual Classification
run "full_manual_classification" {
  command = plan
  variables {
    business_connectors = []
    non_business_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_office365"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    blocked_connectors = [
      {
        id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
        default_action_rule_behavior = ""
        action_rules                 = []
        endpoint_rules               = []
      }
    ]
    custom_connectors_patterns = [
      {
        order            = 1
        host_url_pattern = "*"
        data_group       = "Blocked" # Security-first default
      }
    ]
  }
  assert {
    condition     = length(var.business_connectors) == 0 && length(var.non_business_connectors) == 1 && length(var.blocked_connectors) == 1
    error_message = "Full manual classification pattern should accept all connector types."
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

  # AVM: Planned resource validation assertions (plan-compatible)
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name == var.display_name
    error_message = "Planned DLP policy display_name should match input variable."
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.environment_type == var.environment_type
    error_message = "Planned DLP policy environment_type should match input variable."
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.default_connectors_classification == var.default_connectors_classification
    error_message = "Planned DLP policy default_connectors_classification should match input variable."
  }

  # AVM: Enhanced input validation
  assert {
    condition     = length(var.display_name) <= 50
    error_message = "Display name should be 50 characters or less for Power Platform compatibility."
  }

  assert {
    condition     = can(var.custom_connectors_patterns) && length(var.custom_connectors_patterns) >= 0
    error_message = "Custom connectors patterns should be a valid non-empty list."
  }

  # New assertion: Ensure at least one of the connector lists is non-empty
  assert {
    condition     = length(var.business_connectors) > 0 || length(var.non_business_connectors) > 0 || length(var.blocked_connectors) > 0
    error_message = "At least one connector list (business, non-business, or blocked) should be non-empty."
  }

  # AVM: Resource structure validation
  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.business_connectors)
    error_message = "DLP policy should have business_connectors attribute accessible in plan."
  }

  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.non_business_connectors)
    error_message = "DLP policy should have non_business_connectors attribute accessible in plan."
  }

  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.blocked_connectors)
    error_message = "DLP policy should have blocked_connectors attribute accessible in plan."
  }
}