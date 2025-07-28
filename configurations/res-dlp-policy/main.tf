# res-dlp-policy Configuration
#
# This configuration deploys a Data Loss Prevention (DLP) policy in Power Platform
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

data "powerplatform_connectors" "all" {}

locals {
  # Helper: Set of business connector IDs (empty if null)
  business_connector_ids = var.business_connectors != null ? toset(var.business_connectors) : toset([])

  # Auto-classified non-business connectors (if needed)
  auto_non_business_connectors = (
    var.business_connectors != null && var.non_business_connectors == null
    ) ? [
    for c in data.powerplatform_connectors.all.connectors : {
      id                           = c.id
      default_action_rule_behavior = "Allow"
      action_rules                 = []
      endpoint_rules               = []
    }
    if c.unblockable == true && !contains(local.business_connector_ids, c.id)
  ] : null

  # Auto-classified blocked connectors (if needed)
  auto_blocked_connectors = (
    var.business_connectors != null && var.blocked_connectors == null
    ) ? [
    for c in data.powerplatform_connectors.all.connectors : {
      id                           = c.id
      default_action_rule_behavior = "Block"
      action_rules                 = []
      endpoint_rules               = []
    }
    if c.unblockable == false && !contains(local.business_connector_ids, c.id)
  ] : null

  # Final business connectors: if business_connectors is provided, generate objects, else null (must be provided manually)
  final_business_connectors = var.business_connectors != null ? [
    for id in var.business_connectors : {
      id                           = id
      default_action_rule_behavior = "Allow"
      action_rules                 = []
      endpoint_rules               = []
    }
  ] : null

  # Final non-business connectors: use user value, else auto-classified, else null
  final_non_business_connectors = var.non_business_connectors != null ? var.non_business_connectors : local.auto_non_business_connectors

  # Final blocked connectors: use user value, else auto-classified, else null
  final_blocked_connectors = var.blocked_connectors != null ? var.blocked_connectors : local.auto_blocked_connectors
}

# Validation: Ensure all business connector IDs exist in the tenant
check "business_connector_ids_exist" {
  assert {
    condition = var.business_connectors == null ? true : alltrue([
      for id in var.business_connectors :
      contains([for c in data.powerplatform_connectors.all.connectors : c.id], id)
    ])
    error_message = <<-EOT
      Invalid business connector IDs detected: ${join(", ", [
    for id in coalesce(var.business_connectors, []) :
    id if !contains([for c in data.powerplatform_connectors.all.connectors : c.id], id)
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

  business_connectors     = local.final_business_connectors
  non_business_connectors = local.final_non_business_connectors
  blocked_connectors      = local.final_blocked_connectors

  custom_connectors_patterns = var.custom_connectors_patterns

  lifecycle {
    ignore_changes = [
      # Metadata fields that are automatically updated by Power Platform
      created_by,         # ✅ User who created the policy (read-only)
      created_time,       # ✅ Time when the policy was created (read-only)
      last_modified_by,   # ✅ User who last modified the policy (read-only)
      last_modified_time, # ✅ Time when the policy was last modified (read-only)
      id                  # ✅ Unique name of the policy (read-only)
    ]
  }
}

# Input validation: If business_connectors is null, both non_business_connectors and blocked_connectors must be provided
resource "null_resource" "auto_classification_guard" {
  count = var.business_connectors == null && (var.non_business_connectors == null || var.blocked_connectors == null) ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: When business_connectors is null, both non_business_connectors and blocked_connectors must be provided.' && exit 1"
  }
}