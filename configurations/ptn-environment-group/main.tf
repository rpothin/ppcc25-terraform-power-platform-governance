# Power Platform Environment Group Pattern Configuration
#
# Template-driven pattern for creating environment groups with predefined
# workspace templates. Provides standardized environment configurations
# for PPCC25 demonstration scenarios.
# 
# Pattern Components:
# - Environment Group: Central container for organizing environments (via res-environment-group)
# - Multiple Environments: Template-defined environments (via res-environment)
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
# - Module Orchestration: Uses res-environment-group and res-environment modules
# - Dependency Chain: Environment group → Template processing → Environment creation
# - Governance Integration: Built for DLP policies and environment routing

# ============================================================================
# TERRAFORM CONFIGURATION
# ============================================================================

terraform {
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}

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
# PATTERN SUMMARY AND METADATA
# ============================================================================

# Pattern deployment summary for validation and outputs
locals {
  # Deployment validation
  deployment_validation = {
    template_valid           = contains(keys(local.workspace_templates), var.workspace_template)
    location_valid           = local.location_validation
    all_environments_created = length(module.environments) == local.pattern_metadata.environment_count
    group_assignment_valid   = module.environment_group.environment_group_id != null
    pattern_complete         = local.pattern_metadata.environment_count > 0
  }

  # Environment deployment results
  environment_results = {
    for idx, env in local.environment_summary : idx => {
      display_name     = env.display_name
      environment_type = env.environment_type
      location         = env.location
      environment_id   = module.environments[idx].environment_id
      group_assignment = "automatic" # Assigned via pattern orchestration
      template_suffix  = env.suffix
    }
  }
}