# Input Variables for Export Power Platform Connectors Utility
#
# This file defines input parameters for the configuration following AVM standards.
#
# Variable Categories:
# - Core Configuration: Data export settings
# - Security Settings: Authentication and access controls

variable "timeout" {
  type        = string
  description = "Timeout for reading connectors data (e.g., '60s'). Optional."
  default     = "60s"
  validation {
    condition     = can(regex("^[0-9]+s$", var.timeout))
    error_message = "Timeout must be specified in seconds (e.g., '60s')."
  }
}
