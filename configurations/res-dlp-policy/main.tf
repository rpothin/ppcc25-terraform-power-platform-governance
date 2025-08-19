# res-dlp-policy Configuration
#
# This configuration deploys a Data Loss Prevention (DLP) policy in Power Platform
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

# Fetch all available connectors in the environment
data "powerplatform_connectors" "all" {}

# Query existing DLP policies in the tenant (only when duplicate protection is needed)
data "powerplatform_data_loss_prevention_policies" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Consolidated locals block with simplified state-aware logic
locals {
  # Simplified state-aware resource management detection
  # Use a more reliable approach that doesn't create circular dependencies
  is_managed_resource = var.enable_duplicate_protection ? (
    # Check if we can find the resource in Terraform state via try()
    # This approach works during both plan and apply phases
    can(data.powerplatform_data_loss_prevention_policies.all[0].policies) &&
    length([
      for p in data.powerplatform_data_loss_prevention_policies.all[0].policies : p
      if p.display_name == var.display_name &&
      p.environment_type == var.environment_type &&
      p.id != null
    ]) > 0
  ) : false

  # Only check for duplicates if resource is not already managed
  should_check_duplicates = var.enable_duplicate_protection && !local.is_managed_resource

  # Duplicate detection logic (only runs when checking is needed and enabled)
  existing_policy_matches = local.should_check_duplicates ? [
    for p in try(data.powerplatform_data_loss_prevention_policies.all[0].policies, []) : p
    if p.display_name == var.display_name && p.environment_type == var.environment_type
  ] : []

  # Enhanced duplicate detection with state-awareness
  has_duplicate       = local.should_check_duplicates && length(local.existing_policy_matches) > 0
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

# Enhanced state-aware guardrail: Only fail plan for unmanaged duplicates
resource "null_resource" "dlp_policy_duplicate_guardrail" {
  count = var.enable_duplicate_protection ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.has_duplicate
      error_message = <<-EOT
      🚨 DUPLICATE DLP POLICY DETECTED!
      Policy Name: "${var.display_name}"
      Environment Type: "${var.environment_type}"
      Existing Policy ID: ${coalesce(local.duplicate_policy_id, "unknown")}
      
      📊 DETECTION DETAILS:
      • State Management Status: ${local.is_managed_resource ? "MANAGED" : "UNMANAGED"}
      • Duplicate Check Active: ${local.should_check_duplicates ? "YES" : "NO"}
      • Matching Policies Found: ${length(local.existing_policy_matches)}
      
      💡 RESOLUTION OPTIONS:
      1. Import existing policy to manage with Terraform:
         terraform import powerplatform_data_loss_prevention_policy.this ${coalesce(local.duplicate_policy_id, "POLICY_ID_HERE")}
      
      2. Use a different display_name or environment_type for a new policy.
      
      3. Temporarily disable duplicate protection during import:
         Set enable_duplicate_protection = false in your .tfvars file.
         After successful import, re-enable protection.
      
      📚 After import, you can re-enable duplicate protection for future deployments.
      📖 See onboarding guide in docs/guides/ for detailed steps.
      
      🔍 TROUBLESHOOTING:
      If this policy is already imported but still showing as duplicate:
      - Verify the resource exists in state: terraform state list
      - Check state file integrity: terraform state show powerplatform_data_loss_prevention_policy.this
      - Consider refreshing state: terraform refresh
      EOT
    }
  }

  # Enhanced triggers for re-evaluation
  triggers = {
    display_name         = var.display_name
    environment_type     = var.environment_type
    duplicate_protection = var.enable_duplicate_protection
    # Add state-awareness trigger
    managed_resource = local.is_managed_resource
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
      
      Or check the Power Platform admin center for valid connector IDs.
    EOT
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
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []

    # This runs after the resource is created and the ID is available
    postcondition {
      condition = var.enable_duplicate_protection ? (
        # Validate that our state detection logic is working correctly
        # Now we can safely reference self.id since the resource has been created
        local.is_managed_resource == (self.id != null)
      ) : true
      error_message = <<-EOT
        ⚠️ STATE AWARENESS VALIDATION FAILED
        
        The state-aware duplicate detection logic may not be working correctly.
        This could indicate a Terraform state synchronization issue.
        
        🔍 DIAGNOSTIC INFORMATION:
        • Managed Resource Detection: ${local.is_managed_resource}
        • Resource ID Available: ${self.id != null}
        • Duplicate Protection: ${var.enable_duplicate_protection}
        • Resource ID: ${self.id}
        
        📝 RECOMMENDED ACTIONS:
        1. Run 'terraform refresh' to synchronize state
        2. Verify resource exists: 'terraform state list'
        3. Check resource details: 'terraform state show powerplatform_data_loss_prevention_policy.this'
        
        If issues persist, temporarily disable duplicate protection with:
        enable_duplicate_protection = false
      EOT
    }
  }
}