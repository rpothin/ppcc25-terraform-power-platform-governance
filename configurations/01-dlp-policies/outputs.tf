# Output for Data Loss Prevention Policies Export
# This output exposes the current DLP policies for analysis and migration planning

output "dlp_policies" {
  description = "Current Data Loss Prevention Policies in the tenant"
  value       = data.powerplatform_data_loss_prevention_policies.current
  sensitive   = false
}
