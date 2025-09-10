# Integration Tests for Power Platform Environment Group Pattern Configuration
#
# Template-driven pattern integration tests that validate the simplified approach
# with workspace templates and 4-variable configuration. Tests require authentication
# via OIDC and are designed for CI/CD environments like GitHub Actions.

provider "powerplatform" {
  use_oidc = true
}

# Test Philosophy:
# - Template-Driven Testing: Validates template selection and processing
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, orchestration, and template logic
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 25+ for ptn-* modules (plan and apply tests required)
#
# Template Testing Focus:
# - Template Selection: Validates template choice and processing
# - Environment Generation: Template-driven environment creation
# - Multi-Resource Orchestration: Environment group + template environments
# - Dependency Management: Proper resource creation sequence
# - Group Assignment: Automatic environment assignment to group
# - Integration Validation: Resources work together correctly
# - Governance Readiness: Outputs support downstream governance configuration

variables {
  # Template-driven test configuration
  workspace_template = "basic"
  name               = "TestWorkspace"
  description        = "Test workspace for template-driven pattern validation and CI/CD"
  location           = "unitedstates"
}

# ============================================================================
# STATIC VALIDATION - File-Based Validation During Apply Phase
# ============================================================================

# CRITICAL: All tests use apply command to avoid count expression evaluation issues
# Static validation can still be performed during apply phase using file() functions
run "static_validation" {
  command = apply

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

  # OIDC authentication configuration in versions.tf provider block
  assert {
    condition     = length(regexall("use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider must be configured with use_oidc = true for secure authentication"
  }

  # Module orchestration structure validation (file-based)
  assert {
    condition     = length(regexall("module\\s+\"environment_group\"", file("${path.module}/main.tf"))) > 0
    error_message = "Pattern must orchestrate environment_group module"
  }

  # Module orchestration structure validation (file-based)
  assert {
    condition     = length(regexall("module\\s+\"environments\"", file("${path.module}/main.tf"))) > 0
    error_message = "Pattern must orchestrate environments module with for_each"
  }

  # === TEMPLATE-DRIVEN VARIABLE VALIDATION (5 assertions) ===

  # Workspace template validation
  assert {
    condition     = contains(["basic", "simple", "enterprise"], var.workspace_template)
    error_message = "Workspace template must be one of: basic, simple, enterprise"
  }

  # Workspace name validation
  assert {
    condition     = length(var.name) >= 1 && length(var.name) <= 50
    error_message = "Workspace name must be 1-50 characters for template processing"
  }

  # Workspace description validation
  assert {
    condition     = length(var.description) >= 1 && length(var.description) <= 200
    error_message = "Workspace description must be 1-200 characters"
  }

  # Location validation against Power Platform regions
  assert {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "unitedkingdom", "india",
      "canada", "southamerica", "france", "unitedarabemirates", "southafrica",
      "germany", "switzerland", "norway", "korea", "japan"
    ], var.location)
    error_message = "Location must be a valid Power Platform geographic region"
  }

  # Template processing validation - locals.tf exists
  assert {
    condition     = fileexists("${path.module}/locals.tf")
    error_message = "locals.tf file must exist for template processing"
  }

  # === TEMPLATE STRUCTURE VALIDATION (5 assertions) ===

  # Template definitions validation in locals.tf
  assert {
    condition     = length(regexall("workspace_templates\\s*=\\s*\\{", file("${path.module}/locals.tf"))) > 0
    error_message = "locals.tf must define workspace_templates map"
  }

  # Basic template definition validation
  assert {
    condition     = length(regexall("basic\\s*=\\s*\\{", file("${path.module}/locals.tf"))) > 0
    error_message = "Basic template must be defined in workspace_templates"
  }

  # Template processing logic validation
  assert {
    condition     = length(regexall("selected_template\\s*=\\s*local\\.workspace_templates", file("${path.module}/locals.tf"))) > 0
    error_message = "Template selection logic must be defined in locals.tf"
  }

  # Environment generation logic validation
  assert {
    condition     = length(regexall("template_environments\\s*=\\s*\\{", file("${path.module}/locals.tf"))) > 0
    error_message = "Template environment generation logic must be defined in locals.tf"
  }

  # Service principal configuration validation
  assert {
    condition     = length(regexall("monitoring_service_principal_id\\s*=", file("${path.module}/locals.tf"))) > 0
    error_message = "Monitoring service principal must be configured in locals.tf"
  }

  # === MODULE ORCHESTRATION FILE STRUCTURE (10 assertions) ===

  # Settings module orchestration validation
  assert {
    condition     = length(regexall("module\\s+\"environment_settings\"", file("${path.module}/main.tf"))) > 0
    error_message = "Pattern must orchestrate environment_settings module"
  }



  # Environment application admin module orchestration validation
  assert {
    condition     = length(regexall("module\\s+\"environment_application_admin\"", file("${path.module}/main.tf"))) > 0
    error_message = "Pattern must orchestrate environment_application_admin module"
  }

  # Dependencies validation - environments depend on environment group
  assert {
    condition     = length(regexall("depends_on.*module\\.environment_group", file("${path.module}/main.tf"))) > 0
    error_message = "Environments modules should explicitly depend on environment group module"
  }

  # Template-driven for_each usage
  assert {
    condition     = length(regexall("for_each\\s*=\\s*local\\.template_environments", file("${path.module}/main.tf"))) > 0
    error_message = "Environments module should use for_each with template_environments"
  }

  # Environment group name generation validation
  assert {
    condition     = length(regexall("\\$\\{var\\.name\\}.*Environment Group", file("${path.module}/main.tf"))) > 0
    error_message = "Environment group name should be generated from workspace name"
  }

  # Environment group ID assignment validation
  assert {
    condition     = length(regexall("environment_group_id\\s*=\\s*module\\.environment_group\\.environment_group_id", file("${path.module}/main.tf"))) > 0
    error_message = "Environment group ID should be assigned from module output"
  }

  # Settings dependency chain validation - updated for new structure
  assert {
    condition     = length(regexall("depends_on.*time_sleep\\.environment_provisioning_buffer", file("${path.module}/main.tf"))) > 0
    error_message = "Environment settings should depend on environment provisioning buffer"
  }



  # Environment application admin dependency chain validation
  assert {
    condition     = length(regexall("depends_on.*module\\.environments", file("${path.module}/main.tf"))) > 0
    error_message = "Environment application admin should depend on environments module"
  }

  # === OUTPUT DEFINITIONS VALIDATION (5 assertions) ===

  # Primary outputs validation - environment group
  assert {
    condition     = length(regexall("output\\s+\"environment_group_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Pattern must define environment_group_id output"
  }

  # Template metadata output validation
  assert {
    condition     = length(regexall("output\\s+\"template_metadata\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Pattern must define template_metadata output"
  }

  # Environment collection outputs validation
  assert {
    condition     = length(regexall("output\\s+\"environment_names\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Pattern must define environment_names output"
  }

  # Orchestration summary output validation
  assert {
    condition     = length(regexall("output\\s+\"orchestration_summary\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Pattern must define orchestration_summary output"
  }

  # Governance integration output validation
  assert {
    condition     = length(regexall("output\\s+\"governance_ready_resources\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Pattern must define governance_ready_resources output"
  }
}

# ============================================================================
# APPLY VALIDATION - Runtime Template Processing and Resource Deployment
# ============================================================================

# CRITICAL: Apply phase validates runtime behavior - module outputs, resource creation
# All count-dependent validations and module orchestration testing happens here
run "runtime_validation" {
  command = apply

  # === TEMPLATE PROCESSING VALIDATION (5 assertions) ===

  # Template selection validation
  assert {
    condition     = local.selected_template != null
    error_message = "Selected template must be loaded successfully from workspace_templates"
  }

  # Template environment generation validation
  assert {
    condition     = length(local.template_environments) > 0
    error_message = "Template must generate at least one environment configuration"
  }

  # Basic template specific validation (when using basic template)
  assert {
    condition     = var.workspace_template != "basic" || length(local.template_environments) == 3
    error_message = "Basic template should generate exactly 3 environments (Dev, Test, Prod)"
  }

  # Environment naming validation
  assert {
    condition = alltrue([
      for idx, env in local.environment_summary : startswith(env.display_name, var.name)
    ])
    error_message = "All generated environment names should start with workspace name"
  }

  # Location validation against template
  assert {
    condition     = local.location_validation == true
    error_message = "Location should be validated against template allowed locations"
  }

  # === SETTINGS PROCESSING VALIDATION (5 assertions) ===

  # Settings processing structure validation
  assert {
    condition     = can(local.template_environment_settings)
    error_message = "Settings processing must generate template_environment_settings"
  }

  # Settings merge logic validation
  assert {
    condition = alltrue([
      for idx, settings in local.template_environment_settings :
      can(settings.merged_settings)
    ])
    error_message = "All environment settings must have merged_settings structure"
  }

  # Environment-specific settings validation
  assert {
    condition = alltrue([
      for idx, settings in local.template_environment_settings :
      can(settings.merged_settings.security_settings)
    ])
    error_message = "All environments must have processed security settings"
  }

  # Template environments settings integration validation
  assert {
    condition = alltrue([
      for idx, env in local.template_environments :
      can(env.settings)
    ])
    error_message = "All template environments must include processed settings"
  }

  # Settings count validation
  assert {
    condition     = length(local.template_environment_settings) == length(local.template_environments)
    error_message = "Settings processing count must match environment count"
  }

  # === MODULE ORCHESTRATION VALIDATION (5 assertions) ===

  # Module composition validation - environment group module
  assert {
    condition     = can(module.environment_group)
    error_message = "Environment group module must be deployed and accessible"
  }

  # Module composition validation - environments modules
  assert {
    condition     = can(module.environments)
    error_message = "Environments modules must be deployed and accessible"
  }

  # Environment group name validation
  assert {
    condition     = endswith(module.environment_group.environment_group_name, "Environment Group")
    error_message = "Environment group name should end with 'Environment Group'"
  }

  # Environments modules count validation against template
  assert {
    condition     = length(module.environments) == length(local.template_environments)
    error_message = "Should create one environment module per template environment"
  }

  # Environment group ID assignment validation
  assert {
    condition = alltrue([
      for idx, env_config in local.template_environments :
      module.environments[idx].environment_summary.environment_group_id == module.environment_group.environment_group_id
    ])
    error_message = "All environments should be assigned to the created environment group"
  }

  # === SETTINGS MODULE ORCHESTRATION VALIDATION (3 assertions) ===





  # Settings modules deployment validation
  assert {
    condition     = can(module.environment_settings)
    error_message = "Environment settings modules must be deployed and accessible"
  }

  # Settings modules count validation
  assert {
    condition     = length(module.environment_settings) == length(local.template_environments)
    error_message = "Should create one settings module per template environment"
  }

  # Settings configuration validation
  assert {
    condition = alltrue([
      for idx, settings_module in module.environment_settings :
      can(settings_module.deployment_summary)
    ])
    error_message = "All environment settings modules must deploy successfully"
  }

  # Settings dependency validation (environment ID assignment)
  assert {
    condition = alltrue([
      for idx, settings_module in module.environment_settings :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", settings_module.deployment_summary.environment_id))
    ])
    error_message = "All settings modules should be linked to valid environment IDs"
  }

  # Environment-specific settings application validation
  assert {
    condition = alltrue([
      for idx, settings_module in module.environment_settings :
      settings_module.deployment_summary.settings_applied == true
    ])
    error_message = "All environment settings should be applied successfully"
  }

  # === ENVIRONMENT APPLICATION ADMIN MODULE ORCHESTRATION VALIDATION (3 assertions) ===

  # Module composition validation - environment application admin modules
  assert {
    condition     = can(module.environment_application_admin)
    error_message = "Environment application admin modules must be deployed and accessible"
  }

  # Environment application admin modules count validation
  assert {
    condition     = length(module.environment_application_admin) == length(local.template_environments)
    error_message = "Should create one environment application admin module per template environment"
  }

  # Environment application admin configuration validation
  assert {
    condition = alltrue([
      for idx, admin_module in module.environment_application_admin :
      admin_module.application_id == local.monitoring_service_principal_id
    ])
    error_message = "All environment application admin modules should be configured with the monitoring service principal"
  }

  # === PATTERN METADATA VALIDATION (5 assertions) ===

  # Pattern metadata structure validation
  assert {
    condition     = can(local.pattern_metadata) && local.pattern_metadata.pattern_type == "ptn-environment-group"
    error_message = "Pattern metadata must be computed correctly with proper pattern type"
  }

  # Workspace template tracking validation
  assert {
    condition     = local.pattern_metadata.workspace_template == var.workspace_template
    error_message = "Pattern metadata should track the selected workspace template"
  }

  # Environment count validation
  assert {
    condition     = local.pattern_metadata.environment_count == length(local.template_environments)
    error_message = "Pattern metadata should track correct environment count from template"
  }

  # Template description tracking validation
  assert {
    condition     = local.pattern_metadata.template_description == local.selected_template.description
    error_message = "Pattern metadata should include template description"
  }

  # Deployment validation structure
  assert {
    condition     = can(local.deployment_validation) && local.deployment_validation.pattern_complete == true
    error_message = "Deployment validation should confirm pattern completion"
  }

  # === OUTPUT VALIDATION (5 assertions) ===

  # Template-specific outputs validation
  assert {
    condition     = output.workspace_template == var.workspace_template && output.workspace_name == var.name
    error_message = "Template outputs must match input configuration"
  }

  # Environment collection outputs validation
  assert {
    condition     = length(output.environment_names) == length(local.template_environments)
    error_message = "Environment names output should contain all template-generated environments"
  }

  # Template metadata output validation
  assert {
    condition     = output.template_metadata.template_name == var.workspace_template
    error_message = "Template metadata output should include correct template name"
  }

  # Orchestration summary validation
  assert {
    condition     = output.orchestration_summary.deployment_status == "deployed"
    error_message = "Orchestration summary should indicate successful deployment"
  }

  # Governance readiness validation
  assert {
    condition     = output.governance_ready_resources.environment_group.template_driven == true
    error_message = "Governance resources should be marked as template-driven"
  }

  # === RESOURCE DEPLOYMENT VALIDATION (5+ assertions) ===

  # Environment group deployment validation
  assert {
    condition     = module.environment_group.environment_group_id != null && module.environment_group.environment_group_id != ""
    error_message = "Environment group must be created successfully with valid ID"
  }

  # Environment group naming validation
  assert {
    condition     = strcontains(module.environment_group.environment_group_name, var.name)
    error_message = "Environment group name should contain workspace name"
  }

  # Template environments deployment validation
  assert {
    condition = alltrue([
      for idx, env_module in module.environments : env_module.environment_id != null && env_module.environment_id != ""
    ])
    error_message = "All template environments must be created successfully with valid IDs"
  }

  # Environment naming consistency validation
  assert {
    condition = alltrue([
      for idx, env in local.environment_summary :
      output.environment_names[idx] == env.display_name
    ])
    error_message = "Environment names must match template-generated names"
  }

  # Environment suffixes validation (basic template specific)
  assert {
    condition = var.workspace_template != "basic" || (
      strcontains(output.environment_suffixes[0], "Dev") &&
      strcontains(output.environment_suffixes[1], "Test") &&
      strcontains(output.environment_suffixes[2], "Prod")
    )
    error_message = "Basic template should generate Dev, Test, and Prod environment suffixes"
  }

  # Template processing results validation
  assert {
    condition     = output.orchestration_summary.template_processing.template_loaded == true
    error_message = "Template processing should be successful"
  }

  # Resource count validation
  assert {
    condition     = output.orchestration_summary.total_resources_created == (1 + local.pattern_metadata.environment_count)
    error_message = "Should create 1 environment group + N template environments"
  }

  # Pattern configuration summary validation
  assert {
    condition     = output.pattern_configuration_summary.workspace_config.template == var.workspace_template
    error_message = "Pattern configuration summary should track template selection"
  }

  # Template validation in configuration summary
  assert {
    condition     = output.pattern_configuration_summary.template_processing.template_name == var.workspace_template
    error_message = "Configuration summary should confirm template processing"
  }

  # Governance integration validation
  assert {
    condition = alltrue([
      for idx, env in output.governance_ready_resources.environments :
      env.workspace_name == var.name
    ])
    error_message = "All governance-ready environments should reference workspace name"
  }
}

# ============================================================================
# TEST PHASE SEPARATION EXPLANATION
# ============================================================================

# This fix addresses the critical Terraform limitation where count expressions
# that depend on unknown values during plan phase cause test failures.
#
# ROOT CAUSE:

# - This count depends on var.environment_id from module outputs
# - During plan phase, module outputs are not available
# - Terraform cannot determine count value, causing "Invalid count argument" error
#
# SOLUTION APPLIED:
# - Plan phase: Only static validation (file content, variable structure)
# - Apply phase: All runtime validation (module outputs, resource creation)
#
# PATTERN COMPLIANCE:
# - Maintains 25+ assertions requirement for ptn-* modules
# - Follows Terraform testing best practices
# - Ensures CI/CD compatibility
# - Provides clear error isolation