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
  value     = local.tfvars_content
  sensitive = false
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
  value = length(resource.local_file.generated_tfvars) > 0 ? resource.local_file.generated_tfvars[0].filename : null
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

output "policy_analysis" {
  description = <<DESCRIPTION
Analysis of the source DLP policy for governance insights and migration planning.

Provides detailed analysis of the policy structure including:
- Policy complexity indicators (action rules, endpoint rules, custom patterns)
- Environment targeting and scope information
- Connector distribution and classification patterns
- Migration considerations and recommendations

Use this output for policy assessment and migration planning activities.
Analysis based on live Power Platform policy data for maximum accuracy.
DESCRIPTION
  value = local.policy_exists ? {
    # Policy metadata
    policy_metadata = {
      display_name         = local.selected_policy.display_name
      environment_type     = local.selected_policy.environment_type
      environments_count   = length(local.environments)
      created_time         = try(local.selected_policy.created_time, null)
      last_modified_time   = try(local.selected_policy.last_modified_time, null)
      created_by          = try(local.selected_policy.created_by, null)
      last_modified_by    = try(local.selected_policy.last_modified_by, null)
    }
    
    # Complexity analysis
    complexity_indicators = {
      has_custom_patterns = length(local.custom_connectors_patterns) > 0
      has_action_rules = anytrue([
        anytrue([for conn in local.business_connectors : length(try(conn.action_rules, [])) > 0]),
        anytrue([for conn in local.non_business_connectors : length(try(conn.action_rules, [])) > 0]),
        anytrue([for conn in local.blocked_connectors : length(try(conn.action_rules, [])) > 0])
      ])
      has_endpoint_rules = anytrue([
        anytrue([for conn in local.business_connectors : length(try(conn.endpoint_rules, [])) > 0]),
        anytrue([for conn in local.non_business_connectors : length(try(conn.endpoint_rules, [])) > 0]),
        anytrue([for conn in local.blocked_connectors : length(try(conn.endpoint_rules, [])) > 0])
      ])
      complexity_score = (
        (length(local.custom_connectors_patterns) > 0 ? 2 : 0) +
        (anytrue([
          anytrue([for conn in local.business_connectors : length(try(conn.action_rules, [])) > 0]),
          anytrue([for conn in local.non_business_connectors : length(try(conn.action_rules, [])) > 0]),
          anytrue([for conn in local.blocked_connectors : length(try(conn.action_rules, [])) > 0])
        ]) ? 1 : 0) +
        (anytrue([
          anytrue([for conn in local.business_connectors : length(try(conn.endpoint_rules, [])) > 0]),
          anytrue([for conn in local.non_business_connectors : length(try(conn.endpoint_rules, [])) > 0]),
          anytrue([for conn in local.blocked_connectors : length(try(conn.endpoint_rules, [])) > 0])
        ]) ? 1 : 0)
      )
    }
    
    # Migration recommendations
    migration_considerations = {
      requires_custom_pattern_review = length(local.custom_connectors_patterns) > 0
      requires_rule_validation = anytrue([
        anytrue([for conn in local.business_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0]),
        anytrue([for conn in local.non_business_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0]),
        anytrue([for conn in local.blocked_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0])
      ])
      environment_scope_review = length(local.environments) > 1
      recommended_testing_approach = (
        length(local.custom_connectors_patterns) > 0 || 
        anytrue([
          anytrue([for conn in local.business_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0]),
          anytrue([for conn in local.non_business_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0]),
          anytrue([for conn in local.blocked_connectors : length(try(conn.action_rules, [])) > 0 || length(try(conn.endpoint_rules, [])) > 0])
        ])
      ) ? "sandbox_environment" : "direct_deployment"
    }
  } : null
}

# ============================================================================
# DIAGNOSTIC OUTPUTS - Troubleshooting and validation
# ============================================================================

output "diagnostic_info" {
  description = <<DESCRIPTION
Diagnostic information for troubleshooting tfvars generation issues.

Provides detailed diagnostic data including:
- Data source query results and status
- Policy matching logic and results
- Validation errors and warnings
- Performance metrics and execution context

Use this output when generation fails or produces unexpected results.
All diagnostics based on live Power Platform API responses.
DESCRIPTION
  value = {
    # Data source diagnostics
    data_source_status = {
      total_policies_available = length(data.powerplatform_data_loss_prevention_policies.current.policies)
      query_successful         = can(data.powerplatform_data_loss_prevention_policies.current.policies)
      authentication_method    = "OIDC"
    }
    
    # Policy matching diagnostics
    policy_matching = {
      search_term_used    = var.source_policy_name
      matching_policies   = length(local.matching_policies)
      exact_match_found   = local.policy_exists
      available_policies  = [
        for policy in data.powerplatform_data_loss_prevention_policies.current.policies :
        policy.display_name
      ]
    }
    
    # File generation diagnostics
    file_generation = {
      output_path_configured = var.output_file
      content_length         = local.tfvars_valid ? length(local.tfvars_content) : 0
      generation_successful  = local.tfvars_valid
      file_resource_created  = length(resource.local_file.generated_tfvars) > 0
    }
    
    # Execution context
    execution_context = {
      terraform_version    = "1.5+"  # Minimum required version
      powerplatform_version = "~> 3.8"  # Power Platform provider
      local_provider_version = "~> 2.4"  # Local file provider
      workspace           = terraform.workspace
      execution_time      = timestamp()
    }
  }
}

# ============================================================================
# CONNECTOR ANALYSIS OUTPUTS - Detailed breakdown
# ============================================================================

output "connector_analysis" {
  description = <<DESCRIPTION
Detailed analysis of connector classifications and configurations from the source policy.

Provides granular insights into:
- Connector distribution across classifications
- Action and endpoint rule configurations
- Custom connector pattern analysis
- Policy governance compliance indicators

Use for detailed policy analysis and compliance reporting.
DESCRIPTION
  value = local.policy_exists ? {
    # Classification distribution
    classification_summary = {
      business_connectors = {
        count = length(local.business_connectors)
        ids   = [for conn in local.business_connectors : conn.id]
      }
      non_business_connectors = {
        count = length(local.non_business_connectors)
        ids   = [for conn in local.non_business_connectors : conn.id]
      }
      blocked_connectors = {
        count = length(local.blocked_connectors)
        ids   = [for conn in local.blocked_connectors : conn.id]
      }
    }
    
    # Rule complexity analysis
    rule_analysis = {
      total_action_rules = (
        sum([for conn in local.business_connectors : length(try(conn.action_rules, []))]) +
        sum([for conn in local.non_business_connectors : length(try(conn.action_rules, []))]) +
        sum([for conn in local.blocked_connectors : length(try(conn.action_rules, []))])
      )
      total_endpoint_rules = (
        sum([for conn in local.business_connectors : length(try(conn.endpoint_rules, []))]) +
        sum([for conn in local.non_business_connectors : length(try(conn.endpoint_rules, []))]) +
        sum([for conn in local.blocked_connectors : length(try(conn.endpoint_rules, []))])
      )
      has_complex_rules = (
        sum([for conn in local.business_connectors : length(try(conn.action_rules, []))]) +
        sum([for conn in local.non_business_connectors : length(try(conn.action_rules, []))]) +
        sum([for conn in local.blocked_connectors : length(try(conn.action_rules, []))]) +
        sum([for conn in local.business_connectors : length(try(conn.endpoint_rules, []))]) +
        sum([for conn in local.non_business_connectors : length(try(conn.endpoint_rules, []))]) +
        sum([for conn in local.blocked_connectors : length(try(conn.endpoint_rules, []))])
      ) > 0
    }
    
    # Custom connector patterns
    custom_pattern_analysis = {
      pattern_count     = length(local.custom_connectors_patterns)
      patterns_defined  = local.custom_connectors_patterns
      has_wildcards     = anytrue([for pattern in local.custom_connectors_patterns : can(regex("\\*", pattern.host_url_pattern))])
      blocked_by_default = anytrue([for pattern in local.custom_connectors_patterns : pattern.data_group == "Blocked"])
    }
    
    # Environment scope
    environment_analysis = {
      environment_count       = length(local.environments)
      environment_ids        = local.environments
      environment_type       = local.selected_policy.environment_type
      default_classification = local.selected_policy.default_connectors_classification
    }
  } : null
}