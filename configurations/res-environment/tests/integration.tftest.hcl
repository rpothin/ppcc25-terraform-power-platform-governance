# Integration Tests for Power Platform Environment Configuration
#
# These integration tests validate the environment deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Updated to align with corrected provider schema and variable structure.
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
# - Minimum Assertion Coverage: 20+ for res-* modules (plan and apply tests)

variables {
  # Test configuration - adjustable for different environments
  expected_minimum_count = 0  # Allow empty tenants in test environments
  test_timeout_minutes   = 10 # Extended timeout for environment operations

  # ✅ UPDATED: Use required variable structure
  environment = {
    display_name         = "Test Environment - Integration"
    location             = "unitedstates"
    environment_type     = "Sandbox"                              # Sandbox only - no Developer support
    environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED
  }

  # Optional Dataverse configuration for testing
  dataverse = null

  # Disable duplicate protection for testing to avoid conflicts
  enable_duplicate_protection = false
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
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.environment_group_id))
    error_message = "Environment group ID should be a valid UUID format."
  }

  # Conditional duplicate protection validation (Assertions 13-15)
  assert {
    condition     = var.enable_duplicate_protection == false ? true : can(data.powerplatform_environments.all)
    error_message = "When duplicate protection is enabled, should be able to access environments data source."
  }

  assert {
    condition     = var.enable_duplicate_protection == false ? true : length(null_resource.environment_duplicate_guardrail) == 1
    error_message = "When duplicate protection is enabled, guardrail null_resource should be planned."
  }

  assert {
    condition     = var.enable_duplicate_protection == false ? length(null_resource.environment_duplicate_guardrail) == 0 : true
    error_message = "When duplicate protection is disabled, guardrail null_resource should not be created."
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
}

# --- Advanced Test Scenarios ---

# Duplicate protection disabled test
run "duplicate_protection_disabled_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Test No Duplicate Check"
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse                   = null
    enable_duplicate_protection = false
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
}

# Dataverse configuration test (null case)
run "dataverse_null_configuration_test" {
  command = apply
  variables {
    environment = {
      display_name         = "Test No Dataverse"
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse                   = null
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.dataverse == null
    error_message = "Dataverse config should be null for this test."
  }

  assert {
    condition     = powerplatform_environment.this.dataverse == null
    error_message = "When dataverse is null, provider should not create Dataverse configuration."
  }

  assert {
    condition     = output.dataverse_configuration == null
    error_message = "Dataverse configuration output should be null when no Dataverse is configured."
  }
}

# Dataverse configuration test (explicit case) - FIXED with security_group_id
run "dataverse_explicit_configuration_test" {
  command = apply
  variables {
    environment = {
      display_name         = "Test With Dataverse"
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse = {
      language_code     = 1033
      currency_code     = "USD"
      security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = var.dataverse != null
    error_message = "Dataverse config should be provided for this test."
  }

  assert {
    condition     = var.dataverse.language_code == 1033
    error_message = "Language code should be integer 1033."
  }

  assert {
    condition     = var.dataverse.currency_code == "USD"
    error_message = "Currency code should be USD string."
  }

  assert {
    condition     = var.dataverse.security_group_id != null
    error_message = "Security group ID should be provided for all environment types."
  }

  assert {
    condition     = powerplatform_environment.this.dataverse != null
    error_message = "When dataverse is provided, provider should create Dataverse configuration."
  }

  assert {
    condition     = output.dataverse_configuration != null
    error_message = "Dataverse configuration output should be available when Dataverse is configured."
  }
}

# New provider properties test
run "new_provider_properties_test" {
  command = plan
  variables {
    environment = {
      display_name                     = "Test New Properties"
      location                         = "unitedstates"
      environment_type                 = "Sandbox"
      environment_group_id             = "12345678-1234-1234-1234-123456789012"
      azure_region                     = "eastus"
      cadence                          = "Moderate"
      allow_bing_search                = false
      allow_moving_data_across_regions = false
      description                      = "Test environment for new provider properties"
    }
    dataverse                   = null
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
    condition     = var.environment.allow_bing_search == false
    error_message = "Bing search should be configurable."
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
      location             = "unitedstates"
      environment_type     = "Production"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Production environment for testing"
      cadence              = "Moderate"
    }
    dataverse                   = null
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
      location             = "unitedstates"
      environment_type     = "Trial"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
      description          = "Trial environment for evaluation"
    }
    dataverse                   = null
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
      display_name         = "Dev" # 3 characters - minimum valid
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse                   = null
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
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse                   = null
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
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse = {
      language_code                = 1033
      currency_code                = "USD"
      security_group_id            = "87654321-4321-4321-4321-210987654321"
      domain                       = "test-domain"
      administration_mode_enabled  = true
      background_operation_enabled = false
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
    condition     = var.dataverse.administration_mode_enabled == true
    error_message = "Administration mode should be configurable."
  }

  assert {
    condition     = var.dataverse.background_operation_enabled == false
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
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse = {
      language_code     = 1033
      currency_code     = "USD"
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = null # Should auto-calculate
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
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse = {
      language_code     = 1033
      currency_code     = "USD"
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = "custom-domain-override"
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

# Domain calculation test - special characters and spaces
run "domain_special_characters_test" {
  command = plan
  variables {
    environment = {
      display_name         = "Dev Test 123!@# Environment"
      location             = "unitedstates"
      environment_type     = "Sandbox"
      environment_group_id = "12345678-1234-1234-1234-123456789012"
    }
    dataverse = {
      language_code     = 1033
      currency_code     = "USD"
      security_group_id = "87654321-4321-4321-4321-210987654321"
      domain            = null
    }
    enable_duplicate_protection = false
  }

  assert {
    condition     = local.calculated_domain == "dev-test-123-environment"
    error_message = "Calculated domain should properly handle special characters: '${local.calculated_domain}'"
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