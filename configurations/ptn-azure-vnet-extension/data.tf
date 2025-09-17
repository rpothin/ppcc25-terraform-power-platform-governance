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
    # WHY: Explicit backend configuration required by terraform_remote_state
    # CONTEXT: terraform_remote_state cannot inherit ARM_* environment variables like root backend
    # IMPACT: Enables reading ptn-environment-group state without workflow changes
    # 
    # NOTE: These values must match your actual Azure Storage backend configuration
    # Update resource_group_name if your backend RG name differs from the pattern below
    storage_account_name = "stterraformpp2cc7945b"                 # From Azure portal - update if different
    container_name       = "terraform-state"                       # Standard container name
    resource_group_name  = "rg-terraform-powerplatform-governance" # Common pattern - verify/update as needed
    use_oidc             = true

    # WHY: Dynamic state key construction based on actual workflow naming pattern
    # CONTEXT: Workflows use flat naming: {pattern}-{tfvars-file}.tfstate format
    # IMPACT: Enables reading from ptn-environment-group state file specifically
    key = "ptn-environment-group-${var.paired_tfvars_file}.tfstate"
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
    workspace_name              = var.paired_tfvars_file # Derived from paired tfvars file for mock data
    template_metadata           = { created_by = "terraform", pattern = "ptn-environment-group" }

    # WHY: Additional attributes to match actual ptn-environment-group remote state structure
    # CONTEXT: Remote state includes these attributes that mock data must provide for type consistency
    # IMPACT: Enables seamless switching between test mode and real remote state
    environment_group_id            = "44444444-4444-4444-4444-444444444444" # Mock environment group ID
    output_schema_version           = "1.0.0"                                # Schema version for compatibility
    deployment_status_summary       = { environments_created = 3 }           # Mock deployment status
    template_configuration          = { template = "basic" }                 # Mock template config
    workspace_template              = "basic"                                # Mock workspace template
    configuration_validation_status = { valid = true }                       # Mock validation status
    resource_naming_summary         = { pattern = "mock-naming" }            # Mock naming summary
    environment_deployment_summary  = { total = 3, successful = 3 }          # Mock deployment summary
  }

  # Conditional remote state access - use mock data in test mode
  remote_state_data = var.test_mode ? local.mock_environment_data : data.terraform_remote_state.environment_group[0].outputs

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
  remote_workspace_name              = try(local.remote_state_data.workspace_name, var.paired_tfvars_file)
  remote_template_metadata           = try(local.remote_state_data.template_metadata, {})
}