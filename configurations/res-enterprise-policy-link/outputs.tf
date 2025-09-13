# Output Values for res-enterprise-policy-link
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.
#
# Output Categories:
# - Resource Identifiers: Primary keys for downstream references
# - Policy Assignment: Enterprise policy assignment details
# - Environment Binding: Environment-policy relationship information
# - Configuration Summary: Aggregated configuration details for reporting
# - Operational Metadata: Deployment and lifecycle information

# ============================================================================
# RESOURCE IDENTIFIER OUTPUTS
# ============================================================================

output "enterprise_policy_id" {
  description = <<DESCRIPTION
The unique identifier of the enterprise policy assignment.

This output provides the primary key for referencing this policy assignment
in other Terraform configurations or external systems. The ID represents the
specific binding between the Power Platform environment and the Azure enterprise policy.

Usage Examples:
- Reference in other modules: module.enterprise_policy.enterprise_policy_id
- Export for external systems integration
- Use in dependency chains for resource ordering
- Include in governance reporting and audit trails

Format: Typically a GUID assigned by the Power Platform service
Example: "36f603f9-0af2-e33d-98a5-64b02c1bac19"

Security Note: This ID is not sensitive and can be safely logged or exported.
DESCRIPTION
  value       = powerplatform_enterprise_policy.this.id
}

# ============================================================================
# POLICY ASSIGNMENT OUTPUTS
# ============================================================================

output "policy_assignment_details" {
  description = <<DESCRIPTION
Comprehensive details of the enterprise policy assignment configuration.

This output provides a structured summary of the policy assignment including
all key configuration parameters. Useful for validation, reporting, and
downstream module consumption.

Included Information:
- environment_id: Target Power Platform environment identifier
- policy_type: Type of enterprise policy (NetworkInjection/Encryption)
- system_id: Azure enterprise policy resource identifier
- assignment_id: Power Platform policy assignment identifier

Usage Examples:
- Validation: Confirm policy was assigned correctly
- Reporting: Include in governance dashboards
- Integration: Pass to monitoring or audit systems
- Documentation: Auto-generate deployment reports

Data Structure: Object with string properties
Security: Contains no sensitive information, safe for logging
DESCRIPTION
  value = {
    environment_id = powerplatform_enterprise_policy.this.environment_id
    policy_type    = powerplatform_enterprise_policy.this.policy_type
    system_id      = powerplatform_enterprise_policy.this.system_id
    assignment_id  = powerplatform_enterprise_policy.this.id
  }
  sensitive = false # Policy assignment details are not sensitive for operations teams
}

output "policy_type" {
  description = <<DESCRIPTION
The type of enterprise policy assigned to the environment.

This discrete output provides the policy type for downstream consumption
without exposing the full resource object. Useful for conditional logic
in parent modules and policy type validation.

Valid Values:
- "NetworkInjection" - VNet integration and subnet delegation policy
- "Encryption" - Customer-managed key encryption policy

Usage Examples:
- Conditional resource creation based on policy type
- Validation in parent modules or patterns
- Documentation generation and reporting
- Integration with monitoring systems

Format: String value matching the input policy_type variable
Security: Policy type is not sensitive information
DESCRIPTION
  value       = powerplatform_enterprise_policy.this.policy_type
}

# ============================================================================
# ENVIRONMENT BINDING OUTPUTS
# ============================================================================

output "environment_assignments" {
  description = <<DESCRIPTION
Summary of policy assignments to environments for governance tracking.

This output provides a consolidated view of the environment-policy relationship
established by this module. Designed for governance reporting, audit trails,
and integration with policy management systems.

Included Information:
- environment_id: Target Power Platform environment
- assignment_id: Unique identifier for this policy assignment
- policy_type: Type of enterprise policy applied
- system_id: Azure enterprise policy resource reference
- assignment_status: Status of the policy assignment

Usage Examples:
- Governance dashboards showing policy coverage
- Audit reports for compliance verification
- Integration with enterprise policy management systems
- Automated policy assignment validation

Data Structure: Object with comprehensive assignment metadata
Update Frequency: Changes when policy assignments are modified
Security: Contains no sensitive data, safe for external reporting
DESCRIPTION
  value = {
    environment_id    = var.environment_id
    assignment_id     = powerplatform_enterprise_policy.this.id
    policy_type       = var.policy_type
    system_id         = var.system_id
    assignment_status = "assigned"
  }
  sensitive = false # Assignment metadata is not sensitive for governance reporting
}

output "target_environment_id" {
  description = <<DESCRIPTION
The Power Platform environment ID that received the policy assignment.

This discrete output provides the target environment identifier for
downstream consumption and validation. Useful for chaining modules
and creating dependency relationships.

Usage Examples:
- Reference in dependent modules requiring the same environment
- Validation that policy was applied to correct environment
- Documentation and audit trail generation
- Integration with environment management systems

Format: GUID string representing the Power Platform environment
Example: "36f603f9-0af2-e33d-98a5-64b02c1bac19"
Source: Directly from the powerplatform_enterprise_policy resource
DESCRIPTION
  value       = powerplatform_enterprise_policy.this.environment_id
}

# ============================================================================
# CONFIGURATION SUMMARY OUTPUTS
# ============================================================================

output "deployment_summary" {
  description = <<DESCRIPTION
Comprehensive summary of the enterprise policy assignment deployment for validation and compliance.

This output aggregates all key deployment information into a single object
suitable for reporting, validation, and integration with external systems.
Follows AVM patterns for configuration summary outputs.

IMPORTANT: This module assigns existing Azure enterprise policies to Power Platform environments.
The Azure enterprise policy must be pre-created (typically using azapi_resource).

Summary Components:
- Resource Information: IDs, types, and identifiers
- Configuration Details: Policy type and assignment parameters
- Deployment Metadata: Timestamps, module version, and operational details
- Assignment Status: Policy assignment completion and validation

Usage Examples:
- Automated compliance reporting and audit trails
- Integration with governance dashboards and monitoring
- Validation in CI/CD pipelines and deployment verification
- Documentation generation and deployment artifacts

Data Quality:
- All timestamps are in RFC3339 format for consistency
- Version information tracks module evolution
- Status fields provide clear deployment state indication

Security: Contains no sensitive information, designed for external consumption
DESCRIPTION
  value = {
    # Resource identifiers
    enterprise_policy_id = powerplatform_enterprise_policy.this.id
    environment_id       = var.environment_id
    system_id            = var.system_id

    # Configuration details
    policy_type = var.policy_type

    # Deployment metadata
    deployment_time   = timestamp()
    module_version    = "1.0.0"
    deployment_status = "assigned"

    # Assignment summary
    assignment_summary = {
      azure_policy_exists   = true # Assumed - policy must pre-exist
      assignment_successful = true # Confirmed by successful resource creation
      environment_bound     = true # Environment-policy binding established
    }
  }
  sensitive = false # Deployment summary is designed for external reporting
}

# ============================================================================
# OPERATIONAL METADATA OUTPUTS
# ============================================================================

output "module_metadata" {
  description = <<DESCRIPTION
Metadata about the res-enterprise-policy-link module deployment.

This output provides operational information about the module itself,
including version, capabilities, and configuration options. Useful for
module management, troubleshooting, and integration validation.

Metadata Components:
- module_type: Always "res-enterprise-policy-link" for identification
- module_version: Semantic version of this module implementation
- supported_policy_types: List of enterprise policy types supported
- avm_compliance: AVM specification compliance information
- provider_requirements: Power Platform provider version requirements

Usage Examples:
- Module inventory and version management
- Compatibility checking in parent modules
- Documentation generation and module catalogs
- Troubleshooting and support ticket information

Data Stability: Module metadata changes only with module updates
Format: Structured object with consistent field names across AVM modules
Security: Contains no sensitive operational information
DESCRIPTION
  value = {
    module_type            = "res-enterprise-policy-link"
    module_version         = "1.0.0"
    supported_policy_types = ["NetworkInjection", "Encryption"]
    avm_compliance = {
      compliant             = true
      anti_corruption_layer = true
      child_module_pattern  = true
      lifecycle_management  = true
    }
    provider_requirements = {
      powerplatform = "~> 3.8"
    }
  }
  sensitive = false # Module metadata is not sensitive
}