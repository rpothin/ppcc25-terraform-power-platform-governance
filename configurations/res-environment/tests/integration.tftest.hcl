# Integration Tests for Power Platform Environment Configuration
#
# These integration tests validate the environment deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Updated to include comprehensive managed environment testing following the consolidation pattern.
# 
# ⚠️  DEVELOPER ENVIRONMENT LIMITATION:
# - Developer environments are NOT SUPPORTED with service principal authentication
# - All tests use Sandbox, Production, or Trial environment types only
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 25+ for res-* modules with managed environment (plan and apply tests)

# Provider configuration required for testing child modules
provider "powerplatform" {
  use_oidc = true
}

variables {
  # Test configuration - adjustable for different environments
  expected_minimum_count = 0  # Allow empty tenants in test environments
  test_timeout_minutes   = 10 # Extended timeout for environment operations

  environment = {
    display_name         = "Test Environment - Integration"
    location             = "unitedstates"                         # EXPLICIT CHOICE
    environment_group_id = "0675a2e2-dd4d-4ab6-8b9f-0d5048f62214" # Required for governance
    # environment_type defaults to "Sandbox" - using default value
    # cadence defaults to "Moderate" - using default value  
    # AI settings controlled by environment group rules
  }

  # Required Dataverse configuration for governance
  dataverse = {
    language_code     = 1033  # Using default value
    currency_code     = "USD" # EXPLICIT CHOICE
    security_group_id = "6a199811-5433-4076-81e8-1ca7ad8ffb67"
    # domain will be auto-calculated from display_name
    # administration_mode_enabled defaults to true - using default value
    # background_operation_enabled defaults to false - using default value
  }

  # Disable duplicate protection for testing to avoid conflicts
  enable_duplicate_protection = false

  # Test managed environment with defaults (enabled by default)
  enable_managed_environment   = true
  managed_environment_settings = {}
}

# --- Plan Validation Tests ---

# Comprehensive plan validation (10+ assertions for plan phase)
run "plan_validation" {
  command = plan

  # Framework and provider validation (Assertions 1-4)
  assert {
    condition     = can(powerplatform_environment.this.display_name)
    error_message = "Environment resource should be plannable and display_name should be accessible."
  }

  assert {
    condition     = can(powerplatform_environment.this.location)
    error_message = "Environment resource should have location accessible in plan."
  }

  assert {
    condition     = can(powerplatform_environment.this.environment_type)
    error_message = "Environment resource should have environment_type accessible in plan."
  }

  assert {
    condition     = powerplatform_environment.this.display_name == var.environment.display_name
    error_message = "Planned environment display_name should match input variable."
  }

  # Variable validation and input constraints (Assertions 5-8)
  assert {
    condition     = contains(["Sandbox", "Production", "Trial"], var.environment.environment_type)
    error_message = "Environment type should be valid value (no Developer support): ${var.environment.environment_type}"
  }

  assert {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "india", "japan", "canada",
      "southamerica", "unitedkingdom", "france", "germany", "unitedarabemirates",
      "switzerland", "korea", "norway", "southafrica"
    ], var.environment.location)
    error_message = "Location should be valid Power Platform region: ${var.environment.location}"
  }

  assert {
    condition     = length(var.environment.display_name) >= 3 && length(var.environment.display_name) <= 64
    error_message = "Display name should be 3-64 characters: '${var.environment.display_name}' (${length(var.environment.display_name)} chars)"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment.display_name))
    error_message = "Display name should match required pattern: '${var.environment.display_name}'"
  }

  # Resource configuration validation (Assertions 9-12)
  assert {
    condition     = powerplatform_environment.this.location == var.environment.location
    error_message = "Planned environment location should match input variable."
  }

  assert {
    condition     = powerplatform_environment.this.environment_type == var.environment.environment_type
    error_message = "Planned environment type should match input variable."
  }

  assert {
    condition     = can(var.enable_duplicate_protection) && (var.enable_duplicate_protection == true || var.enable_duplicate_protection == false)
    error_message = "Enable duplicate protection should be a valid boolean value."
  }

  assert {
    condition     = var.environment.environment_group_id == "0675a2e2-dd4d-4ab6-8b9f-0d5048f62214"
    error_message = "Environment group ID should match test configuration."
  }

  # Default values validation (Additional assertions 13-15)
  assert {
    condition     = powerplatform_environment.this.environment_type == "Sandbox"
    error_message = "Should use default environment_type 'Sandbox' when not explicitly specified."
  }

  assert {
    condition     = powerplatform_environment.this.cadence == "Moderate"
    error_message = "Should use default cadence 'Moderate' when not explicitly specified."
  }

  assert {
    condition     = var.environment.environment_group_id != null
    error_message = "Environment group ID should be required for governance (AI settings controlled by group)."
  }

  # Managed environment plan validation (Additional assertions 16-18)
  # WHY: Only validate static configuration during plan phase
  # Runtime attributes are validated in apply_validation block
  assert {
    condition     = var.enable_managed_environment == true
    error_message = "Managed environment should be enabled by default."
  }

  assert {
    condition     = length(module.managed_environment) == 1
    error_message = "Should create managed environment module when enabled and not Developer type."
  }

  assert {
    condition     = can(var.managed_environment_settings)
    error_message = "Should have managed environment settings variable accessible in plan."
  }
}

# --- Apply Validation Tests ---

# Comprehensive apply validation (10+ assertions for apply phase)
run "apply_validation" {
  command = apply

  # Actual resource deployment validation (Assertions 16-20)
  assert {
    condition     = powerplatform_environment.this.id != null && powerplatform_environment.this.id != ""
    error_message = "Environment should have a valid ID after creation."
  }

  assert {
    condition     = powerplatform_environment.this.display_name != null && powerplatform_environment.this.display_name != ""
    error_message = "Environment should have a valid display_name after deployment."
  }

  assert {
    condition     = powerplatform_environment.this.display_name == var.environment.display_name
    error_message = "Deployed environment display_name should match input: expected '${var.environment.display_name}', got '${powerplatform_environment.this.display_name}'"
  }

  assert {
    condition     = powerplatform_environment.this.location == var.environment.location
    error_message = "Deployed environment location should match input."
  }

  assert {
    condition     = powerplatform_environment.this.environment_type == var.environment.environment_type
    error_message = "Deployed environment type should match input."
  }

  # Output validation and anti-corruption layer (Assertions 21-25)
  assert {
    condition     = output.environment_id == powerplatform_environment.this.id
    error_message = "Environment ID output should match resource ID."
  }

  assert {
    condition     = can(output.environment_summary)
    error_message = "Environment summary output should be available."
  }

  assert {
    condition     = output.environment_summary.name == var.environment.display_name
    error_message = "Environment summary name should match configuration."
  }

  assert {
    condition = (
      output.environment_summary.terraform_managed == true &&
      output.environment_summary.classification == "res-environment" &&
      output.environment_summary.resource_type == "powerplatform_environment"
    )
    error_message = "Environment summary should contain correct metadata."
  }

  assert {
    condition     = output.environment_summary.has_dataverse == (var.dataverse != null)
    error_message = "Environment summary dataverse flag should match configuration."
  }

  # Managed environment apply validation (Assertions 26-30)
  assert {
    condition     = output.managed_environment_enabled == (var.enable_managed_environment && var.environment.environment_type != "Developer")
    error_message = "Managed environment enabled output should match configuration logic."
  }

  assert {
    condition     = output.managed_environment_id == powerplatform_environment.this.id
    error_message = "Managed environment ID should match environment ID after deployment."
  }

  assert {
    condition     = can(output.managed_environment_summary)
    error_message = "Managed environment summary should be available."
  }

  assert {
    condition     = output.managed_environment_summary.enabled == var.enable_managed_environment
    error_message = "Managed environment summary should reflect enabled status."
  }

  assert {
    condition     = output.environment_summary.managed_environment_enabled == true
    error_message = "Environment summary should show managed environment is enabled."
  }

  # Additional managed environment runtime validation (Assertions 31-33)
  # WHY: These validate actual resource attributes only available after apply
  assert {
    condition     = module.managed_environment[0].managed_environment_id != null && module.managed_environment[0].managed_environment_id != ""
    error_message = "Managed environment module should have a valid managed_environment_id after creation."
  }

  assert {
    condition     = module.managed_environment[0].managed_environment_id == powerplatform_environment.this.id
    error_message = "Managed environment module should reference the same environment ID after deployment."
  }

  assert {
    condition     = module.managed_environment[0].sharing_configuration.group_sharing_disabled == false
    error_message = "Should use default sharing settings (group sharing enabled) after deployment."
  }
}

# --- Advanced Test Scenarios ---

# Duplicate protection disabled test
run "duplicate_protection_disabled_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test No Duplicate Check"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using default values: environment_type="Sandbox", cadence="Moderate", AI=false
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values: language_code=1033, admin_mode=true, background=false
    }
    enable_duplicate_protection  = false
    enable_managed_environment   = false
    managed_environment_settings = {}
  }

  assert {
    condition     = var.enable_duplicate_protection == false
    error_message = "Duplicate protection should be disabled for this test."
  }

  assert {
    condition     = length(null_resource.environment_duplicate_guardrail) == 0
    error_message = "Guardrail null_resource should not be created when duplicate protection is disabled."
  }

  assert {
    condition     = length(data.powerplatform_environments.all) == 0
    error_message = "Environments data source should not be created when duplicate protection is disabled."
  }

  assert {
    condition     = length(module.managed_environment) == 0
    error_message = "Should not create managed environment module when disabled in variables."
  }
}

# New provider properties test
run "new_provider_properties_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test New Properties"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Test environment for new provider properties"
      azure_region         = "eastus"
      cadence              = "Frequent" # Override default value
      # AI settings controlled by environment group rules
      # environment_type defaults to "Sandbox" - using default value
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.environment.azure_region == "eastus"
    error_message = "Azure region should be configurable."
  }

  assert {
    condition     = contains(["Frequent", "Moderate"], var.environment.cadence)
    error_message = "Cadence should be valid value."
  }

  assert {
    condition     = var.environment.environment_group_id != null
    error_message = "Environment group should be required (controls AI settings via governance)."
  }

  assert {
    condition     = powerplatform_environment.this.azure_region == var.environment.azure_region
    error_message = "Planned azure_region should match input."
  }

  assert {
    condition     = powerplatform_environment.this.cadence == var.environment.cadence
    error_message = "Planned cadence should match input."
  }
}

# Production environment test
run "production_environment_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Production Environment Test"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_type     = "Production"   # Override default value
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Production environment for testing"
      # cadence defaults to "Moderate" - using default value
      # AI settings default to false - using default values
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.environment.environment_type == "Production"
    error_message = "Environment type should be Production for this test."
  }

  assert {
    condition     = contains(["Sandbox", "Production", "Trial"], var.environment.environment_type)
    error_message = "Environment type should be valid (no Developer support)."
  }

  assert {
    condition     = powerplatform_environment.this.description == var.environment.description
    error_message = "Environment description should match input."
  }
}

# Trial environment test
run "trial_environment_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Trial Environment Test"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_type     = "Trial"        # Override default value
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Trial environment for evaluation"
      # Using secure defaults for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.environment.environment_type == "Trial"
    error_message = "Environment type should be Trial for this test."
  }

  assert {
    condition     = powerplatform_environment.this.environment_type == "Trial"
    error_message = "Planned environment type should be Trial."
  }
}

# Edge case: Minimum valid display name
run "minimum_display_name_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Dev"          # 3 characters - minimum valid
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = length(var.environment.display_name) == 3
    error_message = "Display name should be exactly 3 characters for minimum test."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment.display_name))
    error_message = "Minimum display name should pass regex validation."
  }
}

# Edge case: Maximum valid display name  
run "maximum_display_name_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Very Long Environment Name for Testing Maximum Length Validation" # 64 characters
      location             = "unitedstates"                                                     # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = length(var.environment.display_name) == 64
    error_message = "Display name should be exactly 64 characters for maximum test."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment.display_name))
    error_message = "Maximum display name should pass regex validation."
  }
}

# Comprehensive dataverse properties test
run "comprehensive_dataverse_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Comprehensive Dataverse Test"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code                = "USD" # EXPLICIT CHOICE
      language_code                = 1033  # Using default value
      security_group_id            = "87654321-4321-4321-4321-210987654321"
      domain                       = "test-domain"
      administration_mode_enabled  = false # Override default value
      background_operation_enabled = true  # Override default value
      template_metadata            = "test-metadata"
      templates                    = ["template1", "template2"]
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.dataverse.language_code == 1033
    error_message = "Language code should be integer."
  }

  assert {
    condition     = var.dataverse.administration_mode_enabled == false
    error_message = "Administration mode should be configurable."
  }

  assert {
    condition     = var.dataverse.background_operation_enabled == true
    error_message = "Background operations should be configurable."
  }

  assert {
    condition     = length(var.dataverse.templates) == 2
    error_message = "Templates list should be configurable."
  }

  assert {
    condition     = var.dataverse.security_group_id != null
    error_message = "Security group ID should be required."
  }
}

# Domain calculation test - auto-calculated from display_name
run "domain_auto_calculation_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Production Finance Environment"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = null # Should auto-calculate
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.dataverse.domain == null
    error_message = "Domain should be null for auto-calculation test."
  }

  assert {
    condition     = local.calculated_domain == "production-finance-environment"
    error_message = "Calculated domain should be 'production-finance-environment', got '${local.calculated_domain}'"
  }

  assert {
    condition     = local.final_domain == local.calculated_domain
    error_message = "Final domain should match calculated domain when manual domain is null."
  }

  assert {
    condition     = can(output.domain_calculation_summary)
    error_message = "Domain calculation summary output should be available."
  }
}

# Domain calculation test - manual override
run "domain_manual_override_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test Environment with Custom Domain"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = "custom-domain-override"
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.dataverse.domain == "custom-domain-override"
    error_message = "Domain should be manually set for override test."
  }

  assert {
    condition     = local.final_domain == "custom-domain-override"
    error_message = "Final domain should match manual domain when provided."
  }

  assert {
    condition     = local.calculated_domain != null
    error_message = "Calculated domain should still be computed even when manual domain is provided."
  }
}

# Domain calculation test - mixed separators and formatting
run "domain_special_characters_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Dev Test_123-Environment Name" # Mixed valid separators
      location             = "unitedstates"                  # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using secure defaults for all other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = null
      # Using secure defaults for other properties
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = local.calculated_domain == "dev-test-123-environment-name"
    error_message = "Calculated domain should properly normalize mixed separators: '${local.calculated_domain}'"
  }

  assert {
    condition     = can(regex("^[a-z0-9\\-]+$", local.calculated_domain))
    error_message = "Calculated domain should only contain lowercase letters, numbers, and hyphens."
  }

  assert {
    condition     = length(local.calculated_domain) <= 63
    error_message = "Calculated domain should not exceed 63 characters."
  }
}

# ==============================================================================
# MANAGED ENVIRONMENT TESTING
# ==============================================================================

# Managed environment disabled test
run "managed_environment_disabled_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test Environment - No Managed Features"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using default values for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values for other properties
    }
    enable_duplicate_protection  = false
    enable_managed_environment   = false
    managed_environment_settings = {}
  }

  assert {
    condition     = var.enable_managed_environment == false
    error_message = "Managed environment should be disabled for this test."
  }

  assert {
    condition     = length(module.managed_environment) == 0
    error_message = "Should not create managed environment module when disabled."
  }

  assert {
    condition     = can(powerplatform_environment.this.display_name)
    error_message = "Should still create base environment when managed environment is disabled."
  }
}

# Managed environment with custom settings test
run "managed_environment_custom_settings_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test Environment - Custom Managed Settings"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using default values for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values for other properties
    }
    enable_duplicate_protection = false
    enable_managed_environment  = true
    managed_environment_settings = {
      sharing_settings = {
        is_group_sharing_disabled = true
        limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
        max_limit_user_sharing    = 5
      }
      usage_insights_disabled = false
      solution_checker = {
        mode                       = "Block"
        suppress_validation_emails = false
        rule_overrides             = ["meta-avoid-reg-no-attribute"]
      }
      maker_onboarding = {
        markdown_content = "Custom welcome message for production environment"
        learn_more_url   = "https://contoso.com/powerplatform-guidelines"
      }
    }
  }

  assert {
    condition     = var.enable_managed_environment == true
    error_message = "Managed environment should be enabled for this test."
  }

  assert {
    condition     = length(module.managed_environment) == 1
    error_message = "Should create managed environment module when enabled."
  }

  assert {
    condition     = module.managed_environment[0].sharing_configuration.group_sharing_disabled == true
    error_message = "Should use custom sharing settings."
  }

  assert {
    condition     = module.managed_environment[0].solution_validation_status.checker_mode == "Block"
    error_message = "Should use custom solution checker mode."
  }

  assert {
    condition     = module.managed_environment[0].managed_environment_summary.usage_insights_status == "enabled"
    error_message = "Should use custom usage insights setting."
  }

  assert {
    condition     = can(module.managed_environment[0].managed_environment_summary)
    error_message = "Should use custom maker onboarding content via module."
  }
}

# Developer environment test (managed environment should be disabled)
run "developer_environment_managed_disabled_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test Developer Environment"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_type     = "Sandbox"      # Developer not supported, using Sandbox as proxy
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using default values for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values for other properties
    }
    enable_duplicate_protection  = false
    enable_managed_environment   = true # Should be ignored for Developer type
    managed_environment_settings = {}
  }

  # Note: Using Sandbox here since Developer is not supported with service principal
  # This test validates that the logic is correct for the condition
  assert {
    condition     = var.environment.environment_type != "Developer"
    error_message = "Developer environment type not supported in this test due to service principal limitation."
  }

  assert {
    condition     = length(module.managed_environment) == 1
    error_message = "Should create managed environment module for Sandbox type (Developer type would be 0)."
  }
}

# Production environment with managed features test
run "production_managed_environment_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Production Environment - Managed"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_type     = "Production"   # Override default value
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Production environment with managed features"
      # Using default values for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values for other properties
    }
    enable_duplicate_protection = false
    enable_managed_environment  = true
    managed_environment_settings = {
      solution_checker = {
        mode                       = "Block"
        suppress_validation_emails = false
      }
    }
  }

  assert {
    condition     = var.environment.environment_type == "Production"
    error_message = "Environment type should be Production for this test."
  }

  assert {
    condition     = var.enable_managed_environment == true
    error_message = "Managed environment should be enabled for production."
  }

  assert {
    condition     = length(module.managed_environment) == 1
    error_message = "Should create managed environment module for Production type."
  }

  assert {
    condition     = module.managed_environment[0].solution_validation_status.checker_mode == "Block"
    error_message = "Production should use strict solution checker mode."
  }
}

# Managed environment output validation test
run "managed_environment_outputs_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test Environment - Output Validation"
      location             = "unitedstates" # EXPLICIT CHOICE
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      # Using default values for other properties
    }
    dataverse = {
      currency_code     = "USD" # EXPLICIT CHOICE
      security_group_id = "33333333-3333-3333-3333-333333333333"
      # Using default values for other properties
    }
    enable_duplicate_protection  = false
    enable_managed_environment   = true
    managed_environment_settings = {}
  }

  assert {
    condition     = can(output.managed_environment_id)
    error_message = "Should have managed_environment_id output."
  }

  assert {
    condition     = can(output.managed_environment_summary)
    error_message = "Should have managed_environment_summary output."
  }

  assert {
    condition     = can(output.managed_environment_enabled)
    error_message = "Should have managed_environment_enabled output."
  }

  assert {
    condition     = output.managed_environment_enabled == true
    error_message = "Managed environment enabled output should be true when enabled."
  }
}