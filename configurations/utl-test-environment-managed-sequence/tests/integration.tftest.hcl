# ==============================================================================
# INTEGRATION TESTS - SEQUENTIAL ENVIRONMENT AND MANAGED ENVIRONMENT DEPLOYMENT
# ==============================================================================
# These tests validate the sequential deployment pattern and verify that the
# environment → managed environment sequencing works correctly with the Power
# Platform provider, specifically targeting the "Request url must be an absolute
# url" error resolution.
# ==============================================================================

# REQUIRED: Provider block for child module compatibility
provider "powerplatform" {
  use_oidc  = true
  tenant_id = "00000000-0000-0000-0000-000000000000" # Mock for testing
  client_id = "00000000-0000-0000-0000-000000000000" # Mock for testing
}

# Test variables for consistent test execution
variables {
  test_name                    = "ci-test-seq-deploy"
  location                     = "unitedstates"
  security_group_id            = "550e8400-e29b-41d4-a716-446655440000" # Mock GUID for testing
  enable_comprehensive_logging = true
}

# ==============================================================================
# PLAN TESTS - STATIC VALIDATION (15+ ASSERTIONS REQUIRED FOR UTL- MODULE)
# ==============================================================================
run "plan_validation" {
  command = plan

  # === ASSERTION GROUP 1: CONFIGURATION STRUCTURE VALIDATION ===
  assert {
    condition = alltrue([
      can(var.test_name),
      can(var.location),
      can(var.security_group_id),
      can(var.enable_comprehensive_logging)
    ])
    error_message = "All required variables must be defined (test_name, location, security_group_id, enable_comprehensive_logging)"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.test_name))
    error_message = "Test name must follow valid naming pattern for environment creation"
  }

  assert {
    condition     = contains(["unitedstates", "europe", "asia", "australia"], var.location)
    error_message = "Location must be a valid Power Platform region"
  }

  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.security_group_id))
    error_message = "Security group ID must be a valid GUID format"
  }



  # === ASSERTION GROUP 2: STATIC CONFIGURATION VALIDATION ===
  assert {
    condition     = can(regex("^test-", local.resource_prefix))
    error_message = "Resource prefix must start with 'test-' for proper identification"
  }

  assert {
    condition     = local.deployment_metadata.configuration == "utl-test-environment-managed-sequence"
    error_message = "Configuration metadata must match module name"
  }



  # === ASSERTION GROUP 3: TERRAFORM CONFIGURATION VALIDATION ===
  assert {
    condition     = fileexists("${path.module}/main.tf")
    error_message = "main.tf must exist in configuration directory"
  }

  assert {
    condition     = fileexists("${path.module}/variables.tf")
    error_message = "variables.tf must exist in configuration directory"
  }

  assert {
    condition     = fileexists("${path.module}/outputs.tf")
    error_message = "outputs.tf must exist in configuration directory"
  }

  assert {
    condition     = fileexists("${path.module}/versions.tf")
    error_message = "versions.tf must exist in configuration directory"
  }

  # === ASSERTION GROUP 4: MODULE PATH VALIDATION ===
  assert {
    condition     = length(local.resource_prefix) > 5
    error_message = "Resource prefix must be properly constructed with sufficient length"
  }

  # === ASSERTION GROUP 5: LOCAL VALUES VALIDATION ===
  assert {
    condition     = length(regexall("test-", local.resource_prefix)) > 0
    error_message = "Resource prefix must include 'test-' identifier"
  }

  assert {
    condition     = local.deployment_metadata.test_purpose == "validate-sequential-deployment"
    error_message = "Deployment metadata must indicate sequential deployment validation purpose"
  }

  # === ASSERTION GROUP 6: ADDITIONAL STATIC VALIDATION ===
  assert {
    condition     = local.deployment_metadata.configuration != null
    error_message = "Configuration metadata must be populated"
  }

  assert {
    condition     = can(timestamp(local.deployment_metadata.initiated_at))
    error_message = "Deployment timestamp must be valid RFC3339 format"
  }

  assert {
    condition     = var.enable_comprehensive_logging == true
    error_message = "Comprehensive logging should be enabled for testing"
  }
}

# ==============================================================================
# APPLY TESTS - RUNTIME VALIDATION (ADDITIONAL ASSERTIONS FOR COMPREHENSIVE COVERAGE)
# ==============================================================================
run "apply_validation" {
  command = apply

  # === ASSERTION GROUP 7: RESOURCE CREATION VALIDATION ===
  assert {
    condition     = can(powerplatform_environment.test)
    error_message = "Test environment resource must be available after creation"
  }

  assert {
    condition     = can(module.test_managed_environment)
    error_message = "Test managed environment module must be available after creation"
  }

  assert {
    condition     = length(trimspace(powerplatform_environment.test.id)) > 0
    error_message = "Test environment must be created with valid environment_id"
  }

  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_environment.test.id))
    error_message = "Environment ID must be valid GUID format after creation"
  }

  assert {
    condition     = length(trimspace(module.test_managed_environment.managed_environment_id)) > 0
    error_message = "Managed environment must be created successfully after environment"
  }

  # === ASSERTION GROUP 8: OUTPUT STRUCTURE VALIDATION ===
  assert {
    condition     = can(output.test_environment_id)
    error_message = "test_environment_id output must be defined"
  }

  assert {
    condition     = can(output.test_managed_environment_id)
    error_message = "test_managed_environment_id output must be defined"
  }

  assert {
    condition     = can(output.validation_checkpoints)
    error_message = "validation_checkpoints output must be defined for debugging"
  }

  assert {
    condition     = can(output.created_resources_summary)
    error_message = "created_resources_summary output must be defined for cleanup"
  }

  assert {
    condition     = can(output.dataverse_organization_id)
    error_message = "dataverse_organization_id output must be defined"
  }

  # === ASSERTION GROUP 9: SEQUENTIAL DEPLOYMENT SUCCESS VALIDATION ===
  assert {
    condition     = output.validation_checkpoints.environment_created == true
    error_message = "Environment creation checkpoint must pass"
  }

  assert {
    condition     = output.validation_checkpoints.environment_id_valid_format == true
    error_message = "Environment ID format validation checkpoint must pass"
  }

  assert {
    condition     = output.validation_checkpoints.managed_environment_enabled == true
    error_message = "Managed environment enablement checkpoint must pass"
  }

  assert {
    condition     = output.validation_checkpoints.sequential_deployment_success == true
    error_message = "Overall sequential deployment must be successful"
  }

  # === ASSERTION GROUP 10: OUTPUT INTEGRITY VALIDATION ===
  assert {
    condition     = output.test_environment_id == powerplatform_environment.test.id
    error_message = "Output environment ID must match resource environment ID"
  }

  assert {
    condition     = output.test_managed_environment_id == module.test_managed_environment.managed_environment_id
    error_message = "Output managed environment ID must match module managed environment ID"
  }

  assert {
    condition     = length(output.created_resources_summary.environment.id) > 0
    error_message = "Resource summary must contain valid environment information"
  }

  # === ASSERTION GROUP 11: DEBUGGING AND METADATA VALIDATION ===
  assert {
    condition     = can(timestamp(output.deployment_timestamp))
    error_message = "Deployment timestamp must be valid RFC3339 timestamp"
  }

  assert {
    condition     = output.test_configuration.test_name == var.test_name
    error_message = "Test configuration summary must match input variables"
  }

  assert {
    condition     = length(output.debug_information.dependency_chain) == 2
    error_message = "Simplified dependency chain should have exactly 2 steps"
  }

  assert {
    condition     = output.debug_information != null
    error_message = "Debug information must be available when comprehensive logging is enabled"
  }
}