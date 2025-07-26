# Output Values for res-dlp-policy
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.
#
# Output Categories:
# - Resource Identifiers: Primary keys for downstream references
# - Computed Values: Derived attributes useful for integration
# - Summary Information: Aggregated data for reporting
# - Security Attributes: Access-related information (marked sensitive)

output "dlp_policy_id" {
  description = <<DESCRIPTION
The unique identifier of the DLP policy.
This output provides the primary key for referencing this resource in other Terraform configurations or external systems. The ID format follows Power Platform standards.
DESCRIPTION
  value       = powerplatform_data_loss_prevention_policy.this.id
}

output "dlp_policy_display_name" {
  description = "The display name of the DLP policy."
  value       = powerplatform_data_loss_prevention_policy.this.display_name
}

output "dlp_policy_environment_type" {
  description = "The environment type for the DLP policy."
  value       = powerplatform_data_loss_prevention_policy.this.environment_type
}
