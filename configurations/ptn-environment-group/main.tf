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
# This provides governance at the pattern level with proper state awareness
data "powerplatform_environments" "all" {
  # Always query to enable state-aware duplicate detection
}

# Simplified state-aware duplicate detection logic
# Based on research showing we need to check platform vs planned environments
locals {
  # Extract all environment names that this pattern will create
  planned_environment_names = [
    for key, env in local.template_environments : env.environment.display_name
  ]

  # Find environments that exist in platform with same names as our planned environments
  conflicting_environments = [
    for env in try(data.powerplatform_environments.all.environments, []) : env
    if contains(local.planned_environment_names, env.display_name)
  ]

  # For backwards compatibility with existing guardrail
  has_external_duplicates = length(local.conflicting_environments) > 0

  # Create detailed information about conflicting environments
  duplicate_environment_details = {
    for env in local.conflicting_environments : env.display_name => {
      platform_id  = env.id
      display_name = env.display_name
      location     = env.location
      message      = "Environment exists in platform - may need import if should be managed by Terraform"
    }
  }
}

# Pattern-level duplicate protection guardrail
# Duplicate detection guardrail - prevents creation of environments that already exist
# Note: This will detect duplicates on fresh deployments but will not block
# terraform operations on existing state that has already imported environments
resource "null_resource" "pattern_duplicate_guardrail" {
  count = local.has_external_duplicates && var.enable_pattern_duplicate_protection ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'DUPLICATE ENVIRONMENT DETECTED: This pattern would create environments with names that already exist. This is blocked for governance and consistency.'; exit 1"
  }

  lifecycle {
    precondition {
      condition     = !local.has_external_duplicates
      error_message = <<-EOF
        ENVIRONMENT NAME CONFLICT DETECTED:
        
        This pattern would create environments with names that already exist in your Power Platform tenant.
        
        Conflicting environments found:
        ${jsonencode(local.duplicate_environment_details)}
        
        ANALYSIS:
        If these environments should be managed by this Terraform configuration, this indicates
        they need to be imported into the Terraform state. If they shouldn't be managed by
        this configuration, choose different names.
        
        RESOLUTION OPTIONS:
        
        1. IMPORT EXISTING ENVIRONMENTS (if they should be managed by Terraform):
           For each conflicting environment, run:
           terraform import 'module.environments["ENVIRONMENT_KEY"].powerplatform_environment.this' ENVIRONMENT_ID
           
           Example:
           terraform import 'module.environments["0"].powerplatform_environment.this' 12345678-1234-1234-1234-123456789012
        
        2. CHOOSE DIFFERENT NAMES:
           Update your .tfvars file to use different environment names that don't conflict
        
        3. REMOVE CONFLICTING ENVIRONMENTS:
           If the existing environments are not needed, remove them from Power Platform
        
        4. DISABLE PROTECTION TEMPORARILY (not recommended):
           Set enable_pattern_duplicate_protection = false in your .tfvars
        
        This protection prevents unintentional environment conflicts while allowing proper Terraform management.
      EOF
    }
  }
}

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

  # Pattern-level governance control - authorize child after parent validation
  # WHY: Parent validates global state, then authorizes child execution
  # This creates proper governance chaining: validate at pattern level, execute at child level
  enable_duplicate_protection        = true
  parent_duplicate_validation_passed = !local.has_external_duplicates

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
