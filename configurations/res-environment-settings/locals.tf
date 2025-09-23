# Local Values for Power Platform Environment Settings Logic
#
# This file contains computed values and logic for the environment settings module,
# including workarounds for provider limitations and conditional logic following 
# AVM patterns for complex transformation when main.tf exceeds 150 lines.
#
# Key Features:
# - Provider Bug Mitigation: Logic to prevent Power Platform provider state inconsistencies
# - Security Settings Validation: Determines when security block should be created
# - AVM Compliance: Follows AVM patterns for resource module local value organization
# - Future Compatibility: Structured to support managed environment features when available

locals {
  # ==========================================================================
  # PROVIDER BUG WORKAROUND: Security Settings Validation
  # ==========================================================================

  # Determine if we have valid security settings that should be applied
  # WORKAROUND: Completely disable security block for standard environments
  # 
  # Provider Issue: The microsoft/power-platform provider incorrectly converts null 
  # firewall fields to empty sets after apply, causing "inconsistent result" errors
  # 
  # Platform Limitation: Standard environments cannot use ANY security/firewall settings
  # ALL security settings require managed environments due to timing issues:
  # - allow_application_user_access (managed environment only)
  # - allow_microsoft_trusted_service_tags (managed environment only)  
  # - reverse_proxy_ip_addresses (managed environment only)
  # - All firewall settings (managed environment only)
  # 
  # Solution: Completely omit security block until managed environments are implemented
  has_valid_security_settings = false

  # ==========================================================================
  # SECURITY CONFIGURATION: Working Settings Only
  # ==========================================================================

  # Extract only the security settings that work with standard environments
  # RESULT: No security settings work with standard environments due to managed environment requirement
  working_security_settings = null

  # WHY: ALL security settings are omitted entirely for standard environments
  # CONTEXT: Standard environments don't support ANY security/firewall configuration
  # MANAGED ENV REQUIRED: ALL these fields require managed environments due to timing issues:
  #   - allow_application_user_access (managed environment only)
  #   - allow_microsoft_trusted_service_tags (managed environment only)
  #   - reverse_proxy_ip_addresses (managed environment only)
  #   - enable_ip_based_firewall_rule (managed environment only)
  #   - enable_ip_based_firewall_rule_in_audit_mode (managed environment only)
  #   - allowed_ip_range_for_firewall (managed environment only)
  #   - allowed_service_tags_for_firewall (managed environment only)
  # 
  # PROVIDER BUG: Setting these fields to null still causes state inconsistency
  # SOLUTION: Omit entire security block so provider doesn't attempt to manage ANY security fields
  # FUTURE: When managed environments are implemented, security settings can be enabled

  # ==========================================================================
  # DEPLOYMENT VALIDATION
  # ==========================================================================

  # Configuration validation for troubleshooting and monitoring
  configuration_validation = {
    has_audit_settings    = var.audit_settings != null
    has_security_settings = local.has_valid_security_settings
    has_feature_settings  = var.feature_settings != null
    has_email_settings    = var.email_settings != null

    # Count of configured setting types for summary reporting
    configured_setting_types = sum([
      var.audit_settings != null ? 1 : 0,
      local.has_valid_security_settings ? 1 : 0,
      var.feature_settings != null ? 1 : 0,
      var.email_settings != null ? 1 : 0
    ])
  }

  # ==========================================================================
  # COMPATIBILITY METADATA
  # ==========================================================================

  # Track compatibility and workaround status for governance reporting
  compatibility_status = {
    provider_version          = "3.8.x"
    standard_environment_mode = true  # Currently using standard environments
    managed_environment_mode  = false # Future: Set to true when using managed environments

    # Security feature compatibility (all require managed environments)
    firewall_rules_supported     = false # Managed environments only
    reverse_proxy_supported      = false # Managed environments only (timing issue)
    application_access_supported = false # Managed environments only (timing issue)
    service_tags_supported       = false # Managed environments only (timing issue)

    # Workaround status
    provider_bug_workaround_active = true
    security_block_conditional     = true
    firewall_fields_omitted        = true
  }
}