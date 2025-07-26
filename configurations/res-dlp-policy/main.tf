# res-dlp-policy Configuration
#
# This configuration deploys a Data Loss Prevention (DLP) policy in Power Platform
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Resource module for DLP policy deployment
# - Anti-Corruption Layer: Outputs only resource IDs and computed attributes
# - Security-First: OIDC authentication, no secrets in code
# - Resource Deployment: Follows WAF and Power Platform governance best practices
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform due to lack of DLP support in azurerm/azapi
# - Backend Strategy: Azure Storage with OIDC for secure, keyless authentication
# - Resource Organization: All DLP policy logic in this module for clarity and reusability

resource "powerplatform_data_loss_prevention_policy" "this" {
  display_name                      = var.display_name
  default_connectors_classification = var.default_connectors_classification
  environment_type                  = var.environment_type
  environments                      = var.environments

  business_connectors     = var.business_connectors
  non_business_connectors = var.non_business_connectors
  blocked_connectors      = var.blocked_connectors

  custom_connectors_patterns = var.custom_connectors_patterns
}
