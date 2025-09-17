# Remote State Data Sources for Power Platform Azure VNet Extension Pattern
#
# WHY: Pattern module orchestration requires reading state from paired modules
# to maintain consistency and avoid configuration duplication
#
# CONTEXT: This pattern extends ptn-environment-group with Azure VNet infrastructure,
# requiring environment data to determine enterprise policy deployment targets
#
# IMPACT: Remote state integration enables loosely coupled pattern composition
# while maintaining data consistency across deployments

# ============================================================================
# REMOTE STATE READING - Environment Group Pattern Integration
# ============================================================================

# WHY: Read environment group remote state to discover environments for VNet integration
# CONTEXT: This pattern requires existing environments to apply enterprise policies
# IMPACT: VNet integration policies will be applied to discovered environments
# 
# TECHNICAL: Dynamic state key generation eliminates hardcoded state configuration,
# using backend config from current Terraform execution context for consistency
data "terraform_remote_state" "environment_group" {
  count   = var.test_mode ? 0 : 1
  backend = "azurerm"
  config = {
    # WHY: Use current backend configuration to avoid configuration duplication
    # CONTEXT: Terraform execution inherits backend config from versions.tf
    # IMPACT: Ensures consistent state storage location across pattern modules
    use_oidc = true

    # WHY: Dynamic state key construction based on actual workflow naming pattern
    # CONTEXT: Workflows use flat naming: {pattern}-{tfvars-file}.tfstate format
    # IMPACT: Enables reading from actual state files created by GitHub Actions workflow
    key = "ptn-environment-group-${var.paired_tfvars_file}.tfstate"

    # Note: resource_group_name, storage_account_name, container_name inherited
    # from current backend configuration automatically by Terraform
  }
}

# ============================================================================
# VALIDATION - Remote State Output Validation
# ============================================================================

# WHY: Validate remote state contains required outputs for VNet integration
# CONTEXT: Pattern requires specific outputs to function correctly
# IMPACT: Early failure prevents resource creation without proper dependencies
locals {
  # WHY: Mock data for test mode to enable testing without backend dependencies
  # CONTEXT: Test environments may not have access to production state backend
  # IMPACT: Enables comprehensive testing while maintaining production behavior
  mock_environment_data = {
    environment_ids = {
      "dev"  = "11111111-1111-1111-1111-111111111111" # Valid GUID format for dev
      "test" = "22222222-2222-2222-2222-222222222222" # Valid GUID format for test  
      "prod" = "33333333-3333-3333-3333-333333333333" # Valid GUID format for prod
    }
    environment_names           = { "dev" = "Development", "test" = "Test", "prod" = "Production" }
    environment_types           = { "dev" = "Development", "test" = "Test", "prod" = "Production" }
    environment_suffixes        = { "dev" = "dev", "test" = "test", "prod" = "prod" }
    environment_classifications = { "dev" = "Non-Production", "test" = "Non-Production", "prod" = "Production" }
    workspace_name              = "DemoWorkspace" # Derived from tfvars file name for mock data
    template_metadata           = { created_by = "terraform", pattern = "ptn-environment-group" }
  }

  # Conditional remote state access - use mock data in test mode
  remote_state_data = var.test_mode ? local.mock_environment_data : (
    length(data.terraform_remote_state.environment_group) > 0 ? data.terraform_remote_state.environment_group[0].outputs : local.mock_environment_data
  )

  # Validate remote state outputs exist
  remote_state_validation = {
    environment_ids_exist      = length(try(local.remote_state_data.environment_ids, {})) > 0
    environment_names_exist    = length(try(local.remote_state_data.environment_names, {})) > 0
    environment_types_exist    = length(try(local.remote_state_data.environment_types, {})) > 0
    environment_suffixes_exist = length(try(local.remote_state_data.environment_suffixes, {})) > 0
    workspace_name_exists      = try(local.remote_state_data.workspace_name, null) != null
    template_metadata_exists   = try(local.remote_state_data.template_metadata, null) != null
  }

  # Check if all required outputs are present
  remote_state_valid = alltrue([
    local.remote_state_validation.environment_ids_exist,
    local.remote_state_validation.environment_names_exist,
    local.remote_state_validation.environment_types_exist,
    local.remote_state_validation.environment_suffixes_exist,
    local.remote_state_validation.workspace_name_exists,
    local.remote_state_validation.template_metadata_exists
  ])

  # Extract validated outputs or provide empty fallbacks
  remote_environment_ids             = try(local.remote_state_data.environment_ids, {})
  remote_environment_names           = try(local.remote_state_data.environment_names, {})
  remote_environment_types           = try(local.remote_state_data.environment_types, {})
  remote_environment_suffixes        = try(local.remote_state_data.environment_suffixes, {})
  remote_environment_classifications = try(local.remote_state_data.environment_classifications, {})
  remote_workspace_name              = try(local.remote_state_data.workspace_name, "DemoWorkspace")
  remote_template_metadata           = try(local.remote_state_data.template_metadata, {})
}