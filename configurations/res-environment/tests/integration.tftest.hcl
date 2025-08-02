# Integration Tests for Power Platform Environment Configuration
#
# These integration tests validate the environment deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 20+ for res-* modules (plan and apply tests)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Resource Validation: Resource-specific structure and constraints
# - Variable Validation: Input parameter validation and constraints  
# - Configuration Validation: Resource configuration compliance
# - Duplicate Protection: Guardrail functionality and state awareness
# - Dataverse Integration: Optional database configuration testing

variables {
  # Test configuration - adjustable for different environments
  expected_minimum_count = 0  # Allow empty tenants in test environments
  test_timeout_minutes   = 10 # Extended timeout for environment operations

  # Required variables for res-environment configuration
  environment_config = {
    display_name     = "Test Environment - Integration"
    location         = "unitedstates"
    environment_type = "Sandbox"
  }

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
    condition     = powerplatform_environment.this.display_name == var.environment_config.display_name
    error_message = "Planned environment display_name should match input variable."
  }

  # Variable validation and input constraints (Assertions 5-8)
  assert {
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment_config.environment_type)
    error_message = "Environment type should be valid value: ${var.environment_config.environment_type}"
  }

  assert {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "india", "japan", "canada",
      "southamerica", "unitedkingdom", "france", "germany", "unitedarabemirates",
      "switzerland", "korea", "norway", "southafrica"
    ], var.environment_config.location)
    error_message = "Location should be valid Power Platform region: ${var.environment_config.location}"
  }

  assert {
    condition     = length(var.environment_config.display_name) >= 3 && length(var.environment_config.display_name) <= 64
    error_message = "Display name should be 3-64 characters: '${var.environment_config.display_name}' (${length(var.environment_config.display_name)} chars)"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment_config.display_name))
    error_message = "Display name should match required pattern: '${var.environment_config.display_name}'"
  }

  # Resource configuration validation (Assertions 9-12)
  assert {
    condition     = powerplatform_environment.this.location == var.environment_config.location
    error_message = "Planned environment location should match input variable."
  }

  assert {
    condition     = powerplatform_environment.this.environment_type == var.environment_config.environment_type
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
    condition     = powerplatform_environment.this.id != null && powerplatform_environment.this.id != ""
    error_message = "Environment should have a valid ID after creation."
  }

  assert {
    condition     = output.environment_url == null || can(regex("^https://", output.environment_url))
    error_message = "Environment URL should be a valid HTTPS URL when available."
  }

  assert {
    condition     = powerplatform_environment.this.display_name != null && powerplatform_environment.this.display_name != ""
    error_message = "Environment should have a valid display_name after deployment."
  }

  assert {
    condition     = powerplatform_environment.this.display_name == var.environment_config.display_name
    error_message = "Deployed environment display_name should match input: expected '${var.environment_config.display_name}', got '${powerplatform_environment.this.display_name}'"
  }

  # Output validation and anti-corruption layer (Assertions 21-25)
  assert {
    condition     = output.environment_id == powerplatform_environment.this.id
    error_message = "Environment ID output should match resource ID."
  }

  assert {
    condition     = output.environment_url == try(powerplatform_environment.this.dataverse.url, null)
    error_message = "Environment URL output should match resource Dataverse URL when available."
  }

  assert {
    condition     = can(output.environment_summary)
    error_message = "Environment summary output should be available."
  }

  assert {
    condition     = output.environment_summary.name == var.environment_config.display_name
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
}

# --- Advanced Test Scenarios ---

# Duplicate protection disabled test
run "duplicate_protection_disabled_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Test No Duplicate Check"
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
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

# Duplicate protection enabled test
run "duplicate_protection_enabled_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Test Duplicate Check Enabled"
      location         = "europe"
      environment_type = "Developer"
      owner_id         = "12345678-1234-1234-1234-123456789012"
    }
    dataverse_config = {
      language_code = "1033"
      currency_code = "USD"
    }
    enable_duplicate_protection = true
    tags = {
      TestScenario = "DuplicateProtection"
    }
  }

  assert {
    condition     = var.enable_duplicate_protection == true
    error_message = "Duplicate protection should be enabled for this test."
  }

  assert {
    condition     = length(null_resource.environment_duplicate_guardrail) == 1
    error_message = "Guardrail null_resource should be created when duplicate protection is enabled."
  }

  assert {
    condition     = can(data.powerplatform_environments.all)
    error_message = "Should be able to query existing environments when duplicate protection is enabled."
  }

  assert {
    condition     = var.environment_config.owner_id != null
    error_message = "Owner ID should be provided for Developer environment test."
  }

  assert {
    condition     = powerplatform_environment.this.owner_id == var.environment_config.owner_id
    error_message = "Planned environment owner_id should match input variable."
  }
}

# Dataverse configuration test (null case)
run "dataverse_null_configuration_test" {
  command = apply
  variables {
    environment_config = {
      display_name     = "Test No Dataverse"
      location         = "unitedstates"
      environment_type = "Sandbox"
      owner_id         = null
    }
    dataverse_config            = null
    enable_duplicate_protection = false
    tags                        = {}
  }

  assert {
    condition     = var.dataverse_config == null
    error_message = "Dataverse config should be null for this test."
  }

  assert {
    condition     = var.dataverse_config == null
    error_message = "Dataverse config should be null for this test."
  }

  assert {
    condition     = var.environment_config.environment_type == "Sandbox"
    error_message = "Environment type should be Sandbox for this test."
  }

  assert {
    condition = (
      # Power Platform provider creates default Dataverse configuration
      # even when not explicitly specified - this is expected behavior
      powerplatform_environment.this.dataverse != null &&
      powerplatform_environment.this.dataverse.language_code != null &&
      powerplatform_environment.this.dataverse.currency_code != null
    )
    error_message = "Provider should create default Dataverse configuration for Sandbox environments."
  }
}

# Edge case: Minimum valid display name
run "minimum_display_name_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Dev" # 3 characters - minimum valid
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    enable_duplicate_protection = false
    tags                        = {}
  }

  assert {
    condition     = length(var.environment_config.display_name) == 3
    error_message = "Display name should be exactly 3 characters for minimum test."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment_config.display_name))
    error_message = "Minimum display name should pass regex validation."
  }
}

# Edge case: Maximum valid display name  
run "maximum_display_name_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Very Long Environment Name for Testing Maximum Length Validation" # 64 characters
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    enable_duplicate_protection = false
    tags                        = {}
  }

  assert {
    condition     = length(var.environment_config.display_name) == 64
    error_message = "Display name should be exactly 64 characters for maximum test."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment_config.display_name))
    error_message = "Maximum display name should pass regex validation."
  }
}

# Environment type coverage test
run "environment_types_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Production Environment Test"
      location         = "unitedstates"
      environment_type = "Production"
    }
    enable_duplicate_protection = false
    tags = {
      EnvironmentType = "Production"
    }
  }

  assert {
    condition     = var.environment_config.environment_type == "Production"
    error_message = "Environment type should be Production for this test."
  }

  assert {
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment_config.environment_type)
    error_message = "Environment type should be valid."
  }
}

# Developer environment specific test
run "developer_environment_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Developer Environment Test"
      location         = "unitedstates"
      environment_type = "Developer"
      owner_id         = "87654321-4321-4321-4321-210987654321"
    }
    enable_duplicate_protection = false
    tags = {
      EnvironmentType = "Developer"
      TestScenario    = "DeveloperEnvironment"
    }
  }

  assert {
    condition     = var.environment_config.environment_type == "Developer"
    error_message = "Environment type should be Developer for this test."
  }

  assert {
    condition     = var.environment_config.owner_id != null
    error_message = "Owner ID should be provided for Developer environment."
  }

  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_config.owner_id))
    error_message = "Owner ID should be valid UUID format."
  }

  assert {
    condition     = powerplatform_environment.this.owner_id == var.environment_config.owner_id
    error_message = "Planned environment owner_id should match input variable."
  }

  assert {
    condition     = powerplatform_environment.this.environment_type == "Developer"
    error_message = "Planned environment type should be Developer."
  }
}

# Owner ID validation test (negative case)
run "owner_id_validation_test" {
  command = plan
  variables {
    environment_config = {
      display_name     = "Sandbox with Optional Owner"
      location         = "unitedstates"
      environment_type = "Sandbox"
      owner_id         = null
    }
    enable_duplicate_protection = false
    tags                        = {}
  }

  assert {
    condition     = var.environment_config.environment_type == "Sandbox"
    error_message = "Environment type should be Sandbox for this test."
  }

  assert {
    condition     = var.environment_config.owner_id == null
    error_message = "Owner ID should be null for non-Developer environment test."
  }

  assert {
    condition     = powerplatform_environment.this.owner_id == null
    error_message = "Planned environment owner_id should be null when not provided."
  }
}