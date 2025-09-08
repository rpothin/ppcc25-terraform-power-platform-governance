# Power Platform Environment Group Pattern Configuration
#
# Template-driven pattern for creating environment groups with predef# Environment Group Pattern Configuration
#
# Template-driven pattern for creating Power Platform environment groups with standardized
# workspace templates. Provides standardized environment configurations
# for PPCC25 demonstration scenarios.
# 
# Pattern Components:
# - Environment Group: Central container for organizing environments (via res-environment-group)
# - Multiple Environments: Template-defined environments (via res-environment)
# - Application Admin: Assigns application admin permissions to environments (via res-environment-application-admin)
# - Template System: Predefined configurations in locals.tf
#
# Key Features:
# - Template-Driven: Uses workspace templates (basic, simple, enterprise)
# - AVM Module Orchestration: Uses res-* modules for resource creation
# - Convention over Configuration: Predefined templates reduce complexity
# - Security-First: OIDC authentication, service principal monitoring
# - Pattern Module: Orchestrates multiple resource modules for governance
# - Location Validation: Template-specific allowed locations
# - Strong Typing: Explicit types and validation throughout
#
# Architecture Decisions:
# - Template System: Predefined configurations in locals.tf
# - Variable Simplification: Only 4 user inputs (template, name, description, location)
# - Module Orchestration: Uses res-environment-group, res-environment, and res-environment-application-admin modules
# - Dependency Chain: Environment group → Template processing → Environment creation → Application admin assignment
# - Governance Integration: Built for DLP policies and environment routing

# ============================================================================
# ENVIRONMENT GROUP MODULE ORCHESTRATION
# ============================================================================

# Create the environment group using the res-environment-group module
# This provides the central governance container for environment organization
module "environment_group" {
  source = "../res-environment-group"

  # Simple mapping from pattern variables to module interface
  display_name = "${var.name} - Environment Group"
  description  = "${var.description} (${local.selected_template.description})"
}

# ============================================================================
# ENVIRONMENT MODULE ORCHESTRATION
# ============================================================================

# Query existing environments for state-aware duplicate detection
# Query existing environments for true state-aware duplicate detection
# Following research-based approach for three-scenario detection
data "powerplatform_environments" "all" {}

# Self-referencing state approach for reliable duplicate detection
# This reads the current state's managed_environments output to determine what's already managed
data "terraform_remote_state" "self" {
  backend = "azurerm"
  config = {
    # Use the actual backend configuration for this environment
    resource_group_name  = "rg-terraform-powerplatform-governance"
    storage_account_name = "stterraformpp2cc7945b"
    container_name       = "terraform-state"
    key                  = "powerplatform/governance/ptn-environment-group-regional-examples.tfstate"
    use_oidc             = true
  }
}

locals {
  # Platform environment lookup (from Power Platform API)
  platform_envs = {
    for env in data.powerplatform_environments.all.environments :
    lower(env.display_name) => {
      id           = env.id
      display_name = env.display_name
      location     = env.location
    }
  }

  # Safely access the terraform_state_tracking output from current state
  # This avoids circular dependency since terraform_data resources exist independently of modules
  current_managed_environments = try(
    data.terraform_remote_state.self.outputs.terraform_state_tracking,
    {}
  )

  # Build the existing state managed environments map
  # Uses the terraform_state_tracking output structure as the authoritative source
  # This avoids circular dependency since terraform_data exists independently of modules
  existing_state_managed_envs = {
    for key, details in local.current_managed_environments :
    lower(details.display_name) => {
      display_name = details.display_name
      template_key = details.template_key
      scenario     = "managed_update" # All tracked environments are managed
    }
  } # Implement true three-scenario detection for each planned environment
  environment_scenarios = {
    for key, env_config in local.template_environments : key => {
      target_name_lower = lower(env_config.environment.display_name)

      # TRUE SCENARIO DETECTION: Based on platform existence and actual state
      exists_in_platform = contains(keys(local.platform_envs), lower(env_config.environment.display_name))
      exists_in_state    = contains(keys(local.existing_state_managed_envs), lower(env_config.environment.display_name))

      # THREE SCENARIOS (corrected logic):
      # 1. create_new: Environment doesn't exist in platform
      # 2. managed_update: Environment exists in platform AND in current Terraform state
      # 3. duplicate_blocked: Environment exists in platform but NOT in current Terraform state
      scenario = contains(keys(local.platform_envs), lower(env_config.environment.display_name)) ? (
        contains(keys(local.existing_state_managed_envs), lower(env_config.environment.display_name)) ? "managed_update" : "duplicate_blocked"
      ) : "create_new"

      # RESOURCE CREATION LOGIC: Only create if NOT blocked
      should_create_resource = !contains(keys(local.platform_envs), lower(env_config.environment.display_name)) || contains(keys(local.existing_state_managed_envs), lower(env_config.environment.display_name))

      # Debug information
      platform_id = try(local.platform_envs[lower(env_config.environment.display_name)].id, null)

      # Error message for blocked scenarios
      error_message = contains(keys(local.platform_envs), lower(env_config.environment.display_name)) && !contains(keys(local.existing_state_managed_envs), lower(env_config.environment.display_name)) ? "Environment '${env_config.environment.display_name}' exists in Power Platform but is not managed by this Terraform configuration. This is a duplicate that must be resolved." : ""
    }
  }

  # Identify blocked environments (research pattern)
  blocked_environments = {
    for key, scenario_data in local.environment_scenarios : key => scenario_data
    if scenario_data.scenario == "duplicate_blocked"
  }

  # Overall blocking flag (backwards compatibility)
  has_external_duplicates = length(local.blocked_environments) > 0

  # Detailed error information (research format)
  duplicate_environment_details = {
    for key, scenario_data in local.blocked_environments : scenario_data.target_name_lower => {
      display_name = local.template_environments[key].environment.display_name
      platform_id  = scenario_data.platform_id
      scenario     = scenario_data.scenario
      message      = scenario_data.error_message
    }
  }
}

# Pattern-level duplicate protection guardrail
# Prevents creation of environments that already exist in platform but aren't in Terraform state
resource "null_resource" "pattern_duplicate_guardrail" {
  count = local.has_external_duplicates && var.enable_pattern_duplicate_protection ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'DUPLICATE ENVIRONMENT DETECTED: This pattern would create environments with names that already exist in Power Platform but are not managed by this Terraform configuration.'; exit 1"
  }

  lifecycle {
    precondition {
      condition     = !local.has_external_duplicates || !var.enable_pattern_duplicate_protection
      error_message = <<-EOF
        DUPLICATE ENVIRONMENTS DETECTED:
        
        The following environments exist in Power Platform but are not in this Terraform state:
        ${join("\n", [for name, details in local.duplicate_environment_details : "- ${details.display_name} (Platform ID: ${details.platform_id})"])}
        
        RESOLUTION OPTIONS:
        
        1. IMPORT EXISTING ENVIRONMENTS (if they should be managed):
${join("\n", [for key, scenario_data in local.blocked_environments : "           terraform import 'module.environments[\"${key}\"].powerplatform_environment.this' ${scenario_data.platform_id}"])}
        
        2. DISABLE DUPLICATE PROTECTION (temporary, for testing only):
           Set enable_pattern_duplicate_protection = false
        
        3. CHOOSE DIFFERENT NAMES:
           Update your .tfvars to use non-conflicting environment names
        
        This implements true state-aware duplicate detection without assumption flags.
      EOF
    }
  }
}

# Create environments using conditional logic from research document
# Only create environments that pass the three-scenario validation
module "environments" {
  source = "../res-environment"
  for_each = {
    for key, env_config in local.template_environments : key => env_config
    if local.environment_scenarios[key].should_create_resource
  }

  # Environment configuration from template
  environment = merge(each.value.environment, {
    environment_group_id = module.environment_group.environment_group_id
  })

  # Dataverse configuration with monitoring service principal
  dataverse = each.value.dataverse

  # Disable child-level duplicate protection since parent handles it with state awareness
  enable_duplicate_protection        = false
  parent_duplicate_validation_passed = true

  # Disable managed environment module since environments auto-convert when in groups
  enable_managed_environment = false

  # Explicit dependency on environment group module and duplicate check
  depends_on = [module.environment_group, null_resource.pattern_duplicate_guardrail]
}

# ============================================================================
# MANAGED ENVIRONMENT CONVERSION WAIT
# ============================================================================

# Add explicit wait time for managed environment conversion
# WHY: When environments are added to environment groups, they automatically
# convert to managed environments, but this conversion takes time. Applying
# IPFirewall settings before conversion completes causes failures.
resource "time_sleep" "managed_environment_conversion" {
  # Wait for environments to fully convert to managed status
  create_duration = "120s" # 2 minutes - sufficient for managed conversion

  # Explicit dependency on environment creation
  depends_on = [module.environments]

  # Lifecycle management for consistent timing
  lifecycle {
    # Prevent destruction to maintain consistent timing
    prevent_destroy = false
  }

  # Trigger re-creation if environment configuration changes
  triggers = {
    environment_count    = length(local.template_environments)
    environment_group_id = module.environment_group.environment_group_id
  }
}

# ============================================================================
# ENVIRONMENT SETTINGS MODULE ORCHESTRATION
# ============================================================================

# Configure environment settings using template-processed configurations
# Applies workspace-level defaults with environment-specific overrides
# CRITICAL: Now includes wait time for managed environment conversion
module "environment_settings" {
  source   = "../res-environment-settings"
  for_each = local.template_environments

  # Environment ID from created environments
  environment_id = module.environments[each.key].environment_id

  # Apply processed settings from template configuration
  audit_settings    = each.value.settings.audit_settings
  security_settings = each.value.settings.security_settings
  feature_settings  = each.value.settings.feature_settings
  email_settings    = each.value.settings.email_settings

  # CRITICAL: Enhanced dependency chain: group → environments → wait → settings
  # This ensures environments are fully converted to managed before applying settings
  depends_on = [module.environments, time_sleep.managed_environment_conversion]
}

# ============================================================================
# ENVIRONMENT APPLICATION ADMIN MODULE ORCHESTRATION
# ============================================================================

# Assigns the monitoring service principal as an application admin to each environment
# This enables tenant-level monitoring and governance capabilities
module "environment_application_admin" {
  source   = "../res-environment-application-admin"
  for_each = local.template_environments

  # Environment ID from created environments
  environment_id = module.environments[each.key].environment_id

  # Application ID for the monitoring service principal
  application_id = local.monitoring_service_principal_id

  # Explicit dependency chain: group → environments → application_admin
  depends_on = [module.environments]
}

# ============================================================================
# TERRAFORM STATE TRACKING (Research Document Pattern)
# ============================================================================

# Track managed environments in Terraform state using terraform_data
# This enables true state-aware duplicate detection without circular dependencies
resource "terraform_data" "managed_environment_tracker" {
  for_each = module.environments

  # Store environment metadata for state tracking
  input = {
    environment_id = each.value.environment_id
    display_name   = each.value.environment_summary.name
    template_key   = each.key
    managed_by     = "terraform"
    creation_time  = timestamp()
  }

  # Lifecycle management
  lifecycle {
    # Recreate tracker when environment changes
    create_before_destroy = true
  }
}
