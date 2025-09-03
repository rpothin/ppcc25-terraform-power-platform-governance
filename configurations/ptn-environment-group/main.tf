# Power Platform Environment Group Pattern Configuration
#
# Template-driven pattern for creating environment groups with predefined
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

# Create environments using the template-driven configuration
module "environments" {
  source   = "../res-environment"
  for_each = local.template_environments

  # Environment configuration from template
  environment = merge(each.value.environment, {
    environment_group_id = module.environment_group.environment_group_id
  })

  # Dataverse configuration with monitoring service principal
  dataverse = each.value.dataverse

  # Enable duplicate protection for production workspaces
  enable_duplicate_protection = true

  # Explicit dependency on environment group module
  depends_on = [module.environment_group]
}

# ============================================================================
# MANAGED ENVIRONMENT MODULE ORCHESTRATION WITH SEQUENTIAL DEPLOYMENT
# ============================================================================

# Sequential deployment resource for managing rollout timing
# This prevents overwhelming the Power Platform API with simultaneous requests
resource "null_resource" "managed_environment_deployment_control" {
  for_each = local.template_environments

  # Sequential deployment triggers
  triggers = {
    environment_id = module.environments[each.key].environment_id
    environment_ready_hash = sha256(jsonencode({
      environment_id = module.environments[each.key].environment_id
      deployment_key = each.key
      template_name  = var.workspace_template
    }))
    deployment_timestamp = timestamp()
  }

  # Validate environment is ready before managed environment configuration
  lifecycle {
    precondition {
      condition     = length(trimspace(module.environments[each.key].environment_id)) > 0
      error_message = "Environment ${each.key} must have a valid ID before managed environment configuration. Current ID: '${module.environments[each.key].environment_id}'"
    }

    precondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", module.environments[each.key].environment_id))
      error_message = "Environment ${each.key} ID must be a valid GUID format. Received: '${module.environments[each.key].environment_id}'"
    }
  }

  # Explicit dependency chain: group → environments → readiness_check
  depends_on = [module.environments]
}

# Configure managed environment settings using template-processed configurations
# Applies workspace-level defaults with environment-specific overrides
# Uses sequential deployment to prevent API overwhelm and timing issues
module "managed_environment" {
  source   = "../res-managed-environment"
  for_each = local.template_environments

  # Environment ID from created environments with validation
  environment_id = module.environments[each.key].environment_id

  # Use default managed environment settings for template-driven configuration
  # These can be customized per template in the future if needed
  sharing_settings = {
    is_group_sharing_disabled = false     # Enable group sharing (better governance)
    limit_sharing_mode        = "NoLimit" # Allow sharing with security groups
    max_limit_user_sharing    = -1        # Unlimited when group sharing enabled
  }

  usage_insights_disabled = true # Disable weekly email digests for demo environments

  solution_checker = {
    mode                       = "Warn" # Validate but don't block
    suppress_validation_emails = true   # Reduce email noise
    rule_overrides             = []     # No rule overrides by default
  }

  maker_onboarding = {
    markdown_content = "Welcome to the ${var.name} workspace. Please follow organizational guidelines when developing solutions."
    learn_more_url   = "https://learn.microsoft.com/power-platform/"
  }

  # Sequential dependency chain: group → environments → readiness_check → managed_environment
  depends_on = [null_resource.managed_environment_deployment_control]
}

# ============================================================================
# ENVIRONMENT SETTINGS MODULE ORCHESTRATION
# ============================================================================

# Configure environment settings using template-processed configurations
# Applies workspace-level defaults with environment-specific overrides
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

  # Explicit dependency chain: group → environments → managed_environment → settings
  depends_on = [module.managed_environment]
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
