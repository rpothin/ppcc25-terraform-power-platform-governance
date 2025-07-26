# Export Power Platform Connectors Utility Configuration
#
# This configuration exports all connectors in the tenant using AVM best practices.
#
# Key Features:
# - AVM-Inspired Structure: Modular, reusable, and secure
# - Anti-Corruption Layer: Outputs only computed attributes
# - Security-First: OIDC authentication, no secrets in code
# - Utility-Specific: No resource creation, only data export
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for direct API access
# - Backend Strategy: Azure Storage with OIDC for secure, keyless authentication
# - Resource Organization: Data source only, no stateful resources

provider "powerplatform" {
  use_oidc = true
}

data "powerplatform_connectors" "all" {}
