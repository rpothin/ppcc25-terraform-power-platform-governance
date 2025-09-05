# ==============================================================================
# OUTPUTS - ANTI-CORRUPTION LAYER FOR SEQUENTIAL DEPLOYMENT TEST
# ==============================================================================
# These outputs provide discrete access to test results and resource information
# without exposing full resource objects, following AVM TFFR2 compliance
# ==============================================================================

# Primary Resource Identifiers
output "test_environment_id" {
  description = "The unique identifier of the test Power Platform environment"
  value       = powerplatform_environment.test.id
}

output "test_environment_name" {
  description = "The display name of the test Power Platform environment"
  value       = powerplatform_environment.test.display_name
}

output "test_managed_environment_id" {
  description = "The unique identifier of the test managed environment configuration"
  value       = module.test_managed_environment.managed_environment_id
}

# Deployment Validation Outputs
output "environment_url" {
  description = "The web URL of the test Power Platform environment"
  value       = try(powerplatform_environment.test.dataverse.url, null)
}

output "environment_unique_name" {
  description = "The unique name (schema name) of the test environment"
  value       = try(powerplatform_environment.test.dataverse.unique_name, null)
}

output "dataverse_organization_id" {
  description = "The organization ID of the Dataverse instance in the test environment"
  value       = try(powerplatform_environment.test.dataverse.organization_id, null)
  sensitive   = true
}

# Test Execution Metadata
output "deployment_timestamp" {
  description = "The timestamp when the sequential deployment test was initiated"
  value       = local.deployment_metadata.initiated_at
}

output "test_configuration" {
  description = "Summary of the test configuration parameters"
  value = {
    test_name             = var.test_name
    location              = var.location
    comprehensive_logging = var.enable_comprehensive_logging
  }
}

# Validation Status
output "validation_checkpoints" {
  description = "Status indicators for key validation checkpoints in sequential deployment"
  value = {
    environment_created         = length(powerplatform_environment.test.id) > 0
    environment_id_valid_format = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_environment.test.id))
    managed_environment_enabled = length(module.test_managed_environment.managed_environment_id) > 0
    sequential_deployment_success = (
      length(powerplatform_environment.test.id) > 0 &&
      length(module.test_managed_environment.managed_environment_id) > 0
    )
  }
}

# Debugging Information
output "debug_information" {
  description = "Detailed debugging information for troubleshooting sequential deployment issues"
  value = var.enable_comprehensive_logging ? {
    resource_prefix           = local.resource_prefix
    environment_resource_type = "powerplatform_environment"
    managed_env_module_path   = "../res-managed-environment"
    dependency_chain = [
      "1. powerplatform_environment.test",
      "2. module.test_managed_environment"
    ]
  } : null
}

# Resource Summary for Cleanup
output "created_resources_summary" {
  description = "Summary of resources created during the test for cleanup reference"
  value = {
    environment = {
      id          = powerplatform_environment.test.id
      name        = powerplatform_environment.test.display_name
      unique_name = try(powerplatform_environment.test.dataverse.unique_name, null)
    }
    managed_environment = {
      id = module.test_managed_environment.managed_environment_id
    }
    test_metadata = {
      initiated_at  = local.deployment_metadata.initiated_at
      test_purpose  = local.deployment_metadata.test_purpose
      configuration = local.deployment_metadata.configuration
    }
  }
}
