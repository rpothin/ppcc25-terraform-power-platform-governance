# res-dlp-policy Configuration
#
# This configuration deploys a Data Loss Prevention (DLP) policy in Power Platform
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

data "powerplatform_connectors" "all" {}

# Query existing DLP policies in the tenant
data "powerplatform_data_loss_prevention_policies" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Consolidated locals block with all logic
locals {
  # Duplicate detection logic
  existing_policy_matches = var.enable_duplicate_protection ? [
    for p in try(data.powerplatform_data_loss_prevention_policies.all[0].policies, []) : p
    if p.display_name == var.display_name && p.environment_type == var.environment_type
  ] : []
  has_duplicate       = length(local.existing_policy_matches) > 0
  duplicate_policy_id = local.has_duplicate ? local.existing_policy_matches[0].id : null

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

# Guardrail: Fail plan if duplicate detected
resource "null_resource" "dlp_policy_duplicate_guardrail" {
  count = var.enable_duplicate_protection ? 1 : 0
  lifecycle {
    precondition {
      condition     = !local.has_duplicate
      error_message = <<-EOT
        🚨 DUPLICATE DLP POLICY DETECTED!
        Policy Name: "${var.display_name}"
        Environment Type: "${var.environment_type}"
        Existing Policy ID: ${local.duplicate_policy_id}

        💡 RESOLUTION OPTIONS:
        1. Import existing policy:
           terraform import powerplatform_data_loss_prevention_policy.this ${local.duplicate_policy_id}
        2. Use a different display_name or environment_type.
        3. Set enable_duplicate_protection = false (not recommended).

        📚 See onboarding guide for details.
      EOT
    }
  }
}

# Main DLP Policy Resource
resource "powerplatform_data_loss_prevention_policy" "this" {
  depends_on = [null_resource.dlp_policy_duplicate_guardrail]

  display_name                      = var.display_name
  default_connectors_classification = var.default_connectors_classification
  environment_type                  = var.environment_type
  environments                      = var.environments

  business_connectors     = var.business_connectors
  non_business_connectors = local.auto_non_business_connectors
  blocked_connectors      = local.auto_blocked_connectors

  custom_connectors_patterns = var.custom_connectors_patterns

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Allow manual changes in Power Platform admin center without drift
    ]
  }
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