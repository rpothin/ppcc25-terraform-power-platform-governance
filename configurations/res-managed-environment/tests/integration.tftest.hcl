# Integration Tests for Power Platform Managed Environment Configuration
#
# This test file provides comprehensive validation for the res-managed-environment module
# following AVM testing standards with Power Platform provider adaptations.
#
# Test Coverage:
# - Plan Phase: Static validation (file structure, variable types, resource configuration)
# - Apply Phase: Runtime validation (resource creation, outputs, integration)
# - Minimum 20 test assertions for res-* modules (AVM requirement)
# - Comprehensive validation across all configuration scenarios
#
# Test Categories:
# - Framework Validation: Core Terraform and provider functionality
# - Resource Configuration: Power Platform managed environment setup
# - Variable Integration: Input validation and transformation
# - Output Structure: Anti-corruption layer verification
# - Governance Controls: Sharing, validation, and onboarding configuration
# - Security Validation: Access controls and compliance features

# Provider block required for child module testing
provider "powerplatform" {
  use_oidc = true
}

variables {
  # Test configuration - production-ready example values
  test_environment_id = "7bd6b68b-e4a4-e058-aeb6-7f7820ba6ff5" # Test environment GUID

  # Custom configuration for testing overrides
  test_custom_sharing_settings = {
    is_group_sharing_disabled = true
    limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
    max_limit_user_sharing    = 10
  }

  test_custom_usage_insights_disabled = false # Override default to test customization

  test_custom_solution_checker = {
    mode                       = "Block"
    suppress_validation_emails = false
    rule_overrides             = ["meta-avoid-reg-no-attribute", "app-use-delayoutput-text-input"]
  }

  test_custom_maker_onboarding = {
    markdown_content = "## Welcome to Power Platform\n\nPlease follow our development guidelines."
    learn_more_url   = "https://docs.microsoft.com/power-platform"
  }
}

# ============================================================================
# PLAN PHASE TESTS - Static validation (design-time)
# ============================================================================

run "plan_validation" {
  command = plan

  variables {
    environment_id          = var.test_environment_id
    sharing_settings        = var.test_custom_sharing_settings
    usage_insights_disabled = var.test_custom_usage_insights_disabled
    solution_checker        = var.test_custom_solution_checker
    maker_onboarding        = var.test_custom_maker_onboarding
  }

  # Test Category: Framework Validation (5 assertions)
  assert {
    condition     = powerplatform_managed_environment.this.environment_id == var.test_environment_id
    error_message = "Managed environment should be linked to the correct environment ID"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_group_sharing_disabled == var.test_custom_sharing_settings.is_group_sharing_disabled
    error_message = "Group sharing setting should match input configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.limit_sharing_mode == var.test_custom_sharing_settings.limit_sharing_mode
    error_message = "Sharing mode should match input configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.max_limit_user_sharing == var.test_custom_sharing_settings.max_limit_user_sharing
    error_message = "User sharing limit should match input configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_usage_insights_disabled == var.test_custom_usage_insights_disabled
    error_message = "Usage insights setting should match input configuration"
  }

  # Test Category: Solution Checker Configuration (5 assertions)
  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_mode == var.test_custom_solution_checker.mode
    error_message = "Solution checker mode should match input configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.suppress_validation_emails == var.test_custom_solution_checker.suppress_validation_emails
    error_message = "Validation email setting should match input configuration"
  }

  assert {
    condition     = toset(powerplatform_managed_environment.this.solution_checker_rule_overrides) == toset(var.test_custom_solution_checker.rule_overrides)
    error_message = "Solution checker rule overrides should match input configuration (order-independent comparison)"
  }

  assert {
    condition     = powerplatform_managed_environment.this.maker_onboarding_markdown == var.test_custom_maker_onboarding.markdown_content
    error_message = "Maker onboarding markdown should match input configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.maker_onboarding_url == var.test_custom_maker_onboarding.learn_more_url
    error_message = "Maker onboarding URL should match input configuration"
  }

  # Test Category: File Structure Validation (5 assertions)
  assert {
    condition     = length(regexall("resource\\s+\"powerplatform_managed_environment\"\\s+\"this\"", file("${path.module}/main.tf"))) > 0
    error_message = "Configuration should define the main managed environment resource"
  }

  assert {
    condition     = length(regexall("lifecycle\\s*\\{", file("${path.module}/main.tf"))) > 0
    error_message = "Configuration should include lifecycle management for operational flexibility"
  }

  assert {
    condition     = length(regexall("variable\\s+\"environment_id\"", file("${path.module}/variables.tf"))) > 0
    error_message = "Configuration should define environment_id variable"
  }

  assert {
    condition     = length(regexall("variable\\s+\"sharing_settings\"", file("${path.module}/variables.tf"))) > 0
    error_message = "Configuration should define sharing_settings variable"
  }

  assert {
    condition     = length(regexall("variable\\s+\"solution_checker\"", file("${path.module}/variables.tf"))) > 0
    error_message = "Configuration should define solution_checker variable"
  }

  # Test Category: Output Structure Validation (5 assertions)
  assert {
    condition     = length(regexall("output\\s+\"managed_environment_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Configuration should define managed_environment_id output"
  }

  assert {
    condition     = length(regexall("output\\s+\"environment_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Configuration should define environment_id output"
  }

  assert {
    condition     = length(regexall("output\\s+\"managed_environment_summary\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Configuration should define managed_environment_summary output"
  }

  assert {
    condition     = length(regexall("output\\s+\"sharing_configuration\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Configuration should define sharing_configuration output"
  }

  assert {
    condition     = length(regexall("output\\s+\"solution_validation_status\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Configuration should define solution_validation_status output"
  }
}

# ============================================================================
# DEFAULT BEHAVIOR TESTS - Validate governance-friendly defaults
# ============================================================================

run "default_configuration_validation" {
  command = plan

  variables {
    environment_id = var.test_environment_id
    # All other variables use defaults
  }

  # Test Category: Default Values Validation (10 assertions)
  assert {
    condition     = powerplatform_managed_environment.this.is_group_sharing_disabled == false
    error_message = "Default should enable group sharing (governance best practice)"
  }

  assert {
    condition     = powerplatform_managed_environment.this.limit_sharing_mode == "NoLimit"
    error_message = "Default should allow unrestricted sharing with security groups"
  }

  assert {
    condition     = powerplatform_managed_environment.this.max_limit_user_sharing == -1
    error_message = "Default should set unlimited user sharing when group sharing enabled"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_usage_insights_disabled == true
    error_message = "Default should disable usage insights to avoid admin email spam"
  }

  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_mode == "Warn"
    error_message = "Default should use Warn mode for balanced governance approach"
  }

  assert {
    condition     = powerplatform_managed_environment.this.suppress_validation_emails == true
    error_message = "Default should suppress validation emails to reduce noise"
  }

  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_rule_overrides == null || length(powerplatform_managed_environment.this.solution_checker_rule_overrides) == 0
    error_message = "Default should not override any solution checker rules (expects null or empty set)"
  }

  assert {
    condition     = length(powerplatform_managed_environment.this.maker_onboarding_markdown) > 0
    error_message = "Default should provide basic maker onboarding content"
  }

  assert {
    condition     = can(regex("^https://", powerplatform_managed_environment.this.maker_onboarding_url))
    error_message = "Default should provide secure HTTPS URL for maker guidance"
  }

  assert {
    condition     = can(regex("^https://learn\\.microsoft\\.com/", powerplatform_managed_environment.this.maker_onboarding_url))
    error_message = "Default should link to official Microsoft documentation (learn.microsoft.com domain)"
  }
}

# ============================================================================
# APPLY PHASE TESTS - Runtime validation (deployment-time)
# ============================================================================

run "apply_validation" {
  command = apply

  variables {
    environment_id          = var.test_environment_id
    sharing_settings        = var.test_custom_sharing_settings
    usage_insights_disabled = var.test_custom_usage_insights_disabled
    solution_checker        = var.test_custom_solution_checker
    maker_onboarding        = var.test_custom_maker_onboarding
  }

  # Test Category: Runtime Resource Validation (5 assertions)
  assert {
    condition     = can(powerplatform_managed_environment.this.environment_id)
    error_message = "Managed environment resource should be created successfully"
  }

  assert {
    condition     = powerplatform_managed_environment.this.environment_id != null
    error_message = "Managed environment should have a valid environment ID"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_group_sharing_disabled != null
    error_message = "Managed environment should have sharing configuration applied"
  }

  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_mode != null
    error_message = "Managed environment should have solution checker configuration applied"
  }

  assert {
    condition     = powerplatform_managed_environment.this.maker_onboarding_markdown != null
    error_message = "Managed environment should have maker onboarding configuration applied"
  }

  # Test Category: Output Verification (5 assertions)
  assert {
    condition     = output.managed_environment_id == var.test_environment_id
    error_message = "Managed environment ID output should match input environment ID"
  }

  assert {
    condition     = output.environment_id == var.test_environment_id
    error_message = "Environment ID output should match input environment ID"
  }

  assert {
    condition     = can(output.managed_environment_summary.environment_id)
    error_message = "Managed environment summary should include environment ID"
  }

  assert {
    condition     = output.managed_environment_summary.classification == "res-*"
    error_message = "Managed environment summary should indicate correct module classification"
  }

  assert {
    condition     = output.managed_environment_summary.deployment_status == "deployed"
    error_message = "Managed environment summary should indicate successful deployment"
  }
}

# ============================================================================
# MINIMAL CONFIGURATION TEST - Validate that only environment_id is required
# ============================================================================

run "minimal_configuration_test" {
  command = plan

  variables {
    environment_id = var.test_environment_id
    # Test that all other variables are optional with sensible defaults
  }

  # Test Category: Minimal Configuration Validation (5 assertions)
  assert {
    condition     = powerplatform_managed_environment.this.environment_id == var.test_environment_id
    error_message = "Should work with only environment_id specified"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_group_sharing_disabled == false
    error_message = "Should use governance-friendly default for group sharing"
  }

  assert {
    condition     = powerplatform_managed_environment.this.is_usage_insights_disabled == true
    error_message = "Should use admin-friendly default for usage insights"
  }

  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_mode == "Warn"
    error_message = "Should use balanced default for solution checker mode"
  }

  assert {
    condition     = powerplatform_managed_environment.this.suppress_validation_emails == true
    error_message = "Should use noise-reducing default for validation emails"
  }
}

# ============================================================================
# MINIMAL CONFIGURATION APPLY TEST - Validate defaults work at runtime
# ============================================================================

run "minimal_configuration_apply_test" {
  command = apply

  variables {
    environment_id = var.test_environment_id
    # Test that all default values work during actual deployment
  }

  # Test Category: Runtime Minimal Configuration (5 assertions)
  assert {
    condition     = can(powerplatform_managed_environment.this.environment_id)
    error_message = "Managed environment should be created with minimal configuration"
  }

  assert {
    condition     = powerplatform_managed_environment.this.environment_id == var.test_environment_id
    error_message = "Applied environment ID should match input with minimal config"
  }

  assert {
    condition     = powerplatform_managed_environment.this.solution_checker_rule_overrides == null
    error_message = "Solution checker rule overrides should be null by default (matching API behavior)"
  }

  assert {
    condition     = output.managed_environment_id == var.test_environment_id
    error_message = "Output should work correctly with minimal configuration"
  }

  assert {
    condition     = output.managed_environment_summary.deployment_status == "deployed"
    error_message = "Deployment should succeed with only environment_id specified"
  }
}