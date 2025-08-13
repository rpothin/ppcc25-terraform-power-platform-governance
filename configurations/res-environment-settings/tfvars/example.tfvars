# Example Environment Settings Configuration for Power Platform Environment
#
# This file contains example values for the res-environment-settings configuration.
# Copy this file and customize it for your specific environment governance needs.
#
# Configuration Philosophy:
# - Governance Focused: Values enabling compliance and audit requirements
# - Security Conscious: Restrictive defaults with clear security controls
# - Operationally Friendly: Settings that support operational monitoring
# - Change Trackable: Version controlled for audit and rollback capability

# Core environment settings configuration
environment_settings_config = {
  # Required: Environment identifier (replace with your actual environment GUID)
  environment_id = "12345678-1234-1234-1234-123456789012"

  # Audit and logging configuration for compliance tracking
  audit_and_logs = {
    # Plugin trace level for troubleshooting ("Off", "Exception", "All")
    plugin_trace_log_setting = "Exception" # Recommended for production balance

    # Detailed audit settings for compliance requirements
    audit_settings = {
      is_audit_enabled             = true  # Enable general auditing for compliance
      is_user_access_audit_enabled = true  # Track user access for security monitoring
      is_read_audit_enabled        = false # Disable read auditing to reduce noise
      log_retention_period_in_days = 90    # 90 days retention for regulatory compliance
    }
  }

  # Email and file handling configuration
  email_settings = {
    email_settings = {
      # Maximum file upload size (10 MB in bytes)
      max_upload_file_size_in_bytes = 10485760 # 10 MB - reasonable limit for most use cases
    }
  }

  # Product-specific settings for Power Platform features
  product_settings = {
    # User interface behavior settings
    behavior_settings = {
      # Dashboard card display preference
      show_dashboard_cards_in_expanded_state = true # Better user experience
    }

    # Power Platform feature enablement
    features = {
      # Enable Power Apps Component Framework for canvas apps
      power_apps_component_framework_for_canvas_apps = true # Enable modern controls
    }

    # Security settings for access control and network protection
    security = {
      # Allow service principal access for automation
      allow_application_user_access = true # Required for service principal operations

      # Allow Microsoft trusted service tags for integration
      allow_microsoft_trusted_service_tags = true # Enable Azure service integration

      # IP-based firewall configuration
      enable_ip_based_firewall_rule = true # Enable network-level security

      # Enable audit mode for firewall (recommended for initial deployment)
      enable_ip_based_firewall_rule_in_audit_mode = true # Test firewall rules first

      # Allowed IP ranges for corporate network access
      allowed_ip_range_for_firewall = [
        "10.0.0.0/8",     # Internal corporate network
        "192.168.1.0/24", # Branch office network
        "203.0.113.0/24"  # External partner network (example)
      ]

      # Allowed Azure service tags for integration
      allowed_service_tags_for_firewall = [
        "ApiManagement",        # Azure API Management
        "AzureActiveDirectory", # Azure AD integration
        "Storage"               # Azure Storage access
      ]

      # Reverse proxy IP addresses (if using corporate proxy)
      reverse_proxy_ip_addresses = [
        "203.0.113.100", # Corporate proxy server 1
        "203.0.113.101"  # Corporate proxy server 2 (example)
      ]
    }
  }
}

# Alternative minimal configuration example (uncomment to use):
# environment_settings_config = {
#   environment_id = "12345678-1234-1234-1234-123456789012"
#   
#   # Enable basic auditing only
#   audit_and_logs = {
#     plugin_trace_log_setting = "Off"
#     audit_settings = {
#       is_audit_enabled = true
#       log_retention_period_in_days = 31  # Minimum retention
#     }
#   }
# }

# Alternative security-focused configuration example (uncomment to use):
# environment_settings_config = {
#   environment_id = "12345678-1234-1234-1234-123456789012"
#   
#   # Maximum auditing for high-security environments
#   audit_and_logs = {
#     plugin_trace_log_setting = "All"
#     audit_settings = {
#       is_audit_enabled             = true
#       is_user_access_audit_enabled = true
#       is_read_audit_enabled        = true
#       log_retention_period_in_days = 365  # 1 year retention
#     }
#   }
#   
#   # Restrictive security settings
#   product_settings = {
#     security = {
#       allow_application_user_access        = false  # Disable service principals
#       allow_microsoft_trusted_service_tags = false  # Disable external services
#       enable_ip_based_firewall_rule        = true   # Strict network controls
#       allowed_ip_range_for_firewall        = ["10.0.0.0/8"]  # Internal only
#     }
#   }
# }