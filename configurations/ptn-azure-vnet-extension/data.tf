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
  # WHY: Direct access to remote state outputs when available
  # CONTEXT: Avoid type checking issues by using null for the false branch
  # IMPACT: Terraform won't enforce type consistency between object and null

  # Check if we have remote state available
  has_remote_state = !var.test_mode && length(data.terraform_remote_state.environment_group) > 0

  # WHY: Use null instead of {} to avoid type checking conflicts
  # CONTEXT: Terraform doesn't type-check null against objects
  # IMPACT: Eliminates "inconsistent conditional result types" error
  remote_outputs = local.has_remote_state ? data.terraform_remote_state.environment_group[0].outputs : null

  # Extract actual environment data from state file structure (numeric keys)
  # The state file uses "0", "1", "2" as keys, not environment names
  remote_environment_ids = local.has_remote_state ? local.remote_outputs.environment_ids : {
    # Test mode mock data only used when test_mode = true
    "0" = "11111111-1111-1111-1111-111111111111"
    "1" = "22222222-2222-2222-2222-222222222222"
    "2" = "33333333-3333-3333-3333-333333333333"
  }

  remote_environment_names = local.has_remote_state ? local.remote_outputs.environment_names : {
    "0" = "Development"
    "1" = "Test"
    "2" = "Production"
  }

  remote_environment_types = local.has_remote_state ? local.remote_outputs.environment_types : {
    "0" = "Sandbox"
    "1" = "Sandbox"
    "2" = "Production"
  }

  remote_environment_suffixes = local.has_remote_state ? local.remote_outputs.environment_suffixes : {
    "0" = " - Dev"
    "1" = " - Test"
    "2" = " - Prod"
  }

  # Build classifications from environment types (not in state file directly)
  remote_environment_classifications = {
    for key, env_type in local.remote_environment_types :
    key => env_type == "Production" ? "Production" : "Non-Production"
  }

  # Extract workspace name from state
  remote_workspace_name = local.has_remote_state ? local.remote_outputs.workspace_name : var.paired_tfvars_file

  # Extract template metadata from state
  remote_template_metadata = local.has_remote_state ? local.remote_outputs.template_metadata : {
    pattern_type  = "ptn-environment-group"
    template_name = "basic"
  }

  # Validation of remote state data
  remote_state_validation = {
    environment_ids_exist      = length(local.remote_environment_ids) > 0
    environment_names_exist    = length(local.remote_environment_names) > 0
    environment_types_exist    = length(local.remote_environment_types) > 0
    environment_suffixes_exist = length(local.remote_environment_suffixes) > 0
    workspace_name_exists      = local.remote_workspace_name != null && local.remote_workspace_name != ""
    template_metadata_exists   = length(local.remote_template_metadata) > 0
  }

  remote_state_valid = alltrue(values(local.remote_state_validation))
}