# Outputs: Anti-Corruption Layer for tfvars Generation
#
# These outputs provide only discrete, non-sensitive attributes for downstream use (AVM standard).

output "generated_tfvars_content" {
  description = <<DESCRIPTION
The generated tfvars content for the selected or templated DLP policy.

This output provides a ready-to-use tfvars block, suitable for direct use with the res-dlp-policy configuration. It is generated based on either onboarding an existing policy (from export) or creating a new policy from a governance template.
DESCRIPTION
  value       = local.tfvars_content
}

output "generation_summary" {
  description = <<DESCRIPTION
Summary of the tfvars generation process, including input parameters, operational mode, and validation results.

This output provides operational context for the tfvars generation, including:
- The source policy name (if onboarding)
- The template type used (if template mode)
- The output file name
- Whether onboarding or template mode was used
- Validation status for generated tfvars
- Lists of business, non-business, and blocked connectors
DESCRIPTION
  value = {
    source_policy_name      = var.source_policy_name
    template_type           = var.template_type
    output_file             = var.output_file
    onboarding_mode         = local.onboarding_mode
    tfvars_valid            = local.tfvars_valid
    business_connectors     = local.business_connectors
    non_business_connectors = local.non_business_connectors
    blocked_connectors      = local.blocked_connectors
  }
}
