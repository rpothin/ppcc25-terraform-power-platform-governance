# Output Values for Smart DLP tfvars Generator
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

output "generated_tfvars_content" {
  description = <<DESCRIPTION
The generated tfvars content for the selected or templated DLP policy.

This output provides the tfvars file content as a string, ready for use with the res-dlp-policy configuration.
DESCRIPTION
  value       = "" # Placeholder for generated content
}

output "generation_summary" {
  description = <<DESCRIPTION
Summary of the tfvars generation process, including input parameters and validation results.
DESCRIPTION
  value = {
    source_policy_name = var.source_policy_name
    template_type      = var.template_type
    output_file        = var.output_file
    # Add more fields as implementation progresses
  }
}
