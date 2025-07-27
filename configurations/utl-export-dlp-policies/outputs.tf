# Output Values for Export Power Platform DLP Policies Utility
#
# Implements AVM anti-corruption layer with unified output structure that eliminates
# redundancy while providing configurable detail levels. Uses shared transformation
# logic and optimized processing for better performance and maintainability.

# ============================================================================
# Output Schema Version
# ============================================================================

locals {
  output_schema_version = "1.0.0"
}

output "output_schema_version" {
  description = "The version of the output schema for this module."
  value       = local.output_schema_version
}

# ============================================================================
# SHARED TRANSFORMATIONS - DRY principle for connector data structures
# ============================================================================

locals {
  # Reusable connector transformation function (summary level)
  transform_connector_summary = {
    for policy_idx, policy in local.filtered_policies : policy_idx => {
      business_connectors = [for conn in policy.business_connectors : {
        id                           = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules_count           = length(conn.action_rules)
        endpoint_rules_count         = length(conn.endpoint_rules)
      }]
      non_business_connectors = [for conn in policy.non_business_connectors : {
        id                           = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules_count           = length(conn.action_rules)
        endpoint_rules_count         = length(conn.endpoint_rules)
      }]
      blocked_connectors = [for conn in policy.blocked_connectors : {
        id                           = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules_count           = length(conn.action_rules)
        endpoint_rules_count         = length(conn.endpoint_rules)
      }]
    }
  }

  # Reusable connector transformation function (detailed level)
  transform_connector_detailed = {
    for policy_idx, policy in local.filtered_policies : policy_idx => {
      business_connectors = [for conn in policy.business_connectors : {
        connector_id                 = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules = [for rule in conn.action_rules : {
          action_id = rule.action_id
          behavior  = rule.behavior
        }]
        endpoint_rules = [for rule in conn.endpoint_rules : {
          endpoint = rule.endpoint
          behavior = rule.behavior
          order    = rule.order
        }]
      }]
      non_business_connectors = [for conn in policy.non_business_connectors : {
        connector_id                 = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules = [for rule in conn.action_rules : {
          action_id = rule.action_id
          behavior  = rule.behavior
        }]
        endpoint_rules = [for rule in conn.endpoint_rules : {
          endpoint = rule.endpoint
          behavior = rule.behavior
          order    = rule.order
        }]
      }]
      blocked_connectors = [for conn in policy.blocked_connectors : {
        connector_id                 = conn.id
        default_action_rule_behavior = conn.default_action_rule_behavior
        action_rules = [for rule in conn.action_rules : {
          action_id = rule.action_id
          behavior  = rule.behavior
        }]
        endpoint_rules = [for rule in conn.endpoint_rules : {
          endpoint = rule.endpoint
          behavior = rule.behavior
          order    = rule.order
        }]
      }]
    }
  }

  # Pre-calculated summary statistics for performance
  policy_summaries = {
    for policy_idx, policy in local.filtered_policies : policy_idx => {
      business_count        = length(policy.business_connectors)
      non_business_count    = length(policy.non_business_connectors)
      blocked_count         = length(policy.blocked_connectors)
      custom_patterns_count = length(policy.custom_connectors_patterns)
      total_connectors      = length(policy.business_connectors) + length(policy.non_business_connectors) + length(policy.blocked_connectors)
    }
  }
}

# ============================================================================
# PRIMARY OUTPUT - Unified DLP policies with configurable detail
# ============================================================================

output "dlp_policies" {
  description = <<DESCRIPTION
Unified DLP policies export with configurable detail level for optimal performance.
Always represents the final processed dataset after applying any policy filters.

Structure:
- policy_count: Total number of DLP policies exported (after filtering)
- export_metadata: Information about the export configuration and processing
- policies: Array of policy objects with complete configuration
  - Core metadata: id, display_name, environment_type, environments, etc.
  - Connector classifications: business, non_business, blocked (with configurable detail)
  - Custom connector patterns: For accurate migration of custom connector policies
  - Summary statistics: Quick analysis and validation metrics

Detail Levels:
- When include_detailed_rules = false: Connector summaries with rule counts only
- When include_detailed_rules = true: Complete action and endpoint rule configurations

Performance Notes:
- Summary level optimized for large tenants and quick analysis
- Detailed level provides complete migration data but may impact performance
- Use policy_filter variable to limit scope for large tenants
DESCRIPTION
  value = {
    # Export metadata for traceability and validation
    export_metadata = {
      total_policies_in_tenant = length(data.powerplatform_data_loss_prevention_policies.current.policies)
      filtered_policies_count  = length(local.filtered_policies)
      filter_applied          = length(var.policy_filter) > 0
      detail_level           = var.include_detailed_rules ? "detailed" : "summary"
      export_timestamp       = timestamp()
    }

    # Policy count for quick reference
    policy_count = length(local.filtered_policies)

    # Main policies array with dynamic detail level
    policies = [for policy_idx, policy in local.filtered_policies : {
      # Core policy metadata (always included)
      id                                = policy.id
      display_name                      = policy.display_name
      environment_type                  = policy.environment_type
      environments                      = toset(policy.environments)
      default_connectors_classification = policy.default_connectors_classification

      # Audit information (always included)
      created_by         = policy.created_by
      created_time       = policy.created_time
      last_modified_by   = policy.last_modified_by
      last_modified_time = policy.last_modified_time

      # Custom connector patterns (always included - critical for migration)
      custom_connectors_patterns = [for pattern in policy.custom_connectors_patterns : {
        data_group       = pattern.data_group
        host_url_pattern = pattern.host_url_pattern
        order            = pattern.order
      }]

      # Summary statistics (always included)
      connector_summary = local.policy_summaries[policy_idx]

      # Connector data with configurable detail level
      business_connectors = (
        var.include_detailed_rules
        ? local.transform_connector_detailed[policy_idx].business_connectors
        : local.transform_connector_summary[policy_idx].business_connectors
      )

      non_business_connectors = (
        var.include_detailed_rules
        ? local.transform_connector_detailed[policy_idx].non_business_connectors
        : local.transform_connector_summary[policy_idx].non_business_connectors
      )

      blocked_connectors = (
        var.include_detailed_rules
        ? local.transform_connector_detailed[policy_idx].blocked_connectors
        : local.transform_connector_summary[policy_idx].blocked_connectors
      )
    }]
  }
  
  # Mark as sensitive when detailed rules are included
  sensitive = var.include_detailed_rules
}

# ============================================================================
# ANALYSIS OUTPUTS - Governance insights and relationship mapping
# ============================================================================

output "governance_analysis" {
  description = <<DESCRIPTION
Governance analysis and insights derived from the DLP policies export.
Provides high-level statistics and patterns useful for governance planning,
compliance reporting, and policy optimization recommendations.
DESCRIPTION
  value = {
    # Tenant-level statistics
    tenant_summary = {
      total_policies = length(local.filtered_policies)
      policies_by_type = {
        for env_type in distinct([for p in local.filtered_policies : p.environment_type]) :
        env_type => length([for p in local.filtered_policies : p if p.environment_type == env_type])
      }
      policies_with_custom_patterns = length([
        for p in local.filtered_policies : p 
        if length(p.custom_connectors_patterns) > 0
      ])
    }

    # Connector classification distribution
    connector_distribution = {
      total_business_connectors = sum([
        for p in local.filtered_policies : length(p.business_connectors)
      ])
      total_non_business_connectors = sum([
        for p in local.filtered_policies : length(p.non_business_connectors)  
      ])
      total_blocked_connectors = sum([
        for p in local.filtered_policies : length(p.blocked_connectors)
      ])
    }

    # Policy complexity indicators
    complexity_indicators = {
      policies_with_action_rules = length([
        for p in local.filtered_policies : p
        if anytrue([
          anytrue([for c in p.business_connectors : length(c.action_rules) > 0]),
          anytrue([for c in p.non_business_connectors : length(c.action_rules) > 0]),
          anytrue([for c in p.blocked_connectors : length(c.action_rules) > 0])
        ])
      ])
      policies_with_endpoint_rules = length([
        for p in local.filtered_policies : p
        if anytrue([
          anytrue([for c in p.business_connectors : length(c.endpoint_rules) > 0]),
          anytrue([for c in p.non_business_connectors : length(c.endpoint_rules) > 0]),
          anytrue([for c in p.blocked_connectors : length(c.endpoint_rules) > 0])
        ])
      ])
      average_connectors_per_policy = length(local.filtered_policies) > 0 ? sum([
        for p in local.filtered_policies : 
        length(p.business_connectors) + length(p.non_business_connectors) + length(p.blocked_connectors)
      ]) / length(local.filtered_policies) : 0
    }
  }
}

# ============================================================================
# EXPORT OUTPUTS - Integration with external governance tools
# ============================================================================

output "export_formats" {
  description = <<DESCRIPTION
DLP policies in various export formats for integration with external tools.
Provides structured data optimized for different consumption scenarios.
DESCRIPTION
  value = {
    # JSON format for API consumption and automation
    policies_json = jsonencode({
      export_timestamp = timestamp()
      policy_count    = length(local.filtered_policies)
      detail_level    = var.include_detailed_rules ? "detailed" : "summary"
      policies        = [for policy_idx, policy in local.filtered_policies : {
        id           = policy.id
        display_name = policy.display_name
        environment_type = policy.environment_type
        environments = policy.environments
        summary      = local.policy_summaries[policy_idx]
      }]
    })

    # CSV format for spreadsheet analysis (summary data only)
    policies_csv = join("\n", concat([
      "policy_id,display_name,environment_type,business_count,non_business_count,blocked_count,total_connectors"
    ], [
      for policy_idx, policy in local.filtered_policies : join(",", [
        policy.id,
        "\"${policy.display_name}\"",
        policy.environment_type,
        tostring(local.policy_summaries[policy_idx].business_count),
        tostring(local.policy_summaries[policy_idx].non_business_count),
        tostring(local.policy_summaries[policy_idx].blocked_count),
        tostring(local.policy_summaries[policy_idx].total_connectors)
      ])
    ]))
  }
}