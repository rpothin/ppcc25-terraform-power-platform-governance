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
# ENVIRONMENT PROVISIONING COORDINATION
# ============================================================================

# Buffer time for environment provisioning to complete
# Power Platform environments need time for backend provisioning before settings configuration
resource "time_sleep" "environment_provisioning_buffer" {
  for_each = local.template_environments

  create_duration = "30s" # Allow time for environment backend setup

  depends_on = [module.environments]

  triggers = {
    environment_id = module.environments[each.key].environment_id
  }
}

# REMOVED: Managed environment functionality will be integrated into res-environment module
# when issues #17 and #18 are fully completed. For now, environments are created
# without managed environment configuration to maintain working state.

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

  # Explicit dependency chain: group → environments → buffer → settings
  # This ensures environments are fully provisioned before applying settings
  depends_on = [time_sleep.environment_provisioning_buffer]
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
