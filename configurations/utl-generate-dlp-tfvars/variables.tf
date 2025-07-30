# Input Variables for Smart DLP tfvars Generator (utl-generate-dlp-tfvars)
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Policy Selection: Controls which existing policy to onboard
# - Output Configuration: File generation settings and paths
#
# Architecture: Direct data source approach for live Power Platform policy access

# ============================================================================
# POLICY SELECTION VARIABLES
# ============================================================================

variable "source_policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the DLP policy to onboard and generate tfvars for.

This variable specifies which existing policy to retrieve from the live Power Platform tenant
and convert into a tfvars configuration for Infrastructure as Code management.

Usage Context:
- Used to select an existing policy from live Power Platform data (onboarding mode)
- Must match a policy display_name present in the Power Platform tenant
- Enables seamless transition from ClickOps to Infrastructure as Code

Data Source: Live Power Platform tenant via powerplatform_data_loss_prevention_policies data source
Authentication: OIDC authentication to Power Platform APIs

Example Values:
- "Corporate Data Protection Policy"
- "Development Environment DLP"
- "Copilot Studio Autonomous Agents"

Validation Rules:
- Must be non-empty string (minimum 1 character)
- Maximum 100 characters for Power Platform compatibility
- Alphanumeric characters, spaces, hyphens, and underscores only
- Case-sensitive matching against actual policy names

Troubleshooting:
- If policy not found, check exact spelling and case sensitivity
- Verify authentication and access to Power Platform tenant
- Use diagnostic_info output for policy matching details
DESCRIPTION

  validation {
    condition     = length(var.source_policy_name) > 0 && length(var.source_policy_name) <= 100
    error_message = "source_policy_name must be between 1 and 100 characters for Power Platform compatibility."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9 _.-]+$", var.source_policy_name))
    error_message = "source_policy_name must contain only alphanumeric characters, spaces, hyphens, underscores, and periods."
  }
}

# ============================================================================
# OUTPUT CONFIGURATION VARIABLES
# ============================================================================

variable "output_file" {
  type        = string
  description = <<DESCRIPTION
Path and filename for the generated tfvars output file.

This variable controls where the generated tfvars configuration will be written
on the local filesystem for subsequent use with the res-dlp-policy module.

File Format: Standard Terraform .tfvars format with HCL syntax
File Content: Complete DLP policy configuration ready for immediate use
File Encoding: UTF-8 with proper Terraform formatting and indentation
File Permissions: 0644 (readable by owner and group, writable by owner only)

Path Configuration:
- Relative paths: Interpreted relative to Terraform working directory
- Absolute paths: Used as-is for full path control
- Directory creation: Parent directories must exist (not auto-created)

Integration with res-dlp-policy:
- Generated file can be used directly with: terraform apply -var-file="path/to/generated.tfvars"
- All variable names match res-dlp-policy module input requirements
- No manual editing required for basic policy deployment

Example Values:
- "generated-dlp-policy.tfvars" (default, current directory)
- "tfvars/production-dlp.tfvars" (subdirectory organization)
- "/workspace/configs/imported-policy.tfvars" (absolute path)
- "environments/dev/dlp-baseline.tfvars" (environment-specific)

Security Considerations:
- Generated files may contain policy configuration details
- Ensure appropriate file system permissions and access controls
- Consider excluding generated tfvars from version control if sensitive
DESCRIPTION

  default = "generated-dlp-policy.tfvars"

  validation {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars extension for Terraform compatibility."
  }

  validation {
    condition     = length(var.output_file) >= 9 # Minimum: "x.tfvars"
    error_message = "output_file must be at least 9 characters long (minimum valid filename)."
  }

  validation {
    condition     = length(var.output_file) <= 255
    error_message = "output_file path must be 255 characters or less for filesystem compatibility."
  }

  validation {
    condition     = !can(regex("[\\\\/]{2,}|[<>:\"|?*]", var.output_file))
    error_message = "output_file must not contain invalid filesystem characters or consecutive path separators."
  }
}