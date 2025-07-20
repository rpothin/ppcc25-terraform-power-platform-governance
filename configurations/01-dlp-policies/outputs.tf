# Output for Data Loss Prevention Policies Export
# This output exposes the current DLP policies for analysis and migration planning
# Using anti-corruption layer pattern to provide discrete attributes instead of complete resource objects

output "dlp_policies" {
  description = <<-EOT
    Data Loss Prevention Policies information with discrete attributes:
    - policy_count: Total number of DLP policies in the tenant
    - policy_ids: List of policy identifiers for reference
    - policy_names: List of policy display names for identification
    - environment_types: Types of environments each policy covers
    - created_by: Users who created each policy
    - last_modified_time: Timestamps of last policy modifications
  EOT
  value = {
    policy_count       = length(data.powerplatform_data_loss_prevention_policies.current.policies)
    policy_ids         = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.id]
    policy_names       = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.display_name]
    environment_types  = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.environment_type]
    created_by         = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.created_by]
    last_modified_time = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.last_modified_time]
  }
  sensitive = false
}

output "dlp_policies_sensitive" {
  description = <<-EOT
    Sensitive DLP policy configuration details:
    - connector_configurations: Summary of connector classifications per policy
    - business_connectors_count: Number of business connectors per policy
    - non_business_connectors_count: Number of non-business connectors per policy
    - blocked_connectors_count: Number of blocked connectors per policy
    
    Note: This output is marked as sensitive to protect connector configuration details.
  EOT
  value = {
    connector_configurations = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : {
      policy_id                     = policy.id
      policy_name                   = policy.display_name
      business_connectors_count     = length(policy.business_connectors)
      non_business_connectors_count = length(policy.non_business_connectors)
      blocked_connectors_count      = length(policy.blocked_connectors)
      default_classification        = policy.default_connectors_classification
    }]
  }
  sensitive = true
}
