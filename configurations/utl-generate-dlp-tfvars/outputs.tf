# Output Values for Generate DLP Policy tfvars Utility
#
# Implements AVM anti-corruption layer with discrete outputs for tfvars generation.
# These outputs provide validation information and generated content without exposing
# sensitive or complex internal structures.

# ============================================================================
# OUTPUT SCHEMA VERSION
# ============================================================================

locals {
  output_schema_version = "1.0.0"
}

output "output_schema_version" {
  description = "The version of the output schema for this module."
  value       = local.output_schema_version
}

# ============================================================================
# PRIMARY OUTPUTS - Generated tfvars content and validation
# ============================================================================

output "generated_tfvars_content" {
  description = <<DESCRIPTION
The generated tfvars content for the selected DLP policy.

This output provides a ready-to-use tfvars configuration that can be:
- Saved to a .tfvars file for use with res-dlp-policy module
- Used directly in Terraform configurations for policy replication
- Modified as needed for environment-specific adjustments

The content includes:
- Complete DLP policy configuration structure
- All connector classifications (business, non_business, blocked)
- Custom connector patterns if present
- Properly formatted Terraform syntax ready for immediate use

Generated from live Power Platform data to ensure accuracy and freshness.
No dependency on exported files - direct tenant access via OIDC authentication.
DESCRIPTION
  value       = local.tfvars_content
  sensitive   = false
}

output "tfvars_file_path" {
  description = <<DESCRIPTION
The absolute path to the generated tfvars file on the local filesystem.

This output provides the location where the physical tfvars file has been written,
enabling downstream processes to reference or process the file as needed.

File Location: Relative to Terraform working directory
File Format: Standard .tfvars format compatible with res-dlp-policy module
File Encoding: UTF-8 with proper Terraform syntax formatting
File Permissions: 0644 (readable by owner and group, writable by owner only)

Usage:
- Reference this path for automated deployment workflows
- Use with terraform apply -var-file="$(terraform output -raw tfvars_file_path)"
- Integrate with CI/CD pipelines for policy deployment automation
DESCRIPTION
  value       = length(resource.local_file.generated_tfvars) > 0 ? resource.local_file.generated_tfvars[0].filename : null
}

# ============================================================================
# VALIDATION AND SUMMARY OUTPUTS
# ============================================================================

output "generation_summary" {
  description = <<DESCRIPTION
Summary of the tfvars generation process and validation results.

Provides operational context and validation information including:
- Source policy identification and matching status
- Output file configuration and write status
- Policy data validation and completeness checks
- Connector classification summaries for quick review
- Generation timestamp for audit and tracking purposes

Use this output to verify successful generation and troubleshoot any issues.
Data sourced directly from live Power Platform tenant via authenticated API access.
DESCRIPTION
  value = {
    # Input validation
    source_policy_name = var.source_policy_name
    output_file_path   = var.output_file

    # Policy matching results
    policy_found            = local.policy_exists
    policy_id               = local.policy_exists ? local.selected_policy.id : null
    policy_environment_type = local.policy_exists ? local.selected_policy.environment_type : null

    # Content validation
    tfvars_generated = local.tfvars_valid
    file_written     = length(resource.local_file.generated_tfvars) > 0

    # Connector summaries
    connector_counts = {
      business_connectors     = length(local.business_connectors)
      non_business_connectors = length(local.non_business_connectors)
      blocked_connectors      = length(local.blocked_connectors)
      custom_patterns         = local.policy_exists ? length(local.custom_connectors_patterns) : 0
      total_connectors        = length(local.business_connectors) + length(local.non_business_connectors) + length(local.blocked_connectors)
    }

    # Generation metadata
    generation_timestamp = timestamp()
    terraform_workspace  = terraform.workspace
  }
}