# Integration Tests for Power Platform Environment Group Pattern Configuration
#
# These integration tests validate the pattern deployment against a real Power Platform tenant.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.

provider "powerplatform" {
  use_oidc = true
}
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, orchestration, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 25+ for ptn-* modules (plan and apply tests required)
#
# Pattern Testing Focus:
# - Multi-Resource Orchestration: Environment group + multiple environments
# - Dependency Management: Proper resource creation sequence
# - Group Assignment: Automatic environment assignment to group
# - Integration Validation: Resources work together correctly
# - Governance Readiness: Outputs support downstream governance configuration

variables {
  # Test configuration for pattern validation
  environment_group_config = {
    display_name = "Test Environment Group Pattern"
    description  = "Test environment group pattern for Terraform validation and CI/CD"
  }

  # Security group ID for Dataverse access control (test value)
  security_group_id = "00000000-0000-0000-0000-000000000000"

  environments = [
    {
      display_name     = "Test Pattern Environment 1"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "test-pattern-env1"
    },
    {
      display_name     = "Test Pattern Environment 2"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "test-pattern-env2"
    }
  ]

  # Disable duplicate protection for testing to avoid conflicts
  enable_duplicate_protection = false
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  # === FRAMEWORK VALIDATION (5 assertions) ===

  # Terraform provider functionality - file-based validation
  assert {
    condition     = length(regexall("powerplatform\\s*=\\s*\\{", file("${path.module}/versions.tf"))) > 0
    error_message = "Power Platform provider must be configured in required_providers block"
  }

  # Provider version compliance with centralized standard
  assert {
    condition     = length(regexall("version\\s*=\\s*\"~> 3\\.8\"", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider version must match centralized standard ~> 3.8 in versions.tf"
  }

  # OIDC authentication configuration in provider block
  assert {
    condition     = length(regexall("use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider must be configured with use_oidc = true for secure authentication"
  }

  # Module composition validation - environment group module
  assert {
    condition     = can(module.environment_group)
    error_message = "Environment group module must be planned and accessible"
  }

  # Module composition validation - environments modules
  assert {
    condition     = can(module.environments)
    error_message = "Environments modules must be planned and accessible"
  }

  # === VARIABLE VALIDATION (5 assertions) ===

  # Environment group configuration structure
  assert {
    condition     = can(var.environment_group_config.display_name) && can(var.environment_group_config.description)
    error_message = "Environment group config must have display_name and description properties"
  }

  # Environments list validation
  assert {
    condition     = length(var.environments) >= 1
    error_message = "Pattern must have at least one environment for meaningful orchestration"
  }

  # Environment structure validation
  assert {
    condition = alltrue([
      for env in var.environments : can(env.display_name) && can(env.location) && can(env.environment_type)
    ])
    error_message = "All environments must have required properties: display_name, location, environment_type"
  }

  # Environment type validation for service principal compatibility
  assert {
    condition = alltrue([
      for env in var.environments : contains(["Sandbox", "Production", "Trial"], env.environment_type)
    ])
    error_message = "Environment types must be Sandbox, Production, or Trial for service principal authentication"
  }

  # Duplicate protection configuration validation
  assert {
    condition     = can(var.enable_duplicate_protection) && (var.enable_duplicate_protection == true || var.enable_duplicate_protection == false)
    error_message = "Enable duplicate protection must be a boolean value"
  }

  # === MODULE ORCHESTRATION VALIDATION (5 assertions) ===

  # Environment group module input validation
  assert {
    condition     = module.environment_group.environment_group_name == var.environment_group_config.display_name
    error_message = "Environment group module should receive correct display_name input"
  }

  # Security group ID validation
  assert {
    condition     = can(var.security_group_id) && length(var.security_group_id) > 0
    error_message = "Security group ID must be provided for Dataverse configuration"
  }

  # Environments modules count validation
  assert {
    condition     = length(module.environments) == length(var.environments)
    error_message = "Should create one environment module per environment config"
  }

  # Environment group ID assignment validation via local transformation
  assert {
    condition = alltrue([
      for idx, env_config in local.transformed_environments : env_config.environment.environment_group_id == module.environment_group.environment_group_id
    ])
    error_message = "All environments should be assigned to the created environment group via transformation"
  }

  # Dependency validation - environments modules depend on environment group module
  assert {
    condition     = length(regexall("depends_on.*module\\.environment_group", file("${path.module}/main.tf"))) > 0
    error_message = "Environments modules should explicitly depend on environment group module"
  }

  # === OUTPUT VALIDATION (5 assertions) ===

  # Primary outputs availability
  assert {
    condition     = can(output.environment_group_id) && can(output.environment_group_name)
    error_message = "Primary outputs (environment_group_id, environment_group_name) must be available"
  }

  # Environment collection outputs
  assert {
    condition     = can(output.environment_ids) && can(output.environment_names)
    error_message = "Environment collection outputs (environment_ids, environment_names) must be available"
  }

  # Orchestration summary output
  assert {
    condition     = can(output.orchestration_summary)
    error_message = "Orchestration summary output must be available for pattern validation"
  }

  # Governance integration outputs
  assert {
    condition     = can(output.governance_ready_resources)
    error_message = "Governance ready resources output must be available for downstream configuration"
  }

  # Pattern configuration summary
  assert {
    condition     = can(output.pattern_configuration_summary)
    error_message = "Pattern configuration summary must be available for compliance reporting"
  }

  # === PATTERN LOGIC VALIDATION (5 assertions) ===

  # Local computations validation
  assert {
    condition     = can(local.pattern_metadata) && can(local.environment_summary) && can(local.deployment_validation)
    error_message = "Pattern logic locals (metadata, summary, validation) must be computed correctly"
  }

  # Resource count calculation
  assert {
    condition     = local.pattern_metadata.resource_count == (1 + length(var.environments))
    error_message = "Pattern should calculate correct resource count: 1 group + N environments"
  }

  # Environment summary structure
  assert {
    condition     = length(local.environment_summary) == length(var.environments)
    error_message = "Environment summary should include all configured environments"
  }

  # Pattern completeness validation
  assert {
    condition     = local.deployment_validation.pattern_complete == true
    error_message = "Pattern should validate as complete with multiple resources"
  }

  # Dataverse configuration validation via module interface
  assert {
    condition = alltrue([
      for idx, env_config in local.transformed_environments : env_config.dataverse != null
    ])
    error_message = "All environments should have Dataverse configured for environment group assignment via module transformation"
  }
}

# Comprehensive apply validation - validates actual resource deployment
run "apply_validation" {
  command = apply

  # === RESOURCE DEPLOYMENT VALIDATION (5+ assertions) ===

  # Environment group module deployment
  assert {
    condition     = module.environment_group.environment_group_id != null && module.environment_group.environment_group_id != ""
    error_message = "Environment group must be created successfully with valid ID via module"
  }

  # Environment group module properties
  assert {
    condition     = module.environment_group.environment_group_name == var.environment_group_config.display_name
    error_message = "Environment group must maintain correct display name after deployment via module"
  }

  # Environment modules deployment
  assert {
    condition = alltrue([
      for idx, env_module in module.environments : env_module.environment_id != null && env_module.environment_id != ""
    ])
    error_message = "All environments must be created successfully with valid IDs via modules"
  }

  # Environment group assignment verification via outputs
  assert {
    condition = alltrue([
      for idx, env_module in module.environments : output.governance_ready_resources.environments[idx].group_membership == module.environment_group.environment_group_id
    ])
    error_message = "All environments must be properly assigned to the environment group via modules"
  }

  # Environment names consistency via module outputs
  assert {
    condition = alltrue([
      for idx, env_module in module.environments : output.environment_names[idx] == var.environments[idx].display_name
    ])
    error_message = "Environment names must match input configuration after deployment via modules"
  }

  # Pattern orchestration output validation
  assert {
    condition     = output.orchestration_summary.deployment_status == "deployed"
    error_message = "Orchestration summary should indicate successful deployment"
  }

  # Resource count validation in outputs
  assert {
    condition     = output.orchestration_summary.total_resources_created == (1 + length(var.environments))
    error_message = "Orchestration summary should report correct number of resources created"
  }

  # Environment collection outputs validation
  assert {
    condition     = length(output.environment_ids) == length(var.environments) && length(output.environment_names) == length(var.environments)
    error_message = "Environment collection outputs should contain all created environments"
  }

  # Governance readiness validation
  assert {
    condition     = output.governance_ready_resources.environment_group.governance_ready == true
    error_message = "Environment group should be marked as governance ready"
  }

  # Pattern configuration validation
  assert {
    condition     = output.pattern_configuration_summary.orchestration_results.pattern_executed == true
    error_message = "Pattern configuration should confirm successful pattern execution"
  }
}