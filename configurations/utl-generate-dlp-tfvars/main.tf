# Smart DLP tfvars Generator: Data Processing Logic (Onboarding Only)
#
# This file implements the core logic for generating tfvars files from live DLP policy data.
# Focuses only on onboarding existing policies to IaC (no template generation).
# Follows AVM and project standards: clear separation of concerns, security-first, and anti-corruption outputs.

# Direct access to live DLP policies data
data "powerplatform_data_loss_prevention_policies" "current" {}

locals {
  # Find the policy by display_name in live data
  matching_policies = [
    for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy
    if policy.display_name == var.source_policy_name
  ]

  selected_policy = length(local.matching_policies) > 0 ? local.matching_policies[0] : null
  policy_exists   = local.selected_policy != null
}

# Extract connector data from selected policy (with safe defaults)
locals {
  default_connector_object = {
    id                           = ""
    default_action_rule_behavior = ""
    action_rules                 = []
    endpoint_rules               = []
  }

  # Extract and normalize business connectors
  business_connectors = local.policy_exists ? [
    for c in(local.selected_policy["business_connectors"] != null ? local.selected_policy["business_connectors"] : []) :
    can(c.id) ? c : merge(local.default_connector_object, { id = tostring(c) })
  ] : []

  # Extract and normalize non-business connectors
  non_business_connectors = local.policy_exists ? [
    for c in(local.selected_policy["non_business_connectors"] != null ? local.selected_policy["non_business_connectors"] : []) :
    can(c.id) ? c : merge(local.default_connector_object, { id = tostring(c) })
  ] : []

  # Extract and normalize blocked connectors
  blocked_connectors = local.policy_exists ? [
    for c in(local.selected_policy["blocked_connectors"] != null ? local.selected_policy["blocked_connectors"] : []) :
    can(c.id) ? c : merge(local.default_connector_object, { id = tostring(c) })
  ] : []

  # Extract environment and custom connector settings from policy
  environments = local.policy_exists && local.selected_policy["environments"] != null ? local.selected_policy["environments"] : []
  custom_connectors_patterns = local.policy_exists && local.selected_policy["custom_connectors_patterns"] != null ? local.selected_policy["custom_connectors_patterns"] : [
    {
      order            = 1
      host_url_pattern = "*"
      data_group       = "Blocked"
    }
  ]
}

# Generate tfvars content in HCL format (not JSON) for direct use
locals {
  tfvars_content = <<-TFVARS
# Generated tfvars for DLP policy: ${var.source_policy_name}
# Generated on: ${timestamp()}
# Source: utl-generate-dlp-tfvars

display_name                      = "${var.source_policy_name}"
default_connectors_classification = "${local.policy_exists ? local.selected_policy.default_connectors_classification : "Blocked"}"
environment_type                  = "${local.policy_exists ? local.selected_policy.environment_type : "OnlyEnvironments"}"

environments = ${jsonencode(local.environments)}

business_connectors = [
%{for c in local.business_connectors~}
  {
    id                           = "${c.id}"
    default_action_rule_behavior = "${c.default_action_rule_behavior}"
    action_rules                 = []
    endpoint_rules               = []
  }%{if c != local.business_connectors[length(local.business_connectors)-1]},
%{endif}
%{endfor~}
]

non_business_connectors = [
%{for c in local.non_business_connectors~}
  {
    id                           = "${c.id}"
    default_action_rule_behavior = "${c.default_action_rule_behavior}"
    action_rules                 = []
    endpoint_rules               = []
  }%{if c != local.non_business_connectors[length(local.non_business_connectors)-1]},
%{endif}
%{endfor~}
]

blocked_connectors = [
%{for c in local.blocked_connectors~}
  {
    id                           = "${c.id}"
    default_action_rule_behavior = "${c.default_action_rule_behavior}"
    action_rules                 = []
    endpoint_rules               = []
  }%{if c != local.blocked_connectors[length(local.blocked_connectors)-1]},
%{endif}
%{endfor~}
]

custom_connectors_patterns = [
%{for p in local.custom_connectors_patterns~}
  {
    order            = ${p.order}
    host_url_pattern = "${p.host_url_pattern}"
    data_group       = "${p.data_group}"
  }%{if p != local.custom_connectors_patterns[length(local.custom_connectors_patterns)-1]},
%{endif}
%{endfor~}
]
TFVARS
}

# Write the tfvars file to disk
resource "local_file" "generated_tfvars" {
  count    = local.policy_exists ? 1 : 0
  filename = var.output_file
  content  = local.tfvars_content

  # Ensure proper file permissions
  file_permission = "0644"
}

# Validate that we found the policy and generated valid content
locals {
  tfvars_valid = local.policy_exists && (
    length(local.business_connectors) +
    length(local.non_business_connectors) +
    length(local.blocked_connectors)
  ) > 0
}

# Outputs are defined in outputs.tf (see anti-corruption layer pattern)