# Local Values for Template-Driven Environment Group Pattern
#
# This file defines workspace templates and common configuration for
# the Power Platform environment group pattern. Templates provide
# predefined environment configurations for different use cases.

locals {
  # ==========================================================================
  # COMMON CONFIGURATION
  # ==========================================================================

  # Service principal for tenant-level monitoring and automation (hardcoded for demonstration)
  # WHY: Used for monitoring dashboards and automated reporting, not environment access control
  # In production, this would be managed through Azure Key Vault or similar secure storage
  monitoring_service_principal_id = "b4a04840-2aa7-426a-ba2b-19330b6ae3d2" # Replace with actual monitoring SP ID

  # Default Dataverse configuration for all environments
  # WHY: Provides consistent Dataverse settings across all environments in the workspace
  default_dataverse_config = {
    language_code     = 1033                  # English (United States)
    currency_code     = "USD"                 # US Dollar
    security_group_id = var.security_group_id # Entra ID security group for user access control
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

      # Workspace-level settings applied to all environments
      workspace_settings = {
        # Global features enabled across all environments
        global_features = {
          power_apps_component_framework_for_canvas_apps = true
          show_dashboard_cards_in_expanded_state         = false
        }
        # Global email settings for workspace
        global_email = {
          max_upload_file_size_in_bytes = 52428800 # 50MB default
        }
        # Global security baseline
        global_security = {
          allow_microsoft_trusted_service_tags = true
          allow_application_user_access        = true
          # NOTE: IP firewall settings require Power Platform Managed Environments
          # This pattern uses standard environments for simplicity following PPCC25 "Keep It Simple" principle
          # For enterprise scenarios requiring IP restrictions, consider implementing managed environments
        }
      }

      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and testing"

          # Environment-specific settings for Dev
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "All" # Full tracing for debugging
              is_audit_enabled             = true
              is_user_access_audit_enabled = false # Less strict for dev
              is_read_audit_enabled        = false # Performance over auditing
              log_retention_period_in_days = 31    # Shorter retention
            }
            security_settings = {
              enable_ip_based_firewall_rule = false # Open access for development
              allowed_ip_range_for_firewall = []    # No restrictions
            }
            email_settings = {
              max_upload_file_size_in_bytes = 104857600 # 100MB for dev testing
            }
          }
        },
        {
          suffix           = " - Test"
          environment_type = "Sandbox"
          description      = "Testing environment for quality assurance and user acceptance testing"

          # Environment-specific settings for Test (different from Dev despite same type)
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Less verbose than dev
              is_audit_enabled             = true
              is_user_access_audit_enabled = true  # More audit for UAT
              is_read_audit_enabled        = false # Still performance focused
              log_retention_period_in_days = 90    # Longer than dev
            }
            security_settings = {
              # IP firewall rules removed - require managed environments
              # enable_ip_based_firewall_rule = true
              # allowed_ip_range_for_firewall = ["10.0.0.0/8", "192.168.0.0/16"]
            }
            # Inherit global email settings (no override)
          }
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"

          # Environment-specific settings for Production
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Production-appropriate
              is_audit_enabled             = true
              is_user_access_audit_enabled = true # Full audit compliance
              is_read_audit_enabled        = true # Complete audit trail
              log_retention_period_in_days = 365  # Compliance requirement
            }
            security_settings = {
              # IP firewall rules removed - require managed environments  
              # enable_ip_based_firewall_rule               = true
              # allowed_ip_range_for_firewall               = ["10.0.0.0/8"]
              # enable_ip_based_firewall_rule_in_audit_mode = false
            }
            # Inherit global email settings (production uses workspace default)
          }
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

      # Workspace-level settings applied to all environments
      workspace_settings = {
        # Simplified global features for basic workflow
        global_features = {
          power_apps_component_framework_for_canvas_apps = false # Keep it simple
          show_dashboard_cards_in_expanded_state         = true  # Better UX for simple setup
        }
        # Conservative email settings
        global_email = {
          max_upload_file_size_in_bytes = 26214400 # 25MB conservative default
        }
        # Basic security baseline
        global_security = {
          allow_microsoft_trusted_service_tags = true
          allow_application_user_access        = false # More restrictive for simple setup
        }
      }

      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and testing"

          # Simplified Dev settings
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Moderate tracing
              is_audit_enabled             = true
              is_user_access_audit_enabled = false # Keep it simple
              is_read_audit_enabled        = false # Performance focused
              log_retention_period_in_days = 31    # Standard retention
            }
            security_settings = {
              enable_ip_based_firewall_rule = false # Open for development
              allowed_ip_range_for_firewall = []    # No restrictions
            }
          }
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"

          # Production settings for simple template
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Standard production
              is_audit_enabled             = true
              is_user_access_audit_enabled = true  # Essential for prod
              is_read_audit_enabled        = false # Balance security and performance
              log_retention_period_in_days = 180   # Moderate compliance requirement
            }
            security_settings = {
              # IP firewall rules removed - require managed environments
              # enable_ip_based_firewall_rule = true
              # allowed_ip_range_for_firewall = ["10.0.0.0/8", "192.168.0.0/16"]
            }
            # Inherit global email settings
          }
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

      # Enterprise workspace-level settings with comprehensive features
      workspace_settings = {
        # Advanced global features for enterprise
        global_features = {
          power_apps_component_framework_for_canvas_apps = true  # Full feature set
          show_dashboard_cards_in_expanded_state         = false # Clean enterprise UX
        }
        # Enterprise email settings with larger limits
        global_email = {
          max_upload_file_size_in_bytes = 104857600 # 100MB for enterprise needs
        }
        # Enterprise security baseline
        global_security = {
          allow_microsoft_trusted_service_tags = true
          allow_application_user_access        = true # Enable automation
        }
      }

      environments = [
        {
          suffix           = " - Dev"
          environment_type = "Sandbox"
          description      = "Development environment for feature development and unit testing"

          # Enterprise Dev settings with comprehensive debugging
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "All" # Full debugging capability
              is_audit_enabled             = true
              is_user_access_audit_enabled = false # Dev focused on functionality
              is_read_audit_enabled        = false # Performance over auditing
              log_retention_period_in_days = 31    # Standard dev retention
            }
            security_settings = {
              enable_ip_based_firewall_rule = false # Open for development
              allowed_ip_range_for_firewall = []    # No restrictions for dev creativity
            }
            email_settings = {
              max_upload_file_size_in_bytes = 131072000 # 125MB maximum for dev testing
            }
          }
        },
        {
          suffix           = " - Staging"
          environment_type = "Sandbox"
          description      = "Staging environment for pre-production validation and integration testing"

          # Staging settings balancing testing needs with security
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Focus on issues
              is_audit_enabled             = true
              is_user_access_audit_enabled = true  # Pre-prod security
              is_read_audit_enabled        = false # Performance balance
              log_retention_period_in_days = 90    # Extended for staging analysis
            }
            security_settings = {
              # IP firewall rules removed - require managed environments
              # enable_ip_based_firewall_rule               = true
              # allowed_ip_range_for_firewall               = ["10.0.0.0/8"]
              # enable_ip_based_firewall_rule_in_audit_mode = true
            }
          }
        },
        {
          suffix           = " - Test"
          environment_type = "Sandbox"
          description      = "Testing environment for quality assurance and user acceptance testing"

          # QA/UAT settings optimized for testing workflows
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Issue-focused logging
              is_audit_enabled             = true
              is_user_access_audit_enabled = true  # UAT requires user tracking
              is_read_audit_enabled        = false # Performance for testing
              log_retention_period_in_days = 180   # Extended for test analysis
            }
            security_settings = {
              # IP firewall rules removed - require managed environments
              # enable_ip_based_firewall_rule = true
              # allowed_ip_range_for_firewall = ["10.0.0.0/8", "192.168.0.0/16"]
            }
            # Inherit global email settings for consistency
          }
        },
        {
          suffix           = " - Prod"
          environment_type = "Production"
          description      = "Production environment for live business operations"

          # Full enterprise production settings with maximum security and compliance
          environment_settings = {
            audit_settings = {
              plugin_trace_log_setting     = "Exception" # Production-appropriate
              is_audit_enabled             = true
              is_user_access_audit_enabled = true # Full compliance
              is_read_audit_enabled        = true # Complete audit trail
              log_retention_period_in_days = 2555 # 7 years for enterprise compliance
            }
            security_settings = {
              # IP firewall rules removed - require managed environments
              # enable_ip_based_firewall_rule               = true
              # allowed_ip_range_for_firewall               = ["10.0.0.0/8"]
              # enable_ip_based_firewall_rule_in_audit_mode = false
              # allowed_service_tags_for_firewall           = ["PowerPlatformPlex"]
            }
            # Inherit global email settings (enterprise production standard)
          }
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

  # ==========================================================================
  # ENVIRONMENT SETTINGS PROCESSING
  # ==========================================================================

  # Process environment settings from templates - merge workspace defaults with environment-specific overrides
  template_environment_settings = {
    for idx, env_config in local.selected_template.environments : idx => {
      # Merge workspace defaults with environment-specific settings
      merged_settings = {
        # Audit settings - environment-specific only (no workspace defaults)
        audit_settings = lookup(lookup(env_config, "environment_settings", {}), "audit_settings", null)

        # Security settings - merge global baseline with environment-specific overrides
        security_settings = merge(
          # Start with global security baseline from workspace
          local.selected_template.workspace_settings.global_security,
          # Add environment-specific security overrides if they exist
          lookup(lookup(env_config, "environment_settings", {}), "security_settings", {})
        )

        # Feature settings - use workspace global features as base
        feature_settings = merge(
          local.selected_template.workspace_settings.global_features,
          lookup(lookup(env_config, "environment_settings", {}), "feature_settings", {})
        )

        # Email settings - merge workspace defaults with environment overrides
        email_settings = merge(
          local.selected_template.workspace_settings.global_email,
          lookup(lookup(env_config, "environment_settings", {}), "email_settings", {})
        )
      }
    }
  }

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

      # Environment settings configuration from processed template settings
      settings = local.template_environment_settings[idx].merged_settings
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

# Validate service principal ID format for monitoring
check "monitoring_service_principal_valid" {
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", local.monitoring_service_principal_id))
    error_message = "Monitoring service principal ID must be a valid UUID format. This is used for monitoring and automation, not environment access control. Update the hardcoded value in locals.tf."
  }
}

# Validate security group ID format for environment access control
check "security_group_id_valid" {
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.security_group_id))
    error_message = "Security group ID must be a valid UUID format for Entra ID security group. This controls user access to Power Platform environments. Get from Azure Portal → Entra ID → Groups → [Your Group] → Properties → Object ID."
  }
}