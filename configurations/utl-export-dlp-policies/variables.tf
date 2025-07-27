# Input Variables for utl-export-dlp-policies

# Optional: Filter exported DLP policies by display name for performance optimization in large tenants.
variable "policy_filter" {
  type        = list(string)
  description = <<-EOT
    (Optional) List of DLP policy display names to export. If set, only policies whose display names match any value in this list will be exported.
    Filtering is case-sensitive and matches exact display names. Improves performance for large tenants.
    Example:
      policy_filter = ["Corporate DLP", "Finance DLP"]
  EOT
  default     = []
}

# Optional: Include detailed action and endpoint rules in the output.
variable "include_detailed_rules" {
  type        = bool
  description = <<DESCRIPTION
Whether to include detailed action and endpoint rules in the output.
When false (default), outputs connector summaries with rule counts only.
When true, outputs complete rule configurations for migration scenarios.

Performance impact:
- false: Optimized for large tenants and quick analysis
- true: Complete data but may impact performance with many policies/rules

Security considerations:
- true: Output marked as sensitive due to potential endpoint exposure
- false: Output not sensitive, safe for logging and external systems
DESCRIPTION
  default     = false

  validation {
    condition     = can(var.include_detailed_rules)
    error_message = "include_detailed_rules must be a boolean value (true or false)."
  }
}