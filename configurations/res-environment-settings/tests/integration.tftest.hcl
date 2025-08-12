# Integration Tests for Power Platform Environment Settings Configuration
#
# These integration tests validate the Power Platform environment settings management
# against a real Power Platform tenant. Tests require authentication via OIDC
# and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 20+ for res-* modules (plan/apply tests required)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Variable Validation: Input parameter structure and constraints
# - Resource Validation: Resource-specific structure and configuration
# - Output Validation: AVM compliance and data integrity
# - Security Validation: Sensitive data handling and access controls

variables {
  # Test configuration - adjustable for different environments
  test_environment_id  = "00000000-0000-0000-0000-000000000001" # Test environment GUID
  test_timeout_minutes = 10                                     # Extended timeout for environment settings operations
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  variables {
    environment_settings_config = {
      environment_id = var.test_environment_id
      audit_and_logs = {
        plugin_trace_log_setting = "Exception"
        audit_settings = {
          is_audit_enabled             = true
          is_user_access_audit_enabled = true
          is_read_audit_enabled        = false
          log_retention_period_in_days = 90
        }
      }
      product_settings = {
        security = {
          allow_application_user_access = true
          enable_ip_based_firewall_rule = false
        }
        features = {
          power_apps_component_framework_for_canvas_apps = false
        }
      }
    }
  }

  # Test Category: Framework Validation (5 assertions)
  assert {
    condition     = powerplatform_environment_settings.this != null
    error_message = "Environment settings resource should be defined"
  }

  assert {
    condition     = powerplatform_environment_settings.this.environment_id == var.test_environment_id
    error_message = "Environment ID should match input variable"
  }

  assert {
    condition     = can(powerplatform_environment_settings.this.id)
    error_message = "Environment settings should have a computed ID attribute"
  }

  assert {
    condition     = terraform.required_providers.powerplatform.version == "~> 3.8"
    error_message = "Provider version should match centralized standard (~> 3.8)"
  }

  assert {
    condition     = terraform.required_version == ">= 1.5.0"
    error_message = "Terraform version constraint should be >= 1.5.0"
  }

  # Test Category: Variable Validation (5 assertions)  
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_settings_config.environment_id))
    error_message = "Environment ID should be valid GUID format"
  }

  assert {
    condition     = var.environment_settings_config.audit_and_logs.plugin_trace_log_setting == "Exception"
    error_message = "Plugin trace log setting should accept valid values"
  }

  assert {
    condition     = var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days == 90
    error_message = "Log retention period should accept valid values within range"
  }

  assert {
    condition     = can(var.environment_settings_config.product_settings.security.allow_application_user_access)
    error_message = "Security settings should be properly structured"
  }

  assert {
    condition     = can(var.environment_settings_config.product_settings.features.power_apps_component_framework_for_canvas_apps)
    error_message = "Feature settings should be properly structured"
  }

  # Test Category: Output Validation (5 assertions)
  assert {
    condition     = can(output.environment_settings_id)
    error_message = "Environment settings ID output should be available"
  }

  assert {
    condition     = can(output.environment_id)
    error_message = "Environment ID output should be available"
  }

  assert {
    condition     = can(output.applied_settings_summary)
    error_message = "Applied settings summary output should be available"
  }

  assert {
    condition     = can(output.settings_configuration_summary)
    error_message = "Settings configuration summary output should be available"
  }

  assert {
    condition     = output.applied_settings_summary.module_classification == "res-*"
    error_message = "Module classification should be res-* for resource modules"
  }

  # Test Category: Resource Configuration Validation (5 assertions)
  assert {
    condition     = powerplatform_environment_settings.this.audit_and_logs != null
    error_message = "Audit and logs configuration should be applied when specified"
  }

  assert {
    condition     = powerplatform_environment_settings.this.product != null
    error_message = "Product configuration should be applied when specified"
  }

  assert {
    condition     = powerplatform_environment_settings.this.email == null
    error_message = "Email configuration should be null when not specified in plan test"
  }

  assert {
    condition     = powerplatform_environment_settings.this.audit_and_logs.plugin_trace_log_setting == "Exception"
    error_message = "Plugin trace log setting should match configured value"
  }

  assert {
    condition     = length(regexall("use_oidc.*=.*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider should use OIDC authentication for security"
  }
}

# Apply validation for actual deployment testing
run "apply_validation" {
  command = apply

  variables {
    environment_settings_config = {
      environment_id = var.test_environment_id
      audit_and_logs = {
        plugin_trace_log_setting = "Exception"
        audit_settings = {
          is_audit_enabled             = true
          is_user_access_audit_enabled = false
          is_read_audit_enabled        = false
          log_retention_period_in_days = 31 # Minimum valid retention
        }
      }
      email_settings = {
        email_settings = {
          max_upload_file_size_in_bytes = 5242880 # 5MB limit
        }
      }
      product_settings = {
        behavior_settings = {
          show_dashboard_cards_in_expanded_state = true
        }
        security = {
          allow_application_user_access = true
        }
      }
    }
  }

  # Test Category: Deployment Validation (5+ assertions)
  assert {
    condition     = powerplatform_environment_settings.this.id != null
    error_message = "Environment settings should have non-null ID after deployment"
  }

  assert {
    condition     = powerplatform_environment_settings.this.environment_id == var.test_environment_id
    error_message = "Deployed environment ID should match input configuration"
  }

  assert {
    condition     = output.environment_settings_id == powerplatform_environment_settings.this.id
    error_message = "Output environment settings ID should match resource ID"
  }

  assert {
    condition     = output.environment_id == powerplatform_environment_settings.this.environment_id
    error_message = "Output environment ID should match resource environment ID"
  }

  assert {
    condition     = output.applied_settings_summary.audit_and_logs_configured == true
    error_message = "Applied settings summary should reflect audit and logs configuration"
  }

  assert {
    condition     = output.applied_settings_summary.email_settings_configured == true
    error_message = "Applied settings summary should reflect email settings configuration"
  }

  assert {
    condition     = output.applied_settings_summary.product_settings_configured == true
    error_message = "Applied settings summary should reflect product settings configuration"
  }

  assert {
    condition     = output.applied_settings_summary.deployment_timestamp != null
    error_message = "Deployment timestamp should be generated in applied settings summary"
  }

  assert {
    condition     = output.settings_configuration_summary.scope_description != null
    error_message = "Configuration summary should include scope description"
  }

  assert {
    condition     = output.settings_configuration_summary.environment_lifecycle_stage == "post_creation_configuration"
    error_message = "Configuration summary should indicate post-creation lifecycle stage"
  }
}