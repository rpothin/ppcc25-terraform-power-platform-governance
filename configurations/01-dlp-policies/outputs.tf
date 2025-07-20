# Output for Data Loss Prevention Policies Export
# This output exposes the current DLP policies for analysis and migration planning
# Using enhanced anti-corruption layer pattern to provide complete migration data while maintaining AVM compliance

# TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
# output "dlp_policies" {
#   description = <<-EOT
#     DLP policies structured for migration analysis with complete configuration data.
#     Each policy includes all necessary information to recreate via IaC without regressions.
#     
#     Structure:
#     - policy_count: Total number of DLP policies in the tenant
#     - policies: Array of policy objects with complete configuration
#       - Basic metadata (id, display_name, environment_type, environments)
#       - Connector classifications (business, non_business, blocked)
#       - Custom connector patterns for migration accuracy
#       - Summary counts for quick analysis
#   EOT
#   value = {
#     policy_count = length(data.powerplatform_data_loss_prevention_policies.current.policies)
#     policies = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : {
#       # Core policy metadata
#       id                                = policy.id
#       display_name                      = policy.display_name
#       environment_type                  = policy.environment_type
#       environments                      = toset(policy.environments)
#       default_connectors_classification = policy.default_connectors_classification
#
#       # Audit information
#       created_by         = policy.created_by
#       created_time       = policy.created_time
#       last_modified_by   = policy.last_modified_by
#       last_modified_time = policy.last_modified_time
#
#       # Business connectors (sensitive data connectors)
#       business_connectors = [for conn in policy.business_connectors : {
#         id                           = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules_count           = length(conn.action_rules)
#         endpoint_rules_count         = length(conn.endpoint_rules)
#       }]
#
#       # Non-business connectors (general data connectors)
#       non_business_connectors = [for conn in policy.non_business_connectors : {
#         id                           = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules_count           = length(conn.action_rules)
#         endpoint_rules_count         = length(conn.endpoint_rules)
#       }]
#
#       # Blocked connectors (prohibited connectors)
#       blocked_connectors = [for conn in policy.blocked_connectors : {
#         id                           = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules_count           = length(conn.action_rules)
#         endpoint_rules_count         = length(conn.endpoint_rules)
#       }]
#
#       # Custom connector patterns (critical for custom connector policies)
#       custom_connectors_patterns = [for pattern in policy.custom_connectors_patterns : {
#         data_group       = pattern.data_group
#         host_url_pattern = pattern.host_url_pattern
#         order            = pattern.order
#       }]
#
#       # Summary counts for quick analysis and validation
#       connector_summary = {
#         business_count        = length(policy.business_connectors)
#         non_business_count    = length(policy.non_business_connectors)
#         blocked_count         = length(policy.blocked_connectors)
#         custom_patterns_count = length(policy.custom_connectors_patterns)
#         total_connectors      = length(policy.business_connectors) + length(policy.non_business_connectors) + length(policy.blocked_connectors)
#       }
#     }]
#   }
#   sensitive = false
# }

# TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
# output "dlp_policies_detailed_rules" {
#   description = <<-EOT
#     Detailed connector action and endpoint rules for DLP policies.
#     
#     This output includes complete rule configurations which may contain:
#     - Specific action IDs and their allow/block behaviors
#     - Endpoint URLs and access patterns
#     - Custom rule configurations
#     
#     Use this data for:
#     - Complete policy recreation with exact rule preservation
#     - Advanced migration scenarios requiring granular rule control
#     - Compliance auditing of specific connector behaviors
#     
#     Note: Marked as sensitive due to potential exposure of internal endpoints and detailed security configurations.
#   EOT
#   value = {
#     policies_with_detailed_rules = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : {
#       policy_id   = policy.id
#       policy_name = policy.display_name
#
#       # Complete business connector rules
#       business_connectors_detailed = [for conn in policy.business_connectors : {
#         connector_id                 = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules = [for rule in conn.action_rules : {
#           action_id = rule.action_id
#           behavior  = rule.behavior
#         }]
#         endpoint_rules = [for rule in conn.endpoint_rules : {
#           endpoint = rule.endpoint
#           behavior = rule.behavior
#           order    = rule.order
#         }]
#       }]
#
#       # Complete non-business connector rules
#       non_business_connectors_detailed = [for conn in policy.non_business_connectors : {
#         connector_id                 = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules = [for rule in conn.action_rules : {
#           action_id = rule.action_id
#           behavior  = rule.behavior
#         }]
#         endpoint_rules = [for rule in conn.endpoint_rules : {
#           endpoint = rule.endpoint
#           behavior = rule.behavior
#           order    = rule.order
#         }]
#       }]
#
#       # Complete blocked connector rules
#       blocked_connectors_detailed = [for conn in policy.blocked_connectors : {
#         connector_id                 = conn.id
#         default_action_rule_behavior = conn.default_action_rule_behavior
#         action_rules = [for rule in conn.action_rules : {
#           action_id = rule.action_id
#           behavior  = rule.behavior
#         }]
#         endpoint_rules = [for rule in conn.endpoint_rules : {
#           endpoint = rule.endpoint
#           behavior = rule.behavior
#           order    = rule.order
#         }]
#       }]
#     }]
#   }
#   sensitive = true
# }

# Hello World Outputs - TODO: Remove after testing
# Simple outputs for testing the integration testing infrastructure

output "test_message" {
  description = "A simple test message"
  value       = local.test_message
}

output "test_number" {
  description = "A simple test number"
  value       = local.test_number
}

output "test_input_variable" {
  description = "The value of the test input variable"
  value       = var.test_input
}

output "test_computed_values" {
  description = "Computed values for testing"
  value = {
    list_length = length(local.test_list)
    map_keys    = keys(local.test_map)
    environment = local.test_map.environment
    workspace   = terraform.workspace
  }
}
