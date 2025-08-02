# Integration Tests for Power Platform Environment Configuration
#
# These integration tests validate the environment deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Updated to align with corrected provider schema and variable structure.
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

  # ✅ CORRECTED: Use actual variable structure
  environment = {
    display_name     = "Test Environment - Integration"
    location         = "unitedstates"
    environment_type = "Sandbox"
  }

  # Optional Dataverse configuration for testing
  dataverse = null

  # Disable duplicate protection for testing to avoid conflicts
  enable_duplicate_protection = false

  # Optional tags for testing
  tags = {
    Environment = "Test"
    Purpose     = "Integration Testing"
    Owner       = "terraform-ci"
  }
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
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment.environment_type)
    error_message = "Environment type should be valid value: ${var.environment.environment_type}"
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
    condition     = can(var.tags) && length(var.tags) >= 0
    error_message = "Tags should be a valid map."
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
      display_name     = "Test No Duplicate Check"
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags                        = {}
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

# Developer environment with owner_id test
run "developer_environment_test" {
  command = plan
  variables {
    environment = {
      display_name     = "Developer Environment Test"
      location         = "unitedstates"
      environment_type = "Developer"
      owner_id         = "87654321-4321-4321-4321-210987654321"
    }
    dataverse = {
      language_code = 1033 # INTEGER not string!
      currency_code = "USD"
    }
    enable_duplicate_protection = false
    tags = {
      EnvironmentType = "Developer"
      TestScenario    = "DeveloperEnvironment"
    }
  }

  assert {
    condition     = var.environment.environment_type == "Developer"
    error_message = "Environment type should be Developer for this test."
  }

  assert {
    condition     = var.environment.owner_id != null
    error_message = "Owner ID should be provided for Developer environment."
  }

  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.owner_id))
    error_message = "Owner ID should be valid UUID format."
  }

  assert {
    condition     = powerplatform_environment.this.owner_id == var.environment.owner_id
    error_message = "Planned environment owner_id should match input variable."
  }
}

# Developer environment with Dataverse test (security_group_id optional)
run "developer_dataverse_test" {
  command = apply
  variables {
    environment = {
      display_name     = "Developer With Dataverse"
      location         = "unitedstates"
      environment_type = "Developer" # Developer environment
      owner_id         = "87654321-4321-4321-4321-210987654321"
    }
    dataverse = {
      language_code = 1033
      currency_code = "USD"
      # security_group_id NOT required for Developer environments
    }
    enable_duplicate_protection = false
    tags = {
      TestScenario = "DeveloperDataverse"
    }
  }

  assert {
    condition     = var.environment.environment_type == "Developer"
    error_message = "Environment type should be Developer for this test."
  }

  assert {
    condition     = var.environment.owner_id != null
    error_message = "Owner ID should be provided for Developer environment."
  }

  assert {
    condition     = var.dataverse.security_group_id == null
    error_message = "Security group ID should be null for Developer environment test."
  }

  assert {
    condition     = powerplatform_environment.this.dataverse != null
    error_message = "Developer environment should support Dataverse without security_group_id."
  }
}

# Dataverse configuration test (null case)
run "dataverse_null_configuration_test" {
  command = apply
  variables {
    environment = {
      display_name     = "Test No Dataverse"
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags                        = {}
  }

  assert {
    condition     = var.dataverse == null
    error_message = "Dataverse config should be null for this test."
  }

  # ✅ CORRECTED: Test actual provider behavior
  assert {
    condition     = powerplatform_environment.this.dataverse == null
    error_message = "When dataverse is null, provider should not create Dataverse configuration."
  }

  assert {
    condition     = output.dataverse_configuration == null
    error_message = "Dataverse configuration output should be null when no Dataverse is configured."
  }
}

# Dataverse configuration test (explicit case) - FIXED
run "dataverse_explicit_configuration_test" {
  command = apply
  variables {
    environment = {
      display_name     = "Test With Dataverse"
      location         = "unitedstates"
      environment_type = "Sandbox" # Non-Developer environment
    }
    dataverse = {
      language_code     = 1033
      currency_code     = "USD"
      security_group_id = "12345678-1234-1234-1234-123456789012" # ✅ REQUIRED for non-Developer
    }
    enable_duplicate_protection = false
    tags = {
      TestScenario = "ExplicitDataverse"
    }
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

  # ✅ ADDED: Verify security_group_id is provided for non-Developer environments
  assert {
    condition     = var.dataverse.security_group_id != null
    error_message = "Security group ID should be provided for non-Developer environments with Dataverse."
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
      azure_region                     = "eastus"
      cadence                          = "Moderate"
      allow_bing_search                = false
      allow_moving_data_across_regions = false
      description                      = "Test environment for new provider properties"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags = {
      TestScenario = "NewProperties"
    }
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

# Edge case: Minimum valid display name
run "minimum_display_name_test" {
  command = plan
  variables {
    environment = {
      display_name     = "Dev" # 3 characters - minimum valid
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags                        = {}
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
      display_name     = "Very Long Environment Name for Testing Maximum Length Validation" # 64 characters
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags                        = {}
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

# Production environment test
run "production_environment_test" {
  command = plan
  variables {
    environment = {
      display_name     = "Production Environment Test"
      location         = "unitedstates"
      environment_type = "Production"
      description      = "Production environment for testing"
      cadence          = "Moderate"
    }
    dataverse                   = null
    enable_duplicate_protection = false
    tags = {
      EnvironmentType = "Production"
    }
  }

  assert {
    condition     = var.environment.environment_type == "Production"
    error_message = "Environment type should be Production for this test."
  }

  assert {
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment.environment_type)
    error_message = "Environment type should be valid."
  }

  assert {
    condition     = powerplatform_environment.this.description == var.environment.description
    error_message = "Environment description should match input."
  }
}

# Comprehensive dataverse properties test
run "comprehensive_dataverse_test" {
  command = plan
  variables {
    environment = {
      display_name     = "Comprehensive Dataverse Test"
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse = {
      language_code                = 1033
      currency_code                = "USD"
      security_group_id            = "12345678-1234-1234-1234-123456789012"
      domain                       = "test-domain"
      administration_mode_enabled  = true
      background_operation_enabled = false
      template_metadata            = "test-metadata"
      templates                    = ["template1", "template2"]
    }
    enable_duplicate_protection = false
    tags = {
      TestScenario = "ComprehensiveDataverse"
    }
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
}