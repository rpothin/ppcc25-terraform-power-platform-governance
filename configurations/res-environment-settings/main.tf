# Power Platform Environment Settings Configuration
#
# This configuration manages Power Platform environment settings to control various
# aspects of Power Platform features and behaviors after environment creation,
# enabling standardized governance and compliance controls through Infrastructure as Code
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Follows AVM patterns for resource modules (res-*) with comprehensive validation
# - Anti-Corruption Layer: Discrete outputs instead of full resource exposure for interface stability  
# - Security-First: OIDC authentication, input validation, and sensitive data protection
# - Resource Deployment: Deploys primary Power Platform resources with lifecycle management
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
# - Lifecycle Management: Resource modules include `ignore_changes` for manual admin center changes
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single environment settings resource with comprehensive nested configuration
# - Post-Creation Management: Designed to configure environments after creation, complementing res-environment
#
# Environment Lifecycle Progression:
# 1. res-environment: Creates the environment 
# 2. res-environment-application-admin: Assigns permissions
# 3. res-environment-settings: Configures environment settings (this module)


# Main resource: Power Platform Environment Settings
# Manages comprehensive environment configuration for governance and compliance
resource "powerplatform_environment_settings" "this" {
  environment_id = var.environment_settings_config.environment_id

  # Audit and logging configuration for compliance tracking
  # Controls what activities are logged and for how long
  dynamic "audit_and_logs" {
    for_each = var.environment_settings_config.audit_and_logs != null ? [var.environment_settings_config.audit_and_logs] : []
    content {
      # Plugin trace logging for troubleshooting and monitoring
      plugin_trace_log_setting = audit_and_logs.value.plugin_trace_log_setting

      # Comprehensive audit settings for compliance and security
      dynamic "audit_settings" {
        for_each = audit_and_logs.value.audit_settings != null ? [audit_and_logs.value.audit_settings] : []
        content {
          is_audit_enabled             = audit_settings.value.is_audit_enabled
          is_user_access_audit_enabled = audit_settings.value.is_user_access_audit_enabled
          is_read_audit_enabled        = audit_settings.value.is_read_audit_enabled
          log_retention_period_in_days = audit_settings.value.log_retention_period_in_days
        }
      }
    }
  }

  # Email configuration for file handling and communication settings
  dynamic "email" {
    for_each = var.environment_settings_config.email_settings != null ? [var.environment_settings_config.email_settings] : []
    content {
      dynamic "email_settings" {
        for_each = email.value.email_settings != null ? [email.value.email_settings] : []
        content {
          max_upload_file_size_in_bytes = email_settings.value.max_upload_file_size_in_bytes
        }
      }
    }
  }

  # Product-specific configuration controlling Power Platform features and behaviors
  dynamic "product" {
    for_each = var.environment_settings_config.product_settings != null ? [var.environment_settings_config.product_settings] : []
    content {
      # Behavior settings controlling user interface and experience
      dynamic "behavior_settings" {
        for_each = product.value.behavior_settings != null ? [product.value.behavior_settings] : []
        content {
          show_dashboard_cards_in_expanded_state = behavior_settings.value.show_dashboard_cards_in_expanded_state
        }
      }

      # Feature enablement controls for Power Platform capabilities
      dynamic "features" {
        for_each = product.value.features != null ? [product.value.features] : []
        content {
          power_apps_component_framework_for_canvas_apps = features.value.power_apps_component_framework_for_canvas_apps
        }
      }

      # Security settings for access control and network protection
      dynamic "security" {
        for_each = product.value.security != null ? [product.value.security] : []
        content {
          allow_application_user_access               = security.value.allow_application_user_access
          allow_microsoft_trusted_service_tags        = security.value.allow_microsoft_trusted_service_tags
          allowed_ip_range_for_firewall               = security.value.allowed_ip_range_for_firewall
          allowed_service_tags_for_firewall           = security.value.allowed_service_tags_for_firewall
          enable_ip_based_firewall_rule               = security.value.enable_ip_based_firewall_rule
          enable_ip_based_firewall_rule_in_audit_mode = security.value.enable_ip_based_firewall_rule_in_audit_mode
          reverse_proxy_ip_addresses                  = security.value.reverse_proxy_ip_addresses
        }
      }
    }
  }

  # Lifecycle management for manual admin center changes
  # Allows administrators to make manual adjustments without Terraform interference
  lifecycle {
    ignore_changes = [
      # Allow manual changes to audit settings in admin center
      audit_and_logs,
      # Allow manual changes to email settings
      email,
      # Allow manual changes to product configurations
      product
    ]
  }
}