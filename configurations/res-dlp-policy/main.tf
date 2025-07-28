# res-dlp-policy Configuration
#
# This configuration deploys a Data Loss Prevention (DLP) policy in Power Platform
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

# Test

data "powerplatform_connectors" "all" {}

locals {
  # Set of business connector IDs for auto-classification
  business_connector_ids = [for c in var.business_connectors : c.id]

  # Auto-classified non-business connectors (if not provided)
  auto_non_business_connectors = (
    length(var.non_business_connectors) == 0
    ) ? [
    for c in data.powerplatform_connectors.all.connectors : {
      id                           = c.id
      default_action_rule_behavior = ""
      action_rules                 = []
      endpoint_rules               = []
    }
    if c.unblockable == true && !contains(local.business_connector_ids, c.id)
  ] : var.non_business_connectors

  # Auto-classified blocked connectors (if not provided)
  auto_blocked_connectors = (
    length(var.blocked_connectors) == 0
    ) ? [
    for c in data.powerplatform_connectors.all.connectors : {
      id                           = c.id
      default_action_rule_behavior = ""
      action_rules                 = []
      endpoint_rules               = []
    }
    if c.unblockable == false && !contains(local.business_connector_ids, c.id)
  ] : var.blocked_connectors
}

# Validation: Ensure all business connector IDs exist in the tenant
check "business_connector_ids_exist" {
  assert {
    condition = alltrue([
      for bc in var.business_connectors :
      contains([for c in data.powerplatform_connectors.all.connectors : c.id], bc.id)
    ])
    error_message = <<-EOT
      Invalid business connector IDs detected: ${join(", ", [
    for bc in var.business_connectors :
    bc.id if !contains([for c in data.powerplatform_connectors.all.connectors : c.id], bc.id)
])}
      To see available connectors, run:
        terraform plan -target=data.powerplatform_connectors.all
      EOT
}
}

resource "powerplatform_data_loss_prevention_policy" "this" {
  display_name                      = var.display_name
  default_connectors_classification = var.default_connectors_classification
  environment_type                  = var.environment_type
  environments                      = var.environments

  business_connectors     = var.business_connectors
  non_business_connectors = local.auto_non_business_connectors
  blocked_connectors      = local.auto_blocked_connectors

  custom_connectors_patterns = var.custom_connectors_patterns

  lifecycle {
    ignore_changes = []
  }
}

