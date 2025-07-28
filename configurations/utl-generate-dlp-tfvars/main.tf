# Smart DLP tfvars Generator Configuration
#
# This configuration automates the generation of tfvars files for DLP policy management by processing exported policy and connector data, supporting both new policy creation and onboarding of existing policies to IaC.
#
# Key Features:
# - AVM-Inspired Structure: Follows Azure Verified Module (AVM) best practices with Power Platform provider adaptations
# - Anti-Corruption Layer: Outputs only discrete computed attributes, never full resource objects
# - Security-First: OIDC authentication, no hardcoded secrets
# - Utility-Specific: No resource deployment, only data processing and export
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Utility module for data transformation and export


# --- Data Processing Logic for Smart DLP tfvars Generator ---

# 1. Load exported DLP policy and connector data (JSON files must be present in the working directory)
locals {
  dlp_policies_json = fileexists("${path.module}/terraform-output-utl-export-dlp-policies.json") ? file("${path.module}/terraform-output-utl-export-dlp-policies.json") : null
  connectors_json   = fileexists("${path.module}/terraform-output-utl-export-connectors.json") ? file("${path.module}/terraform-output-utl-export-connectors.json") : null
  dlp_policies      = local.dlp_policies_json != null ? jsondecode(local.dlp_policies_json) : {}
  connectors        = local.connectors_json != null ? jsondecode(local.connectors_json) : {}
}

# 2. Select policy by name (for onboarding) or use template (for new policy)
locals {
  onboarding_mode = var.source_policy_name != ""
  selected_policy = local.onboarding_mode && contains(keys(local.dlp_policies), var.source_policy_name) ? local.dlp_policies[var.source_policy_name] : null
  policy_name     = local.onboarding_mode ? var.source_policy_name : (var.policy_name != null ? var.policy_name : "New DLP Policy")
  template_type   = var.template_type != "" ? var.template_type : "strict-security"
}

# 3. Classify connectors (business, non-business, blocked) based on selected policy or template
locals {
  business_connectors     = local.onboarding_mode && local.selected_policy != null ? local.selected_policy["business_connectors"] : []
  non_business_connectors = local.onboarding_mode && local.selected_policy != null ? local.selected_policy["non_business_connectors"] : []
  blocked_connectors      = local.onboarding_mode && local.selected_policy != null ? local.selected_policy["blocked_connectors"] : []
}

# 4. Render tfvars content using the appropriate template
locals {
  tfvars_content = templatefile("${path.module}/templates/${local.template_type}.tftpl", {
    policy_name             = local.policy_name
    business_connectors     = local.business_connectors
    non_business_connectors = local.non_business_connectors
    blocked_connectors      = local.blocked_connectors
  })
}

# 5. Validate generated tfvars for completeness
locals {
  tfvars_valid = length(local.business_connectors) + length(local.non_business_connectors) + length(local.blocked_connectors) > 0
}

# 6. Output generated tfvars content and summary
output "generated_tfvars_content" {
  description = "The generated tfvars content for the selected or templated DLP policy."
  value       = local.tfvars_content
}

output "generation_summary" {
  description = "Summary of the tfvars generation process, including input parameters and validation results."
  value = {
    source_policy_name      = var.source_policy_name
    template_type           = var.template_type
    output_file             = var.output_file
    onboarding_mode         = local.onboarding_mode
    tfvars_valid            = local.tfvars_valid
    business_connectors     = local.business_connectors
    non_business_connectors = local.non_business_connectors
    blocked_connectors      = local.blocked_connectors
  }
}
