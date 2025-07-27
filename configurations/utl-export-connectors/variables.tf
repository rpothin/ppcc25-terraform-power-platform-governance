# Input Variables for Export Power Platform Connectors Utility
#
# Variables are organized by functional purpose:
# - Filtering variables: Control which connectors are included
# - Pagination variables: Control output size and incremental processing

# ============================================================================
# FILTERING VARIABLES - Control which connectors are included in export
# ============================================================================

variable "filter_publishers" {
  type = list(string)
  description = <<DESCRIPTION
Optional list of connector publishers to include in the export. If set, only connectors whose publisher matches one of the provided values will be included.

Example:
  filter_publishers = ["Microsoft", "Troy Taylor"]

Validation:
- Each publisher must be a non-empty string.
- If empty or unset, no filtering by publisher is applied.
DESCRIPTION
  default = []
  validation {
    condition     = alltrue([for p in var.filter_publishers : length(trim(p)) > 0])
    error_message = "All publisher filter values must be non-empty strings."
  }
}

variable "filter_tiers" {
  type = list(string)
  description = <<DESCRIPTION
Optional list of connector tiers to include in the export. Valid values are "Standard" and "Premium". If set, only connectors whose tier matches one of the provided values will be included.

Example:
  filter_tiers = ["Standard", "Premium"]

Validation:
- Each tier must be either "Standard" or "Premium" (case-sensitive).
- If empty or unset, no filtering by tier is applied.
DESCRIPTION
  default = []
  validation {
    condition     = alltrue([for t in var.filter_tiers : contains(["Standard", "Premium"], t)])
    error_message = "Each tier filter value must be either 'Standard' or 'Premium'."
  }
}

variable "filter_types" {
  type = list(string)
  description = <<DESCRIPTION
Optional list of connector types to include in the export. If set, only connectors whose type matches one of the provided values will be included.

Example:
  filter_types = ["Custom", "BuiltIn"]

Validation:
- Each type must be a non-empty string.
- If empty or unset, no filtering by type is applied.
DESCRIPTION
  default = []
  validation {
    condition     = alltrue([for t in var.filter_types : length(trim(t)) > 0])
    error_message = "All type filter values must be non-empty strings."
  }
}

# ============================================================================
# PAGINATION VARIABLES - Control output size and incremental processing
# ============================================================================

variable "page_size" {
  type        = number
  description = <<DESCRIPTION
Optional page size for paginating connector results. If set to 0 or unset, all filtered connectors are returned. For very large tenants, set to a reasonable value (e.g., 100) to limit output size.

Example:
  page_size = 100

Validation:
- Must be >= 0
- If 0, pagination is disabled (all results returned)
DESCRIPTION
  default = 0
  validation {
    condition     = var.page_size >= 0
    error_message = "page_size must be 0 (disabled) or a positive integer."
  }
}

variable "page_number" {
  type        = number
  description = <<DESCRIPTION
Optional page number for paginating connector results. Ignored if page_size is 0. First page is 1.

Example:
  page_number = 1

Validation:
- Must be >= 1 if page_size > 0
DESCRIPTION
  default = 1
  validation {
    condition     = var.page_size == 0 || var.page_number >= 1
    error_message = "page_number must be >= 1 if page_size is set."
  }
}