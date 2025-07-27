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