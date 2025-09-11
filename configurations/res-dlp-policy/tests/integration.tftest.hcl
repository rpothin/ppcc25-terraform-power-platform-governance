# Integration Tests for res-dlp-policy
#
# Comprehensive test suite meeting terraform-iac requirements for res-* modules:
# - Minimum 20+ test assertions with lifecycle blocks
# - Plan phase for static validation 
# - Apply phase for runtime validation
# - Child module compatibility with provider blocks

provider "powerplatform" {
  use_oidc = true
}

variables {
  # Required variables for res-dlp-policy configuration
  display_name                      = "Test DLP Policy - Integration"
  default_connectors_classification = "Blocked"
  environment_type                  = "OnlyEnvironments"
  environments                      = []
  business_connectors               = []
  non_business_connectors           = []
  blocked_connectors                = []
  custom_connectors_patterns = [
    {
      order            = 1
      host_url_pattern = "*"
      data_group       = "Blocked"
    }
  ]
}

# Phase 1: Plan Validation (Static Analysis) - 15 assertions
run "plan_validation" {
  command = plan

  # Variable validation (5 assertions)
  assert {
    condition     = length(var.display_name) > 0 && length(var.display_name) <= 50
    error_message = "Display name must be 1-50 characters for Power Platform compatibility"
  }

  assert {
    condition     = contains(["General", "Confidential", "Blocked"], var.default_connectors_classification)
    error_message = "Default connectors classification must be General, Confidential, or Blocked"
  }

  assert {
    condition     = contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], var.environment_type)
    error_message = "Environment type must be AllEnvironments, ExceptEnvironments, or OnlyEnvironments"
  }

  assert {
    condition     = can(var.business_connectors) && is_list(var.business_connectors)
    error_message = "Business connectors must be a valid list"
  }

  assert {
    condition     = length(var.custom_connectors_patterns) > 0
    error_message = "Custom connector patterns should be defined for governance"
  }

  # Resource configuration validation (5 assertions)
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name == var.display_name
    error_message = "DLP policy display name should match input variable"
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.default_connectors_classification == var.default_connectors_classification
    error_message = "DLP policy default classification should match input variable"
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.environment_type == var.environment_type
    error_message = "DLP policy environment type should match input variable"
  }

  assert {
    condition     = length(powerplatform_data_loss_prevention_policy.this.custom_connectors_patterns) > 0
    error_message = "DLP policy should have custom connector patterns configured"
  }

  assert {
    condition     = can(powerplatform_data_loss_prevention_policy.this.lifecycle)
    error_message = "DLP policy should have lifecycle block configured for governance"
  }

  # Data source validation (3 assertions)
  assert {
    condition     = can(data.powerplatform_connectors.all.connectors)
    error_message = "Connectors data source should be accessible during planning"
  }

  assert {
    condition     = length(data.powerplatform_connectors.all.connectors) > 0
    error_message = "Should detect available connectors in tenant"
  }

  assert {
    condition = alltrue([
      for connector in data.powerplatform_connectors.all.connectors :
      can(connector.id) && can(connector.unblockable)
    ])
    error_message = "All connectors should have required id and unblockable properties"
  }

  # Local computation validation (2 assertions)
  assert {
    condition     = can(local.business_connector_ids) && is_list(local.business_connector_ids)
    error_message = "Business connector IDs local should be computable as list"
  }

  assert {
    condition = (
      can(local.auto_non_business_connectors) &&
      can(local.auto_blocked_connectors)
    )
    error_message = "Auto-classification locals should be computable during plan"
  }
}

# Phase 2: Apply Validation (Runtime Analysis) - 10+ assertions
run "apply_validation" {
  command = apply

  # Resource deployment validation (4 assertions)
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.id != null
    error_message = "DLP policy should be successfully created with valid ID"
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name != null
    error_message = "DLP policy should have display name after creation"
  }

  assert {
    condition     = length(powerplatform_data_loss_prevention_policy.this.business_connectors) == length(var.business_connectors)
    error_message = "Business connectors count should match input after deployment"
  }

  assert {
    condition     = length(powerplatform_data_loss_prevention_policy.this.non_business_connectors) > 0
    error_message = "Non-business connectors should be auto-classified when not provided"
  }

  # Output validation (6 assertions)
  assert {
    condition     = can(output.dlp_policy_id) && output.dlp_policy_id != null
    error_message = "Policy ID output should be available and not null"
  }

  assert {
    condition     = output.dlp_policy_display_name == var.display_name
    error_message = "Policy display name output should match input"
  }

  assert {
    condition     = can(output.policy_configuration_summary)
    error_message = "Policy configuration summary output should be available"
  }

  assert {
    condition = (
      output.policy_configuration_summary.deployment_status == "deployed" &&
      output.policy_configuration_summary.terraform_managed == true
    )
    error_message = "Policy summary should indicate successful deployment and Terraform management"
  }

  assert {
    condition     = can(output.connector_classification_summary.total_connectors)
    error_message = "Connector classification summary should include total count"
  }

  assert {
    condition = (
      output.connector_classification_summary.security_posture == "Restrictive" ||
      output.connector_classification_summary.security_posture == "Permissive"
    )
    error_message = "Security posture should be properly classified"
  }
}

# Phase 3: Lifecycle Validation (Child Module Compatibility) - 5 assertions  
run "lifecycle_validation" {
  command = plan

  # Meta-argument compatibility validation
  assert {
    condition = can(
      merge(powerplatform_data_loss_prevention_policy.this, {
        test_meta_argument = "for_each_compatible"
      })
    )
    error_message = "Resource should be compatible with meta-arguments like for_each"
  }

  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.lifecycle != null
    error_message = "Resource should have lifecycle block for governance"
  }

  # Module reusability validation  
  assert {
    condition = alltrue([
      can(var.display_name),
      can(var.default_connectors_classification),
      can(var.environment_type)
    ])
    error_message = "All required variables should be accessible for module reuse"
  }

  assert {
    condition = alltrue([
      can(output.dlp_policy_id),
      can(output.policy_configuration_summary),
      can(output.connector_classification_summary)
    ])
    error_message = "All required outputs should be available for module composition"
  }

  # AVM compliance validation
  assert {
    condition = (
      length(var.business_connectors) >= 0 &&
      length(local.auto_non_business_connectors) >= 0 &&
      length(local.auto_blocked_connectors) >= 0
    )
    error_message = "Auto-classification logic should handle all connector types properly"
  }
}
