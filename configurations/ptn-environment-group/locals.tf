# Local Values for Template-Driven Environment Group Pattern
#
# This file defines workspace templates and common configuration for
# the Power Platform environment group pattern. Templates provide
# predefined environment configurations for different use cases.

locals {
  # ==========================================================================
  # COMMON CONFIGURATION
  # ==========================================================================

  # Service principal for tenant-level monitoring (hardcoded for demonstration)
  # In production, this would be managed through Azure Key Vault or similar
  monitoring_service_principal_id = "00000000-0000-0000-0000-000000000000" # Replace with actual SP ID

  # Default Dataverse configuration
  default_dataverse_config = {
    language_code     = 1033 # English (United States)
    currency_code     = "USD"
    security_group_id = local.monitoring_service_principal_id
  }

  # ==========================================================================
  # WORKSPACE TEMPLATES
  # ==========================================================================

  # Template definitions with environment specifications
  workspace_templates = {
    # Basic template: Standard development lifecycle
    basic = {
      description = "Standard three-tier development lifecycle"
      allowed_locations = [
        "unitedstates", "europe", "asia", "australia", "unitedkingdom",
        "india", "canada", "southamerica", "france", "unitedarabemirates",
        "southafrica", "germany", "switzerland", "norway", "korea", "japan"
      ]
      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and testing"
        },
        {
          suffix           = " - Test"
          environment_type = "Sandbox"
          description      = "Testing environment for quality assurance and user acceptance testing"
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"
        }
      ]
    }

    # Simple template: Minimal development lifecycle
    simple = {
      description = "Simplified two-tier development lifecycle"
      allowed_locations = [
        "unitedstates", "europe", "asia", "australia", "unitedkingdom",
        "india", "canada", "southamerica", "france", "unitedarabemirates",
        "southafrica", "germany", "switzerland", "norway", "korea", "japan"
      ]
      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and testing"
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"
        }
      ]
    }

    # Enterprise template: Full enterprise lifecycle with staging
    enterprise = {
      description = "Enterprise-grade four-tier development lifecycle with staging"
      allowed_locations = [
        "unitedstates", "europe", "asia", "australia", "unitedkingdom",
        "india", "canada", "southamerica", "france", "unitedarabemirates",
        "southafrica", "germany", "switzerland", "norway", "korea", "japan"
      ]
      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and unit testing"
        },
        {
          suffix           = " - Staging"
          environment_type = "Sandbox"
          description      = "Staging environment for pre-production validation and integration testing"
        },
        {
          suffix           = " - Test"
          environment_type = "Sandbox"
          description      = "Testing environment for quality assurance and user acceptance testing"
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"
        }
      ]
    }
  }

  # ==========================================================================
  # TEMPLATE VALIDATION AND PROCESSING
  # ==========================================================================

  # Selected template configuration
  selected_template = local.workspace_templates[var.workspace_template]

  # Validate location against template allowed locations
  location_validation = contains(local.selected_template.allowed_locations, var.location)

  # Generate environment configurations from template
  template_environments = {
    for idx, env_config in local.selected_template.environments : idx => {
      # Environment configuration object
      environment = {
        display_name         = "${var.name}${env_config.suffix}"
        location             = var.location
        environment_type     = env_config.environment_type
        environment_group_id = null # Will be set after group creation
        description          = env_config.description
      }

      # Dataverse configuration object
      # Note: Domain will be auto-calculated by res-environment module from display_name
      dataverse = local.default_dataverse_config
    }
  }

  # ==========================================================================
  # PATTERN METADATA
  # ==========================================================================

  # Pattern metadata for outputs and validation
  pattern_metadata = {
    pattern_type         = "ptn-environment-group"
    workspace_template   = var.workspace_template
    workspace_name       = var.name
    environment_count    = length(local.selected_template.environments)
    template_description = local.selected_template.description
  }

  # Environment summary for governance reporting
  environment_summary = {
    for idx, env_config in local.selected_template.environments : idx => {
      display_name     = "${var.name}${env_config.suffix}"
      environment_type = env_config.environment_type
      location         = var.location
      suffix           = env_config.suffix
      description      = env_config.description
    }
  }

  # ==========================================================================
  # DEPLOYMENT VALIDATION
  # ==========================================================================

  # Deployment validation
  deployment_validation = {
    template_valid           = contains(keys(local.workspace_templates), var.workspace_template)
    location_valid           = local.location_validation
    all_environments_created = true # Will be calculated after deployment
    group_assignment_valid   = true # Will be validated after group creation
    pattern_complete         = length(local.selected_template.environments) > 0
  }

  # Environment deployment results (for outputs)
  environment_results = {
    for idx, env_config in local.selected_template.environments : idx => {
      display_name     = "${var.name}${env_config.suffix}"
      environment_type = env_config.environment_type
      location         = var.location
      suffix           = env_config.suffix
      template_source  = var.workspace_template
    }
  }
}

# ==========================================================================
# VALIDATION CHECKS
# ==========================================================================

# Validate location is allowed by selected template
check "location_allowed_by_template" {
  assert {
    condition     = local.location_validation
    error_message = "Location '${var.location}' is not allowed by template '${var.workspace_template}'. Allowed locations: ${join(", ", local.selected_template.allowed_locations)}."
  }
}

# Validate environment name lengths will not exceed limits
check "environment_names_within_limits" {
  assert {
    condition = alltrue([
      for env in local.environment_summary : length(env.display_name) <= 100
    ])
    error_message = "One or more generated environment names exceed 100 characters. Consider shortening the workspace name. Current names: ${join(", ", [for env in local.environment_summary : env.display_name])}."
  }
}

# Validate service principal ID format
check "monitoring_service_principal_valid" {
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", local.monitoring_service_principal_id))
    error_message = "Monitoring service principal ID must be a valid UUID format. Update the hardcoded value in locals.tf."
  }
}