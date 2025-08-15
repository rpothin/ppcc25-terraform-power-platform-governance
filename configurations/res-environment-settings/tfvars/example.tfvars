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
# - AVM Compliant: Uses decomposed variables following SNFR14 best practices

# Required: Environment identifier (replace with your actual environment GUID)
environment_id = "12345678-1234-1234-1234-123456789012"

# Audit and logging configuration for compliance tracking
audit_settings = {
  # Plugin trace level for troubleshooting ("Off", "Exception", "All")
  plugin_trace_log_setting = "Exception" # Recommended for production balance

  # Comprehensive audit configuration for compliance
  is_audit_enabled             = true  # Enable general auditing for compliance
  is_user_access_audit_enabled = true  # Track user access for security monitoring
  is_read_audit_enabled        = false # Disable read auditing to reduce noise
  log_retention_period_in_days = 90    # 90 days retention for regulatory compliance
}

# Security settings for access control and network protection
security_settings = {
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

# Power Platform feature enablement and user interface behavior
feature_settings = {
  # Enable Power Apps Component Framework for canvas apps
  power_apps_component_framework_for_canvas_apps = true # Enable modern controls

  # Dashboard card display preference
  show_dashboard_cards_in_expanded_state = true # Better user experience
}

# Email and file handling configuration
email_settings = {
  # Maximum file upload size (10 MB in bytes)
  max_upload_file_size_in_bytes = 10485760 # 10 MB - reasonable limit for most use cases
}

# =============================================================================
# Alternative Configuration Examples
# =============================================================================

# ----------------------------
# MINIMAL CONFIGURATION EXAMPLE
# ----------------------------
# Uncomment and modify as needed for minimal governance requirements:
#
# environment_id = "12345678-1234-1234-1234-123456789012"
# 
# # Enable basic auditing only
# audit_settings = {
#   plugin_trace_log_setting     = "Off"
#   is_audit_enabled             = true
#   log_retention_period_in_days = 31  # Minimum retention
# }

# ----------------------------
# SECURITY-FOCUSED CONFIGURATION EXAMPLE
# ----------------------------
# Uncomment and modify as needed for high-security environments:
#
# environment_id = "12345678-1234-1234-1234-123456789012"
# 
# # Maximum auditing for high-security environments
# audit_settings = {
#   plugin_trace_log_setting      = "All"
#   is_audit_enabled              = true
#   is_user_access_audit_enabled  = true
#   is_read_audit_enabled         = true
#   log_retention_period_in_days  = 365  # 1 year retention
# }
# 
# # Restrictive security settings
# security_settings = {
#   allow_application_user_access        = false  # Disable service principals
#   allow_microsoft_trusted_service_tags = false  # Disable external services
#   enable_ip_based_firewall_rule        = true   # Strict network controls
#   allowed_ip_range_for_firewall        = ["10.0.0.0/8"]  # Internal only
# }

# ----------------------------
# DEVELOPMENT ENVIRONMENT EXAMPLE
# ----------------------------
# Uncomment and modify as needed for development environments:
#
# environment_id = "87654321-4321-4321-4321-210987654321"
# 
# # Minimal auditing for development
# audit_settings = {
#   plugin_trace_log_setting     = "Exception"
#   is_audit_enabled             = false  # Disable for development
#   log_retention_period_in_days = 31     # Minimum retention
# }
# 
# # Open security for development
# security_settings = {
#   allow_application_user_access = true
#   enable_ip_based_firewall_rule = false  # Disable firewall for development
# }
# 
# # Enable all features for testing
# feature_settings = {
#   power_apps_component_framework_for_canvas_apps = true
#   show_dashboard_cards_in_expanded_state         = true
# }
# 
# # Higher upload limits for development
# email_settings = {
#   max_upload_file_size_in_bytes = 52428800  # 50 MB for development
# }

# ----------------------------
# PRODUCTION ENVIRONMENT EXAMPLE
# ----------------------------
# Uncomment and modify as needed for production environments:
#
# environment_id = "11111111-2222-3333-4444-555555555555"
# 
# # Comprehensive auditing for production
# audit_settings = {
#   plugin_trace_log_setting      = "Exception"
#   is_audit_enabled              = true
#   is_user_access_audit_enabled  = true
#   is_read_audit_enabled         = false  # Avoid excessive logging
#   log_retention_period_in_days  = 180    # 6 months retention
# }
# 
# # Strict security for production
# security_settings = {
#   allow_application_user_access               = true   # Required for automation
#   allow_microsoft_trusted_service_tags        = true   # Required for Azure integration
#   enable_ip_based_firewall_rule               = true   # Enforce network security
#   enable_ip_based_firewall_rule_in_audit_mode = false  # Enforce rather than audit
#   allowed_ip_range_for_firewall               = ["10.0.0.0/8"]  # Corporate network only
#   allowed_service_tags_for_firewall           = ["AzureActiveDirectory"]  # Minimal services
# }
# 
# # Conservative feature settings
# feature_settings = {
#   power_apps_component_framework_for_canvas_apps = true   # Enable modern development
#   show_dashboard_cards_in_expanded_state         = false  # Compact view for efficiency
# }
# 
# # Conservative upload limits
# email_settings = {
#   max_upload_file_size_in_bytes = 5242880  # 5 MB limit for production
# }

# =============================================================================
# Configuration Guidelines
# =============================================================================
#
# Environment ID:
# - Obtain from Power Platform admin center or res-environment output
# - Must be valid GUID format
# - Environment must exist before applying settings
#
# Audit Settings:
# - plugin_trace_log_setting: "Off" (minimal), "Exception" (balanced), "All" (verbose)
# - Retention period: 31-24855 days, or -1 for forever
# - Consider storage costs for long retention periods
#
# Security Settings:
# - IP ranges must be in CIDR format (e.g., "10.0.0.0/8")
# - Service tags are Azure-specific (see Azure documentation)
# - Use audit mode initially to test firewall rules
#
# Feature Settings:
# - PCF enables modern Power Apps controls and components
# - Dashboard settings affect user experience organization-wide
#
# Email Settings:
# - File size in bytes (1 byte to 131,072,000 bytes / 125 MB)
# - Consider organizational file sharing policies
# - Balance between usability and storage costs